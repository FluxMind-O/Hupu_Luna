import { HttpManager } from './HttpManager';
import {
  NbaNewsItem,
  MatchItem,
  MatchDay,
  PlayerScoreRow,
  PlayerScoreDetail,
  ScoreBucket,
  PlayerHeadInfo,
  PlayerStatItem,
  PlayerStageStats,
  PlayerSeasonData,
  ShootZone,
  AwardItem
} from '../model/Models';

const BASE: string = 'https://m.hupu.com';

/* ---- m.hupu.com/nba 页面内嵌结构 ---- */

interface NbaNewsDto {
  nid?: string;
  tid?: string;
  title?: string;
  img?: string;
  lights?: number;
  replies?: number;
  publishTime?: string;
}

interface NbaFrontStatusDto {
  id?: number;
  desc?: string;
}

interface NbaMatchDto {
  matchId?: string;
  matchStatus?: string;
  matchStatusChinese?: string;
  frontEndMatchStatus?: NbaFrontStatusDto;
  homeTeamName?: string;
  awayTeamName?: string;
  homeTeamId?: string;
  awayTeamId?: string;
  homeTeamLogo?: string;
  awayTeamLogo?: string;
  homeScore?: number | null;
  awayScore?: number | null;
  matchTime?: string;
  competitionStageDesc?: string;
  score?: string | null;
}

interface NbaRecommendMatchDto {
  matchList?: NbaMatchDto[];
}

interface NbaPagePropsDto {
  newsData?: NbaNewsDto[];
  recommendMatch?: NbaRecommendMatchDto;
}

interface NbaPageDataDto {
  pageProps?: NbaPagePropsDto;
}

interface NbaRespDto {
  props?: NbaPageDataDto;
}

/* ---- m.hupu.com/nba/schedule 页面内嵌结构 ---- */

interface NbaMatchDayDto {
  day?: string;
  dayBlock?: string;
  matchList?: NbaMatchDto[];
}

interface NbaSchedulePropsDto {
  gameList?: NbaMatchDayDto[];
}

interface NbaScheduleDataDto {
  pageProps?: NbaSchedulePropsDto;
}

interface NbaScheduleRespDto {
  props?: NbaScheduleDataDto;
}

/* ---- 球员评分详情（basketball-player-score SSR） ---- */

interface ScoreDetailInfoDto {
  playerId?: string;
  number?: string;
  name?: string;
  alias?: string;
  photo?: string;
  logoUrl?: string;
  mins?: string;
  pts?: number;
  reb?: number;
  asts?: number;
  stl?: number;
  blk?: number;
  twoPoints?: string;
  threePoints?: string;
  ft?: string;
  fgp?: string;
  tpp?: string;
  plusMinus?: string;
  position?: string;
  userScoreAvg?: number;
  userScoreCount?: number;
}

interface ScoreDetailInfoWrapDto {
  playerInfo?: ScoreDetailInfoDto;
  scoreDistribution?: Record<string, number>;
}

interface ScoreDetailPagePropsDto {
  scoreInfo?: ScoreDetailInfoWrapDto;
}

interface ScoreDetailPropsDto {
  pageProps?: ScoreDetailPagePropsDto;
}

interface ScoreDetailRespDto {
  props?: ScoreDetailPropsDto;
}

/* ---- 球员主页（playerPageHeadInfo / playerSeasonStats） ---- */

interface PlayerHeadDto {
  playerId?: string;
  name?: string;
  alias?: string;
  eng_name?: string;
  nick?: string;
  number?: string;
  position?: string;
  age?: string;
  height?: string;
  weight?: string;
  country?: string;
  college_school?: string;
  draft_year?: number;
  draftRound?: number;
  draftPick?: number;
  salary?: number;
  contractDetails?: string;
  teamName?: string;
  teamLogoLink?: string;
  photo?: string;
  birth_date?: string;
}

interface PlayerHeadResultDto {
  player?: PlayerHeadDto;
}

interface PlayerHeadRespDto {
  result?: PlayerHeadResultDto;
}

interface StatItemDto {
  name?: string;
  cnName?: string;
  quota?: string;
  rank?: number | null;
  leagueAvgValue?: string | null;
  leagueMaxValue?: string | null;
}

interface DimensionDto {
  competitionStagePackListMap?: Record<string, StatItemDto[]>;
}

interface SeasonStatsResultDto {
  season?: string;
  anchorCompetitionStageType?: string;
  dataDimensionMap?: Record<string, DimensionDto>;
}

interface SeasonStatsRespDto {
  result?: SeasonStatsResultDto;
}

/* ---- 投篮热图 / 荣誉 ---- */

interface ShootAreaDto {
  areaId?: string;
  fgs?: string;
  fgm?: string;
  fgp?: string;
  level?: string;
  color?: string;
}

interface ShootHotResultDto {
  shootAreaDTOList?: ShootAreaDto[];
}

interface ShootHotRespDto {
  result?: ShootHotResultDto;
}

interface AwardDetailDto {
  season?: string;
  awardDate?: string;
}

interface AwardItemDto {
  awardDesc?: string;
  awardCount?: number;
  awardDetailList?: AwardDetailDto[];
}

interface AwardResultDto {
  awardSummaryList?: AwardItemDto[];
}

interface AwardRespDto {
  result?: AwardResultDto;
}

/* ---- 球员评分（games.mobileapi.hupu.com，无需签名） ---- */

interface ScoreStatsDto {
  playerId?: string;
  teamId?: string;
  number?: string;
  name?: string;
  alias?: string;
  photo?: string;
  logoUrl?: string;
  mins?: string;
  pts?: number;
  reb?: number;
  asts?: number;
  stl?: number;
  blk?: number;
  fgp?: string;
  position?: string;
  starter?: number;
  userScoreAvg?: number | null;
  userScoreCount?: number | null;
}

interface ScoreCommentDto {
  commentContent?: string | null;
}

interface ScorePlayerDto {
  playerOrStaffId?: string;
  stats?: ScoreStatsDto;
  comment?: ScoreCommentDto;
}

interface ScoreResultDto {
  players?: ScorePlayerDto[];
}

interface ScoreApiRespDto {
  result?: ScoreResultDto;
  success?: boolean;
}

/** NBA 模块接口（数据来自 m.hupu.com 页面内嵌 JSON） */
export class NbaApi {
  /** NBA 资讯流 */
  static async getNews(): Promise<NbaNewsItem[]> {
    const html: string = await HttpManager.get(`${BASE}/nba`);
    const json: string = NbaApi.extractNextData(html);
    const resp = JSON.parse(json) as NbaRespDto;
    const list = resp.props?.pageProps?.newsData;
    const result: NbaNewsItem[] = [];
    if (!list) {
      throw new Error('资讯数据为空');
    }
    for (const d of list) {
      const item: NbaNewsItem = new NbaNewsItem();
      item.nid = d.nid ?? '';
      item.tid = d.tid ?? '';
      item.title = d.title ?? '';
      item.img = d.img ?? '';
      item.lights = d.lights ?? 0;
      item.replies = d.replies ?? 0;
      item.publishTime = d.publishTime ?? '';
      result.push(item);
    }
    return result;
  }

  /** 赛程/比分（按比赛日分组） */
  static async getSchedule(): Promise<MatchDay[]> {
    const html: string = await HttpManager.get(`${BASE}/nba/schedule`);
    const json: string = NbaApi.extractNextData(html);
    const resp = JSON.parse(json) as NbaScheduleRespDto;
    const gameList = resp.props?.pageProps?.gameList;
    const result: MatchDay[] = [];
    if (!gameList) {
      throw new Error('赛程数据为空');
    }
    for (const g of gameList) {
      const day: MatchDay = new MatchDay();
      day.day = g.day ?? '';
      day.dayLabel = g.dayBlock ?? '';
      const matches = g.matchList ?? [];
      for (const m of matches) {
        day.matches.push(NbaApi.mapMatch(m));
      }
      if (day.matches.length > 0) {
        result.push(day);
      }
    }
    return result;
  }

  /** CBA 赛程/比分（与 NBA 同构） */
  static async getCbaSchedule(): Promise<MatchDay[]> {
    const html: string = await HttpManager.get(`${BASE}/cba/schedule`);
    const json: string = NbaApi.extractNextData(html);
    const resp = JSON.parse(json) as NbaScheduleRespDto;
    const gameList = resp.props?.pageProps?.gameList;
    const result: MatchDay[] = [];
    if (!gameList) {
      throw new Error('赛程数据为空');
    }
    for (const g of gameList) {
      const day: MatchDay = new MatchDay();
      day.day = g.day ?? '';
      day.dayLabel = g.dayBlock ?? '';
      const matches = g.matchList ?? [];
      for (const m of matches) {
        day.matches.push(NbaApi.mapMatch(m));
      }
      if (day.matches.length > 0) {
        result.push(day);
      }
    }
    return result;
  }

  /** 投篮热图（stage: REGULAR / PLAYOFF） */
  static async getShootHotMap(playerId: string, leagueType: string, stage: string): Promise<ShootZone[]> {
    const url: string =
      `https://games.mobileapi.hupu.com/1/7.5.29/basketballapi/shootHotMap?playerId=${playerId}` +
        `&competitionLeagueType=${leagueType}&competitionType=${leagueType}&competitionStageType=${stage}`;
    const resp = await HttpManager.getJson<ShootHotRespDto>(url);
    const list = resp.result?.shootAreaDTOList;
    const result: ShootZone[] = [];
    if (!list) {
      return result;
    }
    for (const d of list) {
      const z: ShootZone = new ShootZone();
      z.areaId = NbaApi.toIntSafe(d.areaId);
      z.fgs = NbaApi.toIntSafe(d.fgs);
      z.fgm = NbaApi.toIntSafe(d.fgm);
      z.fgp = d.fgp ?? '';
      z.level = NbaApi.toIntSafe(d.level);
      z.color = d.color ?? '';
      result.push(z);
    }
    return result;
  }

  /** 球员荣誉列表 */
  static async getPlayerAwards(playerId: string, leagueType: string): Promise<AwardItem[]> {
    const url: string =
      `https://games.mobileapi.hupu.com/1/7.5.29/basketballapi/playerAwardList?playerId=${playerId}` +
        `&competitionLeagueType=${leagueType}&competitionType=${leagueType}`;
    const resp = await HttpManager.getJson<AwardRespDto>(url);
    const list = resp.result?.awardSummaryList;
    const result: AwardItem[] = [];
    if (!list) {
      return result;
    }
    for (const d of list) {
      const item: AwardItem = new AwardItem();
      item.name = d.awardDesc ?? '';
      item.count = d.awardCount ?? 0;
      const details = d.awardDetailList ?? [];
      for (const dd of details) {
        const text: string = (dd.awardDate && dd.awardDate.length > 0) ? dd.awardDate : (dd.season ?? '');
        if (text.length > 0) {
          item.dates.push(text);
        }
      }
      result.push(item);
    }
    return result;
  }

  private static toIntSafe(v: string | undefined): number {
    if (!v) {
      return 0;
    }
    const n: number = Number.parseInt(v);
    return Number.isNaN(n) ? 0 : n;
  }

  /** 球员头部信息（资料页头部） */
  static async getPlayerHeadInfo(playerId: string, leagueType: string): Promise<PlayerHeadInfo> {
    const url: string =
      `https://games.mobileapi.hupu.com/1/7.5.29/basketballapi/playerPageHeadInfo?playerId=${playerId}&leagueType=${leagueType}`;
    const resp = await HttpManager.getJson<PlayerHeadRespDto>(url);
    const p = resp.result?.player;
    const info: PlayerHeadInfo = new PlayerHeadInfo();
    if (!p || !p.playerId) {
      throw new Error('暂无球员资料');
    }
    info.playerId = p.playerId ?? '';
    info.name = p.name ?? '';
    info.alias = p.alias ?? '';
    info.engName = p.eng_name ?? '';
    info.nick = p.nick ?? '';
    info.number = p.number ?? '';
    info.position = p.position ?? '';
    info.age = p.age ?? '';
    info.height = p.height ?? '';
    info.weight = p.weight ?? '';
    info.country = p.country ?? '';
    info.college = p.college_school ?? '';
    info.draftYear = p.draft_year === undefined || p.draft_year === null ? '' : `${p.draft_year}`;
    info.draftRound = p.draftRound ?? 0;
    info.draftPick = p.draftPick ?? 0;
    info.salary = p.salary ?? 0;
    info.contract = p.contractDetails ?? '';
    info.teamName = p.teamName ?? '';
    info.teamLogo = p.teamLogoLink ?? '';
    info.photo = p.photo ?? '';
    info.birthDate = p.birth_date ?? '';
    return info;
  }

  /** 球员赛季数据（基础/进阶 × 季前/常规/季后，含联盟排名） */
  static async getPlayerSeasonStats(playerId: string, leagueType: string): Promise<PlayerSeasonData> {
    const url: string =
      `https://games.mobileapi.hupu.com/1/7.5.29/basketballapi/playerSeasonStats?playerId=${playerId}` +
        `&competitionLeagueType=${leagueType}&competitionType=${leagueType}`;
    const resp = await HttpManager.getJson<SeasonStatsRespDto>(url);
    const r = resp.result;
    const data: PlayerSeasonData = new PlayerSeasonData();
    if (!r || !r.dataDimensionMap) {
      throw new Error('暂无赛季数据');
    }
    data.season = r.season ?? '';
    data.anchorStage = r.anchorCompetitionStageType ?? '';
    const basic = r.dataDimensionMap['basic'];
    if (basic && basic.competitionStagePackListMap) {
      data.basicStages = NbaApi.mapStages(basic.competitionStagePackListMap);
    }
    const advanced = r.dataDimensionMap['advanced'];
    if (advanced && advanced.competitionStagePackListMap) {
      data.advancedStages = NbaApi.mapStages(advanced.competitionStagePackListMap);
    }
    return data;
  }

  private static mapStages(pack: Record<string, StatItemDto[]>): PlayerStageStats[] {
    const result: PlayerStageStats[] = [];
    for (const key of ['PRESEASON', 'REGULAR', 'PLAYOFF']) {
      const arr = pack[key];
      if (!arr) {
        continue;
      }
      const stage: PlayerStageStats = new PlayerStageStats();
      stage.stage = key;
      stage.label = NbaApi.stageLabel(key);
      for (const it of arr) {
        const item: PlayerStatItem = new PlayerStatItem();
        item.name = it.name ?? '';
        item.cnName = it.cnName ?? '';
        item.quota = it.quota ?? '';
        item.rank = it.rank ?? 0;
        item.leagueAvg = it.leagueAvgValue ?? '';
        item.leagueMax = it.leagueMaxValue ?? '';
        stage.items.push(item);
      }
      if (stage.items.length > 0) {
        result.push(stage);
      }
    }
    return result;
  }

  private static stageLabel(stage: string): string {
    if (stage === 'PRESEASON') {
      return '季前赛';
    }
    if (stage === 'REGULAR') {
      return '常规赛';
    }
    if (stage === 'PLAYOFF') {
      return '季后赛';
    }
    return stage;
  }

  /** 球员评分详情（含评分分布分档，来自 basketball-player-score SSR 页面） */
  static async getPlayerScoreDetail(matchId: string, playerId: string): Promise<PlayerScoreDetail> {
    const url: string = `${BASE}/basketball-player-score?id=${playerId}&matchId=${matchId}&role=player`;
    const html: string = await HttpManager.get(url);
    const json: string = NbaApi.extractNextData(html);
    const resp = JSON.parse(json) as ScoreDetailRespDto;
    const info = resp.props?.pageProps?.scoreInfo?.playerInfo;
    const detail: PlayerScoreDetail = new PlayerScoreDetail();
    if (!info || !info.playerId) {
      throw new Error('暂无该球员评分数据');
    }
    detail.playerName = info.name ?? '';
    detail.alias = info.alias ?? '';
    detail.number = info.number ?? '';
    detail.position = info.position ?? '';
    detail.photo = info.photo ?? info.logoUrl ?? '';
    detail.mins = info.mins ?? '';
    detail.pts = info.pts ?? 0;
    detail.reb = info.reb ?? 0;
    detail.asts = info.asts ?? 0;
    detail.stl = info.stl ?? 0;
    detail.blk = info.blk ?? 0;
    detail.twoPoints = info.twoPoints ?? '';
    detail.threePoints = info.threePoints ?? '';
    detail.ft = info.ft ?? '';
    detail.fgp = info.fgp ?? '';
    detail.tpp = info.tpp ?? '';
    detail.plusMinus = info.plusMinus ?? '';
    detail.scoreAvg = info.userScoreAvg ?? 0;
    detail.scoreCount = info.userScoreCount ?? 0;
    // 评分分布：{ "2":n, "4":n, "6":n, "8":n, "10":n }
    const dist = resp.props?.pageProps?.scoreInfo?.scoreDistribution;
    const buckets: ScoreBucket[] = [];
    if (dist) {
      for (const key of ['2', '4', '6', '8', '10']) {
        const b: ScoreBucket = new ScoreBucket();
        b.score = Number.parseInt(key);
        b.count = dist[key] ?? 0;
        buckets.push(b);
      }
    }
    detail.buckets = buckets;
    return detail;
  }

  /** 比赛球员评分（两队分别调用，返回按评分降序） */
  static async getMatchScores(matchId: string, teamId: string): Promise<PlayerScoreRow[]> {
    const url: string =
      `https://games.mobileapi.hupu.com/1/7.5.29/basketballapi/teamMatchRosterScoreStats?matchId=${matchId}&teamId=${teamId}&userId=`;
    const resp = await HttpManager.getJson<ScoreApiRespDto>(url);
    const players = resp.result?.players;
    const result: PlayerScoreRow[] = [];
    if (!players) {
      return result;
    }
    for (const p of players) {
      const s = p.stats;
      if (!s) {
        continue;
      }
      const row: PlayerScoreRow = new PlayerScoreRow();
      row.playerId = s.playerId ?? p.playerOrStaffId ?? '';
      row.teamId = s.teamId ?? teamId;
      row.name = s.name ?? '';
      row.alias = s.alias ?? '';
      row.number = s.number ?? '';
      row.position = s.position ?? '';
      row.photo = s.photo ?? s.logoUrl ?? '';
      row.mins = s.mins ?? '';
      row.pts = s.pts ?? 0;
      row.reb = s.reb ?? 0;
      row.ast = s.asts ?? 0;
      row.stl = s.stl ?? 0;
      row.blk = s.blk ?? 0;
      row.fgp = s.fgp ?? '';
      row.starter = s.starter === 1;
      row.scoreAvg = s.userScoreAvg ?? 0;
      row.scoreCount = s.userScoreCount ?? 0;
      row.comment = p.comment?.commentContent ?? '';
      result.push(row);
    }
    result.sort((a: PlayerScoreRow, b: PlayerScoreRow): number => b.scoreAvg - a.scoreAvg);
    return result;
  }

  private static mapMatch(m: NbaMatchDto): MatchItem {
    const item: MatchItem = new MatchItem();
    item.matchId = m.matchId ?? '';
    item.status = m.matchStatus ?? '';
    item.statusCn = m.matchStatusChinese ?? '';
    item.statusDesc = m.frontEndMatchStatus?.desc ?? '';
    item.homeName = m.homeTeamName ?? '';
    item.awayName = m.awayTeamName ?? '';
    item.homeTeamId = m.homeTeamId ?? '';
    item.awayTeamId = m.awayTeamId ?? '';
    item.homeLogo = m.homeTeamLogo ?? '';
    item.awayLogo = m.awayTeamLogo ?? '';
    item.homeScore = m.homeScore === null || m.homeScore === undefined ? '' : `${m.homeScore}`;
    item.awayScore = m.awayScore === null || m.awayScore === undefined ? '' : `${m.awayScore}`;
    item.matchTime = m.matchTime ?? '';
    item.stage = m.competitionStageDesc ?? '';
    item.scorePv = m.score ?? '';
    return item;
  }

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
}
