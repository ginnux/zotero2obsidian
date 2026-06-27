<a id="top"></a>

# Zotero2Obsidian Skills 📚

[English](#english) | [中文](#中文)

---

<a id="english"></a>

## English

Turn a Zotero paper into a structured Obsidian reading note with one Better BibTeX citekey.

Zotero2Obsidian Skills is a local-first workflow for researchers who read papers with Zotero, Obsidian, and an agentic coding assistant. It fetches the PDF from your Zotero library, extracts text and figures, writes a Chinese technical reading note, and keeps Obsidian Bases indexes up to date.

> Give it a citekey. Get a paper note, local assets, extracted text, and searchable indexes.

### ✨ Features

- 🔑 Uses Better BibTeX citekeys as stable paper IDs.
- 📥 Fetches PDF attachments from your local Zotero library.
- 🧠 Prefers MinerU precise parsing when configured, with PyMuPDF fallback.
- 🖼️ Stores each paper's PDF, figures, and extracted assets under `assets/{citekey}/`.
- 📝 Generates structured Chinese paper notes for Obsidian.
- 🗂️ Maintains Obsidian Bases indexes for paper collections.
- 🔒 Keeps the workflow local by default; external parsing is opt-in through MinerU.

### 🚀 Quick Start

This is the minimum setup needed to run the workflow.

#### 1. Prepare Zotero

- Open Zotero.
- Install and enable Better BibTeX.
- Confirm that Better BibTeX JSON-RPC is reachable at:

```text
http://localhost:23119/better-bibtex/json-rpc
```

#### 2. Install the local extraction dependency

```bash
pip install pymupdf
```

#### 3. Configure your vault path

```bash
cp .env.example .env
```

Edit `.env` and set:

```bash
Z2O_VAULT="/absolute/path/to/your/ObsidianVault"
```

#### 4. Prepare one paper

```bash
./scripts/prepare.sh ouyang2026reasoningbank
```

Expected outputs:

```text
assets/ouyang2026reasoningbank/ouyang2026reasoningbank.pdf
.paper-cache/ouyang2026reasoningbank_text.md
.paper-cache/ouyang2026reasoningbank_zotero.json
```

When used through the `read-zotero-paper` skill, the current Agent reads these extracted materials and writes the final note.

### 🧩 Skills

| Skill | Purpose |
| --- | --- |
| `read-zotero-paper` | Fetch a Zotero PDF by citekey, extract text/assets, and write a deep Chinese reading note |
| `paper-index` | Build and update Obsidian Bases indexes from paper-note frontmatter |
| `paper-summary` | Create survey-style reports from multiple paper notes |

Example prompt:

```text
Read this paper: ouyang2026reasoningbank
```

### 🛠️ Script Workflow

Recommended material-preparation entry:

```bash
./scripts/prepare.sh <citekey>
```

This runs:

```bash
./scripts/download.sh <citekey>
./scripts/extract.sh <citekey>
```

For a full CLI smoke test with a deterministic local draft:

```bash
./scripts/paper.sh <citekey>
```

The best-quality note path is still the Agent skill path: `prepare.sh` prepares PDF/text/assets, then the current Agent reads the extracted paper and writes the final note.

### ⚙️ Configuration

The only required value is usually:

```bash
Z2O_VAULT="/absolute/path/to/your/ObsidianVault"
```

Default directories:

```bash
Z2O_NOTES_DIR="papers/notes"
Z2O_INDEX_DIR="papers/index"
Z2O_SUMMARY_DIR="knowledge/Summary"
Z2O_TEMP_DIR=".paper-cache"
Z2O_ASSETS_DIR="assets"
```

Enable MinerU precise parsing:

```bash
Z2O_EXTRACTOR="auto"
MINERU_API_TOKEN="your-token"
MINERU_MODEL_VERSION="vlm"
MINERU_LANGUAGE="ch"
```

Extractor modes:

| Mode | Behavior |
| --- | --- |
| `auto` | Use MinerU when a token exists, then fall back to PyMuPDF |
| `mineru` | Prefer MinerU, then fall back to PyMuPDF |
| `mineru-strict` | Require MinerU and fail if MinerU is unavailable |
| `pymupdf` | Force local PyMuPDF extraction |

If PyMuPDF is installed in a non-default interpreter:

```bash
PYTHON="/path/to/python"
```

### 📁 Vault Layout

```text
your-vault/
├── assets/
│   └── ouyang2026reasoningbank/
│       ├── ouyang2026reasoningbank.pdf
│       ├── page1_img1.png
│       └── page_1.png
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

### 🔍 How Zotero Lookup Works

The download step calls Better BibTeX JSON-RPC:

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

Only PDF attachments are used. HTML snapshots and other files are ignored.

### 🧠 Note Style

`read-zotero-paper` writes notes for LLM researchers:

- Chinese explanation with the English title preserved.
- Strong emphasis on motivation, method, experiments, limitations, and personal thoughts.
- Figures are linked from `assets/{citekey}/`.
- The citekey is used as the filename, frontmatter ID, and stable Obsidian reference.

Customize the style in:

```text
skills/read-zotero-paper/SKILL.md
```

### 🧱 Repository Structure

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

### 🧯 Troubleshooting

- `Operation not permitted` when calling `localhost:23119`: allow the command to access local Zotero / Better BibTeX.
- `Cannot connect to Better BibTeX JSON-RPC`: check that Zotero is open and Better BibTeX is enabled.
- `Missing PyMuPDF`: run `pip install pymupdf` or set `PYTHON=/path/to/python`.
- MinerU failures in `auto` or `mineru` mode fall back to PyMuPDF; use `mineru-strict` only when you want hard failure.

### 📄 License

This project is licensed under the GNU Affero General Public License v3.0 or later. See LICENSE for details.

This project is derived from [Chang-pw/paper2obsidian_skill](https://github.com/Chang-pw/paper2obsidian_skill), which is licensed under the MIT License.

Original project:

Name: paper2obsidian_skill
\
Repository: [https://github.com/Chang-pw/paper2obsidian_skill](https://github.com/Chang-pw/paper2obsidian_skill)
\
Copyright: Copyright (c) 2026 Chang-pw
\
License: MIT License

[Back to top](#top)

---

<a id="中文"></a>

## 中文

用一个 Better BibTeX citekey，把 Zotero 里的论文变成结构化 Obsidian 阅读笔记。

Zotero2Obsidian Skills 是一个本地优先的论文阅读工作流，适合同时使用 Zotero、Obsidian 和 Agent 编程助手的研究者。它会从 Zotero 文献库读取 PDF 附件，提取全文和图片，生成中文技术解读笔记，并维护 Obsidian Bases 索引。

> 输入 citekey，得到论文笔记、本地资产、提取全文和可检索索引。

### ✨ 特性

- 🔑 使用 Better BibTeX citekey 作为稳定论文 ID。
- 📥 从本地 Zotero 文献库读取 PDF 附件。
- 🧠 配置 MinerU 后优先精准解析，不可用时回退 PyMuPDF。
- 🖼️ 每篇论文的 PDF、图片和提取资产统一放在 `assets/{citekey}/`。
- 📝 为 Obsidian 生成结构化中文论文笔记。
- 🗂️ 自动维护 Obsidian Bases 论文索引。
- 🔒 默认本地运行；只有配置 MinerU token 时才使用外部精准解析。

### 🚀 快速上手

这里只保留能启动的最小流程。

#### 1. 准备 Zotero

- 打开 Zotero。
- 安装并启用 Better BibTeX。
- 确认 Better BibTeX JSON-RPC 地址可访问：

```text
http://localhost:23119/better-bibtex/json-rpc
```

#### 2. 安装本地提取依赖

```bash
pip install pymupdf
```

#### 3. 配置 vault 路径

```bash
cp .env.example .env
```

编辑 `.env`，设置：

```bash
Z2O_VAULT="/你的ObsidianVault绝对路径"
```

#### 4. 准备一篇论文

```bash
./scripts/prepare.sh ouyang2026reasoningbank
```

成功后会生成：

```text
assets/ouyang2026reasoningbank/ouyang2026reasoningbank.pdf
.paper-cache/ouyang2026reasoningbank_text.md
.paper-cache/ouyang2026reasoningbank_zotero.json
```

如果通过 `read-zotero-paper` skill 使用，准备完成后当前 Agent 会读取这些材料并写正式笔记。

### 🧩 Skills

| Skill | 用途 |
| --- | --- |
| `read-zotero-paper` | 按 citekey 获取 Zotero PDF，提取全文/资产，并生成中文深度阅读笔记 |
| `paper-index` | 根据论文笔记 frontmatter 生成和更新 Obsidian Bases 索引 |
| `paper-summary` | 基于多篇论文笔记生成综述报告 |

示例提示：

```text
阅读这篇文章：ouyang2026reasoningbank
```

### 🛠️ 脚本流程

推荐的材料准备入口：

```bash
./scripts/prepare.sh <citekey>
```

它会依次运行：

```bash
./scripts/download.sh <citekey>
./scripts/extract.sh <citekey>
```

如果想跑完整 CLI 冒烟测试并生成确定性本地草稿：

```bash
./scripts/paper.sh <citekey>
```

质量最高的路径仍然是 Agent skill：`prepare.sh` 只准备 PDF、全文和图片资产，然后当前 Agent 阅读提取材料并写正式笔记。

### ⚙️ 配置

通常只需要配置：

```bash
Z2O_VAULT="/你的ObsidianVault绝对路径"
```

默认目录：

```bash
Z2O_NOTES_DIR="papers/notes"
Z2O_INDEX_DIR="papers/index"
Z2O_SUMMARY_DIR="knowledge/Summary"
Z2O_TEMP_DIR=".paper-cache"
Z2O_ASSETS_DIR="assets"
```

启用 MinerU 精准解析：

```bash
Z2O_EXTRACTOR="auto"
MINERU_API_TOKEN="你的MinerU token"
MINERU_MODEL_VERSION="vlm"
MINERU_LANGUAGE="ch"
```

提取模式：

| 模式 | 行为 |
| --- | --- |
| `auto` | 有 token 时使用 MinerU，失败后回退 PyMuPDF |
| `mineru` | 优先 MinerU，失败后回退 PyMuPDF |
| `mineru-strict` | 强制 MinerU；MinerU 不可用时直接失败 |
| `pymupdf` | 强制本地 PyMuPDF 提取 |

如果 PyMuPDF 装在非默认解释器：

```bash
PYTHON="/path/to/python"
```

### 📁 Vault 目录结构

```text
your-vault/
├── assets/
│   └── ouyang2026reasoningbank/
│       ├── ouyang2026reasoningbank.pdf
│       ├── page1_img1.png
│       └── page_1.png
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

### 🔍 Zotero 查询方式

下载步骤会调用 Better BibTeX JSON-RPC：

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

脚本只使用 PDF 附件，会忽略 HTML 快照和其他文件。

### 🧠 笔记风格

`read-zotero-paper` 面向大模型研究者生成笔记：

- 中文解释，保留英文原标题。
- 强调研究动机、核心方法、实验、局限和个人思考。
- 图片从 `assets/{citekey}/` 引用。
- citekey 用作文件名、frontmatter ID 和稳定 Obsidian 引用。

自定义写作风格：

```text
skills/read-zotero-paper/SKILL.md
```

### 🧱 仓库结构

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

### 🧯 常见问题

- 调用 `localhost:23119` 时出现 `Operation not permitted`：允许命令访问本地 Zotero / Better BibTeX。
- `无法连接 Better BibTeX JSON-RPC`：检查 Zotero 是否打开，Better BibTeX 是否启用。
- `缺少 PyMuPDF`：运行 `pip install pymupdf`，或设置 `PYTHON=/path/to/python`。
- `auto` 或 `mineru` 模式下 MinerU 失败会自动回退 PyMuPDF；只有需要强制失败时才用 `mineru-strict`。

### 📄 License

本项目采用 GNU Affero General Public License v3.0 or later 授权。详情请查看 LICENSE。

本项目派生自 [Chang-pw/paper2obsidian_skill](https://github.com/Chang-pw/paper2obsidian_skill)，原项目采用 MIT License 授权。

原项目信息：

名称：paper2obsidian_skill
\
仓库：[https://github.com/Chang-pw/paper2obsidian_skill](https://github.com/Chang-pw/paper2obsidian_skill)
\
版权：Copyright (c) 2026 Chang-pw
\
协议：MIT License

[返回顶部](#top)
