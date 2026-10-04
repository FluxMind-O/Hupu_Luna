import { MyApi, MyProfile, MyThreadItem } from '../network/MyApi';
import { HupuApi } from '../network/HupuApi';
import { UserProfile, UserPostItem, UserSpaceData } from '../model/Models';
import { LoadState } from '../views/StateView';
import { Spacing, FontSize, Radius, RouteName } from '../common/Theme';
import { compactCount } from '../views/TagChip';
import { thumbUrl } from '../common/Utils';
import { common } from '@kit.AbilityKit';
import { AppNavBar } from '../views/AppNavBar';

/**
 * 个人主页，两种模式：
 * - 本人（param 为 '' / '0' / '1'）：m 站"我的"域 SSR，页签切换主题帖/回帖
 * - 他人（param 为 puid 数字）：m 站公开页 m.hupu.com/user/{puid}，
 *   一个页面同时返回档案 + 主题帖 + 回帖，切换页签无需重新请求
 */
@Component
export struct UserSpacePage {
  @Consume('pageStack') pageStack: NavPathStack;
  // 本人模式
  @State profile: MyProfile = new MyProfile();
  @State threads: MyThreadItem[] = [];
  // 他人模式
  @State otherProfile: UserProfile = new UserProfile();
  @State otherThreads: UserPostItem[] = [];
  @State otherReplies: UserPostItem[] = [];
  @State otherItems: UserPostItem[] = [];
  @State tab: number = 0;
  @State headState: LoadState = LoadState.Loading;
  @State listState: LoadState = LoadState.Loading;
  /** 目标 puid：空 = 本人；非空 = 他人主页 */
  private targetPuid: string = '';
  param: string = '';

  aboutToAppear(): void {
    const p: string = this.param.trim();
    // param 约定：'' / '0' / '1' = 本人（后两者指定初始页签）；长数字 = 他人 puid
    if (p.length >= 5 && this.isNumeric(p)) {
      this.targetPuid = p;
    } else if (p === '1') {
      this.tab = 1;
    }
    if (this.isOther()) {
      this.loadOther();
    } else {
      this.loadHead();
      this.loadList();
    }
  }

  private getCtx(): common.Context {
    return this.getUIContext().getHostContext() as common.Context;
  }

  private isOther(): boolean {
    return this.targetPuid.length > 0;
  }

  private isNumeric(s: string): boolean {
    for (let i = 0; i < s.length; i++) {
      const c: number = s.charCodeAt(i);
      if (c < 48 || c > 57) {
        return false;
      }
    }
    return s.length > 0;
  }

  private navTitle(): string {
    if (this.isOther()) {
      return this.otherProfile.nickname.length > 0 ? this.otherProfile.nickname : '个人主页';
    }
    return '个人主页';
  }

  /** 他人主页：一次请求拿档案 + 主题帖 + 回帖 */
  private async loadOther(): Promise<void> {
    this.headState = LoadState.Loading;
    this.listState = LoadState.Loading;
    try {
      const data: UserSpaceData = await HupuApi.getUserSpace(this.targetPuid);
      this.otherProfile = data.profile;
      this.otherThreads = data.threads;
      this.otherReplies = data.replies;
      this.headState = data.profile.nickname.length > 0 ? LoadState.Ready : LoadState.Empty;
      this.applyOtherList();
    } catch (e) {
      this.headState = LoadState.Error;
      this.listState = LoadState.Error;
    }
  }

  /** 他人页签切换：数据已在手，直接取用（不重复请求） */
  private applyOtherList(): void {
    const list: UserPostItem[] = this.tab === 0 ? this.otherThreads : this.otherReplies;
    this.otherItems = list;
    this.listState = list.length > 0 ? LoadState.Ready : LoadState.Empty;
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
    if (this.isOther()) {
      this.applyOtherList();
    } else {
      this.loadList();
    }
  }

  private retry(): void {
    if (this.isOther()) {
      this.loadOther();
    } else {
      this.loadHead();
      this.loadList();
    }
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

  /** 他人主页条目：主题帖（带标题）或回帖（带正文） */
  @Builder
  OtherRow(item: UserPostItem) {
    Column({ space: 6 }) {
      if (item.title.length > 0) {
        Text(item.title)
          .fontSize(15)
          .fontColor($r('app.color.text_primary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      if (item.content.length > 0) {
        Text(item.content)
          .fontSize(14)
          .lineHeight(21)
          .fontColor($r('app.color.text_primary'))
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      Row({ space: 12 }) {
        if (item.topicName.length > 0) {
          Text(item.topicName)
            .fontSize(11)
            .fontColor($r('app.color.brand_primary'))
            .maxLines(1)
        }
        if (item.visits > 0) {
          Text(`${compactCount(item.visits)} 浏览`)
            .fontSize(11)
            .fontColor($r('app.color.text_tertiary'))
        }
        if (item.replies > 0) {
          Text(`${compactCount(item.replies)} 回复`)
            .fontSize(11)
            .fontColor($r('app.color.text_tertiary'))
        }
        if (item.lights > 0) {
          Text(`${compactCount(item.lights)} 亮`)
            .fontSize(11)
            .fontColor($r('app.color.text_tertiary'))
        }
        Blank()
        if (item.time.length > 0) {
          Text(item.time)
            .fontSize(11)
            .fontColor($r('app.color.text_tertiary'))
        }
      }
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: Spacing.lg, right: Spacing.lg, top: 13, bottom: 13 })
    .backgroundColor($r('app.color.bg_card'))
    .onClick(() => {
      if (item.tid.length > 0) {
        this.pageStack.pushPathByName(RouteName.POST_DETAIL, item.tid);
      }
    })
  }

  /** 他人档案卡：头像 + 昵称 + 等级 + 声望/点亮/关注数据 */
  @Builder
  OtherHeadCard() {
    Column() {
      Row({ space: 14 }) {
        if (this.otherProfile.header.length > 0) {
          Image(thumbUrl(this.otherProfile.header, 160))
            .width(64)
            .height(64)
            .borderRadius(32)
            .alt($r('app.media.app_icon'))
        }
        Column({ space: 5 }) {
          Text(this.otherProfile.nickname)
            .fontSize(FontSize.title)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Row({ space: 8 }) {
            if (this.otherProfile.levelDesc.length > 0) {
              Text(this.otherProfile.levelDesc)
                .fontSize(11)
                .fontColor($r('app.color.text_secondary'))
                .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                .backgroundColor($r('app.color.tag_bg'))
                .borderRadius(10)
            }
            if (this.otherProfile.beRecommend > 0) {
              Text(`被推荐 ${compactCount(this.otherProfile.beRecommend)}`)
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
        this.StatCell(compactCount(this.otherProfile.reputation), '声望')
        this.StatCell(compactCount(this.otherProfile.beLight), '被点亮')
        this.StatCell(compactCount(this.otherProfile.beFollow), '粉丝')
        this.StatCell(compactCount(this.otherProfile.follow), '关注')
      }
      .width('100%')
      .padding({ top: 16 })
    }
    .width('100%')
    .padding(Spacing.lg)
    .backgroundColor($r('app.color.bg_card'))
    .margin({ bottom: Spacing.sm })
  }

  /**
   * 页签（主题帖 / 回帖）
   * @param t0 第一个页签文案
   */
  @Builder
  TabBar(t0: string, t1: string) {
    Row() {
      Text(t0)
        .fontSize(14)
        .fontWeight(this.tab === 0 ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.tab === 0 ? $r('app.color.text_primary') : $r('app.color.text_secondary'))
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.switchTab(0);
        })
      Text(t1)
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
  }

  @Builder
  ListArea() {
    if (this.listState === LoadState.Ready) {
      if (this.isOther()) {
        ForEach(this.otherItems, (item: UserPostItem) => {
          Column() {
            this.OtherRow(item)
            Divider().color($r('app.color.divider'))
          }
        }, (item: UserPostItem, idx: number) => `o_${item.tid}_${idx}`)
      } else {
        ForEach(this.threads, (item: MyThreadItem) => {
          Column() {
            this.ThreadRow(item)
            Divider().color($r('app.color.divider'))
          }
        }, (item: MyThreadItem) => item.tid)
      }
    } else if (this.listState === LoadState.Loading) {
      Column() {
        LoadingProgress().width(24).height(24).color($r('app.color.text_tertiary'))
      }
      .width('100%')
      .padding(30)
    } else {
      Text(this.listState === LoadState.Empty ? '暂无内容' : '加载失败，点击重试')
        .fontSize(13)
        .fontColor($r('app.color.text_tertiary'))
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding(30)
        .onClick(() => {
          this.retry();
        })
    }
  }

  build() {
    NavDestination() {
      Column() {
        AppNavBar({ title: this.navTitle() })
        Scroll() {
          Column() {
            // 头部卡
            if (this.isOther()) {
              if (this.headState === LoadState.Ready) {
                this.OtherHeadCard()
              } else if (this.headState === LoadState.Loading) {
                Column() {
                  LoadingProgress().width(28).height(28).color($r('app.color.text_tertiary'))
                }
                .width('100%')
                .padding(30)
                .backgroundColor($r('app.color.bg_card'))
                .margin({ bottom: Spacing.sm })
              } else {
                Text(this.headState === LoadState.Empty ? '用户不存在' : '加载失败，点击重试')
                  .fontSize(13)
                  .fontColor($r('app.color.text_tertiary'))
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .padding(30)
                  .backgroundColor($r('app.color.bg_card'))
                  .margin({ bottom: Spacing.sm })
                  .onClick(() => {
                    this.retry();
                  })
              }
            } else if (this.headState === LoadState.Ready) {
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
            if (this.isOther()) {
              this.TabBar(`主题帖(${this.otherThreads.length})`, `回帖(${this.otherReplies.length})`)
            } else {
              this.TabBar('主题帖', '回帖')
            }

            // 列表
            this.ListArea()
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
