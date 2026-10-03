import web_webview from '@ohos.web.webview';
import { common } from '@kit.AbilityKit';
import { Spacing, Radius } from '../common/Theme';
import { SessionManager, HupuUserInfo } from '../network/SessionManager';
import { AppNavBar } from '../views/AppNavBar';

/**
 * 内嵌 WebView 虎扑登录（V2-M1 便捷方案）
 *
 * 流程：加载 passport.hupu.com 官方登录页 → 用户登录 → 跳回 bbs 域时
 * 自动用 WebCookieManager 抓取 Cookie（bbs + m 双域合并）→ 校验 ua= 键 →
 * SessionManager 保存并验证 → 成功 toast + 返回。
 * 密码只在官方页面输入，本应用不接触账号密码，Cookie 仅存本机。
 */
@Component
export struct CookieLoginPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State captured: boolean = false;
  @State triedOnce: boolean = false;
  private controller: web_webview.WebviewController = new web_webview.WebviewController();

  private getCtx(): common.Context {
    return this.getUIContext().getHostContext() as common.Context;
  }

  private async tryCapture(): Promise<void> {
    if (this.captured) {
      return;
    }
    let bbsCookie: string = '';
    let mCookie: string = '';
    try {
      bbsCookie = web_webview.WebCookieManager.fetchCookieSync('https://bbs.hupu.com');
    } catch (e) {
    }
    try {
      mCookie = web_webview.WebCookieManager.fetchCookieSync('https://m.hupu.com');
    } catch (e) {
    }
    const merged: string = SessionManager.mergeCookies(mCookie, bbsCookie);
    if (merged.indexOf('ua=') < 0) {
      return;
    }
    this.captured = true;
    const u: HupuUserInfo | null = await SessionManager.saveAndVerify(this.getCtx(), merged);
    if (u !== null) {
      try {
        this.getUIContext().getPromptAction().showToast({ message: `登录成功：${u.username}` });
      } catch (e) {
      }
      this.pageStack.pop();
    } else {
      // 抓到了 ua= 但验证失败（如网络问题）：允许继续在页面停留重试
      this.captured = false;
      this.triedOnce = true;
    }
  }

  build() {
    NavDestination() {
      Column() {
        AppNavBar({ title: this.triedOnce ? '虎扑登录（验证未过，可重试）' : '虎扑登录' })
        Text('在下方虎扑官方登录页登录后自动返回。密码不经过本应用，Cookie 仅存本机。')
          .fontSize(11)
          .lineHeight(16)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .padding({ left: Spacing.lg, right: Spacing.lg, top: 8, bottom: 8 })

        Web({ src: 'https://passport.hupu.com/v2/login?pcPhone=1&jumpurl=https%3A%2F%2Fbbs.hupu.com&from=https%3A%2F%2Fwww.hupu.com', controller: this.controller })
          .onPageEnd((e: OnPageEndEvent) => {
            // 跳回业务域（登录成功）时尝试抓取；passport 域内抓不到也无副作用
            const url: string = e.url ?? '';
            if (url.indexOf('passport.hupu.com') < 0) {
              this.tryCapture();
            }
          })
          .domStorageAccess(true)
          .javaScriptAccess(true)
          .multiWindowAccess(false)
          .width('100%')
          .layoutWeight(1)
          .backgroundColor(Color.White)
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.bg_page'))
    }
    .hideTitleBar(true)
    .backgroundColor($r('app.color.bg_page'))
  }
}
