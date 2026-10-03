import { NbaApi } from '../network/NbaApi';
import { SoccerApi } from '../network/SoccerApi';
import { MatchDay, MatchItem } from '../model/Models';
import { LoadState, StateView } from '../views/StateView';
import { Spacing } from '../common/Theme';
import { RouteName } from '../common/Theme';
import { ImageKnifeComponent } from '@ohos/imageknife';
import { AppNavBar } from '../views/AppNavBar';

/** 近期全部热门比赛列表页（按比赛日分组） */
@Component
export struct MatchListPage {
  /** 格式："league||title"，league: nba / cba / soccer */
  param: string = '';
  @Consume('pageStack') pageStack: NavPathStack;
  @State days: MatchDay[] = [];
  @State state: LoadState = LoadState.Loading;
  @State pageTitle: string = '近期比赛';
  private league: string = '';
  private listScroller: Scroller = new Scroller();

  aboutToAppear(): void {
    const parts: string[] = this.param.split('||');
    if (parts.length >= 1) {
      this.league = parts[0];
    }
    if (parts.length >= 2 && parts[1].length > 0) {
      this.pageTitle = parts[1];
    }
    this.load();
  }

  private async load(): Promise<void> {
    this.state = LoadState.Loading;
    try {
      let raw: MatchDay[] = [];
      if (this.league === 'soccer') {
        raw = await SoccerApi.getAllDays();
      } else if (this.league === 'cba') {
        raw = await NbaApi.getCbaSchedule();
      } else {
        raw = await NbaApi.getSchedule();
      }
      this.days = this.sortAscending(raw);
      this.state = this.days.length > 0 ? LoadState.Ready : LoadState.Empty;
      // 渲染完成后定位到"今天"：上方为更早的历史比赛，下方为未来赛程
      setTimeout(() => {
        this.jumpToToday();
      }, 150);
    } catch (e) {
      this.state = LoadState.Error;
    }
  }

  /** 按日期升序（时间线：上早下晚） */
  private sortAscending(raw: MatchDay[]): MatchDay[] {
    const result: MatchDay[] = raw.slice();
    result.sort((a: MatchDay, b: MatchDay): number => {
      if (a.day < b.day) {
        return -1;
      }
      if (a.day > b.day) {
        return 1;
      }
      return 0;
    });
    return result;
  }

  /** 定位到今天（今天无比赛则取最近的过去比赛日；全为未来则回到顶部） */
  private jumpToToday(): void {
    if (this.days.length === 0) {
      return;
    }
    const today: string = SoccerApi.todayStr();
    let target: number = -1;
    for (let i = 0; i < this.days.length; i++) {
      if (this.days[i].day <= today) {
        target = i;
      } else {
        break;
      }
    }
    if (target < 0) {
      target = 0;
    }
    try {
      this.listScroller.scrollToIndex(target, false);
    } catch (e) {
    }
  }

  private isDone(m: MatchItem): boolean {
    return m.status === 'COMPLETED' || m.statusCn.indexOf('结束') >= 0;
  }

  private timeText(m: MatchItem): string {
    if (m.matchTime.length >= 16) {
      return m.matchTime.substring(11, 16);
    }
    return m.matchTime;
  }

  private openMatch(m: MatchItem): void {
    if (!this.isDone(m)) {
      return;
    }
    const p: string = `${m.matchId}||${m.homeTeamId}||${m.awayTeamId}||${m.homeName}||${m.awayName}||${m.homeScore}||${m.awayScore}||${m.homeLogo}||${m.awayLogo}||${m.stage}||${this.pageTitle}`;
    if (this.league === 'soccer') {
      this.pageStack.pushPathByName(RouteName.MATCH_REPORT, p);
      return;
    }
    this.pageStack.pushPathByName(RouteName.MATCH_SCORE, p);
  }

  @Builder
  DayHeader(label: string, day: string) {
    Row() {
      Text(label.length > 0 ? label : day)
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .padding({ left: Spacing.lg, right: Spacing.lg, top: 12, bottom: 6 })
    .backgroundColor($r('app.color.bg_page'))
  }

  @Builder
  TeamLine(logo: string, name: string, score: string, showScore: boolean) {
    Row({ space: 8 }) {
      ImageKnifeComponent({
        imageKnifeOption: {
          loadSrc: logo,
          objectFit: ImageFit.Contain
        }
      })
        .width(22)
        .height(22)
      Text(name)
        .fontSize(14)
        .fontColor($r('app.color.text_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
      if (showScore) {
        Text(score)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
      }
    }
    .width('100%')
  }

  @Builder
  MatchRow(m: MatchItem) {
    Row({ space: 10 }) {
      Column({ space: 4 }) {
        Text(this.timeText(m))
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
        Text(m.stage)
          .fontSize(10)
          .fontColor($r('app.color.text_tertiary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width(78)
      .alignItems(HorizontalAlign.Start)

      Column({ space: 6 }) {
        this.TeamLine(m.homeLogo, m.homeName, m.homeScore, this.isDone(m))
        this.TeamLine(m.awayLogo, m.awayName, m.awayScore, this.isDone(m))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Column({ space: 4 }) {
        Text(this.isDone(m) ? (m.statusCn.length > 0 ? m.statusCn : '已结束') : '未开始')
          .fontSize(12)
          .fontColor(this.isDone(m) ? $r('app.color.text_secondary') : $r('app.color.score_blue'))
          .maxLines(1)
        if (this.isDone(m) && m.scorePv.length > 0) {
          Text(m.scorePv)
            .fontSize(10)
            .fontColor($r('app.color.text_tertiary'))
            .maxLines(1)
        }
        if (this.isDone(m) && this.league !== 'soccer') {
          Text('球员评分 ›')
            .fontSize(10)
            .fontColor($r('app.color.score_blue'))
        }
      }
      .width(88)
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ left: Spacing.lg, right: Spacing.lg, top: 12, bottom: 12 })
    .backgroundColor($r('app.color.bg_card'))
    .onClick(() => {
      this.openMatch(m);
    })
  }

  build() {
    NavDestination() {
      Column() {
        AppNavBar({ title: this.pageTitle })
        if (this.state === LoadState.Ready) {
        Column() {
          Text('↑ 更早的比赛在上方 · ↓ 未来赛程在下方')
            .fontSize(11)
            .fontColor($r('app.color.text_tertiary'))
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: 8, bottom: 4 })
            .backgroundColor($r('app.color.bg_page'))

          List({ space: 0, scroller: this.listScroller }) {
          ForEach(this.days, (day: MatchDay) => {
            ListItemGroup({ header: this.DayHeader(day.dayLabel, day.day) }) {
              ForEach(day.matches, (m: MatchItem) => {
                ListItem() {
                  Column() {
                    this.MatchRow(m)
                    Divider().color($r('app.color.divider')).margin({ left: Spacing.lg, right: Spacing.lg })
                  }
                }
              }, (m: MatchItem, idx: number) => `${day.day}_${m.matchId}_${idx}`)
            }
          }, (day: MatchDay) => `day_${day.day}`)

          ListItem() {
            Text(this.league === 'soccer'
              ? '数据来自虎扑足球赛程 · 点击已结束比赛查看战报'
              : '数据来自虎扑篮球赛程 · 点击已结束比赛查看球员评分')
              .fontSize(11)
              .fontColor($r('app.color.text_tertiary'))
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding({ top: 16, bottom: 24 })
          }
          }
          .sticky(StickyStyle.Header)
          .cachedCount(4)
          .width('100%')
          .layoutWeight(1)
          .backgroundColor($r('app.color.bg_page'))
          .scrollBar(BarState.Off)
        }
        .width('100%')
        .layoutWeight(1)
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
          message: '暂无比赛数据',
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
