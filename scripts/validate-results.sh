#!/bin/sh
set -eu

check_rows() {
    file="$1"
    expected="$2"

    if [ ! -f "$file" ]; then
        echo "FAIL: Missing file: $file"
        return 1
    fi

    actual=$(awk 'END { print (NR > 0 ? NR - 1 : 0) }' "$file")

    if [ "$actual" -ne "$expected" ]; then
        echo "FAIL: $file — expected $expected cases, found $actual"
        return 1
    fi

    echo "PASS: $file — $actual cases"
}

check_constraint() {
    file="$1"
    missing_value="$2"

    if awk -v missing="$missing_value" '
        NR > 1 && (($1 == missing || $2 == missing) && $3 != "Normal") {
            print "Violation in " FILENAME ", line " NR ": " $0
            failed = 1
        }
        END { exit failed }
    ' "$file"; then
        echo "PASS: $file — missing-account constraint"
    else
        echo "FAIL: $file — missing-account constraint violated"
        return 1
    fi
}

check_rows results/browser-2way.txt 12
check_rows results/browser-3way.txt 36
check_rows results/transfer-nc.txt 26
check_rows results/transfer.txt 26
check_rows results/transfer-neg.txt 36

check_constraint results/transfer.txt Missing
check_constraint results/transfer-neg.txt '~Missing'

echo "All validation checks passed."
