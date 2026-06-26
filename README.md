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

5. Set your Obsidian vault path:

```bash
export OBSIDIAN_VAULT="$HOME/path/to/your/vault"
```

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

Run the full local pipeline:

```bash
./scripts/paper.sh ouyang2026reasoningbank "$OBSIDIAN_VAULT"
```

Or run each step:

```bash
./scripts/download.sh ouyang2026reasoningbank "$OBSIDIAN_VAULT"
./scripts/extract.sh ouyang2026reasoningbank "$OBSIDIAN_VAULT"
./scripts/summarize.sh ouyang2026reasoningbank "$OBSIDIAN_VAULT"
./scripts/index.sh "$OBSIDIAN_VAULT"
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
export OBSIDIAN_VAULT="$HOME/你的Vault路径"
```

如果 PyMuPDF 装在非默认解释器里，可以用 `PYTHON=/path/to/python` 指定脚本使用的 Python。

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
./scripts/paper.sh ouyang2026reasoningbank "$OBSIDIAN_VAULT"
```

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
- 图片引用本地 `assets/png/{citekey}/` 下的关键图或页面渲染

### 自定义

- 写作风格：`skills/read-zotero-paper/SKILL.md`
- 分类规则：`skills/paper-index/SKILL.md`
- 综述结构：`skills/paper-summary/SKILL.md`

### License

MIT
