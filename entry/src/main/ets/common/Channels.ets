/**
 * 首页频道目录
 * kind: hot=热榜 / recommend=推荐(walkingStreet) / nba=NBA资讯 / schedule=赛程比分 / topic=分区帖子流
 * matchLeague: 该频道顶部嵌入的比赛条数据源（''=不显示） / 'nba' / 'cba' / 'soccer'
 * newsSource: 官方资讯源（''=无，走帖子流）；非空时该频道展示官方资讯而非个人帖子
 *   —— m 站仅提供 nba / cba / soccer 三个官方资讯页，其余话题无资讯源
 * officialSources: 该频道的官方号 puid 列表（逗号分隔）。
 *   官方号主页 `m.hupu.com/user/{puid}` 一次返回 20 条跨板块发文，
 *   按 topicId 过滤即得到本频道官方帖——这是官方内容的主数据源
 *   （话题帖子流官方帖稀疏且分页失效，仅作补充）。
 *   为空表示不做官方过滤（社区属性话题，个人发帖即内容常态）。
 *
 * 上拉加载历史：`topicId`（配合 officialSources 过滤）决定历史捞取来源，
 *   均走 PC 话题页分页 `bbs.hupu.com/{topicId}-{N}`：
 *   - 资讯类频道（newsSource 非空）首屏为官方资讯页（固定 30+ 条），
 *     上拉时用 topicId 对应的**资讯板块**捞官方历史（实测单板块 6~8 页即有 300+ 条）；
 *   - 注意资讯板块 ≠ 讨论区：国际足球用 482（国际足球资讯）而非 184（足球话题区，
 *     用户讨论为主，官方帖 6 页仅 1 条）；中国篮球用 173（CBA专区）；NBA 用 502（篮球资讯）。
 */
export class ChannelDef {
  id: string = '';
  name: string = '';
  kind: string = '';
  topicId: number = 0;
  matchLeague: string = '';
  newsSource: string = '';
  officialSources: string = '';
  /**
   * 历史加载用的搜索关键词（'' = 走 PC 话题页）。
   * 资讯频道用此法是因为 **PC 话题页不提供图片**，而资讯页首屏有图，
   * 两段展示不一致；`search2` 搜索结果带 `picture` 封面且分页有效，
   * 配合 `topicId`（作为 fid 过滤）即可得到带图的官方资讯历史。
   */
  historyKeyword: string = '';
}

export class ChannelKind {
  static readonly HOT: string = 'hot';
  static readonly RECOMMEND: string = 'recommend';
  static readonly NBA: string = 'nba';
  static readonly SCHEDULE: string = 'schedule';
  static readonly TOPIC: string = 'topic';
}

/** 官方资讯源白名单：误填其它值会被丢弃，避免错配到别的频道数据 */
const NEWS_SOURCES: string[] = ['nba', 'cba', 'soccer'];

function def(id: string, name: string, kind: string, topicId: number = 0, league: string = '',
  news: string = '', officialSources: string = '', historyKeyword: string = ''): ChannelDef {
  const c: ChannelDef = new ChannelDef();
  c.id = id;
  c.name = name;
  c.kind = kind;
  c.topicId = topicId;
  c.matchLeague = league;
  // 仅接受白名单内的资讯源：非法值一律忽略，回落帖子流（防参数错位静默显示错误内容）
  c.newsSource = NEWS_SOURCES.indexOf(news) >= 0 ? news : '';
  c.officialSources = officialSources;
  c.historyKeyword = historyKeyword;
  return c;
}

/**
 * 官方号 puid（2026-10-04 实测，含各号在本站的板块发文分布）
 * 虎扑体坛资讯     93956731  综合体育10/网球场4/乒乓球3/奥运会1/F1·1
 * 虎扑篮球资讯     56098302  篮球资讯5/湿乎乎5/CBA3
 * 虎扑篮球           25948   湿乎乎12
 * 虎扑足球资讯     83276249  国际足球资讯3
 * 虎扑足球            4168925  足球话题区13/中国足球6
 * 虎扑影视资讯     55150048  娱乐圈13/影视区7
 * 虎扑影视         18912543  娱乐圈9/影视区1
 * 虎扑数码资讯    112446935  数码综合讨论20
 * 虎扑汽车资讯    112474163  汽车区20
 * 虎扑装备小助手    96772422  运动装备20
 * 虎扑游戏         14513993  游戏区14
 * 虎扑游戏电竞资讯  94991862  王者荣耀16/无畏契约1
 * 虎扑电竞         17215809  无畏契约1
 */
const ALL_LIST: ChannelDef[] = [
  def('hot', '热榜', ChannelKind.HOT),
  def('recommend', '推荐', ChannelKind.RECOMMEND),
  // 资讯频道：首屏走 newsSource 资讯页（有图），
  // 上拉历史走 searchThreads(historyKeyword) + fid(=topicId) 过滤（带图，与首屏一致）
  def('nba', 'NBA', ChannelKind.NBA, 502, 'nba', 'nba', '56098302', '流言板'),
  def('intl_football', '国际足球', ChannelKind.TOPIC, 482, 'soccer', 'soccer', '83276249', '流言板'),
  def('cba', '中国篮球', ChannelKind.TOPIC, 173, 'cba', 'cba', '56098302', 'CBA'),
  def('schedule', '赛程比分', ChannelKind.SCHEDULE),
  def('csl', '中国足球', ChannelKind.TOPIC, 220, 'soccer', '', '4168925'),
  def('intl_fb_news', '国际足球资讯', ChannelKind.TOPIC, 482, 'soccer', '', '83276249'),
  def('bball_news', '篮球资讯', ChannelKind.TOPIC, 502, '', '', '56098302'),
  def('nba_talk', '湿乎乎的话题', ChannelKind.TOPIC, 177, '', '', '56098302,25948'),
  def('comprehensive', '综合体育', ChannelKind.TOPIC, 240, '', '', '93956731'),
  def('tennis', '网球场', ChannelKind.TOPIC, 245, '', '', '93956731'),
  def('pingpong', '乒乓球', ChannelKind.TOPIC, 246, '', '', '93956731'),
  def('olympics', '奥运会', ChannelKind.TOPIC, 753, '', '', '93956731'),
  def('equipment', '运动装备', ChannelKind.TOPIC, 255, '', '', '96772422'),
  def('movie', '影视区', ChannelKind.TOPIC, 60, '', '', '55150048,18912543'),
  def('star', '娱乐圈', ChannelKind.TOPIC, 59, '', '', '55150048,18912543'),
  def('digital', '数码综合讨论', ChannelKind.TOPIC, 294, '', '', '112446935'),
  def('auto', '汽车区', ChannelKind.TOPIC, 278, '', '', '112474163'),
  def('f1', 'F1赛车区', ChannelKind.TOPIC, 241, '', '', '93956731'),
  def('game', '游戏区', ChannelKind.TOPIC, 86, '', '', '14513993'),
  def('valorant', '无畏契约', ChannelKind.TOPIC, 803, '', '', '94991862,17215809'),
  def('honor', '王者荣耀', ChannelKind.TOPIC, 88, '', '', '94991862'),
  // 无官方号覆盖（实测无对应账号）：保留个人帖子流
  def('pubg', '和平精英', ChannelKind.TOPIC, 115),
  // 社区属性话题：个人发帖即内容常态，不做官方过滤
  def('walkway', '步行街主干道', ChannelKind.TOPIC, 1),
  def('love', '恋爱区', ChannelKind.TOPIC, 6),
  def('history', '历史区', ChannelKind.TOPIC, 12),
  def('acg', 'ACG圈', ChannelKind.TOPIC, 64)
];

const DEFAULT_IDS: string[] = ['hot', 'recommend', 'nba', 'intl_football', 'cba'];

export class ChannelCatalog {
  /** 全部可选频道 */
  static all(): ChannelDef[] {
    return ALL_LIST;
  }

  /** 默认频道（对齐官方：热榜/推荐/NBA/国际足球/中国篮球） */
  static defaults(): string[] {
    return DEFAULT_IDS;
  }

  /** 按 id 查找（找不到时回退到第一个） */
  static find(id: string): ChannelDef {
    for (const c of ALL_LIST) {
      if (c.id === id) {
        return c;
      }
    }
    return ALL_LIST[0];
  }

  /** 过滤未知 id */
  static sanitize(ids: string[]): string[] {
    const result: string[] = [];
    for (const id of ids) {
      let exists = false;
      for (const c of ALL_LIST) {
        if (c.id === id) {
          exists = true;
          break;
        }
      }
      if (exists) {
        let dup = false;
        for (const r of result) {
          if (r === id) {
            dup = true;
            break;
          }
        }
        if (!dup) {
          result.push(id);
        }
      }
    }
    return result;
  }
}
