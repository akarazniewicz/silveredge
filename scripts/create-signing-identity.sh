#!/bin/sh
# Creates the stable self-signed code-signing identity `make build` signs
# with, once. Every build signed with the same identity has the same
# designated requirement, so macOS keeps whatever it granted SilverEdge
# (Login Items, for one) across updates (ad-hoc builds change identity with
# every build).
#
# It lives in its own keychain, never the login keychain: codesign may only
# use a key without a dialog once the key's partition list allows it, and
# changing that list needs the keychain's password — here one this script
# sets (it guards nothing but this self-signed key).
#
# It doesn't make SilverEdge "identified" to Gatekeeper (that's Developer ID),
# and it doesn't stop Keychain prompts for items an app saves: login-keychain
# items are partitioned per build (`cdhash:`) for any non-Apple signature.
#
# Keep the keychain file: losing the identity means granting those once more.
set -eu

NAME="${1:-SilverEdge Self-Signed}"
KEYCHAIN="${2:-$HOME/Library/Keychains/silveredge-signing.keychain-db}"
PASSWORD="silveredge-signing"

if [ -f "$KEYCHAIN" ] && security find-identity -p codesigning "$KEYCHAIN" | grep -q "\"$NAME\""; then
    echo "'$NAME' already exists in $KEYCHAIN — nothing to do."
    exit 0
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cat > "$WORK/cert.cnf" <<EOF
[req]
distinguished_name = dn
x509_extensions = ext
prompt = no
[dn]
CN = $NAME
[ext]
basicConstraints = critical, CA:false
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, codeSigning
EOF

# The system LibreSSL: its .p12 encryption is what `security import` reads
# (OpenSSL 3's default isn't).
/usr/bin/openssl req -x509 -newkey rsa:2048 -nodes -days 3650 -config "$WORK/cert.cnf" \
    -keyout "$WORK/key.pem" -out "$WORK/cert.pem" 2>/dev/null
/usr/bin/openssl pkcs12 -export -inkey "$WORK/key.pem" -in "$WORK/cert.pem" \
    -name "$NAME" -out "$WORK/identity.p12" -passout pass:silveredge

[ -f "$KEYCHAIN" ] || security create-keychain -p "$PASSWORD" "$KEYCHAIN"
security set-keychain-settings "$KEYCHAIN"   # never locks itself
security unlock-keychain -p "$PASSWORD" "$KEYCHAIN"
security import "$WORK/identity.p12" -k "$KEYCHAIN" -P silveredge -T /usr/bin/codesign >/dev/null
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$PASSWORD" "$KEYCHAIN" >/dev/null

# On the search list, so Xcode finds the identity by name.
if ! security list-keychains -d user | grep -q "$KEYCHAIN"; then
    # shellcheck disable=SC2046 # one path per word, as listed
    security list-keychains -d user -s $(security list-keychains -d user | tr -d '"') "$KEYCHAIN"
fi

echo "Created '$NAME' in $KEYCHAIN. \`make build\` signs with it from now on."
