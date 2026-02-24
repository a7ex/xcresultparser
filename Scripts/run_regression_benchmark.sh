#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEST_DIR="$ROOT_DIR/TestResults"
NEW_BIN="$TEST_DIR/xcresultparser"
OLD_BIN="$TEST_DIR/lastVersion/xcresultparser"
NEW_OUT_DIR="$TEST_DIR/newResults"
OLD_OUT_DIR="$TEST_DIR/oldResults"
CSV_FILE="$TEST_DIR/timings.csv"
MD_FILE="$TEST_DIR/timings.md"
CHART_CSV_FILE="$TEST_DIR/timings_chart.csv"
RAW_CSV_FILE="$TEST_DIR/.timings_raw.csv"

TEST_BUNDLE="$ROOT_DIR/Tests/XcresultparserTests/TestAssets/test.xcresult"
ERROR_BUNDLE="$ROOT_DIR/Tests/XcresultparserTests/TestAssets/resultWithCompileError.xcresult"
SUFFIX=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bundle)
      TEST_BUNDLE="$2"
      shift 2
      ;;
    --error-bundle)
      ERROR_BUNDLE="$2"
      shift 2
      ;;
    --suffix)
      SUFFIX="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$ERROR_BUNDLE" ]]; then
  ERROR_BUNDLE="$TEST_BUNDLE"
fi
if [[ -n "$SUFFIX" ]]; then
  NEW_OUT_DIR="$TEST_DIR/newResults_${SUFFIX}"
  OLD_OUT_DIR="$TEST_DIR/oldResults_${SUFFIX}"
  CSV_FILE="$TEST_DIR/timings_${SUFFIX}.csv"
  MD_FILE="$TEST_DIR/timings_${SUFFIX}.md"
  CHART_CSV_FILE="$TEST_DIR/timings_chart_${SUFFIX}.csv"
  RAW_CSV_FILE="$TEST_DIR/.timings_raw_${SUFFIX}.csv"
fi

mkdir -p "$NEW_OUT_DIR" "$OLD_OUT_DIR"
rm -f "$NEW_OUT_DIR"/* "$OLD_OUT_DIR"/* "$CSV_FILE" "$MD_FILE" "$CHART_CSV_FILE" "$RAW_CSV_FILE"

if [[ ! -x "$NEW_BIN" ]]; then
  echo "Missing executable: $NEW_BIN" >&2
  exit 1
fi
if [[ ! -x "$OLD_BIN" ]]; then
  echo "Missing executable: $OLD_BIN" >&2
  exit 1
fi

echo "version,case,binary,bundle,seconds,exit_code,bytes,sha256" > "$RAW_CSV_FILE"

run_case() {
  local version_label="$1"
  local bin="$2"
  local out_dir="$3"
  local case_name="$4"
  local bundle="$5"
  shift 5
  local args=("$@")

  local out_file="$out_dir/${case_name}.out"
  local err_file="$out_dir/${case_name}.stderr"
  local time_file="$out_dir/${case_name}.time"

  local rc=0
  /usr/bin/time -p -o "$time_file" "$bin" "${args[@]}" "$bundle" > "$out_file" 2> "$err_file" || rc=$?

  local seconds
  seconds=$(awk '/^real /{print $2}' "$time_file" | tail -n 1)
  [[ -z "$seconds" ]] && seconds="NA"

  local bytes
  bytes=$(wc -c < "$out_file" | tr -d ' ')

  local checksum
  checksum=$(shasum -a 256 "$out_file" | awk '{print $1}')

  echo "$version_label,$case_name,$bin,$bundle,$seconds,$rc,$bytes,$checksum" >> "$RAW_CSV_FILE"
}

run_version() {
  local version_label="$1"
  local bin="$2"
  local out_dir="$3"

  run_case "$version_label" "$bin" "$out_dir" "txt" "$TEST_BUNDLE" -o txt
  run_case "$version_label" "$bin" "$out_dir" "cli" "$TEST_BUNDLE" -o cli
  run_case "$version_label" "$bin" "$out_dir" "html" "$TEST_BUNDLE" -o html
  run_case "$version_label" "$bin" "$out_dir" "md" "$TEST_BUNDLE" -o md
  run_case "$version_label" "$bin" "$out_dir" "junit" "$TEST_BUNDLE" -o junit
  run_case "$version_label" "$bin" "$out_dir" "xml_tests" "$TEST_BUNDLE" -o xml
  run_case "$version_label" "$bin" "$out_dir" "xml_coverage" "$TEST_BUNDLE" -c -o xml
  run_case "$version_label" "$bin" "$out_dir" "cobertura" "$TEST_BUNDLE" -o cobertura
  run_case "$version_label" "$bin" "$out_dir" "warnings" "$TEST_BUNDLE" -o warnings
  run_case "$version_label" "$bin" "$out_dir" "errors" "$ERROR_BUNDLE" -o errors
  run_case "$version_label" "$bin" "$out_dir" "warnings_and_errors" "$ERROR_BUNDLE" -o warnings-and-errors
}

run_version "new" "$NEW_BIN" "$NEW_OUT_DIR"
run_version "old" "$OLD_BIN" "$OLD_OUT_DIR"

awk -F',' '
  NR==1 {next}
  {
    version=$1
    key=$2
    sec=$5
    bytes=$7
    if (version=="new") {
      new_sec[key]=sec
      new_bytes[key]=bytes
    } else if (version=="old") {
      old_sec[key]=sec
      old_bytes[key]=bytes
    }
    keys[key]=1
  }
  END {
    print "case,seconds_old,seconds_new,bytes_old,bytes_new"
    for (k in keys) {
      printf "%s,%s,%s,%s,%s\n", k, old_sec[k], new_sec[k], old_bytes[k], new_bytes[k]
    }
  }
' "$RAW_CSV_FILE" | sort > "$CSV_FILE"

cat > "$MD_FILE" <<'HEADER'
# Regression Timing And Output Comparison

| Case | New (s) | Old (s) | Delta (s) | New/Old |
|---|---:|---:|---:|---:|
HEADER

awk -F',' '
  NR==1 {next}
  {
    key=$1
    os=$2+0
    ns=$3+0
    delta=ns-os
    ratio=(os==0)?0:(ns/os)
    printf "| %s | %.3f | %.3f | %.3f | %.3f |\n", key, ns, os, delta, ratio
  }
' "$CSV_FILE" >> "$MD_FILE"

CASE_ORDER="txt cli html md junit xml_tests xml_coverage cobertura warnings errors warnings_and_errors"

awk -F',' -v order="$CASE_ORDER" '
  BEGIN {
    split(order, ordered, " ")
  }
  NR==1 {next}
  {
    key=$1
    old_sec=$2
    new_sec=$3
    value["old",key]=old_sec
    value["new",key]=new_sec
  }
  END {
    printf "version"
    for (i=1; i<=length(ordered); i++) {
      if (ordered[i] != "") {
        printf ",%s", ordered[i]
      }
    }
    printf "\n"
    versions[1]="new"
    versions[2]="old"
    for (v=1; v<=2; v++) {
      ver=versions[v]
      printf "%s", ver
      for (i=1; i<=length(ordered); i++) {
        key=ordered[i]
        if (key != "") {
          printf ",%s", value[ver,key]
        }
      }
      printf "\n"
    }
  }
' "$CSV_FILE" > "$CHART_CSV_FILE"

{
  echo ""
  echo "## Timing Matrix"
  echo ""
  echo "| Version | txt | cli | html | md | junit | xml_tests | xml_coverage | cobertura | warnings | errors | warnings_and_errors |"
  echo "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|"
  awk -F',' 'NR>1 {printf "| %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |\n", $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12}' "$CHART_CSV_FILE"
} >> "$MD_FILE"

echo "Created:"
echo "- $CSV_FILE"
echo "- $MD_FILE"
echo "- $CHART_CSV_FILE"
echo "- $NEW_OUT_DIR"
echo "- $OLD_OUT_DIR"
