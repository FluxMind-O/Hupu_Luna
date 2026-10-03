import { NbaApi } from '../network/NbaApi';
import { PlayerScoreDetail, ScoreBucket, PlayerScoreRow } from '../model/Models';
import { LoadState, StateView } from '../views/StateView';
import { Spacing, Radius, RouteName } from '../common/Theme';
import { compactCount } from '../views/TagChip';
import { ImageKnifeComponent } from '@ohos/imageknife';
import { AppNavBar } from '../views/AppNavBar';

const STAR_COUNT: number = 5;

/** 球员评分详情页（评分分布 + 本场数据 + 亮评 + 球员主页入口） */
@Component
export struct PlayerScoreDetailPage {
  /** 格式："matchId||playerId||fallbackName||teamId" */
  param: string = '';
  @Consume('pageStack') pageStack: NavPathStack;
  @State detail: PlayerScoreDetail = new PlayerScoreDetail();
  @State state: LoadState = LoadState.Loading;
  @State fallbackName: string = '';
  @State hotComment: string = '';
  private matchId: string = '';
  private playerId: string = '';
  private teamId: string = '';

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
      this.loadHotComment();
    } catch (e) {
      this.state = LoadState.Error;
    }
  }

  /** 热评：从球队评分数据中取该球员的一条亮评 */
  private async loadHotComment(): Promise<void> {
    if (this.teamId.length === 0) {
      return;
    }
    try {
      const rows: PlayerScoreRow[] = await NbaApi.getMatchScores(this.matchId, this.teamId);
      for (const r of rows) {
        if (r.playerId === this.playerId) {
          this.hotComment = r.comment;
          break;
        }
      }
    } catch (e) {
    }
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
          Row({ space: 8 }) {
            if (this.detail.number.length > 0) {
              Text(`#${this.detail.number}`)
                .fontSize(13)
                .fontColor($r('app.color.text_tertiary'))
            }
            Text(this.detail.playerName.length > 0 ? this.detail.playerName : this.fallbackName)
              .fontSize(19)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
            Text('资料 ›')
              .fontSize(12)
              .fontColor($r('app.color.score_blue'))
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              .backgroundColor($r('app.color.tag_bg'))
              .borderRadius(10)
              .onClick(() => {
                this.openProfile();
              })
          }
          if (this.detail.position.length > 0) {
            Text(`位置 ${this.detail.position}  ·  出场 ${this.detail.mins}`)
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
          }
          Row({ space: 1 }) {
            ForEach([0, 1, 2, 3, 4], (i: number) => {
              Text('★')
                .fontSize(13)
                .fontColor(i < this.filledStars(this.detail.scoreAvg) ? $r('app.color.comment_amber') : $r('app.color.text_tertiary'))
            }, (i: number) => `ps_star_${i}`)
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

  @Builder
  CommentCard() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Text('亮回复')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        Blank()
        Text('最亮')
          .fontSize(11)
          .fontColor($r('app.color.text_secondary'))
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .backgroundColor($r('app.color.tag_bg'))
          .borderRadius(8)
      }
      .width('100%')

      Text(`“${this.hotComment}”`)
        .fontSize(14)
        .lineHeight(22)
        .fontColor($r('app.color.comment_amber'))
        .width('100%')
        .padding({ left: 12, top: 2, bottom: 2 })
        .border({ width: { left: 3 }, color: $r('app.color.brand_primary') })

      Text('评论列表需在虎扑官方 App 中查看')
        .fontSize(10)
        .fontColor($r('app.color.text_tertiary'))
        .width('100%')
        .textAlign(TextAlign.End)
        .padding({ top: 4 })
    }
    .width('100%')
    .padding(Spacing.lg)
    .backgroundColor($r('app.color.bg_card'))
    .borderRadius(Radius.md)
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
            if (this.hotComment.length > 0) {
              this.CommentCard()
            }
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
