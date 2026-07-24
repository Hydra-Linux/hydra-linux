#include "flash.h"

typedef struct {
    char **names;
    int nnames;
    int cap;
} VisitedSet;

static void visited_init(VisitedSet *v) {
    v->names = NULL; v->nnames = 0; v->cap = 0;
}

static int visited_contains(VisitedSet *v, const char *name) {
    for (int i = 0; i < v->nnames; i++)
        if (strcmp(v->names[i], name) == 0) return 1;
    return 0;
}

static void visited_add(VisitedSet *v, const char *name) {
    if (v->nnames >= v->cap) {
        v->cap = v->cap ? v->cap * 2 : 16;
        v->names = realloc(v->names, sizeof(char *) * v->cap);
    }
    v->names[v->nnames++] = strdup_safe(name);
}

static void visited_free(VisitedSet *v) {
    for (int i = 0; i < v->nnames; i++) free(v->names[i]);
    free(v->names);
}

int vercmp(const char *a, const char *b) {
    while (*a && *b) {
        if (isdigit(*a) && isdigit(*b)) {
            long na = strtol(a, (char **)&a, 10);
            long nb = strtol(b, (char **)&b, 10);
            if (na != nb) return na < nb ? -1 : 1;
        } else {
            if (*a != *b) return *a < *b ? -1 : 1;
            a++; b++;
        }
    }
    if (*a) return 1;
    if (*b) return -1;
    return 0;
}

static int constraint_match(const char *constraint, const char *version) {
    if (!constraint || !*constraint) return 1;
    char op[8] = {0};
    const char *ver = constraint;
    if (strstart(constraint, ">=")) { strcpy(op, ">="); ver = constraint + 2; }
    else if (strstart(constraint, "<=")) { strcpy(op, "<="); ver = constraint + 2; }
    else if (strstart(constraint, "==")) { strcpy(op, "=="); ver = constraint + 2; }
    else if (strstart(constraint, "!=")) { strcpy(op, "!="); ver = constraint + 2; }
    else if (strstart(constraint, ">")) { strcpy(op, ">"); ver = constraint + 1; }
    else if (strstart(constraint, "<")) { strcpy(op, "<"); ver = constraint + 1; }
    else if (strstart(constraint, "=")) { strcpy(op, "="); ver = constraint + 1; }
    else { ver = constraint; }

    while (*ver == ' ') ver++;
    int cmp = vercmp(version, ver);
    if (strcmp(op, ">=") == 0) return cmp >= 0;
    if (strcmp(op, "<=") == 0) return cmp <= 0;
    if (strcmp(op, "==") == 0 || strcmp(op, "=") == 0) return cmp == 0;
    if (strcmp(op, "!=") == 0) return cmp != 0;
    if (strcmp(op, ">") == 0) return cmp > 0;
    if (strcmp(op, "<") == 0) return cmp < 0;
    return 1;
}

static int resolve_recursive(const char *name, const char *constraint,
                              VisitedSet *visited, VisitedSet *resolved,
                              Package ***result, int *nresult, int *cap) {
    if (visited_contains(visited, name)) {
        warn("Circular dependency detected: %s", name);
        return 1;
    }

    if (visited_contains(resolved, name)) return 0;

    Package pkg;
    int found = 0;
    if (db_package_get(name, &pkg) == 0) {
        found = 1;
    }
    if (!found) {
        warn("Package not found: %s", name);
        return 0;
    }

    if (constraint && !constraint_match(constraint, pkg.version)) {
        warn("Version constraint %s not satisfied for %s (have %s)",
             constraint, name, pkg.version);
        free(pkg.name); free(pkg.version); free(pkg.desc);
        free(pkg.license); free(pkg.maintainer); free(pkg.homepage);
        free(pkg.checksum);
        return 0;
    }

    visited_add(visited, name);

    sqlite3_stmt *stmt;
    const char *sql = "SELECT dep_name, dep_constraint FROM dependencies WHERE package = ?1";
    if (sqlite3_prepare_v2(g_db, sql, -1, &stmt, NULL) == SQLITE_OK) {
        sqlite3_bind_text(stmt, 1, name, -1, SQLITE_TRANSIENT);
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            const char *dname = (const char *)sqlite3_column_text(stmt, 0);
            const char *dcon = (const char *)sqlite3_column_text(stmt, 1);
            resolve_recursive(dname, dcon, visited, resolved, result, nresult, cap);
        }
        sqlite3_finalize(stmt);
    }

    if (*nresult >= *cap) {
        *cap *= 2;
        *result = realloc(*result, sizeof(Package *) * (*cap));
    }
    (*result)[*nresult] = malloc(sizeof(Package));
    memcpy((*result)[*nresult], &pkg, sizeof(Package));
    (*nresult)++;

    visited_add(resolved, name);
    return 0;
}

int resolve_dependencies(const char *pkg_name, const char *version_constraint,
                         Package ***result, int *nresult) {
    *result = NULL;
    *nresult = 0;
    int cap = 16;
    *result = malloc(sizeof(Package *) * cap);

    VisitedSet visited, resolved;
    visited_init(&visited);
    visited_init(&resolved);

    int ret = resolve_recursive(pkg_name, version_constraint,
                                 &visited, &resolved, result, nresult, &cap);

    visited_free(&visited);
    visited_free(&resolved);
    return ret;
}
