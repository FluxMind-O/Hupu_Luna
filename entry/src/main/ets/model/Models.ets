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
  topicIcon: string = '';
  coverUrl: string = '';
  isVideo: boolean = false;
  videoDuration: string = '';
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
  forumName: string = '';
  hits: number = 0;
  replies: number = 0;
  lights: number = 0;
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
  userName: string = '';
  userHeader: string = '';
  content: string = '';
  contentImages: string[] = [];
  light: number = 0;
  createDt: string = '';
  isLz: boolean = false;
}
