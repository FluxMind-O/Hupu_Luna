import { http } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { SessionManager } from './SessionManager';
import { CryptoUtil } from '../common/CryptoUtil';

const DOMAIN: number = 0x0000;
const TAG: string = 'HupuLuna';
const UA: string =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36 Edg/154.0.0.0';

/* 逆向自 PC 站 bundle 的硬编码凭证（客户端内置，非用户凭证） */
const STS_URL: string = 'https://hss.hupu.com/kaleido/hss/app/credentials';
const APP_ID: string = 'uPRLht4dLiblkF6bcjRtLuDQ4eo=';
const SECRET_KEY: string = 'uxiXcdOrdp2PxTTDlNGQ3g72oWM=';
/** 图片上传模块（host=i1.hoopchina.com.cn） */
const MODULE_IMG: string = 'editor-oss';
/** 视频上传模块（host=v.hoopchina.com.cn） */
const MODULE_VIDEO: string = 'editor-video-oss';
const PATH_EDITOR: string = '/editor';

/** STS 凭证（接口返回） */
class StsCredential {
  region: string = '';
  bucket: string = '';
  accessKey: string = '';
  secretKey: string = '';
  token: string = '';
  domains: string[] = [];
  /** 过期时间（毫秒） */
  expireMs: number = 0;
}

interface StsDataDto {
  region?: string;
  expiration?: number;
  bucket?: string;
  accessKey?: string;
  secretKey?: string;
  token?: string;
  domains?: string[];
}

interface StsRespDto {
  code?: string;
  msg?: string;
  data?: StsDataDto;
}

/**
 * 虎扑图床直传（阿里云 OSS）。
 *
 * 链路（逆向自 PC 站 bundle）：
 *  1. GET `hss.hupu.com/kaleido/hss/app/credentials`（参数走 query，带登录 Cookie）
 *     签名 `sign` = URL-safe-Base64(HmacSHA1("action=1&appId=..&module=..&path=..&timestamp=..", secretKey))
 *     → 返回临时凭证 {region, bucket, accessKey, secretKey, token, domains}
 *  2. PUT `https://{bucket}.{region}.aliyuncs.com/{object}`
 *     Authorization: `OSS {accessKey}:{Base64(HmacSHA1(StringToSign, secretKey))}`
 *     StringToSign = `PUT\n\n{contentType}\n{date}\nx-oss-security-token:{token}\n/{bucket}/{object}`
 *  3. 公开地址 = `domains[0] + object`
 *
 * 对象路径（对齐官方）：`editor/{年-月-日}/{时-分-日}/{随机名}.{ext}`
 *   注意月/日不补零（官方用 toLocaleString 后替换分隔符）。
 */
export class OssUpload {
  private static cred: StsCredential | null = null;

  /** 获取（并缓存）STS 临时凭证，过期前 5 分钟自动续期 */
  private static async ensureCredential(video: boolean): Promise<StsCredential> {
    const cached: StsCredential | null = OssUpload.cred;
    if (cached !== null && cached.expireMs - Date.now() > 5 * 60 * 1000) {
      return cached;
    }
    if (!SessionManager.hasCookie()) {
      throw new Error('未登录，请先在设置页注入 Cookie');
    }
    const moduleName: string = video ? MODULE_VIDEO : MODULE_IMG;
    const ts: string = CryptoUtil.nowMs();
    const toSign: string =
      `action=1&appId=${APP_ID}&module=${moduleName}&path=${PATH_EDITOR}&timestamp=${ts}`;
    const sign: string = await CryptoUtil.hmacSha1Base64UrlSafe(toSign, SECRET_KEY);
    const qs: string =
      `action=1&appId=${encodeURIComponent(APP_ID)}&module=${encodeURIComponent(moduleName)}` +
        `&path=${encodeURIComponent(PATH_EDITOR)}&timestamp=${ts}&sign=${encodeURIComponent(sign)}&cookie=`;
    const url: string = `${STS_URL}?${qs}`;

    const request = http.createHttp();
    try {
      const resp = await request.request(url, {
        method: http.RequestMethod.GET,
        header: {
          'User-Agent': UA,
          'Referer': 'https://bbs.hupu.com/',
          'Accept': 'application/json',
          'Cookie': SessionManager.cookieHeader()
        },
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 15000,
        readTimeout: 20000
      });
      const text: string = resp.result as string;
      let obj: StsRespDto | null = null;
      try {
        obj = JSON.parse(text) as StsRespDto;
      } catch (e) {
        throw new Error('凭证响应解析失败');
      }
      if (obj.code !== '0' || !obj.data) {
        const msg: string = obj.msg !== undefined && obj.msg.length > 0 ? obj.msg : '获取上传凭证失败';
        throw new Error(msg);
      }
      const d: StsDataDto = obj.data;
      const cred: StsCredential = new StsCredential();
      cred.region = d.region ?? '';
      cred.bucket = d.bucket ?? '';
      cred.accessKey = d.accessKey ?? '';
      cred.secretKey = d.secretKey ?? '';
      cred.token = d.token ?? '';
      cred.domains = d.domains ?? [];
      // expiration 为秒级时间戳
      cred.expireMs = (d.expiration ?? 0) * 1000;
      if (cred.bucket.length === 0 || cred.accessKey.length === 0 || cred.domains.length === 0) {
        throw new Error('上传凭证不完整');
      }
      OssUpload.cred = cred;
      return cred;
    } finally {
      request.destroy();
    }
  }

  /**
   * 对象路径（对齐官方规则）
   * @param ext 扩展名（不含点），空则用 png
   */
  private static buildObjectName(ext: string): string {
    const now: Date = new Date();
    // 官方用 Asia/Shanghai 时区的本地时间，且月/日不补零
    const y: number = now.getFullYear();
    const mo: number = now.getMonth() + 1;
    const da: number = now.getDate();
    const h: number = now.getHours();
    const mi: number = now.getMinutes();
    const s: number = now.getSeconds();
    const p2 = (n: number): string => (n < 10 ? `0${n}` : `${n}`);
    const e: string = ext.length > 0 ? ext : 'png';
    return `editor/${y}-${mo}-${da}/${h}-${mi}-${s}/${CryptoUtil.randomName()}.${e}`;
  }

  /** RFC1123 GMT 时间（OSS Date 头） */
  private static gmtDate(): string {
    return new Date().toUTCString();
  }

  /**
   * 上传图片字节到虎扑图床。
   * @param data 文件字节
   * @param ext 扩展名（png/jpg/gif/webp）
   * @param contentType MIME（如 image/png）
   * @returns 公网可访问的图片地址
   */
  static async uploadImage(data: Uint8Array, ext: string, contentType: string): Promise<string> {
    return OssUpload.putObject(data, ext, contentType, MODULE_IMG, false);
  }

  /** 上传视频字节到虎扑视频图床（小文件单次 PUT，大文件建议分片） */
  static async uploadVideo(data: Uint8Array, ext: string, contentType: string): Promise<string> {
    return OssUpload.putObject(data, ext, contentType, MODULE_VIDEO, true);
  }

  private static async putObject(data: Uint8Array, ext: string, contentType: string,
    moduleName: string, video: boolean): Promise<string> {
    const cred: StsCredential = await OssUpload.ensureCredential(video);
    const object: string = OssUpload.buildObjectName(ext);
    const date: string = OssUpload.gmtDate();

    // StringToSign（阿里云 OSS v1 签名）
    const stringToSign: string =
      `PUT\n\n${contentType}\n${date}\nx-oss-security-token:${cred.token}\n/${cred.bucket}/${object}`;
    const sig: string = await CryptoUtil.hmacSha1Base64(stringToSign, cred.secretKey);
    const endpoint: string = `https://${cred.bucket}.${cred.region}.aliyuncs.com/${object}`;

    const request = http.createHttp();
    try {
      const resp = await request.request(endpoint, {
        method: http.RequestMethod.PUT,
        header: {
          'User-Agent': UA,
          'Content-Type': contentType,
          'Date': date,
          'x-oss-security-token': cred.token,
          'Authorization': `OSS ${cred.accessKey}:${sig}`
        },
        extraData: data.buffer as ArrayBuffer,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 30000,
        readTimeout: video ? 180000 : 60000
      });
      if (resp.responseCode < 200 || resp.responseCode >= 300) {
        hilog.error(DOMAIN, TAG, 'oss put failed code=%{public}d', resp.responseCode);
        throw new Error(`图片上传失败（${resp.responseCode}）`);
      }
      const domain: string = cred.domains[0];
      const base: string = domain.endsWith('/') ? domain : `${domain}/`;
      hilog.info(DOMAIN, TAG, 'oss put ok');
      return `${base}${object}`;
    } catch (e) {
      if (e instanceof Error && e.message.indexOf('图片上传失败') >= 0) {
        throw e;
      }
      throw new Error(`上传失败：${e instanceof Error ? e.message : '网络异常'}`);
    } finally {
      request.destroy();
    }
  }

  /** 清除缓存凭证（凭证失效时重试用） */
  static invalidate(): void {
    OssUpload.cred = null;
  }
}
