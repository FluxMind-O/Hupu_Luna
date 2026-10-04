/**
 * 虎扑官方账号名单（用于"官方资讯优先"频道过滤）
 *
 * 背景：话题帖子流接口（topicThreads）不区分官方与个人内容——
 * 官方号（如"虎扑体坛资讯"）与普通用户字段完全一致（certTitle 均为 null），
 * 且 &isNews=1 / &type=news 等过滤参数全部无效（实测返回结果不变）。
 * 因此只能按作者名做白名单过滤。
 *
 * 数据来源（2026-10-04 实测）：
 * - 搜索接口 `m.hupu.com/api/v2/search2?...&type=users` 返回账号的 title 字段，
 *   官方号带"官方账号/官方帐号/官方运营账号"等标记；
 * - App 搜索页"用户"标签的官方号列表（带虎字认证徽章）；
 * - 跨话题发文统计（官方号会跨多个话题发帖，普通用户极少跨话题）。
 *
 * 注意：**不能用"虎扑"前缀判定**——"虎扑JR1234567"是普通用户默认昵称，
 * 且存在大量以"虎扑"开头的个人昵称（虎扑体育生、虎扑黑子不懂球等）。
 */
export class OfficialAccounts {
  /** 官方账号名单（精确匹配作者名） */
  private static readonly NAMES: string[] = [
    // 资讯类（带"官方账号"标记 + 高被推荐数）
    '虎扑篮球资讯',
    '虎扑足球资讯',
    '虎扑体坛资讯',
    '虎扑游戏电竞资讯',
    '虎扑影视资讯',
    '虎扑汽车资讯',
    '虎扑数码资讯',
    '虎扑动漫资讯',
    '虎扑运动资讯',
    '虎扑玩具资讯',
    // 平台号（带"官方帐号"标记）
    '虎扑游戏',
    '虎扑的步行街',
    '虎扑影视',
    '虎扑足球',
    '虎扑直播',
    '虎扑篮球',
    '虎扑CBA',
    '虎扑电竞',
    '虎扑字幕组',
    '虎扑团队',
    '虎扑站务组',
    '虎扑游戏官方账号',
    '虎扑潮流装备',
    '虎扑海报',
    '虎扑H币中心',
    '虎扑众测官方账号',
    '中篮联官方小马甲',
    // 高被推荐数平台号
    '虎扑卧谈会',
    '虎扑吃货毛哥',
    '虎扑典藏馆',
    '虎扑识货',
    '虎扑专家预测',
    '虎扑广播站',
    '虎扑评分小助手',
    '虎扑装备区',
    '虎扑小卖部',
    '虎扑CUBAL',
    '虎扑跑步区',
    '虎扑放映厅',
    '虎扑综合体育',
    '虎扑客服',
    '虎扑小志玲',
    // 小助手系列
    '虎扑装备小助手',
    '虎扑热点小助手',
    '虎扑社区小助手',
    '虎扑播客小助手',
    '虎扑前线小助手',
    '虎扑创作小助手',
    '虎扑影视小助手',
    '扑电小助手',
    // 其他官方/签约号
    '虎扑选秀日官方',
    '解说米勒',
    '解说雨童',
    '解说Remember',
    '解说毛毛',
    '解说柯基',
    '解说瓶子'
  ];

  private static index: Map<string, boolean> = OfficialAccounts.buildIndex();

  private static buildIndex(): Map<string, boolean> {
    const map: Map<string, boolean> = new Map<string, boolean>();
    for (const n of OfficialAccounts.NAMES) {
      map.set(n, true);
    }
    return map;
  }

  /** 是否官方账号（按作者名精确匹配） */
  static isOfficial(name: string): boolean {
    if (name.length === 0) {
      return false;
    }
    return OfficialAccounts.index.get(name) === true;
  }

  /** 官方账号总数（调试/统计用） */
  static count(): number {
    return OfficialAccounts.NAMES.length;
  }
}
