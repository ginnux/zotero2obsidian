#!/bin/bash
# 生成 CLI 草稿论文笔记
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
ASSET_DIR="$(z2o_paper_asset_dir "$CITEKEY")"
FIG_DIR="$ASSET_DIR"
OUTPUT_DIR="$Z2O_NOTES_DIR_ABS"
OUTPUT="$OUTPUT_DIR/$CITEKEY.md"
ASSET_REL_DIR="$(z2o_relpath "$ASSET_DIR" "$Z2O_NOTES_DIR_ABS")"
FIG_LINK_PREFIX="$ASSET_REL_DIR"
PDF_LINK="$(z2o_join_path "$ASSET_REL_DIR" "$CITEKEY.pdf")"
PYTHON_BIN="$(z2o_python_bin)"

mkdir -p "$OUTPUT_DIR"

if [[ ! -f "$TEXT_FILE" ]]; then
    echo "❌ 文本文件不存在，请先运行 extract.sh"
    exit 1
fi

# 列出可用的图片
FIGURES=$(find "$FIG_DIR" -maxdepth 1 -type f \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.webp' \) 2>/dev/null | sort || echo "无图片")
if [[ -f "$META_FILE" ]]; then
    ZOTERO_META=$(cat "$META_FILE")
else
    ZOTERO_META="{}"
fi

echo "📝 正在生成 CLI 草稿论文笔记..."

is_claude_cc() {
    local cmd="$1"
    local first_line
    first_line=$("$cmd" --help 2>&1 | head -1 || true)
    [[ "$first_line" == *"Claude Code"* || "$first_line" == *"Usage: claude"* ]]
}

select_note_generator() {
    if [[ -n "${Z2O_NOTE_GENERATOR:-}" ]]; then
        printf '%s\n' "$Z2O_NOTE_GENERATOR"
    else
        printf '%s\n' "local"
    fi
}

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
9. frontmatter 中使用 src_type: "zotero" 标记来源类型，不要写 source 字段
10. frontmatter 不要默认写入 status: unread

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
src_type: "zotero"
pdf: "${PDF_LINK}"
tags: [标签]
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

GENERATOR="$(select_note_generator)"
echo "🧠 笔记生成器: $GENERATOR"
if [[ "$GENERATOR" != "local" ]]; then
    echo "⚠️ 外部笔记生成器只会在显式设置 Z2O_NOTE_GENERATOR 时调用。skill 正式流程应由当前 Agent 直接写笔记。" >&2
fi

run_local_generator() {
    "$PYTHON_BIN" "$SCRIPT_DIR/generate_note.py" \
        --citekey "$CITEKEY" \
        --text-file "$TEXT_FILE" \
        --output "$OUTPUT" \
        --pdf-link "$PDF_LINK" \
        --figure-prefix "$FIG_LINK_PREFIX"
}

run_with_log() {
    local generator_name="$1"
    local log_file="$CACHE_DIR/${CITEKEY}_${generator_name}.log"
    shift

    if "$@" > "$log_file" 2>&1; then
        return 0
    fi

    echo "⚠️ $generator_name 生成失败，日志: $log_file" >&2
    return 1
}

case "$GENERATOR" in
    codex)
        if ! run_with_log codex bash -c 'codex exec --cd "$2" --sandbox read-only --color never -o "$1" -' _ "$OUTPUT" "$Z2O_PROJECT_DIR" <<< "$PROMPT"; then
            echo "⚠️ codex 生成失败，回退到本地草稿生成。" >&2
            run_local_generator
        fi
        ;;
    claude)
        if ! run_with_log claude bash -c 'claude -p --output-format text > "$1"' _ "$OUTPUT" <<< "$PROMPT"; then
            echo "⚠️ claude 生成失败，回退到本地草稿生成。" >&2
            run_local_generator
        fi
        ;;
    cc)
        if ! is_claude_cc cc; then
            echo "⚠️ cc 不是 Claude Code，回退到本地草稿生成。" >&2
            run_local_generator
        elif ! run_with_log cc bash -c 'cc -p --output-format text > "$1"' _ "$OUTPUT" <<< "$PROMPT"; then
            echo "⚠️ cc 生成失败，回退到本地草稿生成。" >&2
            run_local_generator
        fi
        ;;
    opencode)
        if ! run_with_log opencode bash -c 'opencode -p > "$1"' _ "$OUTPUT" <<< "$PROMPT"; then
            echo "⚠️ opencode 生成失败，回退到本地草稿生成。" >&2
            run_local_generator
        fi
        ;;
    local)
        run_local_generator
        ;;
    *)
        echo "❌ 不支持的 Z2O_NOTE_GENERATOR: $GENERATOR (可选: local, codex, claude, cc, opencode)" >&2
        exit 1
        ;;
esac

if [[ ! -s "$OUTPUT" ]]; then
    echo "⚠️ 生成器没有产生有效输出，回退到本地草稿生成。" >&2
    run_local_generator
fi

echo "✅ 笔记已生成: $OUTPUT"
