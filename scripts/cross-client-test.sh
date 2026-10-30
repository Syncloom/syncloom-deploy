#!/bin/bash
# Cross-client check: the native CLI writes encrypted files and key/value data, a real browser (WebAssembly build of
# the same core) reads them and uploads a file back, and the CLI syncs that file down.
#   needs: docker, expect, the syncloom CLI (SYNCLOOM_CLI), a FRESH stack on :8088 (docker-compose.test.yml)
set -euo pipefail
cd "$(dirname "$0")/../.."
URL=${SYNCLOOM_URL:-http://localhost:8088}
CLI=${SYNCLOOM_CLI:-$PWD/syncloom-linux/target/debug/syncloom}
WORK=$(mktemp -d); export SYNCLOOM_NO_KEYRING=1 SYNCLOOM_PASSWORD='correct horse battery staple' SYNCLOOM_CONFIG_DIR=$WORK/cfg
USER_NAME=xclient

mkdir -p "$WORK/files/Reports"
printf 'written by the command-line client\n' > "$WORK/files/from-cli.txt"
printf 'quarterly numbers\n' > "$WORK/files/Reports/q3.txt"
printf 'unicode\n' > "$WORK/files/ünïcödé 日本語.txt"
head -c 3000000 /dev/urandom > "$WORK/files/blob.bin"

expect <<EXP > "$WORK/register.log" 2>&1
set timeout 60
spawn $CLI register $URL $USER_NAME --dir $WORK/files
expect -re {Secret: +([A-Z2-7]+)}
set secret \$expect_out(1,string)
set f [open $WORK/secret w]; puts \$f \$secret; close \$f
expect "6-digit code"
send "[exec $CLI totp \$secret]\r"
expect eof
EXP
SECRET=$(cat "$WORK/secret")
$CLI sync >/dev/null
NS=$($CLI kv create prefs); $CLI kv put "$NS" theme "dark from the cli" >/dev/null

docker run --rm --network syncloom_default --ipc=host \
  -e XCLIENT_USER=$USER_NAME -e XCLIENT_PASSWORD="$SYNCLOOM_PASSWORD" -e XCLIENT_SECRET="$SECRET" -e XCLIENT_BLOB=/data/blob.bin \
  -v "$PWD/syncloom-web/e2e":/e2e -v "$WORK/files":/data:ro -v syncloom-e2e-nm:/e2e/node_modules -w /e2e mcr.microsoft.com/playwright:v1.50.0-jammy \
  sh -c "npx playwright test crossclient.spec.ts 2>&1 | grep -v 'npm notice'"

# and back: the CLI pulls what the browser uploaded and decrypts it natively
$CLI sync | grep -q "from-browser.txt" || { echo "FAIL: the CLI did not download the browser's file"; exit 1; }
[ "$(cat "$WORK/files/from-browser.txt")" = "written by the browser, read by the CLI" ] || { echo "FAIL: content mismatch"; exit 1; }
echo "CROSS-CLIENT TEST PASSED"
rm -rf "$WORK"
