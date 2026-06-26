#!/usr/bin/env python3
"""Fetch a Zotero PDF attachment by Better BibTeX citekey."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import shutil
import sys
import urllib.error
import urllib.request
from pathlib import Path


DEFAULT_BBT_URL = "http://localhost:23119/better-bibtex/json-rpc"


def fail(message: str, code: int = 1) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(code)


def call_bbt(url: str, citekey: str) -> list[dict]:
    payload = {
        "jsonrpc": "2.0",
        "method": "item.attachments",
        "params": [citekey, "*"],
        "id": 1,
    }
    data = json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(
        url,
        data=data,
        headers={
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(request, timeout=10) as response:
            raw = response.read()
    except urllib.error.URLError as exc:
        fail(
            "无法连接 Better BibTeX JSON-RPC。请确认 Zotero 正在运行，"
            f"Better BibTeX 已启用，并且 {url} 可访问。原始错误: {exc}",
            code=2,
        )

    try:
        decoded = json.loads(raw.decode("utf-8"))
    except json.JSONDecodeError as exc:
        fail(f"Better BibTeX 返回了非 JSON 内容: {exc}")

    if "error" in decoded:
        fail(f"Better BibTeX JSON-RPC 错误: {decoded['error']}")

    result = decoded.get("result")
    if not isinstance(result, list):
        fail(f"Better BibTeX 返回格式异常: {decoded}")
    return result


def choose_pdf(attachments: list[dict]) -> dict:
    pdfs = []
    for attachment in attachments:
        path = attachment.get("path")
        if isinstance(path, str) and path.lower().endswith(".pdf"):
            pdfs.append(attachment)

    if not pdfs:
        available = [
            attachment.get("path", "<missing path>")
            for attachment in attachments
            if isinstance(attachment, dict)
        ]
        fail("该 citekey 没有 PDF 附件。可见附件: " + json.dumps(available, ensure_ascii=False))

    if len(pdfs) > 1:
        print(f"WARNING: 找到 {len(pdfs)} 个 PDF 附件，默认使用第一个。", file=sys.stderr)
    return pdfs[0]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("citekey", help="Better BibTeX citekey")
    parser.add_argument("vault", help="Obsidian vault path")
    parser.add_argument(
        "--bbt-url",
        default=DEFAULT_BBT_URL,
        help=f"Better BibTeX JSON-RPC URL (default: {DEFAULT_BBT_URL})",
    )
    args = parser.parse_args()

    citekey = args.citekey.strip()
    if not citekey:
        fail("citekey 不能为空")
    if "/" in citekey or "\\" in citekey:
        fail("citekey 会作为文件名使用，不能包含路径分隔符 / 或 \\")

    vault = Path(args.vault).expanduser().resolve()
    pdf_dir = vault / "assets" / "pdfs"
    cache_dir = vault / ".paper-cache"
    pdf_dir.mkdir(parents=True, exist_ok=True)
    cache_dir.mkdir(parents=True, exist_ok=True)

    print(f"Querying Zotero Better BibTeX for citekey: {citekey}", flush=True)
    attachments = call_bbt(args.bbt_url, citekey)
    pdf_attachment = choose_pdf(attachments)
    source = Path(pdf_attachment["path"]).expanduser()
    if not source.is_file():
        fail(f"Zotero PDF 路径不存在: {source}")

    destination = pdf_dir / f"{citekey}.pdf"
    if destination.exists():
        print(f"PDF already exists: {destination}")
    else:
        shutil.copy2(source, destination)
        print(f"Copied PDF: {destination}")

    metadata = {
        "citekey": citekey,
        "source": "zotero",
        "better_bibtex_url": args.bbt_url,
        "pdf_path": str(destination),
        "zotero_pdf_path": str(source),
        "zotero_open": pdf_attachment.get("open"),
        "attachments": attachments,
        "fetched_at": dt.datetime.now(dt.timezone.utc).isoformat(),
    }
    metadata_path = cache_dir / f"{citekey}_zotero.json"
    metadata_path.write_text(json.dumps(metadata, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Cached Zotero metadata: {metadata_path}")

    print(citekey)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
