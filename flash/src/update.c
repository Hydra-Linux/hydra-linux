#include "flash.h"

int cmd_update(int argc, char **argv) {
    (void)argc; (void)argv;
    if (db_open() != 0) return -1;

    Package **all;
    int nall;
    if (db_list_all(&all, &nall) != 0) return -1;

    if (nall == 0) {
        if (!g_flags.quiet) print_status(1, "update", "No packages installed");
        free(all);
        return 0;
    }

    int updated = 0;
    for (int i = 0; i < nall; i++) {
        Package *pkg = all[i];

        if (db_is_held(pkg->name)) {
            if (g_flags.verbose) print_status(1, "held", pkg->name);
            free(pkg->name); free(pkg->version); free(pkg->desc);
            free(pkg->license); free(pkg->maintainer); free(pkg->homepage);
            free(pkg->checksum); free(pkg);
            continue;
        }

        if (!g_flags.quiet)
            print_colored(COLOR_CYAN, "checking %s (%s)", pkg->name, pkg->version);

        char metadata_url[4096];
        snprintf(metadata_url, sizeof(metadata_url), "%s/meta/%s.json",
                 g_config.repo_url, pkg->name);
        char meta_path[4096];
        snprintf(meta_path, sizeof(meta_path), "%s/%s.meta.json",
                 g_config.cache_dir, pkg->name);

        if (access(meta_path, F_OK) != 0) {
            if (g_flags.dry_run) {
                printf("Would fetch: %s\n", metadata_url);
            } else {
                mkdir_p(g_config.cache_dir);
                fetch_url(metadata_url, meta_path);
            }
        }

        char *meta = read_file(meta_path);
        if (!meta) {
            if (g_flags.verbose) warn("No metadata for %s", pkg->name);
            goto next;
        }

        char *ver_line = strstr(meta, "\"version\":");
        if (ver_line) {
            ver_line += 10;
            while (*ver_line == ' ' || *ver_line == '"') ver_line++;
            char *end = strchr(ver_line, '"');
            if (end) *end = 0;

            if (vercmp(ver_line, pkg->version) > 0) {
                if (!g_flags.quiet)
                    print_colored(COLOR_YELLOW, "upgrading %s: %s -> %s",
                                  pkg->name, pkg->version, ver_line);

                if (!g_flags.dry_run) {
                    int argc2 = 1;
                    char *argv2[] = { pkg->name };
                    cmd_install(argc2, argv2);
                    updated++;
                } else {
                    printf("Would upgrade %s to %s\n", pkg->name, ver_line);
                    updated++;
                }
            }
        }
        free(meta);

    next:
        free(pkg->name); free(pkg->version); free(pkg->desc);
        free(pkg->license); free(pkg->maintainer); free(pkg->homepage);
        free(pkg->checksum); free(pkg);
    }
    free(all);

    if (!g_flags.quiet) {
        if (updated == 0) print_status(1, "update", "All packages up to date");
        else print_status(1, "update", "Updated %d package(s)", updated);
    }

    return 0;
}
