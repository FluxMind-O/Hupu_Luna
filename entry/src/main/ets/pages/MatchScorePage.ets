import { NbaApi } from '../network/NbaApi';
import { SoccerApi } from '../network/SoccerApi';
import { PlayerScoreRow, BattleReport, BattleEvent, BattleStat } from '../model/Models';
import { LoadState, StateView } from '../views/StateView';
import { Spacing, Radius, RouteName } from '../common/Theme';
import { compactCount } from '../views/TagChip';
import { ImageKnifeComponent } from '@ohos/imageknife';
import { AppNavBar } from '../views/AppNavBar';

const STAR_COUNT: number = 5;

/** 球员评分页（比赛两队球员的 JRs 评分，对齐官方版式） */
@Component
export struct MatchScorePage {
  /** 格式："matchId||homeTeamId||awayTeamId||homeName||awayName||homeScore||awayScore||homeLogo||awayLogo||stage||leagueTitle" */
  param: string = '';
  @Consume('pageStack') pageStack: NavPathStack;
  @State homeName: string = '';
  @State awayName: string = '';
  @State homeLogo: string = '';
  @State awayLogo: string = '';
  @State homeScore: string = '';
  @State awayScore: string = '';
  @State stage: string = '';
  @State leagueTitle: string = '球员评分';
  @State homePlayers: PlayerScoreRow[] = [];
  @State awayPlayers: PlayerScoreRow[] = [];
  @State state: LoadState = LoadState.Loading;
  @State tabSel: number = 0;
  @State teamSel: number = 0;
  @State report: BattleReport = new BattleReport();
  @State reportState: LoadState = LoadState.Loading;
  private reportLoaded: boolean = false;
  private matchId: string = '';
  private homeTeamId: string = '';
  private awayTeamId: string = '';

  aboutToAppear(): void {
    const parts: string[] = this.param.split('||');
    if (parts.length >= 3) {
      this.matchId = parts[0];
      this.homeTeamId = parts[1];
      this.awayTeamId = parts[2];
    }
    if (parts.length >= 7) {
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
        this.leagueTitle = parts[10];
      }
    }
    this.load();
  }

  private async load(): Promise<void> {
    this.state = LoadState.Loading;
    try {
      const hp: PlayerScoreRow[] = await NbaApi.getMatchScores(this.matchId, this.homeTeamId);
      const ap: PlayerScoreRow[] = await NbaApi.getMatchScores(this.matchId, this.awayTeamId);
      this.homePlayers = hp;
      this.awayPlayers = ap;
      this.state = hp.length > 0 || ap.length > 0 ? LoadState.Ready : LoadState.Empty;
      this.loadReport();
    } catch (e) {
      this.state = LoadState.Error;
    }
  }

  /** 战报（懒加载，与评分互不影响） */
  private async loadReport(): Promise<void> {
    if (this.reportLoaded) {
      return;
    }
    this.reportLoaded = true;
    this.reportState = LoadState.Loading;
    try {
      const r: BattleReport = await SoccerApi.getBattleReport(this.matchId);
      this.report = r;
      const empty: boolean = r.content.length === 0 && r.events.length === 0 && r.stats.length === 0;
      this.reportState = empty ? LoadState.Empty : LoadState.Ready;
    } catch (e) {
      this.reportState = LoadState.Error;
    }
  }

  private currentPlayers(): PlayerScoreRow[] {
    return this.teamSel === 0 ? this.homePlayers : this.awayPlayers;
  }

  private ratingSort(list: PlayerScoreRow[]): PlayerScoreRow[] {
    if (this.tabSel === 0) {
      return list.slice().sort((a: PlayerScoreRow, b: PlayerScoreRow): number => b.scoreAvg - a.scoreAvg);
    }
    return list.slice().sort((a: PlayerScoreRow, b: PlayerScoreRow): number => b.pts - a.pts);
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

  private statsLine(p: PlayerScoreRow): string {
    return `${p.pts}分${p.reb}板${p.ast}助${p.stl}断${p.blk}帽`;
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
          .width(52)
          .height(52)
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
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
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
          .width(52)
          .height(52)
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
  }

  @Builder
  TabBar() {
    Row({ space: 22 }) {
      Column({ space: 5 }) {
        Text('虎扑评分')
          .fontSize(15)
          .fontWeight(this.tabSel === 0 ? FontWeight.Medium : FontWeight.Normal)
          .fontColor(this.tabSel === 0 ? $r('app.color.text_primary') : $r('app.color.text_secondary'))
        Row()
          .width(56)
          .height(3)
          .borderRadius(2)
          .backgroundColor(this.tabSel === 0 ? $r('app.color.brand_primary') : Color.Transparent)
      }
      .onClick(() => {
        this.tabSel = 0;
      })

      Column({ space: 5 }) {
        Text('统计')
          .fontSize(15)
          .fontWeight(this.tabSel === 1 ? FontWeight.Medium : FontWeight.Normal)
          .fontColor(this.tabSel === 1 ? $r('app.color.text_primary') : $r('app.color.text_secondary'))
        Row()
          .width(40)
          .height(3)
          .borderRadius(2)
          .backgroundColor(this.tabSel === 1 ? $r('app.color.brand_primary') : Color.Transparent)
      }
      .onClick(() => {
        this.tabSel = 1;
      })

      Column({ space: 5 }) {
        Text('战报')
          .fontSize(15)
          .fontWeight(this.tabSel === 2 ? FontWeight.Medium : FontWeight.Normal)
          .fontColor(this.tabSel === 2 ? $r('app.color.text_primary') : $r('app.color.text_secondary'))
        Row()
          .width(40)
          .height(3)
          .borderRadius(2)
          .backgroundColor(this.tabSel === 2 ? $r('app.color.brand_primary') : Color.Transparent)
      }
      .onClick(() => {
        this.tabSel = 2;
        if (!this.reportLoaded) {
          this.loadReport();
        }
      })
      Blank()
    }
    .width('100%')
    .padding({ left: Spacing.lg, right: Spacing.lg, top: 10, bottom: 8 })
  }

  @Builder
  TeamSwitch() {
    Row() {
      Row({ space: 6 }) {
        ImageKnifeComponent({
          imageKnifeOption: {
            loadSrc: this.homeLogo,
            objectFit: ImageFit.Contain
          }
        })
          .width(18)
          .height(18)
        Text(this.homeName)
          .fontSize(13)
          .fontColor(this.teamSel === 0 ? Color.White : $r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .height(38)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.teamSel === 0 ? $r('app.color.brand_primary') : Color.Transparent)
      .borderRadius(Radius.sm)
      .onClick(() => {
        this.teamSel = 0;
      })

      Row({ space: 6 }) {
        ImageKnifeComponent({
          imageKnifeOption: {
            loadSrc: this.awayLogo,
            objectFit: ImageFit.Contain
          }
        })
          .width(18)
          .height(18)
        Text(this.awayName)
          .fontSize(13)
          .fontColor(this.teamSel === 1 ? Color.White : $r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .height(38)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.teamSel === 1 ? $r('app.color.brand_primary') : Color.Transparent)
      .borderRadius(Radius.sm)
      .onClick(() => {
        this.teamSel = 1;
      })
    }
    .width('100%')
    .padding(3)
    .backgroundColor($r('app.color.tag_bg'))
    .borderRadius(Radius.sm)
  }

  @Builder
  StarsRow(v: number) {
    Row({ space: 1 }) {
      ForEach([0, 1, 2, 3, 4], (i: number) => {
        Text('★')
          .fontSize(10)
          .fontColor(i < this.filledStars(v) ? $r('app.color.comment_amber') : $r('app.color.text_tertiary'))
      }, (i: number) => `star_${i}`)
    }
  }

  @Builder
  RatingCard(p: PlayerScoreRow) {
    Column({ space: 6 }) {
      Row({ space: 10 }) {
        ImageKnifeComponent({
          imageKnifeOption: {
            loadSrc: p.photo,
            objectFit: ImageFit.Cover,
            border: { radius: 6 }
          }
        })
          .width(54)
          .height(54)

        Column({ space: 5 }) {
          Text(p.name)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
          Text(this.statsLine(p))
            .fontSize(11)
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
            .width('100%')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Column({ space: 2 }) {
          this.StarsRow(p.scoreAvg)
          Text(p.scoreAvg > 0 ? p.scoreAvg.toFixed(1) : '—')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.scoreColor(p.scoreAvg))
          Text(p.scoreCount > 0 ? `${compactCount(p.scoreCount)} JRs评分` : '暂无评分')
            .fontSize(9)
            .fontColor($r('app.color.text_tertiary'))
            .maxLines(1)
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      if (p.comment.length > 0) {
        Text(`“${p.comment}”`)
          .fontSize(12)
          .lineHeight(17)
          .fontColor($r('app.color.comment_amber'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .padding({ left: 64 })
      }
    }
    .width('100%')
    .padding({ left: Spacing.lg, right: Spacing.lg, top: 12, bottom: 12 })
    .backgroundColor($r('app.color.bg_card'))
    .onClick(() => {
      this.pageStack.pushPathByName(RouteName.PLAYER_SCORE,
        `${this.matchId}||${p.playerId}||${p.name}||${p.teamId}`);
    })
  }

  @Builder
  StatsRow(p: PlayerScoreRow) {
    Row() {
      Text(p.name)
        .fontSize(14)
        .fontColor($r('app.color.text_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
      Text(`${p.pts}分`)
        .fontSize(13)
        .fontColor($r('app.color.text_primary'))
        .width(52)
        .textAlign(TextAlign.Center)
      Text(`${p.reb}板`)
        .fontSize(13)
        .fontColor($r('app.color.text_primary'))
        .width(52)
        .textAlign(TextAlign.Center)
      Text(`${p.ast}助`)
        .fontSize(13)
        .fontColor($r('app.color.text_primary'))
        .width(52)
        .textAlign(TextAlign.Center)
      Text(p.fgp.length > 0 ? p.fgp : '—')
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
        .width(58)
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .padding({ left: Spacing.lg, right: Spacing.lg, top: 11, bottom: 11 })
    .backgroundColor($r('app.color.bg_card'))
  }

  @Builder
  StatsHeaderRow() {
    Row() {
      Text('球员')
        .fontSize(11)
        .fontColor($r('app.color.text_tertiary'))
        .layoutWeight(1)
      Text('得分')
        .fontSize(11)
        .fontColor($r('app.color.text_tertiary'))
        .width(52)
        .textAlign(TextAlign.Center)
      Text('篮板')
        .fontSize(11)
        .fontColor($r('app.color.text_tertiary'))
        .width(52)
        .textAlign(TextAlign.Center)
      Text('助攻')
        .fontSize(11)
        .fontColor($r('app.color.text_tertiary'))
        .width(52)
        .textAlign(TextAlign.Center)
      Text('命中率')
        .fontSize(11)
        .fontColor($r('app.color.text_tertiary'))
        .width(58)
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .padding({ left: Spacing.lg, right: Spacing.lg, top: 12, bottom: 6 })
  }

  @Builder
  ReportStatRow(s: BattleStat) {
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
    .padding({ left: Spacing.lg, right: Spacing.lg, top: 9, bottom: 9 })
    .backgroundColor($r('app.color.bg_card'))
  }

  @Builder
  ReportEventRow(e: BattleEvent) {
    Row({ space: 10 }) {
      Text(e.time)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(e.isKey ? $r('app.color.brand_primary') : $r('app.color.text_tertiary'))
        .width(42)
        .textAlign(TextAlign.End)
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
          .width(64)
          .height(42)
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .padding({ left: Spacing.lg, right: Spacing.lg, top: 10, bottom: 10 })
    .backgroundColor($r('app.color.bg_card'))
  }

  build() {
    NavDestination() {
      Column() {
        AppNavBar({ title: this.leagueTitle })
        if (this.state === LoadState.Ready) {
        List({ space: 0 }) {
          ListItem() {
            Column() {
              this.ScoreHeader()
            }
            .width('100%')
            .padding(Spacing.lg)
            .backgroundColor($r('app.color.bg_card'))
          }

          ListItem() {
            this.TabBar()
          }

          if (this.tabSel !== 2) {
            ListItem() {
              Column() {
                this.TeamSwitch()
              }
              .padding({ left: Spacing.lg, right: Spacing.lg, top: 4, bottom: 10 })
            }
          }

          if (this.tabSel === 0) {
            ForEach(this.ratingSort(this.currentPlayers()), (p: PlayerScoreRow) => {
              ListItem() {
                Column() {
                  this.RatingCard(p)
                  Divider().color($r('app.color.divider')).margin({ left: Spacing.lg, right: Spacing.lg })
                }
              }
            }, (p: PlayerScoreRow) => `rt_${p.playerId}`)
          } else if (this.tabSel === 1) {
            ListItem() {
              this.StatsHeaderRow()
            }
            ForEach(this.ratingSort(this.currentPlayers()), (p: PlayerScoreRow) => {
              ListItem() {
                Column() {
                  this.StatsRow(p)
                  Divider().color($r('app.color.divider')).margin({ left: Spacing.lg, right: Spacing.lg })
                }
              }
            }, (p: PlayerScoreRow) => `st_${p.playerId}`)
          } else {
            if (this.reportState === LoadState.Ready) {
              if (this.report.content.length > 0) {
                ListItem() {
                  Text(this.report.content)
                    .fontSize(15)
                    .lineHeight(24)
                    .fontColor($r('app.color.text_primary'))
                    .width('100%')
                    .padding({ left: Spacing.lg, right: Spacing.lg, top: 12, bottom: 14 })
                    .backgroundColor($r('app.color.bg_card'))
                }
              }
              if (this.report.stats.length > 0) {
                ListItem() {
                  Row() {
                    Text(`${this.homeName}  vs  ${this.awayName}`)
                      .fontSize(13)
                      .fontWeight(FontWeight.Medium)
                      .fontColor($r('app.color.text_secondary'))
                  }
                  .width('100%')
                  .padding({ left: Spacing.lg, right: Spacing.lg, top: 14, bottom: 6 })
                  .backgroundColor($r('app.color.bg_page'))
                }
                ForEach(this.report.stats, (s: BattleStat, idx: number) => {
                  ListItem() {
                    Column() {
                      this.ReportStatRow(s)
                      Divider().color($r('app.color.divider')).margin({ left: Spacing.lg, right: Spacing.lg })
                    }
                  }
                }, (s: BattleStat, idx: number) => `rs_${idx}_${s.name}`)
              }
              if (this.report.events.length > 0) {
                ListItem() {
                  Row() {
                    Text('关键事件')
                      .fontSize(13)
                      .fontWeight(FontWeight.Medium)
                      .fontColor($r('app.color.text_secondary'))
                  }
                  .width('100%')
                  .padding({ left: Spacing.lg, right: Spacing.lg, top: 14, bottom: 6 })
                  .backgroundColor($r('app.color.bg_page'))
                }
                ForEach(this.report.events, (e: BattleEvent, idx: number) => {
                  ListItem() {
                    Column() {
                      this.ReportEventRow(e)
                      Divider().color($r('app.color.divider')).margin({ left: Spacing.lg, right: Spacing.lg })
                    }
                  }
                }, (e: BattleEvent, idx: number) => `re_${idx}_${e.title.length}`)
              }
            } else if (this.reportState === LoadState.Loading) {
              ListItem() {
                Column() {
                  LoadingProgress()
                    .width(28)
                    .height(28)
                    .color($r('app.color.text_tertiary'))
                }
                .width('100%')
                .padding({ top: 40, bottom: 40 })
                .alignItems(HorizontalAlign.Center)
              }
            } else {
              ListItem() {
                Text('本场暂无战报数据')
                  .fontSize(13)
                  .fontColor($r('app.color.text_tertiary'))
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .padding({ top: 40, bottom: 40 })
              }
            }
          }

          ListItem() {
            Text('评分与评论均来自虎扑用户')
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
          message: '本场暂无球员评分',
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
