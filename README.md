# Zotero2Obsidian Skills

[English](#english) | [中文](#中文)

Agent skills for reading papers from a local Zotero library and writing structured Chinese reading notes in an Obsidian vault. The reading flow uses Better BibTeX citekeys as stable IDs: you provide a unique citekey, the skill asks Zotero for the PDF attachment, copies it into the vault, extracts text/images, and generates a note.

---

<a id="english"></a>

## Available Skills

### read-zotero-paper

Read a paper from Zotero by Better BibTeX citekey and generate an in-depth Obsidian note.

**Use when:**

```text
Read ouyang2026reasoningbank
Read these papers: keyA2025, keyB2026
```

**Features:**

- Uses Better BibTeX JSON-RPC `item.attachments`
- Copies the selected PDF attachment to `assets/pdfs/{citekey}.pdf`
- Extracts text and images into `.paper-cache/` and `assets/png/{citekey}/`
- Generates a structured Chinese note at `papers/notes/{citekey}.md`
- Supports `.env` configuration for vault and directory layout
- Prefers MinerU precise parsing for text/elements when configured
- Uses citekey for filenames, wikilinks, and frontmatter IDs
- Auto-updates the paper index after notes are generated

### paper-index

Scan paper notes and maintain categorized Obsidian Bases files.

### paper-summary

Generate structured survey reports from multiple related paper notes.

## Prerequisites

1. Zotero is running.
2. Better BibTeX is installed and enabled in Zotero.
3. Better BibTeX JSON-RPC is reachable at:

```text
http://localhost:23119/better-bibtex/json-rpc
```

4. Python dependencies:

```bash
pip install pymupdf
```

If PyMuPDF is installed in a non-default interpreter, pass it explicitly:

```bash
PYTHON=/path/to/python ./scripts/extract.sh ouyang2026reasoningbank "$OBSIDIAN_VAULT"
```

5. Configure paths with `.env`:

```bash
cp .env.example .env
```

Then edit `.env`:

```bash
Z2O_VAULT="/absolute/path/to/your/vault"
Z2O_NOTES_DIR="papers/notes"
Z2O_INDEX_DIR="papers/index"
Z2O_SUMMARY_DIR="knowledge/Summary"
Z2O_TEMP_DIR=".paper-cache"
Z2O_PDF_DIR="assets/pdfs"
Z2O_IMAGE_DIR="assets/png"
```

Directory values may be relative to `Z2O_VAULT` or absolute. The scripts still support `OBSIDIAN_VAULT` for backward compatibility, and an explicit `vault_path` argument overrides `.env`.

6. Optional: enable MinerU precise parsing:

```bash
Z2O_EXTRACTOR="auto"
MINERU_API_TOKEN="your-token"
MINERU_MODEL_VERSION="vlm"
MINERU_LANGUAGE="ch"
```

With `Z2O_EXTRACTOR=auto`, `extract.sh` uses MinerU first when a token exists, then falls back to PyMuPDF if MinerU is unavailable. Use `Z2O_EXTRACTOR=mineru` to require MinerU, or `Z2O_EXTRACTOR=pymupdf` to force local extraction.

7. Optional: choose the CLI note generator:

```bash
Z2O_NOTE_GENERATOR="local"
```

When unset, `summarize.sh` uses the deterministic local draft generator. The recommended skill workflow does not call another LLM command to write the formal note; the current Agent reads the extracted text and images and writes `papers/notes/{citekey}.md` directly. Legacy external generators (`codex`, `cc`, `claude`, `opencode`) are only used when explicitly set with `Z2O_NOTE_GENERATOR`.

## Zotero PDF Lookup

The workflow calls Better BibTeX like this:

```bash
curl http://localhost:23119/better-bibtex/json-rpc \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  --data-binary '{
    "jsonrpc": "2.0",
    "method": "item.attachments",
    "params": ["ouyang2026reasoningbank", "*"],
    "id": 1
  }'
```

Only `.pdf` attachments are used. HTML snapshots or other files are ignored.

## Vault Structure

```text
your-vault/
├── assets/
│   ├── pdfs/
│   │   └── ouyang2026reasoningbank.pdf
│   └── png/
│       └── ouyang2026reasoningbank/
│           ├── page1_img1.png
│           └── page_1.png
├── papers/
│   ├── index/
│   │   ├── All-Papers.base
│   │   └── Reasoning.base
│   └── notes/
│       └── ouyang2026reasoningbank.md
├── knowledge/
│   └── Summary/
└── .paper-cache/
    ├── ouyang2026reasoningbank_text.md
    └── ouyang2026reasoningbank_zotero.json
```

## Script Usage

Recommended Agent skill flow:

```bash
./scripts/prepare.sh ouyang2026reasoningbank
```

`prepare.sh` only downloads the Zotero PDF and extracts text/images. The current skill Agent then reads `.paper-cache/{citekey}_text.md`, selects key figures from `assets/png/{citekey}/`, writes the formal note, and runs `./scripts/index.sh`.

Run the full CLI fallback pipeline:

```bash
./scripts/paper.sh ouyang2026reasoningbank
```

The CLI fallback generates a deterministic local draft note by default. It is useful for smoke tests and non-Agent use, but the skill-generated note is the higher-quality path.

Or run each step:

```bash
./scripts/download.sh ouyang2026reasoningbank
./scripts/extract.sh ouyang2026reasoningbank
./scripts/summarize.sh ouyang2026reasoningbank
./scripts/index.sh
```

For temporary tests, pass a vault path explicitly:

```bash
./scripts/extract.sh ouyang2026reasoningbank /private/tmp/z2o-smoke
```

## Skill Structure

```text
zotero2obsidian/
├── skills/
│   ├── read-zotero-paper/
│   │   └── SKILL.md
│   ├── paper-index/
│   │   └── SKILL.md
│   └── paper-summary/
│       └── SKILL.md
├── scripts/
│   ├── fetch_zotero_pdf.py
│   ├── mineru_extract.py
│   ├── env.sh
│   ├── prepare.sh
│   ├── download.sh
│   ├── extract.sh
│   ├── summarize.sh
│   ├── index.sh
│   └── paper.sh
└── templates/
```

## License

MIT

---

<a id="中文"></a>

## 中文说明

### 这是什么？

这是一个把 Zotero 文献库接入 Obsidian 阅读流程的 Agent Skills 仓库。之后读论文时，你只需要输入 Better BibTeX 的唯一 `citekey`，skill 会从 Zotero 条目中找到 PDF 附件，复制到 Obsidian vault，再提取全文和图片，生成中文深度阅读笔记。

### 包含的 Skills

| Skill | 说明 |
| --- | --- |
| `read-zotero-paper` | 按 citekey 从 Zotero 获取 PDF，提取全文和图片，生成论文解读笔记 |
| `paper-index` | 使用 Obsidian Bases 维护论文笔记数据库 |
| `paper-summary` | 根据多篇论文笔记生成综述报告 |

### 前置依赖

```bash
pip install pymupdf
cp .env.example .env
```

在 `.env` 中配置：

```bash
Z2O_VAULT="/你的Vault绝对路径"
Z2O_NOTES_DIR="papers/notes"
Z2O_INDEX_DIR="papers/index"
Z2O_SUMMARY_DIR="knowledge/Summary"
Z2O_TEMP_DIR=".paper-cache"
Z2O_PDF_DIR="assets/pdfs"
Z2O_IMAGE_DIR="assets/png"
```

这些目录可以写相对于 vault 的路径，也可以写绝对路径。`OBSIDIAN_VAULT` 仍然兼容；命令行传入的 `vault_path` 优先级最高。

可选：启用 MinerU 精准识别：

```bash
Z2O_EXTRACTOR="auto"
MINERU_API_TOKEN="你的MinerU token"
MINERU_MODEL_VERSION="vlm"
MINERU_LANGUAGE="ch"
```

`auto` 模式会在配置 token 后优先调用 MinerU 精准解析；未配置 token 或 MinerU 不可用时回退 PyMuPDF。本地强制模式可用 `Z2O_EXTRACTOR=pymupdf`，强制 MinerU 可用 `Z2O_EXTRACTOR=mineru`。

可选：指定 CLI 草稿生成器：

```bash
Z2O_NOTE_GENERATOR="local"
```

不配置时，`summarize.sh` 只使用确定性的本地草稿生成器。推荐的 skill 流程不会再调用另一个 LLM 命令生成正式笔记；当前 Agent 会读取提取出的全文和图片，直接写入 `papers/notes/{citekey}.md`。历史兼容的外部生成器（`codex`、`cc`、`claude`、`opencode`）只有在显式设置 `Z2O_NOTE_GENERATOR` 时才会调用。

如果 PyMuPDF 装在非默认解释器里，可以在 `.env` 中设置 `PYTHON=/path/to/python`。

同时需要：

- Zotero 正在运行
- Better BibTeX 已安装并启用
- Better BibTeX JSON-RPC 地址可访问：`http://localhost:23119/better-bibtex/json-rpc`

### 使用方式

安装 skill 后直接和 agent 对话：

```text
帮我读 ouyang2026reasoningbank
```

本地脚本也可以直接运行：

```bash
./scripts/prepare.sh ouyang2026reasoningbank
./scripts/paper.sh ouyang2026reasoningbank
```

`prepare.sh` 是 skill 推荐入口，只准备 PDF、全文和图片；随后由当前 Agent 写正式笔记并更新索引。`paper.sh` 是纯 CLI 兜底流程，默认只生成本地草稿。

### 目录结构

```text
your-vault/
├── assets/
│   ├── pdfs/                  # 从 Zotero 复制出的 PDF
│   └── png/                   # 从 PDF 提取出的图片和页面渲染
├── papers/
│   ├── index/                 # Obsidian Bases 索引
│   └── notes/                 # 论文笔记，以 citekey 命名
├── knowledge/
│   └── Summary/               # 综述报告
└── .paper-cache/              # 提取文本和 Zotero 附件缓存
```

### 笔记特点

- 中文撰写，保留英文原标题
- citekey 是唯一 ID，用于文件名、wikilink 和 frontmatter
- 侧重研究动机和核心方法，适合大模型研究者
- 图片引用 `Z2O_IMAGE_DIR/{citekey}/` 下的关键图或页面渲染，脚本会按笔记目录计算相对路径

### 自定义

- 写作风格：`skills/read-zotero-paper/SKILL.md`
- 分类规则：`skills/paper-index/SKILL.md`
- 综述结构：`skills/paper-summary/SKILL.md`

### License

MIT
