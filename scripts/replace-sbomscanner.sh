#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSIONS_DIR="${SCRIPT_DIR}/../versions"

find "$VERSIONS_DIR" -type f -name "*.adoc" -print0 |
while IFS= read -r -d '' file; do
    tmp="$(mktemp)"

    awk '
    BEGIN {
        in_md_fence = 0
        in_listing  = 0
        in_literal  = 0
        in_source   = 0

        pending_source_block = 0
        source_delim = ""

        replaced   = 0
        target     = "SBOMscanner"
        tlen       = length(target)
        first_repl = "{sbom-name}"
        rest_repl  = "{sbom-short-name}"
    }

    # Markdown fenced code blocks
    /^[[:space:]]*```/ {
        in_md_fence = 1 - in_md_fence
        print
        next
    }

    # [source,bash], [source,yaml], [listing], etc.
    /^[[:space:]]*\[(source|listing)(,.*)?\][[:space:]]*$/ {
        pending_source_block = 1
        print
        next
    }

    # Any other AsciiDoc attribute line
    /^[[:space:]]*\[.*\][[:space:]]*$/ {
        print
        next
    }

    # Opening/closing source block delimiters
    pending_source_block &&
    /^[[:space:]]*(====+|----+)[[:space:]]*$/ {
        source_delim = $0
        in_source = 1
        pending_source_block = 0
        print
        next
    }

    in_source && $0 == source_delim {
        in_source = 0
        source_delim = ""
        print
        next
    }

    # Standard listing blocks
    /^[[:space:]]*----+[[:space:]]*$/ {
        in_listing = 1 - in_listing
        print
        next
    }

    # Literal blocks
    /^[[:space:]]*\.\.\.\.+[[:space:]]*$/ {
        in_literal = 1 - in_literal
        print
        next
    }

    # Skip all code/literal blocks
    (in_md_fence || in_listing || in_literal || in_source) {
        print
        next
    }

    {
        line = $0
        out  = ""

        while (length(line) > 0) {
            tick_pos    = index(line, "`")
            scanner_pos = index(line, target)

            if (scanner_pos == 0) {
                out = out line
                break
            }

            if (tick_pos > 0 && tick_pos < scanner_pos) {
                out  = out substr(line, 1, tick_pos)
                line = substr(line, tick_pos + 1)

                close_pos = index(line, "`")

                if (close_pos > 0) {
                    out  = out substr(line, 1, close_pos)
                    line = substr(line, close_pos + 1)
                } else {
                    out = out line
                    line = ""
                }
            }
            else {
                out = out substr(line, 1, scanner_pos - 1)

                if (replaced == 0) {
                    out = out first_repl
                    replaced = 1
                } else {
                    out = out rest_repl
                }

                line = substr(line, scanner_pos + tlen)
            }
        }

        print out
    }
    ' "$file" > "$tmp"

    mv "$tmp" "$file"
    echo "Updated: $file"
done

echo "Done."