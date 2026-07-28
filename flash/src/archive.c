#include "flash.h"

static la_ssize_t file_read(struct archive *a, void *client_data, const void **buff) {
    (void)a;
    FILE *f = (FILE *)client_data;
    size_t size = 8192;
    char *buf = malloc(size);
    if (!buf) return -1;
    size_t n = fread(buf, 1, size, f);
    if (n == 0) { free(buf); return 0; }
    *buff = buf;
    return (la_ssize_t)n;
}

static int file_close(struct archive *a, void *client_data) {
    (void)a;
    FILE *f = (FILE *)client_data;
    fclose(f);
    return ARCHIVE_OK;
}

static int file_open(struct archive *a, void *client_data) {
    (void)a; (void)client_data;
    return ARCHIVE_OK;
}

static la_ssize_t file_write(struct archive *a, void *client_data, const void *buff, size_t n) {
    (void)a;
    FILE *f = (FILE *)client_data;
    return fwrite(buff, 1, n, f) == n ? (la_ssize_t)n : -1;
}

int archive_extract(const char *path, const char *destdir) {
    if (g_flags.dry_run) {
        printf("Would extract: %s -> %s\n", path, destdir);
        return 0;
    }

    struct archive *a = archive_read_new();
    struct archive *ext = archive_write_disk_new();
    struct archive_entry *entry;

    archive_read_support_filter_zstd(a);
    archive_read_support_format_tar(a);
    archive_write_disk_set_options(ext, ARCHIVE_EXTRACT_TIME | ARCHIVE_EXTRACT_PERM |
                                   ARCHIVE_EXTRACT_ACL | ARCHIVE_EXTRACT_FFLAGS);

    FILE *f = fopen(path, "rb");
    if (!f) { archive_read_free(a); archive_write_free(ext); return -1; }

    archive_read_open(a, f, file_open, file_read, file_close);

    char *old_cwd = NULL;
    if (destdir) {
        old_cwd = getcwd(NULL, 0);
        if (chdir(destdir) != 0) {
            warn("Cannot chdir to %s: %s", destdir, strerror(errno));
            archive_read_close(a); archive_read_free(a); archive_write_free(ext);
            free(old_cwd); return -1;
        }
    }

    int r;
    while ((r = archive_read_next_header(a, &entry)) == ARCHIVE_OK) {
        const char *name = archive_entry_pathname(entry);
        if (g_flags.verbose) print_status(1, "extract", name);
        archive_entry_set_perm(entry, archive_entry_mode(entry));
        r = archive_write_header(ext, entry);
        if (r == ARCHIVE_OK) {
            const void *buf;
            size_t size;
            la_int64_t offset;
            while ((r = archive_read_data_block(a, &buf, &size, &offset)) == ARCHIVE_OK) {
                if (archive_write_data_block(ext, buf, size, offset) != ARCHIVE_OK) {
                    warn("Write error: %s", archive_error_string(ext));
                    break;
                }
            }
        }
        archive_write_finish_entry(ext);
    }

    archive_read_close(a);
    archive_read_free(a);
    archive_write_close(ext);
    archive_write_free(ext);

    if (old_cwd) { int rc = chdir(old_cwd); (void)rc; free(old_cwd); }
    return (r == ARCHIVE_EOF) ? 0 : -1;
}

int archive_create(const char *srcdir, const char *output_path, char **excludes, int nexcludes) {
    if (g_flags.dry_run) {
        printf("Would create archive: %s <- %s\n", output_path, srcdir);
        return 0;
    }

    struct archive *a = archive_write_new();
    struct archive *disk = archive_read_disk_new();
    struct archive_entry *entry = archive_entry_new();

    archive_write_add_filter_zstd(a);
    archive_write_set_format_pax_restricted(a);

    FILE *f = fopen(output_path, "wb");
    if (!f) { archive_write_free(a); archive_entry_free(entry); archive_read_free(disk); return -1; }

    archive_write_open(a, f, file_open, file_write, file_close);
    archive_read_disk_set_standard_lookup(disk);

    if (srcdir && chdir(srcdir) != 0) {
        warn("Cannot chdir to %s", srcdir);
        archive_write_close(a); archive_write_free(a);
        archive_entry_free(entry); archive_read_free(disk);
        return -1;
    }

    int r = archive_read_disk_open(disk, ".");
    if (r != ARCHIVE_OK) {
        archive_entry_free(entry); archive_read_free(disk);
        archive_write_close(a); archive_write_free(a);
        if (srcdir) { int rc = chdir("/"); (void)rc; }
        return -1;
    }

    for (;;) {
        r = archive_read_next_header2(disk, entry);
        if (r == ARCHIVE_EOF) break;
        if (r != ARCHIVE_OK) { warn("Read error: %s", archive_error_string(disk)); break; }

        const char *path = archive_entry_pathname(entry);
        int skip = 0;
        for (int i = 0; i < nexcludes; i++) {
            if (strcmp(path, excludes[i]) == 0 ||
                strstart(path, excludes[i])) { skip = 1; break; }
        }
        if (skip) {
            archive_read_disk_descend(disk);
            continue;
        }

        archive_read_disk_descend(disk);
        r = archive_write_header(a, entry);
        if (r == ARCHIVE_OK) {
            int fd = open(path, O_RDONLY);
            if (fd >= 0) {
                char buf[8192];
                ssize_t n;
                while ((n = read(fd, buf, sizeof(buf))) > 0) {
                    archive_write_data(a, buf, (size_t)n);
                }
                close(fd);
            }
            archive_write_finish_entry(a);
        }
    }

    archive_entry_free(entry);
    archive_read_close(disk);
    archive_read_free(disk);
    archive_write_close(a);
    archive_write_free(a);
    if (srcdir) { int rc = chdir("/"); (void)rc; }
    return 0;
}

int archive_list(const char *path) {
    struct archive *a = archive_read_new();
    struct archive_entry *entry;

    archive_read_support_filter_zstd(a);
    archive_read_support_format_tar(a);

    FILE *f = fopen(path, "rb");
    if (!f) { archive_read_free(a); return -1; }

    archive_read_open(a, f, file_open, file_read, file_close);

    int r;
    while ((r = archive_read_next_header(a, &entry)) == ARCHIVE_OK) {
        const char *name = archive_entry_pathname(entry);
        long size = (long)archive_entry_size(entry);
        if (g_flags.json) {
            printf("{\"path\":\"%s\",\"size\":%ld}\n", name, size);
        } else {
            printf("%s  %ld\n", name, size);
        }
    }

    archive_read_close(a);
    archive_read_free(a);
    return (r == ARCHIVE_EOF) ? 0 : -1;
}
