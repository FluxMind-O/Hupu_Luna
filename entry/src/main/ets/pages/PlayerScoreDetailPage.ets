import { NbaApi } from '../network/NbaApi';
import { PlayerScoreDetail, ScoreBucket, PlayerScoreRow, PlayerScoreComment } from '../model/Models';
import { LoadState, StateView } from '../views/StateView';
import { Spacing, Radius, RouteName } from '../common/Theme';
import { compactCount } from '../views/TagChip';
import { ImageKnifeComponent } from '@ohos/imageknife';
import { AppNavBar } from '../views/AppNavBar';
import { HupuUserInfo } from '../network/SessionManager';

const STAR_COUNT: number = 5;

/** 球员评分详情页（评分分布 + 本场数据 + 亮回复评论流 + 球员主页入口） */
@Component
export struct PlayerScoreDetailPage {
  /** 格式："matchId||playerId||fallbackName||teamId" */
  param: string = '';
  @Consume('pageStack') pageStack: NavPathStack;
  @State detail: PlayerScoreDetail = new PlayerScoreDetail();
  @State state: LoadState = LoadState.Loading;
  @State fallbackName: string = '';
  /** 评论流（官方 latestCommentList；roster 单条热评降级） */
  @State replies: PlayerScoreComment[] = [];
  /** 排序：""=最亮 / "latest"=最晚 / "early"=最早（官方三页签） */
  @State order: string = '';
  @State cursor: string = '';
  @State hasMore: boolean = false;
  @State loadingMore: boolean = false;
  @State repliesLoading: boolean = false;
  private matchId: string = '';
  private playerId: string = '';
  private teamId: string = '';
  /** roster 评分行缓存（enrich 与 fallback 共用，避免重复请求） */
  private rosterRows: PlayerScoreRow[] | null = null;

  aboutToAppear(): void {
    const parts: string[] = this.param.split('||');
    if (parts.length >= 2) {
      this.matchId = parts[0];
      this.playerId = parts[1];
    }
    if (parts.length >= 3) {
      this.fallbackName = parts[2];
    }
    if (parts.length >= 4) {
      this.teamId = parts[3];
    }
    this.load();
  }

  private async load(): Promise<void> {
    this.state = LoadState.Loading;
    try {
      const d: PlayerScoreDetail = await NbaApi.getPlayerScoreDetail(this.matchId, this.playerId);
      this.detail = d;
      this.state = LoadState.Ready;
      // roster 接口补齐：SSR 对评分数据空化（avg/count/分布），官方 App 数据在 roster
      this.enrichFromRoster();
      this.loadComments(true);
    } catch (e) {
      this.state = LoadState.Error;
    }
  }

  /** SSR 分布桶是否全 0（SSR 空化时返回 count 全 0 的桶，需用 roster 数据替换） */
  private bucketsEmpty(): boolean {
    let total: number = 0;
    for (const b of this.detail.buckets) {
      total = total + b.count;
    }
    return this.detail.buckets.length === 0 || total === 0;
  }

  /** 用 roster 接口数据补齐评分（SSR 空化修正）：总分/人数/分布 */
  private async enrichFromRoster(): Promise<void> {
    if (this.teamId.length === 0) {
      return;
    }
    try {
      const rows = await this.getRosterRows();
      for (const r of rows) {
        if (r.playerId !== this.playerId) {
          continue;
        }
        if (this.detail.scoreCount <= 0 && r.scoreCount > 0) {
          this.detail.scoreAvg = r.scoreAvg;
          this.detail.scoreCount = r.scoreCount;
        }
        if (this.bucketsEmpty() && r.scoreDistribution.length > 0) {
          this.detail.buckets = r.scoreDistribution;
        }
        break;
      }
    } catch (e) {
    }
  }

  /** roster 评分行（带缓存） */
  private async getRosterRows(): Promise<PlayerScoreRow[]> {
    if (this.rosterRows !== null) {
      return this.rosterRows;
    }
    const rows: PlayerScoreRow[] = await NbaApi.getMatchScores(this.matchId, this.teamId);
    this.rosterRows = rows;
    return rows;
  }

  /** 当前登录用户虎扑 uid（未登录为空） */
  private currentUid(): string {
    try {
      const s: string = AppStorage.get<string>('loginUserJson') ?? '';
      if (s.length === 0) {
        return '';
      }
      const u: HupuUserInfo = JSON.parse(s) as HupuUserInfo;
      return u.uid ?? '';
    } catch (e) {
      return '';
    }
  }

  /**
   * 加载评论流：官方 POST latestCommentList（需登录态）。
   * 接口成功且有数据 → replies = commentDTOList（reload）或追加（loadMore）；
   * 接口失败【或成功但 result 空（未登录/服务端不下发）】→ 降级 roster 单条热评（仅 reload）。
   */
  private async loadComments(reload: boolean): Promise<void> {
    if (this.repliesLoading) {
      return;
    }
    if (!reload && !this.hasMore) {
      return;
    }
    this.repliesLoading = true;
    let gotEmpty: boolean = false;
    try {
      const page = await NbaApi.getPlayerComments(this.matchId, this.playerId, this.currentUid(),
        this.order, reload ? '' : this.cursor);
      if (reload) {
        this.replies = page.list;
      } else {
        this.replies = this.replies.concat(page.list);
      }
      this.cursor = page.cursor;
      this.hasMore = page.cursor.length > 0;
      gotEmpty = reload && this.replies.length === 0;
    } catch (e) {
      gotEmpty = reload;
    }
    if (gotEmpty) {
      await this.loadFallbackComment();
    }
    this.repliesLoading = false;
  }

  /** 降级：roster 接口的该球员单条热评 */
  private async loadFallbackComment(): Promise<void> {
    const fallback: PlayerScoreComment[] = this.detail.comments.slice();
    if (this.teamId.length > 0) {
      try {
        const rows = await this.getRosterRows();
        for (const r of rows) {
          if (r.playerId !== this.playerId || r.comment.length === 0) {
            continue;
          }
          const dup: boolean = fallback.some((c: PlayerScoreComment) => c.content === r.comment);
          if (!dup) {
            const c: PlayerScoreComment = new PlayerScoreComment();
            c.content = r.comment;
            c.userName = r.commentUser;
            c.timeText = r.commentTime;
            c.lightCount = r.commentLights;
            // roster comment 无评论者信息（全 null），星级用球员本场均分近似渲染
            c.score = r.scoreAvg;
            fallback.push(c);
          }
          break;
        }
      } catch (e) {
      }
    }
    this.replies = fallback;
    this.hasMore = false;
  }

  /** 切换排序页签（最亮/最晚/最早） */
  private switchOrder(o: string): void {
    if (this.order === o || this.repliesLoading) {
      return;
    }
    this.order = o;
    this.cursor = '';
    this.hasMore = false;
    this.loadComments(true);
  }

  /** 打开球员主页 */
  private openProfile(): void {
    this.pageStack.pushPathByName(RouteName.PLAYER_PROFILE, `${this.playerId}||NBA`);
  }

  private scoreColor(v: number): ResourceColor {
    if (v >= 8) {
      return $r('app.color.score_blue');
    }
    if (v >= 6) {
      return $r('app.color.score_green');
    }
    return $r('app.color.text_secondary');
  }

  private filledStars(v: number): number {
    let n: number = Math.round(v / 2);
    if (n < 0) {
      n = 0;
    }
    if (n > STAR_COUNT) {
      n = STAR_COUNT;
    }
    return n;
  }

  private bucketTotal(): number {
    let total: number = 0;
    for (const b of this.detail.buckets) {
      total = total + b.count;
    }
    return total;
  }

  private bucketMax(): number {
    let max: number = 1;
    for (const b of this.detail.buckets) {
      if (b.count > max) {
        max = b.count;
      }
    }
    return max;
  }

  /** 分布条宽度：按占最大值比例（10% ~ 100%） */
  private bucketWidth(b: ScoreBucket): string {
    const max: number = this.bucketMax();
    const ratio: number = max <= 0 ? 0 : b.count / max;
    const percent: number = Math.max(6, Math.round(ratio * 100));
    return `${percent}%`;
  }

  @Builder
  HeaderCard() {
    Column({ space: 12 }) {
      Row({ space: 14 }) {
        ImageKnifeComponent({
          imageKnifeOption: {
            loadSrc: this.detail.photo,
            objectFit: ImageFit.Cover
          }
        })
          .width(76)
          .height(76)
          .borderRadius(38)

        Column({ space: 6 }) {
          Row({ space: 6 }) {
            if (this.detail.number.length > 0) {
              Text(`#${this.detail.number}`)
                .fontSize(13)
                .fontColor($r('app.color.text_tertiary'))
            }
            // 名字允许换行完整展示（官方形态），整行可点进资料
            Text(this.detail.playerName.length > 0 ? this.detail.playerName : this.fallbackName)
              .fontSize(19)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
            Text('›')
              .fontSize(20)
              .fontColor($r('app.color.text_tertiary'))
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
          .onClick(() => {
            this.openProfile();
          })
          if (this.detail.position.length > 0) {
            Text(`位置 ${this.detail.position}  ·  出场 ${this.detail.mins}`)
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
          }
          Row({ space: 8 }) {
            Row({ space: 1 }) {
              ForEach([0, 1, 2, 3, 4], (i: number) => {
                Text('★')
                  .fontSize(13)
                  .fontColor(i < this.filledStars(this.detail.scoreAvg) ? $r('app.color.comment_amber') : $r('app.color.text_tertiary'))
              }, (i: number) => `ps_star_${i}`)
            }
            Text('资料 ›')
              .fontSize(11)
              .fontColor($r('app.color.score_blue'))
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              .backgroundColor($r('app.color.tag_bg'))
              .borderRadius(10)
              .onClick(() => {
                this.openProfile();
              })
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Column({ space: 2 }) {
          Text(this.detail.scoreAvg > 0 ? this.detail.scoreAvg.toFixed(1) : '—')
            .fontSize(34)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.scoreColor(this.detail.scoreAvg))
          Text(this.detail.scoreCount > 0 ? `${compactCount(this.detail.scoreCount)} JRs评分` : '暂无评分')
            .fontSize(10)
            .fontColor($r('app.color.text_tertiary'))
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(Spacing.lg)
    .backgroundColor($r('app.color.bg_card'))
    .borderRadius(Radius.md)
  }

  @Builder
  DistributionCard() {
    Column({ space: 8 }) {
      Text(`评分分布（共 ${this.bucketTotal()} 人打分）`)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')

      ForEach(this.detail.buckets.slice().reverse(), (b: ScoreBucket) => {
        Row({ space: 8 }) {
          Text(`${b.score}分`)
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .width(34)
            .textAlign(TextAlign.End)
          Stack({ alignContent: Alignment.Start }) {
            Row()
              .width('100%')
              .height(10)
              .borderRadius(5)
              .backgroundColor($r('app.color.tag_bg'))
            Row()
              .width(this.bucketWidth(b))
              .height(10)
              .borderRadius(5)
              .backgroundColor(b.score >= 8 ? $r('app.color.score_blue')
                : (b.score >= 6 ? $r('app.color.score_green') : $r('app.color.comment_amber')))
          }
          .layoutWeight(1)
          .height(10)

          Text(`${b.count}`)
            .fontSize(12)
            .fontColor($r('app.color.text_tertiary'))
            .width(40)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }, (b: ScoreBucket) => `bk_${b.score}`)
    }
    .width('100%')
    .padding(Spacing.lg)
    .backgroundColor($r('app.color.bg_card'))
    .borderRadius(Radius.md)
  }

  @Builder
  StatCell(label: string, value: string) {
    Column({ space: 4 }) {
      Text(value.length > 0 ? value : '—')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .maxLines(1)
      Text(label)
        .fontSize(11)
        .fontColor($r('app.color.text_tertiary'))
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  StatsCard() {
    Column({ space: 10 }) {
      Text('本场数据')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')

      Row() {
        this.StatCell('得分', `${this.detail.pts}`)
        this.StatCell('篮板', `${this.detail.reb}`)
        this.StatCell('助攻', `${this.detail.asts}`)
        this.StatCell('抢断', `${this.detail.stl}`)
        this.StatCell('盖帽', `${this.detail.blk}`)
      }
      .width('100%')

      Row() {
        this.StatCell('命中率', this.detail.fgp)
        this.StatCell('三分', this.detail.threePoints)
        this.StatCell('三分%', this.detail.tpp)
        this.StatCell('罚球', this.detail.ft)
        this.StatCell('±值', this.detail.plusMinus)
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.lg)
    .backgroundColor($r('app.color.bg_card'))
    .borderRadius(Radius.md)
  }

  /** 单条亮回复：头像+名字+星级 → 内容 → 楼中楼引用 → 时间/点亮（官方排版） */
  @Builder
  CommentItem(c: PlayerScoreComment) {
    Row({ space: 10 }) {
      if (c.avatar.length > 0) {
        ImageKnifeComponent({
          imageKnifeOption: {
            loadSrc: c.avatar,
            objectFit: ImageFit.Cover
          }
        })
          .width(32)
          .height(32)
          .borderRadius(16)
      } else {
        Column() {
          Text('虎')
            .fontSize(13)
            .fontColor(Color.White)
        }
        .width(32)
        .height(32)
        .borderRadius(16)
        .backgroundColor($r('app.color.tag_bg'))
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }

      Column({ space: 6 }) {
        Row({ space: 8 }) {
          Text(c.userName.length > 0 ? c.userName : '虎扑JR')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          if (c.score > 0) {
            Row({ space: 1 }) {
              ForEach([0, 1, 2, 3, 4], (i: number) => {
                Text('★')
                  .fontSize(11)
                  .fontColor(i < this.filledStars(c.score) ? $r('app.color.comment_amber') : $r('app.color.text_tertiary'))
              }, (i: number) => `pc_star_${c.commentId}_${i}`)
            }
          }
        }
        .width('100%')

        Text(c.content)
          .fontSize(15)
          .lineHeight(23)
          .fontColor($r('app.color.text_primary'))
          .width('100%')

        if (c.replyToContent.length > 0) {
          Column({ space: 3 }) {
            Text(c.replyToUser.length > 0 ? `回复 @${c.replyToUser}` : '回复')
              .fontSize(11)
              .fontColor($r('app.color.score_blue'))
            Text(c.replyToContent)
              .fontSize(12)
              .lineHeight(18)
              .fontColor($r('app.color.text_secondary'))
              .maxLines(3)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .padding(8)
          .backgroundColor($r('app.color.tag_bg'))
          .borderRadius(8)
        }

        Row({ space: 8 }) {
          Text(c.timeText)
            .fontSize(11)
            .fontColor($r('app.color.text_tertiary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          if (c.lightCount > 0) {
            Row({ space: 3 }) {
              Text('⚡')
                .fontSize(11)
              Text(compactCount(c.lightCount))
                .fontSize(11)
                .fontColor($r('app.color.text_secondary'))
            }
          }
        }
        .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .padding({ top: 10, bottom: 10 })
  }

  @Builder
  CommentCard() {
    Column({ space: 8 }) {
      Row({ space: 4 }) {
        Text('亮回复')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        if (this.replies.length > 0) {
          Text(` /${this.replies.length}`)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
        }
        Blank()
        // 官方三页签：最亮 / 最晚 / 最早
        Row({ space: 0 }) {
          this.OrderTab('最亮', '')
          this.OrderTab('最晚', 'latest')
          this.OrderTab('最早', 'early')
        }
        .backgroundColor($r('app.color.tag_bg'))
        .borderRadius(8)
      }
      .width('100%')

      if (this.replies.length > 0) {
        ForEach(this.replies, (c: PlayerScoreComment, idx: number) => {
          Column() {
            this.CommentItem(c)
            if (idx < this.replies.length - 1) {
              Divider().color($r('app.color.divider'))
            }
          }
        }, (c: PlayerScoreComment, idx: number) => `pc_${this.order}_${idx}_${c.commentId}`)
      } else if (this.repliesLoading) {
        Row() {
          LoadingProgress()
            .width(20)
            .height(20)
            .color($r('app.color.text_tertiary'))
          Text('加载评论...')
            .fontSize(12)
            .fontColor($r('app.color.text_tertiary'))
            .margin({ left: 8 })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 14, bottom: 14 })
      } else {
        Text('暂无亮回复')
          .fontSize(13)
          .fontColor($r('app.color.text_tertiary'))
          .width('100%')
          .padding({ top: 8, bottom: 8 })
      }

      if (this.hasMore) {
        Text(this.repliesLoading ? '加载中...' : '加载更多评论')
          .fontSize(12)
          .fontColor($r('app.color.score_blue'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 8, bottom: 4 })
          .onClick(() => {
            this.loadComments(false);
          })
      }
    }
    .width('100%')
    .padding(Spacing.lg)
    .backgroundColor($r('app.color.bg_card'))
    .borderRadius(Radius.md)
  }

  /** 排序页签（官方样式：选中深色块） */
  @Builder
  OrderTab(label: string, value: string) {
    Text(label)
      .fontSize(11)
      .fontColor(this.order === value ? Color.White : $r('app.color.text_secondary'))
      .padding({ left: 10, right: 10, top: 4, bottom: 4 })
      .backgroundColor(this.order === value ? $r('app.color.text_tertiary') : Color.Transparent)
      .borderRadius(8)
      .onClick(() => {
        this.switchOrder(value);
      })
  }

  build() {
    NavDestination() {
      Column() {
        AppNavBar({ title: '球员评分' })
        if (this.state === LoadState.Ready) {
        Scroll() {
          Column({ space: 10 }) {
            this.HeaderCard()
            this.DistributionCard()
            this.StatsCard()
            this.CommentCard()
            Text('评分来自虎扑 JRs')
              .fontSize(11)
              .fontColor($r('app.color.text_tertiary'))
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding({ top: 8, bottom: 20 })
          }
          .padding(Spacing.lg)
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .backgroundColor($r('app.color.bg_page'))
      } else if (this.state === LoadState.Loading) {
        Column() {
          LoadingProgress()
            .width(36)
            .height(36)
            .color($r('app.color.text_tertiary'))
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .backgroundColor($r('app.color.bg_page'))
      } else {
        StateView({
          state: this.state,
          message: '暂无该球员评分数据',
          onRetry: () => {
            this.load();
          }
        })
          .width('100%')
          .layoutWeight(1)
          .backgroundColor($r('app.color.bg_page'))
      }
      }
    }
    .hideTitleBar(true)
    .backgroundColor($r('app.color.bg_page'))
  }
}
