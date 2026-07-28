name="ca-certificates"
version="20240203"
release="1"
license="GPL-2.0-or-later"
maintainer="Hydra Linux Team"
source=("https://github.com/mozilla/gecko-dev/raw/master/security/nss/lib/ckfw/builtins/certdata.txt")
sha256sums=("0000000000000000000000000000000000000000000000000000000000000000")
depends=("bash" "coreutils" "openssl")
build_depends=()
prepare() { mkdir -p "${srcdir}/certs"; }
build() { cp "${srcdir}/certdata.txt" "${srcdir}/certs/" && cd "${srcdir}/certs" && openssl x509 -inform PEM -text -in certdata.txt 2>/dev/null || true; }
install() { mkdir -p "${pkgdir}/etc/ssl/certs" && cp /etc/ssl/certs/ca-certificates.crt "${pkgdir}/etc/ssl/certs/" 2>/dev/null || true; }
