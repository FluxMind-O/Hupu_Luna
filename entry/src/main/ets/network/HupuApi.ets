import { HttpManager } from './HttpManager';
import { LinkHealth } from './LinkHealth';
import {
  ThreadListItem,
  ThreadListPage,
  ThreadDetail,
  ReplyItem,
  ReplyListPage,
  ZoneCategory,
  ZoneTopic,
  SearchItem,
  SearchResultPage,
  HotRankItem,
  SubReplyItem,
  UserProfile,
  UserPostItem,
  UserSpaceData,
  TopicInfo
} from '../model/Models';
import { htmlToText, extractImages, formatTime } from '../common/Utils';

const BASE: string = 'https://m.hupu.com';
const PC_BASE: string = 'https://bbs.hupu.com';
const PAGE_SIZE: number = 20;

const DESKTOP_UA: string =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36';

/* PC 站话题页列表解析（SSR HTML 正则提取） */
/** 阿里云 WAF 验证页特征（bbs.hupu.com 高频访问会触发） */
const WAF_MARK: string = 'aliyun_waf';
const ITEM_MARK: string = '<li class="bbs-sl-web-post-body"';
const REG_TITLE: RegExp = new RegExp('href="/(\\d+)\\.html"[^>]*class="p-title"[^>]*>([^<]*)<');
const REG_DATUM: RegExp = new RegExp('class="post-datum">([^<]*)<');
const REG_AUTH: RegExp = new RegExp('class="post-auth"><a[^>]*>([^<]*)<');
const REG_POSTTIME: RegExp = new RegExp('class="post-time">([^<]*)<');

/* PC 话题页头部（专区信息） */
// 名称处常夹 HTML 注释（如 "#<!-- -->NBA2KOL2"），故捕获整段文本后统一清洗
const REG_TOPIC_NAME: RegExp = new RegExp('bbs-sl-web-intro-detail-title">([\\s\\S]{0,60}?)</span>');
const REG_TOPIC_BG: RegExp = new RegExp('class="bbs-sl-web-intro"[^>]*background:[^;]*url\\(&#x27;([^&]+)&#x27;\\)');
const REG_TOPIC_DESC: RegExp = new RegExp(
  'bbs-sl-web-intro-detail-desc-title">([^<]*)</span><span class="bbs-sl-web-intro-detail-desc-text">([\\s\\S]{0,80}?)</span>');
const REG_TOPIC_ADMIN: RegExp = new RegExp(
  'bbs-sl-web-admin-detail-desc-text">([\\s\\S]{0,600}?)</div>');

/* ---------------- 原始响应 DTO ---------------- */

interface WsVideoDto {
  img?: string;
  humanDuration?: string;
  /** 直连播放地址（mp4，带时效 auth_key） */
  url?: string;
  /** 播放量 */
  playNum?: number;
  width?: number;
  height?: number;
}

interface WsPicDto {
  url?: string;
  width?: number;
  height?: number;
}

/** 神回复（亮评） */
interface WsLightReplyDto {
  content?: string;
  replyUserName?: string;
  lightCount?: number;
}

interface WsThreadDto {
  tid?: number;
  title?: string;
  userName?: string;
  userHeader?: string;
  time?: string;
  replies?: number;
  recommendCount?: number;
  /** 分享数 */
  shareNum?: number;
  topicName?: string;
  topicIcon?: string;
  videoThread?: boolean;
  video?: WsVideoDto;
  picList?: WsPicDto[];
  lightReplyResult?: WsLightReplyDto;
}

interface WsDataDto {
  nextPage?: boolean;
  threadList?: WsThreadDto[];
  cursor?: string;
}

interface WsRespDto {
  data?: WsDataDto;
  code?: number;
  msg?: string;
}

interface TtThreadDto {
  tid?: number;
  title?: string;
  replies?: number;
  username?: string;
  recommendNum?: number;
  time?: string;
  isVideo?: boolean;
}

interface TtDataDto {
  count?: number;
  topicThreads?: TtThreadDto[];
  cursor?: string;
}

interface TtRespDto {
  data?: TtDataDto;
  code?: number;
}

interface ThreadUserDto {
  puid?: string;
  username?: string;
  header?: string | null;
}

interface ThreadFInfoDto {
  fid?: string;
  f_name?: string;
}

interface ThreadDetailDto {
  tid?: number;
  title?: string;
  content?: string;
  hits?: string;
  replies?: string;
  lights?: string;
  f_info?: ThreadFInfoDto;
  user?: ThreadUserDto;
}

interface ThreadDataDto {
  t_detail?: ThreadDetailDto;
}

interface ThreadRespDto {
  data?: ThreadDataDto;
  status?: string;
}

/* PC 站（bbs.hupu.com）页面内嵌评论结构 */

interface PcAuthorDto {
  puid?: string;
  puname?: string;
  header?: string;
}

interface PcReplyDto {
  pid?: string;
  content?: string;
  count?: number;
  replyNum?: number;
  createdAtFormat?: string;
  location?: string;
  isStarter?: boolean;
  author?: PcAuthorDto;
}

interface PcRepliesDto {
  count?: number;
  size?: number;
  current?: number;
  total?: number;
  list?: PcReplyDto[];
}

interface PcDetailDto {
  replies?: PcRepliesDto;
  thread?: PcThreadDto;
}

/* PC 站详情页正文结构（L0 兜底数据源） */

interface PcTopicDto {
  name?: string;
  logo?: string;
}

/** 特殊帖正文（二次嵌套 JSON）：比赛卡等 */
interface PcSpecialContentDto {
  team?: string;
  type?: string;
  url?: string;
}

/** PC 站 format 字段（JSON 字符串）内的视频信息 */
interface PcVideoInfoDto {
  coverUrl?: string;
  remoteUrl?: string;
  width?: number;
  height?: number;
}

interface PcFormatDto {
  videoInfo?: PcVideoInfoDto;
}

interface PcThreadDto {
  tid?: string;
  title?: string;
  content?: string;
  lights?: number;
  replies?: number;
  read?: number;
  createdAtFormat?: string;
  location?: string;
  author?: PcAuthorDto;
  fid?: string;
  topic?: PcTopicDto;
  /** 视频帖标记 + 直连播放地址 + 封面（m 站详情 API 无此三项，故详情以 PC 站为主链路） */
  hasVideo?: boolean;
  video?: string;
  videoCover?: string;
  /** 作者端格式 JSON，内含 videoInfo 原始宽高 */
  format?: string;
}

interface PcPagePropsDto {
  detail?: PcDetailDto;
}

interface PcPropsDto {
  pageProps?: PcPagePropsDto;
}

interface PcNextRespDto {
  props?: PcPropsDto;
}

/* 用户主页（m.hupu.com/user/{puid} 公开页） */

interface UspReputationDto {
  value?: number;
}

interface UspUserDto {
  puid?: string;
  nickname?: string;
  header?: string;
  level?: number;
  bbsUserLevelDesc?: string;
  reputation?: UspReputationDto;
  be_light_count?: number;
  be_follow_count?: number;
  follow_count?: number;
  be_recommend_count?: number;
  is_self?: number;
}

interface UspThreadDto {
  tid?: number;
  title?: string;
  topic_name?: string;
  topic_id?: number;
  visits?: number;
  replies?: number;
  lights?: number;
  share_num?: number;
  create_time?: number;
  lastpost_time?: number;
  pics?: WsPicDto[];
}

interface UspReplyDto {
  pid?: number;
  tid?: number;
  content?: string;
  score?: number;
  createTime?: number;
}

interface UspPagePropsDto {
  puid?: string;
  userInfoData?: UspUserDto;
  threadList?: UspThreadDto[];
  replyList?: UspReplyDto[];
}

interface UspPropsDto {
  pageProps?: UspPagePropsDto;
}

interface UspNextRespDto {
  props?: UspPropsDto;
}

interface NextZoneTopicDto {
  topicId?: number;
  topicName?: string;
  topicLogo?: string;
  count?: string;
}

interface NextZoneCategoryDto {
  categoryId?: number;
  name?: string;
  topicList?: NextZoneTopicDto[];
}

interface NextPagePropsDto {
  data?: NextZoneCategoryDto[];
}

interface NextPropsDto {
  pageProps?: NextPagePropsDto;
}

interface NextRespDto {
  props?: NextPropsDto;
}

interface SearchItemDto {
  id?: number;
  replies?: number;
  recNum?: number;
  lights?: number;
  title?: string;
  content?: string;
  picture?: string;
  username?: string;
  forum_name?: string;
  /** 板块 fid（官方资讯历史按此过滤到目标频道） */
  fid?: number;
  addtime?: number;
}

interface SearchInnerDto {
  count?: number;
  hasNextPage?: number;
  data?: SearchItemDto[];
}

interface SearchResultDto {
  result?: SearchInnerDto;
}

interface SearchRespDto {
  data?: SearchResultDto;
  status?: string;
}

/* 热榜（m.hupu.com/hot 页面内嵌） */

interface HotRankDto {
  rank?: number;
  tagId?: number;
  tagName?: string;
  heat?: number;
  competitionType?: string;
  tagUpdateDesc?: string;
}

interface HotPagePropsDto {
  res?: HotRankDto[];
}

interface HotPropsDto {
  pageProps?: HotPagePropsDto;
}

interface HotPageRespDto {
  props?: HotPropsDto;
}

/* 话题帖子流（tagThreads API） */

interface TagThreadDto {
  tid?: number;
  title?: string;
  userName?: string;
  userHeader?: string;
  time?: string;
  replies?: number;
  recommendCount?: number;
  videoThread?: boolean;
  video?: WsVideoDto;
  picList?: WsPicDto[];
}

interface TagThreadsDataDto {
  nextPage?: boolean;
  threadList?: TagThreadDto[];
  cursor?: string;
}

interface TagThreadsRespDto {
  data?: TagThreadsDataDto;
}

/* 楼中楼（bbs-reply-detail API） */

interface SubReplyUserDto {
  puid?: number;
  username?: string;
  header?: string | null;
  createDt?: string;
}

interface SubReplyDto {
  pid?: number;
  content?: string;
  lights?: number;
  replies?: number;
  lz?: boolean;
  user?: SubReplyUserDto;
}

interface ReplyDetailDataDto {
  replies?: SubReplyDto[];
}

interface ReplyDetailRespDto {
  data?: ReplyDetailDataDto;
}

/* ---------------- API ---------------- */

export class HupuApi {
  /** PC 站页面在途请求（详情/评论共用去重，键=URL） */
  private static pcPageInflight: Map<string, Promise<string>> = new Map<string, Promise<string>>();

  /** 步行街热帖流 */
  static async getWalkingStreet(page: number, cursor: string): Promise<ThreadListPage> {
    const url: string = `${BASE}/api/v2/bbs/walkingStreet/threads?page=${page}&cursor=${cursor}`;
    const resp = await HttpManager.getJson<WsRespDto>(url);
    const data = resp.data;
    const result: ThreadListPage = new ThreadListPage();
    if (!data || !data.threadList) {
      throw new Error('热帖数据为空');
    }
    for (const d of data.threadList) {
      result.items.push(HupuApi.mapWsItem(d));
    }
    result.hasMore = data.nextPage === true;
    result.cursor = data.cursor ?? '';
    return result;
  }

  /** 分区帖子流 */
  static async getTopicThreads(topicId: number, page: number, cursor: string): Promise<ThreadListPage> {
    const url: string = `${BASE}/api/v2/bbs/topicThreads?topicId=${topicId}&page=${page}&cursor=${cursor}`;
    const resp = await HttpManager.getJson<TtRespDto>(url);
    const data = resp.data;
    const result: ThreadListPage = new ThreadListPage();
    if (!data || !data.topicThreads) {
      throw new Error('板块数据为空');
    }
    for (const d of data.topicThreads) {
      result.items.push(HupuApi.mapTtItem(d));
    }
    result.hasMore = result.items.length >= PAGE_SIZE;
    result.cursor = data.cursor ?? '';
    return result;
  }

  /**
   * 帖子详情：PC 站优先，失败降级 m 站 API。
   * 关键：m 站 bbs-thread API **不返回 video / videoCover / hasVideo**，
   * 视频帖走 m 站会导致"详情页看不到视频"；PC 站详情页内嵌数据含完整视频字段，
   * 故主链路改为 PC 站（与评论同源，可共用一次请求）。
   */
  static async getThreadDetail(tid: string): Promise<ThreadDetail> {
    const linkKey: string = 'thread-detail';
    if (LinkHealth.allow(linkKey)) {
      try {
        const detail: ThreadDetail = await HupuApi.getThreadDetailFromPc(tid);
        LinkHealth.record(linkKey, true);
        return detail;
      } catch (e) {
        LinkHealth.record(linkKey, false);
      }
    }
    return HupuApi.getThreadDetailFromApi(tid);
  }

  /**
   * PC 站页面请求去重：详情与首页评论会并行请求同一 URL，
   * 共享同一次网络往返（省掉一份 200KB+ 页面传输）；完成后即释放，不做结果缓存。
   */
  private static async getPcPage(url: string): Promise<string> {
    const inflight: Promise<string> | undefined = HupuApi.pcPageInflight.get(url);
    if (inflight !== undefined) {
      return inflight;
    }
    const task: Promise<string> = HttpManager.get(url, DESKTOP_UA);
    HupuApi.pcPageInflight.set(url, task);
    try {
      return await task;
    } finally {
      HupuApi.pcPageInflight.delete(url);
    }
  }

  /** 主链路：m 站 bbs-thread API */
  private static async getThreadDetailFromApi(tid: string): Promise<ThreadDetail> {
    const url: string = `${BASE}/api/v2/bbs-thread/${tid}`;
    const resp = await HttpManager.getJson<ThreadRespDto>(url);
    const d = resp.data?.t_detail;
    if (!d) {
      throw new Error('帖子不存在或已删除');
    }
    const detail: ThreadDetail = new ThreadDetail();
    detail.tid = String(d.tid ?? tid);
    detail.title = d.title ?? '';
    detail.content = d.content ?? '';
    detail.contentImages = detail.content.indexOf('<') >= 0 ? extractImages(detail.content) : [];
    detail.authorName = d.user?.username ?? '';
    detail.authorHeader = d.user?.header ?? '';
    detail.authorPuid = d.user?.puid !== undefined ? `${d.user.puid}` : '';
    detail.forumName = d.f_info?.f_name ?? '';
    detail.fid = d.f_info?.fid ?? '';
    detail.hits = HupuApi.toInt(d.hits);
    detail.replies = HupuApi.toInt(d.replies);
    detail.lights = HupuApi.toInt(d.lights);
    return detail;
  }

  /** PC 站详情页 __NEXT_DATA__ 的 detail.thread（title/content/author/板块/计数 + 视频） */
  private static async getThreadDetailFromPc(tid: string): Promise<ThreadDetail> {
    const url: string = `${PC_BASE}/${tid}.html`;
    const html: string = await HupuApi.getPcPage(url);
    const resp = JSON.parse(HupuApi.extractNextData(html)) as PcNextRespDto;
    const t = resp.props?.pageProps?.detail?.thread;
    if (!t || !t.title) {
      throw new Error('帖子不存在或已删除');
    }
    const detail: ThreadDetail = new ThreadDetail();
    detail.tid = t.tid ?? tid;
    detail.title = t.title ?? '';
    // 正文：普通帖为 HTML；比赛卡等特殊帖 content 是二次 JSON，转占位提示
    const rawContent: string = t.content ?? '';
    if (rawContent.length > 0 && rawContent.indexOf('{') === 0) {
      try {
        const special = JSON.parse(rawContent) as PcSpecialContentDto;
        detail.content = special.type === 'iframe-match'
          ? '<p>［本帖为比赛类帖子，正文请在比赛页查看］</p>'
          : '<p>［本帖正文为特殊格式，暂不支持展示］</p>';
      } catch (e) {
        detail.content = rawContent;
      }
    } else {
      detail.content = rawContent;
    }
    detail.contentImages = detail.content.indexOf('<') >= 0 ? extractImages(detail.content) : [];
    detail.authorName = t.author?.puname ?? '';
    detail.authorHeader = t.author?.header ?? '';
    detail.authorPuid = t.author?.puid ?? '';
    detail.forumName = t.topic?.name ?? '';
    detail.fid = t.fid ?? '';
    detail.hits = t.read ?? 0;
    detail.replies = t.replies ?? 0;
    detail.lights = t.lights ?? 0;
    HupuApi.applyPcVideo(detail, t);
    return detail;
  }

  /**
   * 解析 PC 站视频信息到详情模型。
   * 数据源：顶层 hasVideo / video（直连 mp4）/ videoCover，
   * 宽高取 format JSON 内的 videoInfo（顶层无尺寸字段）。
   */
  private static applyPcVideo(detail: ThreadDetail, t: PcThreadDto): void {
    const playUrl: string = t.video ?? '';
    const hasFlag: boolean = t.hasVideo === true;
    if (!hasFlag && playUrl.length === 0) {
      return;
    }
    detail.hasVideo = true;
    detail.videoUrl = playUrl;
    detail.videoCover = t.videoCover ?? '';
    // format 为作者端 JSON 字符串，含 videoInfo 原始宽高与备选封面
    const fmt: string = t.format ?? '';
    if (fmt.length > 0 && fmt.charAt(0) === '{') {
      try {
        const f = JSON.parse(fmt) as PcFormatDto;
        const vi = f.videoInfo;
        if (vi) {
          detail.videoWidth = vi.width ?? 0;
          detail.videoHeight = vi.height ?? 0;
          if (detail.videoCover.length === 0) {
            detail.videoCover = vi.coverUrl ?? '';
          }
          if (detail.videoUrl.length === 0) {
            detail.videoUrl = vi.remoteUrl ?? '';
          }
        }
      } catch (e) {
      }
    }
  }

  /**
   * 回复列表（楼层）
   * 数据源：PC 站页面内嵌 JSON（m 站 API 不支持翻页）
   * 第 1 页：bbs.hupu.com/{tid}.html；第 N 页：bbs.hupu.com/{tid}-{N}.html
   */
  static async getReplies(tid: string, page: number): Promise<ReplyListPage> {
    const url: string = page <= 1 ? `${PC_BASE}/${tid}.html` : `${PC_BASE}/${tid}-${page}.html`;
    // 第 1 页与详情同 URL：走共用去重，避免并行请求同一页面两次
    const html: string = await HupuApi.getPcPage(url);
    const json: string = HupuApi.extractNextData(html);
    const resp = JSON.parse(json) as PcNextRespDto;
    const replies = resp.props?.pageProps?.detail?.replies;
    const result: ReplyListPage = new ReplyListPage();
    if (!replies || !replies.list) {
      return result;
    }
    for (const d of replies.list) {
      result.items.push(HupuApi.mapPcReply(d));
    }
    result.totalCount = replies.count ?? 0;
    result.hasMore = (replies.current ?? 1) < (replies.total ?? 1);
    return result;
  }

  /**
   * 用户主页（他人空间）：`GET m.hupu.com/user/{puid}` 公开页。
   * 页内 __NEXT_DATA__.props.pageProps 提供：
   * userInfoData（头像/昵称/等级/声望/被点亮/关注数）/ threadList（主题帖）/ replyList（回帖）。
   * 注：此为公开页，无需登录即可查看任意用户。
   */
  static async getUserSpace(puid: string): Promise<UserSpaceData> {
    const url: string = `${BASE}/user/${puid}`;
    const html: string = await HttpManager.get(url);
    const resp = JSON.parse(HupuApi.extractNextData(html)) as UspNextRespDto;
    const pp = resp.props?.pageProps;
    const u = pp?.userInfoData;
    if (!pp || !u) {
      throw new Error('用户不存在或已注销');
    }
    const data: UserSpaceData = new UserSpaceData();
    const p: UserProfile = new UserProfile();
    p.puid = u.puid ?? puid;
    p.nickname = u.nickname ?? '';
    p.header = u.header ?? '';
    p.level = u.level ?? 0;
    p.levelDesc = u.bbsUserLevelDesc ?? '';
    p.reputation = u.reputation?.value ?? 0;
    p.beLight = u.be_light_count ?? 0;
    p.beFollow = u.be_follow_count ?? 0;
    p.follow = u.follow_count ?? 0;
    p.beRecommend = u.be_recommend_count ?? 0;
    p.isSelf = u.is_self === 1;
    data.profile = p;
    const threads = pp?.threadList ?? [];
    for (const t of threads) {
      const item: UserPostItem = new UserPostItem();
      item.tid = `${t.tid ?? 0}`;
      item.title = t.title ?? '';
      item.topicName = t.topic_name ?? '';
      item.lights = t.lights ?? 0;
      item.replies = t.replies ?? 0;
      item.visits = t.visits ?? 0;
      item.time = formatTime(t.lastpost_time ?? 0);
      data.threads.push(item);
    }
    const replies = pp?.replyList ?? [];
    for (const r of replies) {
      const item: UserPostItem = new UserPostItem();
      item.tid = `${r.tid ?? 0}`;
      item.content = htmlToText(r.content ?? '');
      item.lights = r.score ?? 0;
      item.time = formatTime(r.createTime ?? 0);
      data.replies.push(item);
    }
    return data;
  }

  /**
   * 官方号发文列表（官方资讯优先频道的权威数据源）。
   *
   * 为什么不用话题帖子流：`topicThreads` 官方帖稀疏（实测乒乓球仅 2 条/次）
   * 且**分页完全失效**（page/cursor/pageSize/offset/lastId 全部被忽略，
   * 永远返回同一批 10 条）。官方号主页 `m.hupu.com/user/{puid}` 的
   * `threadList` 一次返回 **20 条该号跨板块发文**，按 `topic_id` 过滤即可
   * 得到目标板块的官方帖（如虎扑体坛资讯：综合体育 10 / 网球场 4 / 乒乓球 3）。
   */
  static async getUserPosts(puid: string): Promise<ThreadListItem[]> {
    const url: string = `${BASE}/user/${puid}`;
    const html: string = await HttpManager.get(url);
    const resp = JSON.parse(HupuApi.extractNextData(html)) as UspNextRespDto;
    const list = resp.props?.pageProps?.threadList;
    const result: ThreadListItem[] = [];
    if (!list) {
      return result;
    }
    for (const d of list) {
      const item: ThreadListItem = new ThreadListItem();
      item.tid = `${d.tid ?? 0}`;
      item.title = d.title ?? '';
      item.topicName = d.topic_name ?? '';
      item.topicId = d.topic_id ?? 0;
      item.replies = d.replies ?? 0;
      item.recommendCount = d.lights ?? 0;
      item.shareNum = d.share_num ?? 0;
      item.visits = d.visits ?? 0;
      item.time = formatTime(d.create_time ?? d.lastpost_time ?? 0);
      const pics = d.pics;
      if (pics && pics.length > 0) {
        item.coverUrl = pics[0].url ?? '';
        item.coverWidth = pics[0].width ?? 0;
        item.coverHeight = pics[0].height ?? 0;
        for (const pc of pics) {
          const u: string = pc.url ?? '';
          if (u.length > 0 && item.picUrls.length < 3) {
            item.picUrls.push(u);
          }
        }
      }
      result.push(item);
    }
    return result;
  }

  /**
   * 话题帖子流（PC 站分页版，支持无限滚动）。
   *
   * 为什么用 PC 站：m 站 `topicThreads` 接口**分页完全失效**（page/cursor/pageSize/
   * offset/lastId 全部被忽略，恒返回同一批 10 条），无法支撑无限滚动。
   * PC 站话题页 `bbs.hupu.com/{topicId}` 的分页**实测有效**：
   * 第 1 页 `/{topicId}`、第 N 页 `/{topicId}-{N}`（**不带 `.html`**，
   * 带 `.html` 会被当作帖子评论页），实测 1~20 页各约 50 条且内容不重复。
   *
   * 列表结构（SSR HTML，正则提取）：
   * <li class="bbs-sl-web-post-body">
   *   <div class="post-title"><a href="/{tid}.html" class="p-title">标题</a>
   *   <div class="post-datum">{回复} / {浏览}</div>
   *   <div class="post-auth"><a>{作者}</a></div>
   *   <div class="post-time">{时间}</div>
   */
  static async getForumThreads(topicId: number, page: number): Promise<ThreadListPage> {
    const url: string = page <= 1 ? `${PC_BASE}/${topicId}` : `${PC_BASE}/${topicId}-${page}`;
    const html: string = await HttpManager.get(url, DESKTOP_UA);
    const result: ThreadListPage = new ThreadListPage();
    if (html.indexOf(WAF_MARK) >= 0) {
      // 阿里云 WAF 滑块验证页（响应头 punish-loc: keepper）：高频请求触发
      throw new Error('访问过于频繁，请稍后再试');
    }
    const chunks: string[] = html.split(ITEM_MARK);
    // 首段是列表之前的头部，跳过
    for (let i: number = 1; i < chunks.length; i++) {
      const item: ThreadListItem | null = HupuApi.parseForumItem(chunks[i]);
      if (item !== null) {
        result.items.push(item);
      }
    }
    result.hasMore = result.items.length > 0;
    result.cursor = '';
    return result;
  }

  /** 解析 PC 话题页单条帖子（正则；字段缺失不阻断整条） */
  private static parseForumItem(block: string): ThreadListItem | null {
    const head = REG_TITLE.exec(block);
    if (head === null) {
      return null;
    }
    const item: ThreadListItem = new ThreadListItem();
    item.tid = head[1];
    item.title = htmlToText(head[2]).trim();
    const datum = REG_DATUM.exec(block);
    if (datum !== null) {
      // "回复 / 浏览"
      const parts: string[] = datum[1].split('/');
      if (parts.length >= 1) {
        item.replies = HupuApi.toInt(parts[0].trim());
      }
      if (parts.length >= 2) {
        item.visits = HupuApi.toInt(parts[1].trim());
      }
    }
    const auth = REG_AUTH.exec(block);
    if (auth !== null) {
      item.userName = htmlToText(auth[1]).trim();
    }
    const tm = REG_POSTTIME.exec(block);
    if (tm !== null) {
      item.time = tm[1].trim();
    }
    return item;
  }

  /**
   * 官方资讯历史（带图，用于资讯频道上拉加载）。
   *
   * 为什么用搜索接口：PC 话题页（目前话题频道的历史源）**不提供图片**，
   * 而资讯频道首屏来自 m 站资讯页（有图），两段展示不一致。
   * `search2` 搜索"流言板"等官方资讯标志词的结果**带 `picture` 封面**（实测 106/120 有图）
   * 且**分页有效**（count 500+），配合 `fid` 过滤即可得到目标板块的带图官方资讯。
   *
   * @param keyword 搜索关键词（官方资讯标志词，如"流言板"）
   * @param page 页码（1 起）
   */
  static async searchThreads(keyword: string, page: number): Promise<ThreadListItem[]> {
    const url: string =
      `${BASE}/api/v2/search2?keyword=${encodeURIComponent(keyword)}&puid=0&type=posts&topicId=0&page=${page}`;
    const resp = await HttpManager.getJson<SearchRespDto>(url);
    const list = resp.data?.result?.data;
    const result: ThreadListItem[] = [];
    if (!list) {
      return result;
    }
    for (const d of list) {
      const item: ThreadListItem = new ThreadListItem();
      item.tid = `${d.id ?? 0}`;
      // 标题含搜索高亮标签（<font color=...>），清洗后使用
      item.title = htmlToText(d.title ?? '');
      item.userName = d.username ?? '';
      item.topicName = d.forum_name ?? '';
      item.fid = d.fid ?? 0;
      item.replies = d.replies ?? 0;
      item.recommendCount = d.lights ?? 0;
      item.coverUrl = d.picture ?? '';
      // 与资讯页首屏时间格式（MM-DD HH:MM）保持一致，避免两段展示风格割裂
      item.time = HupuApi.formatDateTime(d.addtime ?? 0);
      result.push(item);
    }
    return result;
  }

  /** 时间戳 → MM-DD HH:MM（与资讯页 publishTime 裁剪格式一致） */
  private static formatDateTime(sec: number): string {
    if (sec <= 0) {
      return '';
    }
    const d: Date = new Date(sec * 1000);
    const mm: number = d.getMonth() + 1;
    const dd: number = d.getDate();
    const hh: number = d.getHours();
    const mi: number = d.getMinutes();
    const p2 = (n: number): string => (n < 10 ? `0${n}` : `${n}`);
    return `${p2(mm)}-${p2(dd)} ${p2(hh)}:${p2(mi)}`;
  }

  /**
   * 专区信息（PC 话题页头部解析）：名称 / 话题介绍 / 热度 / 版主 / 头部图。
   * 头部图取 `bbs-sl-web-intro` 的 background-image，与专区头像同源（方形 LOGO），
   * 官方 App 亦以此作头部背景，放大铺满 + 暗化蒙层即可适配。
   */
  static async getTopicInfo(topicId: number): Promise<TopicInfo> {
    const html: string = await HupuApi.getPcPage(`${PC_BASE}/${topicId}`);
    const info: TopicInfo = new TopicInfo();
    info.topicId = topicId;
    if (html.indexOf(WAF_MARK) >= 0) {
      throw new Error('访问过于频繁，请稍后再试');
    }
    // 名称
    const mName = REG_TOPIC_NAME.exec(html);
    if (mName !== null) {
      info.name = htmlToText(mName[1]).replace('#', '').trim();
    }
    // 头部图（intro 的 background-url，位于 style 属性内）
    const mBg = REG_TOPIC_BG.exec(html);
    if (mBg !== null) {
      info.bannerUrl = mBg[1];
    }
    // 话题介绍 / 话题热度（两段结构相同，按标签文本区分）
    const descs: RegExpExecArray[] = [];
    const regDesc: RegExp = new RegExp(REG_TOPIC_DESC.source, 'g');
    let m: RegExpExecArray | null = regDesc.exec(html);
    while (m !== null && descs.length < 4) {
      descs.push(m);
      m = regDesc.exec(html);
    }
    for (const d of descs) {
      const label: string = d[1];
      let val: string = d[2];
      // 热度值前有 <i> 图标，清洗标签
      val = htmlToText(val).trim();
      if (label.indexOf('介绍') >= 0 && info.desc.length === 0) {
        info.desc = val;
      } else if (label.indexOf('热度') >= 0 && info.heat.length === 0) {
        info.heat = val;
      }
    }
    // 版主（可能多位，以 、 分隔）
    if (REG_TOPIC_ADMIN.test(html)) {
      const block: RegExpExecArray | null = REG_TOPIC_ADMIN.exec(html);
      if (block !== null) {
        const regA: RegExp = new RegExp('>([^<>]{1,24})</a>', 'g');
        let ma: RegExpExecArray | null = regA.exec(block[1]);
        while (ma !== null) {
          const nm: string = ma[1].trim();
          if (nm.length > 0) {
            info.moderators.push(nm);
          }
          ma = regA.exec(block[1]);
        }
      }
    }
    if (info.name.length === 0) {
      throw new Error('专区不存在');
    }
    return info;
  }

  /** 社区分区树（从页面内嵌 __NEXT_DATA__ 提取） */
  static async getZones(): Promise<ZoneCategory[]> {
    const html: string = await HttpManager.get(`${BASE}/zone`);
    const json: string = HupuApi.extractNextData(html);
    const resp = JSON.parse(json) as NextRespDto;
    const categories = resp.props?.pageProps?.data;
    const result: ZoneCategory[] = [];
    if (!categories) {
      throw new Error('分区数据为空');
    }
    for (const c of categories) {
      const cat: ZoneCategory = new ZoneCategory();
      cat.categoryId = c.categoryId ?? 0;
      cat.name = c.name ?? '';
      const topics = c.topicList ?? [];
      for (const t of topics) {
        const zt: ZoneTopic = new ZoneTopic();
        zt.topicId = t.topicId ?? 0;
        zt.topicName = t.topicName ?? '';
        zt.topicLogo = t.topicLogo ?? '';
        zt.count = t.count ?? '';
        cat.topics.push(zt);
      }
      result.push(cat);
    }
    return result;
  }

  /** 全站搜索 */
  static async search(keyword: string, page: number): Promise<SearchResultPage> {
    const url: string =
      `${BASE}/api/v2/search2?keyword=${encodeURIComponent(keyword)}&puid=0&type=posts&topicId=0&page=${page}`;
    const resp = await HttpManager.getJson<SearchRespDto>(url);
    const inner = resp.data?.result;
    const result: SearchResultPage = new SearchResultPage();
    if (!inner || !inner.data) {
      return result;
    }
    for (const d of inner.data) {
      const item: SearchItem = new SearchItem();
      item.tid = String(d.id ?? 0);
      item.title = htmlToText(d.title ?? '');
      item.summary = htmlToText((d.content ?? '').substring(0, 120));
      item.userName = d.username ?? '';
      item.forumName = d.forum_name ?? '';
      item.replies = d.replies ?? 0;
      item.createTime = d.addtime ?? 0;
      item.coverUrl = d.picture ?? '';
      result.items.push(item);
    }
    result.hasMore = inner.hasNextPage === 1;
    return result;
  }

  /** 热榜列表（榜单聚合，m.hupu.com/hot 页面内嵌） */
  static async getHotRanks(): Promise<HotRankItem[]> {
    const html: string = await HttpManager.get(`${BASE}/hot`);
    const json: string = HupuApi.extractNextData(html);
    const resp = JSON.parse(json) as HotPageRespDto;
    const list = resp.props?.pageProps?.res;
    const result: HotRankItem[] = [];
    if (!list) {
      throw new Error('热榜数据为空');
    }
    for (const d of list) {
      const item: HotRankItem = new HotRankItem();
      item.rank = d.rank ?? 0;
      item.tagId = d.tagId ?? 0;
      item.tagName = d.tagName ?? '';
      item.heat = d.heat ?? 0;
      item.competitionType = d.competitionType ?? '';
      item.updateDesc = d.tagUpdateDesc ?? '';
      result.push(item);
    }
    return result;
  }

  /** 话题下的帖子流（tagThreads API，tagType: 1 主贴 / 2 全部） */
  static async getTagThreads(tagId: number, tagType: number, page: number, cursor: string): Promise<ThreadListPage> {
    const url: string =
      `${BASE}/api/v2/bbs/tagThreads?tagId=${tagId}&tagType=${tagType}&page=${page}&pageSize=20&cursor=${cursor}`;
    const resp = await HttpManager.getJson<TagThreadsRespDto>(url);
    const data = resp.data;
    const result: ThreadListPage = new ThreadListPage();
    if (!data || !data.threadList) {
      return result;
    }
    for (const d of data.threadList) {
      const item: ThreadListItem = new ThreadListItem();
      item.tid = `${d.tid ?? 0}`;
      item.title = d.title ?? '';
      item.userName = d.userName ?? '';
      item.userHeader = d.userHeader ?? '';
      item.time = d.time ?? '';
      item.replies = d.replies ?? 0;
      item.recommendCount = d.recommendCount ?? 0;
      item.isVideo = d.videoThread === true;
      const v = d.video;
      if (v && v.img) {
        item.coverUrl = v.img;
        item.videoDuration = v.humanDuration ?? '';
      }
      const pics = d.picList;
      if (!item.coverUrl && pics && pics.length > 0) {
        item.coverUrl = pics[0].url ?? '';
      }
      if (pics && pics.length > 0) {
        for (const pc of pics) {
          const u: string = pc.url ?? '';
          if (u.length > 0 && item.picUrls.length < 3) {
            item.picUrls.push(u);
          }
        }
      }
      result.items.push(item);
    }
    result.hasMore = data.nextPage === true;
    result.cursor = data.cursor ?? '';
    return result;
  }

  /** 楼中楼：某条评论下的回复列表（bbs-reply-detail API） */
  static async getSubReplies(tid: string, pid: string): Promise<SubReplyItem[]> {
    const url: string = `${BASE}/api/v2/bbs-reply-detail/${tid}-${pid}`;
    const resp = await HttpManager.getJson<ReplyDetailRespDto>(url);
    const list = resp.data?.replies;
    const result: SubReplyItem[] = [];
    if (!list) {
      return result;
    }
    for (const d of list) {
      const item: SubReplyItem = new SubReplyItem();
      const raw: string = d.content ?? '';
      item.parentPid = pid;
      item.pid = `${d.pid ?? 0}`;
      item.puid = d.user?.puid !== undefined ? `${d.user.puid}` : '';
      item.userName = d.user?.username ?? '';
      item.userHeader = d.user?.header ?? '';
      item.content = htmlToText(raw);
      item.contentImages = extractImages(raw);
      item.light = d.lights ?? 0;
      item.createDt = d.user?.createDt ?? '';
      item.isLz = d.lz === true;
      result.push(item);
    }
    return result;
  }

  /* ---------------- 内部工具 ---------------- */

  private static extractNextData(html: string): string {
    const marker: string = '__NEXT_DATA__';
    const i: number = html.indexOf(marker);
    if (i < 0) {
      throw new Error('页面结构已变化');
    }
    const s: number = html.indexOf('>', i) + 1;
    const e: number = html.indexOf('</script>', s);
    if (s <= 0 || e <= s) {
      throw new Error('页面数据解析失败');
    }
    return html.substring(s, e);
  }

  private static toInt(v: string | undefined): number {
    if (!v) {
      return 0;
    }
    const n: number = Number(v);
    return Number.isNaN(n) ? 0 : Math.floor(n);
  }

  private static mapWsItem(d: WsThreadDto): ThreadListItem {
    const item: ThreadListItem = new ThreadListItem();
    item.tid = `${d.tid ?? 0}`;
    item.title = d.title ?? '';
    item.userName = d.userName ?? '';
    item.userHeader = d.userHeader ?? '';
    item.time = d.time ?? '';
    item.replies = d.replies ?? 0;
    item.recommendCount = d.recommendCount ?? 0;
    item.shareNum = d.shareNum ?? 0;
    item.topicName = d.topicName ?? '';
    item.topicIcon = d.topicIcon ?? '';
    item.isVideo = d.videoThread === true;
    const v = d.video;
    if (v && v.img) {
      item.coverUrl = v.img;
      item.videoDuration = v.humanDuration ?? '';
    }
    if (v) {
      item.videoUrl = v.url ?? '';
      item.playNum = v.playNum ?? 0;
      item.coverWidth = v.width ?? 0;
      item.coverHeight = v.height ?? 0;
    }
    const pics = d.picList;
    if (pics && pics.length > 0) {
      if (!item.coverUrl) {
        item.coverUrl = pics[0].url ?? '';
      }
      if (item.coverWidth <= 0 && pics[0].width !== undefined) {
        item.coverWidth = pics[0].width;
      }
      if (item.coverHeight <= 0 && pics[0].height !== undefined) {
        item.coverHeight = pics[0].height;
      }
      for (const pc of pics) {
        const u: string = pc.url ?? '';
        if (u.length > 0 && item.picUrls.length < 3) {
          item.picUrls.push(u);
        }
      }
    }
    const lr = d.lightReplyResult;
    if (lr) {
      item.lightReplyContent = lr.content ?? '';
      item.lightReplyUser = lr.replyUserName ?? '';
      item.lightReplyCount = lr.lightCount ?? 0;
    }
    return item;
  }

  private static mapTtItem(d: TtThreadDto): ThreadListItem {
    const item: ThreadListItem = new ThreadListItem();
    item.tid = `${d.tid ?? 0}`;
    item.title = d.title ?? '';
    item.userName = d.username ?? '';
    item.time = d.time ?? '';
    item.replies = d.replies ?? 0;
    item.recommendCount = d.recommendNum ?? 0;
    item.isVideo = d.isVideo === true;
    return item;
  }

  private static mapPcReply(d: PcReplyDto): ReplyItem {
    const item: ReplyItem = new ReplyItem();
    const raw: string = d.content ?? '';
    item.pid = d.pid ?? '';
    item.puid = d.author?.puid ?? '';
    item.userName = d.author?.puname ?? '';
    item.userHeader = d.author?.header ?? '';
    item.content = htmlToText(raw);
    item.contentImages = extractImages(raw);
    item.light = d.count ?? 0;
    item.replyCount = d.replyNum ?? 0;
    item.createDt = d.createdAtFormat ?? '';
    item.location = d.location ?? '';
    item.isLz = d.isStarter === true;
    return item;
  }
}

export class TimeUtil {
  static fromEpoch(sec: number): string {
    return formatTime(sec);
  }
}
