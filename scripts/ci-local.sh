#!/usr/bin/env bash
# Local CI: runs the checks in .github/workflows/ on this machine, in the same
# order and with the same flags, so a push can be checked while GitHub Actions
# is unavailable. .githooks/pre-push runs the fast mode.
#
#   scripts/ci-local.sh          fast mode
#   scripts/ci-local.sh --full   fast mode plus the slow jobs
#
# Steps stop at the first failure, as a CI job does. A step whose tooling is
# missing here prints SKIPPED (reason) instead of failing. No step may change
# a tracked file; the script fails if one does.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

FULL=0
for arg in "$@"; do
  case "$arg" in
    --full) FULL=1 ;;
    -h|--help) sed -n '2,11p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown argument: $arg" >&2; exit 2 ;;
  esac
done

START_ALL=$SECONDS
tree_state() { { git diff HEAD --no-ext-diff 2>/dev/null; git status --porcelain --untracked-files=no; } | sha1sum; }
TREE_BEFORE="$(tree_state)"

# step "name" command [args...]: runs the command in a subshell with errexit.
step() {
  local name="$1"; shift
  local t0=$SECONDS rc
  echo "==> $name"
  set +e
  ( set -e; "$@" )
  rc=$?
  set -e
  if [ "$rc" -ne 0 ]; then
    echo "    FAIL  $name ($((SECONDS - t0))s, exit $rc)"
    echo "local CI: FAILED at '$name' after $((SECONDS - START_ALL))s" >&2
    exit 1
  fi
  echo "    PASS  $name ($((SECONDS - t0))s)"
}

skip() { echo "==> $1"; echo "    SKIPPED ($2)"; }
have() { command -v "$1" >/dev/null 2>&1; }

finish() {
  if [ "$(tree_state)" != "$TREE_BEFORE" ]; then
    echo "local CI: FAILED, a step changed tracked files (see git status)" >&2
    exit 1
  fi
  echo "local CI: PASSED ($([ "$FULL" = 1 ] && echo full || echo fast) mode, $((SECONDS - START_ALL))s)"
}

# ---------------------------------------------------------------------------
# Mirrors tests.yml (Swift Package Tests) and, with --full, the build job of
# docs.yml. Both run on macos-15 with Xcode 16. The package imports SwiftUI
# and Combine, so it cannot build on Linux even with a Swift toolchain.

if [ "$(uname -s)" != "Darwin" ]; then
  skip "Show Swift version" "needs macOS"
  skip "Run tests (swift test --configuration release --parallel)" "needs macOS"
  if [ "$FULL" = 1 ]; then skip "Generate DocC docs (docs.yml)" "needs macOS"; fi
elif ! have swift; then
  skip "Show Swift version" "swift not installed"
  skip "Run tests (swift test --configuration release --parallel)" "swift not installed"
  if [ "$FULL" = 1 ]; then skip "Generate DocC docs (docs.yml)" "swift not installed"; fi
else
  step "Show Swift version" swift --version
  step "Run tests (swift test --configuration release --parallel)" swift test --configuration release --parallel

  if [ "$FULL" = 1 ]; then
    # docs.yml writes to ./docs for upload; here the output goes to a temp dir.
    docs_out="$(mktemp -d)"
    trap 'rm -rf "$docs_out"' EXIT
    step "Generate DocC docs (docs.yml)" swift package \
      --allow-writing-to-directory "$docs_out" \
      generate-documentation \
      --target Bloc \
      --output-path "$docs_out" \
      --transform-for-static-hosting \
      --hosting-base-path /
  fi
fi

finish
