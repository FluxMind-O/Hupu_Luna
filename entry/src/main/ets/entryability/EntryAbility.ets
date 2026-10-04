import { AbilityConstant, Configuration, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';
import { ImageKnife } from '@ohos/imageknife';

const DOMAIN: number = 0x0000;
const TAG: string = 'HupuLuna';
const STORE_NAME: string = 'hupluna_settings';
const KEY_CHANNELS: string = 'channel_ids';
const KEY_LAST_CHANNEL: string = 'last_channel_id';

export default class EntryAbility extends UIAbility {
  private mainWindow: window.Window | undefined = undefined;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 跟随系统深浅色（失败不阻断启动）
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'setColorMode failed');
    }
    // 全局上下文：页面组件统一从这里取（getHostContext 在部分组件层级可能为空）
    AppStorage.setOrCreate<Object>('appContext', this.context);
    hilog.info(DOMAIN, TAG, 'onCreate');
  }

  /**
   * 启动前同步恢复首页频道态（Preferences 读取为同步接口，可在首帧前完成）。
   * 关键：必须在 loadContent 之前写入 AppStorage，页面 build 时即拿到恢复值，
   * 避免页面内异步恢复与 @StorageLink 同步时序竞争，导致每次都从第一个栏目开始。
   */
  private restoreChannelState(): void {
    try {
      const pref: preferences.Preferences = preferences.getPreferencesSync(this.context, { name: STORE_NAME });
      const savedChannels: string = pref.getSync(KEY_CHANNELS, '') as string;
      if (savedChannels.length > 0) {
        AppStorage.setOrCreate<string>('channelIdsJson', savedChannels);
      }
      const saved: string = pref.getSync(KEY_LAST_CHANNEL, '') as string;
      hilog.info(DOMAIN, TAG, 'restore channel saved=%{public}s', saved);
      if (saved.length > 0) {
        AppStorage.setOrCreate<string>('activeChannelId', saved);
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'restoreChannelState FAIL: %{public}s', String(e));
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // 首帧前恢复频道态，保证首页渲染即为上次停留栏目
    this.restoreChannelState();

    // 初始化 ImageKnife 磁盘缓存（最多 256 个文件 / 256MB）
    try {
      ImageKnife.getInstance()
        .initFileCache(this.context, 256, 256 * 1024 * 1024)
        .then(() => {
          hilog.info(DOMAIN, TAG, 'ImageKnife file cache ready');
        });
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'ImageKnife init failed');
    }

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'loadContent failed: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, TAG, 'loadContent succeeded');
      try {
        const win = windowStage.getMainWindowSync();
        this.mainWindow = win;
        // 沉浸式 + 系统栏透明 + 窗口背景随主题（须先于避让高度读取，确保全屏布局下数值正确）
        this.applyWindowChrome();
        // 状态栏避让高度（Tab 页自绘头部需要避开）
        const sys = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
        const nav = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
        AppStorage.setOrCreate<number>('topAvoidPx', sys.topRect.height);
        AppStorage.setOrCreate<number>('bottomAvoidPx', nav.bottomRect.height);
      } catch (e) {
        hilog.warn(DOMAIN, TAG, 'avoid area read failed');
      }
    });
  }

  /** 深浅色等系统配置变化：重刷窗口背景与系统栏内容色 */
  onConfigurationUpdate(newConfig: Configuration): void {
    this.applyWindowChrome();
  }

  /**
   * 窗口沉浸式布局 + 系统栏透明 + 窗口背景随主题。
   * 修复深色模式下顶部状态栏区 / 底部导航条区显示纯黑（系统默认色）、
   * 与应用底色 #1D1F23 不一致的上下显示问题。
   */
  private applyWindowChrome(): void {
    if (this.mainWindow === undefined) {
      return;
    }
    const win: window.Window = this.mainWindow;
    try {
      win.setWindowLayoutFullScreen(true);
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'setWindowLayoutFullScreen failed');
    }
    const dark: boolean = this.context.config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    try {
      win.setWindowSystemBarProperties({
        statusBarColor: '#00000000',
        navigationBarColor: '#00000000',
        statusBarContentColor: dark ? '#FFFFFF' : '#18191C',
        navigationBarContentColor: dark ? '#FFFFFF' : '#18191C'
      });
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'setWindowSystemBarProperties failed');
    }
    try {
      const bg: number = this.context.resourceManager.getColorSync($r('app.color.bg_page').id) >>> 0;
      const rgb: string = ('00000' + (bg & 0xFFFFFF).toString(16)).slice(-6);
      win.setWindowBackgroundColor(`#${rgb}`);
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'setWindowBackgroundColor failed');
    }
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, 'onWindowStageDestroy');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'onDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, TAG, 'onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, TAG, 'onBackground');
  }
}
