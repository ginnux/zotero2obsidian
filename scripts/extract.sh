#!/bin/bash
# 从 PDF 中提取文本和图片
# 用法: ./extract.sh <citekey> [vault_path]

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "用法: $0 <citekey> [vault_path]" >&2
    exit 1
fi

CITEKEY="$1"

if [[ $# -ge 2 ]]; then
    VAULT="$2"
elif [[ -n "${OBSIDIAN_VAULT:-}" ]]; then
    VAULT="$OBSIDIAN_VAULT"
else
    echo "❌ 未提供 vault_path，且 OBSIDIAN_VAULT 未设置" >&2
    exit 1
fi

PDF_PATH="$VAULT/assets/pdfs/$CITEKEY.pdf"
FIG_DIR="$VAULT/assets/png/$CITEKEY"
CACHE_DIR="$VAULT/.paper-cache"
if [[ -n "${PYTHON:-}" ]]; then
    PYTHON_BIN="$PYTHON"
elif command -v python >/dev/null 2>&1; then
    PYTHON_BIN="python"
else
    PYTHON_BIN="python3"
fi

if [[ ! -f "$PDF_PATH" ]]; then
    echo "❌ PDF 不存在: $PDF_PATH"
    exit 1
fi

mkdir -p "$FIG_DIR"
mkdir -p "$CACHE_DIR"

echo "🔍 提取图片和文本..."

# 使用 Python 提取图片和文本
"$PYTHON_BIN" - "$CITEKEY" "$VAULT" << 'PYEOF'
import sys

try:
    import fitz  # pymupdf
except ModuleNotFoundError:
    print(
        "❌ 缺少 PyMuPDF（fitz）。请运行 `pip install pymupdf`，"
        "或设置 `PYTHON=/path/to/python` 指向已安装 PyMuPDF 的解释器。",
        file=sys.stderr,
    )
    raise SystemExit(1)

citekey = sys.argv[1]
vault = sys.argv[2]

pdf_path = f"{vault}/assets/pdfs/{citekey}.pdf"
fig_dir = f"{vault}/assets/png/{citekey}"
cache_dir = f"{vault}/.paper-cache"

doc = fitz.open(pdf_path)

# 提取全文
full_text = ""
for page in doc:
    full_text += page.get_text() + "\n\n"

# 保存全文
with open(f"{cache_dir}/{citekey}_text.md", "w", encoding="utf-8") as f:
    f.write(full_text)

# 提取图片
img_count = 0
for page_num in range(len(doc)):
    page = doc[page_num]
    images = page.get_images(full=True)
    for img_idx, img in enumerate(images):
        xref = img[0]
        pix = fitz.Pixmap(doc, xref)
        if pix.n < 5:  # GRAY or RGB
            img_path = f"{fig_dir}/page{page_num+1}_img{img_idx+1}.png"
            pix.save(img_path)
        else:  # CMYK: convert to RGB
            pix2 = fitz.Pixmap(fitz.csRGB, pix)
            img_path = f"{fig_dir}/page{page_num+1}_img{img_idx+1}.png"
            pix2.save(img_path)
        img_count += 1

# 也把每页渲染成图片（用于捕获 figure/table 的完整渲染）
for page_num in range(len(doc)):
    page = doc[page_num]
    # 2x 分辨率渲染
    mat = fitz.Matrix(2, 2)
    pix = page.get_pixmap(matrix=mat)
    pix.save(f"{fig_dir}/page_{page_num+1}.png")

print(f"✅ 提取完成: {img_count} 张嵌入图片, {len(doc)} 页渲染图")

doc.close()
PYEOF

echo "✅ 图片保存至: $FIG_DIR"
echo "✅ 文本保存至: $CACHE_DIR/${CITEKEY}_text.md"
