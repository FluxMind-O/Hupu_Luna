# Hupu Luna - 虎扑第三方客户端

> 纯净轻快的 HarmonyOS NEXT 虎扑客户端，无广告、无运营位、纯粹阅读体验。

## 项目简介

Hupu Luna 是一款基于 HarmonyOS NEXT (ArkTS/ArkUI) 开发的第三方虎扑客户端。项目采用直连虎扑逆向接口的方式获取数据，无需自建后端，实现了纯净、轻量、无广告的阅读体验。

### 主要特性

- **纯净阅读**：无启动广告、无弹窗运营位、无营销模块
- **核心功能**：首页热帖流、社区分区、帖子详情、评论浏览、搜索
- **篮球模块**：NBA/CBA 赛程比分、球员评分、投篮热图、球员主页
- **足球模块**：足球赛程、战报详情、关键事件时间线
- **频道管理**：自定义频道排序、滑动切换、持久化存储
- **本地收藏**：基于 RelationalStore 的本地收藏功能
- **深色模式**：完整深色/浅色主题支持，自动跟随系统
- **流畅体验**：骨架屏加载、图片磁盘缓存、手势交互优化

## 技术栈

- **框架**：HarmonyOS NEXT (Stage 模型)
- **语言**：ArkTS / ArkUI
- **状态管理**：ArkUI V2 (@ObservedV2 / @Trace)
- **网络**：@ohos.net.http 自封装
- **图片缓存**：ImageKnife
- **本地存储**：RelationalStore + Preferences
- **构建工具**：hvigor

## 项目文件目录结构

```
hupu/
├── AppScope/                          # 应用级配置
│   ├── app.json5                      # 应用配置（版本、包名等）
│   └── resources/                     # 应用级资源
│       └── base/
│           ├── element/
│           │   └── string.json        # 应用名称等字符串
│           └── media/
│               └── app_icon.png       # 应用图标
├── entry/                             # 主模块
│   ├── src/main/
│   │   ├── ets/                       # ArkTS 源代码
│   │   │   ├── common/                # 公共模块
│   │   │   │   ├── Channels.ets       # 频道配置与定义
│   │   │   │   ├── Theme.ets          # 设计 Token（间距/字号/圆角/路由）
│   │   │   │   └── Utils.ets          # 工具函数
│   │   │   ├── database/              # 数据存储
│   │   │   │   ├── ChannelStore.ets   # 频道持久化（Preferences）
│   │   │   │   └── FavStore.ets       # 收藏存储（RelationalStore）
│   │   │   ├── entryability/          # 应用入口
│   │   │   │   └── EntryAbility.ets   # Stage 模型入口
│   │   │   ├── model/                 # 数据模型
│   │   │   │   └── Models.ets         # 接口数据模型定义
│   │   │   ├── network/               # 网络层
│   │   │   │   ├── HttpManager.ets    # HTTP 请求封装（超时/重试/UA）
│   │   │   │   ├── HupuApi.ets        # 虎扑接口清单
│   │   │   │   ├── NbaApi.ets         # NBA 相关接口
│   │   │   │   └── SoccerApi.ets      # 足球相关接口
│   │   │   ├── pages/                 # 页面组件
│   │   │   │   ├── Index.ets          # 主页面（Tab 导航 + 路由）
│   │   │   │   ├── HomePage.ets       # 首页（频道热帖流）
│   │   │   │   ├── CommunityPage.ets  # 社区（分区列表）
│   │   │   │   ├── ProfilePage.ets    # 我的（收藏/设置入口）
│   │   │   │   ├── PostDetailPage.ets # 帖子详情 + 评论
│   │   │   │   ├── SearchPage.ets     # 搜索页
│   │   │   │   ├── AllChannelsPage.ets# 全部频道管理
│   │   │   │   ├── ImageViewerPage.ets# 图片查看器（缩放/翻页）
│   │   │   │   ├── SettingsPage.ets   # 设置页（关于/缓存清理）
│   │   │   │   ├── MatchListPage.ets  # 全部比赛列表（时间线）
│   │   │   │   ├── MatchScorePage.ets # 比赛评分页（球员评分）
│   │   │   │   ├── MatchReportPage.ets# 战报页（足球/篮球）
│   │   │   │   ├── PlayerScoreDetailPage.ets # 球员评分详情
│   │   │   │   ├── PlayerProfilePage.ets # 球员主页（数据/投篮热图）
│   │   │   │   ├── TopicThreadsPage.ets # 板块帖子流
│   │   │   │   └── TopicTagPage.ets   # 话题标签页
│   │   │   └── views/                 # 可复用组件
│   │   │       ├── Skeleton.ets       # 骨架屏组件
│   │   │       ├── StateView.ets      # 三态组件（加载/空/错误）
│   │   │       └── TagChip.ets        # 标签组件
│   │   └── resources/                 # 资源文件
│   │       ├── base/
│   │       │   ├── element/
│   │       │   │   ├── color.json     # 颜色定义（浅色模式）
│   │       │   │   └── string.json    # 字符串资源
│   │       │   ├── media/
│   │       │   │   └── app_icon.png   # 模块图标
│   │       │   └── profile/
│   │       │       └── main_pages.json# 路由配置
│   │       ├── dark/
│   │       │   └── element/
│   │       │       └── color.json     # 深色模式颜色
│   │       ├── en_US/                 # 英文资源（备用）
│   │       │   └── element/
│   │       │       └── string.json
│   │       └── zh_CN/                 # 中文资源
│   │           └── element/
│   │               └── string.json
│   ├── build-profile.json5            # 构建配置
│   ├── hvigorfile.ts                  # 构建脚本
│   ├── oh-package.json5               # 模块依赖
│   └── obfuscation-rules.txt          # 混淆规则
├── hvigor/                            # hvigor 构建工具配置
│   └── hvigor-config.json5
├── .hvigor/                           # 构建缓存（可删除）
│   ├── cache/
│   ├── outputs/
│   └── report/
├── .codeartsdoer/                     # 开发工具配置
├── build-profile.json5                # 工程构建配置
├── hvigorfile.ts                      # 工程构建脚本
├── oh-package.json5                   # 工程依赖
├── PLAN.md                            # 项目施工计划（详细技术文档）
├── .gitignore                         # Git 忽略配置
└── vacrib.code-workspace              # VS Code 工作区配置
```

## 核心模块说明

### 网络层 (network/)
- **HttpManager**: 统一的 HTTP 请求封装，支持超时、重试、UA/Referer 注入
- **HupuApi**: 虎扑主站接口（热帖、帖子详情、评论、搜索）
- **NbaApi**: NBA 相关接口（赛程、评分、球员数据）
- **SoccerApi**: 足球相关接口（赛程、战报）

### 数据存储 (database/)
- **ChannelStore**: 使用 Preferences 持久化用户自定义频道顺序
- **FavStore**: 使用 RelationalStore 实现本地收藏功能

### 页面组件 (pages/)
采用 Navigation + Tabs 架构，主要页面包括：
- 首页：频道化热帖流，支持左右滑动切换频道
- 社区：虎扑分区列表，可浏览各板块帖子
- 帖子详情：帖子内容 + 分页评论 + 楼中楼
- 篮球/足球：赛程比分、球员评分、战报
- 搜索：帖子/资讯关键词搜索
- 我的：收藏管理、设置

### 设计系统 (common/)
- **Theme**: 统一的设计 Token（间距、字号、圆角）
- **Channels**: 频道配置定义
- **Utils**: 通用工具函数

## 构建与运行

### 环境要求
- DevEco Studio (最新稳定版)
- HarmonyOS NEXT SDK (API 12+)
- 真机或模拟器

### 构建步骤
1. 使用 DevEco Studio 打开项目
2. 等待依赖下载完成
3. 选择目标设备（真机需开启开发者模式）
4. 点击 Run 构建并运行

### 侧载安装
项目支持通过 hap 包侧载安装到真机：
```bash
# 构建未签名 hap
hvigor assembleHap

# 使用 hap_installer 安装（需开发者证书）
```

## 数据来源

应用直连虎扑逆向接口，主要数据链路：
- **L1**: `m.hupu.com` Next.js SSR 内嵌 JSON（首选）
- **L2**: H5/Web JSON 接口
- **L3**: 移动 App API（备用，需签名）

## 版本信息

- **当前版本**: v0.12.0
- **最低系统**: HarmonyOS NEXT 6.0
- **包名**: `com.hupluna.app`

## 免责声明

本项目为非官方第三方客户端，仅供个人学习使用，不上架应用市场、不商业分发。虎扑相关商标归虎扑所有。

## 开发计划

详细开发计划与技术文档请参考 [PLAN.md](./PLAN.md)。