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
}
