#ifndef FLASH_H
#define FLASH_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <stdint.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sqlite3.h>
#include <archive.h>
#include <archive_entry.h>
#include <gpgme.h>
#include <pthread.h>
#include <errno.h>
#include <dirent.h>
#include <fcntl.h>
#include <libgen.h>
#include <ctype.h>
#include <signal.h>
#include <sys/wait.h>

#define FLASH_VERSION "1.0.0"
#define FLASH_DB_PATH "/var/lib/flash/flash.db"
#define FLASH_CONF_PATH "/etc/flash/flash.conf"
#define FLASH_CACHE_DIR "/var/cache/flash"
#define FLASH_BUILD_DIR "/var/tmp/flash-build"
#define FLASH_RECIPES_DIR "/var/lib/flash/recipes"
#define FLASH_KEYRING "/etc/flash/keyring"
#define FLASH_REPO_URL "https://repo.hydralinux.org/flash"

#define TIER_SOURCE 0
#define TIER_BINARY 1
#define TIER_PARTS 2

#define COLOR_RESET "\033[0m"
#define COLOR_RED "\033[1;31m"
#define COLOR_GREEN "\033[1;32m"
#define COLOR_YELLOW "\033[1;33m"
#define COLOR_BLUE "\033[1;34m"
#define COLOR_MAGENTA "\033[1;35m"
#define COLOR_CYAN "\033[1;36m"

typedef struct {
    char *name;
    char *version;
    int release;
    char *desc;
    char *license;
    char *maintainer;
    char *homepage;
    char **depends;
    int ndepends;
    long size;
    char *checksum;
} Package;

typedef struct {
    char *name;
    char *version;
    char *constraint;
    int type;
} Dependency;

typedef struct {
    char *root;
    char *db_path;
    char *cache_dir;
    char *build_dir;
    char *recipes_dir;
    char *keyring;
    int sandbox;
    int jobs;
    int sign;
    long source_threshold;
    long binary_threshold;
    char *repo_url;
} Config;

typedef enum {
    CMD_INSTALL, CMD_RM, CMD_UPDATE, CMD_FIND, CMD_INFO, CMD_LIST,
    CMD_CONTENTS, CMD_FIND_OWNER, CMD_MAKE, CMD_AUDIT, CMD_CACHE,
    CMD_CONFIG, CMD_SYNC, CMD_REVERT, CMD_FREEZE, CMD_UNFREEZE,
    CMD_REBUILD, CMD_HELP
} Command;

typedef struct {
    int agree;
    int dry_run;
    int force;
    int quiet;
    int verbose;
    int json;
    char *root;
} Flags;

extern Flags g_flags;
extern Config g_config;

void print_colored(const char *color, const char *fmt, ...);
void print_progress(long current, long total, const char *label);
void print_status(int success, const char *label, const char *fmt, ...);
char *read_file(const char *path);
int write_file(const char *path, const char *data);
char *strjoin(const char *a, const char *b);
void die(const char *fmt, ...);
void warn(const char *fmt, ...);
int confirm(const char *prompt);
long file_size(const char *path);
int mkdir_p(const char *path);
char *path_join(const char *a, const char *b);
char *strdup_safe(const char *s);
int strstart(const char *str, const char *prefix);

int parse_flags(int argc, char **argv, Flags *flags);
Command command_from_string(const char *str);
void print_usage(void);
void print_version(void);

int cmd_install(int argc, char **argv);
int cmd_remove(int argc, char **argv);
int cmd_update(int argc, char **argv);
int cmd_find(int argc, char **argv);
int cmd_info(int argc, char **argv);
int cmd_list(int argc, char **argv);
int cmd_contents(int argc, char **argv);
int cmd_find_owner(int argc, char **argv);
int cmd_make(int argc, char **argv);
int cmd_audit(int argc, char **argv);
int cmd_cache(int argc, char **argv);
int cmd_config(int argc, char **argv);
int cmd_sync(int argc, char **argv);
int cmd_revert(int argc, char **argv);
int cmd_freeze(int argc, char **argv);
int cmd_unfreeze(int argc, char **argv);
int cmd_rebuild(int argc, char **argv);
int cmd_help(int argc, char **argv);

int resolve_dependencies(const char *pkg_name, const char *version_constraint,
                         Package ***result, int *nresult);

int db_open(void);
int db_init(void);
int db_package_insert(Package *pkg);
int db_package_remove(const char *name);
int db_package_find(const char *query, Package **result, int *nresult);
int db_package_get(const char *name, Package *pkg);
int db_file_insert(const char *pkg_name, const char *path);
int db_file_remove(const char *pkg_name);
int db_file_remove_single(const char *pkg_name, const char *path);
int db_find_owner(const char *path, char **pkg_name);
int db_list_all(Package ***result, int *nresult);
int db_holds_list(char ***names, int *nnames);
int db_hold_add(const char *name);
int db_hold_remove(const char *name);
int db_is_held(const char *name);
int db_transaction_log(const char *action, const char *pkg, const char *version);
int db_files_list(const char *pkg_name, char ***files, int *nfiles);
int db_depends_insert(const char *pkg_name, Dependency *dep);
int db_package_exists(const char *name);
void db_close(void);
extern sqlite3 *g_db;

int vercmp(const char *a, const char *b);

int sandbox_build(const char *recipe_path, const char *build_dir, int allow_network);

int archive_extract(const char *path, const char *destdir);
int archive_create(const char *srcdir, const char *output_path, char **excludes, int nexcludes);
int archive_list(const char *path);

int crypto_verify(const char *path, const char *sig_path, const char *keyring);
int crypto_sign(const char *path, const char *key_id);
int crypto_checksum(const char *path, char *out_hash, size_t outlen);

int tier_determine(long size_bytes, int *tier);
int fetch_url(const char *url, const char *dest);
int recipe_parse(const char *recipe_path, Package *pkg, Dependency **deps, int *ndeps);
int config_load(const char *path, Config *cfg);
int config_default(Config *cfg);

#endif
