import { http } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'HttpManager';

const DEFAULT_UA: string =
  'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Mobile Safari/537.36';

/** 额外请求头（可选；class 字段点号访问，规避 arkts-no-props-by-index） */
export class ExtraHeaders {
  UA: string = '';
  contentType: string = '';
  referer: string = '';
  cookie: string = '';
}

/** 请求选项 */
export class RequestOptions {
  method: http.RequestMethod = http.RequestMethod.GET;
  headers: ExtraHeaders | null = null;
  body: string = '';
  timeoutMs: number = 0;
  /** 请求头 UA 覆盖（get 第二参数透传用） */
  ua: string = '';
}

/** 统一请求封装：超时 / UA / 重试 / 统一错误归一 */
export class HttpManager {
  private static async requestOnce(url: string, opts: RequestOptions): Promise<string> {
    const request = http.createHttp();
    try {
      const header: Record<string, string> = {
        'User-Agent': opts.ua.length > 0 ? opts.ua : DEFAULT_UA,
        'Accept': 'application/json, text/html, */*'
      };
      const h: ExtraHeaders | null = opts.headers;
      if (h !== null) {
        if (h.UA.length > 0) {
          header['User-Agent'] = h.UA;
        }
        if (h.contentType.length > 0) {
          header['Content-Type'] = h.contentType;
        }
        if (h.referer.length > 0) {
          header['Referer'] = h.referer;
        }
        if (h.cookie.length > 0) {
          header['Cookie'] = h.cookie;
        }
      }
      const resp = await request.request(url, {
        method: opts.method,
        header: header,
        extraData: opts.body.length > 0 ? opts.body : undefined,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: opts.timeoutMs > 0 ? opts.timeoutMs : 10000,
        readTimeout: opts.timeoutMs > 0 ? opts.timeoutMs : 15000
      });
      if (resp.responseCode !== 200) {
        throw new Error(`HTTP ${resp.responseCode}`);
      }
      return resp.result as string;
    } finally {
      request.destroy();
    }
  }

  /** GET：默认带一次网络层重试（仅超时/连接失败，HTTP 非 200 不重试） */
  static async get(url: string, ua: string = DEFAULT_UA): Promise<string> {
    const opts: RequestOptions = new RequestOptions();
    opts.ua = ua;
    return HttpManager.request(url, opts);
  }

  static async request(url: string, opts: RequestOptions): Promise<string> {
    let lastErr: Error = new Error('unknown');
    const isGet: boolean = opts.method === http.RequestMethod.GET;
    const attempts: number = isGet ? 2 : 1;
    for (let attempt: number = 0; attempt < attempts; attempt++) {
      try {
        return await HttpManager.requestOnce(url, opts);
      } catch (e) {
        const err = e as Error;
        lastErr = err;
        if (err.message.indexOf('HTTP ') === 0) {
          break;
        }
      }
    }
    hilog.error(DOMAIN, TAG, 'request failed: %{public}s', url);
    throw new Error(`网络请求失败: ${lastErr.message}`);
  }

  static async getJson<T>(url: string): Promise<T> {
    const text: string = await HttpManager.get(url);
    try {
      return JSON.parse(text) as T;
    } catch (e) {
      throw new Error('数据解析失败');
    }
  }

  /** 带登录态 Cookie 的 GET JSON（V2 会话验证用） */
  static async getJsonAuth<T>(url: string, cookie: string): Promise<T> {
    const opts: RequestOptions = new RequestOptions();
    const h: ExtraHeaders = new ExtraHeaders();
    h.cookie = cookie;
    opts.headers = h;
    const text: string = await HttpManager.request(url, opts);
    try {
      return JSON.parse(text) as T;
    } catch (e) {
      throw new Error('数据解析失败');
    }
  }

  /** 写操作 POST（V2：桌面 Web 接口，需 Cookie/Referer） */
  static async postJson(url: string, body: string, headers: ExtraHeaders, ua: string): Promise<string> {
    const opts: RequestOptions = new RequestOptions();
    opts.method = http.RequestMethod.POST;
    opts.body = body;
    opts.headers = headers;
    opts.timeoutMs = 15000;
    if (ua.length > 0) {
      opts.ua = ua;
    }
    return HttpManager.request(url, opts);
  }
}
