#include "flash.h"

static int run_install_script(const char *root, const char *script, const char *pkg_name) {
    if (access(script, F_OK) != 0) return 0;
    if (g_flags.dry_run) { printf("Would run: %s\n", script); return 0; }
    pid_t pid = fork();
    if (pid == 0) {
        if (root && *root) { int rc2 = chroot(root); (void)rc2; }
        { int rc3 = chdir("/"); (void)rc3; }
        setenv("PKG_NAME", pkg_name, 1);
        execl("/bin/sh", "sh", script, NULL);
        _exit(127);
    }
    int status;
    waitpid(pid, &status, 0);
    return WIFEXITED(status) ? WEXITSTATUS(status) : -1;
}

static int copy_file(const char *src, const char *dst) {
    int sfd = open(src, O_RDONLY);
    if (sfd < 0) return -1;
    int dfd = open(dst, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (dfd < 0) { close(sfd); return -1; }
    char buf[65536];
    ssize_t n;
    while ((n = read(sfd, buf, sizeof(buf))) > 0) {
        if (write(dfd, buf, (size_t)n) != n) { close(sfd); close(dfd); return -1; }
    }
    close(sfd); close(dfd);
    return 0;
}

static int install_source(const char *name, const char *version, const char *cache_path) {
    char build_dir[FLASH_PATH_MAX];
    snprintf(build_dir, sizeof(build_dir), "%s/%s-%s", g_config.build_dir, name, version);
    mkdir_p(build_dir);

    char recipe_path[FLASH_PATH_MAX];
    snprintf(recipe_path, sizeof(recipe_path), "%s/%s/recipe.sh", g_config.recipes_dir, name);

    if (g_flags.dry_run) {
        printf("Would build %s from source in %s\n", name, build_dir);
        return 0;
    }

    if (g_flags.verbose) print_status(1, "build", name);

    char build_script[FLASH_PATH_MAX];
    snprintf(build_script, sizeof(build_script), "%s/.flash_build.sh", build_dir);

    Package pkg;
    if (db_package_get(name, &pkg) == 0) {
        free(pkg.name); free(pkg.version); free(pkg.desc);
        free(pkg.license); free(pkg.maintainer); free(pkg.homepage);
        free(pkg.checksum);
    }

    int ret = archive_extract(cache_path, build_dir);
    if (ret != 0) { warn("Extract failed for %s", name); return -1; }

    int allow_network = 0;
    char *recipe_data = read_file(recipe_path);
    if (recipe_data && strstr(recipe_data, "network = true")) allow_network = 1;
    free(recipe_data);

    ret = sandbox_build(recipe_path, build_dir, allow_network, NULL);
    if (ret != 0) { warn("Build failed for %s (exit %d)", name, ret); return -1; }

    char install_dir[FLASH_PATH_MAX];
    snprintf(install_dir, sizeof(install_dir), "%s/.flash_install", build_dir);
    mkdir_p(install_dir);

    char pkg_cache[FLASH_PATH_MAX];
    snprintf(pkg_cache, sizeof(pkg_cache), "%s/%s-%s.tar.zst", g_config.cache_dir, name, version);
    archive_create(install_dir, pkg_cache, NULL, 0);

    char iroot[FLASH_PATH_MAX];
    snprintf(iroot, sizeof(iroot), "%s/", g_config.root ? g_config.root : "");
    ret = archive_extract(pkg_cache, iroot);
    if (ret != 0) { warn("Install extract failed for %s", name); return -1; }

    char install_script[FLASH_PATH_MAX];
    snprintf(install_script, sizeof(install_script), "%s/.INSTALL", build_dir);
    run_install_script(g_config.root, install_script, name);

    if (g_flags.verbose) print_status(1, "installed", name);
    return 0;
}

static int install_binary(const char *name, const char *version, const char *cache_path) {
    (void)version;
    char sig_path[FLASH_PATH_MAX];
    snprintf(sig_path, sizeof(sig_path), "%s.sig", cache_path);

    if (access(sig_path, F_OK) == 0) {
        if (crypto_verify(cache_path, sig_path, g_config.keyring) != 0) {
            warn("Signature verification failed for %s", name);
            if (!g_flags.force) return -1;
        }
    }

    char root[FLASH_PATH_MAX];
    snprintf(root, sizeof(root), "%s/", g_config.root ? g_config.root : "");
    int ret = archive_extract(cache_path, root);
    if (ret != 0) { warn("Extract failed for %s", name); return -1; }

    char install_script[FLASH_PATH_MAX];
    snprintf(install_script, sizeof(install_script), "%s/.INSTALL", root);
    run_install_script(g_config.root, install_script, name);

    if (g_flags.verbose) print_status(1, "installed", name);
    return 0;
}

static int install_parts(const char *name, const char *version) {
    char parts_dir[FLASH_PATH_MAX];
    snprintf(parts_dir, sizeof(parts_dir), "%s/%s-%s-parts", g_config.cache_dir, name, version);
    mkdir_p(parts_dir);

    char assembly_dir[FLASH_PATH_MAX];
    snprintf(assembly_dir, sizeof(assembly_dir), "%s/%s-%s-assembly", g_config.cache_dir, name, version);
    mkdir_p(assembly_dir);

    for (int i = 0; ; i++) {
        char part_path[FLASH_PATH_MAX];
        snprintf(part_path, sizeof(part_path), "%s/%s.part.%d.tar.zst", parts_dir, name, i);
        if (access(part_path, F_OK) != 0) break;

        if (g_flags.verbose) print_status(1, "part", part_path);
        int ret = archive_extract(part_path, assembly_dir);
        if (ret != 0) { warn("Part extraction failed for %s.%d", name, i); return -1; }
    }

    char root[FLASH_PATH_MAX];
    snprintf(root, sizeof(root), "%s/", g_config.root ? g_config.root : "");

    DIR *d = opendir(assembly_dir);
    if (!d) return -1;
    struct dirent *de;
    while ((de = readdir(d)) != NULL) {
        if (de->d_name[0] == '.') continue;
        char src[FLASH_PATH_MAX], dst[FLASH_PATH_MAX];
        snprintf(src, sizeof(src), "%s/%s", assembly_dir, de->d_name);
        snprintf(dst, sizeof(dst), "%s/%s", root, de->d_name);
        struct stat st;
        if (lstat(src, &st) < 0) continue;
        if (S_ISLNK(st.st_mode)) {
            char target[FLASH_PATH_MAX];
            ssize_t n = readlink(src, target, sizeof(target)-1);
            if (n >= 0) { target[n] = 0; int rc4 = symlink(target, dst); (void)rc4; }
        } else if (S_ISREG(st.st_mode)) {
            copy_file(src, dst);
        } else if (S_ISDIR(st.st_mode)) {
            mkdir_p(dst);
        }
    }
    closedir(d);

    char install_script[FLASH_PATH_MAX];
    snprintf(install_script, sizeof(install_script), "%s/.INSTALL", root);
    run_install_script(g_config.root, install_script, name);

    if (g_flags.verbose) print_status(1, "installed", name);
    return 0;
}

int cmd_install(int argc, char **argv) {
    if (argc == 0) { warn("No packages specified"); return 1; }

    if (db_open() != 0) return -1;

    for (int i = 0; i < argc; i++) {
        char *pkg_name = argv[i];
        char *version = NULL;
        char *con = strchr(pkg_name, '=');
        if (con) {
            *con = 0;
            version = con + 1;
            if (*version == '=') version++;
        }

        if (db_is_held(pkg_name) && !g_flags.force) {
            warn("%s is held, skipping. Use --force to override.", pkg_name);
            continue;
        }

        if (!g_flags.quiet) print_status(1, "install", pkg_name);

        Package **deps;
        int ndeps;
        resolve_dependencies(pkg_name, version, &deps, &ndeps);

        for (int j = 0; j < ndeps; j++) {
            Package *dep = deps[j];
            if (db_package_exists(dep->name)) {
                if (g_flags.verbose) print_status(1, "already", dep->name);
                continue;
            }

            int tier = TIER_BINARY;
            char url[4096];
            char cache_file[4096];

            if (dep->size > 0) tier_determine(dep->size, &tier);

            switch (tier) {
                case TIER_SOURCE:
                    snprintf(url, sizeof(url), "%s/source/%s/%s-%s.tar.zst",
                             g_config.repo_url, dep->name, dep->name, dep->version);
                    snprintf(cache_file, sizeof(cache_file), "%s/%s-%s.tar.zst",
                             g_config.cache_dir, dep->name, dep->version);
                    break;
                case TIER_BINARY:
                    snprintf(url, sizeof(url), "%s/binary/%s/%s-%s.tar.zst",
                             g_config.repo_url, dep->name, dep->name, dep->version);
                    snprintf(cache_file, sizeof(cache_file), "%s/%s-%s.tar.zst",
                             g_config.cache_dir, dep->name, dep->version);
                    break;
                case TIER_PARTS:
                    snprintf(url, sizeof(url), "%s/parts/%s/%s.part.0.tar.zst",
                             g_config.repo_url, dep->name, dep->name);
                    snprintf(cache_file, sizeof(cache_file), "%s/%s-%s.part.0.tar.zst",
                             g_config.cache_dir, dep->name, dep->version);
                    break;
            }

            if (access(cache_file, F_OK) != 0) {
                if (g_flags.dry_run) {
                    printf("Would fetch: %s\n", url);
                    continue;
                }
                mkdir_p(g_config.cache_dir);
                if (fetch_url(url, cache_file) != 0) {
                    warn("Failed to fetch %s", url);
                    continue;
                }
            }

            switch (tier) {
                case TIER_SOURCE:
                    install_source(dep->name, dep->version, cache_file);
                    break;
                case TIER_BINARY:
                    install_binary(dep->name, dep->version, cache_file);
                    break;
                case TIER_PARTS:
                    install_parts(dep->name, dep->version);
                    break;
            }

            db_package_insert(dep);

            char filelist_path[4096];
            snprintf(filelist_path, sizeof(filelist_path), "%s/%s-%s.files",
                     g_config.cache_dir, dep->name, dep->version);
            char *files_data = read_file(filelist_path);
            if (files_data) {
                char *line = files_data;
                char *nl;
                while ((nl = strchr(line, '\n')) != NULL) {
                    *nl = 0;
                    db_file_insert(dep->name, line);
                    line = nl + 1;
                }
                free(files_data);
            }

            db_transaction_log("install", dep->name, dep->version);
            free(dep);
        }
        free(deps);

        if (con) *con = '=';
    }

    return 0;
}
