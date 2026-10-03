import { MyApi, MyProfile, MyThreadItem } from '../network/MyApi';
import { LoadState } from '../views/StateView';
import { Spacing, FontSize, Radius, RouteName } from '../common/Theme';
import { compactCount } from '../views/TagChip';
import { common } from '@kit.AbilityKit';
import { AppNavBar } from '../views/AppNavBar';

/**
 * 个人主页（m 站"我的"域 SSR 解析）
 * 头部：大头像 + 昵称 + 等级/卡路里/注册天数/数字ID
 * 页签：主题帖 / 回帖（点击进帖子详情）
 */
@Component
export struct UserSpacePage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State profile: MyProfile = new MyProfile();
  @State threads: MyThreadItem[] = [];
  @State tab: number = 0;
  @State headState: LoadState = LoadState.Loading;
  @State listState: LoadState = LoadState.Loading;
  param: string = '';

  aboutToAppear(): void {
    if (this.param === '1') {
      this.tab = 1;
    }
    this.loadHead();
    this.loadList();
  }

  private getCtx(): common.Context {
    return this.getUIContext().getHostContext() as common.Context;
  }

  private async loadHead(): Promise<void> {
    this.headState = LoadState.Loading;
    try {
      this.profile = await MyApi.getMyProfile();
      this.headState = this.profile.username.length > 0 ? LoadState.Ready : LoadState.Empty;
    } catch (e) {
      this.headState = LoadState.Error;
    }
  }

  private async loadList(): Promise<void> {
    this.listState = LoadState.Loading;
    try {
      const path: string = this.tab === 0 ? '/my/userthreads' : '/my/userreplies';
      this.threads = await MyApi.getMyThreads(path);
      this.listState = this.threads.length > 0 ? LoadState.Ready : LoadState.Empty;
    } catch (e) {
      this.listState = LoadState.Error;
    }
  }

  switchTab(t: number): void {
    if (this.tab === t) {
      return;
    }
    this.tab = t;
    this.loadList();
  }

  @Builder
  StatCell(num: string, label: string) {
    Column({ space: 3 }) {
      Text(num)
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
      Text(label)
        .fontSize(11)
        .fontColor($r('app.color.text_secondary'))
    }
    .layoutWeight(1)
  }

  @Builder
  ThreadRow(item: MyThreadItem) {
    Column() {
      Column({ space: 6 }) {
        Text(item.title)
          .fontSize(15)
          .fontColor($r('app.color.text_primary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Row({ space: 14 }) {
          if (item.lights > 0) {
            Text(`${compactCount(item.lights)} 亮`)
              .fontSize(11)
              .fontColor($r('app.color.text_tertiary'))
          }
          if (item.replies > 0) {
            Text(`${compactCount(item.replies)} 回复`)
              .fontSize(11)
              .fontColor($r('app.color.text_tertiary'))
          }
          Blank()
        }
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
    .padding({ left: Spacing.lg, right: Spacing.lg, top: 13, bottom: 13 })
    .backgroundColor($r('app.color.bg_card'))
    .onClick(() => {
      this.pageStack.pushPathByName(RouteName.POST_DETAIL, item.tid);
    })
  }

  build() {
    NavDestination() {
      Column() {
        AppNavBar({ title: '个人主页' })
        Scroll() {
          Column() {
            // 头部卡
            if (this.headState === LoadState.Ready) {
              Column() {
                Row({ space: 14 }) {
                  if (this.profile.avatar.length > 0) {
                    Image(this.profile.avatar)
                      .width(64)
                      .height(64)
                      .borderRadius(32)
                      .alt($r('app.media.app_icon'))
                  }
                  Column({ space: 5 }) {
                    Text(this.profile.username)
                      .fontSize(FontSize.title)
                      .fontWeight(FontWeight.Bold)
                      .fontColor($r('app.color.text_primary'))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Row({ space: 8 }) {
                      if (this.profile.level.length > 0) {
                        Text(this.profile.level.replace('论坛等级', '').trim())
                          .fontSize(11)
                          .fontColor($r('app.color.text_secondary'))
                          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                          .backgroundColor($r('app.color.tag_bg'))
                          .borderRadius(10)
                      }
                      if (this.profile.joinedDays > 0) {
                        Text(`加入虎扑${this.profile.joinedDays}天`)
                          .fontSize(11)
                          .fontColor($r('app.color.text_secondary'))
                          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                          .backgroundColor($r('app.color.tag_bg'))
                          .borderRadius(10)
                      }
                    }
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                }
                .width('100%')
                .alignItems(VerticalAlign.Center)

                Row() {
                  this.StatCell(this.profile.level.replace(/[^0-9]/g, '') || '0', '论坛等级')
                  this.StatCell(this.profile.calories.replace(/[^0-9]/g, '') || '0', '卡路里')
                  this.StatCell(`${this.threads.length}`, this.tab === 0 ? '主题帖(本页)' : '回帖(本页)')
                }
                .width('100%')
                .padding({ top: 16 })
              }
              .width('100%')
              .padding(Spacing.lg)
              .backgroundColor($r('app.color.bg_card'))
              .margin({ bottom: Spacing.sm })
            } else if (this.headState === LoadState.Loading) {
              Column() {
                LoadingProgress().width(28).height(28).color($r('app.color.text_tertiary'))
              }
              .width('100%')
              .padding(30)
              .backgroundColor($r('app.color.bg_card'))
              .margin({ bottom: Spacing.sm })
            }

            // 页签
            Row() {
              Text('主题帖')
                .fontSize(14)
                .fontWeight(this.tab === 0 ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.tab === 0 ? $r('app.color.text_primary') : $r('app.color.text_secondary'))
                .layoutWeight(1)
                .textAlign(TextAlign.Center)
                .onClick(() => {
                  this.switchTab(0);
                })
              Text('回帖')
                .fontSize(14)
                .fontWeight(this.tab === 1 ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.tab === 1 ? $r('app.color.text_primary') : $r('app.color.text_secondary'))
                .layoutWeight(1)
                .textAlign(TextAlign.Center)
                .onClick(() => {
                  this.switchTab(1);
                })
            }
            .width('100%')
            .height(42)
            .backgroundColor($r('app.color.bg_card'))

            // 列表
            if (this.listState === LoadState.Ready) {
              ForEach(this.threads, (item: MyThreadItem) => {
                Column() {
                  this.ThreadRow(item)
                  Divider().color($r('app.color.divider'))
                }
              }, (item: MyThreadItem) => item.tid)
            } else if (this.listState === LoadState.Loading) {
              Column() {
                LoadingProgress().width(24).height(24).color($r('app.color.text_tertiary'))
              }
              .width('100%')
              .padding(30)
            } else {
              Text(this.listState === LoadState.Empty ? '暂无内容' : '加载失败，下拉重试')
                .fontSize(13)
                .fontColor($r('app.color.text_tertiary'))
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding(30)
                .onClick(() => {
                  this.loadList();
                })
            }
          }
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .backgroundColor($r('app.color.bg_page'))
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .backgroundColor($r('app.color.bg_page'))
  }
}
