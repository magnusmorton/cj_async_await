#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUN_TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/cj_async_await_compile_fail.XXXXXX")"

cleanup_run_tmp_dir() {
  if [[ -n "${RUN_TMP_DIR:-}" && -d "$RUN_TMP_DIR" ]]; then
    rm -rf "$RUN_TMP_DIR"
  fi
}

trap cleanup_run_tmp_dir EXIT

build_macro_package() {
  set +u
  source "$HOME/cangjie/envsetup.sh"
  set -u
  cd "$ROOT_DIR"
  cjpm build >/dev/null
}

check_compile_failure() {
  local fixture="$1"
  local expected_text="$2"
  local source_file="$ROOT_DIR/examples/${fixture}.cj"
  local binary_file="$RUN_TMP_DIR/${fixture}"
  local log_file="$RUN_TMP_DIR/${fixture}.log"

  echo "==> compile-fail: ${fixture}"
  if cjc "$source_file" --import-path "$ROOT_DIR/target/release" -o "$binary_file" >"$log_file" 2>&1; then
    echo "unexpected success for ${fixture}" >&2
    cat "$log_file" >&2
    exit 1
  fi

  if ! grep -Fq "$expected_text" "$log_file"; then
    echo "unexpected compiler output for ${fixture}" >&2
    echo "expected to find: $expected_text" >&2
    cat "$log_file" >&2
    exit 1
  fi

  sed -n '1,12p' "$log_file"
  echo "expected failure: ${fixture}"
}

build_macro_package
check_compile_failure "invalid_async_missing_return" "@async functions must declare an explicit return type"
check_compile_failure "invalid_async_non_function" "@async must be placed on a function, main, or let binding"
check_compile_failure "invalid_async_let_missing_type" "@async let bindings must declare an explicit value type"
check_compile_failure "invalid_async_var_binding" "@async variable bindings only support let in v1"
check_compile_failure "invalid_await_non_call" "@await only supports future-producing calls and bindings in v2"
check_compile_failure "invalid_await_sync_call" "undeclared identifier 'get'"
