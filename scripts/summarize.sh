#!/bin/bash
# 使用 opencode 生成论文笔记
# 用法: ./summarize.sh <citekey> [vault_path]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/env.sh"

if [[ $# -lt 1 ]]; then
    echo "用法: $0 <citekey> [vault_path]" >&2
    exit 1
fi

CITEKEY="$1"
z2o_configure_paths "${2:-}"

CACHE_DIR="$Z2O_TEMP_DIR_ABS"
TEXT_FILE="$CACHE_DIR/${CITEKEY}_text.md"
META_FILE="$CACHE_DIR/${CITEKEY}_zotero.json"
FIG_DIR="$Z2O_IMAGE_DIR_ABS/$CITEKEY"
OUTPUT_DIR="$Z2O_NOTES_DIR_ABS"
OUTPUT="$OUTPUT_DIR/$CITEKEY.md"
FIG_REL_DIR="$(z2o_relpath "$Z2O_IMAGE_DIR_ABS" "$Z2O_NOTES_DIR_ABS")"
PDF_REL_DIR="$(z2o_relpath "$Z2O_PDF_DIR_ABS" "$Z2O_NOTES_DIR_ABS")"
FIG_LINK_PREFIX="$(z2o_join_path "$FIG_REL_DIR" "$CITEKEY")"
PDF_LINK="$(z2o_join_path "$PDF_REL_DIR" "$CITEKEY.pdf")"

mkdir -p "$OUTPUT_DIR"

if [[ ! -f "$TEXT_FILE" ]]; then
    echo "❌ 文本文件不存在，请先运行 extract.sh"
    exit 1
fi

# 列出可用的图片
FIGURES=$(ls "$FIG_DIR"/*.png 2>/dev/null | sort || echo "无图片")
if [[ -f "$META_FILE" ]]; then
    ZOTERO_META=$(cat "$META_FILE")
else
    ZOTERO_META="{}"
fi

echo "🤖 正在生成论文笔记..."

# 构建 prompt
PROMPT=$(cat << PROMPTEOF
你是一个论文解读专家。请根据以下 Zotero 文献 PDF 提取出的论文全文，生成一份详细的 Obsidian 笔记。

## 要求：
1. 严格按照下面的模板格式输出
2. 每个 section 都要详细展开，不要敷衍
3. 核心方法部分要像写 blog 一样，用通俗的语言解释清楚
4. 在合适的位置插入图片引用，路径使用 Markdown 相对路径：![说明|600](${FIG_LINK_PREFIX}/xxx.png)
5. 对每张图都要有解读说明
6. 相关论文部分用 [[]] 双链格式
7. frontmatter 中的 tags 要准确反映论文领域
8. 文件名和内部引用以 citekey 为唯一 ID，不要假设论文一定来自 arXiv

## 可用图片文件：
${FIGURES}

## Zotero 元数据：
${ZOTERO_META}

## 论文全文：
$(cat "$TEXT_FILE")

## 输出模板：
---
title: "论文标题"
title_zh: "论文中文标题"
authors: [作者列表]
year: 年份
citekey: "${CITEKEY}"
source: "zotero"
pdf: "${PDF_LINK}"
tags: [标签]
status: unread
rating: 
date_added: $(date +%Y-%m-%d)
tldr: "一句话概括核心贡献"
---

# 论文标题
# 论文中文标题

> **一句话总结：** 

## 📋 基本信息
- **作者：**
- **机构：**
- **发表：**
- **Zotero citekey：** ${CITEKEY}
- **PDF：** [本地 PDF](${PDF_LINK})

## 🎯 研究动机与问题

## 💡 核心方法
（详细分步骤讲解，插入相关 figure）

## 🏗️ 模型架构 / 系统设计
（插入架构图并解读）

## 📊 实验与结果
（插入关键表格/图表并分析）

### 主要发现

## 🔍 消融实验 / 分析

## 💭 个人思考
- **优点：**
- **局限：**
- **启发：**
- **可能的改进方向：**

## 🔗 相关论文
PROMPTEOF
)

# 调用 opencode 生成笔记
echo "$PROMPT" | opencode -p > "$OUTPUT"

echo "✅ 笔记已生成: $OUTPUT"
