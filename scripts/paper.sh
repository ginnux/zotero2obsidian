#!/bin/bash
# 一键处理 Zotero 文献：取 PDF → 提取 → 生成笔记 → 更新索引
# 用法: ./paper.sh <citekey> [vault_path]
#
# 环境变量:
#   OBSIDIAN_VAULT - Obsidian vault 的路径
#
# 示例:
#   export OBSIDIAN_VAULT=~/Documents/MyVault
#   ./paper.sh ouyang2026reasoningbank

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "用法: $0 <citekey> [vault_path]" >&2
    exit 1
fi

SCRIPT_DIR="$(dirname "$0")"
CITEKEY="$1"

if [[ $# -ge 2 ]]; then
    VAULT="$2"
elif [[ -n "${OBSIDIAN_VAULT:-}" ]]; then
    VAULT="$OBSIDIAN_VAULT"
else
    echo "❌ 未提供 vault_path，且 OBSIDIAN_VAULT 未设置" >&2
    exit 1
fi

export OBSIDIAN_VAULT="$VAULT"

echo "📄 Zotero 文献处理流水线启动"
echo "========================"

# Step 1: 从 Zotero 取 PDF
echo ""
echo "📥 Step 1/4: 从 Zotero 获取 PDF..."
CITEKEY=$("$SCRIPT_DIR/download.sh" "$CITEKEY" "$VAULT" | tail -1)

# Step 2: 提取
echo ""
echo "🔍 Step 2/4: 提取文本和图片..."
"$SCRIPT_DIR/extract.sh" "$CITEKEY" "$VAULT"

# Step 3: 生成笔记
echo ""
echo "🤖 Step 3/4: AI 生成论文笔记..."
"$SCRIPT_DIR/summarize.sh" "$CITEKEY" "$VAULT"

# Step 4: 更新索引
echo ""
echo "📚 Step 4/4: 更新论文索引..."
"$SCRIPT_DIR/index.sh" "$VAULT"

echo ""
echo "========================"
echo "🎉 完成！论文笔记: $VAULT/papers/notes/$CITEKEY.md"
echo "📂 图片目录: $VAULT/assets/png/$CITEKEY/"
echo "📄 原始 PDF: $VAULT/assets/pdfs/$CITEKEY.pdf"
