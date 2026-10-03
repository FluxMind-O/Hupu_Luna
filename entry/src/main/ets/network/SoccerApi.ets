import { HttpManager } from './HttpManager';
import { SoccerMatchItem, MatchDay, MatchItem, BattleEvent, BattleStat, BattleReport } from '../model/Models';

/* ---- battleReport 接口结构 ---- */

interface BattleEventDto {
  title?: string;
  gifImgs?: string[];
  eventType?: string;
  eventTimeStr?: string;
}

interface BattleStatItemDto {
  name?: string;
  homeVal?: string;
  awayVal?: string;
}

interface BattleTeamStatsDto {
  itemList?: BattleStatItemDto[];
}

interface BattleReportResultDto {
  beginContent?: string;
  img?: string;
  keyEvent?: BattleEventDto[];
  normalEvent?: BattleEventDto[];
  matchTeamStats?: BattleTeamStatsDto;
  teamLineup?: string;
}

interface BattleReportRespDto {
  result?: BattleReportResultDto;
  success?: boolean;
}

const BASE: string = 'https://m.hupu.com';

/* ---- m.hupu.com/soccer/schedule 页面内嵌结构 ---- */

interface SoccerTeamDto {
  teamId?: number;
  name?: string;
  logo?: string;
  id?: number;
}

interface SoccerStatusDto {
  id?: number;
  txt?: string;
}

interface SoccerMatchDto {
  matchId?: string;
  title?: string;
  home?: SoccerTeamDto;
  away?: SoccerTeamDto;
  home_score?: number;
  away_score?: number;
  status?: SoccerStatusDto;
  begin_time?: number;
  pv?: string | null;
  competitionId?: string;
}

interface SoccerDayDto {
  day?: string;
  date_block?: string;
  data?: SoccerMatchDto[];
}

interface SoccerDaysMetaDto {
  current?: string;
}

interface SoccerDataDto {
  days?: SoccerDaysMetaDto;
  games?: SoccerDayDto[];
}

interface SoccerPagePropsDto {
  data?: SoccerDataDto;
}

interface SoccerPropsDto {
  pageProps?: SoccerPagePropsDto;
}

interface SoccerNextRespDto {
  props?: SoccerPropsDto;
}

/** 足球数据接口（数据来自 m.hupu.com/soccer 系列页面） */
export class SoccerApi {
  /**
   * 与当前日期最相关的比赛（今天优先；无则取最近未来一天；再无可取最近过去一天）
   */
  static async getRelevantMatches(): Promise<SoccerMatchItem[]> {
    const html: string = await HttpManager.get(`${BASE}/soccer/schedule`);
    const json: string = SoccerApi.extractNextData(html);
    const resp = JSON.parse(json) as SoccerNextRespDto;
    const games = resp.props?.pageProps?.data?.games;
    if (!games || games.length === 0) {
      throw new Error('赛程数据为空');
    }
    const today: string = SoccerApi.todayStr();
    let target: SoccerDayDto | null = null;
    let nearestFuture: SoccerDayDto | null = null;
    let nearestPast: SoccerDayDto | null = null;
    for (const g of games) {
      const d: string = g.day ?? '';
      if (d === today) {
        target = g;
        break;
      }
      if (d > today) {
        if (nearestFuture === null || d < (nearestFuture.day ?? '')) {
          nearestFuture = g;
        }
      } else {
        if (nearestPast === null || d > (nearestPast.day ?? '')) {
          nearestPast = g;
        }
      }
    }
    if (target === null) {
      target = nearestFuture !== null ? nearestFuture : nearestPast;
    }
    const result: SoccerMatchItem[] = [];
    if (target === null) {
      return result;
    }
    const matches = target.data ?? [];
    for (const m of matches) {
      result.push(SoccerApi.mapMatch(m));
    }
    return result;
  }

  /** 全部比赛日（按日分组，用于"近期全部热门比赛"列表页） */
  static async getAllDays(): Promise<MatchDay[]> {
    const html: string = await HttpManager.get(`${BASE}/soccer/schedule`);
    const json: string = SoccerApi.extractNextData(html);
    const resp = JSON.parse(json) as SoccerNextRespDto;
    const games = resp.props?.pageProps?.data?.games;
    const result: MatchDay[] = [];
    if (!games) {
      throw new Error('赛程数据为空');
    }
    for (const g of games) {
      const day: MatchDay = new MatchDay();
      day.day = g.day ?? '';
      day.dayLabel = g.date_block ?? '';
      const matches = g.data ?? [];
      for (const m of matches) {
        const item: MatchItem = new MatchItem();
        item.matchId = m.matchId ?? '';
        item.homeName = m.home?.name ?? '';
        item.awayName = m.away?.name ?? '';
        item.homeLogo = m.home?.logo ?? '';
        item.awayLogo = m.away?.logo ?? '';
        item.homeScore = m.home_score === undefined || m.home_score === null ? '' : `${m.home_score}`;
        item.awayScore = m.away_score === undefined || m.away_score === null ? '' : `${m.away_score}`;
        item.stage = m.title ?? '';
        const isDone: boolean = (m.status?.id ?? 0) === 4;
        item.status = isDone ? 'COMPLETED' : 'NOTSTARTED';
        item.statusCn = m.status?.txt ?? '';
        item.scorePv = m.pv ?? '';
        item.matchTime = SoccerApi.hhmm(m.begin_time ?? 0);
        day.matches.push(item);
      }
      if (day.matches.length > 0) {
        result.push(day);
      }
    }
    return result;
  }

  /** 比赛战报（正文 + 关键事件 + 球队数据 + 阵容），足球与篮球均可用 */
  static async getBattleReport(matchId: string): Promise<BattleReport> {
    const url: string =
      `https://games.mobileapi.hupu.com/1/7.5.36/basketballapi/news/battleReport?relationId=${matchId}&relationType=BATTLE_REPORT`;
    const resp = await HttpManager.getJson<BattleReportRespDto>(url);
    const r = resp.result;
    const report: BattleReport = new BattleReport();
    if (!r) {
      throw new Error('暂无战报数据');
    }
    report.content = r.beginContent ?? '';
    report.img = r.img ?? '';
    report.lineup = r.teamLineup ?? '';
    // 关键事件在前，正常事件在后（各自保持原顺序）
    const keys = r.keyEvent ?? [];
    for (const e of keys) {
      report.events.push(SoccerApi.mapEvent(e, true));
    }
    const normals = r.normalEvent ?? [];
    for (const e of normals) {
      report.events.push(SoccerApi.mapEvent(e, false));
    }
    const items = r.matchTeamStats?.itemList ?? [];
    for (const s of items) {
      const stat: BattleStat = new BattleStat();
      stat.name = s.name ?? '';
      stat.homeVal = s.homeVal ?? '';
      stat.awayVal = s.awayVal ?? '';
      report.stats.push(stat);
    }
    return report;
  }

  private static mapEvent(e: BattleEventDto, isKey: boolean): BattleEvent {
    const ev: BattleEvent = new BattleEvent();
    ev.time = e.eventTimeStr ?? '';
    ev.title = e.title ?? '';
    const gifs = e.gifImgs ?? [];
    if (gifs.length > 0) {
      ev.gif = gifs[0];
    }
    ev.isKey = isKey;
    return ev;
  }

  /** 时间戳 → HH:mm */
  static hhmm(sec: number): string {
    if (sec <= 0) {
      return '';
    }
    const d: Date = new Date(sec * 1000);
    const hh: number = d.getHours();
    const mm: number = d.getMinutes();
    return `${hh < 10 ? '0' + hh : hh}:${mm < 10 ? '0' + mm : mm}`;
  }

  static todayStr(): string {
    const now: Date = new Date();
    const y: number = now.getFullYear();
    const mo: number = now.getMonth() + 1;
    const da: number = now.getDate();
    return `${y}${mo < 10 ? '0' + mo : mo}${da < 10 ? '0' + da : da}`;
  }

  private static mapMatch(m: SoccerMatchDto): SoccerMatchItem {
    const item: SoccerMatchItem = new SoccerMatchItem();
    item.matchId = m.matchId ?? '';
    item.title = m.title ?? '';
    item.homeName = m.home?.name ?? '';
    item.awayName = m.away?.name ?? '';
    item.homeLogo = m.home?.logo ?? '';
    item.awayLogo = m.away?.logo ?? '';
    item.homeScore = m.home_score === undefined || m.home_score === null ? '' : `${m.home_score}`;
    item.awayScore = m.away_score === undefined || m.away_score === null ? '' : `${m.away_score}`;
    item.statusId = m.status?.id ?? 0;
    item.statusTxt = m.status?.txt ?? '';
    item.beginTime = m.begin_time ?? 0;
    item.pv = m.pv ?? '';
    item.timeText = SoccerApi.formatTime(item.beginTime);
    return item;
  }

  /** 时间戳 → 今天/明天/昨天 HH:mm 或 MM-DD HH:mm */
  static formatTime(sec: number): string {
    if (sec <= 0) {
      return '';
    }
    const d: Date = new Date(sec * 1000);
    const now: Date = new Date();
    const hh: number = d.getHours();
    const mm: number = d.getMinutes();
    const hm: string = `${hh < 10 ? '0' + hh : hh}:${mm < 10 ? '0' + mm : mm}`;
    const dayMs: number = 24 * 3600 * 1000;
    const startOfToday: number = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
    const startOfThat: number = new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime();
    const diffDays: number = Math.round((startOfThat - startOfToday) / dayMs);
    if (diffDays === 0) {
      return `今天 ${hm}`;
    }
    if (diffDays === 1) {
      return `明天 ${hm}`;
    }
    if (diffDays === -1) {
      return `昨天 ${hm}`;
    }
    const mo: number = d.getMonth() + 1;
    const da: number = d.getDate();
    return `${mo < 10 ? '0' + mo : mo}-${da < 10 ? '0' + da : da} ${hm}`;
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
