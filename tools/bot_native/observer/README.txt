2026-10-10 R3插件 / 动态试点R2：妹红、因幡帝及独立通用乳牙规则已准备。
当前实现和部署说明以POLICY_README.txt为准；新构建目录为bot-native-dynamic-20261010-r2。
生产仍为旧只读观测，候选包未部署。下文较早阶段说明保留作背景。

2026-10-10 R2补充：源码已加入妹红动态试点，见 POLICY_README.txt。
Mode=0为原观测；Mode=1只记录候选；Mode=2会改变Attack/Retreat的getter返回值。
旧生产仍是R1观测。本文件的原样透传说明适用于Mode=0/1，不能套用于Mode=2。
新构建在 artifacts/bot-native-dynamic-20261010-r1/build，不覆盖旧R1构建。
客户端cfg的say入口未通过实机；手动快照请用玩家聊天框输入 -botkv。

THD 静态加载与进攻系数getter只读观测 R1
日期：2026-10-10
状态：2026-10-10已授权部署生产，观测Enabled=1；未启动游戏，未采集实机样本。
离线包仍保留准备阶段的关闭默认，生产部署状态以回滚清单为准。

一、要分别核对的层次

1. Addon源声明：游戏侧LoadKeyValues读取bot_heroes_custom.txt。
2. 引擎单位KV：GetUnitKeyValuesByName读取原版槽位对应的引擎表副本。
3. Bot对象字段：基础系数+0xac、HeroType位+0xa8。
4. 实际getter结果：原生Attack/Retreat自然调用英雄slot4时的原返回值。

前三者一致才能支持配置/初始化一致；第四层允许因原版特化而不同。
这不等于行为改善验收。GetUnitKeyValuesByName读到某值也不能代替Bot字段。
本轮已同时部署R2和观测工具。若以后只装观察工具而不部署对应配置，
它应显示旧运行配置；
不能把“与源码不同”误报为R2加载失败，也不能暗中同步R2来消除差异。

二、只读含义与限制

插件不写Bot参数、角色位、modifier、KV、目标或模式，不下达任何动作，
也不主动调用进攻getter。它只透传引擎本来就会发生的调用，恰好调用
原函数一次，并原样返回float；记录失败时仍透传，不伪造返回值。

取得真实返回值需要观测钩子：启用时改写51个英雄类虚表的slot4指针。
所以它是“只读AI字段/不改业务返回值”，不是“对进程内存零写入”。
冷启动前核对server.dll SHA、12个getter原始字节、51个原虚表指针及
单位名称字段的getter字节；冲突时拒绝安装，不覆盖其他钩子。
禁止热加载。已装钩子时禁止热卸载；完全退出进程后才能移除。

默认VDF后缀为.vdf.disabled，且INI的Enabled=0，双重关闭。
R2新增BotNativePolicy.Mode，默认0；动态试点说明以POLICY_README.txt为准。只捕获Attack和Retreat两个
已核对调用点；RecordOtherConsumers默认0。输出上限100000条。
每个Bot完整句柄/消费者默认最多约每500ms采样一次；短窗口可能漏采。
原函数没有自然执行就没有实际值，工具不会为了补覆盖主动求值。
原版getter自身若有缺陷，本工具不会把该缺陷修复或吞掉。

三、文件

observer.cpp                  原生透传观测插件
signature_layout.json         固定版本51类虚表与12个getter入口
prepare_signatures.py          从匹配DLL和当前R2配置生成签名/期望值
signatures.hpp                唯一由prepare_signatures.py生成
expected-kv.json               与编译插件配套的72槽位期望值及源SHA
scripts/vscripts/util/thd_bot_native_snapshot.lua 为游戏侧快照源码；
kv_snapshot.lua               工具目录的导出镜像，不自动执行、不注册Think
analyze.py                     仅分析已有日志，不连接或控制游戏
Build.cmd                     只编译到聚合工作区artifacts目录
thd_bot_native_observer.ini    默认关闭
thd_bot_native_observer.vdf.disabled  默认不被Metamod发现

共享编译依赖为工作区已有的Metamod SDK和engine_platform.hpp。
Build.cmd应从本仓库的tools/bot_native/observer位置运行；离线包source目录
只是源码副本，不是带齐共享SDK的可独立构建工程。
运行需要匹配7.38的兼容Metamod核心，本包不替换或安装核心。
编译通过不代表插件已加载、字段偏移在实机完成验收或观测开销已接受。

四、已部署后的手动操作（游戏由用户启动）

当前没有自动启动入口。本轮保留已有插件与Metamod核心，追加现有
metaplugins.ini注册观察插件，INI设为Enabled=1；没有安装活动VDF，
不要重复通过VDF注册同一个插件。npc_heroes_custom.txt仅同步新增引用。
部署清单：聚合工作区 artifacts/bot-native-deploy-20261010-210048/manifest.json。

本轮运行路径：
  game/dota/addons/thd_bot_native_observer/bin/win64/thd_bot_native_observer.dll
  game/dota/addons/metamod/metaplugins.ini（追加一行）
  game/dota/cfg/thd_bot_native_observer.ini
  game/dota_addons/THI/scripts/vscripts/util/thd_bot_native_snapshot.lua

旧R1观测已在用户新局中取得实机读数。快照请由房主在游戏聊天中输入：
  -botkv initial
在目标技能状态自然出现期间，可再次输入：
  -botkv state_window
2026-10-10入口修复：cfg使用say发送只读聊天请求，addon_game_mode.lua
负责房主校验与调用。修复需要下一次服务端游戏脚本初始化；不要在当前
已加载旧脚本的对局中强制热重载。客户端不再使用script控制台命令。
它不施放技能、不选择英雄、不切换profile，也不访问Bot侧隐藏敌人数据。

原生日志：game/dota/log/thd_bot_native_observer_<PID>.jsonl
游戏侧输出：[THDNativeKV]开头的JSON，保存到同局console日志。
初始化后第一次自然调用即可有基础值；不要求人为调用未知getter。
只有installed记录而没有getter_sample不能算观测成功。

后续手动结束记录可将已加载插件的Enabled设回0；钩子仍透传，直到
完全退出Dota后才可移除。若插件冷启动时未启用，运行中改成1不会安装
钩子，需要重新冷启动，避免隐式热安装。

五、离线报告

使用包中与该DLL配套的expected-kv.json，不用后来修改过的源期望值。
  python -B analyze.py --native <native.jsonl> --kv-log <console.txt>
      --expected <expected-kv.json> --snapshot <快照ID> --out <报告目录>

快照ID位于kv_begin/kv_end中；只有一个完整快照时可以省略--snapshot。
多个进程、重复槽位、未闭合快照或期望清单不一致会拒绝混合解释。
KV按名称对照，不证明与getter在同帧；使用者必须确认两份日志属于
同一个服务端进程/对局。每个level_epoch和完整owner_handle单独统计，
避免把实体索引复用或跨图样本直接混合。输出保留源日志行号。

报告同时展示源声明、引擎声明、对象基础值、实际值和实际/基础比值。
缺值保持未知，不填默认1.0；没有采样的72槽位不算失败或通过。
观察到倍率也不能仅凭比值断言具体modifier原因。

六、验收边界

本轮可完成：编译、字段/签名/清单静态核对、打包哈希。
本轮已完成：生产文件同步及哈希核对。
本轮未做：运行时进程注入/加载、Dota启动、自动化行为测试。
后续用户新局检查：正确进程/地图、实际getter样本、源码与引擎配置及
对象字段对照、特殊状态前后读数、无新Lua错误/崩溃及可接受的观测开销。
日志对齐和哈希不是实机行为成功的替代品。
