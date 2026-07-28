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
        if (!*line || *line == '#' || *line == '[') { while (*line && *line != '\n') line++; if (*line) line++; continue; }

        char *next = strchr(line, '\n');
        char *eq = strchr(line, '=');
        if (!eq || (next && eq > next)) {
            if (next) { line = next + 1; continue; }
            else break;
        }

        size_t vallen;
        char key_buf[256], val_buf[1024];
        const char *kp = line;
        while (kp < eq && (*kp == ' ' || *kp == '\t')) kp++;
        size_t klen = eq - kp;
        while (klen > 0 && (kp[klen-1] == ' ' || kp[klen-1] == '\t')) klen--;
        if (klen >= sizeof(key_buf)) klen = sizeof(key_buf) - 1;
        memcpy(key_buf, kp, klen); key_buf[klen] = 0;

        const char *vp = eq + 1;
        while (*vp == ' ' || *vp == '\t') vp++;
        if (next) vallen = next - vp;
        else vallen = strlen(vp);
        while (vallen > 0 && (vp[vallen-1] == ' ' || vp[vallen-1] == '\t' ||
               vp[vallen-1] == '\n' || vp[vallen-1] == '\r')) vallen--;
        if (*vp == '"' && vallen >= 2 && vp[vallen-1] == '"') { vp++; vallen -= 2; }
        if (vallen >= sizeof(val_buf)) vallen = sizeof(val_buf) - 1;
        memcpy(val_buf, vp, vallen); val_buf[vallen] = 0;

        if (strcmp(key_buf, "root") == 0) { free(cfg->root); cfg->root = strdup_safe(val_buf); }
        else if (strcmp(key_buf, "db") == 0 || strcmp(key_buf, "db_path") == 0) { free(cfg->db_path); cfg->db_path = strdup_safe(val_buf); }
        else if (strcmp(key_buf, "cache_dir") == 0) { free(cfg->cache_dir); cfg->cache_dir = strdup_safe(val_buf); }
        else if (strcmp(key_buf, "build_dir") == 0) { free(cfg->build_dir); cfg->build_dir = strdup_safe(val_buf); }
        else if (strcmp(key_buf, "recipes_dir") == 0) { free(cfg->recipes_dir); cfg->recipes_dir = strdup_safe(val_buf); }
        else if (strcmp(key_buf, "keyring") == 0) { free(cfg->keyring); cfg->keyring = strdup_safe(val_buf); }
        else if (strcmp(key_buf, "sandbox") == 0) cfg->sandbox = atoi(val_buf);
        else if (strcmp(key_buf, "jobs") == 0) cfg->jobs = atoi(val_buf);
        else if (strcmp(key_buf, "sign") == 0) cfg->sign = atoi(val_buf);
        else if (strcmp(key_buf, "source_threshold") == 0) cfg->source_threshold = atol(val_buf);
        else if (strcmp(key_buf, "binary_threshold") == 0) cfg->binary_threshold = atol(val_buf);
        else if (strcmp(key_buf, "repo_url") == 0) { free(cfg->repo_url); cfg->repo_url = strdup_safe(val_buf); }

        line = next ? next + 1 : NULL;
    }

    free(data);
    return 0;
}

char *fetch_sources(const char *recipe_path, const char *dest_dir) {
    char cmd[8192];
    char urls[32768] = {0};

    snprintf(cmd, sizeof(cmd),
        "bash -c 'source \"%s\" 2>/dev/null; for _s in \"${source[@]}\"; do echo \"$_s\"; done' 2>/dev/null",
        recipe_path);

    FILE *fp = popen(cmd, "r");
    if (!fp) return NULL;

    int total = 0;
    char line[4096];
    int any = 0;
    while (fgets(line, sizeof(line), fp)) {
        size_t len = strlen(line);
        while (len > 0 && (line[len-1] == '\n' || line[len-1] == '\r')) line[--len] = 0;
        if (len == 0) continue;
        any = 1;

        char fname[1024];
        const char *base = strrchr(line, '/');
        if (base) base++; else base = line;
        snprintf(fname, sizeof(fname), "%s/%s", dest_dir, base);

        if (!g_flags.quiet) print_status(1, "source", base);
        if (access(fname, F_OK) != 0) {
            fetch_url(line, fname);
        } else if (g_flags.verbose) {
            print_status(1, "cached", fname);
        }

        int need = snprintf(urls + total, sizeof(urls) - (size_t)total, "%s ", fname);
        if (need > 0) total += need;
    }
    int rc = pclose(fp);
    (void)rc;

    if (!any) return NULL;
    return strdup_safe(dest_dir);
}

static void write_filelist_rec(FILE *f, const char *base, const char *rel) {
    char path[FLASH_PATH_MAX];
    snprintf(path, sizeof(path), "%s/%s", base, rel && *rel ? rel : ".");

    DIR *d = opendir(path);
    if (!d) return;

    struct dirent *de;
    while ((de = readdir(d)) != NULL) {
        if (strcmp(de->d_name, ".") == 0 || strcmp(de->d_name, "..") == 0) continue;
        char full[FLASH_PATH_MAX];
        snprintf(full, sizeof(full), "%s/%s", path, de->d_name);
        struct stat st;
        if (lstat(full, &st) < 0) continue;

        char prefix[FLASH_PATH_MAX];
        if (rel && *rel) snprintf(prefix, sizeof(prefix), "/%s/%s", rel, de->d_name);
        else snprintf(prefix, sizeof(prefix), "/%s", de->d_name);

        if (S_ISDIR(st.st_mode)) {
            fprintf(f, "%s/\n", prefix);
            char sub[FLASH_PATH_MAX];
            if (rel && *rel) snprintf(sub, sizeof(sub), "%s/%s", rel, de->d_name);
            else snprintf(sub, sizeof(sub), "%s", de->d_name);
            write_filelist_rec(f, base, sub);
        } else if (S_ISREG(st.st_mode) || S_ISLNK(st.st_mode)) {
            fprintf(f, "%s\n", prefix);
        }
    }
    closedir(d);
}

static int write_filelist(const char *pkgdir, const char *output_path) {
    FILE *f = fopen(output_path, "w");
    if (!f) return -1;
    write_filelist_rec(f, pkgdir, "");
    fclose(f);
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

        char *next = strchr(line, '\n');
        char *eq = strchr(line, '=');
        if (!eq || (next && eq > next)) { line = next ? next + 1 : NULL; continue; }

        size_t vallen;
        char key_buf[256], val_buf[2048];
        const char *kp = line;
        while (kp < eq && (*kp == ' ' || *kp == '\t')) kp++;
        size_t klen = eq - kp;
        while (klen > 0 && (kp[klen-1] == ' ' || kp[klen-1] == '\t')) klen--;
        if (klen >= sizeof(key_buf)) klen = sizeof(key_buf) - 1;
        memcpy(key_buf, kp, klen); key_buf[klen] = 0;

        const char *vp = eq + 1;
        while (*vp == ' ' || *vp == '\t') vp++;
        if (next) vallen = next - vp;
        else vallen = strlen(vp);
        while (vallen > 0 && (vp[vallen-1] == ' ' || vp[vallen-1] == '\t' ||
               vp[vallen-1] == '\n' || vp[vallen-1] == '\r')) vallen--;
        if (*vp == '"' && vallen >= 2 && vp[vallen-1] == '"') { vp++; vallen -= 2; }
        if (vallen >= sizeof(val_buf)) vallen = sizeof(val_buf) - 1;
        memcpy(val_buf, vp, vallen); val_buf[vallen] = 0;

        if (strcmp(key_buf, "name") == 0) pkg->name = strdup_safe(val_buf);
        else if (strcmp(key_buf, "version") == 0) pkg->version = strdup_safe(val_buf);
        else if (strcmp(key_buf, "release") == 0) pkg->release = atoi(val_buf);
        else if (strcmp(key_buf, "desc") == 0) pkg->desc = strdup_safe(val_buf);
        else if (strcmp(key_buf, "license") == 0) pkg->license = strdup_safe(val_buf);
        else if (strcmp(key_buf, "maintainer") == 0) pkg->maintainer = strdup_safe(val_buf);
        else if (strcmp(key_buf, "homepage") == 0) pkg->homepage = strdup_safe(val_buf);
        else if (strcmp(key_buf, "size") == 0) pkg->size = atol(val_buf);
        else if (strcmp(key_buf, "checksum") == 0) pkg->checksum = strdup_safe(val_buf);
        else if (strcmp(key_buf, "depends") == 0 || strcmp(key_buf, "build_depends") == 0) {
            int dtype = (strcmp(key_buf, "build_depends") == 0) ? 1 : 0;
            char *d = strdup_safe(val_buf);
            if (d) {
                /* Skip empty () or ( arrays */
                char *dt = d;
                while (*dt == ' ' || *dt == '\t') dt++;
                if (*dt != '(') {
                char *dpstart = d;
                while (dpstart && *dpstart) {
                    while (*dpstart == ' ' || *dpstart == ',') dpstart++;
                    if (!*dpstart) break;
                    char *end = strchr(dpstart, ',');
                    if (end) *end = 0;
                    char *space = strchr(dpstart, ' ');
                    if (*ndeps >= depcap) {
                        depcap = depcap ? depcap * 2 : 8;
                        *deps = realloc(*deps, sizeof(Dependency) * depcap);
                    }
                    Dependency *dp = &(*deps)[*ndeps];
                    memset(dp, 0, sizeof(Dependency));
                    dp->type = dtype;
                    if (space) {
                        *space = 0;
                        dp->name = strdup_safe(dpstart);
                        dp->constraint = strdup_safe(space + 1);
                    } else {
                        dp->name = strdup_safe(dpstart);
                    }
                    (*ndeps)++;
                    if (end) dpstart = end + 1;
                    else break;
                }
                }
                free(d);
            }
        }

        line = next ? next + 1 : NULL;
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

static int generate_build_script(const char *script_path, const char *recipe_path,
                                  const char *build_dir, const char *name, const char *version) {
    char *recipe_data = read_file(recipe_path);
    if (!recipe_data) { warn("Cannot read recipe: %s", recipe_path); return -1; }

    int has_prepare = (strstr(recipe_data, "prepare()") != NULL) ||
                      (strstr(recipe_data, "prepare (") != NULL);
    int has_build = (strstr(recipe_data, "build()") != NULL) ||
                    (strstr(recipe_data, "build (") != NULL);
    int has_install = (strstr(recipe_data, "install()") != NULL) ||
                      (strstr(recipe_data, "install (") != NULL);
    int has_check = (strstr(recipe_data, "check()") != NULL) ||
                    (strstr(recipe_data, "check (") != NULL);
    free(recipe_data);

    int use_sandbox = g_config.sandbox;
    const char *base = use_sandbox ? "/build" : build_dir;
    const char *src_sub = "/src";
    const char *pkg_sub = "/pkgdir";

    FILE *f = fopen(script_path, "w");
    if (!f) { warn("Cannot write build script: %s", script_path); return -1; }

    fprintf(f, "#!/bin/bash -e\n");
    fprintf(f, "# flash build script for %s-%s\n", name, version);
    fprintf(f, "export srcdir=\"%s%s\"\n", base, src_sub);
    fprintf(f, "export pkgdir=\"%s%s\"\n", base, pkg_sub);
    fprintf(f, "export scriptdir=\"%s\"\n", base);
    fprintf(f, "export version=\"%s\"\n", version);
    fprintf(f, "mkdir -p \"$srcdir\" \"$pkgdir\"\n");
    fprintf(f, "source \"%s/recipe.sh\"\n", base);
    fprintf(f, "cd \"$srcdir\"\n");
    fprintf(f, "echo \"==> Preparing build dir...\"\n");

    if (has_prepare) {
        fprintf(f, "echo \"==> Preparing %s...\"\n", name);
        fprintf(f, "prepare 2>&1 | tee -a %s/build.log\n", base);
    }
    if (has_build) {
        fprintf(f, "echo \"==> Building %s...\"\n", name);
        fprintf(f, "cd \"$srcdir\"\n");
        fprintf(f, "build 2>&1 | tee -a %s/build.log\n", base);
    }
    if (has_install) {
        fprintf(f, "echo \"==> Installing %s...\"\n", name);
        fprintf(f, "cd \"$srcdir\"\n");
        fprintf(f, "install 2>&1 | tee -a %s/build.log\n", base);
    }
    if (has_check) {
        fprintf(f, "echo \"==> Checking %s...\"\n", name);
        fprintf(f, "cd \"$srcdir\"\n");
        fprintf(f, "check 2>&1 | tee -a %s/build.log\n", base);
    }

    fprintf(f, "echo \"==> Build complete: %s-%s\"\n", name, version);
    fclose(f);
    chmod(script_path, 0755);
    return 0;
}

static int copy_file_to(const char *src, const char *dst) {
    char *data = read_file(src);
    if (!data) return -1;
    int ret = write_file(dst, data);
    free(data);
    return ret;
}

int cmd_make(int argc, char **argv) {
    if (argc == 0) { warn("No recipe specified"); return 1; }
    for (int i = 0; i < argc; i++) {
        Package pkg;
        Dependency *deps = NULL;
        int ndeps = 0;
        char build_dir[FLASH_PATH_MAX], recipe_dest[FLASH_PATH_MAX];
        char script_path[FLASH_PATH_MAX], pkgdir_path[FLASH_PATH_MAX];
        char pkg_cache_path[FLASH_PATH_MAX], hash[65];
        char filelist_path[FLASH_PATH_MAX], recipe_path[FLASH_PATH_MAX];
        int ret, allow_network, has_sources = 0;

        struct stat rst;
        if (stat(argv[i], &rst) == 0 && S_ISDIR(rst.st_mode)) {
            snprintf(recipe_path, sizeof(recipe_path), "%s/recipe.sh", argv[i]);
        } else {
            snprintf(recipe_path, sizeof(recipe_path), "%s", argv[i]);
        }

        if (recipe_parse(recipe_path, &pkg, &deps, &ndeps) != 0) {
            warn("Cannot parse recipe: %s", argv[i]);
            continue;
        }
        if (!pkg.name || !pkg.version) {
            warn("Recipe %s missing name or version", argv[i]);
            goto make_cleanup;
        }

        if (!g_flags.quiet) print_status(1, "make", pkg.name);

        /* Build build dependencies first */
        for (int j = 0; j < ndeps; j++) {
            if (deps[j].type != 1) continue;
            char dep_recipe[FLASH_PATH_MAX];
            snprintf(dep_recipe, sizeof(dep_recipe), "%s/%s/recipe.sh",
                     g_config.recipes_dir, deps[j].name);
            if (access(dep_recipe, F_OK) != 0) {
                warn("Dependency recipe not found: %s", dep_recipe);
                goto make_cleanup;
            }
            if (db_open() == 0 && db_package_exists(deps[j].name)) {
                if (g_flags.verbose) print_status(1, "dep-ok", deps[j].name);
            } else {
                if (!g_flags.quiet) print_status(1, "dep", deps[j].name);
                int argc2 = 1;
                char *argv2[] = { dep_recipe };
                if (cmd_make(argc2, argv2) != 0) {
                    warn("Dependency build failed: %s", deps[j].name);
                    goto make_cleanup;
                }
            }
        }

        snprintf(build_dir, sizeof(build_dir), "%s/%s-%s", g_config.build_dir, pkg.name, pkg.version);
        mkdir_p(build_dir);

        snprintf(recipe_dest, sizeof(recipe_dest), "%s/recipe.sh", build_dir);
        if (copy_file_to(recipe_path, recipe_dest) != 0) {
            warn("Cannot copy recipe to build dir");
            goto make_cleanup;
        }

        /* Check for source=() in recipe */
        char *recipe_data = read_file(recipe_path);
        if (recipe_data) {
            if (strstr(recipe_data, "source=(")) has_sources = 1;
            free(recipe_data);
        }

        /* Fetch sources before sandbox */
        char *src_dir = NULL;
        if (has_sources) {
            char src_cache[FLASH_PATH_MAX];
            snprintf(src_cache, sizeof(src_cache), "%s/src_cache", build_dir);
            mkdir_p(src_cache);
            src_dir = fetch_sources(recipe_dest, src_cache);
        }

        snprintf(script_path, sizeof(script_path), "%s/.flash_build.sh", build_dir);
        if (generate_build_script(script_path, recipe_path, build_dir, pkg.name, pkg.version) != 0) {
            warn("Cannot generate build script");
            free(src_dir);
            goto make_cleanup;
        }

        allow_network = !g_config.sandbox;
        if (!has_sources && !allow_network) {
            allow_network = 0;
        }

        ret = sandbox_build(recipe_dest, build_dir, allow_network, src_dir);
        free(src_dir);
        if (ret != 0) {
            warn("Build failed for %s (exit %d)", pkg.name, ret);
            goto make_cleanup;
        }

        snprintf(pkgdir_path, sizeof(pkgdir_path), "%s/pkgdir", build_dir);
        if (access(pkgdir_path, F_OK) != 0) {
            warn("pkgdir not found after build: %s", pkgdir_path);
            goto make_cleanup;
        }

        snprintf(pkg_cache_path, sizeof(pkg_cache_path), "%s/%s-%s.tar.zst",
                 g_config.cache_dir, pkg.name, pkg.version);
        mkdir_p(g_config.cache_dir);
        archive_create(pkgdir_path, pkg_cache_path, NULL, 0);

        /* Generate .files manifest */
        snprintf(filelist_path, sizeof(filelist_path), "%s/%s-%s.files",
                 g_config.cache_dir, pkg.name, pkg.version);
        write_filelist(pkgdir_path, filelist_path);

        if (g_config.sign) crypto_sign(pkg_cache_path, NULL);

        if (crypto_checksum(pkg_cache_path, hash, sizeof(hash)) == 0) {
            free(pkg.checksum);
            pkg.checksum = strdup_safe(hash);
        }

        if (db_open() == 0) {
            db_package_insert(&pkg);
            /* Register dependencies in DB */
            for (int j = 0; j < ndeps; j++) {
                db_depends_insert(pkg.name, &deps[j]);
            }
            db_transaction_log("make", pkg.name, pkg.version);
            /* Register files in DB */
            char *fdata = read_file(filelist_path);
            if (fdata) {
                char *fl = fdata, *fnl;
                while ((fnl = strchr(fl, '\n')) != NULL) {
                    *fnl = 0;
                    if (*fl) db_file_insert(pkg.name, fl);
                    fl = fnl + 1;
                }
                free(fdata);
            }
        }

        if (!g_flags.quiet) print_status(1, "built", pkg.name);

    make_cleanup:
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
        if (g_flags.dry_run) { printf("Would clean %s\n", g_config.cache_dir); return 0; }
        if (!confirm("Clean package cache?")) return 1;
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
        else if (strcmp(key, "db") == 0 || strcmp(key, "db_path") == 0) { free(g_config.db_path); g_config.db_path = strdup_safe(val); }
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

    /* Quiet initial load; --config flag overrides later */
    {
        char *old = read_file(FLASH_CONF_PATH);
        if (old) { free(old); config_load(FLASH_CONF_PATH, &g_config); }
        else config_default(&g_config);
    }

    int nargs = parse_flags(argc, argv, &g_flags);
    if (nargs < 2) { print_usage(); return 1; }

    Command cmd = command_from_string(argv[1]);
    int ret = dispatch(cmd, nargs - 2, argv + 2);

    db_close();
    return ret;
}
