#include "flash.h"

Flags g_flags;
Config g_config;

static pthread_mutex_t print_mutex = PTHREAD_MUTEX_INITIALIZER;

void print_colored(const char *color, const char *fmt, ...) {
    va_list ap;
    pthread_mutex_lock(&print_mutex);
    if (!g_flags.json) {
        if (color) fputs(color, stdout);
        va_start(ap, fmt);
        vprintf(fmt, ap);
        va_end(ap);
        if (color) fputs(COLOR_RESET, stdout);
    } else {
        va_start(ap, fmt);
        vprintf(fmt, ap);
        va_end(ap);
    }
    pthread_mutex_unlock(&print_mutex);
}

void print_status(int success, const char *label, const char *fmt, ...) {
    if (g_flags.quiet && success) return;
    if (g_flags.json) {
        if (fmt) {
            va_list ap;
            va_start(ap, fmt);
            char buf[4096];
            vsnprintf(buf, sizeof(buf), fmt, ap);
            va_end(ap);
            printf("{\"status\":\"%s\",\"label\":\"%s\",\"message\":\"%s\"}\n",
                   success ? "ok" : "fail", label ? label : "", buf);
        } else {
            printf("{\"status\":\"%s\",\"label\":\"%s\"}\n",
                   success ? "ok" : "fail", label ? label : "");
        }
        return;
    }
    print_colored(success ? COLOR_GREEN : COLOR_RED,
                  success ? " ✔ " : " ✘ ", NULL);
    if (label) print_colored(COLOR_CYAN, "%s", label);
    if (fmt) {
        printf(" ");
        va_list ap;
        va_start(ap, fmt);
        vprintf(fmt, ap);
        va_end(ap);
    }
    printf("\n");
}

void print_progress(long current, long total, const char *label) {
    if (g_flags.quiet || g_flags.json) return;
    int pct = total > 0 ? (int)(current * 100 / total) : 0;
    int barw = 30;
    int pos = barw * pct / 100;
    pthread_mutex_lock(&print_mutex);
    printf("\r");
    if (label) printf("%s: ", label);
    putchar('[');
    for (int i = 0; i < barw; i++) {
        if (i < pos) fputs("=", stdout);
        else if (i == pos) fputs(">", stdout);
        else fputs(" ", stdout);
    }
    printf("] %d%%", pct);
    fflush(stdout);
    if (current >= total) printf("\n");
    pthread_mutex_unlock(&print_mutex);
}

char *read_file(const char *path) {
    FILE *f = fopen(path, "rb");
    if (!f) return NULL;
    fseek(f, 0, SEEK_END);
    long len = ftell(f);
    fseek(f, 0, SEEK_SET);
    if (len < 0) { fclose(f); return NULL; }
    char *buf = malloc((size_t)len + 1);
    if (!buf) { fclose(f); return NULL; }
    size_t n = fread(buf, 1, (size_t)len, f);
    fclose(f);
    buf[n] = 0;
    return buf;
}

int write_file(const char *path, const char *data) {
    FILE *f = fopen(path, "wb");
    if (!f) return -1;
    size_t len = strlen(data);
    if (fwrite(data, 1, len, f) != len) { fclose(f); return -1; }
    fclose(f);
    return 0;
}

char *strjoin(const char *a, const char *b) {
    size_t la = a ? strlen(a) : 0;
    size_t lb = b ? strlen(b) : 0;
    char *r = malloc(la + lb + 1);
    if (!r) return NULL;
    if (a) memcpy(r, a, la);
    if (b) memcpy(r + la, b, lb);
    r[la + lb] = 0;
    return r;
}

char *strdup_safe(const char *s) {
    if (!s) return NULL;
    size_t len = strlen(s);
    char *r = malloc(len + 1);
    if (!r) return NULL;
    memcpy(r, s, len + 1);
    return r;
}

int strstart(const char *str, const char *prefix) {
    if (!str || !prefix) return 0;
    return strncmp(str, prefix, strlen(prefix)) == 0;
}

char *path_join(const char *a, const char *b) {
    if (!a) return strdup_safe(b);
    if (!b) return strdup_safe(a);
    size_t la = strlen(a), lb = strlen(b);
    int need_sep = (la > 0 && a[la-1] != '/');
    char *r = malloc(la + lb + 2);
    if (!r) return NULL;
    memcpy(r, a, la);
    if (need_sep) r[la++] = '/';
    memcpy(r + la, b, lb + 1);
    return r;
}

void die(const char *fmt, ...) {
    va_list ap;
    fputs(COLOR_RED "error: " COLOR_RESET, stderr);
    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap);
    fputc('\n', stderr);
    exit(1);
}

void warn(const char *fmt, ...) {
    if (g_flags.quiet) return;
    va_list ap;
    fputs(COLOR_YELLOW "warning: " COLOR_RESET, stderr);
    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap);
    fputc('\n', stderr);
}

int confirm(const char *prompt) {
    if (g_flags.agree) return 1;
    if (g_flags.dry_run) return 0;
    printf("%s [y/N] ", prompt);
    char buf[16];
    if (!fgets(buf, sizeof(buf), stdin)) return 0;
    return buf[0] == 'y' || buf[0] == 'Y';
}

long file_size(const char *path) {
    struct stat st;
    if (stat(path, &st) != 0) return -1;
    return (long)st.st_size;
}

int mkdir_p(const char *path) {
    char tmp[4096];
    char *p = NULL;
    size_t len;
    snprintf(tmp, sizeof(tmp), "%s", path);
    len = strlen(tmp);
    if (tmp[len-1] == '/') tmp[len-1] = 0;
    for (p = tmp + 1; *p; p++) {
        if (*p == '/') {
            *p = 0;
            mkdir(tmp, 0755);
            *p = '/';
        }
    }
    return mkdir(tmp, 0755);
}

int tier_determine(long size_bytes, int *tier) {
    if (size_bytes < 0) return -1;
    if (size_bytes <= g_config.source_threshold) *tier = TIER_SOURCE;
    else if (size_bytes <= g_config.binary_threshold) *tier = TIER_BINARY;
    else *tier = TIER_PARTS;
    return 0;
}
