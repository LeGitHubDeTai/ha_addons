#!/bin/bash
set -euo pipefail

# generate-update-steps
# Generates .updates/<addon>.sh scripts and the unified auto-upgrades workflow.
# Usage: bash .scripts/generate-update-steps.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== generate-update-steps ==="
echo "Running Python generator..."

# Try python3 first, then py (Windows), then python
python3 "$SCRIPT_DIR/gen_updates.py" 2>/dev/null || \
  py -X utf8 "$SCRIPT_DIR/gen_updates.py" 2>/dev/null || \
  python "$SCRIPT_DIR/gen_updates.py" 2>/dev/null || {
    echo "ERROR: Could not find Python. Please install Python and ensure it's in PATH."
    exit 1
  }

echo ""
echo "=== Done ==="
echo "Generated addon scripts in $REPO_ROOT/.updates/"
echo "Generated workflow at $REPO_ROOT/.github/workflows/auto-upgrades.yml"
echo ""
echo "To use:"
echo "  1. Review the generated files"
echo "  2. Commit and push"
echo "  3. Run: gh workflow run auto-upgrades.yml"
echo ""
echo "To add a new addon:"
echo "  1. Add a new .updates/<addon_name>.sh script"
echo "  2. The workflow will automatically discover it"
