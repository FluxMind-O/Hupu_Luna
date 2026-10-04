/**
 * 虎扑数据结构模型（与 m.hupu.com 接口字段映射）
 */

/** 步行街/分区帖子流条目（/api/v2/bbs/walkingStreet/threads、/api/v2/bbs/topicThreads） */
export class ThreadListItem {
  tid: string = '';
  title: string = '';
  userName: string = '';
  userHeader: string = '';
  time: string = '';
  /** 多图列表（官方样式图网格用） */
  picUrls: string[] = [];
  replies: number = 0;
  recommendCount: number = 0;
  topicName: string = '';
  /** 所属话题 id（官方号发帖列表按此过滤到目标频道） */
  topicId: number = 0;
  /** 板块 fid（搜索结果按此过滤到目标频道） */
  fid: number = 0;
  topicIcon: string = '';
  coverUrl: string = '';
  isVideo: boolean = false;
  videoDuration: string = '';
  /** 视频直连播放地址（videoThread 时由 video.url 提供，带时效 auth_key） */
  videoUrl: string = '';
  /** 封面宽高（按真实比例渲染单图/视频区） */
  coverWidth: number = 0;
  coverHeight: number = 0;
  /** 分享数 */
  shareNum: number = 0;
  /** 浏览数（官方号发文列表提供） */
  visits: number = 0;
  /** 视频播放量（视频帖的"浏览"口径） */
  playNum: number = 0;
  /** 神回复（亮评）：内容 / 作者 / 亮数 */
  lightReplyContent: string = '';
  lightReplyUser: string = '';
  lightReplyCount: number = 0;
}

/** 帖子流响应包 */
export class ThreadListPage {
  items: ThreadListItem[] = [];
  hasMore: boolean = false;
  cursor: string = '';
}

/** 帖子详情 */
export class ThreadDetail {
  tid: string = '';
  /** 板块 fid（写接口需要） */
  fid: string = '';
  title: string = '';
  /** 正文（HTML 或内嵌 JSON 字符串） */
  content: string = '';
  contentImages: string[] = [];
  authorName: string = '';
  authorHeader: string = '';
  /** 楼主 puid（点击头像进楼主主页） */
  authorPuid: string = '';
  forumName: string = '';
  hits: number = 0;
  replies: number = 0;
  lights: number = 0;
  /** 是否视频帖（仅 PC 站详情页提供；m 站 API 无此字段） */
  hasVideo: boolean = false;
  /** 视频直连播放地址（PC 站 video 字段，带时效 auth_key） */
  videoUrl: string = '';
  /** 视频封面 */
  videoCover: string = '';
  /** 视频原始宽高（按比例渲染用） */
  videoWidth: number = 0;
  videoHeight: number = 0;
}

/** 回复（楼层） */
export class ReplyItem {
  pid: string = '';
  /** 回复作者 puid（点亮需要） */
  puid: string = '';
  userName: string = '';
  userHeader: string = '';
  content: string = '';
  contentImages: string[] = [];
  light: number = 0;
  replyCount: number = 0;
  createDt: string = '';
  location: string = '';
  isLz: boolean = false;
}

/** 回复页响应包 */
export class ReplyListPage {
  items: ReplyItem[] = [];
  totalCount: number = 0;
  hasMore: boolean = false;
}

/** 社区分区下的板块 */
export class ZoneTopic {
  topicId: number = 0;
  topicName: string = '';
  topicLogo: string = '';
  count: string = '';
}

/** 社区分区分类（热门/步行街/体育...） */
export class ZoneCategory {
  categoryId: number = 0;
  name: string = '';
  topics: ZoneTopic[] = [];
}

/** 搜索结果条目 */
export class SearchItem {
  tid: string = '';
  title: string = '';
  summary: string = '';
  userName: string = '';
  forumName: string = '';
  replies: number = 0;
  createTime: number = 0;
  coverUrl: string = '';
}

/** 搜索响应包 */
export class SearchResultPage {
  items: SearchItem[] = [];
  hasMore: boolean = false;
}

/** NBA 新闻条目 */
export class NbaNewsItem {
  nid: string = '';
  tid: string = '';
  title: string = '';
  img: string = '';
  lights: number = 0;
  replies: number = 0;
  publishTime: string = '';
}

/** 比赛条目 */
export class MatchItem {
  matchId: string = '';
  status: string = '';
  statusCn: string = '';
  statusDesc: string = '';
  homeName: string = '';
  awayName: string = '';
  homeTeamId: string = '';
  awayTeamId: string = '';
  homeLogo: string = '';
  awayLogo: string = '';
  homeScore: string = '';
  awayScore: string = '';
  matchTime: string = '';
  stage: string = '';
  /** 评分人数文案（如 "49.8万评分" / "4679评分"） */
  scorePv: string = '';
}

/** 投篮热图区域（shootHotMap） */
export class ShootZone {
  areaId: number = 0;
  fgs: number = 0;
  fgm: number = 0;
  fgp: string = '';
  level: number = 0;
  color: string = '';
}

/** 荣誉明细 */
export class AwardDetail {
  season: string = '';
  awardDate: string = '';
}

/** 球员荣誉（playerAwardList） */
export class AwardItem {
  name: string = '';
  count: number = 0;
  dates: string[] = [];
}

/** 球员头部信息（playerPageHeadInfo） */
export class PlayerHeadInfo {
  playerId: string = '';
  name: string = '';
  alias: string = '';
  engName: string = '';
  nick: string = '';
  number: string = '';
  position: string = '';
  age: string = '';
  height: string = '';
  weight: string = '';
  country: string = '';
  college: string = '';
  draftYear: string = '';
  draftRound: number = 0;
  draftPick: number = 0;
  salary: number = 0;
  contract: string = '';
  teamName: string = '';
  teamLogo: string = '';
  photo: string = '';
  birthDate: string = '';
}

/** 球员单项数据 */
export class PlayerStatItem {
  name: string = '';
  cnName: string = '';
  quota: string = '';
  rank: number = 0;
  leagueAvg: string = '';
  leagueMax: string = '';
}

/** 某阶段（季前/常规/季后）的数据分组 */
export class PlayerStageStats {
  stage: string = '';
  label: string = '';
  items: PlayerStatItem[] = [];
}

/** 球员赛季数据（playerSeasonStats） */
export class PlayerSeasonData {
  season: string = '';
  anchorStage: string = '';
  basicStages: PlayerStageStats[] = [];
  advancedStages: PlayerStageStats[] = [];
}

/** 球员评分行（teamMatchRosterScoreStats） */
export class PlayerScoreRow {
  playerId: string = '';
  teamId: string = '';
  name: string = '';
  alias: string = '';
  number: string = '';
  position: string = '';
  photo: string = '';
  mins: string = '';
  pts: number = 0;
  reb: number = 0;
  ast: number = 0;
  stl: number = 0;
  blk: number = 0;
  fgp: string = '';
  starter: boolean = false;
  scoreAvg: number = 0;
  scoreCount: number = 0;
  comment: string = '';
}

/** 比赛日（赛程分组） */
export class MatchDay {
  day: string = '';
  dayLabel: string = '';
  matches: MatchItem[] = [];
}

/** 评分分布分档（2/4/6/8/10 分档） */
export class ScoreBucket {
  score: number = 0;
  count: number = 0;
}

/** 球员评分详情（basketball-player-score SSR） */
export class PlayerScoreDetail {
  playerName: string = '';
  alias: string = '';
  number: string = '';
  position: string = '';
  photo: string = '';
  mins: string = '';
  pts: number = 0;
  reb: number = 0;
  asts: number = 0;
  stl: number = 0;
  blk: number = 0;
  twoPoints: string = '';
  threePoints: string = '';
  ft: string = '';
  fgp: string = '';
  tpp: string = '';
  plusMinus: string = '';
  scoreAvg: number = 0;
  scoreCount: number = 0;
  buckets: ScoreBucket[] = [];
}

/** 战报事件（进球/红牌/关键镜头等） */
export class BattleEvent {
  time: string = '';
  title: string = '';
  gif: string = '';
  isKey: boolean = false;
}

/** 战报球队数据对比项 */
export class BattleStat {
  name: string = '';
  homeVal: string = '';
  awayVal: string = '';
}

/** 比赛战报（battleReport 接口） */
export class BattleReport {
  content: string = '';
  img: string = '';
  events: BattleEvent[] = [];
  stats: BattleStat[] = [];
  lineup: string = '';
}

/** 足球比赛条目（m.hupu.com/soccer/schedule） */
export class SoccerMatchItem {
  matchId: string = '';
  title: string = '';
  homeName: string = '';
  awayName: string = '';
  homeLogo: string = '';
  awayLogo: string = '';
  homeScore: string = '';
  awayScore: string = '';
  statusTxt: string = '';
  statusId: number = 0;
  timeText: string = '';
  pv: string = '';
  beginTime: number = 0;
}

/** 热榜条目（m.hupu.com/hot） */
export class HotRankItem {
  rank: number = 0;
  tagId: number = 0;
  tagName: string = '';
  heat: number = 0;
  competitionType: string = '';
  updateDesc: string = '';
}

/** 楼中楼回复（评论的回复） */
export class SubReplyItem {
  parentPid: string = '';
  pid: string = '';
  /** 作者 puid（点击头像进主页用） */
  puid: string = '';
  userName: string = '';
  userHeader: string = '';
  content: string = '';
  contentImages: string[] = [];
  light: number = 0;
  createDt: string = '';
  isLz: boolean = false;
}

/** 专区信息（PC 话题页头部解析） */
export class TopicInfo {
  topicId: number = 0;
  /** 专区名（如 NBA2KOL2） */
  name: string = '';
  /** 话题介绍 */
  desc: string = '';
  /** 话题热度（如 3.4w） */
  heat: string = '';
  /** 版主昵称列表 */
  moderators: string[] = [];
  /**
   * 头部图（PC 页 intro 的 background-image）。
   * 注意：该图与专区头像同源（方形 LOGO，约 500x500），
   * 官方 App 亦用它作头部背景——放大铺满 + 暗化蒙层即可适配。
   */
  bannerUrl: string = '';
}

/** 用户主页档案（m.hupu.com/user/{puid} 公开页） */
export class UserProfile {
  puid: string = '';
  nickname: string = '';
  header: string = '';
  /** 论坛等级数字 */
  level: number = 0;
  /** 等级文案（如 Lv.3） */
  levelDesc: string = '';
  /** 声望值 */
  reputation: number = 0;
  /** 被点亮数 */
  beLight: number = 0;
  /** 被关注数（粉丝） */
  beFollow: number = 0;
  /** 关注数 */
  follow: number = 0;
  /** 被推荐数 */
  beRecommend: number = 0;
  /** 是否本人（接口 is_self 字段） */
  isSelf: boolean = false;
}

/** 用户主页条目（主题帖 / 回帖统一结构） */
export class UserPostItem {
  tid: string = '';
  /** 主题帖标题；回帖时为空 */
  title: string = '';
  /** 回帖正文；主题帖时为空 */
  content: string = '';
  topicName: string = '';
  lights: number = 0;
  replies: number = 0;
  visits: number = 0;
  time: string = '';
}

/** 用户主页数据包 */
export class UserSpaceData {
  profile: UserProfile = new UserProfile();
  threads: UserPostItem[] = [];
  replies: UserPostItem[] = [];
}
