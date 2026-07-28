#include "flash.h"

int config_default(Config *cfg) {
    memset(cfg, 0, sizeof(Config));
    cfg->root = NULL;
    cfg->db_path = strdup_safe(FLASH_DB_PATH);
    cfg->cache_dir = strdup_safe(FLASH_CACHE_DIR);
    cfg->build_dir = strdup_safe(FLASH_BUILD_DIR);
    cfg->recipes_dir = strdup_safe(FLASH_RECIPES_DIR);
    cfg->keyring = strdup_safe(FLASH_KEYRING);
    cfg->sandbox = 1;
    cfg->jobs = 1;
    cfg->sign = 0;
    cfg->source_threshold = 104857600;
    cfg->binary_threshold = 471859200;
    cfg->repo_url = strdup_safe(FLASH_REPO_URL);
    return 0;
}

int config_load(const char *path, Config *cfg) {
    config_default(cfg);

    char *data = read_file(path);
    if (!data) {
        warn("No config found at %s, using defaults", path);
        return 0;
    }

    char *line = data;
    while (line && *line) {
        while (*line == ' ' || *line == '\t' || *line == '\n' || *line == '\r') line++;
        if (!*line || *line == '#') { while (*line && *line != '\n') line++; if (*line) line++; continue; }

        char *eq = strchr(line, '=');
        if (!eq) { while (*line && *line != '\n') line++; if (*line) line++; continue; }

        *eq = 0;
        char *key = line;
        char *val = eq + 1;
        while (*key == ' ' || *key == '\t') key++;
        char *ke = key + strlen(key) - 1;
        while (ke > key && (*ke == ' ' || *ke == '\t')) *ke-- = 0;
        while (*val == ' ' || *val == '\t') val++;
        char *ve = val + strlen(val) - 1;
        while (ve > val && (*ve == ' ' || *ve == '\t' || *ve == '\n' || *ve == '\r')) *ve-- = 0;
        if (*val == '"') { val++; ve = val + strlen(val) - 1; if (*ve == '"') *ve = 0; }

        if (strcmp(key, "root") == 0) { free(cfg->root); cfg->root = strdup_safe(val); }
        else if (strcmp(key, "db_path") == 0) { free(cfg->db_path); cfg->db_path = strdup_safe(val); }
        else if (strcmp(key, "cache_dir") == 0) { free(cfg->cache_dir); cfg->cache_dir = strdup_safe(val); }
        else if (strcmp(key, "build_dir") == 0) { free(cfg->build_dir); cfg->build_dir = strdup_safe(val); }
        else if (strcmp(key, "recipes_dir") == 0) { free(cfg->recipes_dir); cfg->recipes_dir = strdup_safe(val); }
        else if (strcmp(key, "keyring") == 0) { free(cfg->keyring); cfg->keyring = strdup_safe(val); }
        else if (strcmp(key, "sandbox") == 0) cfg->sandbox = atoi(val);
        else if (strcmp(key, "jobs") == 0) cfg->jobs = atoi(val);
        else if (strcmp(key, "sign") == 0) cfg->sign = atoi(val);
        else if (strcmp(key, "source_threshold") == 0) cfg->source_threshold = atol(val);
        else if (strcmp(key, "binary_threshold") == 0) cfg->binary_threshold = atol(val);
        else if (strcmp(key, "repo_url") == 0) { free(cfg->repo_url); cfg->repo_url = strdup_safe(val); }

        *eq = '=';
        while (*line && *line != '\n') line++;
        if (*line) line++;
    }

    free(data);
    return 0;
}

int fetch_url(const char *url, const char *dest) {
    if (g_flags.verbose) print_status(1, "fetch", url);
    char cmd[4096];
    snprintf(cmd, sizeof(cmd), "curl -sfL '%s' -o '%s' 2>/dev/null", url, dest);
    int ret = system(cmd);
    if (ret != 0) {
        snprintf(cmd, sizeof(cmd), "wget -q '%s' -O '%s' 2>/dev/null", url, dest);
        ret = system(cmd);
    }
    return ret == 0 ? 0 : -1;
}

int recipe_parse(const char *recipe_path, Package *pkg, Dependency **deps, int *ndeps) {
    memset(pkg, 0, sizeof(Package));
    *deps = NULL;
    *ndeps = 0;

    char *data = read_file(recipe_path);
    if (!data) return -1;

    char *line = data;
    int depcap = 0;
    while (line && *line) {
        while (*line == ' ' || *line == '\t' || *line == '\n' || *line == '\r') line++;
        if (!*line || *line == '#') { while (*line && *line != '\n') line++; if (*line) line++; continue; }

        char *eq = strchr(line, '=');
        if (!eq) { while (*line && *line != '\n') line++; if (*line) line++; continue; }
        *eq = 0;
        char *key = line;
        char *val = eq + 1;
        while (*key == ' ' || *key == '\t') key++;
        char *ke = key + strlen(key) - 1;
        while (ke > key && (*ke == ' ' || *ke == '\t')) *ke-- = 0;
        while (*val == ' ' || *val == '\t') val++;
        char *ve = val + strlen(val) - 1;
        while (ve > val && (*ve == ' ' || *ve == '\t' || *ve == '\n' || *ve == '\r')) *ve-- = 0;
        if (*val == '"') { val++; ve = val + strlen(val) - 1; if (*ve == '"') *ve = 0; }

        if (strcmp(key, "name") == 0) pkg->name = strdup_safe(val);
        else if (strcmp(key, "version") == 0) pkg->version = strdup_safe(val);
        else if (strcmp(key, "release") == 0) pkg->release = atoi(val);
        else if (strcmp(key, "desc") == 0) pkg->desc = strdup_safe(val);
        else if (strcmp(key, "license") == 0) pkg->license = strdup_safe(val);
        else if (strcmp(key, "maintainer") == 0) pkg->maintainer = strdup_safe(val);
        else if (strcmp(key, "homepage") == 0) pkg->homepage = strdup_safe(val);
        else if (strcmp(key, "size") == 0) pkg->size = atol(val);
        else if (strcmp(key, "checksum") == 0) pkg->checksum = strdup_safe(val);
        else if (strcmp(key, "depends") == 0 || strcmp(key, "build_depends") == 0) {
            int dtype = (strcmp(key, "build_depends") == 0) ? 1 : 0;
            char *d = val;
            while (d && *d) {
                while (*d == ' ' || *d == ',') d++;
                if (!*d) break;
                char *end = strchr(d, ',');
                if (end) *end = 0;
                char *space = strchr(d, ' ');
                if (*ndeps >= depcap) {
                    depcap = depcap ? depcap * 2 : 8;
                    *deps = realloc(*deps, sizeof(Dependency) * depcap);
                }
                Dependency *dp = &(*deps)[*ndeps];
                memset(dp, 0, sizeof(Dependency));
                dp->type = dtype;
                if (space) {
                    *space = 0;
                    dp->name = strdup_safe(d);
                    dp->constraint = strdup_safe(space + 1);
                    *space = ' ';
                } else {
                    dp->name = strdup_safe(d);
                }
                (*ndeps)++;
                if (end) { *end = ','; d = end + 1; }
                else break;
            }
        }

        *eq = '=';
        while (*line && *line != '\n') line++;
        if (*line) line++;
    }

    free(data);
    return 0;
}

int cmd_find(int argc, char **argv) {
    if (argc == 0) { warn("No search query"); return 1; }
    if (db_open() != 0) return -1;
    Package *results;
    int nresults;
    if (db_package_find(argv[0], &results, &nresults) != 0) return -1;
    if (nresults == 0) { print_status(0, "find", "No results"); free(results); return 0; }
    for (int i = 0; i < nresults; i++) {
        Package *p = &results[i];
        if (g_flags.json) printf("{\"name\":\"%s\",\"version\":\"%s\"}\n", p->name, p->version);
        else printf("%s %s  %s\n", p->name, p->version, p->desc ? p->desc : "");
        free(p->name); free(p->version); free(p->desc); free(p->license);
        free(p->maintainer); free(p->homepage); free(p->checksum);
    }
    free(results);
    return 0;
}

int cmd_info(int argc, char **argv) {
    if (argc == 0) { warn("No package specified"); return 1; }
    if (db_open() != 0) return -1;
    for (int i = 0; i < argc; i++) {
        Package pkg;
        if (db_package_get(argv[i], &pkg) != 0) {
            warn("Package not found: %s", argv[i]);
            continue;
        }
        if (g_flags.json) {
            printf("{\"name\":\"%s\",\"version\":\"%s\",\"release\":%d,"
                   "\"desc\":\"%s\",\"license\":\"%s\",\"maintainer\":\"%s\","
                   "\"homepage\":\"%s\",\"size\":%ld}\n",
                   pkg.name, pkg.version, pkg.release,
                   pkg.desc ? pkg.desc : "", pkg.license ? pkg.license : "",
                   pkg.maintainer ? pkg.maintainer : "",
                   pkg.homepage ? pkg.homepage : "", pkg.size);
        } else {
            printf("Name:       %s\n", pkg.name);
            printf("Version:    %s-%d\n", pkg.version, pkg.release);
            printf("Desc:       %s\n", pkg.desc ? pkg.desc : "");
            printf("License:    %s\n", pkg.license ? pkg.license : "");
            printf("Maintainer: %s\n", pkg.maintainer ? pkg.maintainer : "");
            printf("Homepage:   %s\n", pkg.homepage ? pkg.homepage : "");
            printf("Size:       %ld\n", pkg.size);
        }
        free(pkg.name); free(pkg.version); free(pkg.desc); free(pkg.license);
        free(pkg.maintainer); free(pkg.homepage); free(pkg.checksum);
    }
    return 0;
}

int cmd_list(int argc, char **argv) {
    if (db_open() != 0) return -1;
    Package **all;
    int nall;
    if (db_list_all(&all, &nall) != 0) return -1;
    (void)argc; (void)argv;
    if (g_flags.json) {
        printf("[");
        for (int i = 0; i < nall; i++) {
            if (i > 0) printf(",");
            printf("{\"name\":\"%s\",\"version\":\"%s\"}", all[i]->name, all[i]->version);
        }
        printf("]\n");
    } else {
        for (int i = 0; i < nall; i++) {
            printf("%s %s\n", all[i]->name, all[i]->version);
        }
    }
    for (int i = 0; i < nall; i++) {
        free(all[i]->name); free(all[i]->version); free(all[i]->desc);
        free(all[i]->license); free(all[i]->maintainer); free(all[i]->homepage);
        free(all[i]->checksum); free(all[i]);
    }
    free(all);
    return 0;
}

int cmd_contents(int argc, char **argv) {
    if (argc == 0) { warn("No package specified"); return 1; }
    if (db_open() != 0) return -1;
    for (int i = 0; i < argc; i++) {
        char **files;
        int nfiles;
        if (db_files_list(argv[i], &files, &nfiles) != 0) {
            warn("Package not found: %s", argv[i]);
            continue;
        }
        if (g_flags.json) {
            printf("{\"package\":\"%s\",\"files\":[", argv[i]);
            for (int j = 0; j < nfiles; j++) {
                if (j > 0) printf(",");
                printf("\"%s\"", files[j]);
            }
            printf("]}\n");
        } else {
            for (int j = 0; j < nfiles; j++) {
                printf("%s\n", files[j]);
            }
        }
        for (int j = 0; j < nfiles; j++) free(files[j]);
        free(files);
    }
    return 0;
}

int cmd_find_owner(int argc, char **argv) {
    if (argc == 0) { warn("No file specified"); return 1; }
    if (db_open() != 0) return -1;
    for (int i = 0; i < argc; i++) {
        char *owner;
        if (db_find_owner(argv[i], &owner) != 0) {
            warn("No package owns: %s", argv[i]);
            continue;
        }
        if (g_flags.json) printf("{\"file\":\"%s\",\"package\":\"%s\"}\n", argv[i], owner);
        else printf("%s belongs to %s\n", argv[i], owner);
        free(owner);
    }
    return 0;
}

int cmd_make(int argc, char **argv) {
    if (argc == 0) { warn("No recipe specified"); return 1; }
    for (int i = 0; i < argc; i++) {
        Package pkg;
        Dependency *deps = NULL;
        int ndeps = 0;
        if (recipe_parse(argv[i], &pkg, &deps, &ndeps) != 0) {
            warn("Cannot parse recipe: %s", argv[i]);
            continue;
        }
        if (!pkg.name || !pkg.version) {
            warn("Recipe %s missing name or version", argv[i]);
            free(pkg.name); free(pkg.version); free(pkg.desc);
            free(pkg.license); free(pkg.maintainer); free(pkg.homepage);
            free(pkg.checksum);
            for (int j = 0; j < ndeps; j++) { free(deps[j].name); free(deps[j].version); free(deps[j].constraint); }
            free(deps);
            continue;
        }

        if (!g_flags.quiet) print_status(1, "make", pkg.name);

        char build_dir[4096];
        snprintf(build_dir, sizeof(build_dir), "%s/%s-%s", g_config.build_dir, pkg.name, pkg.version);
        mkdir_p(build_dir);

        int ret = sandbox_build(argv[i], build_dir, 0);
        if (ret != 0) {
            warn("Build failed for %s (exit %d)", pkg.name, ret);
        } else {
            char pkg_path[4096];
            snprintf(pkg_path, sizeof(pkg_path), "%s/%s-%s.tar.zst",
                     g_config.cache_dir, pkg.name, pkg.version);
            mkdir_p(g_config.cache_dir);
            archive_create(build_dir, pkg_path, NULL, 0);
            if (g_config.sign) crypto_sign(pkg_path, NULL);

            char hash[65];
            if (crypto_checksum(pkg_path, hash, sizeof(hash)) == 0) {
                pkg.checksum = strdup_safe(hash);
            }

            if (db_open() == 0) {
                db_package_insert(&pkg);
                db_transaction_log("make", pkg.name, pkg.version);
            }

            if (!g_flags.quiet) print_status(1, "built", pkg.name);
        }

        free(pkg.name); free(pkg.version); free(pkg.desc);
        free(pkg.license); free(pkg.maintainer); free(pkg.homepage);
        free(pkg.checksum);
        for (int j = 0; j < ndeps; j++) { free(deps[j].name); free(deps[j].version); free(deps[j].constraint); }
        free(deps);
    }
    return 0;
}

int cmd_audit(int argc, char **argv) {
    if (db_open() != 0) return -1;
    Package **all;
    int nall;
    if (db_list_all(&all, &nall) != 0) return -1;
    int ok = 0, bad = 0;
    (void)argc; (void)argv;

    for (int i = 0; i < nall; i++) {
        Package *pkg = all[i];
        char **files;
        int nfiles;
        if (db_files_list(pkg->name, &files, &nfiles) != 0) {
            bad++;
            continue;
        }
        int missing = 0;
        char root[4096];
        snprintf(root, sizeof(root), "%s/", g_config.root ? g_config.root : "");
        for (int j = 0; j < nfiles; j++) {
            char full[4096];
            snprintf(full, sizeof(full), "%s%s", root, files[j]);
            if (access(full, F_OK) != 0) {
                if (g_flags.verbose) print_status(0, "missing", full);
                missing++;
            }
            free(files[j]);
        }
        free(files);

        if (missing) {
            bad++;
            if (!g_flags.quiet) print_status(0, "audit", "%s: %d missing file(s)", pkg->name, missing);
        } else {
            ok++;
        }
        free(pkg->name); free(pkg->version); free(pkg->desc);
        free(pkg->license); free(pkg->maintainer); free(pkg->homepage);
        free(pkg->checksum); free(pkg);
    }
    free(all);

    if (!g_flags.quiet)
        print_status(bad == 0, "audit", "%d OK, %d failed", ok, bad);
    return bad ? 1 : 0;
}

int cmd_cache(int argc, char **argv) {
    if (argc > 0 && strcmp(argv[0], "clean") == 0) {
        if (!confirm("Clean package cache?")) return 1;
        if (g_flags.dry_run) { printf("Would clean %s\n", g_config.cache_dir); return 0; }
        char cmd[4096];
        snprintf(cmd, sizeof(cmd), "rm -rf '%s'/*", g_config.cache_dir);
        int rc = system(cmd); (void)rc;
        if (!g_flags.quiet) print_status(1, "cache", "cleaned");
    } else {
        char cmd[4096];
        snprintf(cmd, sizeof(cmd), "du -sh '%s' 2>/dev/null | cut -f1", g_config.cache_dir);
        FILE *f = popen(cmd, "r");
        if (f) {
            char size[64] = {0};
            if (fgets(size, sizeof(size), f)) {
                size[strcspn(size, "\n")] = 0;
                if (g_flags.json) printf("{\"cache_dir\":\"%s\",\"size\":\"%s\"}\n", g_config.cache_dir, size);
                else printf("Cache: %s (%s)\n", g_config.cache_dir, size);
            }
            pclose(f);
        }
    }
    (void)argc; (void)argv;
    return 0;
}

int cmd_config(int argc, char **argv) {
    if (argc == 0) {
        printf("root=%s\n", g_config.root ? g_config.root : "");
        printf("db_path=%s\n", g_config.db_path);
        printf("cache_dir=%s\n", g_config.cache_dir);
        printf("build_dir=%s\n", g_config.build_dir);
        printf("recipes_dir=%s\n", g_config.recipes_dir);
        printf("keyring=%s\n", g_config.keyring);
        printf("sandbox=%d\n", g_config.sandbox);
        printf("jobs=%d\n", g_config.jobs);
        printf("sign=%d\n", g_config.sign);
        printf("source_threshold=%ld\n", g_config.source_threshold);
        printf("binary_threshold=%ld\n", g_config.binary_threshold);
        printf("repo_url=%s\n", g_config.repo_url);
    } else if (argc >= 2) {
        char *key = argv[0];
        char *val = argv[1];
        if (strcmp(key, "root") == 0) { free(g_config.root); g_config.root = strdup_safe(val); }
        else if (strcmp(key, "db_path") == 0) { free(g_config.db_path); g_config.db_path = strdup_safe(val); }
        else if (strcmp(key, "cache_dir") == 0) { free(g_config.cache_dir); g_config.cache_dir = strdup_safe(val); }
        else if (strcmp(key, "build_dir") == 0) { free(g_config.build_dir); g_config.build_dir = strdup_safe(val); }
        else if (strcmp(key, "recipes_dir") == 0) { free(g_config.recipes_dir); g_config.recipes_dir = strdup_safe(val); }
        else if (strcmp(key, "keyring") == 0) { free(g_config.keyring); g_config.keyring = strdup_safe(val); }
        else if (strcmp(key, "sandbox") == 0) g_config.sandbox = atoi(val);
        else if (strcmp(key, "jobs") == 0) g_config.jobs = atoi(val);
        else if (strcmp(key, "sign") == 0) g_config.sign = atoi(val);
        else if (strcmp(key, "repo_url") == 0) { free(g_config.repo_url); g_config.repo_url = strdup_safe(val); }
        else warn("Unknown config key: %s", key);
    }
    return 0;
}

int cmd_sync(int argc, char **argv) {
    if (db_open() != 0) return -1;
    (void)argc; (void)argv;

    char repo_index[4096];
    snprintf(repo_index, sizeof(repo_index), "%s/packages.json", g_config.repo_url);
    char dest[4096];
    snprintf(dest, sizeof(dest), "%s/repo-packages.json", g_config.cache_dir);

    mkdir_p(g_config.cache_dir);
    if (g_flags.dry_run) {
        printf("Would sync: %s -> %s\n", repo_index, dest);
        return 0;
    }

    if (fetch_url(repo_index, dest) != 0) {
        warn("Failed to sync repository index");
        return -1;
    }

    char *data = read_file(dest);
    if (!data) { warn("Empty repo index"); return -1; }

    char *p = data;
    int count = 0;
    while ((p = strstr(p, "\"name\":")) != NULL) {
        p += 7;
        while (*p && *p != '"') p++;
        if (!*p) break;
        p++;
        char *end = strchr(p, '"');
        if (!end) break;
        *end = 0;
        char *pkg_name = p;
        p = end + 1;

        char meta_url[4096];
        snprintf(meta_url, sizeof(meta_url), "%s/meta/%s.json", g_config.repo_url, pkg_name);
        char meta_dest[4096];
        snprintf(meta_dest, sizeof(meta_dest), "%s/%s.meta.json", g_config.cache_dir, pkg_name);
        fetch_url(meta_url, meta_dest);
        count++;
    }

    free(data);

    if (!g_flags.quiet) print_status(1, "sync", "Synced %d packages", count);
    return 0;
}

int cmd_revert(int argc, char **argv) {
    if (argc == 0) { warn("No package specified"); return 1; }
    if (db_open() != 0) return -1;

    for (int i = 0; i < argc; i++) {
        char *name = argv[i];
        if (!db_package_exists(name)) { warn("Not installed: %s", name); continue; }

        if (db_is_held(name) && !g_flags.force) {
            warn("%s is held. Use --force to revert.", name);
            continue;
        }

        Package pkg;
        db_package_get(name, &pkg);

        sqlite3_stmt *stmt;
        const char *sql = "SELECT version FROM transaction_log WHERE package = ?1 "
            "AND action = 'install' ORDER BY id DESC LIMIT 1 OFFSET 1";
        char *prev_version = NULL;
        if (sqlite3_prepare_v2(g_db, sql, -1, &stmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(stmt, 1, name, -1, SQLITE_TRANSIENT);
            if (sqlite3_step(stmt) == SQLITE_ROW) {
                prev_version = strdup_safe((const char *)sqlite3_column_text(stmt, 0));
            }
            sqlite3_finalize(stmt);
        }

        if (!prev_version) { warn("No previous version for %s", name); goto revert_next; }

        if (!g_flags.quiet)
            print_colored(COLOR_YELLOW, "reverting %s %s -> %s", name, pkg.version, prev_version);

        if (!g_flags.dry_run) {
            int argc2 = 1;
            char *argv2[] = { name };
            cmd_remove(argc2, argv2);
            char *old_ver = pkg.version;
            pkg.version = prev_version;
            prev_version = old_ver;
            cmd_install(argc2, argv2);
        }

    revert_next:
        free(prev_version);
        free(pkg.name); free(pkg.version); free(pkg.desc);
        free(pkg.license); free(pkg.maintainer); free(pkg.homepage);
        free(pkg.checksum);
    }
    return 0;
}

int cmd_freeze(int argc, char **argv) {
    if (argc == 0) { warn("No package specified"); return 1; }
    if (db_open() != 0) return -1;
    for (int i = 0; i < argc; i++) {
        if (!db_package_exists(argv[i])) { warn("Not installed: %s", argv[i]); continue; }
        db_hold_add(argv[i]);
        if (!g_flags.quiet) print_status(1, "freeze", argv[i]);
    }
    return 0;
}

int cmd_unfreeze(int argc, char **argv) {
    if (argc == 0) {
        if (db_open() != 0) return -1;
        char **held;
        int nheld;
        db_holds_list(&held, &nheld);
        for (int i = 0; i < nheld; i++) {
            db_hold_remove(held[i]);
            free(held[i]);
        }
        free(held);
        if (!g_flags.quiet) print_status(1, "unfreeze", "all");
        return 0;
    }
    if (db_open() != 0) return -1;
    for (int i = 0; i < argc; i++) {
        db_hold_remove(argv[i]);
        if (!g_flags.quiet) print_status(1, "unfreeze", argv[i]);
    }
    return 0;
}

int cmd_rebuild(int argc, char **argv) {
    if (argc == 0) { warn("No package specified"); return 1; }
    if (db_open() != 0) return -1;

    for (int i = 0; i < argc; i++) {
        sqlite3_stmt *stmt;
        const char *sql = "SELECT package FROM dependencies WHERE dep_name = ?1";
        if (sqlite3_prepare_v2(g_db, sql, -1, &stmt, NULL) != SQLITE_OK) continue;
        sqlite3_bind_text(stmt, 1, argv[i], -1, SQLITE_TRANSIENT);

        int n = 0;
        char **reverse = NULL;
        int cap = 0;
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            const char *name = (const char *)sqlite3_column_text(stmt, 0);
            if (n >= cap) { cap = cap ? cap * 2 : 8; reverse = realloc(reverse, sizeof(char *) * cap); }
            reverse[n++] = strdup_safe(name);
        }
        sqlite3_finalize(stmt);

        for (int j = 0; j < n; j++) {
            if (!g_flags.quiet) print_status(1, "rebuild", reverse[j]);
            if (!g_flags.dry_run) {
                int argc2 = 1;
                char *argv2[] = { reverse[j] };
                cmd_install(argc2, argv2);
            }
            free(reverse[j]);
        }
        free(reverse);
    }
    return 0;
}

int cmd_help(int argc, char **argv) {
    (void)argc; (void)argv;
    print_usage();
    return 0;
}

static int dispatch(Command cmd, int argc, char **argv) {
    switch (cmd) {
        case CMD_INSTALL: return cmd_install(argc, argv);
        case CMD_RM: return cmd_remove(argc, argv);
        case CMD_UPDATE: return cmd_update(argc, argv);
        case CMD_FIND: return cmd_find(argc, argv);
        case CMD_INFO: return cmd_info(argc, argv);
        case CMD_LIST: return cmd_list(argc, argv);
        case CMD_CONTENTS: return cmd_contents(argc, argv);
        case CMD_FIND_OWNER: return cmd_find_owner(argc, argv);
        case CMD_MAKE: return cmd_make(argc, argv);
        case CMD_AUDIT: return cmd_audit(argc, argv);
        case CMD_CACHE: return cmd_cache(argc, argv);
        case CMD_CONFIG: return cmd_config(argc, argv);
        case CMD_SYNC: return cmd_sync(argc, argv);
        case CMD_REVERT: return cmd_revert(argc, argv);
        case CMD_FREEZE: return cmd_freeze(argc, argv);
        case CMD_UNFREEZE: return cmd_unfreeze(argc, argv);
        case CMD_REBUILD: return cmd_rebuild(argc, argv);
        default: return cmd_help(argc, argv);
    }
}

int main(int argc, char **argv) {
    if (argc < 2) { print_usage(); return 1; }

    config_load(FLASH_CONF_PATH, &g_config);

    int nargs = parse_flags(argc, argv, &g_flags);
    if (nargs < 2) { print_usage(); return 1; }

    Command cmd = command_from_string(argv[1]);
    int ret = dispatch(cmd, nargs - 2, argv + 2);

    db_close();
    return ret;
}
