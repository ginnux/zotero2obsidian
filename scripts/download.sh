#!/bin/bash
# 从 Zotero / Better BibTeX 按 citekey 复制论文 PDF
# 用法: ./download.sh <citekey> [vault_path]

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "用法: $0 <citekey> [vault_path]" >&2
    exit 1
fi

if [[ $# -ge 2 ]]; then
    VAULT="$2"
elif [[ -n "${OBSIDIAN_VAULT:-}" ]]; then
    VAULT="$OBSIDIAN_VAULT"
else
    echo "❌ 未提供 vault_path，且 OBSIDIAN_VAULT 未设置" >&2
    exit 1
fi

CITEKEY="$1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ -n "${PYTHON:-}" ]]; then
    PYTHON_BIN="$PYTHON"
elif command -v python >/dev/null 2>&1; then
    PYTHON_BIN="python"
else
    PYTHON_BIN="python3"
fi

echo "📥 从 Zotero 获取论文 PDF: $CITEKEY"

if [[ -n "${BBT_JSON_RPC_URL:-}" ]]; then
    "$PYTHON_BIN" "$SCRIPT_DIR/fetch_zotero_pdf.py" "$CITEKEY" "$VAULT" --bbt-url "$BBT_JSON_RPC_URL"
else
    "$PYTHON_BIN" "$SCRIPT_DIR/fetch_zotero_pdf.py" "$CITEKEY" "$VAULT"
fi
