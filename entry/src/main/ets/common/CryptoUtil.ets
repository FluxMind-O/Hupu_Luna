import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { util } from '@kit.ArkTS';

/**
 * 虎扑上传链路所需的密码学工具。
 *
 * 逆向自 PC 站 bundle 的 `getSignData`：
 *   HmacSHA1(待签名串, secretKey) → Base64 → URL-safe（+ → - ，/ → _）
 * 注意：**保留 base64 padding `=`**（官方代码只替换了 + 和 /）。
 */
export class CryptoUtil {
  /** HMAC-SHA1 → Base64 → URL-safe（+→- /→_） */
  static async hmacSha1Base64UrlSafe(message: string, secretKey: string): Promise<string> {
    const bytes: Uint8Array = await CryptoUtil.hmacSha1(message, secretKey);
    const b64: string = new util.Base64Helper().encodeToStringSync(bytes);
    return b64.replace(new RegExp('\\+', 'g'), '-').replace(new RegExp('/', 'g'), '_');
  }

  /** HMAC-SHA1 → 标准 Base64（OSS 签名用） */
  static async hmacSha1Base64(message: string, secretKey: string): Promise<string> {
    const bytes: Uint8Array = await CryptoUtil.hmacSha1(message, secretKey);
    return new util.Base64Helper().encodeToStringSync(bytes);
  }

  /** HMAC-SHA1 原始字节 */
  private static async hmacSha1(message: string, secretKey: string): Promise<Uint8Array> {
    const mac: cryptoFramework.Mac = cryptoFramework.createMac('SHA1');
    const keyGen: cryptoFramework.SymKeyGenerator = cryptoFramework.createSymKeyGenerator('HMAC');
    const keyBlob: cryptoFramework.DataBlob = { data: CryptoUtil.utf8(secretKey) };
    const symKey: cryptoFramework.SymKey = await keyGen.convertKey(keyBlob);
    await mac.init(symKey);
    const msgBlob: cryptoFramework.DataBlob = { data: CryptoUtil.utf8(message) };
    await mac.update(msgBlob);
    const out: cryptoFramework.DataBlob = await mac.doFinal();
    return out.data;
  }

  /** 字符串 → UTF-8 字节 */
  static utf8(s: string): Uint8Array {
    const encoder: util.TextEncoder = new util.TextEncoder();
    return encoder.encodeInto(s);
  }

  /** 随机文件名（对齐官方 xc()：随机串） */
  static randomName(): string {
    const chars: string = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let s: string = '';
    for (let i: number = 0; i < 32; i++) {
      const idx: number = Math.floor(Math.random() * chars.length);
      s = s + chars.charAt(idx);
    }
    return s;
  }

  /** 当前时间戳（毫秒，字符串） */
  static nowMs(): string {
    return `${Date.now()}`;
  }
}
