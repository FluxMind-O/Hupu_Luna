import { HupuApi } from '../network/HupuApi';
import { NbaApi } from '../network/NbaApi';
import { SoccerApi } from '../network/SoccerApi';
import { ThreadListItem, ThreadListPage, NbaNewsItem, MatchItem, MatchDay, HotRankItem, SoccerMatchItem } from '../model/Models';
import { LoadState, StateView } from '../views/StateView';
import { FeedSkeleton } from '../views/Skeleton';
import { Spacing, FontSize, Radius, RouteName } from '../common/Theme';
import { thumbUrl } from '../common/Utils';
import { compactCount, formatHeat } from '../views/TagChip';
import { ChannelDef, ChannelKind, ChannelCatalog } from '../common/Channels';
import { ChannelStore } from '../database/ChannelStore';
import { CacheStore, CachedPayload } from '../database/CacheStore';
import { ImageKnifeComponent } from '@ohos/imageknife';
import { common } from '@kit.AbilityKit';

/** 通用信息流行 */
class FeedRow {
  tid: string = '';
  title: string = '';
  author: string = '';
  userHeader: string = '';
  tag: string = '';
  time: string = '';
  meta: string = '';
  cover: string = '';
  pics: string[] = [];
  isVideo: boolean = false;
  videoDur: string = '';
  /** true = 官方大卡样式（仅推荐频道） */
  officialCard: boolean = false;
}

/** 频道顶部比赛条 */
class StripItem {
  matchId: string = '';
  title: string = '';
  homeName: string = '';
  awayName: string = '';
  homeLogo: string = '';
  awayLogo: string = '';
  homeScore: string = '';
  awayScore: string = '';
  homeTeamId: string = '';
  awayTeamId: string = '';
  stage: string = '';
  leagueName: string = '';
  league: string = '';
  done: boolean = false;
  timeText: string = '';
  pv: string = '';
}

/** 频道缓存快照（缓存优先渲染：先渲缓存再静默刷新） */
class HomeCacheData {
  rows: FeedRow[] = [];
  ranks: HotRankItem[] = [];
  days: MatchDay[] = [];
  strip: StripItem[] = [];
  cursor: string = '';
  hasMore: boolean = false;
  page: number = 0;
}

@Component
export struct HomePage {
  @Consume('pageStack') pageStack: NavPathStack;
  @StorageLink('channelIdsJson') @Watch('onChannelsChanged') channelIdsJson: string = '';
  @StorageLink('activeChannelId') @Watch('onActiveChanged') activeChannelId: string = '';
  @State channels: ChannelDef[] = [];
  @State rows: FeedRow[] = [];
  @State ranks: HotRankItem[] = [];
  @State days: MatchDay[] = [];
  @State strip: StripItem[] = [];
  @State activeLeague: string = '';
  @State state: LoadState = LoadState.Loading;
  @State refreshing: boolean = false;
  @State staleTip: boolean = false;
  @StorageLink('topAvoidPx') topAvoidPx: number = 0;
  @State hasMore: boolean = false;
  @State activeKind: string = '';
  @State contentAlpha: number = 1;
  @State enterOffsetX: number = 0;
  private pageIndex: number = 0;
  private cursor: string = '';
  private loadingMore: boolean = false;
  private loadSeq: number = 0;
  private channelScroller: Scroller = new Scroller();
  private lastLoadedChannelId: string = '';
  private lastSwitchDir: number = 1;
  private tapThresholdPx: number = 0;
  private swipeThresholdPx: number = 0;
  private itemStartX: number = 0;
  private itemStartY: number = 0;
  private itemMoved: boolean = true;
  private swipeStartX: number = 0;
  private swipeStartY: number = 0;
  private swipeLastX: number = 0;
  private swipeLastY: number = 0;
  /** 内容区滑动手势状态：0=无 1=待判定 2=横向切频道 3=纵向（交列表） */
  private panState: number = 0;
  /** 滑动方向判定阈值（10vp 转 px） */
  private resolvePx: number = 0;
  /** 列表是否处于滚动中（滚动中的抬起不算点击，防误触跳帖） */
  private scrollArmed: boolean = false;
  /** 按下时间戳（点击时长上限判定） */
  private pressStartTs: number = 0;

  aboutToAppear(): void {
    this.initOnce();
  }

  private getCtx(): common.Context {
    return this.getUIContext().getHostContext() as common.Context;
  }

  private async initOnce(): Promise<void> {
    let json: string = this.channelIdsJson;
    if (json.length === 0) {
      let ids: string[] = [];
      try {
        ids = await ChannelStore.load(this.getCtx());
      } catch (e) {
      }
      ids = ChannelCatalog.sanitize(ids);
      if (ids.length === 0) {
        ids = ChannelCatalog.defaults();
      }
      json = JSON.stringify(ids);
      AppStorage.setOrCreate<string>('channelIdsJson', json);
    }
    if (this.activeChannelId.length === 0) {
      const ids2: string[] = JSON.parse(json) as string[];
      const first: string = ids2.length > 0 ? ids2[0] : 'recommend';
      // 触发 onActiveChanged -> loadActive
      AppStorage.setOrCreate<string>('activeChannelId', first);
    }
    this.rebuildChannels();
    if (this.activeChannelId.length > 0) {
      this.loadActive(false);
    }
  }

  onChannelsChanged(): void {
    this.rebuildChannels();
  }

  onActiveChanged(): void {
    const isSwitch: boolean =
      this.lastLoadedChannelId.length > 0 && this.lastLoadedChannelId !== this.activeChannelId;
    this.loadActive(isSwitch);
  }

  private rebuildChannels(): void {
    const list: ChannelDef[] = [];
    const json: string = this.channelIdsJson;
    if (json.length > 0) {
      try {
        const ids: string[] = ChannelCatalog.sanitize(JSON.parse(json) as string[]);
        for (const id of ids) {
          list.push(ChannelCatalog.find(id));
        }
      } catch (e) {
      }
    }
    if (list.length === 0) {
      for (const id of ChannelCatalog.defaults()) {
        list.push(ChannelCatalog.find(id));
      }
    }
    this.channels = list;
    let found: boolean = false;
    for (const c of list) {
      if (c.id === this.activeChannelId) {
        found = true;
      }
    }
    if (!found && list.length > 0) {
      AppStorage.setOrCreate<string>('activeChannelId', list[0].id);
    }
  }

  private mapThreads(items: ThreadListItem[], officialCard: boolean): FeedRow[] {
    const result: FeedRow[] = [];
    for (const t of items) {
      const row: FeedRow = new FeedRow();
      row.tid = t.tid;
      row.title = t.title;
      row.author = t.userName;
      row.tag = t.topicName;
      row.time = t.time;
      row.meta = `${compactCount(t.replies)} 回复 · ${compactCount(t.recommendCount)} 亮`;
      row.cover = t.coverUrl;
      row.userHeader = t.userHeader;
      for (const u of t.picUrls) {
        row.pics.push(u);
      }
      row.isVideo = t.isVideo;
      row.videoDur = t.videoDuration;
      result.push(row);
    }
    return result;
  }

  private mapNews(items: NbaNewsItem[]): FeedRow[] {
    const result: FeedRow[] = [];
    for (const n of items) {
      const row: FeedRow = new FeedRow();
      row.tid = n.tid;
      row.title = n.title;
      row.tag = 'NBA';
      row.time = n.publishTime.length >= 16 ? n.publishTime.substring(5, 16) : n.publishTime;
      row.meta = `${compactCount(n.replies)} 回复 · ${compactCount(n.lights)} 亮`;
      row.cover = n.img;
      result.push(row);
    }
    return result;
  }

  /** 未开赛/未来在前（升序），往期在后（降序） */
  private orderDays(raw: MatchDay[]): MatchDay[] {
    const now: Date = new Date();
    const y: number = now.getFullYear();
    const mo: number = now.getMonth() + 1;
    const da: number = now.getDate();
    const todayStr: string = `${y}${mo < 10 ? '0' + mo : mo}${da < 10 ? '0' + da : da}`;
    const upcoming: MatchDay[] = [];
    const past: MatchDay[] = [];
    for (const day of raw) {
      if (day.day >= todayStr) {
        upcoming.push(day);
      } else {
        past.push(day);
      }
    }
    const result: MatchDay[] = upcoming;
    for (let i = past.length - 1; i >= 0; i--) {
      result.push(past[i]);
    }
    return result;
  }

  /**
   * 加载当前频道数据
   * @param animate 频道切换场景（保留旧内容、新内容滑入淡入）
   */
  private async loadActive(animate: boolean): Promise<void> {
    const ch: ChannelDef = ChannelCatalog.find(this.activeChannelId);
    this.loadSeq = this.loadSeq + 1;
    const seq: number = this.loadSeq;
    const keepContent: boolean = animate && this.state === LoadState.Ready;
    this.pageIndex = 0;
    this.cursor = '';
    this.hasMore = false;
    if (!keepContent) {
      this.rows = [];
      this.ranks = [];
      this.days = [];
      this.strip = [];
      this.activeKind = ch.kind;
      this.activeLeague = ch.matchLeague;
      this.staleTip = false;
      // 缓存优先：下拉刷新（refreshing=true）时用户明确要新数据，跳过缓存直取网络
      if (!this.refreshing) {
        await this.renderFromCache(ch.id, seq);
      }
      if (this.state !== LoadState.Ready) {
        this.state = LoadState.Loading;
      }
    }
    try {
      let newRows: FeedRow[] = [];
      let newRanks: HotRankItem[] = [];
      let newDays: MatchDay[] = [];
      let newStrip: StripItem[] = [];
      let newCursor: string = '';
      let newHasMore: boolean = false;
      let newPage: number = 0;
      if (ch.kind === ChannelKind.HOT) {
        newRanks = await HupuApi.getHotRanks();
      } else if (ch.kind === ChannelKind.SCHEDULE) {
        newDays = this.orderDays(await NbaApi.getSchedule());
      } else if (ch.kind === ChannelKind.NBA) {
        newRows = this.mapNews(await NbaApi.getNews());
      } else {
        const res: ThreadListPage = ch.kind === ChannelKind.RECOMMEND
          ? await HupuApi.getWalkingStreet(1, '')
          : await HupuApi.getTopicThreads(ch.topicId, 1, '');
        newRows = this.mapThreads(res.items, ch.id === 'recommend');
        newCursor = res.cursor;
        newHasMore = res.hasMore;
        newPage = 1;
      }
      if (ch.matchLeague.length > 0) {
        try {
          // 比赛条最多展示 4 场
          const all: StripItem[] = await this.loadStrip(ch.matchLeague, ch.name);
          newStrip = all.length > 4 ? all.slice(0, 4) : all;
        } catch (e) {
          newStrip = [];
        }
      }
      if (seq !== this.loadSeq) {
        return;
      }
      if (keepContent) {
        // 入场起始态：不可见 + 从切换反方向进入
        this.contentAlpha = 0;
        this.enterOffsetX = this.lastSwitchDir > 0 ? 36 : -36;
      }
      this.rows = newRows;
      this.ranks = newRanks;
      this.days = newDays;
      this.strip = newStrip;
      this.activeKind = ch.kind;
      this.activeLeague = ch.matchLeague;
      this.pageIndex = newPage;
      this.cursor = newCursor;
      this.hasMore = newHasMore;
      const empty: boolean = newRows.length === 0 && newRanks.length === 0 && newDays.length === 0;
      this.state = empty ? LoadState.Empty : LoadState.Ready;
      this.lastLoadedChannelId = ch.id;
      this.staleTip = false;
      this.saveChannelCache(ch.id, newRows, newRanks, newDays, newStrip, newCursor, newHasMore, newPage);
      if (keepContent) {
        // 延迟一帧：等起始态渲染后再播入场动画（同一同步块内启动会被吞掉）
        const targetSeq: number = seq;
        setTimeout(() => {
          if (targetSeq !== this.loadSeq) {
            return;
          }
          this.getUIContext().animateTo({ duration: 220, curve: Curve.FastOutSlowIn }, () => {
            this.contentAlpha = 1;
            this.enterOffsetX = 0;
          });
        }, 16);
      } else {
        this.contentAlpha = 1;
        this.enterOffsetX = 0;
      }
    } catch (e) {
      if (seq === this.loadSeq) {
        if (this.state === LoadState.Ready) {
          // 缓存内容已在渲染：保持展示 + 提示"稍早内容"，不显示错误页
          this.staleTip = true;
          this.lastLoadedChannelId = ch.id;
        } else {
          this.state = LoadState.Error;
          this.contentAlpha = 1;
          this.enterOffsetX = 0;
          this.lastLoadedChannelId = ch.id;
        }
      }
    }
    this.refreshing = false;
  }

  /** 缓存优先：读取频道快照并立即渲染（网络成功后会被静默替换） */
  /** 写频道缓存（fire-and-forget，失败静默） */
  private saveChannelCache(channelId: string, rows: FeedRow[], ranks: HotRankItem[], days: MatchDay[],
    strip: StripItem[], cursor: string, hasMore: boolean, page: number): void {
    const data: HomeCacheData = new HomeCacheData();
    data.rows = rows;
    data.ranks = ranks;
    data.days = days;
    data.strip = strip;
    data.cursor = cursor;
    data.hasMore = hasMore;
    data.page = page;
    CacheStore.put(this.getCtx(), `home/${channelId}`, JSON.stringify(data));
  }

  private async renderFromCache(channelId: string, seq: number): Promise<void> {
    let cached: CachedPayload | null = null;
    try {
      cached = await CacheStore.get(this.getCtx(), `home/${channelId}`);
    } catch (e) {
    }
    if (cached === null || seq !== this.loadSeq) {
      return;
    }
    try {
      const data = JSON.parse(cached.json) as HomeCacheData;
      if (!data) {
        return;
      }
      this.rows = data.rows || [];
      this.ranks = data.ranks || [];
      this.days = data.days || [];
      this.strip = data.strip || [];
      this.cursor = data.cursor || '';
      this.hasMore = data.hasMore === true;
      this.pageIndex = data.page || 0;
      const empty: boolean = this.rows.length === 0 && this.ranks.length === 0 && this.days.length === 0;
      this.state = empty ? LoadState.Empty : LoadState.Ready;
      this.staleTip = true;
      this.contentAlpha = 1;
      this.enterOffsetX = 0;
    } catch (e) {
      // 缓存损坏：忽略，走正常网络加载
    }
  }

  private async loadMore(): Promise<void> {
    if (this.loadingMore || !this.hasMore || this.state !== LoadState.Ready) {
      return;
    }
    const ch: ChannelDef = ChannelCatalog.find(this.activeChannelId);
    if (ch.kind !== ChannelKind.TOPIC && ch.kind !== ChannelKind.RECOMMEND) {
      return;
    }
    this.loadingMore = true;
    const seq: number = this.loadSeq;
    try {
      const res: ThreadListPage = ch.kind === ChannelKind.RECOMMEND
        ? await HupuApi.getWalkingStreet(this.pageIndex + 1, this.cursor)
        : await HupuApi.getTopicThreads(ch.topicId, this.pageIndex + 1, this.cursor);
      if (seq !== this.loadSeq) {
        return;
      }
      this.rows = this.rows.concat(this.mapThreads(res.items, this.activeChannelId === 'recommend'));
      this.pageIndex = this.pageIndex + 1;
      this.cursor = res.cursor;
      this.hasMore = res.hasMore;
    } catch (e) {
    }
    this.loadingMore = false;
  }

  /** 加载频道比赛条：篮球（NBA/CBA）取最相关比赛日；足球取最相关比赛日 */
  private async loadStrip(league: string, channelName: string): Promise<StripItem[]> {
    const result: StripItem[] = [];
    if (league === 'soccer') {
      const list: SoccerMatchItem[] = await SoccerApi.getRelevantMatches();
      for (const m of list) {
        const s: StripItem = new StripItem();
        s.matchId = m.matchId;
        s.title = m.title;
        s.homeName = m.homeName;
        s.awayName = m.awayName;
        s.homeLogo = m.homeLogo;
        s.awayLogo = m.awayLogo;
        s.homeScore = m.homeScore;
        s.awayScore = m.awayScore;
        s.stage = m.title;
        s.leagueName = channelName;
        s.league = 'soccer';
        s.done = m.statusId === 4 || m.statusTxt.indexOf('结束') >= 0;
        s.timeText = m.timeText;
        s.pv = m.pv;
        result.push(s);
      }
      return result;
    }
    const days: MatchDay[] = league === 'cba' ? await NbaApi.getCbaSchedule() : await NbaApi.getSchedule();
    const day: MatchDay | null = this.pickDay(days);
    if (day === null) {
      return result;
    }
    for (const m of day.matches) {
      const s: StripItem = new StripItem();
      s.matchId = m.matchId;
      s.title = m.stage;
      s.homeName = m.homeName;
      s.awayName = m.awayName;
      s.homeLogo = m.homeLogo;
      s.awayLogo = m.awayLogo;
      s.homeScore = m.homeScore;
      s.awayScore = m.awayScore;
      s.homeTeamId = m.homeTeamId;
      s.awayTeamId = m.awayTeamId;
      s.stage = m.stage;
      s.leagueName = league === 'cba' ? 'CBA' : 'NBA';
      s.league = league;
      s.done = m.status === 'COMPLETED';
      s.timeText = m.statusDesc.length > 0
        ? m.statusDesc
        : (m.matchTime.length >= 16 ? m.matchTime.substring(11, 16) : '');
      result.push(s);
    }
    return result;
  }

  /** 选最相关比赛日：今天 > 最近未来 > 最近过去 */
  private pickDay(days: MatchDay[]): MatchDay | null {
    if (days.length === 0) {
      return null;
    }
    const now: Date = new Date();
    const y: number = now.getFullYear();
    const mo: number = now.getMonth() + 1;
    const da: number = now.getDate();
    const todayStr: string = `${y}${mo < 10 ? '0' + mo : mo}${da < 10 ? '0' + da : da}`;
    let future: MatchDay | null = null;
    let past: MatchDay | null = null;
    for (const d of days) {
      if (d.day === todayStr) {
        return d;
      }
      if (d.day > todayStr) {
        if (future === null || d.day < future.day) {
          future = d;
        }
      } else {
        if (past === null || d.day > past.day) {
          past = d;
        }
      }
    }
    return future !== null ? future : past;
  }

  /** 点击比赛条：篮球已完赛 → 球员评分页；足球已完赛 → 战报页 */
  private openStrip(s: StripItem): void {
    if (!s.done) {
      return;
    }
    const param: string = `${s.matchId}||${s.homeTeamId}||${s.awayTeamId}||${s.homeName}||${s.awayName}||${s.homeScore}||${s.awayScore}||${s.homeLogo}||${s.awayLogo}||${s.stage}||${s.leagueName}`;
    if (s.league === 'soccer') {
      this.pageStack.pushPathByName(RouteName.MATCH_REPORT, param);
      return;
    }
    this.pageStack.pushPathByName(RouteName.MATCH_SCORE, param);
  }

  private indexOfChannel(id: string): number {
    for (let i = 0; i < this.channels.length; i++) {
      if (this.channels[i].id === id) {
        return i;
      }
    }
    return -1;
  }

  /** 切换频道并同步频道栏位置 */
  private switchToIndex(idx: number): void {
    if (idx < 0 || idx >= this.channels.length) {
      return;
    }
    const id: string = this.channels[idx].id;
    const curIdx: number = this.indexOfChannel(this.activeChannelId);
    if (curIdx >= 0 && idx !== curIdx) {
      this.lastSwitchDir = idx > curIdx ? 1 : -1;
    }
    if (id !== this.activeChannelId) {
      AppStorage.setOrCreate<string>('activeChannelId', id);
    }
    try {
      this.channelScroller.scrollToIndex(idx, true, ScrollAlign.CENTER);
    } catch (e) {
    }
  }

  private ensureThresholds(): void {
    if (this.tapThresholdPx <= 0) {
      try {
        this.tapThresholdPx = this.getUIContext().vp2px(10);
        this.swipeThresholdPx = this.getUIContext().vp2px(28);
        this.resolvePx = this.getUIContext().vp2px(10);
      } catch (e) {
        this.tapThresholdPx = 26;
        this.swipeThresholdPx = 74;
        this.resolvePx = 26;
      }
    }
  }

  /**
   * 内容区触摸：横向跟手切频道；纵向不拦截，交给列表滚动。
   * 旧实现里父容器 onTouch 与列表滚动竞争同一事件流，横向滑动经常被列表滚动吃掉（"划不动"）。
   * 现改为：先小窗内判定方向，确认横向后列表侧 onTouchIntercept 返回 Block 让出事件，跟手不被抢。
   */
  private onContentTouch(e: TouchEvent): void {
    this.ensureThresholds();
    if (e.type === TouchType.Down) {
      this.scrollArmed = false;
      if (e.touches.length !== 1 || this.state !== LoadState.Ready) {
        this.panState = 0;
        return;
      }
      this.panState = 1;
      this.swipeStartX = e.touches[0].windowX;
      this.swipeStartY = e.touches[0].windowY;
      this.swipeLastX = this.swipeStartX;
      this.swipeLastY = this.swipeStartY;
    } else if (e.type === TouchType.Move) {
      if (e.touches.length !== 1) {
        this.panState = 0;
        return;
      }
      this.swipeLastX = e.touches[0].windowX;
      this.swipeLastY = e.touches[0].windowY;
      const dx: number = this.swipeLastX - this.swipeStartX;
      const dy: number = this.swipeLastY - this.swipeStartY;
      const absX: number = dx < 0 ? -dx : dx;
      const absY: number = dy < 0 ? -dy : dy;
      if (this.panState === 1 && (absX > this.resolvePx || absY > this.resolvePx)) {
        if (absX > absY) {
          // 横向：进入跟手（列表侧由 onTouchIntercept 感知 panState 后主动放行事件）
          this.panState = 2;
        } else {
          // 纵向：放弃手势，滚动完全交给列表
          this.panState = 3;
        }
      }
      if (this.panState === 2) {
        // 1:1 跟手位移，满幅 ±56vp
        let off: number = dx;
        if (off > 56) {
          off = 56;
        }
        if (off < -56) {
          off = -56;
        }
        this.enterOffsetX = off;
      }
    } else {
      const curPan: number = this.panState;
      this.panState = 0;
      if (curPan !== 2) {
        return;
      }
      const dx: number = this.swipeLastX - this.swipeStartX;
      const dy: number = this.swipeLastY - this.swipeStartY;
      const absX: number = dx < 0 ? -dx : dx;
      const absY: number = dy < 0 ? -dy : dy;
      let switched: boolean = false;
      if (absX >= this.swipeThresholdPx && absX > absY) {
        const idx: number = this.indexOfChannel(this.activeChannelId);
        if (idx >= 0) {
          // 立即播放旧内容滑出动画（不等网络），方向与手势一致
          const dir: number = dx < 0 ? -1 : 1;
          this.getUIContext().animateTo({ duration: 140, curve: Curve.EaseOut }, () => {
            this.contentAlpha = 0;
            this.enterOffsetX = 48 * dir;
          });
          if (dx < 0) {
            this.switchToIndex(idx + 1);
          } else {
            this.switchToIndex(idx - 1);
          }
          switched = true;
        }
      }
      if (!switched && this.enterOffsetX !== 0) {
        // 未达标：弹性回位
        this.getUIContext().animateTo({ duration: 160, curve: Curve.FastOutSlowIn }, () => {
          this.enterOffsetX = 0;
        });
      }
    }
  }

  /**
   * 列表触摸拦截：横向跟手期间返回 Block，让列表不再接收触摸、滚动立即停止，
   * 事件交回父容器完成切频道手势（解决列表滚动与横向滑动互相抢事件"划不动"）。
   */
  private feedTouchIntercept(): HitTestMode {
    return this.panState === 2 ? HitTestMode.Block : HitTestMode.Default;
  }

  /** 有效点击：位移小 + 列表未发生滚动 + 按压时长 < 400ms（防滑动/滚动误触跳帖） */
  private isValidTap(): boolean {
    return !this.itemMoved && !this.scrollArmed && (Date.now() - this.pressStartTs) < 400;
  }

  /** 列表项按下 */
  private itemTouchDown(e: TouchEvent): void {
    this.ensureThresholds();
    this.pressStartTs = Date.now();
    if (e.touches.length > 0) {
      this.itemStartX = e.touches[0].windowX;
      this.itemStartY = e.touches[0].windowY;
      this.itemMoved = false;
    }
  }

  /** 列表项移动：超过点击阈值即标记为滑动 */
  private itemTouchMove(e: TouchEvent): void {
    if (this.itemMoved || e.touches.length === 0) {
      return;
    }
    const dx: number = e.touches[0].windowX - this.itemStartX;
    const dy: number = e.touches[0].windowY - this.itemStartY;
    const absX: number = dx < 0 ? -dx : dx;
    const absY: number = dy < 0 ? -dy : dy;
    if (absX > this.tapThresholdPx || absY > this.tapThresholdPx) {
      this.itemMoved = true;
    }
  }

  @Builder
  HeaderBar() {
    Row({ space: 8 }) {
      Text('Hupu Luna')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.brand_primary'))
        .maxLines(1)
      Row() {
        Text('搜索帖子、球队、球员')
          .fontSize(12)
          .fontColor($r('app.color.text_tertiary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .layoutWeight(1)
      .height(34)
      .padding({ left: 12, right: 12 })
      .backgroundColor($r('app.color.tag_bg'))
      .borderRadius(17)
      .onClick(() => {
        this.pageStack.pushPathByName(RouteName.SEARCH, '');
      })

      Text('搜索')
        .fontSize(13)
        .fontColor(Color.White)
        .padding({ left: 14, right: 14, top: 8, bottom: 8 })
        .backgroundColor($r('app.color.brand_primary'))
        .borderRadius(17)
        .onClick(() => {
          this.pageStack.pushPathByName(RouteName.SEARCH, '');
        })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ left: Spacing.lg, right: Spacing.lg, top: 10, bottom: 6 })
  }

  @Builder
  ChannelTab(c: ChannelDef) {
    Column({ space: 4 }) {
      Text(c.name)
        .fontSize(15)
        .fontWeight(this.activeChannelId === c.id ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.activeChannelId === c.id ? $r('app.color.text_primary') : $r('app.color.text_secondary'))
        .maxLines(1)
      Row()
        .width(20)
        .height(3)
        .borderRadius(2)
        .backgroundColor(this.activeChannelId === c.id ? $r('app.color.brand_primary') : Color.Transparent)
    }
    .onClick(() => {
      this.switchToIndex(this.indexOfChannel(c.id));
    })
  }

  @Builder
  Footer(msg: string) {
    Text(msg)
      .fontSize(12)
      .fontColor($r('app.color.text_tertiary'))
      .width('100%')
      .textAlign(TextAlign.Center)
      .padding({ top: 16, bottom: 24 })
  }

  @Builder
  StripCard(s: StripItem) {
    Column({ space: 6 }) {
      if (s.title.length > 0) {
        Text(s.title)
          .fontSize(11)
          .fontColor($r('app.color.text_tertiary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .textAlign(TextAlign.Center)
      }
      Row() {
        Row({ space: 6 }) {
          Text(s.homeName)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          ImageKnifeComponent({
            imageKnifeOption: {
              loadSrc: s.homeLogo,
              objectFit: ImageFit.Contain
            }
          })
            .width(28)
            .height(28)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.End)

        Column({ space: 2 }) {
          if (s.done) {
            Text(`${s.homeScore} - ${s.awayScore}`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
          } else {
            Text(s.timeText.length > 0 ? s.timeText : '未开始')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_secondary'))
          }
          if (s.done && s.pv.length > 0) {
            Text(s.pv)
              .fontSize(10)
              .fontColor($r('app.color.score_blue'))
              .maxLines(1)
          } else if (s.done && s.league !== 'soccer') {
            Text('球员评分 ›')
              .fontSize(10)
              .fontColor($r('app.color.score_blue'))
          }
        }
        .width(116)
        .alignItems(HorizontalAlign.Center)

        Row({ space: 6 }) {
          ImageKnifeComponent({
            imageKnifeOption: {
              loadSrc: s.awayLogo,
              objectFit: ImageFit.Contain
            }
          })
            .width(28)
            .height(28)
          Text(s.awayName)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Start)
      }
      .width('100%')
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
  }

  @Builder
  FeedCard(row: FeedRow) {
    if (row.officialCard) {
      this.OfficialFeedCard(row)
    } else {
      this.CompactFeedCard(row)
    }
  }

  @Builder
  OfficialFeedCard(row: FeedRow) {
    Column({ space: 8 }) {
      // 作者行：头像 + 昵称 + 时间
      Row({ space: 6 }) {
        if (row.userHeader.length > 0) {
          ImageKnifeComponent({
            imageKnifeOption: {
              loadSrc: thumbUrl(row.userHeader, 60),
              objectFit: ImageFit.Cover,
              border: { radius: 10 }
            }
          })
            .width(20)
            .height(20)
        }
        Text(row.author.length > 0 ? row.author : '虎扑JR')
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
        Text(row.time)
          .fontSize(11)
          .fontColor($r('app.color.text_tertiary'))
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 标题
      Text(row.title)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .lineHeight(24)
        .fontColor($r('app.color.text_primary'))
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      // 图片区：多图 3 列网格 / 单图大图
      if (row.pics.length >= 3) {
        Row({ space: 4 }) {
          ForEach(row.pics, (img: string, idx: number) => {
            ImageKnifeComponent({
              imageKnifeOption: {
                loadSrc: thumbUrl(img, 300),
                objectFit: ImageFit.Cover,
                border: { radius: 6 }
              }
            })
              .layoutWeight(1)
              .aspectRatio(1)
          }, (img: string, idx: number) => `p${idx}_${img}`)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
      } else if (row.pics.length === 2) {
        Row({ space: 4 }) {
          ForEach(row.pics, (img: string, idx: number) => {
            ImageKnifeComponent({
              imageKnifeOption: {
                loadSrc: thumbUrl(img, 300),
                objectFit: ImageFit.Cover,
                border: { radius: 6 }
              }
            })
              .layoutWeight(1)
              .aspectRatio(1.33)
          }, (img: string, idx: number) => `p${idx}_${img}`)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
      } else if (row.pics.length === 1 || (row.pics.length === 0 && row.cover.length > 0)) {
        Stack({ alignContent: Alignment.BottomEnd }) {
          ImageKnifeComponent({
            imageKnifeOption: {
              loadSrc: thumbUrl(row.pics.length === 1 ? row.pics[0] : row.cover, 480),
              objectFit: ImageFit.Cover,
              border: { radius: 6 }
            }
          })
            .width('100%')
            .height(180)
          if (row.isVideo) {
            Text(row.videoDur.length > 0 ? row.videoDur : '视频')
              .fontSize(10)
              .fontColor(Color.White)
              .backgroundColor('#80000000')
              .borderRadius(3)
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .margin(6)
          }
        }
        .width('100%')
      }

      // 底部数据栏（官方三列风格，用文字标签避免图标乱码）
      Row() {
        Blank()
        Text(`${row.meta}`)
          .fontSize(11)
          .fontColor($r('app.color.text_tertiary'))
      }
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ top: 12, bottom: 12 })
  }

  /** 紧凑卡（NBA资讯/其它频道原有样式） */
  @Builder
  CompactFeedCard(row: FeedRow) {
    Row({ space: 10 }) {
      Column({ space: 6 }) {
        Text(row.title)
          .fontSize(FontSize.title)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Row({ space: 8 }) {
          if (row.tag.length > 0) {
            Text(row.tag)
              .fontSize(11)
              .fontColor($r('app.color.brand_primary'))
              .maxLines(1)
          }
          if (row.author.length > 0) {
            Text(row.author)
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
          } else {
            Blank().layoutWeight(1)
          }
          Text(row.time)
            .fontSize(11)
            .fontColor($r('app.color.text_tertiary'))
        }
        .width('100%')
        Row({ space: 10 }) {
          Blank()
          Text(row.meta)
            .fontSize(11)
            .fontColor($r('app.color.text_tertiary'))
        }
        .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (row.cover.length > 0) {
        Stack({ alignContent: Alignment.BottomEnd }) {
          ImageKnifeComponent({
            imageKnifeOption: {
              loadSrc: thumbUrl(row.cover, 240),
              objectFit: ImageFit.Cover,
              border: { radius: Radius.sm }
            }
          })
            .width(96)
            .height(72)
          if (row.isVideo) {
            Text(row.videoDur.length > 0 ? row.videoDur : '视频')
              .fontSize(10)
              .fontColor(Color.White)
              .backgroundColor('#80000000')
              .borderRadius(3)
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .margin(4)
          }
        }
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .padding({ top: 12, bottom: 12 })
  }

  @Builder
  RankRow(item: HotRankItem) {
    Row({ space: 12 }) {
      Text(`${item.rank}`)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(item.rank <= 3 ? $r('app.color.brand_primary') : $r('app.color.text_tertiary'))
        .width(26)
        .textAlign(TextAlign.Center)
      Column({ space: 4 }) {
        Text(item.tagName)
          .fontSize(15)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Row({ space: 8 }) {
          if (item.competitionType.length > 0) {
            Text(item.competitionType)
              .fontSize(10)
              .fontColor($r('app.color.brand_primary'))
              .padding({ left: 5, right: 5, top: 1, bottom: 1 })
              .backgroundColor($r('app.color.tag_bg'))
              .borderRadius(4)
          }
          Text(`热度 ${formatHeat(item.heat)}`)
            .fontSize(11)
            .fontColor($r('app.color.text_secondary'))
          if (item.updateDesc.length > 0) {
            Text(item.updateDesc)
              .fontSize(11)
              .fontColor($r('app.color.text_tertiary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
          }
        }
        .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text('›')
        .fontSize(18)
        .fontColor($r('app.color.text_tertiary'))
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ top: 12, bottom: 12 })
  }

  @Builder
  MatchRow(m: MatchItem) {
    Column({ space: 6 }) {
      Row() {
        Row({ space: 6 }) {
          Text(m.homeName.length > 0 ? m.homeName : '主队')
            .fontSize(14)
            .fontColor($r('app.color.text_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          ImageKnifeComponent({
            imageKnifeOption: {
              loadSrc: m.homeLogo,
              objectFit: ImageFit.Contain
            }
          })
            .width(26)
            .height(26)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.End)

        Column({ space: 2 }) {
          Text(m.homeScore.length > 0 || m.awayScore.length > 0 ? `${m.homeScore} - ${m.awayScore}` : m.statusCn)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(m.homeScore.length > 0 ? $r('app.color.text_primary') : $r('app.color.text_secondary'))
          Text(m.homeScore.length > 0 ? m.statusCn : (m.statusDesc.length > 0 ? m.statusDesc : (m.matchTime.length >= 16 ? m.matchTime.substring(11, 16) : '')))
            .fontSize(10)
            .fontColor($r('app.color.text_tertiary'))
            .maxLines(1)
        }
        .width(112)
        .alignItems(HorizontalAlign.Center)

        Row({ space: 6 }) {
          ImageKnifeComponent({
            imageKnifeOption: {
              loadSrc: m.awayLogo,
              objectFit: ImageFit.Contain
            }
          })
            .width(26)
            .height(26)
          Text(m.awayName.length > 0 ? m.awayName : '客队')
            .fontSize(14)
            .fontColor($r('app.color.text_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Start)
      }
      .width('100%')

      Row() {
        Text(m.stage)
          .fontSize(10)
          .fontColor($r('app.color.text_tertiary'))
        Blank()
        if (m.status === 'COMPLETED') {
          Text('球员评分 ›')
            .fontSize(10)
            .fontColor($r('app.color.brand_primary'))
        }
      }
      .width('100%')
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .onClick(() => {
      if (m.status === 'COMPLETED') {
        const p: string = `${m.matchId}||${m.homeTeamId}||${m.awayTeamId}||${m.homeName}||${m.awayName}||${m.homeScore}||${m.awayScore}||${m.homeLogo}||${m.awayLogo}||${m.stage}||NBA`;
        this.pageStack.pushPathByName(RouteName.MATCH_SCORE, p);
      }
    })
  }

  @Builder
  ContentArea() {
    if (this.state === LoadState.Ready) {
      if (this.activeKind === ChannelKind.HOT) {
        List({ space: 0 }) {
          ForEach(this.ranks, (item: HotRankItem) => {
            ListItem() {
              Column() {
                this.RankRow(item)
                Divider().color($r('app.color.divider'))
              }
              .padding({ left: Spacing.lg, right: Spacing.lg })
              .backgroundColor($r('app.color.bg_card'))
              .onTouch((e: TouchEvent) => {
                if (e.type === TouchType.Down) {
                  this.itemTouchDown(e);
                } else if (e.type === TouchType.Move) {
                  this.itemTouchMove(e);
                } else if (e.type === TouchType.Up) {
                  if (this.isValidTap()) {
                    this.pageStack.pushPathByName(RouteName.TAG_THREADS, `${item.tagId}|${item.tagName}`);
                  }
                }
              })
            }
          }, (item: HotRankItem) => `rank_${item.tagId}`)
          ListItem() {
            this.Footer('榜单每 10 分钟更新')
          }
        }
        .cachedCount(3)
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .onTouchIntercept((): HitTestMode => {
          return this.feedTouchIntercept();
        })
        .onScrollStart(() => {
          this.scrollArmed = true;
        })
        .onScrollStop(() => {
          this.scrollArmed = false;
        })
      } else if (this.activeKind === ChannelKind.SCHEDULE) {
        Refresh({ refreshing: $$this.refreshing }) {
          List({ space: 0 }) {
            ForEach(this.days, (day: MatchDay) => {
              ListItem() {
                Row() {
                  Text(day.dayLabel.length > 0 ? day.dayLabel : day.day)
                    .fontSize(12)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.text_secondary'))
                }
                .width('100%')
                .padding({ left: Spacing.lg, right: Spacing.lg, top: 10, bottom: 6 })
                .backgroundColor($r('app.color.bg_page'))
              }

              ForEach(day.matches, (m: MatchItem) => {
                ListItem() {
                  Column() {
                    this.MatchRow(m)
                    Divider().color($r('app.color.divider'))
                  }
                  .padding({ left: Spacing.lg, right: Spacing.lg })
                  .backgroundColor($r('app.color.bg_card'))
                }
              }, (m: MatchItem, idx: number) => `${day.day}_${m.matchId}_${idx}`)
            }, (day: MatchDay) => `day_${day.day}`)
          }
          .cachedCount(3)
          .width('100%')
          .height('100%')
          .scrollBar(BarState.Off)
          .onTouchIntercept((): HitTestMode => {
            return this.feedTouchIntercept();
          })
          .onScrollStart(() => {
            this.scrollArmed = true;
          })
          .onScrollStop(() => {
            this.scrollArmed = false;
          })
        }
        .onRefreshing(() => {
          this.loadActive(false);
        })
        .width('100%')
        .height('100%')
      } else {
        Refresh({ refreshing: $$this.refreshing }) {
          List({ space: 0 }) {
            if (this.strip.length > 0) {
              ForEach(this.strip, (s: StripItem) => {
                ListItem() {
                  Column() {
                    this.StripCard(s)
                    Divider().color($r('app.color.divider'))
                  }
                  .padding({ left: Spacing.lg, right: Spacing.lg })
                  .backgroundColor($r('app.color.bg_card'))
                  .onTouch((e: TouchEvent) => {
                    if (e.type === TouchType.Down) {
                      this.itemTouchDown(e);
                    } else if (e.type === TouchType.Move) {
                      this.itemTouchMove(e);
                    } else if (e.type === TouchType.Up) {
                      if (this.isValidTap()) {
                        this.openStrip(s);
                      }
                    }
                  })
                }
              }, (s: StripItem) => `strip_${s.matchId}`)
            }
            if (this.activeLeague.length > 0) {
              ListItem() {
                Column() {
                  Row({ space: 6 }) {
                    Text('🔥')
                      .fontSize(15)
                    Text('查看近期全部热门比赛')
                      .fontSize(14)
                      .fontWeight(FontWeight.Medium)
                      .fontColor($r('app.color.text_primary'))
                    Text('›')
                      .fontSize(16)
                      .fontColor($r('app.color.text_tertiary'))
                  }
                  .width('100%')
                  .height(46)
                  .justifyContent(FlexAlign.Center)
                  Divider().color($r('app.color.divider'))
                }
                .backgroundColor($r('app.color.bg_card'))
                .onTouch((e: TouchEvent) => {
                  if (e.type === TouchType.Down) {
                    this.itemTouchDown(e);
                  } else if (e.type === TouchType.Move) {
                    this.itemTouchMove(e);
                  } else if (e.type === TouchType.Up) {
                    if (this.isValidTap()) {
                      const name: string = ChannelCatalog.find(this.activeChannelId).name;
                      this.pageStack.pushPathByName(RouteName.MATCH_LIST, `${this.activeLeague}||${name}`);
                    }
                  }
                })
              }
            }
            ForEach(this.rows, (row: FeedRow) => {
              ListItem() {
                Column() {
                  this.FeedCard(row)
                  Divider().color($r('app.color.divider'))
                }
                .padding({ left: Spacing.lg, right: Spacing.lg })
                .backgroundColor($r('app.color.bg_card'))
                .onTouch((e: TouchEvent) => {
                  if (e.type === TouchType.Down) {
                    this.itemTouchDown(e);
                  } else if (e.type === TouchType.Move) {
                    this.itemTouchMove(e);
                  } else if (e.type === TouchType.Up) {
                    if (this.isValidTap() && row.tid.length > 0) {
                      this.pageStack.pushPathByName(RouteName.POST_DETAIL, row.tid);
                    }
                  }
                })
              }
            }, (row: FeedRow, idx: number) => `${row.tid}_${idx}`)
            ListItem() {
              this.Footer(this.hasMore ? '上拉加载更多' : '已经到底了')
            }
          }
          .onReachEnd(() => {
            this.loadMore();
          })
          .cachedCount(3)
          .width('100%')
          .height('100%')
          .scrollBar(BarState.Off)
          .onTouchIntercept((): HitTestMode => {
            return this.feedTouchIntercept();
          })
          .onScrollStart(() => {
            this.scrollArmed = true;
          })
          .onScrollStop(() => {
            this.scrollArmed = false;
          })
        }
        .onRefreshing(() => {
          this.loadActive(false);
        })
        .width('100%')
        .height('100%')
      }
    } else if (this.state === LoadState.Loading) {
      Scroll() {
        FeedSkeleton({ withCover: true, count: 6 })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
    } else {
      StateView({
        state: this.state,
        onRetry: () => {
          this.loadActive(false);
        }
      })
        .width('100%')
        .height('100%')
    }
  }

  build() {
    Column() {
      Column() {
        this.HeaderBar()
      }
      .width('100%')
      .padding({ top: px2vp(this.topAvoidPx) })
      .backgroundColor($r('app.color.bg_page'))

      Row() {
        List({ space: 18, scroller: this.channelScroller }) {
          ForEach(this.channels, (c: ChannelDef, index: number) => {
            ListItem() {
              this.ChannelTab(c)
            }
            .margin({
              left: index === 0 ? Spacing.lg : 0,
              right: index === this.channels.length - 1 ? 4 : 0
            })
          }, (c: ChannelDef) => `ch_${c.id}`)
        }
        .listDirection(Axis.Horizontal)
        .alignListItem(ListItemAlign.Center)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        .height('100%')

        Text('≡')
          .fontSize(20)
          .fontColor($r('app.color.text_secondary'))
          .padding({ left: 8, right: Spacing.lg })
          .onClick(() => {
            this.pageStack.pushPathByName(RouteName.ALL_CHANNELS, '');
          })
      }
      .width('100%')
      .height(40)
      .alignItems(VerticalAlign.Center)

      if (this.staleTip) {
        Row() {
          Text('网络不太顺畅，正在展示稍早内容')
            .fontSize(FontSize.caption)
            .fontColor($r('app.color.text_secondary'))
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .padding({ top: 4, bottom: 4 })
        .backgroundColor($r('app.color.tag_bg'))
      }

      Column() {
        this.ContentArea()
      }
      .layoutWeight(1)
      .width('100%')
      .clip(true)
      .opacity(this.contentAlpha)
      .translate({ x: this.enterOffsetX })
      .onTouch((e: TouchEvent) => {
        this.onContentTouch(e);
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
