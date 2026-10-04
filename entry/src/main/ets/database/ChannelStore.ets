import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

const STORE_NAME: string = 'hupluna_settings';
const KEY_CHANNELS: string = 'channel_ids';
const KEY_LAST_CHANNEL: string = 'last_channel_id';

/** 频道选择持久化（Preferences） */
export class ChannelStore {
  private static async getPref(context: common.Context): Promise<preferences.Preferences> {
    const opt: preferences.Options = { name: STORE_NAME };
    return await preferences.getPreferences(context, opt);
  }

  /** 读取已保存的频道 id；空数组表示尚未保存（用默认） */
  static async load(context: common.Context): Promise<string[]> {
    try {
      const pref: preferences.Preferences = await ChannelStore.getPref(context);
      const v: preferences.ValueType = await pref.get(KEY_CHANNELS, '');
      const s: string = v as string;
      if (!s || s.length === 0) {
        return [];
      }
      return JSON.parse(s) as string[];
    } catch (e) {
      return [];
    }
  }

  static async save(context: common.Context, ids: string[]): Promise<void> {
    try {
      const pref: preferences.Preferences = await ChannelStore.getPref(context);
      await pref.put(KEY_CHANNELS, JSON.stringify(ids));
      await pref.flush();
    } catch (e) {
    }
  }

  /**
   * 记录末次停留栏目（供下次启动恢复）。
   * 同步落盘（putSync/flush）：页面切栏目多发生在退出前，异步写入可能来不及。
   */
  static saveLast(context: common.Context, id: string): void {
    if (id.length === 0) {
      return;
    }
    try {
      const pref: preferences.Preferences = preferences.getPreferencesSync(context, { name: STORE_NAME });
      pref.putSync(KEY_LAST_CHANNEL, id);
      pref.flush();
    } catch (e) {
    }
  }
}
