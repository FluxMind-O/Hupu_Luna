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
  SubReplyItem
} from '../model/Models';
import { htmlToText, extractImages, formatTime } from '../common/Utils';

const BASE: string = 'https://m.hupu.com';
const PC_BASE: string = 'https://bbs.hupu.com';
const PAGE_SIZE: number = 20;

const DESKTOP_UA: string =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36';

/* ---------------- 原始响应 DTO ---------------- */

interface WsVideoDto {
  img?: string;
  humanDuration?: string;
}

interface WsPicDto {
  url?: string;
}

interface WsThreadDto {
  tid?: number;
  title?: string;
  userName?: string;
  userHeader?: string;
  time?: string;
  replies?: number;
  recommendCount?: number;
  topicName?: string;
  topicIcon?: string;
  videoThread?: boolean;
  video?: WsVideoDto;
  picList?: WsPicDto[];
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
  title?: string;
  content?: string;
  picture?: string;
  username?: string;
  forum_name?: string;
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

  /** 帖子详情：主链路（m 站 API）失败或熔断中 → L0 兜底（PC 站页面内嵌 thread） */
  static async getThreadDetail(tid: string): Promise<ThreadDetail> {
    const linkKey: string = 'thread-detail';
    if (LinkHealth.allow(linkKey)) {
      try {
        const detail: ThreadDetail = await HupuApi.getThreadDetailFromApi(tid);
        LinkHealth.record(linkKey, true);
        return detail;
      } catch (e) {
        LinkHealth.record(linkKey, false);
      }
    }
    return HupuApi.getThreadDetailFromPc(tid);
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
    detail.forumName = d.f_info?.f_name ?? '';
    detail.fid = d.f_info?.fid ?? '';
    detail.hits = HupuApi.toInt(d.hits);
    detail.replies = HupuApi.toInt(d.replies);
    detail.lights = HupuApi.toInt(d.lights);
    return detail;
  }

  /** L0 兜底：PC 站详情页 __NEXT_DATA__ 的 detail.thread（title/content/author/板块/计数） */
  private static async getThreadDetailFromPc(tid: string): Promise<ThreadDetail> {
    const url: string = `${PC_BASE}/${tid}.html`;
    const html: string = await HttpManager.get(url, DESKTOP_UA);
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
    detail.forumName = t.topic?.name ?? '';
    detail.fid = t.fid ?? '';
    detail.hits = t.read ?? 0;
    detail.replies = t.replies ?? 0;
    detail.lights = t.lights ?? 0;
    return detail;
  }

  /**
   * 回复列表（楼层）
   * 数据源：PC 站页面内嵌 JSON（m 站 API 不支持翻页）
   * 第 1 页：bbs.hupu.com/{tid}.html；第 N 页：bbs.hupu.com/{tid}-{N}.html
   */
  static async getReplies(tid: string, page: number): Promise<ReplyListPage> {
    const url: string = page <= 1 ? `${PC_BASE}/${tid}.html` : `${PC_BASE}/${tid}-${page}.html`;
    const html: string = await HttpManager.get(url, DESKTOP_UA);
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
    item.topicName = d.topicName ?? '';
    item.topicIcon = d.topicIcon ?? '';
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
