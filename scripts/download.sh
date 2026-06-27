#!/bin/bash
# 从 Zotero / Better BibTeX 按 citekey 复制论文 PDF
# 用法: ./download.sh <citekey> [vault_path]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/env.sh"

if [[ $# -lt 1 ]]; then
    echo "用法: $0 <citekey> [vault_path]" >&2
    exit 1
fi

CITEKEY="$1"
z2o_configure_paths "${2:-}"
PYTHON_BIN="$(z2o_python_bin)"
ASSETS_DIR="$Z2O_ASSETS_DIR_ABS"

echo "📥 从 Zotero 获取论文 PDF: $CITEKEY"

if [[ -n "${BBT_JSON_RPC_URL:-}" ]]; then
    "$PYTHON_BIN" "$SCRIPT_DIR/fetch_zotero_pdf.py" "$CITEKEY" "$Z2O_VAULT" \
        --asset-dir "$ASSETS_DIR" \
        --cache-dir "$Z2O_TEMP_DIR_ABS" \
        --bbt-url "$BBT_JSON_RPC_URL"
else
    "$PYTHON_BIN" "$SCRIPT_DIR/fetch_zotero_pdf.py" "$CITEKEY" "$Z2O_VAULT" \
        --asset-dir "$ASSETS_DIR" \
        --cache-dir "$Z2O_TEMP_DIR_ABS"
fi
