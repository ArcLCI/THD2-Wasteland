#pragma once

// R2统一合并英雄与装备状态，不写Bot字段、不调用技能。
// 原版增益与自定义候选取较大值；原版削弱保留，避免盲乘或抹掉原生限制。
namespace dynamic_policy {
using n2_platform::read;
inline unsigned mode{}; // 冷启动配置：0关闭，1影子读数，2应用。
inline constexpr float teethMultiplier = 1.30f;
inline float mergeIndependent(float a, float b) {
    // 最强增幅全计，第二个独立来源增幅计半；英雄明确组合另行覆盖。
    const float result = a >= b ? a + (b - 1.0f) * 0.5f : b + (a - 1.0f) * 0.5f;
    return result > 1.60f ? 1.60f : result;
}
inline bool failed{}, levelActive{};
struct Variant { double value{}; unsigned char type{}, unused{}; std::uint16_t flags{}; std::uint32_t padding{}; };
static_assert(sizeof(Variant) == 16 && offsetof(Variant, type) == 8);
using Context = Variant*(*)(void*, Variant*, const char*);
inline constexpr std::uintptr_t contextRva = 0x1815730;
inline constexpr std::array<unsigned char,16> contextBytes{0x48,0x89,0x5c,0x24,0x08,0x48,0x89,0x6c,0x24,0x10,0x48,0x89,0x74,0x24,0x18,0x57};
struct Lease {
    std::uint32_t handle{};
    std::uintptr_t entity{};
    std::uint32_t sequence{}, state{};
    ULONGLONG changedAt{}, nextRead{};
    bool primed{}, fresh{};
};
inline std::array<Lease, 64> leases{};
inline std::size_t nextLease{};
struct Decision {
    float wanted{}, returned{};
    bool candidate{}, valid{}, applied{};
    const char* reason{"off"};
    float customMultiplier{1.0f};
    std::uint32_t state{};
};
inline void reset(bool active) { leases = {}; nextLease = 0; levelActive = active; }

// 已离线核对隐藏返回缓冲ABI；GetContext的数值返回是FIELD_FLOAT64(34)，无分配所有权。
// SEH仅包住新增读取，失败时保留已经执行一次的原getter结果。
inline bool contextValue(std::uintptr_t server, std::uintptr_t entity, Variant* result) noexcept {
    __try {
        return reinterpret_cast<Context>(server + contextRva)(reinterpret_cast<void*>(entity), result,
            "thd_native_policy_r2") == result;
    } __except(EXCEPTION_EXECUTE_HANDLER) { return false; }
}
inline Decision evaluate(std::uintptr_t server, std::uintptr_t entity, std::uint32_t handle,
    const std::string& name, std::uintptr_t getter, float base, float original, ULONGLONG now) {
    Decision d{original, original};
    if (!mode || !levelActive) return d;
    if (failed) { d.reason = "context_fault_latched"; return d; }
    const signatures::Expected* expected = nullptr;
    for (const auto& item : signatures::expected) if (name == item.slot) { expected = &item; break; }
    if (!expected) { d.reason = "unregistered_hero"; return d; }
    d.candidate = true;
    bool knownGetter = false;
    for (const auto& item : signatures::getters) if (item.rva == getter) knownGetter = true;
    if (!knownGetter || !std::isfinite(base) || base <= 0 || std::fabs(base - expected->base) > 0.00001f
        || !std::isfinite(original) || original <= 0) {
        d.reason = "baseline_or_getter_mismatch"; return d;
    }
    Lease* lease = nullptr;
    for (auto& item : leases) if (item.entity == entity && item.handle == handle) { lease = &item; break; }
    if (!lease) { lease = &leases[nextLease++ % leases.size()]; *lease = {}; lease->entity = entity; lease->handle = handle; }
    if (now >= lease->nextRead) {
        lease->nextRead = now + 50;
        Variant value{};
        if (!contextValue(server, entity, &value)) { failed = true; d.reason = "context_read_fault"; return d; }
        if (value.type != 34 || value.flags || !std::isfinite(value.value) || value.value < 16
            || value.value > 16000015 || std::floor(value.value) != value.value) {
            lease->primed = lease->fresh = false; d.reason = "missing_or_invalid_context"; return d;
        }
        const auto packed = static_cast<std::uint32_t>(value.value);
        const auto seq = packed / 16, state = packed % 16;
        const auto allowed = name == "npc_dota_hero_chaos_knight" ? 9u
            : name == "npc_dota_hero_gyrocopter" ? 14u : 8u;
        if (state & ~allowed) { lease->primed = lease->fresh = false; d.reason = "invalid_state_for_hero"; return d; }
        if (!lease->primed || seq < lease->sequence) {
            lease->primed = true; lease->fresh = false; lease->changedAt = now;
        } else if (seq != lease->sequence) {
            // 首次遇到旧context不授予租约；必须看到推进中的心跳。长时间断流同样重新预热。
            lease->fresh = now - lease->changedAt <= 600;
            lease->changedAt = now;
        }
        lease->sequence = seq; lease->state = state;
    }
    if (!lease->primed || !lease->fresh || now - lease->changedAt > 600) { d.reason = "heartbeat_unconfirmed_or_expired"; return d; }
    d.valid = true;
    d.state = lease->state;
    const bool teeth = (d.state & 8u) != 0;
    // 乳牙是独立装备来源；只计一次，不把沉默、吸血等子modifier另算一份。
    d.customMultiplier = teeth ? teethMultiplier : 1.0f;
    d.reason = teeth ? "teeth" : "static_state";
    if (name == "npc_dota_hero_gyrocopter") {
        // E/R/乳牙位依次为2/4/8；明确组合覆盖单项，绝不再次相乘。
        constexpr float tei[] = {1.0f, 1.20f, 1.25f, 1.35f, teethMultiplier, 1.40f, 1.40f, 1.50f};
        constexpr const char* reasons[] = {"static_state", "tei_e", "tei_r", "tei_e_r",
            "teeth", "tei_e_teeth", "tei_r_teeth", "tei_e_r_teeth"};
        d.customMultiplier = tei[d.state >> 1];
        d.reason = reasons[d.state >> 1];
    } else if (name == "npc_dota_hero_chaos_knight" && (d.state & 1u)) {
        // 普通独立来源递减合并：最强增幅全计，其余增幅计一半。
        d.customMultiplier = teeth ? mergeIndependent(1.20f, teethMultiplier) : 1.20f;
        d.reason = teeth ? "mokou_ultimate_teeth" : "mokou_ultimate_healthy";
    }
    if (d.customMultiplier > 1.60f) d.customMultiplier = 1.60f;
    if (d.customMultiplier <= 1.0f) return d;
    if (original < base - 0.00001f) { d.reason = "native_penalty_preserved"; return d; }
    // 不推断原版加成来源：重合时只取较大结果，也不裁掉原版高于自定义上限的结果。
    const float custom = base * d.customMultiplier;
    d.wanted = original > custom ? original : custom;
    if (original >= custom) d.reason = "native_bonus_dominates";
    d.applied = mode == 2 && d.wanted > original + 0.00001f;
    if (mode == 2) d.returned = d.wanted;
    return d;
}
}
