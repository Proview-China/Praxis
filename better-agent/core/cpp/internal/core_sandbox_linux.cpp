#include "agent_core_internal.hpp"

#include <filesystem>

#if defined(__linux__)
    #include <cerrno>
    #include <cstring>
    #include <fcntl.h>
    #include <signal.h>
    #include <sys/prctl.h>
    #include <sys/syscall.h>
    #include <sys/wait.h>
    #include <unistd.h>
    #include <sched.h>
    #if __has_include(<linux/landlock.h>)
        #include <linux/landlock.h>
    #endif
#endif

namespace better_agent::core_internal {

namespace {

namespace fs = std::filesystem;

std::string runtime_platform_name() {
#if defined(__linux__)
    return "linux";
#elif defined(__APPLE__)
    return "macos";
#elif defined(_WIN32)
    return "windows";
#else
    return "unknown";
#endif
}

json capability_status(
    const std::string &status,
    const std::string &reason = "",
    const json &detail = json::object()
) {
    json out{{"status", status}};
    if (!reason.empty()) {
        out["reason"] = reason;
    }
    if (!detail.is_null() && !(detail.is_object() && detail.empty())) {
        out["detail"] = detail;
    }
    return out;
}

#if defined(__linux__)
json probe_setrlimit_capability() {
    return capability_status("available");
}

json probe_landlock_capability() {
#if defined(__NR_landlock_create_ruleset) && defined(LANDLOCK_CREATE_RULESET_VERSION)
    errno = 0;
    const long abi_version = syscall(__NR_landlock_create_ruleset, nullptr, 0, LANDLOCK_CREATE_RULESET_VERSION);
    if (abi_version >= 0) {
        return capability_status("available", "", json{{"abi_version", abi_version}});
    }
    if (errno == ENOSYS || errno == EOPNOTSUPP || errno == EINVAL) {
        return capability_status("unavailable", "kernel does not expose usable Landlock support", json{{"errno", errno}});
    }
    return capability_status("unavailable", std::strerror(errno), json{{"errno", errno}});
#else
    return capability_status("unsupported", "landlock headers or syscalls are unavailable at build time");
#endif
}

json probe_network_namespace_capability() {
#if defined(CLONE_NEWNET)
    const pid_t child = fork();
    if (child < 0) {
        return capability_status("unavailable", "fork failed", json{{"errno", errno}});
    }
    if (child == 0) {
        if (unshare(CLONE_NEWNET) == 0) {
            _exit(0);
        }
        _exit(errno == EPERM ? 10 : 11);
    }
    int status = 0;
    (void)waitpid(child, &status, 0);
    if (WIFEXITED(status)) {
        const int code = WEXITSTATUS(status);
        if (code == 0) {
            return capability_status("available");
        }
        if (code == 10) {
            return capability_status("unavailable", "operation not permitted");
        }
    }
    return capability_status("unavailable", "failed to create a new network namespace");
#else
    return capability_status("unsupported", "network namespace is unavailable at build time");
#endif
}

json probe_cgroup_v2_capability() {
    const fs::path controllers("/sys/fs/cgroup/cgroup.controllers");
    if (fs::exists(controllers)) {
        return capability_status("available", "", json{{"path", controllers.string()}});
    }
    return capability_status("unavailable", "cgroup v2 controllers file not found");
}

json probe_seccomp_capability() {
#if defined(PR_GET_SECCOMP)
    errno = 0;
    const int mode = prctl(PR_GET_SECCOMP, 0, 0, 0, 0);
    if (mode >= 0) {
        return capability_status("available", "", json{{"current_mode", mode}});
    }
    if (errno == EINVAL) {
        return capability_status("unavailable", "seccomp is not supported by current kernel");
    }
    return capability_status("unavailable", std::strerror(errno), json{{"errno", errno}});
#else
    return capability_status("unsupported", "seccomp is unavailable at build time");
#endif
}
#endif

json build_linux_capability_snapshot() {
    json capabilities = json::object();
#if defined(__linux__)
    capabilities["setrlimit"] = probe_setrlimit_capability();
    capabilities["landlock"] = probe_landlock_capability();
    capabilities["network_namespace"] = probe_network_namespace_capability();
    capabilities["cgroup_v2"] = probe_cgroup_v2_capability();
    capabilities["seccomp"] = probe_seccomp_capability();
#else
    capabilities["setrlimit"] = capability_status("unsupported", "current platform is not Linux");
    capabilities["landlock"] = capability_status("unsupported", "current platform is not Linux");
    capabilities["network_namespace"] = capability_status("unsupported", "current platform is not Linux");
    capabilities["cgroup_v2"] = capability_status("unsupported", "current platform is not Linux");
    capabilities["seccomp"] = capability_status("unsupported", "current platform is not Linux");
#endif

    return json{
        {"status", "success"},
        {"platform", runtime_platform_name()},
        {"capabilities", capabilities},
        {"supported_policy", json{
            {"linux_filesystem_isolation", json::array({"off", "best_effort", "required"})},
            {"linux_network_isolation", json::array({"off", "best_effort", "required"})},
            {"readonly_paths", true},
            {"writable_paths", true},
            {"network_access", true},
            {"cpu_limit", true},
            {"memory_limit", true}
        }}
    };
}

} // namespace

json get_sandbox_capabilities_locked(const json &request_json, json *err_out) {
    if (err_out != nullptr) {
        *err_out = nullptr;
    }

    const bool refresh = request_json.value("refresh", false);
    if (!refresh && g_sandbox_capability_cache_valid) {
        return g_sandbox_capability_cache;
    }

    g_sandbox_capability_cache = build_linux_capability_snapshot();
    g_sandbox_capability_cache_valid = true;
    return g_sandbox_capability_cache;
}

} // namespace better_agent::core_internal
