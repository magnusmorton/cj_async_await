#!/bin/bash

set -euo pipefail

MODE="${1:-all}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/cj_async_await_examples.XXXXXX")"

cleanup_run_tmp_dir() {
  if [[ -n "${RUN_TMP_DIR:-}" && -d "$RUN_TMP_DIR" ]]; then
    rm -rf "$RUN_TMP_DIR"
  fi
}

trap cleanup_run_tmp_dir EXIT

POSITIVE_EXAMPLES=(
  "smoke_async_main"
  "member_and_generic_await"
)

NEGATIVE_EXAMPLES=(
  "invalid_async_missing_return"
  "invalid_async_non_function"
  "invalid_await_non_call"
  "invalid_await_sync_call"
)

positive_expected_exit() {
  case "$1" in
    smoke_async_main) echo "42" ;;
    member_and_generic_await) echo "11" ;;
    *)
      echo "unknown positive example: $1" >&2
      exit 1
      ;;
  esac
}

build_macro_package() {
  set +u
  source "$HOME/cangjie/envsetup.sh"
  set -u
  cd "$ROOT_DIR"
  cjpm build
}

compile_and_run_positive() {
  local name="$1"
  local src="$ROOT_DIR/examples/${name}.cj"
  local out="$RUN_TMP_DIR/${name}"
  local expected_exit
  expected_exit="$(positive_expected_exit "$name")"

  echo "==> positive: ${name}"
  cjc "$src" --import-path "$ROOT_DIR/target/release" -o "$out"
  set +e
  "$out"
  local actual_exit=$?
  set -e

  if [[ "$actual_exit" != "$expected_exit" ]]; then
    echo "unexpected exit code for ${name}: got ${actual_exit}, expected ${expected_exit}" >&2
    exit 1
  fi

  echo "ok: ${name} exited with ${actual_exit}"
}

compile_negative() {
  local name="$1"
  local src="$ROOT_DIR/examples/${name}.cj"
  local out="$RUN_TMP_DIR/${name}.neg"
  local log="$RUN_TMP_DIR/${name}.neg.log"

  echo "==> negative: ${name}"
  if cjc "$src" --import-path "$ROOT_DIR/target/release" -o "$out" >"$log" 2>&1; then
    echo "unexpected success for ${name}" >&2
    cat "$log" >&2
    exit 1
  fi

  sed -n '1,12p' "$log"
  echo "expected failure: ${name}"
}

run_positive_examples() {
  local name
  for name in "${POSITIVE_EXAMPLES[@]}"; do
    compile_and_run_positive "$name"
  done
}

run_negative_examples() {
  local name
  for name in "${NEGATIVE_EXAMPLES[@]}"; do
    compile_negative "$name"
  done
}

case "$MODE" in
  positive)
    build_macro_package
    run_positive_examples
    ;;
  negative)
    build_macro_package
    run_negative_examples
    ;;
  all)
    build_macro_package
    run_positive_examples
    run_negative_examples
    ;;
  *)
    echo "usage: $0 [positive|negative|all]" >&2
    exit 1
    ;;
esac
