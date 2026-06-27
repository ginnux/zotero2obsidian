#!/usr/bin/env python3
"""Generate a deterministic Obsidian paper-note draft from extracted text."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import re
from pathlib import Path


def first_match(pattern: str, text: str, default: str = "") -> str:
    match = re.search(pattern, text, flags=re.IGNORECASE | re.MULTILINE)
    return match.group(1).strip() if match else default


def section(text: str, heading: str, fallback_chars: int = 1200) -> str:
    pattern = rf"^##?\s+{re.escape(heading)}\b.*?$"
    match = re.search(pattern, text, flags=re.IGNORECASE | re.MULTILINE)
    if not match:
        return text[:fallback_chars].strip()
    start = match.end()
    next_heading = re.search(r"^##?\s+\S", text[start:], flags=re.MULTILINE)
    end = start + next_heading.start() if next_heading else min(len(text), start + fallback_chars)
    return text[start:end].strip()


def truncate_words(text: str, max_words: int) -> str:
    words = re.split(r"\s+", re.sub(r"<[^>]+>", "", text).strip())
    if len(words) <= max_words:
        return " ".join(words)
    return " ".join(words[:max_words]) + " ..."


def parse_title(text: str, citekey: str) -> str:
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith("# "):
            return stripped[2:].strip()
        if stripped and not stripped.startswith("!") and len(stripped) > 8:
            return stripped.lstrip("#").strip()
    return citekey


def parse_authors(text: str) -> list[str]:
    lines = [line.strip() for line in text.splitlines() if line.strip()]
    if len(lines) < 2:
        return []
    author_line = re.sub(r"<[^>]+>", "", lines[1])
    author_line = re.sub(r"\{.*?\}", "", author_line)
    author_line = re.sub(r"\s+", " ", author_line)
    parts = [part.strip(" ,*") for part in re.split(r",| and ", author_line) if part.strip(" ,*")]
    return parts[:16]


def yaml_list(values: list[str]) -> str:
    if not values:
        return "[]"
    return "[" + ", ".join(json.dumps(value, ensure_ascii=False) for value in values) + "]"


def figure_lines(text: str, fig_prefix: str, max_figures: int = 4) -> list[str]:
    lines = text.splitlines()
    figures: list[str] = []
    for i, line in enumerate(lines):
        if "Figure " not in line:
            continue
        caption = line.strip()
        image_path = ""
        for prev in reversed(lines[max(0, i - 4):i]):
            match = re.search(r"!\[\]\(images/([^)]+)\)", prev)
            if match:
                image_path = f"{fig_prefix}/{match.group(1)}"
                break
        if image_path:
            figures.append(f"![{caption}|600]({image_path})\n*{caption}*")
        else:
            figures.append(f"- {caption}")
        if len(figures) >= max_figures:
            break
    return figures


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--citekey", required=True)
    parser.add_argument("--text-file", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--pdf-link", required=True)
    parser.add_argument("--figure-prefix", required=True)
    args = parser.parse_args()

    text = Path(args.text_file).read_text(encoding="utf-8", errors="replace")
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)

    title = parse_title(text, args.citekey)
    authors = parse_authors(text)
    abstract = first_match(r"^##\s+ABSTRACT\s*(.*?)(?=^##\s+|\Z)", text, default="",)
    if not abstract:
        abstract = section(text, "ABSTRACT")
    intro = section(text, "1 INTRODUCTION", fallback_chars=1800)
    method = section(text, "3 AGENTIC CONTEXT ENGINEERING (ACE)", fallback_chars=2200)
    results = section(text, "4 RESULTS", fallback_chars=1800)
    discussion = section(text, "5 DISCUSSION", fallback_chars=1200)
    figs = figure_lines(text, args.figure_prefix)

    tldr = truncate_words(abstract, 60) if abstract else f"{title} 的自动草稿笔记。"
    today = dt.date.today().isoformat()

    note = f"""---
title: {json.dumps(title, ensure_ascii=False)}
title_zh: ""
authors: {yaml_list(authors)}
year:
citekey: {json.dumps(args.citekey, ensure_ascii=False)}
src_type: "zotero"
pdf: {json.dumps(args.pdf_link, ensure_ascii=False)}
tags: [paper, needs-review]
rating:
date_added: {today}
tldr: {json.dumps(tldr, ensure_ascii=False)}
---

# {title}

> **一句话总结：** {tldr}

## 📋 基本信息

- **作者：** {", ".join(authors) if authors else "待补充"}
- **Zotero citekey：** {args.citekey}
- **PDF：** [本地 PDF]({args.pdf_link})
- **生成方式：** 本地兜底草稿。请人工复核标题、作者、年份、tags 和技术细节。

## 🎯 研究动机与问题

{truncate_words(intro, 450)}

## 💡 核心方法

{truncate_words(method, 650)}

## 📊 实验与结果

{truncate_words(results, 500)}

## 🔍 关键图表

{chr(10).join(figs) if figs else "待从提取结果中补充关键图表。"}

## 💭 个人思考

- **优点：** 待人工补充。
- **局限：** {truncate_words(discussion, 180) if discussion else "待人工补充。"}
- **启发：** 待人工补充。

## 🔗 相关论文

- 待补充
"""

    output.write_text(note, encoding="utf-8")
    print(f"✅ 本地草稿笔记已生成: {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
