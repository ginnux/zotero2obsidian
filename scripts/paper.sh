#!/bin/bash
# 一键处理 Zotero 文献：取 PDF → 提取 → 生成本地草稿 → 更新索引
# 用法: ./paper.sh <citekey> [vault_path]
#
# 环境变量:
#   Z2O_VAULT 或 OBSIDIAN_VAULT - Obsidian vault 的路径
#
# 示例:
#   cp .env.example .env
#   ./paper.sh ouyang2026reasoningbank

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/env.sh"

if [[ $# -lt 1 ]]; then
    echo "用法: $0 <citekey> [vault_path]" >&2
    exit 1
fi

CITEKEY="$1"
z2o_configure_paths "${2:-}"

echo "📄 Zotero 文献处理流水线启动"
echo "========================"

# Step 1: 从 Zotero 取 PDF
echo ""
echo "📥 Step 1/4: 从 Zotero 获取 PDF..."
CITEKEY=$("$SCRIPT_DIR/download.sh" "$CITEKEY" "$Z2O_VAULT" | tail -1)

# Step 2: 提取
echo ""
echo "🔍 Step 2/4: 提取文本和图片..."
"$SCRIPT_DIR/extract.sh" "$CITEKEY" "$Z2O_VAULT"

# Step 3: 生成本地草稿笔记
echo ""
echo "📝 Step 3/4: 生成本地草稿笔记..."
"$SCRIPT_DIR/summarize.sh" "$CITEKEY" "$Z2O_VAULT"

# Step 4: 更新索引
echo ""
echo "📚 Step 4/4: 更新论文索引..."
"$SCRIPT_DIR/index.sh" "$Z2O_VAULT"

echo ""
echo "========================"
echo "🎉 完成！论文笔记: $Z2O_NOTES_DIR_ABS/$CITEKEY.md"
echo "📂 图片目录: $Z2O_IMAGE_DIR_ABS/$CITEKEY/"
echo "📄 原始 PDF: $Z2O_PDF_DIR_ABS/$CITEKEY.pdf"
