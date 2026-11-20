#!/bin/bash

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
SHELL_TEST_DIR="$ROOT/tests"
export ROOT

pass() {
  printf 'ok - %s\n' "$1"
}

skip() {
  printf 'ok - %s # SKIP\n' "$1"
}

fail() {
  [[ -z ${2:-} ]] || printf '%s\n' "$2" >&2
  printf 'not ok - %s\n' "$1" >&2
  exit 1
}

run_node_test() {
  {
    cat <<'JS'
const path = require('node:path')
const root = process.env.ROOT
const assertions = require('node:assert/strict')
function assert(condition, description) {
  assertions.ok(condition, description)
  console.log(`ok - ${description}`)
}
function assertEqual(actual, expected, description) {
  assertions.strictEqual(actual, expected, description)
  console.log(`ok - ${description}`)
}
function assertDeepEqual(actual, expected, description) {
  assertions.deepStrictEqual(actual, expected, description)
  console.log(`ok - ${description}`)
}
function requireFromRoot(relativePath) {
  return require(path.join(root, relativePath))
}
JS
    cat
  } | node
}
