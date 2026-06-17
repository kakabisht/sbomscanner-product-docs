#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Script Name: fixup-antora-yml.sh
# Description: This script iterates through antora.yml files in the versions/
#              directory to standardize documentation metadata, including
#              product titles, names, and AsciiDoc attributes.
# -----------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSIONS_DIR="${SCRIPT_DIR}/../versions"

find "$VERSIONS_DIR" -type f -name "antora.yml" -print0 |
while IFS= read -r -d '' file; do

    # Update product name
    sed -i 's/^name: sbom-scanner/name: vulnerability-scanner/' "$file"

    # Update title 
    sed -i 's/^title:.*/title: Vulnerability Scanner/' "$file"

    # Update asciidoc attributes
    if grep -q '^asciidoc:' "$file"; then
        echo "Skipped (asciidoc already exist): $file"
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