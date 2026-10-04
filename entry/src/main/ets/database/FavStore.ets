import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

const TABLE_NAME: string = 'fav_thread';

/** 收藏记录 */
export class FavRecord {
  tid: string = '';
  title: string = '';
  author: string = '';
  forum: string = '';
  favTime: number = 0;
}

/** 本地收藏存储（RelationalStore） */
export class FavStore {
  private static store: relationalStore.RdbStore | null = null;

  private static async ensureStore(context: common.Context): Promise<relationalStore.RdbStore> {
    if (FavStore.store !== null) {
      return FavStore.store;
    }
    const config: relationalStore.StoreConfig = {
      name: 'hupluna.db',
      securityLevel: relationalStore.SecurityLevel.S1
    };
    const store: relationalStore.RdbStore = await relationalStore.getRdbStore(context, config);
    await store.executeSql(
      'CREATE TABLE IF NOT EXISTS ' + TABLE_NAME +
        ' (tid TEXT PRIMARY KEY, title TEXT NOT NULL, author TEXT, forum TEXT, fav_time INTEGER)'
    );
    FavStore.store = store;
    return store;
  }

  static async add(context: common.Context, rec: FavRecord): Promise<void> {
    const store: relationalStore.RdbStore = await FavStore.ensureStore(context);
    const bucket: relationalStore.ValuesBucket = {
      'tid': rec.tid,
      'title': rec.title,
      'author': rec.author,
      'forum': rec.forum,
      'fav_time': rec.favTime
    };
    await store.insert(TABLE_NAME, bucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
  }

  static async remove(context: common.Context, tid: string): Promise<void> {
    const store: relationalStore.RdbStore = await FavStore.ensureStore(context);
    const pred = new relationalStore.RdbPredicates(TABLE_NAME);
    pred.equalTo('tid', tid);
    await store.delete(pred);
  }

  static async clear(context: common.Context): Promise<void> {
    const store: relationalStore.RdbStore = await FavStore.ensureStore(context);
    const pred = new relationalStore.RdbPredicates(TABLE_NAME);
    await store.delete(pred);
  }

  static async isFav(context: common.Context, tid: string): Promise<boolean> {
    const store: relationalStore.RdbStore = await FavStore.ensureStore(context);
    const pred = new relationalStore.RdbPredicates(TABLE_NAME);
    pred.equalTo('tid', tid);
    const rs: relationalStore.ResultSet = await store.query(pred, ['tid']);
    const existed: boolean = rs.rowCount > 0;
    rs.close();
    return existed;
  }

  static async list(context: common.Context): Promise<FavRecord[]> {
    const store: relationalStore.RdbStore = await FavStore.ensureStore(context);
    const pred = new relationalStore.RdbPredicates(TABLE_NAME);
    pred.orderByDesc('fav_time');
    const rs: relationalStore.ResultSet = await store.query(pred, ['tid', 'title', 'author', 'forum', 'fav_time']);
    const result: FavRecord[] = [];
    while (rs.goToNextRow()) {
      const rec: FavRecord = new FavRecord();
      rec.tid = rs.getString(rs.getColumnIndex('tid'));
      rec.title = rs.getString(rs.getColumnIndex('title'));
      rec.author = rs.getString(rs.getColumnIndex('author'));
      rec.forum = rs.getString(rs.getColumnIndex('forum'));
      rec.favTime = rs.getLong(rs.getColumnIndex('fav_time'));
      result.push(rec);
    }
    rs.close();
    return result;
  }

  /** 导出全部收藏为 JSON 串（剪贴板/文件通用） */
  static async exportJson(context: common.Context): Promise<string> {
    const items: FavRecord[] = await FavStore.list(context);
    const payload: Record<string, Object> = {
      'app': 'hupluna',
      'type': 'fav_threads',
      'version': 1,
      'items': items
    };
    return JSON.stringify(payload);
  }

  /** 从 JSON 串导入收藏（按 tid 幂等合并），返回导入条数；格式非法返回 -1 */
  static async importJson(context: common.Context, json: string): Promise<number> {
    let items: FavRecord[] = [];
    try {
      const parsed: Record<string, Object> = JSON.parse(json) as Record<string, Object>;
      if (parsed['type'] !== 'fav_threads' || !Array.isArray(parsed['items'])) {
        return -1;
      }
      items = parsed['items'] as FavRecord[];
    } catch (e) {
      return -1;
    }
    let count: number = 0;
    for (let i = 0; i < items.length; i++) {
      const it = items[i];
      if (typeof it.tid !== 'string' || it.tid.length === 0) {
        continue;
      }
      const rec: FavRecord = new FavRecord();
      rec.tid = it.tid;
      rec.title = typeof it.title === 'string' ? it.title : '';
      rec.author = typeof it.author === 'string' ? it.author : '';
      rec.forum = typeof it.forum === 'string' ? it.forum : '';
      rec.favTime = typeof it.favTime === 'number' ? it.favTime : Date.now();
      await FavStore.add(context, rec);
      count++;
    }
    return count;
  }
}
