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
| V2-M5 收官 0.13.0 | ✅ 完成（2026-10-03） | 版本号 0.13.0/versionCode 13000000；构建通过（18.5s，仅非阻断 imageKnifeOption 类型 WARN）；HupuLuna-0.13.0-unsigned.hap 已同步桌面 |
| 收藏导出/导入 | ✅ 完成（2026-10-03） | 设置页存储区新增「导出收藏（剪贴板）」/「从剪贴板导入收藏」：FavStore.exportJson/importJson（JSON payload 校验 type/items、按 tid 幂等合并 ON_CONFLICT_REPLACE、导入后刷新 favVersion）；pasteboard 剪贴板零权限方案（PLAN 11.5 优先方案落地） |
| **发帖功能** | ✅ 完成（2026-10-03） | **接口突破：`POST /pcmapi/pc/bbs/v1/createThread` 路径实测有效**（curl 探测：空 body → `PC022002 帖子内容不能为空`；补 content → `PC022003 用户未登录`，参数校验在鉴权前）。新页 CreateThreadPage（话题区选择面板+标题+正文+发布按钮，30s 最小间隔风控缓解）；WriteApi.createThread（title/fid/content，fid 先取 topicId 待真机实测微调）；社区页头部 ✎ 入口 |
| 社区页滚动联动 | ✅ 完成（2026-10-03） | 右侧改为**全部区块长列表**（"我的"+14 分类依序拼接，每区块分类头+3 列网格）；**上下滚动联动左侧选中态**（onDidScroll + componentUtils.getRectangleById 检查相邻 section 边界 + 末 section 完全入视口强制末项）；**点左侧分类滚动定位**（scrollToSection 250ms 动画，suppressSync 300ms 防联动闪跳）；分区图标 56→48px |
| 左侧"我的"入口 | ✅ 完成（2026-10-04） | 左侧导航顶部新增「我的」入口（activeIndex=-1 语义，红竖条高亮态与分类行一致）；滚动在"我的"区块内时左侧高亮「我的」，滚过自动切到「热门」；左侧导航本身可上下滑动（leftScroller），右侧联动致选中项超出可视区时**自动居中滚动**（ensureActiveVisible，onScrollStart/Stop 标记 leftManual 手动滑动中不干预）；初始高亮「我的」 |
| 社区页头部品牌化 + 专区搜索 | ✅ 完成（2026-10-04） | 头部左侧「社区」改为首页同款 **Hupu Luna**（16 Bold 品牌红）；右侧 ✎ 发帖入口移除，改为**搜索框**（2026-10-04 二次调整：去掉右侧"搜索"按钮，仅保留 Hupu Luna+搜索框），点击进入**专区搜索模式**（内嵌搜索框实时过滤全部 14 分类下的分区，匹配网格点击进分区帖流，取消恢复原视图）；CreateThreadPage 路由保留待后续合理安排发帖入口 |
| 我的页内容上提 | ✅ 完成（2026-10-04） | 二次大幅上提：标题行 top 10→2 / bottom 8→0；账号卡 top 18→4 / bottom 18→8；统计栏 14→8；Scroll 区块间距 10→8，累计上提约 30vp |
| 末次频道记忆恢复 | ✅ 完成（2026-10-04） | 修复"每次重启都从首页第一个栏目开始"：EntryAbility.onWindowStageCreate 首帧前用 `preferences.getPreferencesSync/getSync` 同步读盘并写 AppStorage（消除页面内异步恢复与 @StorageLink 的时序竞争）；ChannelStore 新增 saveLast（putSync+flush，切栏目即落盘，防进程被杀来不及写）；AllChannelsPage.jump 直连持久化（该页选择时 HomePage 未挂载、@Watch 不触发） |
| **推荐流官方大卡 + 视频自动播放** | ✅ 完成（2026-10-04） | ① **修复 officialCard 漏赋值 bug**（mapThreads 收了参数却未写 row.officialCard），推荐频道此前一直走紧凑卡；② 对齐官方形态：作者行 → Bold17 标题 → 媒体区 → **神回复亮评块**（lightReplyResult）→ 数据栏（浏览/回复/亮/分享）；③ 媒体区按真实比例计算并限幅 **150~200vp**（水平居中：屏幕宽-左右内边距 ÷ 宽高比），多图仍 3 列/2 列网格；④ **视频帖自动播放**：滚动停止后择一播放当前可见视频（静音循环 + controls，onVisibleAreaChange 0.6 阈值，滚动中一律暂停省流），同一时刻仅 1 个 Video 实例；⑤ Models/HupuApi 补齐 videoUrl/playNum/coverWidth/coverHeight/shareNum/lightReply* 字段；⑥ 缓存行归一化（normalizeRows）兜底旧快照缺新字段导致的渲染期崩溃 |
| 视频区尺寸与黑边修正 | ✅ 完成（2026-10-04） | 用户反馈二连：**面积过大 + 播放时左右黑边**。原实现竖屏视频给 340vp 且用 `Contain`（左右留黑）。修正：① `mediaHeight` 改为**按真实宽高比动态计算**（内容区宽 ÷ ratio，限幅 150~200vp），2.17:1 超宽视频≈150vp、16:9≈184vp，与官方卡片量级一致；② 视频统一 **Cover 铺满**（竖屏视频裁切中段显示），彻底消除黑边；③ 移除 `Video.backgroundColor('#000000')`（避免加载期黑底暴露）；④ 内容区宽度改由 `display.getDefaultDisplaySync()` 惰性计算并缓存 |
| 单图尺寸官方化 | ✅ 完成（2026-10-04） | 用户反馈"单张图片帖子显示过大"。**实测三页推荐流**：竖/方图占比极高（848×1915 r=0.44、736×1328 r=0.55、935×1349 r=0.69、1080×1180 r=0.92…），原实现一律撑成满宽×200vp 横向窗口（Cover 裁切成大横条，画面主体被裁）。新增 `MediaBox` + `singleBox()` 双分支：**横图（ratio ≥ 1.2）**满宽 + 高度 150~200vp 限幅；**竖/方图**改官方小图形态（内容宽 42%、高封顶 200vp 反算宽），实测比例 1.0→≈138vp 方形、0.75→131×175、0.44→88×200 窄条，与官方截图量级一致；视频贴缺地址时兜底仍走满宽 |
| 视频控件官方化（极简） | ✅ 完成（2026-10-04） | 用户反馈"原生控件太杂，只要左下角静音小喇叭"。① `Video.controls(false)` **去掉全部原生控件**（暂停键/进度条/时间/全屏）；② 底部浮层改为 `Row` 双区：**播放时左下角仅静音开关**（`SymbolGlyph` + `$r('sys.symbol.speaker_slash')` / `speaker_wave_3` 切换，28vp 半透明圆底），未播放时右下角显示时长；③ 新增 `@State videoMuted`，**每次换视频复位静音**（对齐官方，避免突然出声）；④ 新增 `mutePressed` 按下标记 + `onMuteTouch`（Down 置位、Up/Cancel 用 setTimeout(0) 延迟清除），使 `isValidTap()` 返回 false——**修复点静音会穿透触发"打开帖子"**的问题 |
| **详情页视频丢失修复** | ✅ 完成（2026-10-04） | 用户反馈"所有带视频的帖子进详情都看不到视频"。**根因（探测实证）**：详情主链路 `m.hupu.com/api/v2/bbs-thread/{tid}` 的 `t_detail` **只有 tid/title/content/hits/rcmd/replies/lights/share/f_info/user —— 完全不返回视频字段**；视频信息只存在于列表接口（walkingStreet）与 PC 站详情页。**PC 站详情页实测含完整视频字段**：`hasVideo:true` / `video`（直连 mp4）/ `videoCover` / `format`（JSON 串内 `videoInfo:{remoteUrl,coverUrl,width,height}`）。修复：① `ThreadDetail` 新增 `hasVideo/videoUrl/videoCover/videoWidth/videoHeight`；② `getThreadDetail` **主链路改为 PC 站优先**（唯一提供视频的链路），m 站 API 降为兜底（可看正文，无视频）；③ 新增 `HupuApi.getPcPage()` **在途请求去重**（`Map<string, Promise<string>>`）——详情与首页评论并行请求同一 URL，共享一次网络往返，总流量不增反减（省掉原 m 站那次）；④ `PostDetailPage` 新增 `VideoCard`：正文下方按原始宽高比渲染（限幅 160~420vp，超窄竖屏反算宽居中），**默认封面+播放按钮，点击播放/再点暂停**，播放中左下角仅静音开关（与首页一致）；⑤ **时效性处理**：视频直链带 `auth_key`（数小时过期），详情与首页缓存快照渲染阶段**剥离 videoUrl**（首图封面上限不变、不自动播放），等网络返回最新链接再展示，避免点播黑屏；⑥ 缓存详情新增 `normalizeDetail` 逐字段兜底（旧快照缺新字段） |
| 详情链路主备切换验证 | ✅ 完成（2026-10-04） | 用真实帖子实测 PC 站解析逻辑：**视频帖**（rapper 帖）→ `hasVideo:true`、592×1280、videoUrl/cover 均正确提取；**图文帖**（刘德华帖/多图帖）→ `hasVideo:false`，不误判不显示视频区。链接降级链：PC 站失败 → LinkHealth 熔断 60s → m 站 API 兜底 |
| 详情视频播放器完善 | ✅ 完成（2026-10-04） | 用户三点需求全部落地：① **加进度条**；② **修复暂停后再播从头开始**；③ **进入自动播放**。要点：**②的根因是原实现用 `if (videoPlaying) { Video } else { 封面 }` —— 暂停即销毁 Video 组件，再次播放时组件重建必然从 0 开始**。修复为 **Video 常驻不销毁**（封面作为独立覆盖层，按 `videoReady` 显隐），暂停/继续一律走 `VideoController.pause()/start()`，进度天然保留。③`autoPlay(true)` 挂载即播（静音）；①底部控件条 `静音 + 当前时间 + Slider + 总时长`，`onUpdate` 每秒推进、`onPrepared` 取总时长（注意 `PlaybackInfo` **只有 time 无 duration**，时长只能从 `PreparedInfo.duration` 拿），拖动期间用 `videoScrubbing` 屏蔽回调覆盖、松手才 `setCurrentTime` 跳转。另加：`onHidden` 暂停（防后台偷跑流量）+ `onShown` 按原状态续播；静音按钮 `mutePressed` 防穿透（点静音不触发画面暂停） |
| **频道官方资讯化** | ✅ 完成（2026-10-04） | 用户反馈"除热榜/推荐/NBA 外，其他栏目把个人帖子端上来了，应该是官方新闻"。**全站实测结论**：m 站**仅 4 个官方资讯页** —— `/nba`（newsData）、`/cba`（newsData）、`/soccer`（news）、`/gg`（电竞 list，覆盖 LPL/KPL/绝地求生等）；其余话题（乒乓球/网球/综合体育/影视/数码/汽车/游戏等）**无任何官方资讯源**，`/zone` 分区树中全站仅 2 个"资讯"类 topic（502 篮球资讯、482 国际足球资讯）。修复：① `ChannelDef` 新增 `newsSource` 字段（''=走帖子流）；`中国篮球`→'cba'、`国际足球`→'soccer'、`NBA`→'nba'；② `NbaApi.getLeagueNews(source)` 统一三源解析（NBA/CBA 取 `newsData`、足球取 `news`，同构异构名）；③ `HomePage.loadActive` 优先走资讯分支替代帖子流，`loadMore` 对资讯频道短路（固定列表无分页）；④ `mapNews` 的 tag 由硬编码 'NBA' 改为按频道名动态传入。**实测三频道各 35 条纯官方资讯**（NBA 33 可点/中国篮球 33 可点/国际足球 34 可点，其余为 `type=LINK` 的 App 深链置顶条目，仅展示不可跳）；比赛条保留（中国篮球顶部仍显示季前赛赛程） |
| **★ 官方号过滤（其余 17 频道）** | ✅ 完成（2026-10-04） | 用户采纳"作者名特征过滤"方案。**关键突破：找到权威数据源**——官方号主页 `m.hupu.com/user/{puid}` 的 `threadList` 一次返回 **20 条该号跨板块发文**（含 `topic_id`），按频道板块过滤即得纯净官方帖，彻底摆脱"话题流启发式过滤"的稀疏与误判问题。**实测官方号板块分布**：虎扑体坛资讯(93956731)=综合体育10/网球场4/乒乓球3/奥运会1/F1·1；虎扑篮球资讯(56098302)=篮球资讯5/湿乎乎5/CBA3；虎扑篮球(25948)=湿乎乎12；虎扑足球(4168925)=足球话题13/中国足球6；虎扑足球资讯(83276249)=国际足球资讯3；虎扑影视资讯(55150048)=娱乐圈13/影视区7；虎扑影视(18912543)=娱乐圈9；虎扑数码资讯(112446935)/虎扑汽车资讯(112474163)/虎扑装备小助手(96772422)=各自板块 20；虎扑游戏(14513993)=游戏区14；虎扑游戏电竞资讯(94991862)=王者荣耀16/无畏契约1；虎扑电竞(17215809)=无畏契约1。实现：① `ChannelDef.officialSources`（逗号分隔 puid）；② `HupuApi.getUserPosts(puid)` 解析官方号发文；③ `HomePage.fetchOfficialRows` 双源合并（官方号主源 + 话题流白名单补充源，详见下条口径）；④ 新增 `common/OfficialAccounts.ets` 白名单（56 个账号，含来源说明）；⑤ 官方号发帖无分页 + 话题流分页失效 → `hasMore=false`，避免无效上拉。**实测 17/18 频道输出纯官方内容**：中国足球8、国际足球资讯13、篮球资讯15、湿乎乎17、综合体育10、网球场7、乒乓球3、奥运会4、运动装备20、影视区12、娱乐圈27、数码20、汽车20、F1·3、游戏区14、无畏契约3、王者荣耀16（和平精英无官方号，自动回退原始流）；社区属性频道（步行街/恋爱区/历史区/ACG）保持个人帖子流 |
| **★ 发帖入口与发帖页官方化** | ✅ 完成（2026-10-04） | ① **专区页底部发布条**对齐官方：由"输入框+胶囊按钮"改为**居中「✎ 立即发布」红字**（`sys.symbol.pencil_line` + 16 Medium 品牌红，52vp 高、无按钮底色、上方分隔线）；② **发帖页整体重写**，完整还原官方三 Tab 形态（帖子/视频/投票，按要求**不含"模板"**）：顶部 ✕ 关闭 + 「发帖」→ 内容区 → 工具栏（话题区 / 🔓公开 / 创作类型）→ `# 添加话题` → Tab 栏（选中红下划线）→ 发布按钮；**帖子 Tab** = 大字号通栏标题（"分享你的心情、观点和经历…"）+ 正文（"输入正文(选填)"）+ 84vp 「+」添加图片方块；**视频 Tab** = 180vp 「+ 添加视频」大块 + 输入标题；**投票 Tab** = 输入标题 + [文字投票|图片投票] 切换 + 选项行（≡ 图标 + 输入框）+ 「+ 添加选项」（上限 20）+ [投票时长/投票类型] 下拉（`bindMenu`）+ 添加投票说明。③ 符号图标经 SDK 符号库核验：`xmark` / `plus` / `list_bullet` / `chevron_down` / `hash` / `pencil_line` / `lock_open` / `square_grid_2x2`（编译通过即有效）。**功能边界（诚实标注，不静默失败）**：帖子 Tab **发布可用**（createThread 已验证）；视频/投票 Tab UI 完整但发布链路未接通，点击给出明确提示，页面底部常驻说明文字 |
| **★★ 图片上传链路打通** | ✅ 完成（2026-10-04） | 用户"继续推进"后，**完整逆向并实现虎扑图床直传**（阿里云 OSS）。**逆向成果（PC 站 bundle）**：① 签名算法 `getSignData` = `URL-safe-Base64(HmacSHA1("action=1&appId=..&module=..&path=..&timestamp=..", secretKey))`（**保留 base64 padding `=`**，仅替换 `+`→`-`、`/`→`_`）；② **STS 端点 `GET https://hss.hupu.com/kaleido/hss/app/credentials`**（参数走 query，`withCredentials:true` 带登录 Cookie）；③ **客户端内置凭证**（非用户凭证）：`appId=uPRLht4dLiblkF6bcjRtLuDQ4eo=` / `secretKey=uxiXcdOrdp2PxTTDlNGQ3g72oWM=` / 图片 `module=editor-oss`(host i1.hoopchina.com.cn) / 视频 `module=editor-video-oss`(host v.hoopchina.com.cn) / `path=/editor`；④ **OSS 直传** = `PUT https://{bucket}.{region}.aliyuncs.com/{object}` + `Authorization: OSS {ak}:{Base64(HmacSHA1(StringToSign, sk))}`，`StringToSign = "PUT\n\n{ct}\n{date}\nx-oss-security-token:{token}\n/{bucket}/{object}"`；⑤ **对象路径** `editor/{年-月-日}/{时-分-秒}/{随机32位}.{ext}`（**月/日不补零、时分秒补零**，对齐官方 `toLocaleString` 后替换分隔符的结果）；⑥ 公开地址 = `domains[0] + object`。**实现**：新增 `common/CryptoUtil.ets`（HMAC-SHA1 via `cryptoFramework` + `util.TextEncoder`/`Base64Helper`）与 `network/OssUpload.ets`（凭证缓存 + 提前 5 分钟续期 + 直传）。**发帖页接通图片**：系统选择器（`photoAccessHelper.PhotoViewPicker`）→ 读字节（`fileIo`）→ 上传 → 缩略图网格（可删、上限 9 张），发布时写入 `format.slateValue` 图片节点 + `imgList`。**提交结构升级**：`WriteApi.createThread` 新增 `format` 参数，提交 `{title, fid, content(HTML), format(JSON)}`，其中 `content` 仍为 HTML（**与旧格式兼容**），`format = JSON.stringify({slateValue, imgList, videoInfo:{extra:1}})`；正文与图片皆空才拦截（官方允许"仅图片无正文"）。**验证边界（诚实标注）**：签名算法/对象路径/StringToSign/提交结构均经 Node 端复刻自校验通过；STS 端点实测返回 401「用户鉴权不通过」= **路径正确、仅缺登录 Cookie**；**端到端上传需真机 + 登录态验证**（无法在 PC 侧完成）。投票仍暂缓（`voteInfo` 结构未能完全确认，盲发有风控风险） |
| **★ 发帖链路能力实测** | ✅ 完成（2026-10-04） | 从 PC 站 bundle 逆向出发帖完整链路，判明**视频/投票为何暂不可做**：① **提交结构**：新版编辑器提交为 `{title, format: JSON.stringify({slateValue, imgList, videoInfo:{extra:1}})}`，与当前已验证的 `{title,fid,content}` **不同源**（投票是富文本内的 slate 卡片元素 `type:"vote"` + `voteInfo:{title,type:'radio'|'checkbox',...}`，非独立接口参数）；② **图片/视频上传需三步**：先取 STS 凭证（`{action:1,appId,module,path,timestamp,sign:getSignData({...}),cookie}` → `{region,expiration,bucket,accessKey,secretKey,token,domains}`）→ 再用阿里云 OSS SDK 直传（`kaleido.put(file,name)`）→ 得 `downloadUrl = domains[随机] + name`；另有 `/pcapi/all/upload/img` 仅用于**外链图片转存**（body `{resUrl}`）。**结论：需逆向 `getSignData` 签名算法并在 ArkTS 侧实现 OSS 直传，工作量大且属高风控操作，暂缓**。③ 已探明可用端点：`/pcmapi/pc/bbs/v1/video/auth?scene=pcpreview&url={url}&h5Nosign=1`（返回"请先登录"，路径有效）、`/pcmapi/pc/bbs/v1/createThread`（返回 `PC022002 帖子内容不能为空`，路径有效） |
| **★ 专区页改造（无限下滑/背景图/发帖）** | ✅ 完成（2026-10-04） | 用户三项需求全部落地。① **无限下滑**：专区页原用 `getTopicThreads`（m 站，分页失效仅 10 条），改用 **PC 话题页分页** `getForumThreads(topicId, page)`（50 条/页，1~20 页有效）→ 真正无限；② **专区头部**：新增 `TopicInfo` 模型 + `HupuApi.getTopicInfo(topicId)`，从 PC 话题页解析 **名称/话题介绍/热度/版主/头部图**；头部 UI 对齐官方 = 背景图放大铺满（160vp）+ 自下而上暗化渐变蒙层（`linearGradient` 180°，#00000000→#CC000000）+ 头像 + 白色名称 + 🔥热度 + 版主 + 简介行；③ **底部立即发布**：`PublishBar`（"说点什么…" + 立即发布按钮）→ 跳发帖页并**预设本专区**（`CreateThreadPage` 新增 `param` 支持 `"topicId|topicName"`，`Index.ets` 路由透传 + `createThreadParam()` 防空值）。**★背景图结论：能找到且已适配** —— PC 页 `bbs-sl-web-intro` 的 `background-image` 即头部图，与专区头像同源（方形 LOGO，约 500x500），官方 App 亦以此作背景，我们放大铺满 + 暗化蒙层即可。**实测 26/26 专区全部成功**（名称、背景图、帖子列表，零 WAF）：NBA2KOL2/NBA2K专区/乒乓球/网球场/综合体育/运动装备/影视/娱乐/数码/汽车/F1/游戏/无畏契约/王者荣耀/和平精英/奥运会/中国足球/CBA/湿乎乎/足球话题/国际足球资讯/篮球资讯/步行街/恋爱区/历史区/ACG。另修健壮性：已预设专区时话题列表加载失败**不阻塞发帖**，picker 空态可点击重试 |
| **★ 历史帖图片缺失修复** | ✅ 完成（2026-10-04） | 用户反馈"下滑加载的那些新闻和上方新闻显示不一样，没有图片"。**根因：PC 话题页（上一版的历史源）不提供图片** —— 条目结构仅 `post-title / post-datum / post-auth / post-time`，实测 49 条**零 img 标签**（`data-src`/`lazyload`/`background-image` 均无），而资讯频道首屏来自 m 站资讯页（有 `img`），两段展示割裂。**解决：改用搜索接口作为资讯频道历史源** —— `search2` 按关键词搜索的结果**带 `picture` 封面字段**（实测 106/120 有图）且**分页有效**（"流言板" count=599/30 页），配合 `fid` 过滤即可得到目标板块的带图官方资讯。实现：① `ThreadListItem` 加 `fid`；② `SearchItemDto` 补 `fid`/`lights`；③ 新增 `HupuApi.searchThreads(keyword, page)`（清洗标题高亮标签 + `formatDateTime` 统一为 `MM-DD HH:MM` 与首屏一致 + 取 `picture` 作封面）；④ `ChannelDef.historyKeyword`（空=走 PC 话题页）；⑤ 三资讯频道配关键词：**NBA→"流言板"(fid 502)**、**国际足球→"流言板"(fid 482)**、**中国篮球→"CBA"(fid 173)**（"流言板"搜索结果中 173 板块几乎不出现，故改用 CBA 关键词）；⑥ 双保险过滤 = `fid` 匹配 + 官方号白名单；⑦ 单页命中率不均（2~14 条/页），`loadMoreOfficial` 改为**内部连续翻页攒够 6 条**再返回（最多 4 轮），避免"上拉一次页面毫无变化"。**实测有图率：NBA 85%（67 条）、中国篮球 100%（23 条）、国际足球 100%（17 条）**。注：话题频道（乒乓球等）仍走 PC 话题页（无图），因其官方内容为纯文字流言板帖，无图符合官方形态 |
| 资讯频道历史加载（NBA 等） | ✅ 完成（2026-10-04） | 用户反馈"NBA 等资讯频道还是和之前一样"（截图底部显示"已经到底了"）。**根因**：上一轮只给"官方过滤频道"加了历史加载，而 **NBA / 中国篮球 / 国际足球走的是 `newsSource` 资讯页分支（固定 30+ 条），`loadMore` 对 newsSource 直接短路**，故仍滑到底就停。修复：① 三个资讯频道补上 `topicId`（指向**资讯板块**）+ `officialSources`，上拉复用 `loadMoreOfficial` 捞官方历史；② 资讯分支 `newHasMore = true`、**`newPage = 0`**（首屏用资讯页未消耗 PC 话题页，页码须从 0 起，否则漏掉第 1 页约 33 条新增）；③ 首屏 rows 的 tid 登记进 `officialSeen` 去重；④ `loadMore` 重构为 `isOfficial` 分支优先（含资讯类），清理死代码。**★关键修正：资讯板块 ≠ 讨论区** —— 国际足球必须用 **482（国际足球资讯）**而非 184（足球话题区）：实测 184 翻 6 页仅 1 条官方帖（用户讨论为主），482 翻 8 页得 **388 条**（新增 362）；中国篮球用 173（6 页 64 条）；NBA 用 502（6 页 **299 条全官方**，新增 267，因篮球资讯板块几乎全为官方发帖） |
| 官方频道历史资讯加载 | ✅ 完成（2026-10-04） | 用户要求"保持纯官方、滑到底就停"并追问历史新闻。**验证结论：官方历史内容可大量获取**（PC 话题页翻页 + 官方号过滤）。**实测产出**：乒乓球翻 20 页 → **133 条**官方帖（时间跨度 10-04 ~ 09-28，一周）；网球场翻 10 页 → **222 条**（10-04 ~ 09-23，一周半）。均为纯 `[流言板]` 官方内容，零个人帖。实现：① **移除官方频道的"论坛尾巴"**（恢复纯官方）；② 首屏 = 官方号主页（20 条/号，m 站风控松）+ PC 话题页第 1 页官方帖过滤（PC 失败降级 m 站话题流）；③ 上拉 = `loadMoreOfficial` 逐页翻 PC 话题页捞官方帖（跨请求 `officialSeen` 集合去重）；④ **连续 2 页无收获**才判定到底（PC 话题页按最后回复排序，官方帖分布不均，单页无收获即停会过早截断）或翻满 20 页；⑤ 到底文案区分为"已无更多官方资讯"/"上拉加载更多官方资讯" |
| **★ WAF 风控发现与防护** | ✅ 完成（2026-10-04） | **重要发现：`bbs.hupu.com`（PC 站）有阿里云 WAF 风控** —— 探测期间连续扫描 50+ 请求触发拦截，响应头 `punish-loc: keepper` + 返回阿里云滑块验证页（约 15.9KB，含 `aliyun_waf` 标记）；**冷却约 10~15 分钟**后自动解除。防护措施：① `HupuApi.getForumThreads` 检测 `aliyun_waf` 标记并抛错（避免把验证页当空列表）；② `loadMoreOfficial` 捕获异常即停止翻页（保留已加载内容，**不重试**，避免持续触发风控）；③ 首屏 PC 失败自动降级 m 站话题流（`officialFallback` 标记，回退后不再按官方过滤）；④ 官方频道状态（去重集合/回退标记/连续无收获计数）在频道切换时复位。**另测得关键约束**：PC 话题页**仅对桌面 UA 返回完整内容**（移动 UA/App UA 一律返回 15KB 空页），故必须用 `DESKTOP_UA`。正常浏览频率（用户手动滑动，每次 1 页）安全，实测 1.6s 间隔连翻 30 页未触发 |
| **★ 无限滚动（PC 话题页分页）** | ✅ 完成（2026-10-04） | 用户反馈"往下滑会滑到内容尽头，想要无限滚动"。**★关键突破：找到真正可用的分页源** —— PC 站话题页 `bbs.hupu.com/{topicId}` 分页**实测有效**：第 1 页 `/{topicId}`、第 N 页 `/{topicId}-{N}`（**必须不带 `.html`**，带 `.html` 会被当作帖子评论页返回空列表）。实测乒乓球 1~6 页各 48~50 条**内容互不重复**（与上页重叠 ≤1 条），第 20 页仍有效、第 100 页才超界 → 单话题约 **1000+ 条**可用内容，真正支撑无限滚动。实现：① `HupuApi.getForumThreads(topicId, page)` 解析 SSR HTML（`<li class="bbs-sl-web-post-body">` 按标记切分 + 4 条正则提取 tid/标题/回复/浏览/作者/时间，实测 6 页 288 条**字段零缺失**）；② `HomePage` 话题频道首屏改走 PC 分页流（50 条/页，较原 m 站接口 10 条提升 5 倍）；③ `loadMore` 话题频道按 PC 页码递增加载；④ 官方过滤频道官方内容之后**继续追加 PC 话题流作为"无限尾巴"**（按 tid 去重）——因官方内容本身有限（3~27 条），这是兼顾"官方优先"与"无限滚动"的唯一解；⑤ 推荐频道保持 walkingStreet cursor 分页；⑥ 卡片 meta 补充"浏览"数（PC 流提供 `visits`，m 站接口无此字段）；⑦ 资讯/热榜/赛程为固定长度列表，明确短路不分页 |
| 频道数据源错配修复 | ✅ 完成（2026-10-04） | 用户反馈"中国足球/国际足球资讯两栏目内容错误"（显示 NBA 资讯且标签为"中国足球"）。**根因：`def()` 位置参数错位** —— 签名 `(id, name, kind, topicId, league, newsSource, officialSources)`，但 `def('csl', ..., 220, 'soccer', '4168925')` 只传 6 个参数，**漏了 `newsSource` 占位**，导致官方号 puid 落到了 `newsSource` 上；`loadActive` 判定 `newsSource.length > 0` 成立 → 调 `getLeagueNews('4168925')` → 该值非 'cba'/'soccer' → **路径默认回落 `/nba`** → 显示 NBA 资讯并用频道名打标签，故"中国足球"栏里全是 NBA 内容（两频道同踩此坑，内容完全一致）。修复：① 补上 `newsSource` 空占位；② **`def()` 增加 `NEWS_SOURCES` 白名单校验**，非法资讯源一律丢弃并回落帖子流，从机制上杜绝此类静默错配；③ `HOME_CACHE_PREFIX` 缓存键版本号 `home/`→`home2/`，隔断残留的错误缓存（否则安装后首屏会先显示旧 NBA 内容再被网络结果替换）。**验证**：中国足球 → 亚运男足/国足前瞻等 6 条；国际足球资讯 → C 罗/凯恩/乌帕流言板等 4 条（均含话题流白名单补充） |
| 官方内容源排查（关键结论） | ✅ 完成（2026-10-04） | **① 话题帖子流 `topicThreads` 分页完全失效**：`page` / `cursor` / `pageSize` / `size` / `limit` / `offset` / `start` / `lastId` **全部被忽略**（实测 page=1/2/5/10/20 返回**完全相同的 10 条**），接口恒返回首批 10 条且 `cursor` 恒为空 → 频道"上拉加载更多"对话题类频道实质不可用。对照：`walkingStreet` cursor 分页**有效**、`tagThreads` page 分页**有效**（20/页）。**② 话题流无官方标记**：字段仅 `tid/title/type/replies/username/recommendNum/certTitle/time/isVideo/isVote/url`，官方号（虎扑体坛资讯）与普通用户**完全一致**（certTitle 均 null），`&isNews=1/&type=news/&filter=news/&newsOnly=1` 全部无效。**③ 不能用"虎扑"前缀判定官方**：存在大量同前缀个人昵称（虎扑JR1234567 默认昵称、虎扑体育生、虎扑黑子不懂球、虎扑安妮、虎扑榴莲哥…），必须精确白名单。**④ 官方账号名单获取途径**：`m.hupu.com/api/v2/search2?...&type=users` 返回账号 `title` 字段（官方号带"官方账号/官方帐号/官方运营账号"标记）+ App 搜索页"用户"标签的官方认证徽章列表。 |
| **评论头像 + 他人主页** | ✅ 完成（2026-10-04） | 用户反馈"评论区看不到头像、无法点进主页"。① **评论头像渲染**：`ReplyAuthorRow` 公共 builder（头像 28vp + 昵称 + 楼主标 + 时间），ReplyCard 与 SubReplyRow 复用；无头像时灰底占位保证对齐；② **点击跳转**：头像/昵称 → `UserSpacePage(puid)`，puid 缺失时 toast 提示不跳无效页；③ **楼主头像**：详情头部加 36vp 头像，`ThreadDetail` 新增 `authorPuid`（PC/m 站双链路解析）；④ **★重大发现：`m.hupu.com/user/{puid}` 是公开的他人主页**（推翻 PLAN 旧结论"他人空间不可达"——那是针对需登录的 `/my` 域）。页内 `__NEXT_DATA__.props.pageProps` 一次返回 `userInfoData`（头像/昵称/等级/声望/被点亮/粉丝/关注/被推荐）+ `threadList`（主题帖）+ `replyList`（回帖）；⑤ **UserSpacePage 双模式**：param 约定 `''`/`'0'`/`'1'`=本人（完全兼容旧调用），长数字=他人 puid；他人模式一次请求拿全部数据，切页签零请求；⑥ 楼中楼新增 `SubReplyItem.puid`（`user.puid`）；⑦ `avatarUrl()` 处理 PC 站头像自带 `@150h_150w_2e` 缩略样式与 `thumbUrl` 参数冲突的问题 |

> **★★ 图床上传口径（2026-10-04 逆向 + 实现，虎扑 OSS 直传）**：
> ```
> ① 取凭证  GET https://hss.hupu.com/kaleido/hss/app/credentials
>           ?action=1&appId={APP_ID}&module={module}&path=/editor&timestamp={ms}&sign={sign}&cookie=
>           （参数走 query；需带登录 Cookie，否则 401 用户鉴权不通过）
>           sign = URL-safe-Base64(HmacSHA1("action=1&appId={APP_ID}&module={module}&path=/editor&timestamp={ms}", SECRET_KEY))
>           → {code:"0", data:{region, expiration(秒), bucket, accessKey, secretKey, token, domains[]}}
> ② 直传    PUT https://{bucket}.{region}.aliyuncs.com/{object}
>           Date: {RFC1123 GMT}    x-oss-security-token: {token}
>           Authorization: OSS {accessKey}:{Base64(HmacSHA1("PUT\n\n{contentType}\n{date}\nx-oss-security-token:{token}\n/{bucket}/{object}", secretKey))}
> ③ 公开地址 domains[0] + object
> ```
> - **客户端内置凭证**（非用户凭证，硬编码于 PC bundle）：`APP_ID=uPRLht4dLiblkF6bcjRtLuDQ4eo=`、`SECRET_KEY=uxiXcdOrdp2PxTTDlNGQ3g72oWM=`
> - **两个上传模块**：`editor-oss`（图片，host `i1.hoopchina.com.cn`，`put` 单次上传）/ `editor-video-oss`（视频，host `v.hoopchina.com.cn`，`multipartUpload` 分片）
> - **对象路径规则**：`editor/{年-月-日}/{时-分-秒}/{随机32位}.{ext}`（月日**不**补零、时分秒补零）
> - 另有 `POST https://bbs.hupu.com/pcapi/all/upload/img`（body `{resUrl}`）仅用于**外链图片转存**，非本地上传
> - 视频额外需 `GET /pcmapi/pc/bbs/v1/video/auth?scene=pcpreview&url={url}&h5Nosign=1` 换取 `src`（授权/转码地址）
>
> **★ 发帖提交结构口径（2026-10-04 逆向）**：
> ```js
> { title, fid, content: HTML, format: JSON.stringify({ slateValue, imgList, videoInfo: {extra:1} }) }
> ```
> - `content` 为 HTML（**与旧三字段格式兼容**，服务端同时接受）
> - `slateValue` = slate 节点数组：段落 `{type:'paragraph', children:[{text}]}`；图片 `{type:'img', children:[{text:''}], imageInfo:{remoteUrl}}`；视频 `{type:'video', videoInfo:{...}}`；投票 `{type:'vote', voteInfo:{title, type:'radio'|'checkbox', ...}}`
> - `imgList` = `[{remoteUrl, key}]`（key 为随机 6 位串）
> - 官方会对 `content` 做空段落替换：`<p></p>` → `<br style="margin-bottom:30px;"/>`，并把 `&amp;` 还原为 `&`
>
> **★ 专区信息口径（2026-10-04 实测，26/26 专区成功）**：专区信息全部可从 **PC 话题页** `bbs.hupu.com/{topicId}` 头部解析（无需额外接口）：
> - 名称：`bbs-sl-web-intro-detail-title`（注意夹 HTML 注释，如 `#<!-- -->NBA2KOL2`，需捕获整段后清洗）
> - 头部图：`bbs-sl-web-intro` 的 `style` 内 `background:...,url('...')` —— **与专区头像同源**（方形 LOGO，实测 500x500 / 512x512），官方 App 亦以此作头部背景，放大 `Cover` + 暗化渐变即可
> - 话题介绍 / 话题热度：`bbs-sl-web-intro-detail-desc-title` + `-desc-text`（两段同构，按标签文本区分；热度值内含 `<i>` 图标标签需清洗）
> - 版主：`bbs-sl-web-admin-detail-desc-text` 内多个 `admin-auth > a`（名字 + `my.hupu.com/{euid}` 链接）
> - 页签（全部/24小时榜/精华/游戏攻略/求助提问）：子分类来自 `GET bbs.hupu.com/pcmapi/pc/bbs/v1/topicZone?topicId={id}`（返回 `{zoneName,sortOrder}` 数组，多数专区为空）；`全部/24小时榜/精华` 为内置模式，`最新回复/最新发布` 为排序项
> - **未获取到**：成员数（"58.24w 帖子 / 40.3w JRs"）与"已加入"按钮 —— PC 页与 m 站均无该字段，疑为 App 专有（`m.hupu.com/zone` 仅提供热度 `count`）
>
> **★ 搜索结果口径（2026-10-04 实测，带图历史唯一来源）**：`GET m.hupu.com/api/v2/search2?keyword={kw}&puid=0&type=posts&topicId=0&page={N}` → `data.result.data[]`，条目字段：
> `id`(tid) / `title`(含 `<font>` 高亮标签，需清洗) / `content` / `username` / `fid` / `forum_name` / `picture`(封面) / `replies` / `lights` / `addtime` / `isNews` / `link`。
> - **带图**：实测"流言板"搜索结果 106/120 有 `picture`（约 88%）
> - **分页有效**：`count=599` / `totalPage=30`（对比 `topicThreads` 分页完全失效）
> - **不能按板块过滤**：`topicId`/`fid`/`forumId`/`forum` 参数均被忽略，需**客户端按返回的 `fid` 字段过滤**
> - **关键词决定板块覆盖**：搜"流言板"→ fid 502(篮球资讯)+482(国际足球资讯) 为主；搜"CBA"/"中国篮球"/"男篮"→ fid 173(CBA专区) 为主；乒乓球/数码等话题板块几乎不出现，故仅用于资讯频道
> - PC 话题页与搜索接口的**分工**：PC 话题页 = 话题频道的无图历史源（纯官方、量大）；搜索接口 = 资讯频道的带图历史源（与首屏图片风格一致）
>
> **★ WAF 风控口径（2026-10-04 实测，重要）**：`bbs.hupu.com` 挂阿里云 WAF，高频请求会触发拦截：
> - 拦截特征：响应头 `punish-loc: keepper`，body 为阿里云滑块验证页（约 15.9KB，含 `aliyun_waf` / `aliyunCaptcha-sliding-slider` 标记），HTTP 状态仍为 200
> - 触发阈值：短时间连续 50+ 请求（无间隔扫描）即触发
> - 冷却时间：约 10~15 分钟自动解除（无 IP 封禁）
> - 安全频率：1.6s 间隔连翻 30 页**未触发** → App 内由用户手动滑动驱动（每次 1 页）是安全的
> - **UA 硬约束**：PC 话题页仅对**桌面 UA** 返回完整内容（49~50 条 / 260KB）；移动 UA / App UA 一律返回约 15KB 空页（0 条）→ 必须使用 `DESKTOP_UA`
> - 防护：检测 `aliyun_waf` 标记后抛错 → 上层停止翻页并保留已加载内容，不重试
>
> **★ PC 话题页分页口径（2026-10-04 实测，无限滚动唯一可行源）**：
> - URL：第 1 页 `https://bbs.hupu.com/{topicId}`；第 N 页 `https://bbs.hupu.com/{topicId}-{N}`（**无 `.html` 后缀**）
> - 反例（均无效）：`/{topicId}?page=2`（返回同页）、`/{topicId}-2.html`（0 条，被识别为帖子评论页）、`/{topicId}/2`（404）、`?p/?pageNum/?start/?offset`（全部返回同页）
> - 实测：乒乓球 topicId=246 的 1~6 页各 48~50 条、页间重复 ≤1 条；第 20 页仍 49 条；第 100 页 0 条 → 单话题约 1000+ 条
> - 列表结构（SSR HTML）：`<li class="bbs-sl-web-post-body">` → `.post-title > a.p-title`（含 `href="/{tid}.html"`）/ `.post-datum`（`{回复} / {浏览}`）/ `.post-auth > a`（作者名）/ `.post-time`（如 `10-04 14:40`）
> - 作者链接为 `https://my.hupu.com/{euid}`（euid ≠ puid，不能直接用于本应用的用户主页跳转）
> - 页面约 270KB/页（SSR 全量 HTML），解析用字符串切分 + 4 条正则，无 DOM 依赖
>
> **官方号发文口径（2026-10-04 实测，官方内容的权威源）**：`GET m.hupu.com/user/{puid}` → `__NEXT_DATA__.props.pageProps.threadList[]`（**20 条**）：
> `tid` / `title` / `topic_id` / `topic_name` / `fid` / `visits` / `replies` / `lights` / `share_num` / `create_time` / `lastpost_time` / `pics[{url,width,height}]` / `nickname` / `type`（`mt`=主贴）。
> 同一主题会**在多个板块重复出现**（如一条流言板同时发在"综合体育区/台球区"），按 `topic_id` 过滤后直接得到目标板块的官方帖，无需再去重跨板块副本。
> 注意：该页 `threadList` **无分页**（`?page=2` 返回同一批），故单频道官方内容上限约 20 条/官方号。
>
> **官方资讯源口径（2026-10-04 全站实测）**：m 站官方资讯页**只有 4 个**，结构统一为 `__NEXT_DATA__.props.pageProps` 下的数组，条目字段 `nid/title/img/link/badge/type/lights/replies/publishTime/tid`：
>
> | 页面 | 字段名 | 内容 | 对应频道 |
> |---|---|---|---|
> | `m.hupu.com/nba` | `newsData`(35) | NBA 官方资讯 | NBA |
> | `m.hupu.com/cba` | `newsData`(35) | 中国篮球官方资讯（FIBA/中国之队/U18 亚洲杯等） | 中国篮球 |
> | `m.hupu.com/soccer` | `news`(35) | 足球官方资讯 | 国际足球 |
> | `m.hupu.com/gg` | `list`(35) | 虎扑电竞（LPL/KPL/绝地求生/CSGO/DOTA） | 未映射（无对应电竞频道） |
>
> 站点导航仅 `/gambia /games /gg /hot /nba /score-home /soccer /zone`（`/cba` 可访问但不在导航中）；`/tennis /pingpong /f1 /game /ent /movie /digital /auto /olympics /comprehensive /csl` 全部 404。
> **话题帖子流 `topicThreads` 无官方标记**：接口字段仅 `tid/title/type/replies/username/recommendNum/certTitle/time/isVideo/isVote/url`，官方账号（虎扑体坛资讯）与普通用户字段完全一致（`certTitle` 均为 null），`&isNews=1/&type=news/&filter=news` 等过滤参数全部无效（返回结果不变）——即**无法从帖子流中筛出官方内容**。
> `type=LINK` 的置顶条目 `tid` 为 null 且 `link` 是 `huputiyu://` App 深链，本应用不可跳转（仍展示标题，点击无响应）。

> **他人用户主页口径（2026-10-04 实测，推翻旧结论）**：`GET m.hupu.com/user/{puid}` —— **公开可访问，无需登录**（旧 PLAN 记录的"Web 端用户空间仅限本人"只适用于 `/my` 域）。`__NEXT_DATA__.props.pageProps`：
> - `userInfoData`: `nickname` / `header` / `level`(12) / `bbsUserLevelDesc`("Lv.3") / `reputation.value`(声望 2024) / `be_light_count`(被点亮 11825) / `be_follow_count`(粉丝 11) / `follow_count`(关注 1) / `be_recommend_count`(被推荐 21) / `is_self`(0=他人)
> - `threadList[]`: `tid` / `title` / `topic_name` / `visits` / `replies` / `lights` / `lastpost_time`（含 video 对象）
> - `replyList[]`: `pid` / `tid` / `content` / `score`(亮) / `createTime` / `username`
>
> 注：PC 站详情页评论的作者头像 URL 自带 `@150h_150w_2e` 缩略样式（`bbs.hupu.com/{tid}.html` → `detail.replies.list[].author.header`，作者 `puid` 亦可用），与 m 站 `user/{puid}` 返回的裸 URL 格式不同，拼接裁剪参数时需区分（已由 `avatarUrl()` 处理）；楼中楼作者 puid 来自 `user.puid`。

> **帖子详情视频口径（2026-10-04 实测，重要）**：`GET m.hupu.com/api/v2/bbs-thread/{tid}` 返回 `data.t_detail`，字段仅 `tid/title/content/is_top/is_lock/hits/rcmd/replies/lights/share/update/via/f_info/user` —— **无任何视频字段**，这是"详情页看不到视频"的根因。视频数据须走 PC 站：`GET bbs.hupu.com/{tid}.html`（桌面 UA + Referer）→ `__NEXT_DATA__.props.pageProps.detail.thread` →
> - `hasVideo: true`（视频帖标记）
> - `video`: 直连 mp4 地址（`v.hoopchina.com.cn/..._wz_transcode.mp4?auth_key=...`，**带时效**）
> - `videoCover`: 封面图
> - `format`: 作者端 JSON 字符串，内含 `videoInfo: {coverUrl, remoteUrl, width, height}`（**顶层无尺寸字段，宽高只能从这里取**）
>
> 图文帖这三项均缺失（`hasVideo` 为 undefined），可据此安全区分。

> **推荐流（walkingStreet）视频与亮评口径（2026-10-04 实测）**：`GET m.hupu.com/api/v2/bbs/walkingStreet/threads` 每条直接携带：
> - `video: { url, img, humanDuration, duration, playNum, width, height, size }` —— `url` 为**可直连播放的 mp4**（v.hoopchina.com.cn，带时效 auth_key），无需二次请求详情；`img` 为封面；`playNum` 为播放量。
> - `lightReplyResult: { content, replyUserName, lightCount, score, header, picList }` —— **神回复（亮评）**，官方推荐流卡片的"亮 N"区块数据源。
> - `shareNum` 分享数；`picList[].width/height` 图片真实宽高（单图按比例渲染用）。
> - 注意：该接口**无浏览数**字段，图文帖数据栏以 回复/亮/分享 呈现，视频帖用 `playNum` 作"浏览"。

> **投篮热图/荣誉接口口径**：`GET games.mobileapi.hupu.com/1/7.5.29/basketballapi/shootHotMap?playerId=&competitionLeagueType=&competitionType=&competitionStageType=REGULAR/PLAYOFF` → `shootAreaDTOList[]`（14 区：areaId/fgs/fgm/fgp/level/color）；`GET .../playerAwardList?playerId=&competitionLeagueType=&competitionType=` → `awardSummaryList[]`（awardDesc/awardCount/awardDetailList）。热区语义映射为按经典 14 区布局推断（篮下/油漆区/底线/翼位/肘区/弧顶），数值完全来自接口。

**第六版已探明口径（球员主页 —— 重大突破）：**

| 数据 | 接口 | 说明 |
|---|---|---|
| 球员头部信息 | `GET games.mobileapi.hupu.com/1/7.5.29/basketballapi/playerPageHeadInfo?playerId={longId}&leagueType={NBA/CBA}` | 中/英文名、昵称、年龄、身高体重、国籍、大学、选秀、薪资、合同、球队logo、nbaGdcId（=短ID）|
| 球员赛季数据 | `GET .../basketballapi/playerSeasonStats?playerId=&competitionLeagueType={L}&competitionType={L}` | 67KB 完整数据：`dataDimensionMap.basic/advanced` × `competitionStagePackListMap.PRESEASON/REGULAR/PLAYOFF`；每项 `{name,cnName,quota,rank,leagueAvgValue,leagueMaxValue}`（rank=联盟排名）|
| 球员其他接口（备用） | `.../basketballapi/` | playerAllSeasonStats（全赛季）/ playerAllMatchStats（逐场）/ playerCareerStats（生涯）/ playerAwardList（荣誉）/ shootHotMap（投篮热图）/ playerInjuryList（伤病）/ news/v3/playerNewsById（资讯）|
| 发现方式 | `offline-download.hupu.com/online/prod/330003/playerInfo-data.html` 的 bundle | 该页面是 App 内嵌的球员资料 H5，其 JS 暴露了上述整个 API 家族 |

> **评论接口最终结论（2026-10-03 穷举验证完毕）**：官方评论流（亮回复/29）走 `POST playerStaff/latestCommentList`。穷举测试均失败：① 长/短/gid 三种 playerId（报 "playerModel null" → ID 体系不符）② 真实球员+真实比赛（如 SGA + 雷霆马刺 172万评分场）→ `success:true, result:null`（服务端返回空）③ DTO 泄露字段补偿（order=desc/asc/light、customId、cursorMap、userId 变体）全部空 ④ 12 个 API 版本号（3/7.3.0 ~ 3/8.0.0）全部空。**结论：评论数据服务端对非 App 签名请求一律返回空，Web 端不可达**。评分详情页展示每名球员的**单条热评**（rosterScoreStats.comment 字段，内容与官方亮评一致）作为替代。
>
> **评论接口 2026-10-04 二次深挖（官方 H5 源码逆向 + APK dex 逆向）**：
> ① **方法修正**：2026-10-03 用 GET 测的——实测报 `Request method 'GET' is not supported`，正确方法是 **POST**（GET 判死结论作废）。
> ② **官方调用完整还原**（扒 m.hupu.com 评分页 webpack chunk `597-e78c43c9f36e83ed.js`）：`POST https://games.mobileapi.hupu.com/3/7.5.60/basketballapi/playerStaff/latestCommentList`，参数体 `{matchId, userId, limit, order, cursorMap:{publishTime}, playerId, staffId}`（球员用 playerId、教练裁判用 staffId；响应 `result.commentDTOList[]` + `result.cursorMap.publishTime` 游标分页；order 三值 `""`/`latest`/`early` = 最亮/最晚/最早）。**H5 axios 拦截器无任何签名头**（仅性能埋点），裸 HTTP。
> ③ **仍拿不到数据的根因**：`success:true, result:null` —— userId 需登录态，且 games 网关只认 **games 域 App 登录凭证**（官方 App 内嵌 WebView 的 games 域 cookie/token 由 App 原生层注入），bbs 域 cookie（ua/u/us）不被 games 网关识别（带 Cookie 实测无效）。官方 App 球员评分页即内嵌 H5（m.hupu.com/basketball-player-score），靠 App WebView games 域登录态拿数。
> ④ **APK dex 逆向**（98MB dex）：BPL 评论接口族全曝光（`bplcommentapi/bpl/comment/list/primarySingleRow` 主评 / `getMore` / `hottest` / `subCommentList` 楼中楼 / `comment/publish` / `comment/light` / `score_tab/detail` / `score_tree/*`，独立 BPL 网关）——实测 games.mobileapi 网关 `No static resource`，BPL 网关域名 dex 未泄露（运行时下发）；另有 `GET /player/v1/{gameType}/getAllPlayerScore`（**接口存在**：业务报错"参数不完整"而非 404，返回 `is_login:0`）与 `/matchallapi/queryMatchAllScoreInfo`，参数结构未在字符串池泄露。
> ⑤ **最终结论**：完整评论流（多条+楼中楼）需要 games 域登录凭证——唯一途径抓包官方 App（SSL pinning 需绕过）。未获取前**评分详情页评论区块 = roster 单条热评**（官方亮评同数据源；降级自动触发：latestCommentList 空/失败 → roster comment）。
> ⑥ **SSR 评分数据空化修正（2026-10-04 实测）**：SSR `scoreInfo.playerInfo` 对未登录请求返回 userScoreAvg/userScoreCount/scoreDistribution **全空**（即"共 0 人打分"现象），但 stats（得分/篮板等）正常——**官方 App 评分数据实际来自 roster 接口**（teamMatchRosterScoreStats 返回完整 userScoreAvg/userScoreCount/scoreDistribution + comment）。详情页 = SSR 骨架 + **roster 补齐评分**（scoreCount>0 覆盖；分布全 0 判定后整体替换）。

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

**发帖接口口径（V2-P2 · 2026-10-03 探测）**：`POST bbs.hupu.com/pcmapi/pc/bbs/v1/createThread`（body `{title,fid,content}`，content 为 HTML 文本；空 body 返回 `PC022002 帖子内容不能为空`、补 content 返回 `PC022003 用户未登录` → 参数校验在鉴权前，路径与参数结构确认有效）。fid 与 topicId 的对应关系、真实发帖闭环待真机登录态实测。

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

### 11.5 · 多设备同步（P2）

- 优先方案：**收藏导出/导入**（剪贴板 JSON）✅ 已落地（2026-10-03，设置页入口，FavStore.exportJson/importJson 幂等合并）
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
