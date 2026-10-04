/**
 * Hupu Luna 设计 token（尺寸/字号/圆角）
 * 颜色不在此处定义，一律走 resources 的 $r('app.color.*')，深浅色由 dark 目录自动切换。
 */
export class Spacing {
  static readonly xs: number = 4;
  static readonly sm: number = 8;
  static readonly md: number = 12;
  static readonly lg: number = 16;
  static readonly xl: number = 24;
}

export class FontSize {
  static readonly caption: number = 11;
  static readonly body: number = 14;
  static readonly title: number = 16;
  static readonly headline: number = 20;
}

export class Radius {
  static readonly sm: number = 6;
  static readonly md: number = 10;
  static readonly lg: number = 16;
}

/** 路由页名常量（NavPathStack 用） */
export class RouteName {
  static readonly POST_DETAIL: string = 'PostDetail';
  static readonly TOPIC_THREADS: string = 'TopicThreads';
  static readonly TAG_THREADS: string = 'TagThreads';
  static readonly SEARCH: string = 'Search';
  static readonly ALL_CHANNELS: string = 'AllChannels';
  static readonly IMAGE_VIEWER: string = 'ImageViewer';
  static readonly SETTINGS: string = 'Settings';
  static readonly MATCH_SCORE: string = 'MatchScore';
  static readonly MATCH_LIST: string = 'MatchList';
  static readonly MATCH_REPORT: string = 'MatchReport';
  static readonly PLAYER_SCORE: string = 'PlayerScore';
  static readonly PLAYER_PROFILE: string = 'PlayerProfile';
  static readonly LOGIN_WEB: string = 'LoginWeb';
  static readonly USER_SPACE: string = 'UserSpace';
  static readonly CREATE_THREAD: string = 'CreateThread';
}
