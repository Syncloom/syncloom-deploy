#!/bin/bash
# End-to-end smoke test of a running Syncloom stack through the real CLI, as two devices.
#   SYNCLOOM_URL=http://localhost:8080 ./smoke-test.sh      (needs `expect`, the syncloom CLI, and docker for the ciphertext check)
set -euo pipefail
URL=${SYNCLOOM_URL:-http://localhost:8080}
CLI=${SYNCLOOM_CLI:-syncloom}
WORK=$(mktemp -d)
export SYNCLOOM_NO_KEYRING=1 SYNCLOOM_PASSWORD='correct horse battery staple'
USER_NAME=smoke$RANDOM
fail() { echo "FAIL: $*" >&2; exit 1; }

dev() { # dev <name> <cmd...>: run the CLI with that device's private config dir
  local n=$1; shift
  SYNCLOOM_CONFIG_DIR=$WORK/$n/config "$CLI" "$@"
}

echo "== register $USER_NAME on device A"
mkdir -p "$WORK/a/files" "$WORK/b/files"
SECRET_FILE=$WORK/secret
SYNCLOOM_CONFIG_DIR=$WORK/a/config expect <<EXP >"$WORK/register.log" 2>&1 || { cat "$WORK/register.log"; fail "register"; }
set timeout 60
spawn $CLI register $URL $USER_NAME --dir $WORK/a/files
expect -re {Secret: +([A-Z2-7]+)}
set secret \$expect_out(1,string)
set f [open $SECRET_FILE w]; puts \$f \$secret; close \$f
set code [exec $CLI totp \$secret]
expect "6-digit code"
send "\$code\r"
expect eof
EXP
SECRET=$(cat "$SECRET_FILE")
grep -q "RECOVERY KEY" "$WORK/register.log" || fail "no recovery key shown"
grep -q "RECOVERY CODES" "$WORK/register.log" || fail "no recovery codes shown"

echo "== device A: create files and sync"
mkdir -p "$WORK/a/files/Projects/plan"
echo "top secret roadmap" > "$WORK/a/files/Projects/plan/roadmap.txt"
head -c 3000000 /dev/urandom > "$WORK/a/files/big.bin"
echo "hello" > "$WORK/a/files/hello.txt"
dev a sync
dev a ls Projects/plan | grep -q roadmap.txt || fail "file not listed on server"

echo "== device B: sign in with password + second factor, then sync"
CODE=$("$CLI" totp "$SECRET" --offset 1)
SYNCLOOM_CONFIG_DIR=$WORK/b/config SYNCLOOM_TOTP=$CODE dev b login "$URL" "$USER_NAME" --dir "$WORK/b/files"
dev b sync
diff -r "$WORK/a/files" "$WORK/b/files" || fail "folders differ"

echo "== edit on B, delete on A's copy of hello.txt, sync both"
echo "edited on B" >> "$WORK/b/files/Projects/plan/roadmap.txt"
rm "$WORK/b/files/hello.txt"
dev b sync
dev a sync
diff -r "$WORK/a/files" "$WORK/b/files" || fail "folders differ after edit/delete"
[ ! -e "$WORK/a/files/hello.txt" ] || fail "deletion did not propagate"

echo "== key/value"
NS=$(dev a kv create settings)
dev a kv put "$NS" theme dark > /dev/null
[ "$(dev a kv get "$NS" theme)" = "dark" ] || fail "kv get on A"
[ "$(dev b kv get "$NS" theme)" = "dark" ] || fail "device B (same account) must see the namespace"
dev a kv put "$NS" theme light --if-version 1 >/dev/null
if dev a kv put "$NS" theme stale --if-version 1 >/dev/null 2>&1; then fail "stale compare-and-set must be rejected"; fi

echo "== zero knowledge: the server stores no plaintext"
if command -v docker >/dev/null && docker ps --format '{{.Names}}' | grep -q syncloom-db-1; then
  docker exec syncloom-db-1 pg_dump -U syncloom syncloom --data-only > "$WORK/dump.sql"
  grep -qi "roadmap" "$WORK/dump.sql" && fail "plaintext file name found in the database"
  grep -qi "top secret" "$WORK/dump.sql" && fail "plaintext content found in the database"
  if docker exec syncloom-server-1 sh -c 'grep -rl "top secret" /data/blobs' 2>/dev/null | grep -q .; then fail "plaintext content found in blobs"; fi
  echo "   database and blob store contain only ciphertext"
fi

echo "== sign out"
dev b logout
dev a logout
echo "SMOKE TEST PASSED"
rm -rf "$WORK"
