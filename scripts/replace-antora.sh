#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSIONS_DIR="${SCRIPT_DIR}/../versions"

find "$VERSIONS_DIR" -type f -name "antora.yml" -print0 |
while IFS= read -r -d '' file; do

    if grep -q '^attributes:' "$file"; then
        echo "Skipped (attributes already exist): $file"
        continue
    fi

    cat >> "$file" <<'EOF'
asciidoc:
    attributes:
      sboms-name: SUSE Security Vulnerability Scanner
      sboms-short-name: Vulnerability Scanner
      build-type: product
EOF

    echo "Updated: $file"
done

echo "Done."