import { ImageKnife } from '@ohos/imageknife';
import { bundleManager, common } from '@kit.AbilityKit';
import { pasteboard } from '@kit.BasicServicesKit';
import { Spacing, Radius, RouteName } from '../common/Theme';
import { FavStore } from '../database/FavStore';
import { ChannelStore } from '../database/ChannelStore';
import { CacheStore } from '../database/CacheStore';
import { ChannelCatalog } from '../common/Channels';
import { SessionManager, HupuUserInfo } from '../network/SessionManager';
import { AppNavBar } from '../views/AppNavBar';

/** 设置/关于页 */
@Component
export struct SettingsPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @StorageLink('loginState') @Watch('onLoginChanged') loginState: number = 0;
  @State version: string = '0.5.0';
  @State clearing: boolean = false;
  @State showCookieEditor: boolean = false;
  @State cookieInput: string = '';
  @State verifying: boolean = false;
  @State loginUser: HupuUserInfo = new HupuUserInfo();

  aboutToAppear(): void {
    try {
      const info = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      if (info.versionName && info.versionName.length > 0) {
        this.version = info.versionName;
      }
    } catch (e) {
    }
    this.initSession();
  }

  private async initSession(): Promise<void> {
    await SessionManager.ensureLoaded(this.getCtx());
    this.refreshUser();
  }

  onLoginChanged(): void {
    this.refreshUser();
  }

  private async refreshUser(): Promise<void> {
    if (this.loginState !== 1) {
      this.loginUser = new HupuUserInfo();
      return;
    }
    const u: HupuUserInfo | null = await SessionManager.verify();
    if (u !== null) {
      this.loginUser = u;
    } else {
      await SessionManager.logout(this.getCtx());
      this.toast('登录已失效，请重新注入 Cookie');
    }
  }

  private getCtx(): common.Context {
    return this.getUIContext().getHostContext() as common.Context;
  }

  private toast(msg: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message: msg });
    } catch (e) {
    }
  }

  /** 清除图片缓存（内存 + 磁盘） */
  private async clearImageCache(): Promise<void> {
    if (this.clearing) {
      return;
    }
    this.clearing = true;
    try {
      ImageKnife.getInstance().removeAllMemoryCache();
      await ImageKnife.getInstance().removeAllFileCache();
      this.toast('图片缓存已清除');
    } catch (e) {
      this.toast('清除失败，请重试');
    }
    this.clearing = false;
  }

  /** 清除数据缓存（缓存优先渲染的频道与详情快照） */
  private async clearDataCache(): Promise<void> {
    if (this.clearing) {
      return;
    }
    this.clearing = true;
    try {
      await CacheStore.clear(this.getCtx());
      this.toast('数据缓存已清除');
    } catch (e) {
      this.toast('清除失败，请重试');
    }
    this.clearing = false;
  }

  private confirmClearFavs(): void {
    this.getUIContext().showAlertDialog({
      title: '清除全部收藏',
      message: '将删除所有本地收藏的帖子，删除后无法恢复。',
      autoCancel: true,
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '清除',
        fontColor: $r('app.color.brand_primary'),
        action: () => {
          this.doClearFavs();
        }
      }
    });
  }

  private async doClearFavs(): Promise<void> {
    try {
      await FavStore.clear(this.getCtx());
      AppStorage.setOrCreate<number>('favVersion', Date.now());
      this.toast('收藏已清空');
    } catch (e) {
      this.toast('操作失败');
    }
  }

  /** 频道设置恢复默认 */
  private async resetChannels(): Promise<void> {
    try {
      const ids: string[] = ChannelCatalog.defaults();
      AppStorage.setOrCreate<string>('channelIdsJson', JSON.stringify(ids));
      AppStorage.setOrCreate<string>('activeChannelId', ids[0]);
      await ChannelStore.save(this.getCtx(), ids);
      this.toast('频道已恢复默认');
    } catch (e) {
      this.toast('操作失败');
    }
  }

  /** 导出收藏到剪贴板（JSON） */
  private async exportFavs(): Promise<void> {
    try {
      const json: string = await FavStore.exportJson(this.getCtx());
      const data: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, json);
      await pasteboard.getSystemPasteboard().setData(data);
      this.toast('收藏已导出到剪贴板');
    } catch (e) {
      this.toast('导出失败，请重试');
    }
  }

  /** 从剪贴板导入收藏（幂等合并） */
  private async importFavs(): Promise<void> {
    try {
      const data: pasteboard.PasteData = await pasteboard.getSystemPasteboard().getData();
      const text: string = data.getPrimaryText() ?? '';
      if (text.trim().length === 0) {
        this.toast('剪贴板为空');
        return;
      }
      const count: number = await FavStore.importJson(this.getCtx(), text.trim());
      if (count < 0) {
        this.toast('剪贴板内容不是有效的收藏备份');
        return;
      }
      AppStorage.setOrCreate<number>('favVersion', Date.now());
      this.toast(`已导入 ${count} 条收藏`);
    } catch (e) {
      this.toast('导入失败，请重试');
    }
  }

  /** 注入 Cookie：保存并实测验证 */
  private async doInjectCookie(): Promise<void> {
    if (this.verifying) {
      return;
    }
    const input: string = this.cookieInput.trim();
    if (input.length < 20 || input.indexOf('ua=') < 0) {
      this.toast('请粘贴完整的浏览器 Cookie（需包含 ua= 键）');
      return;
    }
    this.verifying = true;
    try {
      const u: HupuUserInfo | null = await SessionManager.saveAndVerify(this.getCtx(), input);
      if (u !== null) {
        this.loginUser = u;
        this.showCookieEditor = false;
        this.cookieInput = '';
        this.toast(`欢迎，${u.username}`);
      } else {
        this.toast('验证失败：Cookie 无效或已过期');
      }
    } catch (e) {
      this.toast('验证失败，请检查网络');
    }
    this.verifying = false;
  }

  private confirmLogout(): void {
    this.getUIContext().showAlertDialog({
      title: '退出登录',
      message: '将清除本机保存的登录 Cookie，恢复只读模式。',
      autoCancel: true,
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '退出',
        fontColor: $r('app.color.brand_primary'),
        action: () => {
          this.doLogout();
        }
      }
    });
  }

  private async doLogout(): Promise<void> {
    await SessionManager.logout(this.getCtx());
    this.loginUser = new HupuUserInfo();
    this.toast('已退出登录');
  }

  @Builder
  SectionTitle(t: string) {
    Text(t)
      .fontSize(12)
      .fontColor($r('app.color.text_tertiary'))
      .width('100%')
      .padding({ left: 4, top: 14, bottom: 6 })
  }

  @Builder
  RowItem(title: string, arrow: boolean, isAction: boolean, onTap: () => void) {
    Row() {
      Text(title)
        .fontSize(15)
        .fontColor(isAction ? $r('app.color.brand_primary') : $r('app.color.text_primary'))
      Blank()
      if (arrow) {
        Text('›')
          .fontSize(18)
          .fontColor($r('app.color.text_tertiary'))
      }
    }
    .width('100%')
    .height(50)
    .onClick(() => {
      onTap();
    })
  }

  @Builder
  AccountSection() {
    this.SectionTitle('账号')
    Column() {
      if (this.loginState === 1 && this.loginUser.username.length > 0) {
        Row({ space: 12 }) {
          if (this.loginUser.header.length > 0) {
            Image(this.loginUser.header)
              .width(42)
              .height(42)
              .borderRadius(21)
              .alt($r('app.media.app_icon'))
          }
          Column({ space: 3 }) {
            Text(this.loginUser.username)
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text('已登录 · uid ' + this.loginUser.uid)
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          Text('退出')
            .fontSize(13)
            .fontColor($r('app.color.brand_primary'))
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor($r('app.color.tag_bg'))
            .borderRadius(14)
            .onClick(() => {
              this.confirmLogout();
            })
        }
        .width('100%')
        .height(66)
      } else {
        this.RowItem('虎扑账号登录（推荐）', true, false, () => {
          this.pageStack.pushPathByName(RouteName.LOGIN_WEB, '');
        })
        Divider().color($r('app.color.divider'))
        Row() {
          Text('或手动粘贴 Cookie（备用）')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
          Blank()
          Text('›')
            .fontSize(16)
            .fontColor($r('app.color.text_tertiary'))
        }
        .width('100%')
        .height(44)
        .onClick(() => {
          this.showCookieEditor = !this.showCookieEditor;
        })
      }
    }
    .width('100%')
    .padding({ left: 14, right: 14 })
    .backgroundColor($r('app.color.bg_card'))
    .borderRadius(Radius.md)

    if (this.showCookieEditor) {
      Column({ space: 10 }) {
        Text('粘贴浏览器整串 Cookie（F12 → Network → 请求标头 → Cookie）。仅存本机，用于解锁点亮/回复/云收藏。')
          .fontSize(11)
          .lineHeight(16)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
        TextArea({ text: this.cookieInput, placeholder: 'smidV2=...; u=...; us=...; ua=...' })
          .fontSize(12)
          .height(110)
          .width('100%')
          .backgroundColor($r('app.color.tag_bg'))
          .borderRadius(Radius.sm)
          .onChange((v: string) => {
            this.cookieInput = v;
          })
        Row({ space: 10 }) {
          Text('取消')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .padding({ top: 9, bottom: 9 })
            .backgroundColor($r('app.color.tag_bg'))
            .borderRadius(Radius.sm)
            .onClick(() => {
              this.showCookieEditor = false;
              this.cookieInput = '';
            })
          Text(this.verifying ? '验证中…' : '保存并验证')
            .fontSize(13)
            .fontColor(Color.White)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .padding({ top: 9, bottom: 9 })
            .backgroundColor($r('app.color.brand_primary'))
            .borderRadius(Radius.sm)
            .onClick(() => {
              this.doInjectCookie();
            })
        }
        .width('100%')
      }
      .width('100%')
      .padding(12)
      .backgroundColor($r('app.color.bg_card'))
      .borderRadius(Radius.md)
      .margin({ top: 8 })
    }
  }

  build() {
    NavDestination() {
      Column() {
        AppNavBar({ title: '设置' })
        Scroll() {
        Column() {
          this.AccountSection()

          this.SectionTitle('关于')

          Column() {
            Row({ space: 12 }) {
              Image($r('app.media.app_icon'))
                .width(48)
                .height(48)
                .borderRadius(10)
              Column({ space: 3 }) {
                Text('Hupu Luna')
                  .fontSize(17)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.text_primary'))
                Text(`版本 ${this.version} · 非官方客户端`)
                  .fontSize(12)
                  .fontColor($r('app.color.text_secondary'))
              }
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .padding({ top: 12, bottom: 12 })

            Divider().color($r('app.color.divider'))

            Text('本应用为第三方学习项目，与虎扑官方无任何关联。所有内容数据均来自虎扑公开页面，版权归虎扑及相关权利人所有。仅供个人学习与交流使用，请勿用于商业用途。')
              .fontSize(12)
              .lineHeight(19)
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
              .padding({ top: 12, bottom: 12 })
          }
          .width('100%')
          .padding({ left: 14, right: 14 })
          .backgroundColor($r('app.color.bg_card'))
          .borderRadius(Radius.md)

          this.SectionTitle('存储')

          Column() {
            this.RowItem(this.clearing ? '正在清除…' : '清除图片缓存', false, false, () => {
              this.clearImageCache();
            })
            Divider().color($r('app.color.divider'))
            this.RowItem('清除数据缓存', false, false, () => {
              this.clearDataCache();
            })
            Divider().color($r('app.color.divider'))
            this.RowItem('清除全部收藏', true, true, () => {
              this.confirmClearFavs();
            })
            Divider().color($r('app.color.divider'))
            this.RowItem('恢复默认频道', true, false, () => {
              this.resetChannels();
            })
            Divider().color($r('app.color.divider'))
            this.RowItem('导出收藏（剪贴板）', false, false, () => {
              this.exportFavs();
            })
            Divider().color($r('app.color.divider'))
            this.RowItem('从剪贴板导入收藏', false, false, () => {
              this.importFavs();
            })
          }
          .width('100%')
          .padding({ left: 14, right: 14 })
          .backgroundColor($r('app.color.bg_card'))
          .borderRadius(Radius.md)

          Text('数据来源：m.hupu.com / bbs.hupu.com 公开页面')
            .fontSize(11)
            .fontColor($r('app.color.text_tertiary'))
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: 20, bottom: 20 })
        }
        .padding(Spacing.lg)
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.bg_page'))
      }
    }
    .hideTitleBar(true)
    .backgroundColor($r('app.color.bg_page'))
  }
}
