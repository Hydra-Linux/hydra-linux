#include "flash.h"

sqlite3 *g_db = NULL;

int db_open(void) {
    if (g_db) return 0;
    const char *path = g_config.db_path ? g_config.db_path : FLASH_DB_PATH;
    int rc = sqlite3_open(path, &g_db);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "Cannot open database: %s\n", sqlite3_errmsg(g_db));
        return -1;
    }
    sqlite3_exec(g_db, "PRAGMA journal_mode=WAL;", NULL, NULL, NULL);
    sqlite3_exec(g_db, "PRAGMA foreign_keys=ON;", NULL, NULL, NULL);
    return db_init();
}

int db_init(void) {
    const char *sql =
        "CREATE TABLE IF NOT EXISTS packages ("
        "  name TEXT PRIMARY KEY,"
        "  version TEXT NOT NULL,"
        "  release INTEGER DEFAULT 0,"
        "  desc TEXT,"
        "  license TEXT,"
        "  maintainer TEXT,"
        "  homepage TEXT,"
        "  size INTEGER DEFAULT 0,"
        "  checksum TEXT"
        ");"
        "CREATE TABLE IF NOT EXISTS files ("
        "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  package TEXT NOT NULL REFERENCES packages(name) ON DELETE CASCADE,"
        "  path TEXT NOT NULL UNIQUE"
        ");"
        "CREATE TABLE IF NOT EXISTS dependencies ("
        "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  package TEXT NOT NULL REFERENCES packages(name) ON DELETE CASCADE,"
        "  dep_name TEXT NOT NULL,"
        "  dep_constraint TEXT,"
        "  dep_type INTEGER DEFAULT 0"
        ");"
        "CREATE TABLE IF NOT EXISTS holds ("
        "  package TEXT PRIMARY KEY"
        ");"
        "CREATE TABLE IF NOT EXISTS transaction_log ("
        "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,"
        "  action TEXT,"
        "  package TEXT,"
        "  version TEXT"
        ");"
        "CREATE INDEX IF NOT EXISTS idx_files_package ON files(package);"
        "CREATE INDEX IF NOT EXISTS idx_files_path ON files(path);";
    char *err = NULL;
    if (sqlite3_exec(g_db, sql, NULL, NULL, &err) != SQLITE_OK) {
        fprintf(stderr, "DB init error: %s\n", err);
        sqlite3_free(err);
        return -1;
    }
    return 0;
}

int db_package_insert(Package *pkg) {
    if (!pkg || !pkg->name) return -1;
    sqlite3_stmt *stmt;
    const char *sql = "INSERT OR REPLACE INTO packages "
        "(name, version, release, desc, license, maintainer, homepage, size, checksum) "
        "VALUES (?1,?2,?3,?4,?5,?6,?7,?8,?9)";
    if (sqlite3_prepare_v2(g_db, sql, -1, &stmt, NULL) != SQLITE_OK) return -1;
    sqlite3_bind_text(stmt, 1, pkg->name, -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 2, pkg->version ? pkg->version : "0", -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(stmt, 3, pkg->release);
    sqlite3_bind_text(stmt, 4, pkg->desc, -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 5, pkg->license, -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 6, pkg->maintainer, -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 7, pkg->homepage, -1, SQLITE_TRANSIENT);
    sqlite3_bind_int64(stmt, 8, pkg->size);
    sqlite3_bind_text(stmt, 9, pkg->checksum, -1, SQLITE_TRANSIENT);
    int rc = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    return rc == SQLITE_DONE ? 0 : -1;
}

int db_package_remove(const char *name) {
    sqlite3_stmt *stmt;
    const char *sql = "DELETE FROM packages WHERE name = ?1";
    if (sqlite3_prepare_v2(g_db, sql, -1, &stmt, NULL) != SQLITE_OK) return -1;
    sqlite3_bind_text(stmt, 1, name, -1, SQLITE_TRANSIENT);
    int rc = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    return rc == SQLITE_DONE ? 0 : -1;
}

int db_package_get(const char *name, Package *pkg) {
    memset(pkg, 0, sizeof(Package));
    sqlite3_stmt *stmt;
    const char *sql = "SELECT name, version, release, desc, license, maintainer, "
        "homepage, size, checksum FROM packages WHERE name = ?1";
    if (sqlite3_prepare_v2(g_db, sql, -1, &stmt, NULL) != SQLITE_OK) return -1;
    sqlite3_bind_text(stmt, 1, name, -1, SQLITE_TRANSIENT);
    int rc = sqlite3_step(stmt);
    if (rc != SQLITE_ROW) { sqlite3_finalize(stmt); return -1; }
    pkg->name = strdup_safe((const char *)sqlite3_column_text(stmt, 0));
    pkg->version = strdup_safe((const char *)sqlite3_column_text(stmt, 1));
    pkg->release = sqlite3_column_int(stmt, 2);
    pkg->desc = strdup_safe((const char *)sqlite3_column_text(stmt, 3));
    pkg->license = strdup_safe((const char *)sqlite3_column_text(stmt, 4));
    pkg->maintainer = strdup_safe((const char *)sqlite3_column_text(stmt, 5));
    pkg->homepage = strdup_safe((const char *)sqlite3_column_text(stmt, 6));
    pkg->size = (long)sqlite3_column_int64(stmt, 7);
    pkg->checksum = strdup_safe((const char *)sqlite3_column_text(stmt, 8));
    sqlite3_finalize(stmt);
    return 0;
}

int db_package_find(const char *query, Package **result, int *nresult) {
    *result = NULL;
    *nresult = 0;
    sqlite3_stmt *stmt;
    char sql[512];
    snprintf(sql, sizeof(sql),
        "SELECT name, version, release, desc, license, maintainer, homepage, size, checksum "
        "FROM packages WHERE name LIKE '%%%s%%' OR desc LIKE '%%%s%%'", query, query);
    if (sqlite3_prepare_v2(g_db, sql, -1, &stmt, NULL) != SQLITE_OK) return -1;
    int cap = 16;
    *result = malloc(sizeof(Package) * cap);
    int n = 0;
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        if (n >= cap) {
            cap *= 2;
            *result = realloc(*result, sizeof(Package) * cap);
        }
        Package *p = &(*result)[n++];
        memset(p, 0, sizeof(Package));
        p->name = strdup_safe((const char *)sqlite3_column_text(stmt, 0));
        p->version = strdup_safe((const char *)sqlite3_column_text(stmt, 1));
        p->release = sqlite3_column_int(stmt, 2);
        p->desc = strdup_safe((const char *)sqlite3_column_text(stmt, 3));
        p->license = strdup_safe((const char *)sqlite3_column_text(stmt, 4));
        p->maintainer = strdup_safe((const char *)sqlite3_column_text(stmt, 5));
        p->homepage = strdup_safe((const char *)sqlite3_column_text(stmt, 6));
        p->size = (long)sqlite3_column_int64(stmt, 7);
        p->checksum = strdup_safe((const char *)sqlite3_column_text(stmt, 8));
    }
    sqlite3_finalize(stmt);
    *nresult = n;
    return 0;
}

int db_file_insert(const char *pkg_name, const char *path) {
    sqlite3_stmt *stmt;
    const char *sql = "INSERT OR IGNORE INTO files (package, path) VALUES (?1, ?2)";
    if (sqlite3_prepare_v2(g_db, sql, -1, &stmt, NULL) != SQLITE_OK) return -1;
    sqlite3_bind_text(stmt, 1, pkg_name, -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 2, path, -1, SQLITE_TRANSIENT);
    int rc = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    return rc == SQLITE_DONE ? 0 : -1;
}

int db_file_remove(const char *pkg_name) {
    sqlite3_stmt *stmt;
    const char *sql = "DELETE FROM files WHERE package = ?1";
    if (sqlite3_prepare_v2(g_db, sql, -1, &stmt, NULL) != SQLITE_OK) return -1;
    sqlite3_bind_text(stmt, 1, pkg_name, -1, SQLITE_TRANSIENT);
    int rc = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    return rc == SQLITE_DONE ? 0 : -1;
}

int db_file_remove_single(const char *pkg_name, const char *path) {
    sqlite3_stmt *stmt;
    const char *sql = "DELETE FROM files WHERE package = ?1 AND path = ?2";
    if (sqlite3_prepare_v2(g_db, sql, -1, &stmt, NULL) != SQLITE_OK) return -1;
    sqlite3_bind_text(stmt, 1, pkg_name, -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 2, path, -1, SQLITE_TRANSIENT);
    int rc = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    return rc == SQLITE_DONE ? 0 : -1;
}

int db_find_owner(const char *path, char **pkg_name) {
    *pkg_name = NULL;
    sqlite3_stmt *stmt;
    const char *sql = "SELECT package FROM files WHERE path = ?1";
    if (sqlite3_prepare_v2(g_db, sql, -1, &stmt, NULL) != SQLITE_OK) return -1;
    sqlite3_bind_text(stmt, 1, path, -1, SQLITE_TRANSIENT);
    int rc = sqlite3_step(stmt);
    if (rc != SQLITE_ROW) { sqlite3_finalize(stmt); return -1; }
    *pkg_name = strdup_safe((const char *)sqlite3_column_text(stmt, 0));
    sqlite3_finalize(stmt);
    return 0;
}

int db_files_list(const char *pkg_name, char ***files, int *nfiles) {
    *files = NULL;
    *nfiles = 0;
    sqlite3_stmt *stmt;
    const char *sql = "SELECT path FROM files WHERE package = ?1 ORDER BY path";
    if (sqlite3_prepare_v2(g_db, sql, -1, &stmt, NULL) != SQLITE_OK) return -1;
    sqlite3_bind_text(stmt, 1, pkg_name, -1, SQLITE_TRANSIENT);
    int cap = 64;
    *files = malloc(sizeof(char *) * cap);
    int n = 0;
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        if (n >= cap) { cap *= 2; *files = realloc(*files, sizeof(char *) * cap); }
        (*files)[n++] = strdup_safe((const char *)sqlite3_column_text(stmt, 0));
    }
    sqlite3_finalize(stmt);
    *nfiles = n;
    return 0;
}

int db_list_all(Package ***result, int *nresult) {
    *result = NULL;
    *nresult = 0;
    sqlite3_stmt *stmt;
    const char *sql = "SELECT name, version, release, desc, license, maintainer, "
        "homepage, size, checksum FROM packages ORDER BY name";
    if (sqlite3_prepare_v2(g_db, sql, -1, &stmt, NULL) != SQLITE_OK) return -1;
    int cap = 64;
    *result = malloc(sizeof(Package *) * cap);
    int n = 0;
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        if (n >= cap) { cap *= 2; *result = realloc(*result, sizeof(Package *) * cap); }
        Package *p = calloc(1, sizeof(Package));
        p->name = strdup_safe((const char *)sqlite3_column_text(stmt, 0));
        p->version = strdup_safe((const char *)sqlite3_column_text(stmt, 1));
        p->release = sqlite3_column_int(stmt, 2);
        p->desc = strdup_safe((const char *)sqlite3_column_text(stmt, 3));
        p->license = strdup_safe((const char *)sqlite3_column_text(stmt, 4));
        p->maintainer = strdup_safe((const char *)sqlite3_column_text(stmt, 5));
        p->homepage = strdup_safe((const char *)sqlite3_column_text(stmt, 6));
        p->size = (long)sqlite3_column_int64(stmt, 7);
        p->checksum = strdup_safe((const char *)sqlite3_column_text(stmt, 8));
        (*result)[n++] = p;
    }
    sqlite3_finalize(stmt);
    *nresult = n;
    return 0;
}

int db_depends_insert(const char *pkg_name, Dependency *dep) {
    sqlite3_stmt *stmt;
    const char *sql = "INSERT INTO dependencies (package, dep_name, dep_constraint, dep_type) "
        "VALUES (?1,?2,?3,?4)";
    if (sqlite3_prepare_v2(g_db, sql, -1, &stmt, NULL) != SQLITE_OK) return -1;
    sqlite3_bind_text(stmt, 1, pkg_name, -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 2, dep->name, -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 3, dep->constraint, -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(stmt, 4, dep->type);
    int rc = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    return rc == SQLITE_DONE ? 0 : -1;
}

int db_holds_list(char ***names, int *nnames) {
    *names = NULL;
    *nnames = 0;
    sqlite3_stmt *stmt;
    const char *sql = "SELECT package FROM holds ORDER BY package";
    if (sqlite3_prepare_v2(g_db, sql, -1, &stmt, NULL) != SQLITE_OK) return -1;
    int cap = 16;
    *names = malloc(sizeof(char *) * cap);
    int n = 0;
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        if (n >= cap) { cap *= 2; *names = realloc(*names, sizeof(char *) * cap); }
        (*names)[n++] = strdup_safe((const char *)sqlite3_column_text(stmt, 0));
    }
    sqlite3_finalize(stmt);
    *nnames = n;
    return 0;
}

int db_hold_add(const char *name) {
    sqlite3_stmt *stmt;
    const char *sql = "INSERT OR IGNORE INTO holds (package) VALUES (?1)";
    if (sqlite3_prepare_v2(g_db, sql, -1, &stmt, NULL) != SQLITE_OK) return -1;
    sqlite3_bind_text(stmt, 1, name, -1, SQLITE_TRANSIENT);
    int rc = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    return rc == SQLITE_DONE ? 0 : -1;
}

int db_hold_remove(const char *name) {
    sqlite3_stmt *stmt;
    const char *sql = "DELETE FROM holds WHERE package = ?1";
    if (sqlite3_prepare_v2(g_db, sql, -1, &stmt, NULL) != SQLITE_OK) return -1;
    sqlite3_bind_text(stmt, 1, name, -1, SQLITE_TRANSIENT);
    int rc = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    return rc == SQLITE_DONE ? 0 : -1;
}

int db_is_held(const char *name) {
    sqlite3_stmt *stmt;
    const char *sql = "SELECT 1 FROM holds WHERE package = ?1";
    if (sqlite3_prepare_v2(g_db, sql, -1, &stmt, NULL) != SQLITE_OK) return 0;
    sqlite3_bind_text(stmt, 1, name, -1, SQLITE_TRANSIENT);
    int rc = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    return rc == SQLITE_ROW;
}

int db_transaction_log(const char *action, const char *pkg, const char *version) {
    sqlite3_stmt *stmt;
    const char *sql = "INSERT INTO transaction_log (action, package, version) VALUES (?1,?2,?3)";
    if (sqlite3_prepare_v2(g_db, sql, -1, &stmt, NULL) != SQLITE_OK) return -1;
    sqlite3_bind_text(stmt, 1, action, -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 2, pkg, -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 3, version, -1, SQLITE_TRANSIENT);
    int rc = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    return rc == SQLITE_DONE ? 0 : -1;
}

int db_package_exists(const char *name) {
    sqlite3_stmt *stmt;
    const char *sql = "SELECT 1 FROM packages WHERE name = ?1";
    if (sqlite3_prepare_v2(g_db, sql, -1, &stmt, NULL) != SQLITE_OK) return 0;
    sqlite3_bind_text(stmt, 1, name, -1, SQLITE_TRANSIENT);
    int rc = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    return rc == SQLITE_ROW;
}

void db_close(void) {
    if (g_db) sqlite3_close(g_db);
    g_db = NULL;
}
