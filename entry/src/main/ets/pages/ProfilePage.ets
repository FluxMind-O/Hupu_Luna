import { FavStore, FavRecord } from '../database/FavStore';
import { common } from '@kit.AbilityKit';
import { LoadState, StateView } from '../views/StateView';
import { Spacing, FontSize, RouteName } from '../common/Theme';
import { SessionManager, HupuUserInfo } from '../network/SessionManager';
import { MyApi, MyProfile } from '../network/MyApi';

@Component
export struct ProfilePage {
  @Consume('pageStack') pageStack: NavPathStack;
  @StorageLink('favVersion') @Watch('onFavChanged') favVersion: number = 0;
  @StorageLink('loginState') @Watch('onLoginChanged') loginState: number = 0;
  @State favs: FavRecord[] = [];
  @State state: LoadState = LoadState.Loading;
  @State loginUser: HupuUserInfo = new HupuUserInfo();
  @State myProfile: MyProfile = new MyProfile();
  @State profileLoading: boolean = false;
  @StorageLink('topAvoidPx') topAvoidPx: number = 0;

  aboutToAppear(): void {
    this.load();
    this.initSession();
  }

  onFavChanged(): void {
    this.load();
  }

  onLoginChanged(): void {
    this.initSession();
  }

  private getCtx(): common.Context {
    return this.getUIContext().getHostContext() as common.Context;
  }

  private async initSession(): Promise<void> {
    await SessionManager.ensureLoaded(this.getCtx());
    if (this.loginState === 1) {
      this.refreshUser();
    } else {
      this.loginUser = new HupuUserInfo();
      this.myProfile = new MyProfile();
    }
  }

  private async refreshUser(): Promise<void> {
    const u: HupuUserInfo | null = await SessionManager.verify();
    if (u !== null) {
      this.loginUser = u;
      // 拉 m 站 SSR 档案（等级/卡路里/注册天数）
      this.profileLoading = true;
      try {
        this.myProfile = await MyApi.getMyProfile();
      } catch (e) {
      }
      this.profileLoading = false;
    } else {
      await SessionManager.logout(this.getCtx());
      this.loginUser = new HupuUserInfo();
    }
  }

  private async load(): Promise<void> {
    try {
      const rows: FavRecord[] = await FavStore.list(this.getCtx());
      this.favs = rows;
      this.state = rows.length > 0 ? LoadState.Ready : LoadState.Empty;
    } catch (e) {
      this.state = LoadState.Error;
    }
  }

  private async removeOne(tid: string): Promise<void> {
    try {
      await FavStore.remove(this.getCtx(), tid);
      AppStorage.setOrCreate<number>('favVersion', Date.now());
    } catch (e) {
    }
  }

  private async clearAll(): Promise<void> {
    try {
      await FavStore.clear(this.getCtx());
      AppStorage.setOrCreate<number>('favVersion', Date.now());
    } catch (e) {
    }
  }

  /** 加入天数（优先 m 站注册时间，回退 uid 无 → 显示等级） */
  private joinedText(): string {
    if (this.myProfile.joinedDays > 0) {
      return `加入虎扑 ${this.myProfile.joinedDays} 天`;
    }
    if (this.myProfile.level.length > 0) {
      return this.myProfile.level;
    }
    return '已登录';
  }

  @Builder
  AccountCard() {
    Column() {
      if (this.loginState === 1 && (this.loginUser.username.length > 0 || this.myProfile.username.length > 0)) {
        Row({ space: 14 }) {
          if (this.myProfile.avatar.length > 0) {
            Image(this.myProfile.avatar)
              .width(56)
              .height(56)
              .borderRadius(28)
              .alt($r('app.media.app_icon'))
          } else if (this.loginUser.header.length > 0) {
            Image(this.loginUser.header)
              .width(56)
              .height(56)
              .borderRadius(28)
              .alt($r('app.media.app_icon'))
          }
          Column({ space: 4 }) {
            Text(this.myProfile.username.length > 0 ? this.myProfile.username : this.loginUser.username)
              .fontSize(FontSize.title)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.joinedText())
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          Text('›')
            .fontSize(20)
            .fontColor($r('app.color.text_tertiary'))
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.pageStack.pushPathByName(RouteName.USER_SPACE, '');
        })
      } else {
        Row({ space: 12 }) {
          Column({ space: 4 }) {
            Text('未登录 · 只读模式')
              .fontSize(FontSize.title)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
            Text('登录后可点亮、回复、云收藏')
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          Text('去登录')
            .fontSize(13)
            .fontColor(Color.White)
            .padding({ left: 14, right: 14, top: 7, bottom: 7 })
            .backgroundColor($r('app.color.brand_primary'))
            .borderRadius(16)
            .onClick(() => {
              this.pageStack.pushPathByName(RouteName.SETTINGS, '');
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
    }
    .width('100%')
    .padding({ left: Spacing.lg, right: Spacing.lg, top: 4, bottom: 8 })
    .backgroundColor($r('app.color.bg_card'))
    .borderRadius(14)
  }

  @Builder
  StatLine() {
    Row() {
      this.StatCell(this.profileLoading ? '—' : (this.myProfile.threadCount >= 20 ? '20+' : `${this.myProfile.threadCount}`), '主题帖')
      this.StatCell(this.profileLoading ? '—' : (this.myProfile.replyCount >= 20 ? '20+' : `${this.myProfile.replyCount}`), '回帖')
      this.StatCell(this.profileLoading ? '—' : (this.myProfile.calories.replace(/[^0-9]/g, '') || '—'), '卡路里')
      this.StatCell(this.profileLoading ? '—' : (this.myProfile.level.replace(/[^0-9]/g, '') || '—'), '等级')
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .backgroundColor($r('app.color.bg_card'))
    .borderRadius(14)
  }

  @Builder
  StatCell(num: string, label: string) {
    Column({ space: 4 }) {
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
  RowList() {
    Column() {
      this.ListRow('我的收藏', this.favs.length > 0 ? `${this.favs.length} 条` : '', '', () => {
      })
      Divider().color($r('app.color.divider')).margin({ left: 14 })
      this.ListRow('我的主题帖', '', '', () => {
        this.pageStack.pushPathByName(RouteName.USER_SPACE, '0');
      })
      Divider().color($r('app.color.divider')).margin({ left: 14 })
      this.ListRow('我的回帖', '', '', () => {
        this.pageStack.pushPathByName(RouteName.USER_SPACE, '1');
      })

    }
    .width('100%')
    .borderRadius(14)
    .clip(true)
    .backgroundColor($r('app.color.bg_card'))
  }

  @Builder
  ListRow(title: string, sub: string, icon: string, onTap: () => void) {
    Row({ space: 10 }) {
      Text(title)
        .fontSize(15)
        .fontColor($r('app.color.text_primary'))
      Blank()
      if (sub.length > 0) {
        Text(sub)
          .fontSize(12)
          .fontColor($r('app.color.text_tertiary'))
      }
      Text('›')
        .fontSize(18)
        .fontColor($r('app.color.text_tertiary'))
    }
    .width('100%')
    .height(52)
    .padding({ left: 14, right: 14 })
    .onClick(() => {
      onTap();
    })
  }

  @Builder
  FavRow(item: FavRecord) {
    Row() {
      Column({ space: 4 }) {
        Text(item.title)
          .fontSize(15)
          .fontColor($r('app.color.text_primary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Row({ space: 8 }) {
          if (item.forum.length > 0) {
            Text(item.forum)
              .fontSize(11)
              .fontColor($r('app.color.brand_primary'))
              .maxLines(1)
          }
          Text(item.author)
            .fontSize(11)
            .fontColor($r('app.color.text_tertiary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          Text('删除')
            .fontSize(11)
            .fontColor($r('app.color.text_secondary'))
            .padding({ left: 10, right: 10, top: 3, bottom: 3 })
            .backgroundColor($r('app.color.tag_bg'))
            .borderRadius(10)
            .onClick(() => {
              this.removeOne(item.tid);
            })
        }
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: Spacing.lg, right: Spacing.lg, top: 12, bottom: 12 })
    .backgroundColor($r('app.color.bg_card'))
    .onClick(() => {
      this.pageStack.pushPathByName(RouteName.POST_DETAIL, item.tid);
    })
  }

  build() {
    Column() {
      Column() {
      Row() {
        Text('我的')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Blank()
        Text('设置')
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor($r('app.color.tag_bg'))
          .borderRadius(14)
          .onClick(() => {
            this.pageStack.pushPathByName(RouteName.SETTINGS, '');
          })
      }
      .width('100%')
      .padding({ left: Spacing.lg, right: Spacing.lg, top: 2, bottom: 0 })
      }
      .width('100%')
      .padding({ top: px2vp(this.topAvoidPx) })
      .backgroundColor($r('app.color.bg_page'))

      Scroll() {
        Column({ space: 8 }) {
          this.AccountCard()
          if (this.loginState === 1) {
            this.StatLine()
          }
          this.RowList()

          if (this.favs.length > 0) {
            Row() {
              Text(`我的收藏（${this.favs.length}）`)
                .fontSize(13)
                .fontColor($r('app.color.text_secondary'))
              Blank()
              Text('清空')
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                .backgroundColor($r('app.color.tag_bg'))
                .borderRadius(12)
                .onClick(() => {
                  this.clearAll();
                })
            }
            .width('100%')
            .padding({ left: Spacing.lg, right: Spacing.lg, top: 4 })

            Column() {
              ForEach(this.favs, (item: FavRecord) => {
                Column() {
                  this.FavRow(item)
                  Divider().color($r('app.color.divider'))
                }
              }, (item: FavRecord) => item.tid)
            }
            .borderRadius(14)
            .clip(true)
          }

          Text('Hupu Luna · 非官方客户端 · 数据来自虎扑公开页面')
            .fontSize(11)
            .fontColor($r('app.color.text_tertiary'))
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: 10, bottom: 20 })
        }
        .padding({ left: Spacing.lg, right: Spacing.lg, top: 26, bottom: 10 })
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off)
      // 内容不足一屏时 Scroll 默认居中，显式顶对齐避免"我的"卡片悬在屏幕中部
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
