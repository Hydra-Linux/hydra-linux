#include "flash.h"

static void sha256_init(unsigned int *s) {
    s[0] = 0x6a09e667; s[1] = 0xbb67ae85; s[2] = 0x3c6ef372; s[3] = 0xa54ff53a;
    s[4] = 0x510e527f; s[5] = 0x9b05688c; s[6] = 0x1f83d9ab; s[7] = 0x5be0cd19;
}

#define ROTR(x, n) (((x) >> (n)) | ((x) << (32 - (n))))
#define CH(x, y, z) (((x) & (y)) ^ (~(x) & (z)))
#define MAJ(x, y, z) (((x) & (y)) ^ ((x) & (z)) ^ ((y) & (z)))
#define EP0(x) (ROTR(x, 2) ^ ROTR(x, 13) ^ ROTR(x, 22))
#define EP1(x) (ROTR(x, 6) ^ ROTR(x, 11) ^ ROTR(x, 25))
#define SHA256_SIG0(x) (ROTR(x, 7) ^ ROTR(x, 18) ^ ((x) >> 3))
#define SHA256_SIG1(x) (ROTR(x, 17) ^ ROTR(x, 19) ^ ((x) >> 10))

static const unsigned int K[64] = {
    0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
    0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
    0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
    0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
    0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
    0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
    0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
    0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2
};

static void sha256_transform(unsigned int *s, const unsigned char *chunk) {
    unsigned int w[64], a, b, c, d, e, f, g, h, t1, t2;
    int i;
    for (i = 0; i < 16; i++)
        w[i] = ((unsigned int)chunk[4*i] << 24) | (chunk[4*i+1] << 16) |
               (chunk[4*i+2] << 8) | chunk[4*i+3];
    for (i = 16; i < 64; i++)
        w[i] = SHA256_SIG1(w[i-2]) + w[i-7] + SHA256_SIG0(w[i-15]) + w[i-16];
    a = s[0]; b = s[1]; c = s[2]; d = s[3];
    e = s[4]; f = s[5]; g = s[6]; h = s[7];
    for (i = 0; i < 64; i++) {
        t1 = h + EP1(e) + CH(e,f,g) + K[i] + w[i];
        t2 = EP0(a) + MAJ(a,b,c);
        h = g; g = f; f = e; e = d + t1;
        d = c; c = b; b = a; a = t1 + t2;
    }
    s[0] += a; s[1] += b; s[2] += c; s[3] += d;
    s[4] += e; s[5] += f; s[6] += g; s[7] += h;
}

static void sha256_hash(const unsigned char *data, size_t len, unsigned char *out) {
    unsigned int s[8];
    unsigned char chunk[64];
    uint64_t bitlen = (uint64_t)len * 8;
    size_t i, offset = 0;
    sha256_init(s);

    while (len - offset >= 64) {
        sha256_transform(s, data + offset);
        offset += 64;
    }

    size_t remaining = len - offset;
    memset(chunk, 0, sizeof(chunk));
    memcpy(chunk, data + offset, remaining);
    chunk[remaining] = 0x80;

    if (remaining >= 56) {
        sha256_transform(s, chunk);
        memset(chunk, 0, sizeof(chunk));
    }

    for (i = 0; i < 8; i++)
        chunk[56 + i] = (unsigned char)(bitlen >> (56 - i * 8));
    sha256_transform(s, chunk);

    for (i = 0; i < 8; i++) {
        out[4*i]   = (unsigned char)(s[i] >> 24);
        out[4*i+1] = (unsigned char)(s[i] >> 16);
        out[4*i+2] = (unsigned char)(s[i] >> 8);
        out[4*i+3] = (unsigned char)(s[i]);
    }
}

int crypto_verify(const char *path, const char *sig_path, const char *keyring) {
    if (g_flags.dry_run) { printf("Would verify: %s (sig: %s)\n", path, sig_path); return 0; }

    gpgme_ctx_t ctx;
    gpgme_data_t sig_data, file_data;
    gpgme_error_t err;
    gpgme_check_version(NULL);
    err = gpgme_new(&ctx);
    if (err) { warn("gpgme_new: %s", gpgme_strerror(err)); return -1; }

    if (keyring) {
        char *armor = path_join(keyring, "pubring.gpg");
        if (armor) {
            gpgme_set_engine_info(GPGME_PROTOCOL_OpenPGP, NULL, armor);
            free(armor);
        }
    }

    err = gpgme_data_new_from_file(&sig_data, sig_path, 1);
    if (err) { gpgme_release(ctx); warn("sig file: %s", gpgme_strerror(err)); return -1; }
    err = gpgme_data_new_from_file(&file_data, path, 1);
    if (err) { gpgme_data_release(sig_data); gpgme_release(ctx); warn("file: %s", gpgme_strerror(err)); return -1; }
    err = gpgme_op_verify(ctx, sig_data, file_data, NULL);
    if (err) { gpgme_data_release(sig_data); gpgme_data_release(file_data); gpgme_release(ctx); warn("verify: %s", gpgme_strerror(err)); return -1; }

    gpgme_verify_result_t result = gpgme_op_verify_result(ctx);
    int ok = 0;
    if (result && result->signatures) {
        gpgme_signature_t sig = result->signatures;
        if (sig->status == GPG_ERR_NO_ERROR) ok = 1;
        else warn("Bad signature: %s", gpgme_strerror(sig->status));
    }
    gpgme_data_release(sig_data); gpgme_data_release(file_data); gpgme_release(ctx);
    if (g_flags.verbose && ok) print_status(1, "gpg", "Signature verified");
    return ok ? 0 : -1;
}

int crypto_sign(const char *path, const char *key_id) {
    gpgme_ctx_t ctx;
    gpgme_data_t in, out;
    gpgme_key_t key;
    gpgme_error_t err;
    gpgme_check_version(NULL);
    err = gpgme_new(&ctx);
    if (err) { warn("gpgme_new: %s", gpgme_strerror(err)); return -1; }
    if (key_id) {
        err = gpgme_get_key(ctx, key_id, &key, 0);
        if (err) { gpgme_release(ctx); warn("Key not found: %s", gpgme_strerror(err)); return -1; }
        gpgme_signers_add(ctx, key);
        gpgme_key_release(key);
    }
    err = gpgme_data_new_from_file(&in, path, 1);
    if (err) { gpgme_release(ctx); return -1; }
    char sig_path[4096];
    snprintf(sig_path, sizeof(sig_path), "%s.sig", path);
    FILE *f = fopen(sig_path, "wb");
    if (!f) { gpgme_data_release(in); gpgme_release(ctx); return -1; }
    err = gpgme_data_new_from_fd(&out, fileno(f));
    if (err) { fclose(f); gpgme_data_release(in); gpgme_release(ctx); return -1; }
    err = gpgme_op_sign(ctx, in, out, GPGME_SIG_MODE_DETACH);
    fclose(f);
    gpgme_data_release(in); gpgme_data_release(out); gpgme_release(ctx);
    if (err) { warn("Sign failed: %s", gpgme_strerror(err)); return -1; }
    if (g_flags.verbose) print_status(1, "gpg", "Signed");
    return 0;
}

int crypto_checksum(const char *path, char *out_hash, size_t outlen) {
    (void)outlen;
    FILE *f = fopen(path, "rb");
    if (!f) return -1;
    unsigned char buf[8192];
    size_t n;

    unsigned char hash[32];
    unsigned char *data = NULL;
    size_t total = 0, cap = 65536;
    data = malloc(cap);
    if (!data) { fclose(f); return -1; }
    while ((n = fread(buf, 1, sizeof(buf), f)) > 0) {
        if (total + n > cap) {
            cap *= 2;
            data = realloc(data, cap);
        }
        memcpy(data + total, buf, n);
        total += n;
    }
    fclose(f);
    sha256_hash(data, total, hash);
    free(data);

    for (int i = 0; i < 32; i++) {
        sprintf(out_hash + i * 2, "%02x", hash[i]);
    }
    out_hash[64] = 0;
    return 0;
}
