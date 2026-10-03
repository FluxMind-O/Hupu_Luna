import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

/**
 * 数据缓存（缓存优先渲染）
 *
 * 存储结构：key -> {"t":<存入时间戳>,"v":<数据json>}
 * 页面加载顺序：先读缓存立即渲染 → 后台网络刷新 → 成功后替换并更新缓存；
 * 网络失败但缓存存在 → 继续展示缓存内容（页面提示"稍早内容"），不显示错误页。
 */
const STORE_NAME: string = 'hupluna_cache';
const MAX_AGE_MS: number = 72 * 3600 * 1000;

export class CachedPayload {
  json: string = '';
  ageMs: number = 0;
}

class CacheEnvelope {
  t: number = 0;
  v: string = '';
}

export class CacheStore {
  private static async getPref(context: common.Context): Promise<preferences.Preferences> {
    const opt: preferences.Options = { name: STORE_NAME };
    return await preferences.getPreferences(context, opt);
  }

  /** 写缓存（失败静默，不影响主流程） */
  static async put(context: common.Context, key: string, json: string): Promise<void> {
    try {
      const pref: preferences.Preferences = await CacheStore.getPref(context);
      const env: CacheEnvelope = new CacheEnvelope();
      env.t = Date.now();
      env.v = json;
      await pref.put(`cache/${key}`, JSON.stringify(env));
      await pref.flush();
    } catch (e) {
    }
  }

  /** 读缓存：不存在/已过期/损坏返回 null */
  static async get(context: common.Context, key: string): Promise<CachedPayload | null> {
    try {
      const pref: preferences.Preferences = await CacheStore.getPref(context);
      const v: preferences.ValueType = await pref.get(`cache/${key}`, '');
      const s: string = v as string;
      if (!s || s.length === 0) {
        return null;
      }
      const env: CacheEnvelope = JSON.parse(s) as CacheEnvelope;
      if (!env || !env.v || env.t <= 0) {
        return null;
      }
      const age: number = Date.now() - env.t;
      if (age > MAX_AGE_MS) {
        return null;
      }
      const p: CachedPayload = new CachedPayload();
      p.json = env.v;
      p.ageMs = age;
      return p;
    } catch (e) {
      return null;
    }
  }

  /** 清空全部缓存（设置页入口用） */
  static async clear(context: common.Context): Promise<void> {
    try {
      const pref: preferences.Preferences = await CacheStore.getPref(context);
      await pref.clear();
      await pref.flush();
    } catch (e) {
    }
  }
}
