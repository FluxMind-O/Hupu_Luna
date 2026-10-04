import { HomePage } from './HomePage';
import { CommunityPage } from './CommunityPage';
import { ProfilePage } from './ProfilePage';
import { PostDetailPage } from './PostDetailPage';
import { TopicThreadsPage } from './TopicThreadsPage';
import { TopicTagPage } from './TopicTagPage';
import { AllChannelsPage } from './AllChannelsPage';
import { SearchPage } from './SearchPage';
import { ImageViewerPage } from './ImageViewerPage';
import { SettingsPage } from './SettingsPage';
import { MatchScorePage } from './MatchScorePage';
import { MatchListPage } from './MatchListPage';
import { MatchReportPage } from './MatchReportPage';
import { PlayerScoreDetailPage } from './PlayerScoreDetailPage';
import { PlayerProfilePage } from './PlayerProfilePage';
import { CookieLoginPage } from './CookieLoginPage';
import { UserSpacePage } from './UserSpacePage';
import { CreateThreadPage } from './CreateThreadPage';
import { RouteName } from '../common/Theme';
import { HdsTabs, HdsTabsController, hdsMaterial } from '@kit.UIDesignKit';
import { SymbolGlyphModifier } from '@kit.ArkUI';

@Entry
@Component
struct Index {
  @Provide('pageStack') pageStack: NavPathStack = new NavPathStack();
  @State currentIndex: number = 0;
  private tabsController: HdsTabsController = new HdsTabsController();

  /** 发帖页参数（可能未传，返回空串避免 undefined） */
  private createThreadParam(): string {
    const arr: string[] = this.pageStack.getParamByName(RouteName.CREATE_THREAD) as string[];
    return arr.length > 0 ? arr[0] : '';
  }

  private tabSymbol(normal: Resource, selected: Resource): TabBarSymbol {
    return {
      normal: new SymbolGlyphModifier(normal).fontColor(['#9499A0']).fontSize(24),
      selected: new SymbolGlyphModifier(selected).fontColor([$r('app.color.brand_primary')]).fontSize(24)
    };
  }

  @Builder
  PageMap(name: string) {
    if (name === RouteName.POST_DETAIL) {
      PostDetailPage({ tid: this.pageStack.getParamByName(RouteName.POST_DETAIL)[0] as string })
    } else if (name === RouteName.TOPIC_THREADS) {
      TopicThreadsPage({ param: this.pageStack.getParamByName(RouteName.TOPIC_THREADS)[0] as string })
    } else if (name === RouteName.TAG_THREADS) {
      TopicTagPage({ param: this.pageStack.getParamByName(RouteName.TAG_THREADS)[0] as string })
    } else if (name === RouteName.SEARCH) {
      SearchPage()
    } else if (name === RouteName.ALL_CHANNELS) {
      AllChannelsPage()
    } else if (name === RouteName.IMAGE_VIEWER) {
      ImageViewerPage({ param: this.pageStack.getParamByName(RouteName.IMAGE_VIEWER)[0] as string })
    } else if (name === RouteName.SETTINGS) {
      SettingsPage()
    } else if (name === RouteName.MATCH_SCORE) {
      MatchScorePage({ param: this.pageStack.getParamByName(RouteName.MATCH_SCORE)[0] as string })
    } else if (name === RouteName.MATCH_LIST) {
      MatchListPage({ param: this.pageStack.getParamByName(RouteName.MATCH_LIST)[0] as string })
    } else if (name === RouteName.MATCH_REPORT) {
      MatchReportPage({ param: this.pageStack.getParamByName(RouteName.MATCH_REPORT)[0] as string })
    } else if (name === RouteName.PLAYER_SCORE) {
      PlayerScoreDetailPage({ param: this.pageStack.getParamByName(RouteName.PLAYER_SCORE)[0] as string })
    } else if (name === RouteName.PLAYER_PROFILE) {
      PlayerProfilePage({ param: this.pageStack.getParamByName(RouteName.PLAYER_PROFILE)[0] as string })
    } else if (name === RouteName.LOGIN_WEB) {
      CookieLoginPage()
    } else if (name === RouteName.USER_SPACE) {
      UserSpacePage({ param: this.pageStack.getParamByName(RouteName.USER_SPACE)[0] as string })
    } else if (name === RouteName.CREATE_THREAD) {
      CreateThreadPage({ param: this.createThreadParam() })
    } else {
      Column({ space: 8 }) {
        Text(name)
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
        Text('页面开发中')
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor($r('app.color.bg_page'))
    }
  }

  build() {
    Navigation(this.pageStack) {
      HdsTabs({
        barPosition: BarPosition.End,
        index: this.currentIndex,
        controller: this.tabsController
      }) {
        TabContent() {
          HomePage()
        }
        .tabBar(new BottomTabBarStyle(
          this.tabSymbol($r('sys.symbol.house'), $r('sys.symbol.house_fill')), '首页'))

        TabContent() {
          CommunityPage()
        }
        .tabBar(new BottomTabBarStyle(
          this.tabSymbol($r('sys.symbol.person_2'), $r('sys.symbol.person_2_fill')), '社区'))

        TabContent() {
          ProfilePage()
        }
        .tabBar(new BottomTabBarStyle(
          this.tabSymbol($r('sys.symbol.person'), $r('sys.symbol.person_fill')), '我的'))
      }
      .vertical(false)
      .barMode(BarMode.Fixed)
      .scrollable(false)
      // 悬浮页签：TabBar 层叠于内容之上，内容可延伸至栏下方
      .barOverlap(true)
      // 悬浮样式 + 沉浸光感材质（胶囊造型：左右留边、悬浮于导航条上方）
      .barFloatingStyle({
        barSideMargin: 14,
        barBottomMargin: 28,
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.IMMERSIVE,
          materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
        }
      })
      .onChange((index: number) => {
        this.currentIndex = index;
      })
    }
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .navDestination(this.PageMap)
  }
}
