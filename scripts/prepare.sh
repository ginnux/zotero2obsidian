#!/bin/bash
# 准备 Zotero 文献材料：取 PDF → 提取文本和图片
# 用法: ./prepare.sh <citekey> [vault_path]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/env.sh"

if [[ $# -lt 1 ]]; then
    echo "用法: $0 <citekey> [vault_path]" >&2
    exit 1
fi

CITEKEY="$1"
z2o_configure_paths "${2:-}"

echo "📄 Zotero 文献材料准备启动"
echo "========================"

echo ""
echo "📥 Step 1/2: 从 Zotero 获取 PDF..."
CITEKEY=$("$SCRIPT_DIR/download.sh" "$CITEKEY" "$Z2O_VAULT" | tail -1)

echo ""
echo "🔍 Step 2/2: 提取文本和图片..."
"$SCRIPT_DIR/extract.sh" "$CITEKEY" "$Z2O_VAULT"

echo ""
echo "========================"
echo "✅ 材料准备完成，接下来由当前 skill Agent 生成正式笔记。"
echo "citekey: $CITEKEY"
echo "text: $Z2O_TEMP_DIR_ABS/${CITEKEY}_text.md"
echo "metadata: $Z2O_TEMP_DIR_ABS/${CITEKEY}_zotero.json"
echo "images: $Z2O_IMAGE_DIR_ABS/$CITEKEY/"
echo "pdf: $Z2O_PDF_DIR_ABS/$CITEKEY.pdf"
echo "note: $Z2O_NOTES_DIR_ABS/$CITEKEY.md"
