#!/bin/bash
# 生成论文索引（按主题、作者、时间线）
# 用法: ./index.sh [vault_path]

set -euo pipefail

if [[ $# -ge 1 ]]; then
    VAULT="$1"
elif [[ -n "${OBSIDIAN_VAULT:-}" ]]; then
    VAULT="$OBSIDIAN_VAULT"
else
    echo "❌ 未提供 vault_path，且 OBSIDIAN_VAULT 未设置" >&2
    exit 1
fi

PAPERS_DIR="$VAULT/papers/notes"
INDEX_DIR="$VAULT/papers/index"

mkdir -p "$PAPERS_DIR"
mkdir -p "$INDEX_DIR"

echo "📚 生成论文索引..."

frontmatter_line() {
    local pattern="$1"
    local file="$2"
    grep -m 1 "$pattern" "$file" 2>/dev/null || true
}

status_list() {
    local status="$1"
    grep -rl "status: $status" "$PAPERS_DIR" 2>/dev/null \
        | while read -r f; do echo "- [[$(basename "$f" .md)]]"; done \
        || true
}

PAPER_LIST=""
for f in "$PAPERS_DIR"/*.md; do
    if [[ -f "$f" ]]; then
        # 提取 frontmatter
        TITLE=$(frontmatter_line '^title:' "$f" | sed 's/title: *"*//;s/"*$//')
        TAGS=$(frontmatter_line '^tags:' "$f")
        YEAR=$(frontmatter_line '^year:' "$f")
        FNAME=$(basename "$f" .md)
        PAPER_LIST+="- [[$FNAME|$TITLE]] $TAGS $YEAR\n"
    fi
done

# 生成阅读列表
cat > "$INDEX_DIR/reading-list.md" << EOF
# 📚 论文阅读列表

> 自动生成于 $(date +%Y-%m-%d)

## 全部论文
$(echo -e "$PAPER_LIST")

## 按状态

### 📖 待读
$(status_list unread)

### 📝 在读
$(status_list reading)

### ✅ 已读
$(status_list done)
EOF

echo "✅ 索引已更新: $INDEX_DIR/"
