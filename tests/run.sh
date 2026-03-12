#!/bin/bash

set -euo pipefail

MODE="${1:-all}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

run_unit_tests() {
  echo "==> unit tests"
  (
    cd "$ROOT_DIR/tests/examples"
    set +u
    source "$HOME/cangjie/envsetup.sh"
    set -u
    cjpm test --no-progress
  )
}

run_compile_fail_tests() {
  echo "==> compile-fail tests"
  "$ROOT_DIR/tests/compile_fail/run.sh"
}

case "$MODE" in
  unit)
    run_unit_tests
    ;;
  compile-fail)
    run_compile_fail_tests
    ;;
  all)
    run_unit_tests
    run_compile_fail_tests
    ;;
  *)
    echo "usage: $0 [unit|compile-fail|all]" >&2
    exit 1
    ;;
esac
