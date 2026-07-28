#include "flash.h"

int sandbox_build(const char *recipe_path, const char *build_dir, int allow_network) {
    if (g_flags.dry_run) {
        printf("Would sandbox-build: %s in %s\n", recipe_path, build_dir);
        return 0;
    }

    if (!g_config.sandbox) {
        warn("Sandbox disabled, running build without isolation");
        char script_path[1024];
        snprintf(script_path, sizeof(script_path), "%s/.flash_build.sh", build_dir);
        pid_t pid = fork();
        if (pid == 0) {
            if (chdir(build_dir) != 0) _exit(126);
            execl("/bin/sh", "sh", script_path, NULL);
            _exit(127);
        }
        int status;
        waitpid(pid, &status, 0);
        return WIFEXITED(status) ? WEXITSTATUS(status) : -1;
    }

    static const char *bwrap_paths[] = {
        "/usr/bin/bwrap", "/usr/local/bin/bwrap", "/run/current-system/sw/bin/bwrap",
        NULL
    };
    const char *bwrap = NULL;
    char *bwrap_buf = NULL;
    for (int p = 0; bwrap_paths[p]; p++) {
        if (access(bwrap_paths[p], X_OK) == 0) { bwrap = bwrap_paths[p]; break; }
    }
    if (!bwrap) {
        FILE *fp = popen("which bwrap 2>/dev/null", "r");
        if (fp) {
            char buf[4096];
            if (fgets(buf, sizeof(buf), fp)) {
                buf[strcspn(buf, "\n")] = 0;
                if (access(buf, X_OK) == 0) bwrap = bwrap_buf = strdup(buf);
            }
            pclose(fp);
        }
    }
    if (!bwrap) {
        die("bubblewrap (bwrap) not found. Install it (e.g. apt install bubblewrap)");
    }

    int arg_max = 64;
    const char **argv = calloc(arg_max, sizeof(char *));
    int n = 0;

    argv[n++] = bwrap;
    argv[n++] = "--ro-bind";
    argv[n++] = "/usr";
    argv[n++] = "/usr";
    argv[n++] = "--ro-bind";
    argv[n++] = "/lib";
    argv[n++] = "/lib";
    argv[n++] = "--ro-bind";
    argv[n++] = "/lib64";
    argv[n++] = "/lib64";
    argv[n++] = "--ro-bind";
    argv[n++] = "/bin";
    argv[n++] = "/bin";
    argv[n++] = "--ro-bind";
    argv[n++] = "/sbin";
    argv[n++] = "/sbin";
    argv[n++] = "--ro-bind";
    argv[n++] = "/etc";
    argv[n++] = "/etc";
    argv[n++] = "--proc";
    argv[n++] = "/proc";
    argv[n++] = "--dev";
    argv[n++] = "/dev";
    argv[n++] = "--tmpfs";
    argv[n++] = "/tmp";
    argv[n++] = "--bind";
    argv[n++] = build_dir;
    argv[n++] = "/build";
    argv[n++] = "--setenv";
    argv[n++] = "HOME";
    argv[n++] = "/tmp";
    argv[n++] = "--setenv";
    argv[n++] = "BUILD_DIR";
    argv[n++] = "/build";

    if (!allow_network) {
        argv[n++] = "--unshare-net";
    }

    argv[n++] = "--chdir";
    argv[n++] = "/build";
    argv[n++] = "/bin/sh";
    argv[n++] = "/build/.flash_build.sh";

    if (n >= arg_max - 1) die("Too many bwrap arguments");

    if (g_flags.verbose) {
        fprintf(stderr, "sandbox:");
        for (int i = 0; i < n; i++) fprintf(stderr, " %s", argv[i]);
        fprintf(stderr, "\n");
    }

    pid_t pid = fork();
    if (pid == 0) {
        execv(bwrap, (char *const *)argv);
        _exit(127);
    }

    free(argv);
    int status;
    waitpid(pid, &status, 0);
    return WIFEXITED(status) ? WEXITSTATUS(status) : -1;
}
