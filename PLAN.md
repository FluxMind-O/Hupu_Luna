# 施工计划表 v2.1

> 目标：HarmonyOS NEXT 纯血（ArkTS / ArkUI）第三方虎扑客户端，纯净轻快、无广告、无运营位。
> 数据方案：App 直连虎扑逆向接口（无自建后端）。
> 性质：非官方客户端，不上架应用市场、不商业分发。

---

## 施工进度（2026-10-03 更新）

| 阶段 | 状态 | 备注 |
|---|---|---|
| M0 接口验证 | ✅ 完成 | 全部数据链路实测落定（下方"已探明口径"）；登录态相关接口未探（V1 只读不需要） |
| M1 工程骨架 | ✅ 完成 | 四 Tab + Navigation 路由 + 三态组件 + 深浅色 token |
| 基础版（M2+M3 核心） | ✅ 完成 | 首页热帖流（刷新/分页）、社区分区、板块帖子流、帖子详情+分页评论、搜索 |
| M4 · 本地收藏 | ✅ 完成 | RelationalStore 收藏表 + 帖子详情"收藏"按钮 + 我的页（收藏列表/删除/清空） |
| M4 · 篮球模块 | ✅ 完成 | NBA 资讯流 + 赛程比分（40 天窗口：未来在前、往期在后，含比分与赛果） |
| 图片磁盘缓存 | ✅ 完成 | ImageKnife 3.2.10 接入（@ohos/imageknife），列表图/队标/缩略图走磁盘缓存 |
| 首页频道化 | ✅ 完成 | 搜索框下方频道栏（热榜/推荐/NBA/国际足球/中国篮球 + ≡入口）；底部 Tab 精简为 首页/社区/我的；篮球页并入频道（NBA频道+赛程比分频道） |
| 全部频道管理 | ✅ 完成 | 我的频道（编辑增删）+ 推荐频道（28 个可选），Preferences 持久化，重启保持 |
| 手势交互 | ✅ 完成 | 首页内容区左右滑动切换频道（右滑上一个/左滑下一个）；底部 Tab 禁止滑动切换，仅点击 |
| 交互打磨 | ✅ 完成 | 跟手强反馈（阻尼 0.45、起步 5vp、满幅 ±48vp）；松手达标立即播旧内容滑出（140ms）+ 新内容延迟一帧滑入淡入（220ms）；触发阈值 28vp；未达标弹性回位；列表项手动点击判定（位移>10vp 不触发进入帖子） |
| 图片查看器 | ✅ 完成 | 全屏查看（Swiper 多图翻页 + 计数）、双指缩放（1-5x）、双击放大/还原、放大后单指拖动（Swiper disableSwipe 联动）、点击显隐工具栏、✕/系统返回关闭 |
| 楼中楼 | ✅ 完成 | 评论卡片"查看 N 条回复"展开/收起；`GET m.hupu.com/api/v2/bbs-reply-detail/{tid}-{pid}` → `data.replies[]`（移动 UA 实测可用）；内联展示回复（用户名/内容/图片/亮数/楼主标） |
| 设置/关于页 | ✅ 完成 | 关于（版本号读取 bundleInfo、非官方声明）、清除图片缓存（ImageKnife 内存+磁盘）、清除全部收藏（带确认弹窗）、恢复默认频道 |
| 骨架屏 | ✅ 完成 | FeedSkeleton（首页加载）/ DetailSkeleton（详情加载），呼吸闪烁动画替代转圈 |
| **球员评分** | ✅ 完成 | **V1 清单收官**。赛程中已完赛比赛可点入"球员评分"页：比分板 + 两队球员（头像/号码/首发标/数据）+ **JRs 平均分**（按分降序、颜色分级）+ 评分人数 + 球员热评 |
| 频道比赛条 | ✅ 完成 | NBA/中国篮球/国际足球/中国足球 四个频道顶部嵌入最相关比赛日比赛（比分或开赛时间、赛事名、足球显示 JRs评分人数）；篮球完赛可点入评分页 |
| 评分页官方化 | ✅ 完成 | 大 logo 比分头 + 「虎扑评分/统计」双页签 + 两队段选切换 + 评分卡（星级/蓝色大分/橙色热评引文）；统计页含 得分/篮板/助攻/命中率 表 |
| 比赛条限量 + 全部比赛入口 | ✅ 完成 | 频道比赛条**最多 4 场**；下方常驻「🔥 查看近期全部热门比赛 ›」按钮（**无比赛也显示**）；点击进入**全部比赛页**：按日分组（未到日期在前、过去在后），每场显示 时间/阶段/双球队行/比分/状态/**评分人数**（篮球用 `score` 字段如"49.8万评分"，足球用 `pv`），篮球完赛可点入评分页 |
| 足球战报页 | ✅ 完成 | 足球完赛比赛点击进入**战报页**：比分头部 + 战报正文（含配图）+ 关键事件时间线（时间/标题/动图缩略）+ 球队数据 9 项对比（射正/控球率/危险进攻…）+ 首发阵容文本 |
| 球员评分详情页 | ✅ 完成 | 评分页点球员卡进入：大头像+大分+星级 + **评分分布条形图**（2/4/6/8/10 分档，蓝/绿/橙分级）+ 本场数据面板（得分/篮板/助攻/抢断/盖帽/命中率/三分/罚球/±值） |
| 评分页战报页签 | ✅ 完成 | 评分页新增第三个页签「战报」：战报正文 + 数据对比 + 关键事件（含 GIF 缩略），懒加载 |
| 比赛列表时间线化 | ✅ 完成 | 全部比赛列表改为**时间线式**：按日期升序（上行历史 / 下行未来）；打开时**自动定位到今天**（今天无比赛则取最近比赛日）；日期头**吸顶**；顶部固定方向提示 |
| **球员主页** | ✅ 完成 | 新页面：资料头（头像/中英文名/昵称/球队/位置号码/年龄/身高/体重）+ **数据页签**（季前/常规/季后赛切换 + 基础/进阶数据切换 + 3列数据格 + **联盟第N排名**）+ **资料页签**（国籍/生日/大学/选秀/薪资/合同）|
| 评分详情增强 | ✅ 完成 | 新增「资料 ›」入口跳球员主页；新增「亮回复」区块（球员热评）+ 修复长竖条渲染 Bug（改用按侧边框替代 height('100%') 竖条） |
| **投篮热图** | ✅ 完成 | 球员主页新增「投篮」页签：**半场球场示意图**（边线/油漆区/罚球圈/篮筐/三分线）+ **14 个热区圆点**（按 API 配色：橙热/黄中/蓝冷，显示命中率）+ 点击查看区域详情 + 图例 + 14 区数据列表；**常规赛/季后赛**切换 |
| **球员荣誉** | ✅ 完成 | 资料页签新增「荣誉」卡片：8 项荣誉（月最佳新秀/全明星新秀赛 MVP/周最佳/周最佳球员等）含次数与获奖时间 |
| 构建产物 | ✅ `HupuLuna-0.12.0-unsigned.hap`（桌面，未签名，配合 hap_installer 侧载）2026-10-03 重构建同步 | |
| V2 规划 | ✅ 已起草 | 见第 11 节 |
| V2-M0 Spike | ✅ 完成（2026-10-03） | 写接口全部可直连（详见 11.0），卡点解除，仅差 Cookie |
| V2-M3 链路加固 | ✅ 完成（2026-10-03） | 熔断降级 + L0 详情兜底 + 缓存优先渲染，构建通过，HAP 已更新 |
| V2-M1 Cookie 登录态 | ✅ 完成（2026-10-03） | SessionManager + WriteApi + 设置页注入 UI + 我的页账号卡 + 云收藏双写；HAP 已更新（16:02） |
| V2-M2 点亮/回复 UI | ✅ 完成（2026-10-03） | 楼层点亮按钮（乐观更新/失败回滚提示）+ 底部回复输入条（楼层回复=楼中楼）+ ReplyItem.puid/ThreadDetail.fid 贯通；构建通过，HAP 已更新（16:2x） |
| WebView 便捷登录 | ✅ 完成（2026-10-03） | 内嵌 passport.hupu.com 官方登录页（CookieLoginPage），登录后 WebCookieManager 自动抓取 bbs+m 双域 Cookie 合并验证入库；设置页主入口改「虎扑账号登录」，手动粘贴降为备用；密码不经过本应用 |
| 真机验证 | ✅ 通过（2026-10-03） | WebView 登录拿 Cookie → 云收藏/楼层点亮/发回复全链路真机成功；ArkTS 栈未被风控拦截，V2 交互能力全部落地 |
| UI 官方化改版 | ✅ 完成（2026-10-03） | 我的页重构（账号卡+等级/卡路里/注册天数+功能宫格+收藏列表）、新页个人主页（UserSpacePage：档案+主题帖/回帖页签）、社区页大图标、首页推荐流 Bold 标题；构建通过 HAP 已更新 |
| APK 逆向分析 | ✅ 完成（2026-10-03） | 官方 APK 8.2.48 解包（93MB dex）：① 历史 salt 签名机制已废弃——games 网关无 sign/错 sign 一律放行（实测证实）② 用户空间走 Hermes/protobuf 原生协议，Web 不可达，止损放弃 ③ 提取官方深色配色 #24262B/#2C2F37（Lottie 真值）与底栏 Lottie 图标资产 ④ 深色主题已对齐官方色值 |
| 推荐流官方大卡 | ✅ 完成（2026-10-03） | 官方样式：作者行（头像20+昵称+时间）→ Bold17 标题（3 行）→ 图片区（3 图网格 aspect 1:1 / 双图 1.33 / 单图 180px 全宽）→ 底部"回复·亮"数据栏；ThreadListItem/FeedRow 贯通 picUrls（picList 前 3 张） |
| 社区页双栏重构 | ✅ 完成（2026-10-03） | 官方形态 1:1：左侧分类导航（选中红竖条+粗体）+ 右侧"我的"区块（Preferences 收藏 6 分区，长按卡片 toggle）+ 3 列分区网格（56px 圆角图标+名+🔥热度）；新增 MyTopicStore 口径（hupluna_settings/my_topic_ids） |

> **投篮热图/荣誉接口口径**：`GET games.mobileapi.hupu.com/1/7.5.29/basketballapi/shootHotMap?playerId=&competitionLeagueType=&competitionType=&competitionStageType=REGULAR/PLAYOFF` → `shootAreaDTOList[]`（14 区：areaId/fgs/fgm/fgp/level/color）；`GET .../playerAwardList?playerId=&competitionLeagueType=&competitionType=` → `awardSummaryList[]`（awardDesc/awardCount/awardDetailList）。热区语义映射为按经典 14 区布局推断（篮下/油漆区/底线/翼位/肘区/弧顶），数值完全来自接口。

**第六版已探明口径（球员主页 —— 重大突破）：**

| 数据 | 接口 | 说明 |
|---|---|---|
| 球员头部信息 | `GET games.mobileapi.hupu.com/1/7.5.29/basketballapi/playerPageHeadInfo?playerId={longId}&leagueType={NBA/CBA}` | 中/英文名、昵称、年龄、身高体重、国籍、大学、选秀、薪资、合同、球队logo、nbaGdcId（=短ID）|
| 球员赛季数据 | `GET .../basketballapi/playerSeasonStats?playerId=&competitionLeagueType={L}&competitionType={L}` | 67KB 完整数据：`dataDimensionMap.basic/advanced` × `competitionStagePackListMap.PRESEASON/REGULAR/PLAYOFF`；每项 `{name,cnName,quota,rank,leagueAvgValue,leagueMaxValue}`（rank=联盟排名）|
| 球员其他接口（备用） | `.../basketballapi/` | playerAllSeasonStats（全赛季）/ playerAllMatchStats（逐场）/ playerCareerStats（生涯）/ playerAwardList（荣誉）/ shootHotMap（投篮热图）/ playerInjuryList（伤病）/ news/v3/playerNewsById（资讯）|
| 发现方式 | `offline-download.hupu.com/online/prod/330003/playerInfo-data.html` 的 bundle | 该页面是 App 内嵌的球员资料 H5，其 JS 暴露了上述整个 API 家族 |

> **评论接口最终结论（2026-10-03 穷举验证完毕）**：官方评论流（亮回复/29）走 `POST playerStaff/latestCommentList`。穷举测试均失败：① 长/短/gid 三种 playerId（报 "playerModel null" → ID 体系不符）② 真实球员+真实比赛（如 SGA + 雷霆马刺 172万评分场）→ `success:true, result:null`（服务端返回空）③ DTO 泄露字段补偿（order=desc/asc/light、customId、cursorMap、userId 变体）全部空 ④ 12 个 API 版本号（3/7.3.0 ~ 3/8.0.0）全部空。**结论：评论数据服务端对非 App 签名请求一律返回空，Web 端不可达**。评分详情页展示每名球员的**单条热评**（rosterScoreStats.comment 字段，内容与官方亮评一致）作为替代。

> **球员评分详情口径（2026-10-03 突破）**：`GET m.hupu.com/basketball-player-score?id={playerId}&matchId={matchId}&role=player`（Next.js SSR，参数齐全即返回数据）→ `__NEXT_DATA__.props.pageProps.scoreInfo`：`playerInfo`（完整数据+userScoreAvg/userScoreCount）+ `scoreDistribution`（{"2":n,"4":n,"6":n,"8":n,"10":n} 分档）+ `hotComment`；`role=staff` 时 id 需用短格式 staffId。评论流接口 `playerStaff/latestCommentList` 老比赛数据可能为空，暂不接入。

> **足球评分接口结论（2026-10-03 深度逆向）**：足球 SPA（football-frontend-fed）的路由清单中确认**不存在足球评分页面**（路由仅：战报/预览/动画/榜单类）；`football-api.hupu.com` 与 `games.mobileapi.hupu.com` 上测试 15+ 条评分 API 路径全部失败。**足球 JRs 评分仅存在于 App 端专用接口**，Web 端不可达——故足球完赛比赛改接**战报页**（battleReport 接口对足球同样有效，见下）。
>
> **战报接口口径**：`GET games.mobileapi.hupu.com/1/7.5.36/basketballapi/news/battleReport?relationId={matchId}&relationType=BATTLE_REPORT` —— **足球与篮球通用**、无需签名；`result`：beginContent（正文）/ img / keyEvent[]（关键事件：title/gifImgs/eventTimeStr）/ normalEvent[] / matchTeamStats.itemList[]（name/homeVal/awayVal）/ teamLineup（阵容文本）；`playerScoreImg` 字段存在但常为 null。

> 补充口径：篮球赛程的评分人数字段为顶层的 `score`（"49.8万评分"）与 `scoreNumber`；`playerscorecount` 常为空不要用。足球全部比赛日 13 天（约 2 周窗口）。

**第五版已探明口径（足球与频道比赛）：**

| 数据 | 来源 | 说明 |
|---|---|---|
| CBA 赛程 | `GET m.hupu.com/cba/schedule` → `__NEXT_DATA__.props.pageProps.gameList` | 与 NBA 完全同构 |
| 足球赛程 | `GET m.hupu.com/soccer/schedule` → `data.games[].data[]` | 每日分组；home/away{teamId,name,logo}、home_score/away_score、status{id,txt}、begin_time、**pv（如 \"4679评分\"）**、title（赛事名） |
| 足球首页 | `GET m.hupu.com/soccer` | schedules[]（重点比赛）+ news[]（35条资讯） |
| 足球接口域（未完全逆向） | `football-api.hupu.com/1/{version}/...` | `/match/info?matchId=` 可用；评分接口路径未找到（10+ 候选全失败），留待后续 |
| 频道比赛条映射 | Channels.ets `matchLeague` 字段 | nba/cba/soccer，HomePage.loadStrip 统一装配 |

**第四版已探明口径（球员评分）：**

| 数据 | 来源 | 说明 |
|---|---|---|
| 比赛球员评分 | `GET games.mobileapi.hupu.com/1/7.5.29/basketballapi/teamMatchRosterScoreStats?matchId=&teamId=&userId=` | **无需签名**，直接可用；`result.players[]`：stats（name/number/photo/position/pts/reb/asts/fgp/starter/**userScoreAvg/userScoreCount**）+ comment（球员热评） |
| 球员评论列表（备用） | `POST games.mobileapi.hupu.com/3/7.5.60/basketballapi/playerStaff/latestCommentList` | body: matchId/playerId/staffId/limit/order/cursorMap |
| 赛事页面路由发现方式 | `basketball-m-web` 的 `_buildManifest.js` | 列出全部 Next.js 路由（评分页/球员榜/球队数据等），是后续功能的宝藏入口 |
| 其他可用接口 | `games.mobileapi.hupu.com/3/7.5.60/basketballapi/` | `against-plan-match`（对阵）、`news/battleReport`（战报）、`teamSeasonStats`（赛季统计）、`news/v2/teamNewsById`（球队新闻） |

> 注：球员评分数据从已完赛比赛进入（赛程频道中"已结束"的比赛行显示"球员评分 ›"入口）。

**第二版已探明口径（篮球模块）：**

| 数据 | 来源 | 说明 |
|---|---|---|
| NBA 资讯 | `GET m.hupu.com/nba` → `__NEXT_DATA__.props.pageProps.newsData` | 标题/大图/tid/亮数/回复/时间，可跳帖子详情 |
| NBA 赛程比分 | `GET m.hupu.com/nba/schedule` → `__NEXT_DATA__.props.pageProps.gameList` | 40 个比赛日分组；`day=yyyymmdd`、`dayBlock=5月14日 周四`、比分在 `homeScore/awayScore`（未开赛为 null） |

**图片现状**：列表类图片（首页封面、NBA 缩略图、社区版块图标、球队队标）走 ImageKnife（内存 LRU + 磁盘二级缓存，256 文件 / 256MB）；详情正文大图仍用原生 Image（一次性内容、无需磁盘缓存）。

**第三版已探明口径（频道体系）：**

| 数据 | 来源 | 说明 |
|---|---|---|
| 热榜榜单 | `GET m.hupu.com/hot` → `__NEXT_DATA__.props.pageProps.res[]` | rank/tagId/tagName/heat/competitionType/tagUpdateDesc，30 条，每 10 分钟更新 |
| 话题帖子流 | `GET m.hupu.com/api/v2/bbs/tagThreads?tagId=&tagType=&page=&pageSize=20&cursor=` | tagType=1 为主贴（优先），空则回退 tagType=2；`nextPage`+`cursor` 翻页 |
| 分区帖子流（频道主用） | `GET m.hupu.com/api/v2/bbs/topicThreads?topicId=&page=&cursor=` | 频道 catalog 复用其 topicId（如 184=足球话题区、173=CBA专区、502=篮球资讯、240=综合体育区、255=运动装备） |
| 频道持久化 | Preferences（`hupluna_settings/channel_ids`） | JSON 数组存 id 顺序；App/重启后保持 |

> **关键构建约束（2026-10-03 实测）**：hvigor 强制要求工程路径为纯 ASCII——项目实体位于 `D:\hupluna`，桌面 `hupu` 目录为工作副本（同步后于 D 盘构建）。DevEco 请打开 `D:\hupluna` 进行构建/调试。
> 构建命令：node + jbr(bin) 需在 PATH，`DEVECO_SDK_HOME` 指向 DevEco 的 sdk 目录。

**已探明接口口径（App 内已实现）：**

| 数据 | 接口 | 翻页 |
|---|---|---|
| 热帖流 | `GET m.hupu.com/api/v2/bbs/walkingStreet/threads?page=&cursor=` | `nextPage` + `cursor` |
| 板块帖子流 | `GET m.hupu.com/api/v2/bbs/topicThreads?topicId=&page=&cursor=` | 返回 20/页，按页大小判断 |
| 帖子详情 | `GET m.hupu.com/api/v2/bbs-thread/{tid}` | - |
| 评论 | `GET bbs.hupu.com/{tid}.html`、`{tid}-{N}.html` → `__NEXT_DATA__.props.pageProps.detail.replies` | 20/页、`total` 页数（需桌面 UA） |
| 分区树 | `GET m.hupu.com/zone` → `__NEXT_DATA__.props.pageProps.data` | - |
| 搜索 | `GET m.hupu.com/api/v2/search2?keyword=&puid=0&type=posts&topicId=0&page=` | `hasNextPage` |

---

## 0. v1 → v2 修订说明（本次审查结论）

| 级别 | 原计划问题 | 修订内容 |
|---|---|---|
| P0 | 版本基线过时（API 12 / DevEco 5.x） | 目标 API 取当前 DevEco 稳定版，兼容基线待定（见第 9 节决策点 1） |
| P0 | 无接口可行性验证，风险后置 | 新增 **M0 接口验证 spike**，未验证通过不得进入 M1 之后 |
| P0 | 数据链路单点，只押 App API | 改为三级链路降级策略（第 3 节） |
| P0 | 登录态未定义 | V1 明确"只读浏览"；登录（Cookie 注入）列为 V2 可选 |
| P1 | huks 注释笔误 | 网络层修正为 `@ohos.net.http` 封装 |
| P1 | 自建图片磁盘缓存 | 改用 ImageKnife（TPC 三方库），不自造轮子 |
| P1 | 排期无工时/验收标准 | 每里程碑补人天估算与验收物 |

---

## 1. 项目定位

| 项 | 内容 |
|---|---|
| 产品形态 | 普通应用（非元服务），Stage 模型 |
| 应用名 | **Hupu Luna**（显示名，标注非官方客户端） |
| 包名 | `com.hupluna.app` |
| 技术栈 | ArkTS / ArkUI；`compatibleSdkVersion` = **6.0.0(20)**（最低鸿蒙 6.0），`compileSdkVersion` / `targetSdkVersion` 取 DevEco 当前稳定版（截至 2026-10 为 API 26） |
| 数据来源 | 逆向虎扑 Web / H5 / 移动端接口，App 直连，无自建后端 |
| 设计语言 | 纯净轻快：无广告、无启动页、紧凑列表、原生组件、深色模式 |
| V1 功能范围 | 资讯/热榜流、社区帖文浏览、篮球数据/球员评分、搜索、本地收藏与关注（**只读，不含登录态操作**） |
| V2 候选 | Cookie 注入登录（点赞/回复/云收藏）、HTML 兜底解析、多设备同步 |

---

## 2. 功能范围：V1 / V2 分界

| 模块 | 页面 | V1 | V2 |
|---|---|---|---|
| 首页 | 资讯流 + 热榜 | ✅ | |
| 社区 | 分区列表 / 帖子列表 | ✅ | |
| 帖子详情 | 楼主内容 + 楼层评论（只读） | ✅ | 点赞/回复（需登录） |
| 篮球 | 赛程比分 / 数据统计 / 球员评分 | ✅ | |
| 搜索 | 帖子 / 资讯关键词搜索 | ✅ | |
| 我的 | 本地收藏、关注球队/作者（RelationalStore） | ✅ | 虎扑账号云收藏 |
| 登录 | Cookie 粘贴注入（设置页） | ❌ | ✅ |

---

## 3. 数据链路策略（新增，核心架构决策）

虎扑数据有三条可用链路，按"稳定性 × 成本"排序，客户端做成**可降级**结构：

| 链路 | 形式 | 优点 | 缺点 | 定位 |
|---|---|---|---|---|
| L1 · Next.js 内嵌 JSON | `m.hupu.com` 页面内 `__NEXT_DATA__`（实测存在，结构化 JSON） | 风控最松、免签名、**JSON 直取无需解析 DOM** | 字段随页面类型不同，需按页提取 | **首选主链路**（2026-10-03 实测修正） |
| L2 · H5/Web JSON 接口 | 浏览器 UA 的 xhr 接口 | JSON 直用、成本低 | 可能限流 | 主链路（次选） |
| L3 · 移动 App API | `*.mobileapi.hupu.com`，带 `client/night/token/sign` 公共参数 | 数据最全 | sign 摘要校验、易变更、风控严 | 备用链路，Signing.ets 集中收口便于热修 |

规则：同一份业务数据至少实现其中一条，Repository 层负责链路切换与结果归一化。

---

## 4. 工程结构规划

```
hupu/
├── AppScope/                      # 应用级配置（图标、应用名、版本）
└── entry/src/main/ets/
    ├── entryability/              # EntryAbility（Stage 入口）
    ├── pages/                     # 路由页面（首页/社区/详情/搜索/篮球/我的）
    ├── views/                     # 可复用组件（帖子卡片、评论楼层、Skeleton、三态组件）
    ├── model/                     # 数据模型（与接口字段映射，接口→模型收口）
    ├── network/                   # 网络层
    │   ├── HttpManager.ets        # @ohos.net.http 封装：超时/重试/UA/Referer/统一解析
    │   ├── HupuApi.ets            # 接口清单，一接口一方法，集中管理
    │   └── Signing.ets            # 公共参数补全 + sign 摘要（按 M0 结论实现）
    ├── repository/                # 数据仓库：链路降级、缓存策略、归一化
    ├── database/                  # RelationalStore（收藏/关注）+ Preferences（设置）
    └── common/                    # 常量、主题 token、工具函数
```

资源：`resources/`（string / color / media）、深色模式资源 `dark/` 目录。
工程配置：`module.json5` 声明 `ohos.permission.INTERNET`；若存在 http 明文接口，需配置 `network_config` 白名单。

---

## 5. 里程碑排期（含人天与验收物）

### M0 · 接口可行性验证（1-2 人天）⚠ **最大风险前置**
- 抓包工具过一遍 `bbs.hupu.com` / h5 / `*.mobileapi.hupu.com` 三条链路
- 连通性验证：资讯列表、帖子列表、帖子详情+评论、赛程 4 个最小集
- 确定公共参数（`client` / `night` / `token` / `sign`）与 UA、Referer 要求；记录 sign 算法结论
- **验收物：`docs/api-feasibility.md`** —— 哪条链路主用、哪些接口已打通、依赖哪些请求头
- **卡点：M0 未通过不进入 M2**（M1 骨架可照常进行）

**预探测结果（PC 侧 · 2026-10-03 已完成第一轮）：**

| 探测项 | 结果 |
|---|---|
| `bbs.hupu.com` | 200，传统 SSR（`bbs-pc-svc`），无内嵌 JSON 框架标记 |
| `m.hupu.com` | 200，**Next.js（pages router）**，页面内嵌 `__NEXT_DATA__` JSON，约 10KB/页 |
| `www.hupu.com` | 200 |
| `bbs.mobileapi.hupu.com` | 域名存活（根路径 404，需具体接口路径 + 公共参数） |
| 帖子 URL 模式 | `https://m.hupu.com/bbs/{tid}.html`（tid 为 9 位数字） |
| 图片 | 阿里云 OSS 参数可直接裁剪：`?x-oss-process=image/resize,w_600/format,webp` |

首页流样例（`__NEXT_DATA__.props.pageProps.res[]`）：

```json
{
  "tid": "642724300",
  "title": "热身赛：中国0-5巴勒斯坦，队史首次不敌对手",
  "url": "https://m.hupu.com/bbs/642724300.html",
  "label": "中国足球",
  "lights": "50",
  "replies": "1769",
  "type": "1_pic",
  "source": ["https://i1.hoopchina.com.cn/....jpeg?x-oss-process=image/resize,w_600/format,webp"],
  "isNews": true,
  "badge": []
}
```

第二轮探测（列表/详情页结构，同日完成）：

| 探测项 | 结果 |
|---|---|
| 社区分区树 | `https://m.hupu.com/zone?page=N` → `props.pageProps.data[]`（结构：categoryId / name / topicList[topicId / topicName / cateId / count / topicLogo]） |
| 帖子详情 | `https://m.hupu.com/bbs/{tid}.html` → `threadData.data`：`basicInfo`（tid/fid/author/topicName）+ `moduleConfigList`（title/user/content/topic 模块；**正文为二次嵌套 JSON 字符串，需二次解析**） |
| 列表翻页 | `?page=N` 分页；`/bbs` 301 至 `/zone` |
| 评论数据 | SSR 未包含（客户端 XHR 异步加载），接口路径待设备侧抓包确认 ⚠ |
| 页面体积 | 详情页约 16KB / 列表页约 14KB（压缩传输），解析成本低 |

**结论：L1 可行性极高，升格为首选链路；评论接口与 L3 待设备侧抓包确认。**

### M1 · 工程骨架（1-2 人天）
- DevEco Studio 新建 Stage 工程，确定包名（见决策点 4）
- Navigation + Tabs 骨架（首页/篮球/搜索/我的 4 Tab）
- 主题系统：深色/浅色全部走 resource token，含间距、字号、圆角 token
- 三态组件：Loading / Empty / ErrorState
- **验收：所有页面可点通，深色模式切换无硬编码色值**

### M2 · 网络与数据层（2-3 人天）
- HttpManager：超时、重试、UA/Referer 注入、统一返回体解析、错误码归一
- Signing.ets：按 M0 结论实现公共参数与 sign
- HupuApi.ets：资讯列表、热榜、帖子列表、帖子详情、评论、搜索、赛程、评分
- 模型类 + Mock 数据（链路全挂时可演示 UI）
- **验收：真机可拉通 M0 验证过的接口集，Mock 开关可切换**

### M3 · 核心内容页（4-6 人天）
- 首页资讯流 + 热榜（分页、下拉刷新、骨架屏）
- 社区分区 + 帖子列表
- 帖子详情（楼主内容 + 楼层式评论、楼中楼折叠）
- 图片：ImageKnife 接入，磁盘缓存开箱即用
- **验收：列表 500 项滑动流畅（LazyForEach + cachedCount），弱网有骨架屏，断网有 ErrorState**

### M4 · 数据与本地功能（3-4 人天）
- 篮球模块：赛程/比分/数据统计、球员评分榜
- 搜索模块
- 我的：本地收藏帖子、关注球队/作者（RelationalStore）
- **验收：收藏/关注重启不丢失，跨页面状态一致**

### M5 · 打磨与验证（2-3 人天）
- 启动速度、内存占用、列表复用参数调优
- 接口失效兜底：错误提示 + 自动切备用链路
- ArkTS lint 清零、真机调试
- 打包签名：debug 证书侧载测试
- **验收：冷启动到首屏 < 2s（真机），无阻断性 lint 错误**

**合计约 14-20 人天**（单人开发估算，不含接口逆向深水区的时间黑洞）。

---

## 6. 技术关键点

- **网络**：`@ohos.net.http` 自封装（不要用 huks，与网络无关）；https 为主
- **签名链路**：公共参数 + sign 摘要集中在 Signing.ets，一处可改，便于接口失效后快速热修
- **图片**：ImageKnife（TPC 三方库），缩略图接口参数裁剪；不自己实现磁盘缓存
- **状态管理**：ArkUI 状态管理 V2（`@ObservedV2` / `@Trace` / `@Local`），从 V2 起步避免 V1 混用踩坑
- **本地存储**：RelationalStore（收藏/关注，支持以后加分类和搜索）+ Preferences（设置项）
- **解析**：大 JSON 用 `JSON.parse` + 模型类收口；大字段解析走 TaskPool，不阻塞 UI
- **纯净设计**：无启动广告、无弹窗运营位、去营销模块；字体/间距统一 token
- **路由**：Navigation + NavPathStack，深链参数集中定义

---

## 7. 风险与应对

| 风险 | 影响 | 应对 |
|---|---|---|
| 虎扑接口变更 / 加签名校验 | 数据全部失效 | M0 前置验证；三级链路降级；Signing.ets 热修口；Mock 兜底 |
| sign 算法逆向失败 | L3 链路不可用 | 降级 L2 → L1；优先保证资讯/帖子核心数据 |
| 风控封 IP / 封 UA | 请求被拒 | 控制请求频率、缓存优先策略、UA/Referer 固定测试后不动 |
| 图片防盗链 | 图片 403 | 补 Referer/UA 头，M0 一并验证 |
| HTML 解析成本失控 | 工时膨胀 | L1 仅作兜底，V1 不追求全字段解析 |
| 侧载分发给他人受限 | 无法给别人装 | HarmonyOS NEXT 侧载需调试证书 + 设备 UDID 注册（限台数）；自用可行，公开分发不可行 |
| 商标/合规 | 下架或警告 | 应用显示名避免直接使用"虎扑"商标；标注非官方；不上架、不商业分发 |
| 深色模式色值硬编码 | 后期返工 | M1 起全部走 resource token，CI 自查 |

---

## 8. 验证方式

- DevEco Studio Previewer / 模拟器 / 真机（HarmonyOS NEXT 5.0+，建议备一台 6.0 真机）
- `hvigor` 构建 + ArkTS 编译期类型校验 + lint 清零
- 每里程碑验收清单：列表滑动流畅度、深色模式、断网兜底、接口变更容错、冷启动耗时
- M0 单独产出接口可行性报告，作为 M2 的输入

---

## 9. 决策记录（2026-10-03 已确认）

| # | 决策点 | 结论 |
|---|---|---|
| 1 | 兼容基线 | **6.0.0(20)**——最低支持鸿蒙 6.0；5.x 设备不支持，省兼容成本 |
| 2 | V1 登录 | **不做**，V1 只读浏览；V2 用"设置页粘贴 Cookie"方案 |
| 3 | SSR/HTML 链路 | 原"DOM 解析不进 V1"维持；但实测 `m.hupu.com` 为 Next.js 内嵌结构化 JSON，**L1 升格为 V1 首选链路**（2026-10-03 基于实测修正） |
| 4 | 应用名 / 包名 | 显示名 **Hupu Luna**；包名 `com.hupluna.app` |

> 注：显示名保留"Hupu"字样，自用侧载无碍；若以后考虑公开传播，需再评估商标问题。

---

## 10. 施工顺序一句话

**M0 验证接口能通 → M1 起骨架（与 M0 可并行）→ M2 网络层按验证结论落地 → M3 内容页跑通 → M4 补齐数据/搜索/收藏 → M5 打磨暗色与性能 → 真机侧载验收。**

---

## 11. V2 规划（2026-10-03 起草，待施工）

> 定位：V1 = "只读浏览" 已收官；V2 = **"可交互 + 更可靠"**。三条主线：
> ① 账号态（Cookie 注入）解锁写操作；② 数据链路加固（接口失效不白屏）；③ 体验补全。
> 版本基线从 `0.13.0` 起，延续 `com.hupluna.app`，不迁移架构。

### 11.0 V2-M0 · 登录态与写接口 Spike ✅ 已完成并实测通过（2026-10-03）

**探测方法**：逆向桌面 Web（bbs-pc-web）JS bundle 拿接口定义（webpack chunk 映射 → reply-compact-editor 等 chunk）→ 参数探测法补参（pcmapi 系列参数校验在鉴权前，可离线枚举）→ **真实 Cookie + curl.exe 实测闭环**。注意：桌面 chunk 下载必须带 `Referer: https://bbs.hupu.com/` 否则 404（防盗链）。

**核心结论：写接口族 100% 实测打通（云收藏/回复点亮/帖子点亮全部闭环成功），无 App 签名、无 CSRF，鉴权 = Cookie（ua/u/us 三键核心）+ 正确的客户端 TLS 栈。**

**★ 重大架构发现 —— 服务端校验客户端 TLS/HTTP 栈指纹**：同一份 Cookie + 同一 UA，PowerShell/.NET HttpWebRequest 全部 401，而 `curl.exe`（Windows Schannel 栈）全部 200 —— 与 UA/IP 无关（均实测排除）。桌面端验证脚本必须用 curl.exe；ArkTS `@ohos.http`（Node 系栈）待真机验证，大概率可通过（Node 指纹不在常见风控黑名单，且 m 站读接口一直在 ArkTS 上正常）。

| 项 | 结论 |
|---|---|
| 登录态判定 | Cookie `ua=` 键存在 = 已登录（值为 uid）；`GET m.hupu.com/api/v2/user` 带 Cookie → `{code:200,data:{uid,puid,username,header,spaceurl}}`（实测返回真实账号信息） |
| 云收藏 ✅实测 | `POST bbs.hupu.com/api/v2/threads/{tid}/collect` body `{}` → `code:200 成功`；取消 `DELETE` 同路径 → `code:200`；**闭环成功** |
| 回复点亮 ✅实测 | `POST /pcmapi/pc/bbs/v1/reply/light` body `{puid,pid,tid,fid}`（puid=被点亮回复作者）→ `code:1 PC000000 success`；取消 `.../reply/cancelLight` 同参 → `code:1`；**闭环成功** |
| 帖子点亮 ✅实测 | `POST /api/v2/light` body `{tid,pid}`（pid 必填，为回复 id）→ 幂等拒绝 `5003 你已经点亮过这个回帖了`（目标回复用户本已点亮，证明鉴权+参数全通）；`/api/v2/unlight` 语义为"点灭"方向（重复 `5009`），取消点亮接口待深究 |
| 发表回复 | `POST /pcmapi/pc/bbs/v1/createReply` body `{tid,fid,content}`（+可选 pid/quoteId/topicId；pid 非空=楼中楼）；content 为 HTML 文本（`<img src>` 拼接 ≤9 图）；鉴权层已通过，真实发帖实测待用户许可 |
| 错误码速查 | `code:200/1` 成功；`401/401000` 未登录（m 站）；`Unauthorized!` 文本 = bbs 网关未登录；`PC022002` 缺参、`PC022003` 未登录（pcmapi）、`5003` 重复点亮、`5009` 重复点灭、`5010` body 格式错 |
| Cookie 最小集 | `ua`（uid 标志）+ `u`（账号加密串）+ `us`（签名）为核心三件套；`_HUPUSSOID`/`_CLT` 会话辅助；`smidV2`/`tfstk` 等风控 cookie 建议全量携带；逐键剔除实测放 V2-M1 |
| 移动 Web 结论 | bbs-m-web 零写接口（交互按钮全部唤起 App），写操作只走桌面 Web 接口族 |
| 楼中楼新读接口 | `GET bbs.hupu.com/api/v2/reply/reply?tid=&pid=&maxpid=`（桌面版楼中楼，可替代/补充 m 站 bbs-reply-detail） |

**V2 写接口约定**：统一走 `bbs.hupu.com`（`/api/v2/*` 与 `/pcmapi/pc/bbs/v1/*`）；请求头 = `Referer: https://bbs.hupu.com/` + 桌面 UA + `Content-Type: application/json` + Cookie（ua/u/us 必须）。

**V2.1 新探明口径（m 站"我的"域 · 2026-10-03）**：Web 端用户空间仅限登录者本人（他人空间为 App 原生页，无公开接口；声望/被点亮/被推荐/关注/粉丝数字仅 App 原生可得）。

| 数据 | 接口 | 说明 |
|---|---|---|
| 我的资料 | `GET m.hupu.com/my`（带 Cookie，SSR HTML） | 头像 `class="avatar"` style url / 昵称 `class="name"` / 等级 `class="level"` / 卡路里 `class="calories"`；`m/my/{puid}` 参数被忽略恒返回本人 |
| 用户档案 | `GET m.hupu.com/my/userdetail`（SSR） | 数字ID/性别/论坛等级/卡路里/注册时间/自我介绍 |
| 我的主题帖流 | `GET m.hupu.com/my/userthreads`（SSR） | `<a href="//m.hupu.com/bbs/{tid}.html" class="bbs-list-a">` + `<h3>标题` + `bright-no` 亮数 + `icon-comment` 后 span 回复数 |
| 我的回帖流 | `GET m.hupu.com/my/userreplies`（SSR） | 同构 |
| 条数统计 | 主题帖页无总数无分页（20 条上限）；回帖页有分页控件（可翻页） | 数据行条数为首页条数（20 显示 20+） |
| 按用户过滤搜索 | ❌ `search2?puid=` 参数被忽略 | keyword 全站搜索，无法按用户过滤 |

**遗留验证项 → 真机验证通过（2026-10-03）**：✅ ArkTS http 栈指纹被风控接受（WebView 登录 + 云收藏/点亮/回复全链路真机实测成功，V2 写能力在端上完全可用）；Cookie 最小字段集逐键剔除实测与高频写风控阈值仍待后续按需摸底。

### 11.1 · Cookie 登录态（P0，依赖 M0 通过）

| 项 | 方案 |
|---|---|
| 注入方式 | 设置页"粘贴 Cookie"文本框（用户从浏览器 F12 复制整串），解析为键值对；不做内嵌 WebView 登录（风控 + 免维护） |
| 存储 | Preferences 存（`hupluna_settings/cookie_jar`）；不入 RelationalStore |
| 会话管理 | `SessionManager`：全请求统一附带 Cookie；启动时验证一次登录态；失效自动清空并降级只读 + 顶部提示条 |
| UI | 我的页新增账号卡（头像/昵称/等级，未登录显示"注入 Cookie"入口）；设置页"退出登录" |
| 安全 | Cookie 只存本机，不落日志 |

- **验收**：注入后重启保持登录；Cookie 失效自动降级不崩溃；退出后写入口全部隐藏

### 11.2 · 交互能力（P0，依赖 11.1）

| 功能 | 说明 | 优先级 |
|---|---|---|
| 点亮/取消点亮 | 帖子卡、详情、评论楼层；本地乐观更新 + 失败回滚 | P0 |
| 发表回复 | 详情页底部输入条；支持楼层引用；楼中楼回复 | P0 |
| 云收藏 | 详情页"收藏"改双写：本地 RelationalStore + 虎扑云收藏；列表以云端为准 | P1 |
| 关注 | 关注作者/话题 → 我的页聚合流（复用 topicThreads 接口） | P1 |
| 图片上传回复 | 写接口 + 上传接口双风险，若 M0 不通过则砍 | P2 |
| 发帖 | 独立编辑页，选择话题区；风控最敏感，放最后 | P2 |

- **验收**：官方 App 与本客户端互看数据一致；写失败有明确错误提示且不脏状态

### 11.3 · 数据链路加固（P0）✅ 已完成（2026-10-03）

> 实施记录：新增 `network/LinkHealth.ets`（连续 3 失败熔断 60s、半开恢复）、`database/CacheStore.ets`（Preferences 快照缓存，72h 过期）；`HupuApi.getThreadDetail` 挂接主链路健康度，失败降级 PC 站 `detail.thread` 兜底；`HomePage.loadActive` 与 `PostDetailPage.loadDetail` 缓存优先渲染（顶部"稍早内容"提示条，网络成功静默替换，失败保持缓存不白屏，下拉刷新跳过缓存）；设置页新增「清除数据缓存」。`LinkHealth.snapshot()` 备用，V2-M4 接入监控页。构建通过，HAP 已更新桌面。

| 项 | 方案 |
|---|---|
| L0 · HTML 兜底解析 | 当 `__NEXT_DATA__` 结构变更/缺失时，降级到 SSR HTML 结构化抽取核心字段（标题/正文/楼层），保证核心页不白屏 |
| 链路自动降级 | Repository 层加健康度计数：单链路连续 N 次失败自动切下一链路，恢复后自动切回 |
| 缓存优先渲染 | 冷启动先渲染上次缓存数据（带时间戳标记"稍旧"），后台静默刷新替换 |
| 接口监控页 | 设置页隐藏入口：各链路最近一次探活结果/耗时/失败原因，方便快速定位失效接口 |

- **验收**：人为改坏 L1 字段路径，App 降级 L0/L2 仍可浏览；冷启动秒开（缓存）

### 11.4 · 体验补全（P1）

| 功能 | 说明 |
|---|---|
| 正文字号调节 | 设置页 3 档（紧凑/标准/大字），详情页即时生效 |
| 阅读历史 | 本地记录最近 200 条已读帖，详情页标记"已读"，我的页入口 |
| 纯黑 OLED 模式 | 深色模式加深（#000 底），夜间省电护眼 |
| 分享 | 系统分享卡片（标题+链接）；详情长按楼层复制文本 |
| 双列瀑布流开关 | 首页/板块列表可选单列紧凑 / 双列瀑布（图片党友好） |

### 11.5 · 多设备同步（P2，技术预研）

- 优先方案：**收藏导出/导入**（剪贴板 JSON / 文件分享），零服务端成本，先落地
- 预研方案：`distributedKVStore`（鸿蒙分布式数据对象）——需同华为账号 + 设备组网，自用可行；若体验好再替换导出方案
- 虎扑云收藏（11.2）落地后，同步需求大部分自然消解，优先级可再降

### 11.6 · V2 排期一览（单人估算）

| 里程碑 | 内容 | 人天 | 依赖 |
|---|---|---|---|
| V2-M0 | 登录态/写接口 Spike | 1-2 | 无（卡点） |
| V2-M1 | Cookie 管理 + 登录 UI | 1-2 | M0 |
| V2-M2 | 点亮/回复/云收藏 | 2-3 | M1 |
| V2-M3 | 链路加固 + 缓存优先 | 1-2 | 无，可与 M0 并行 |
| V2-M4 | 体验补全五项 | 1-2 | 无 |
| V2-M5 | 打磨 + 打包 0.13.0 | 1 | 全部 |
| 合计 | | **约 7-12 人天** | |

### 11.7 · V2 风险与应对

| 风险 | 应对 |
|---|---|
| 写接口全部需 App 签名 | M0 卡点前置；不通过则 V2 收缩为 11.3/11.4，交互延后 |
| Cookie 有效期短（数天~数周） | SessionManager 失效检测 + 一键重注入引导；不自动刷新（不碰登录密码） |
| 写操作触发风控/封号 | 控制频率（发帖/回复加最小间隔）；自用小流量；文档明示风险自担 |
| 账号安全 | Cookie 仅存本机 Preferences；日志全脱敏；README 免责声明更新 |
| `__NEXT_DATA__` 字段变更 | L0 HTML 兜底 + 健康度自动降级，保证可用性下限 |
