/**
 * 首页频道目录
 * kind: hot=热榜 / recommend=推荐(walkingStreet) / nba=NBA资讯 / schedule=赛程比分 / topic=分区帖子流
 * matchLeague: 该频道顶部嵌入的比赛条数据源（''=不显示） / 'nba' / 'cba' / 'soccer'
 */
export class ChannelDef {
  id: string = '';
  name: string = '';
  kind: string = '';
  topicId: number = 0;
  matchLeague: string = '';
}

export class ChannelKind {
  static readonly HOT: string = 'hot';
  static readonly RECOMMEND: string = 'recommend';
  static readonly NBA: string = 'nba';
  static readonly SCHEDULE: string = 'schedule';
  static readonly TOPIC: string = 'topic';
}

function def(id: string, name: string, kind: string, topicId: number = 0, league: string = ''): ChannelDef {
  const c: ChannelDef = new ChannelDef();
  c.id = id;
  c.name = name;
  c.kind = kind;
  c.topicId = topicId;
  c.matchLeague = league;
  return c;
}

const ALL_LIST: ChannelDef[] = [
  def('hot', '热榜', ChannelKind.HOT),
  def('recommend', '推荐', ChannelKind.RECOMMEND),
  def('nba', 'NBA', ChannelKind.NBA, 0, 'nba'),
  def('intl_football', '国际足球', ChannelKind.TOPIC, 184, 'soccer'),
  def('cba', '中国篮球', ChannelKind.TOPIC, 173, 'cba'),
  def('schedule', '赛程比分', ChannelKind.SCHEDULE),
  def('csl', '中国足球', ChannelKind.TOPIC, 220, 'soccer'),
  def('intl_fb_news', '国际足球资讯', ChannelKind.TOPIC, 482, 'soccer'),
  def('bball_news', '篮球资讯', ChannelKind.TOPIC, 502),
  def('nba_talk', '湿乎乎的话题', ChannelKind.TOPIC, 177),
  def('comprehensive', '综合体育', ChannelKind.TOPIC, 240),
  def('tennis', '网球场', ChannelKind.TOPIC, 245),
  def('pingpong', '乒乓球', ChannelKind.TOPIC, 246),
  def('olympics', '奥运会', ChannelKind.TOPIC, 753),
  def('equipment', '运动装备', ChannelKind.TOPIC, 255),
  def('movie', '影视区', ChannelKind.TOPIC, 60),
  def('star', '娱乐圈', ChannelKind.TOPIC, 59),
  def('digital', '数码综合讨论', ChannelKind.TOPIC, 294),
  def('auto', '汽车区', ChannelKind.TOPIC, 278),
  def('f1', 'F1赛车区', ChannelKind.TOPIC, 241),
  def('game', '游戏区', ChannelKind.TOPIC, 86),
  def('valorant', '无畏契约', ChannelKind.TOPIC, 803),
  def('honor', '王者荣耀', ChannelKind.TOPIC, 88),
  def('pubg', '和平精英', ChannelKind.TOPIC, 115),
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
