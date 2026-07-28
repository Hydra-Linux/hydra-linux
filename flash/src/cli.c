#include "flash.h"

static const char *usage_text =
    "flash " FLASH_VERSION " - Hydra Linux Package Manager\n"
    "\n"
    "Usage: flash <command> [options] [arguments]\n"
    "\n"
    "Commands:\n"
    "  install, i     Install package(s)\n"
    "  rm, remove     Remove package(s)\n"
    "  update, up     Update all packages\n"
    "  find, search   Search packages\n"
    "  info, show     Show package info\n"
    "  list, ls       List installed packages\n"
    "  contents, files  List files owned by package\n"
    "  find-owner, who  Find which package owns a file\n"
    "  make, build    Build package from recipe\n"
    "  audit, check   Verify package integrity\n"
    "  cache          Manage package cache\n"
    "  config         Show/edit configuration\n"
    "  sync           Sync repository metadata\n"
    "  revert, downgrade  Revert package to previous version\n"
    "  freeze, hold   Hold package at current version\n"
    "  unfreeze, unhold  Remove version hold\n"
    "  rebuild, revdep  Rebuild packages depending on target\n"
    "  help, h        Show this help\n"
    "\n"
    "Flags:\n"
    "  --agree, -y    Assume yes to prompts\n"
    "  --dry-run, -n  Show what would be done\n"
    "  --force, -f    Force operation\n"
    "  --quiet, -q    Suppress normal output\n"
    "  --verbose, -v  Verbose output\n"
    "  --json         JSON output mode\n"
    "  --root <dir>   Set alternative root\n";

void print_usage(void) {
    printf("%s", usage_text);
}

void print_version(void) {
    printf("flash %s\n", FLASH_VERSION);
}

Command command_from_string(const char *str) {
    if (!str) return CMD_HELP;
    if (strcmp(str, "install") == 0 || strcmp(str, "i") == 0) return CMD_INSTALL;
    if (strcmp(str, "rm") == 0 || strcmp(str, "remove") == 0) return CMD_RM;
    if (strcmp(str, "update") == 0 || strcmp(str, "up") == 0) return CMD_UPDATE;
    if (strcmp(str, "find") == 0 || strcmp(str, "search") == 0) return CMD_FIND;
    if (strcmp(str, "info") == 0 || strcmp(str, "show") == 0) return CMD_INFO;
    if (strcmp(str, "list") == 0 || strcmp(str, "ls") == 0) return CMD_LIST;
    if (strcmp(str, "contents") == 0 || strcmp(str, "files") == 0) return CMD_CONTENTS;
    if (strcmp(str, "find-owner") == 0 || strcmp(str, "who") == 0) return CMD_FIND_OWNER;
    if (strcmp(str, "make") == 0 || strcmp(str, "build") == 0) return CMD_MAKE;
    if (strcmp(str, "audit") == 0 || strcmp(str, "check") == 0) return CMD_AUDIT;
    if (strcmp(str, "cache") == 0) return CMD_CACHE;
    if (strcmp(str, "config") == 0) return CMD_CONFIG;
    if (strcmp(str, "sync") == 0) return CMD_SYNC;
    if (strcmp(str, "revert") == 0 || strcmp(str, "downgrade") == 0) return CMD_REVERT;
    if (strcmp(str, "freeze") == 0 || strcmp(str, "hold") == 0) return CMD_FREEZE;
    if (strcmp(str, "unfreeze") == 0 || strcmp(str, "unhold") == 0) return CMD_UNFREEZE;
    if (strcmp(str, "rebuild") == 0 || strcmp(str, "revdep") == 0) return CMD_REBUILD;
    if (strcmp(str, "help") == 0 || strcmp(str, "h") == 0) return CMD_HELP;
    return CMD_HELP;
}

int parse_flags(int argc, char **argv, Flags *flags) {
    memset(flags, 0, sizeof(Flags));
    int i = 1;
    for (int j = 1; j < argc; j++) {
        char *arg = argv[j];
        if (arg[0] == '-') {
            if (strcmp(arg, "--agree") == 0 || strcmp(arg, "-y") == 0) flags->agree = 1;
            else if (strcmp(arg, "--dry-run") == 0 || strcmp(arg, "-n") == 0) flags->dry_run = 1;
            else if (strcmp(arg, "--force") == 0 || strcmp(arg, "-f") == 0) flags->force = 1;
            else if (strcmp(arg, "--quiet") == 0 || strcmp(arg, "-q") == 0) flags->quiet = 1;
            else if (strcmp(arg, "--verbose") == 0 || strcmp(arg, "-v") == 0) flags->verbose = 1;
            else if (strcmp(arg, "--json") == 0) flags->json = 1;
            else if (strcmp(arg, "--help") == 0 || strcmp(arg, "-h") == 0) { print_usage(); exit(0); }
            else if (strcmp(arg, "--config") == 0 && j + 1 < argc) {
                config_load(argv[++j], &g_config);
            } else {
                warn("Unknown flag: %s", arg);
            }
        } else {
            argv[i++] = arg;
        }
    }
    return i;
}
