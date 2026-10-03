import { SoccerApi } from '../network/SoccerApi';
import { BattleReport, BattleEvent, BattleStat } from '../model/Models';
import { LoadState, StateView } from '../views/StateView';
import { Spacing, Radius, RouteName } from '../common/Theme';
import { ImageKnifeComponent } from '@ohos/imageknife';
import { AppNavBar } from '../views/AppNavBar';

/** 比赛战报页（正文 + 关键事件 + 球队数据 + 首发阵容） */
@Component
export struct MatchReportPage {
  /** 与评分页同格式 param（matchId 在第 0 段） */
  param: string = '';
  @Consume('pageStack') pageStack: NavPathStack;
  @State homeName: string = '';
  @State awayName: string = '';
  @State homeLogo: string = '';
  @State awayLogo: string = '';
  @State homeScore: string = '';
  @State awayScore: string = '';
  @State stage: string = '';
  @State pageTitle: string = '比赛战报';
  @State report: BattleReport = new BattleReport();
  @State state: LoadState = LoadState.Loading;
  private matchId: string = '';
  private homeTeamId: string = '';
  private awayTeamId: string = '';

  aboutToAppear(): void {
    const parts: string[] = this.param.split('||');
    if (parts.length >= 1) {
      this.matchId = parts[0];
    }
    if (parts.length >= 7) {
      this.homeTeamId = parts[1];
      this.awayTeamId = parts[2];
      this.homeName = parts[3];
      this.awayName = parts[4];
      this.homeScore = parts[5];
      this.awayScore = parts[6];
    }
    if (parts.length >= 9) {
      this.homeLogo = parts[7];
      this.awayLogo = parts[8];
    }
    if (parts.length >= 11) {
      this.stage = parts[9];
      if (parts[10].length > 0) {
        this.pageTitle = parts[10];
      }
    }
    this.load();
  }

  private async load(): Promise<void> {
    this.state = LoadState.Loading;
    try {
      const r: BattleReport = await SoccerApi.getBattleReport(this.matchId);
      this.report = r;
      const empty: boolean = r.content.length === 0 && r.events.length === 0 && r.stats.length === 0;
      this.state = empty ? LoadState.Empty : LoadState.Ready;
    } catch (e) {
      this.state = LoadState.Error;
    }
  }

  @Builder
  ScoreHeader() {
    Row() {
      Column({ space: 6 }) {
        ImageKnifeComponent({
          imageKnifeOption: {
            loadSrc: this.homeLogo,
            objectFit: ImageFit.Contain
          }
        })
          .width(48)
          .height(48)
        Text(this.homeName)
          .fontSize(13)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)

      Column({ space: 4 }) {
        if (this.stage.length > 0) {
          Text(this.stage)
            .fontSize(11)
            .fontColor($r('app.color.text_tertiary'))
            .maxLines(1)
        }
        Text(this.homeScore.length > 0 ? `${this.homeScore} - ${this.awayScore}` : 'VS')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Text('全场结束')
          .fontSize(10)
          .fontColor($r('app.color.text_tertiary'))
      }
      .width(140)
      .alignItems(HorizontalAlign.Center)

      Column({ space: 6 }) {
        ImageKnifeComponent({
          imageKnifeOption: {
            loadSrc: this.awayLogo,
            objectFit: ImageFit.Contain
          }
        })
          .width(48)
          .height(48)
        Text(this.awayName)
          .fontSize(13)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding(Spacing.lg)
    .backgroundColor($r('app.color.bg_card'))
  }

  @Builder
  SectionTitle(t: string) {
    Row() {
      Row()
        .width(3)
        .height(14)
        .borderRadius(2)
        .backgroundColor($r('app.color.brand_primary'))
      Text(t)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .margin({ left: 8 })
    }
    .width('100%')
    .padding({ top: 14, bottom: 8 })
    .backgroundColor($r('app.color.bg_page'))
  }

  @Builder
  EventRow(e: BattleEvent) {
    Row({ space: 10 }) {
      Column() {
        Text(e.time)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
      }
      .width(44)
      .alignItems(HorizontalAlign.End)

      Column() {
        Row()
          .width(8)
          .height(8)
          .borderRadius(4)
          .backgroundColor(e.isKey ? $r('app.color.brand_primary') : $r('app.color.text_tertiary'))
        if (!e.isKey) {
          Row()
            .width(2)
            .height(28)
            .backgroundColor($r('app.color.divider'))
        }
      }
      .width(10)
      .alignItems(HorizontalAlign.Center)

      Text(e.title)
        .fontSize(14)
        .lineHeight(20)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)

      if (e.gif.length > 0) {
        ImageKnifeComponent({
          imageKnifeOption: {
            loadSrc: e.gif,
            objectFit: ImageFit.Cover,
            border: { radius: 4 }
          }
        })
          .width(72)
          .height(48)
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .padding({ top: 10, bottom: 10 })
    .backgroundColor($r('app.color.bg_card'))
  }

  @Builder
  StatRow(s: BattleStat) {
    Row() {
      Text(s.homeVal)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .width(64)
        .textAlign(TextAlign.Start)
      Text(s.name)
        .fontSize(12)
        .fontColor($r('app.color.text_tertiary'))
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      Text(s.awayVal)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .width(64)
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .padding({ top: 9, bottom: 9 })
    .backgroundColor($r('app.color.bg_card'))
  }

  build() {
    NavDestination() {
      Column() {
        AppNavBar({ title: this.pageTitle + '战报' })
        if (this.state === LoadState.Ready) {
        List({ space: 0 }) {
          ListItem() {
            this.ScoreHeader()
          }

          if (this.report.content.length > 0) {
            ListItem() {
              this.SectionTitle('战报')
            }
            ListItem() {
              Column({ space: 10 }) {
                Text(this.report.content)
                  .fontSize(15)
                  .lineHeight(24)
                  .fontColor($r('app.color.text_primary'))
                  .width('100%')
                if (this.report.img.length > 0) {
                  ImageKnifeComponent({
                    imageKnifeOption: {
                      loadSrc: this.report.img,
                      objectFit: ImageFit.Contain,
                      border: { radius: Radius.sm }
                    }
                  })
                    .width('100%')
                    .height(200)
                }
              }
              .width('100%')
              .padding({ left: Spacing.lg, right: Spacing.lg, top: 12, bottom: 14 })
              .backgroundColor($r('app.color.bg_card'))
            }
          }

          if (this.report.events.length > 0) {
            ListItem() {
              this.SectionTitle('关键事件')
            }
            ForEach(this.report.events, (e: BattleEvent, idx: number) => {
              ListItem() {
                Column() {
                  this.EventRow(e)
                  Divider().color($r('app.color.divider')).margin({ left: 64 })
                }
                .padding({ left: Spacing.lg, right: Spacing.lg })
              }
            }, (e: BattleEvent, idx: number) => `ev_${idx}_${e.time}_${e.title.length}`)
          }

          if (this.report.stats.length > 0) {
            ListItem() {
              this.SectionTitle(`${this.homeName}  vs  ${this.awayName}`)
            }
            ForEach(this.report.stats, (s: BattleStat, idx: number) => {
              ListItem() {
                Column() {
                  this.StatRow(s)
                  Divider().color($r('app.color.divider')).margin({ left: Spacing.lg, right: Spacing.lg })
                }
                .padding({ left: Spacing.lg, right: Spacing.lg })
              }
            }, (s: BattleStat, idx: number) => `st_${idx}_${s.name}`)
          }

          if (this.report.lineup.length > 0) {
            ListItem() {
              this.SectionTitle('首发阵容')
            }
            ListItem() {
              Text(this.report.lineup)
                .fontSize(13)
                .lineHeight(21)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
                .padding({ left: Spacing.lg, right: Spacing.lg, top: 12, bottom: 14 })
                .backgroundColor($r('app.color.bg_card'))
            }
          }

          ListItem() {
            Text('战报数据来自虎扑')
              .fontSize(11)
              .fontColor($r('app.color.text_tertiary'))
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding({ top: 16, bottom: 24 })
          }
        }
        .cachedCount(4)
        .width('100%')
        .layoutWeight(1)
        .backgroundColor($r('app.color.bg_page'))
        .scrollBar(BarState.Off)
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
          message: '本场暂无战报数据',
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
