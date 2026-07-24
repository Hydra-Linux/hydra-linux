#include "flash.h"

int cmd_remove(int argc, char **argv) {
    if (argc == 0) { warn("No packages specified"); return 1; }

    if (db_open() != 0) return -1;

    for (int i = 0; i < argc; i++) {
        char *name = argv[i];

        if (!db_package_exists(name)) {
            warn("Package not installed: %s", name);
            continue;
        }

        sqlite3_stmt *stmt;
        const char *sql = "SELECT COUNT(*) FROM dependencies WHERE dep_name = ?1";
        int revdeps = 0;
        if (sqlite3_prepare_v2(g_db, sql, -1, &stmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(stmt, 1, name, -1, SQLITE_TRANSIENT);
            if (sqlite3_step(stmt) == SQLITE_ROW) revdeps = sqlite3_column_int(stmt, 0);
            sqlite3_finalize(stmt);
        }

        if (revdeps > 0 && !g_flags.force) {
            if (!g_flags.quiet)
                warn("%s is required by %d other package(s). Use --force to remove.", name, revdeps);
            continue;
        }

        if (!g_flags.quiet)
            print_status(1, "remove", name);

        if (!confirm("Proceed with removal?")) {
            if (!g_flags.quiet) print_status(0, "skip", name);
            continue;
        }

        if (g_flags.dry_run) {
            printf("Would remove: %s\n", name);
            continue;
        }

        char **files;
        int nfiles;
        if (db_files_list(name, &files, &nfiles) == 0) {
            char root[4096];
            snprintf(root, sizeof(root), "%s/", g_config.root ? g_config.root : "");
            for (int j = 0; j < nfiles; j++) {
                char full[4096];
                snprintf(full, sizeof(full), "%s%s", root, files[j]);
                if (remove(full) == 0 && g_flags.verbose)
                    print_status(1, "rm", files[j]);
                free(files[j]);
            }
            free(files);
        }

        db_package_remove(name);
        db_file_remove(name);
        db_transaction_log("remove", name, "");

        if (!g_flags.quiet) print_status(1, "removed", name);
    }

    return 0;
}
