#include "flash.h"

int sandbox_build(const char *recipe_path, const char *build_dir, int allow_network) {
    if (g_flags.dry_run) {
        printf("Would sandbox-build: %s in %s\n", recipe_path, build_dir);
        return 0;
    }

    if (!g_config.sandbox) {
        warn("Sandbox disabled, running build without isolation");
        pid_t pid = fork();
        if (pid == 0) {
            execl("/bin/sh", "sh", recipe_path, NULL);
            _exit(127);
        }
        int status;
        waitpid(pid, &status, 0);
        return WIFEXITED(status) ? WEXITSTATUS(status) : -1;
    }

    const char *bwrap = "/usr/bin/bwrap";
    if (access(bwrap, X_OK) != 0) {
        die("bubblewrap not found at %s", bwrap);
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
