// 自然getter观测与可选妹红动态试点：默认透传；Mode=2才改返回值，不写AI字段。
#include "engine_platform.hpp"
#include <atomic>
#include <cmath>
#include <iomanip>
#include <mutex>
#include <utility>
#include <intrin.h>
#include "signatures.hpp"
#include "dynamic_policy.hpp"
#pragma warning(push)
#pragma warning(disable:4100 4245)
#include "ISmmPlugin.h"
#pragma warning(pop)

namespace observer {
using Getter = float(*)(void*);
using n2_platform::read;
using n2_platform::json;
constexpr char run[] = "THD-BOT-KV-OBSERVE-20261010-R1";
constexpr std::uint64_t maxRecords = 100000;
std::uintptr_t server{};
std::array<Getter, std::size(signatures::getters)> originals{};
std::mutex observationMutex;
std::ofstream output;
std::wstring configPath;
std::atomic<bool> collecting{false};
std::atomic<bool> healthy{true};
std::atomic<DWORD> callbackThread{};
std::atomic<std::uint64_t> calls{}, skippedLocks{}, skippedThreads{}, readFaults{};
std::uint64_t records{}, samples{}, epoch{}, serial{};
ULONGLONG nextPoll{}, nextFlush{};
unsigned intervalMs{500};
bool installed{}, recordOther{};
std::array<bool, std::size(signatures::classes)> changedSlots{};
thread_local unsigned depth{};
struct Rate {
    std::uintptr_t bot{};
    std::uint32_t handle{};
    unsigned consumer{};
    ULONGLONG next{};
};
std::array<Rate, 256> rates{};
std::size_t nextRate{};

void log(const char* event, const std::string& fields = {}) {
    if (!output || records >= maxRecords) return;
    output << "{\"run\":" << json(run) << ",\"event\":" << json(event)
        << ",\"pid\":" << GetCurrentProcessId() << ",\"tick_ms\":" << GetTickCount64()
        << ",\"level_epoch\":" << epoch << ",\"sequence\":" << ++serial << fields << "}\n";
    ++records;
    if (!output.good()) { collecting = false; healthy = false; }
}
std::string counters() {
    return ",\"getter_calls\":" + std::to_string(calls.load())
        + ",\"samples\":" + std::to_string(samples)
        + ",\"lock_skipped\":" + std::to_string(skippedLocks.load())
        + ",\"wrong_thread_skipped\":" + std::to_string(skippedThreads.load())
        + ",\"read_faults\":" + std::to_string(readFaults.load())
        + ",\"policy_mode\":" + std::to_string(dynamic_policy::mode)
        + ",\"policy_fault_latched\":" + (dynamic_policy::failed ? "true" : "false")
        + ",\"ai_field_writes\":0,\"actions\":0,\"extra_aggression_getter_calls\":0";
}
std::string number(float value) {
    if (!std::isfinite(value)) return "null";
    std::ostringstream s; s << std::setprecision(9) << value; return s.str();
}
std::string boundedName(std::uintptr_t address) {
    if (!address) return {};
    std::string result;
    for (std::size_t i = 0; i < 128; ++i) {
        const auto ch = read<unsigned char>(address + i);
        if (!ch) return result;
        if (ch < 32 || ch > 126) return {};
        result += static_cast<char>(ch);
    }
    return {};
}
bool active(ULONGLONG now) {
    if (!healthy || records >= maxRecords) return false;
    if (now >= nextPoll) {
        nextPoll = now + 1000;
        const bool enabled = GetPrivateProfileIntW(L"BotNativeObserver", L"Enabled", 0, configPath.c_str()) == 1;
        if (enabled != collecting.load()) { collecting = enabled; log(enabled ? "observation_enabled" : "observation_disabled"); }
    }
    if (now >= nextFlush) {
        nextFlush = now + 5000;
        log("summary", counters()); output.flush();
        if (!output.good()) { collecting = false; healthy = false; }
    }
    return collecting && healthy;
}
float capture(void* self, std::size_t getterIndex, std::uintptr_t caller, float actual) noexcept {
    if (!healthy) return actual;
    const auto callerRva = caller >= server && caller < server + signatures::imageSize ? caller - server : 0;
    const unsigned consumer = callerRva == 0x1e03cca ? 1u : callerRva == 0x1e577b0 ? 2u : 0u;
    if (!consumer && !recordOther) return actual;
    std::unique_lock lock(observationMutex, std::try_to_lock);
    if (!lock.owns_lock()) { ++skippedLocks; return actual; }
    DWORD empty = 0;
    callbackThread.compare_exchange_strong(empty, GetCurrentThreadId());
    if (callbackThread.load() != GetCurrentThreadId()) { ++skippedThreads; return actual; }
    try {
        const auto now = GetTickCount64();
        if (!active(now)) return actual;
        const auto bot = reinterpret_cast<std::uintptr_t>(self);
        const auto handle = read<std::uint32_t>(bot + 0x9c);
        if (handle == 0xffffffffu || handle == 0xfffffffeu) return actual;
        // 关闭动态时保留R1早期限流；启用时先更新租约再对日志限流。
        for (const auto& rate : rates)
            if (rate.bot == bot && rate.handle == handle && rate.consumer == consumer && now < rate.next
                && !dynamic_policy::mode) return actual;

        const auto vt = read<std::uintptr_t>(bot);
        const signatures::HeroClass* type = nullptr;
        for (const auto& item : signatures::classes)
            if (vt == server + item.vtable && item.getter == getterIndex) { type = &item; break; }
        if (!type) { ++readFaults; return actual; }

        // 固定版本的完整句柄校验与实体反向Bot指针校验，防止实体索引复用。
        const auto list = read<std::uintptr_t>(server + 0x41fbdc0);
        if (!list) return actual;
        const auto index = handle & 0x7fffu;
        const auto chunk = read<std::uintptr_t>(list + (index >> 9) * sizeof(std::uintptr_t));
        if (!chunk) return actual;
        const auto entry = chunk + (index & 0x1ffu) * 0x78;
        if (read<std::uint32_t>(entry + 0x10) != handle) return actual;
        const auto entity = read<std::uintptr_t>(entry);
        if (!entity || read<unsigned char>(entity + 0x2f1) != 3 || read<std::uintptr_t>(entity + 0xa40) != bot) return actual;

        const auto base = read<float>(bot + 0xac);
        const auto mask = read<std::uint32_t>(bot + 0xa8);
        // 与初始化所用的unit-name getter相同字段；不额外调用游戏函数。
        const auto name = boundedName(read<std::uintptr_t>(entity + 0x1318));
        if (read<std::uint32_t>(entry + 0x10) != handle || read<std::uintptr_t>(entity + 0xa40) != bot) return actual;
        const auto policy = dynamic_policy::evaluate(server, entity, handle, name,
            signatures::getters[getterIndex].rva, base, actual, now);
        if (read<std::uint32_t>(entry + 0x10) != handle || read<std::uintptr_t>(entity + 0xa40) != bot) return actual;
        const float returned = consumer ? policy.returned : actual;
        for (const auto& rate : rates)
            if (rate.bot == bot && rate.handle == handle && rate.consumer == consumer && now < rate.next) return returned;
        rates[nextRate++ % rates.size()] = {bot, handle, consumer, now + intervalMs};
        const signatures::Expected* expected = nullptr;
        for (const auto& item : signatures::expected) if (name == item.slot) { expected = &item; break; }
        std::uint32_t baseBits{}, actualBits{};
        std::memcpy(&baseBits, &base, sizeof(baseBits)); std::memcpy(&actualBits, &returned, sizeof(actualBits));
        const auto ratio = std::isfinite(base) && base > 0 && std::isfinite(returned) ? returned / base : NAN;
        std::string fields = ",\"consumer\":" + json(consumer == 1 ? "attack" : consumer == 2 ? "retreat" : "other")
            + ",\"caller_rva\":" + json(n2_platform::ptr(callerRva))
            + ",\"bot\":" + json(n2_platform::ptr(bot)) + ",\"owner_handle\":" + std::to_string(handle)
            + ",\"entity_index\":" + std::to_string(index) + ",\"unit_kv_name\":" + json(name)
            + ",\"hero_class\":" + json(type->name) + ",\"getter_rva\":" + json(n2_platform::ptr(signatures::getters[getterIndex].rva))
            + ",\"base_after_call\":" + number(base) + ",\"effective\":" + number(returned)
            + ",\"base_bits\":" + std::to_string(baseBits) + ",\"effective_bits\":" + std::to_string(actualBits)
            + ",\"native_hero_type_mask\":" + std::to_string(mask) + ",\"effective_over_base\":" + number(ratio)
            + ",\"expected_source_sha256\":" + json(signatures::sourceSha)
            + ",\"expected_base\":" + (expected ? number(expected->base) : "null")
            + ",\"expected_mask\":" + (expected ? std::to_string(expected->mask) : "null")
            + ",\"base_matches_source\":" + (expected ? (std::isfinite(base) && std::fabs(base - expected->base) < 0.00001f ? "true" : "false") : "null")
            + ",\"mask_matches_source\":" + (expected ? (mask == expected->mask ? "true" : "false") : "null");
        fields += ",\"original_effective\":" + number(actual)
            + ",\"policy_mode\":" + std::to_string(dynamic_policy::mode)
            + ",\"policy_candidate\":" + (policy.candidate ? "true" : "false")
            + ",\"policy_valid\":" + (policy.valid ? "true" : "false")
            + ",\"policy_applied\":" + (consumer && policy.applied ? "true" : "false")
            + ",\"policy_wanted\":" + number(policy.wanted)
            + ",\"policy_reason\":" + json(policy.reason)
            + ",\"policy_state\":" + std::to_string(policy.state)
            + ",\"policy_custom_multiplier\":" + number(policy.customMultiplier);
        ++samples; log("getter_sample", fields);
        return returned;
    } catch (...) {
        ++readFaults; healthy = false; collecting = false; dynamic_policy::failed = true;
        try { log("observer_fault_pass_through", counters()); output.flush(); } catch (...) {}
    }
    return actual;
}

template<std::size_t Index> __declspec(noinline) float passthrough(void* self) {
    const auto caller = reinterpret_cast<std::uintptr_t>(_ReturnAddress());
    ++calls;
    struct Depth { Depth() { ++depth; } ~Depth() { --depth; } } guard;
    // 恰好调用原getter一次取得原值；只在明确的Mode=2试点条件下替换返回，不改参数。
    const float actual = originals[Index](self);
    if (depth == 1) return capture(self, Index, caller, actual);
    return actual;
}
template<std::size_t... I> auto replacements(std::index_sequence<I...>) {
    return std::array<Getter, sizeof...(I)>{&passthrough<I>...};
}
const auto hooks = replacements(std::make_index_sequence<std::size(signatures::getters)>{});

struct ExchangeResult { bool exchanged; bool protectionRestored; };
ExchangeResult exchangeSlot(std::uintptr_t address, void* wanted, void* expected) noexcept {
    DWORD old{};
    if (!VirtualProtect(reinterpret_cast<void*>(address), sizeof(void*), PAGE_READWRITE, &old)) return {false, true};
    const auto before = InterlockedCompareExchangePointer(reinterpret_cast<void* volatile*>(address), wanted, expected);
    DWORD ignored{};
    const bool protectedAgain = VirtualProtect(reinterpret_cast<void*>(address), sizeof(void*), old, &ignored) != 0;
    if (!protectedAgain) healthy = false;
    return {before == expected, protectedAgain};
}
void install() {
    server = reinterpret_cast<std::uintptr_t>(n2_platform::module(L"server.dll", n2_platform::serverSha));
    for (std::size_t i = 0; i < std::size(signatures::getters); ++i) {
        const auto& g = signatures::getters[i];
        if (read<std::array<unsigned char,16>>(server + g.rva) != g.bytes) throw std::runtime_error("getter_bytes_conflict");
        originals[i] = reinterpret_cast<Getter>(server + g.rva);
    }
    // 先核对全部虚表，再安装；不覆盖第三方已改写的slot。
    for (const auto& item : signatures::classes)
        if (read<Getter>(server + item.vtable + 4 * sizeof(void*)) != originals[item.getter]) throw std::runtime_error("vtable_conflict");
    const std::array<unsigned char,7> nameGuard{0x48,0x8b,0x91,0x18,0x13,0,0};
    if (read<std::array<unsigned char,7>>(server + 0x774710) != nameGuard) throw std::runtime_error("unit_name_layout_conflict");
    if (dynamic_policy::mode && read<std::array<unsigned char,16>>(server + dynamic_policy::contextRva) != dynamic_policy::contextBytes)
        throw std::runtime_error("context_getter_bytes_conflict");
    HMODULE pin{};
    if (!GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_PIN,
        reinterpret_cast<LPCWSTR>(&install), &pin)) throw std::runtime_error("module_pin_failed");
    for (std::size_t i = 0; i < std::size(signatures::classes); ++i) {
        const auto& item = signatures::classes[i];
        const auto address = server + item.vtable + 4 * sizeof(void*);
        // CAS结果直接记录实际改写；即使恢复页保护失败也不能漏掉回滚项。
        const auto result = exchangeSlot(address, reinterpret_cast<void*>(hooks[item.getter]), reinterpret_cast<void*>(originals[item.getter]));
        changedSlots[i] = result.exchanged;
        installed = installed || changedSlots[i];
        if (!result.exchanged || !result.protectionRestored) {
            for (std::size_t j = i + 1; j-- > 0;) if (changedSlots[j]) {
                const auto& prior = signatures::classes[j];
                const auto restored = exchangeSlot(server + prior.vtable + 4 * sizeof(void*), reinterpret_cast<void*>(originals[prior.getter]), reinterpret_cast<void*>(hooks[prior.getter]));
                if (restored.exchanged) changedSlots[j] = false;
            }
            installed = false;
            for (bool changed : changedSlots) installed = installed || changed;
            throw std::runtime_error("hook_install_failed");
        }
    }
    log("installed", ",\"class_slots\":51,\"getter_implementations\":12,\"observer_enabled\":true,\"ai_field_writes\":0,\"actions\":0");
    output.flush();
}

class Plugin final : public SourceMM::ISmmPlugin, public SourceMM::IMetamodListener {
public:
    bool Load(SourceMM::PluginId, SourceMM::ISmmAPI* api, char* error, size_t size, bool late) override {
        try {
            if (late) throw std::runtime_error("cold_start_only");
            if (api->GetSourceEngineBuild() != SOURCE_ENGINE_DOTA) throw std::runtime_error("dota_only");
            HMODULE own{};
            if (!GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                reinterpret_cast<LPCWSTR>(&install), &own)) throw std::runtime_error("own_module");
            std::array<wchar_t,32768> path{};
            if (!GetModuleFileNameW(own, path.data(), static_cast<DWORD>(path.size()))) throw std::runtime_error("own_path");
            auto root = std::filesystem::path(path.data()).parent_path();
            for (int i = 0; i < 4; ++i) root = root.parent_path();
            if (root.filename() != L"dota") throw std::runtime_error("unexpected_plugin_layout");
            configPath = (root / L"cfg/thd_bot_native_observer.ini").wstring();
            const bool armed = GetPrivateProfileIntW(L"BotNativeObserver", L"Enabled", 0, configPath.c_str()) == 1;
            std::filesystem::create_directories(root / L"log");
            output.open(root / (L"log/thd_bot_native_observer_" + std::to_wstring(GetCurrentProcessId()) + L".jsonl"), std::ios::app | std::ios::binary);
            if (!output) throw std::runtime_error("log_open");
            log("load", ",\"armed\":" + std::string(armed ? "true" : "false") + ",\"expected_source_sha256\":" + json(signatures::sourceSha));
            if (!armed) { output.flush(); return true; }
            intervalMs = GetPrivateProfileIntW(L"BotNativeObserver", L"SampleIntervalMs", 500, configPath.c_str());
            if (intervalMs < 100 || intervalMs > 5000) throw std::runtime_error("invalid_sample_interval");
            recordOther = GetPrivateProfileIntW(L"BotNativeObserver", L"RecordOtherConsumers", 0, configPath.c_str()) == 1;
            int policyMode = GetPrivateProfileIntW(L"BotNativePolicy", L"Mode", 0, configPath.c_str());
            if (policyMode < 0 || policyMode > 2) throw std::runtime_error("invalid_policy_mode");
            // 客户端共享同一INI时只做原有观测；动态试点只在专服启用。
            if (policyMode) {
                try { n2_platform::dedicated(); }
                catch (...) { policyMode = 0; log("policy_suppressed_non_dedicated"); }
            }
            dynamic_policy::mode = static_cast<unsigned>(policyMode);
            log("policy_config", ",\"mode\":" + std::to_string(policyMode) + ",\"policy_version\":2,\"hero_pilots\":\"mokou,tei\",\"generic_items\":\"item_teeth\"");
            collecting = true;
            { std::lock_guard lock(observationMutex); install(); }
            api->AddListener(this, this);
            api->ConPrintf("[THDNativeKV] observer armed pid=%lu run=%s; policy mode=%u\n", GetCurrentProcessId(), run, dynamic_policy::mode);
            return true;
        } catch (const std::exception& e) {
            healthy = false; collecting = false;
            try { log("load_failed", ",\"reason\":" + json(e.what()) + ",\"hooks_remaining\":" + (installed ? "true" : "false")); output.flush(); } catch (...) {}
            if (error && size) snprintf(error, size, "%s", e.what());
            return installed; // 残余透传钩子不能因模块卸载变成悬空地址。
        }
    }
    bool Unload(char* error, size_t size) override {
        if (installed) { if (error && size) snprintf(error, size, "Exit Dota before removal; Enabled=0 stops recording"); return false; }
        return true;
    }
    bool Pause(char*, size_t) override { return false; }
    bool QueryRunning(char*, size_t) override { return healthy; }
    void OnLevelInit(const char*, const char*, const char*, const char*, bool, bool) override {
        std::lock_guard lock(observationMutex); ++epoch; rates = {}; nextRate = 0;
        callbackThread = dynamic_policy::mode ? GetCurrentThreadId() : 0;
        dynamic_policy::reset(true);
        log("level_init", counters()); output.flush();
    }
    void OnLevelShutdown() override {
        std::lock_guard lock(observationMutex); rates = {}; dynamic_policy::reset(false); log("level_shutdown", counters()); output.flush();
    }
    const char* GetAuthor() override { return "THD workspace"; }
    const char* GetName() override { return "THD Native Bot Getter Observer"; }
    const char* GetDescription() override { return "Fixed 7.38 getter observation with opt-in hero and item policies"; }
    const char* GetURL() override { return ""; }
    const char* GetLicense() override { return "Private"; }
    const char* GetVersion() override { return "R3-POLICY-20261010"; }
    const char* GetDate() override { return __DATE__; }
    const char* GetLogTag() override { return "THDNativeKV"; }
};
Plugin plugin;
}
extern "C" __declspec(dllexport) void* CreateInterface(const char* name, int* code) {
    const bool ok = name && std::strcmp(name, METAMOD_PLAPI_NAME) == 0;
    if (code) *code = ok ? META_IFACE_OK : META_IFACE_FAILED;
    return ok ? static_cast<SourceMM::ISmmPlugin*>(&observer::plugin) : nullptr;
}
