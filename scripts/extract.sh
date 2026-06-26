#!/bin/bash
# 从 PDF 中提取文本和图片
# 用法: ./extract.sh <citekey> [vault_path]

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

PDF_PATH="$Z2O_PDF_DIR_ABS/$CITEKEY.pdf"
FIG_DIR="$Z2O_IMAGE_DIR_ABS/$CITEKEY"
CACHE_DIR="$Z2O_TEMP_DIR_ABS"
TEXT_PATH="$CACHE_DIR/${CITEKEY}_text.md"
EXTRACTOR="${Z2O_EXTRACTOR:-auto}"

if [[ ! -f "$PDF_PATH" ]]; then
    echo "❌ PDF 不存在: $PDF_PATH"
    exit 1
fi

mkdir -p "$FIG_DIR"
mkdir -p "$CACHE_DIR"

echo "🔍 提取图片和文本..."

run_mineru() {
    "$PYTHON_BIN" "$SCRIPT_DIR/mineru_extract.py" "$CITEKEY" "$PDF_PATH" "$TEXT_PATH" "$FIG_DIR" "$CACHE_DIR"
}

run_pymupdf() {
    "$PYTHON_BIN" - "$CITEKEY" "$PDF_PATH" "$FIG_DIR" "$CACHE_DIR" << 'PYEOF'
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
pdf_path = sys.argv[2]
fig_dir = sys.argv[3]
cache_dir = sys.argv[4]

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
}

case "$EXTRACTOR" in
    mineru)
        run_mineru
        ;;
    pymupdf)
        run_pymupdf
        ;;
    auto)
        if [[ -n "${MINERU_API_TOKEN:-${MINERU_TOKEN:-}}" ]]; then
            if ! run_mineru; then
                echo "⚠️ MinerU 提取失败，回退到 PyMuPDF 本地提取。" >&2
                run_pymupdf
            fi
        else
            echo "ℹ️ 未配置 MINERU_API_TOKEN / MINERU_TOKEN，使用 PyMuPDF 本地提取。"
            run_pymupdf
        fi
        ;;
    *)
        echo "❌ 不支持的 Z2O_EXTRACTOR: $EXTRACTOR (可选: auto, mineru, pymupdf)" >&2
        exit 1
        ;;
esac

echo "✅ 图片保存至: $FIG_DIR"
echo "✅ 文本保存至: $TEXT_PATH"
