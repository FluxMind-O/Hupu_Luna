import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HttpManager, ExtraHeaders } from './HttpManager';

const DOMAIN: number = 0x0000;
const TAG: string = 'SessionManager';
const STORE_NAME: string = 'hupluna_settings';
const KEY_COOKIE: string = 'cookie_jar';

/** 登录用户信息（/api/v2/user 返回） */
export class HupuUserInfo {
  uid: string = '';
  puid: string = '';
  username: string = '';
  header: string = '';
  spaceurl: string = '';
}

interface UserRespDto {
  data?: UserInnerDto;
  code?: number;
  msg?: string;
}

interface UserInnerDto {
  uid?: string;
  puid?: string;
  username?: string;
  header?: string;
  spaceurl?: string;
}

/**
 * 登录态管理（V2）
 *
 * - Cookie 整串存 Preferences（`hupluna_settings/cookie_jar`），不落日志
 * - `ua=` 键存在 = 已登录（V2-M0 口径）
 * - `verify()` 调 m 站 /api/v2/user 实测登录态并取回用户信息
 * - 登录状态同步到 AppStorage：loginState（0 未登录 / 1 已登录）、loginUserJson（用户信息）
 * - 写接口收到 401/PC022003 时调 markInvalid() 降级只读
 */
export class SessionManager {
  private static cookie: string = '';
  private static loaded: boolean = false;

  /** AppStorage 同步键 */
  static readonly KEY_STATE: string = 'loginState';
  static readonly KEY_USER: string = 'loginUserJson';

  /** 从 Preferences 载入 Cookie（幂等） */
  static async ensureLoaded(context: common.Context): Promise<void> {
    if (SessionManager.loaded) {
      return;
    }
    try {
      const opt: preferences.Options = { name: STORE_NAME };
      const pref: preferences.Preferences = await preferences.getPreferences(context, opt);
      const v: preferences.ValueType = await pref.get(KEY_COOKIE, '');
      const s: string = v as string;
      SessionManager.cookie = s ?? '';
      SessionManager.loaded = true;
      SessionManager.syncState();
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'load cookie failed');
    }
  }

  /** 是否有 Cookie（本地判定，快速路径） */
  static hasCookie(): boolean {
    if (SessionManager.cookie.length === 0) {
      return false;
    }
    return SessionManager.cookie.indexOf('ua=') >= 0;
  }

  /** 当前 Cookie 串（HttpManager 写请求用） */
  static cookieHeader(): string {
    return SessionManager.cookie;
  }

  /** 保存 Cookie 并立即验证；返回验证后的用户信息（null = 验证失败） */
  static async saveAndVerify(context: common.Context, cookieString: string): Promise<HupuUserInfo | null> {
    const trimmed: string = cookieString.trim();
    if (trimmed.length < 20 || trimmed.indexOf('ua=') < 0) {
      return null;
    }
    SessionManager.cookie = trimmed;
    SessionManager.loaded = true;
    try {
      const opt: preferences.Options = { name: STORE_NAME };
      const pref: preferences.Preferences = await preferences.getPreferences(context, opt);
      await pref.put(KEY_COOKIE, trimmed);
      await pref.flush();
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'save cookie failed');
    }
    const user: HupuUserInfo | null = await SessionManager.verify();
    if (user !== null) {
      SessionManager.syncState();
    }
    return user;
  }

  /** 实测登录态：调 /api/v2/user（Cookie 自动附带） */
  static async verify(): Promise<HupuUserInfo | null> {
    if (!SessionManager.hasCookie()) {
      SessionManager.syncState();
      return null;
    }
    try {
      const resp = await HttpManager.getJsonAuth<UserRespDto>('https://m.hupu.com/api/v2/user', SessionManager.cookie);
      if (resp.code === 200 && resp.data && resp.data.username) {
        const u: HupuUserInfo = new HupuUserInfo();
        u.uid = resp.data.uid ?? '';
        u.puid = resp.data.puid ?? '';
        u.username = resp.data.username ?? '';
        u.header = resp.data.header ?? '';
        u.spaceurl = resp.data.spaceurl ?? '';
        SessionManager.syncState();
        return u;
      }
    } catch (e) {
    }
    SessionManager.syncState();
    return null;
  }

  /** 登录失效（写接口 401 时调用）：清 Cookie 降级只读 */
  static async markInvalid(context: common.Context): Promise<void> {
    SessionManager.cookie = '';
    try {
      const opt: preferences.Options = { name: STORE_NAME };
      const pref: preferences.Preferences = await preferences.getPreferences(context, opt);
      await pref.delete(KEY_COOKIE);
      await pref.flush();
    } catch (e) {
    }
    SessionManager.syncState();
  }

  /** 退出登录（设置页） */
  static async logout(context: common.Context): Promise<void> {
    await SessionManager.markInvalid(context);
  }

  /** 合并多域 Cookie 串（同键后者覆盖），供 WebView 抓取合并 */
  static mergeCookies(a: string, b: string): string {
    const map: Map<string, string> = new Map();
    const parts: string[] = (a + '; ' + b).split(';');
    for (const part of parts) {
      const kv: string = part.trim();
      if (kv.length === 0) {
        continue;
      }
      const i: number = kv.indexOf('=');
      if (i <= 0) {
        continue;
      }
      map.set(kv.substring(0, i), kv.substring(i + 1));
    }
    const arr: string[] = [];
    map.forEach((v: string, k: string) => {
      arr.push(k + '=' + v);
    });
    return arr.join('; ');
  }

  /** 同步到 AppStorage 供 UI 响应式刷新 */
  private static syncState(): void {
    AppStorage.setOrCreate<number>(SessionManager.KEY_STATE, SessionManager.hasCookie() ? 1 : 0);
  }
}

/** 统一构造带登录态的写请求头 */
export function writeHeaders(contentType: boolean): ExtraHeaders {
  const h: ExtraHeaders = new ExtraHeaders();
  h.UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36 Edg/154.0.0.0';
  h.referer = 'https://bbs.hupu.com/';
  if (contentType) {
    h.contentType = 'application/json';
  }
  h.cookie = SessionManager.cookieHeader();
  return h;
}
