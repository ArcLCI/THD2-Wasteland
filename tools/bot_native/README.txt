THD 原生 Bot 静态配置与动态适配后续工作
版本：THD-NATIVE-BOT-KV-20261010-R2

一、当前源码

配置：scripts/npc/bot_heroes_custom.txt
入口：scripts/npc/npc_heroes_custom.txt 中的 #base 引用。
范围：specialmode.lua 当前注册的 72 个原版槽位，包括普通池禁用项。
不会因此开放禁用英雄，也不修改 Lua 技能、购买或分路实现。
古明地觉/Rubick 不在这 72 项注册表中，本轮未扩展其配置。

只配置 AggressionFactor 与 HeroType。七项 LaningInfo 不做适配，
14 维人工评分继续由 Lua 分路系统使用，不向原生七项转换。
未增加 Build、Loadout、SupportsEasyMode 或 BotImplemented。
这些旧字段在引擎合并后是否保留，仍需核对；没有用空块尝试删除旧表。

二、静态取值原则

AggressionFactor 采用 0.95、1.0、1.05 三档，小幅偏置不等同定位分档。
0.95：灵梦、梅蒂欣、莉莉卡、青娥、秋穰子，均为当前开放的单一辅助。
1.05：芳香，单一前排，恢复与常驻伤害延迟支持站场。
其他66名为1.0；多定位和强依赖技能状态者保持中性，不因默认profile
或TANK标签直接提高。美铃因多定位、华扇因形态、莉莉白因黑白状态
均保持1.0。禁用英雄本轮不微调，HeroType也不改变。
原版魔理沙槽位 Crystal Maiden、蕾米利亚槽位 Warlock 的显式 0.8
也改为本基线 1.0；这是基础配置变化，不代表其行为已经验收。
该系数同时参与 Attack 目标评分和 Retreat 的附近战力差分项。
实际 getter 可能有槽位专属乘法，1.0 不意味着最终系数永远为 1.0。

HeroType 只使用固定 7.38 已识别的七个 DOTA_BOT_* 标签：
TANK、STUN_SUPPORT、PURE_SUPPORT、PUSH_SUPPORT、HARD_CARRY、
SEMI_CARRY、GANKER。不使用 NUKER 或 SUPPORT 这两个未识别标签。
每条源码注释说明选择依据；技能/KV 与当前 Bot 路线优先，Wiki 定位
只是参考。选人池中的 frontline 可能表示先手，不机械映射为 TANK。
角色标签不是模式欲望倍率，也不是强制仇恨或攻击优先级开关。

多 profile 的静态取舍：
- 椛、桑尼、幽香使用已登记的默认前排构筑基线。
- 荷取使用已登记的默认 damage 构筑，不能声称 support 已动态适配。
- 萃香保留前排与普攻战士共性，普通池仍禁用。
- 探女仅按当前开放的 damage 处理，保留的辅助实现不并入类型。
- 帕秋莉、白莲依据当前共用的技能/购买链，而非三个选人池的标签并集。
这是一份可审核的静态基线，不是逐场状态的完整表达。

三、后续动态适配是必做项

本轮追加的固定版本证据、候选接口和阶段方案见同目录 DYNAMIC_DESIGN.txt。

当前没有实现动态桥接或修改引擎。后续至少需要覆盖：
1. profile 差异：物理输出、前排、辅助的实际战术与目标价值。
2. 状态窗口：技能前摇、持续施法、变身、爆发、保护/免伤和恢复阶段。
3. 原版特化：例如 Luna 的原版 Eclipse modifier 会使其 getter 加乘；
   必须防止新动态系数与旧特化重复叠加或错用不存在的原版技能状态。
4. 双侧影响：调进攻系数必须同时检查 Attack 与 Retreat，不能只观察
   其中一个 desire。HeroType 的目标侧价值变化也需单独评估。
5. 动作所有权：动态状态不能打断已保护的施法、传送、逃生或物品确认。

路线需要另行确定：
A. 经确认的原生读写桥接，让原生 Attack/Retreat 消费动态状态；或
B. 在明确的 Lua 决策范围内处理状态，不能伪称改到了原生私有系数。
仅新增 Lua modifier、修改 Lua 表或复用原版 modifier 名称，都不能
直接算作通用动态适配。不要为所有英雄伪造 modifier_luna_eclipse。
若使用 modifier BotAttackScoreBonus，也要先确认其作用方向和接口；
目标评分加分不能当作自身 AggressionFactor 的替代品。

四、接入与验收边界

静态R2与只读观测工具已于2026-10-10授权同步生产并核对哈希。
没有启动Dota或取得实机getter样本，没有进行运行时注入，没有修改
server.dll或Metamod核心，没有创建/运行自动化行为测试。

后续先在用户启动的新局中核对原版槽位的最终 Bot 子树及初始化值，
再观察候选目标、模式 desire、实际动作、位置与结果。
缺块样本可用 Larva/Dark Willow；有块样本可用 Cirno/Axe。
Larva 的样本选取不等于授权开放普通随机池。
静态可解析、源码哈希或 Lua LoadKeyValues 读到配置都不能替代原生
Bot 对象确实读取了配置的证据，更不能替代行为验收。

固定参考引擎 server.dll SHA-256：
254bee29e9d60998c66cc6700dcaff0f0d4be692f092c20b59a2ae19fa227058
研发字段说明见聚合工作区 .codex/skills/develop-thd-hero-bots/references/
native-bot-kv-738.md；如与本文件范围不同，以当前任务要求为准。

五、只读观测工具准备

observer/README.txt 说明已准备的静态加载与getter观测工具。
它以默认关闭的独立插件记录自然调用的原始返回值，并配合手动游戏侧
KV快照。没有系数或角色字段setter，没有启用动态调整。观测工具已
于2026-10-10授权部署生产并设为Enabled=1，仍待用户冷启动新局。
开启观测会安装透传虚表钩子；“只读”指不改AI字段和业务返回值，
不是对进程内存零写入。部署已完成；加载与实际读数仍须用户新局确认。
