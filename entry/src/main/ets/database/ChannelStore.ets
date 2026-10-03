import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

const STORE_NAME: string = 'hupluna_settings';
const KEY_CHANNELS: string = 'channel_ids';

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
}
