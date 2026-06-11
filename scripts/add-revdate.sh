#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSIONS_DIR="${SCRIPT_DIR}/../versions"

TODAY="$(date +%F)"

find "$VERSIONS_DIR" -type f -name "*.adoc" -print0 |
while IFS= read -r -d '' file; do
    tmp="$(mktemp)"

    awk -v revdate="$TODAY" '
    BEGIN {
        found_revdate = 0
        found_page_revdate = 0
        inserted = 0
    }

    /^:revdate:[[:space:]]*/ {
        print ":revdate: " revdate
        found_revdate = 1
        next
    }

    /^:page-revdate:[[:space:]]*/ {
        print ":page-revdate: {revdate}"
        found_page_revdate = 1
        next
    }

    {
        lines[++n] = $0
    }

    END {
        start = 1

        # Handle AsciiDoc title
        if (n > 0 && lines[1] ~ /^= /) {
            print lines[1]
            start = 2

            if (!found_revdate)
                print ":revdate: " revdate

            if (!found_page_revdate)
                print ":page-revdate: {revdate}"

            print ""
            inserted = 1
        }

        for (i = start; i <= n; i++) {
            if (!inserted) {
                if (!found_revdate)
                    print ":revdate: " revdate

                if (!found_page_revdate)
                    print ":page-revdate: {revdate}"

                print ""
                inserted = 1
            }

            print lines[i]
        }

        if (n == 0) {
            print ":revdate: " revdate
            print ":page-revdate: {revdate}"
        }
    }
    ' "$file" > "$tmp"

    mv "$tmp" "$file"
    echo "Updated: $file"
done

echo "Done."