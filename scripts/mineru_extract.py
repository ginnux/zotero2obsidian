#!/usr/bin/env python3
"""Extract a local PDF with MinerU precise parsing API."""

from __future__ import annotations

import argparse
import json
import os
import shutil
import sys
import time
import urllib.error
import urllib.request
import zipfile
from pathlib import Path
from typing import Any


DEFAULT_API_BASE = "https://mineru.net/api/v4"
TERMINAL_SUCCESS = {"done"}
TERMINAL_FAILURE = {"failed"}


def fail(message: str, code: int = 1) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(code)


def as_bool(value: str | bool | None, default: bool = False) -> bool:
    if value is None:
        return default
    if isinstance(value, bool):
        return value
    return value.strip().lower() in {"1", "true", "yes", "y", "on"}


def request_json(
    method: str,
    url: str,
    token: str,
    payload: dict[str, Any] | None = None,
    timeout: int = 60,
) -> dict[str, Any]:
    data = None
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/json",
    }
    if payload is not None:
        data = json.dumps(payload).encode("utf-8")
        headers["Content-Type"] = "application/json"

    request = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            raw = response.read()
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        fail(f"MinerU API HTTP {exc.code}: {detail}", code=2)
    except urllib.error.URLError as exc:
        fail(f"无法访问 MinerU API: {exc}", code=2)

    try:
        decoded = json.loads(raw.decode("utf-8"))
    except json.JSONDecodeError as exc:
        fail(f"MinerU API 返回了非 JSON 内容: {exc}")

    code = decoded.get("code")
    if code not in (0, "0", None):
        fail(f"MinerU API 错误: {decoded}", code=2)
    return decoded


def upload_pdf(upload_url: str, pdf_path: Path, timeout: int = 300) -> None:
    request = urllib.request.Request(
        upload_url,
        data=pdf_path.read_bytes(),
        headers={"Content-Type": ""},
        method="PUT",
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            response.read()
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        fail(f"上传 PDF 到 MinerU 失败 HTTP {exc.code}: {detail}", code=2)
    except urllib.error.URLError as exc:
        fail(f"上传 PDF 到 MinerU 失败: {exc}", code=2)


def download_file(url: str, destination: Path, timeout: int = 300) -> None:
    request = urllib.request.Request(url, method="GET")
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            destination.write_bytes(response.read())
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        fail(f"下载 MinerU 结果失败 HTTP {exc.code}: {detail}", code=2)
    except urllib.error.URLError as exc:
        fail(f"下载 MinerU 结果失败: {exc}", code=2)


def first_data(decoded: dict[str, Any]) -> dict[str, Any]:
    data = decoded.get("data")
    if isinstance(data, dict):
        return data
    fail(f"MinerU API 返回缺少 data: {decoded}")


def first_extract_result(data: dict[str, Any]) -> dict[str, Any]:
    results = data.get("extract_result")
    if isinstance(results, list) and results:
        result = results[0]
        if isinstance(result, dict):
            return result
    fail(f"MinerU batch 结果缺少 extract_result: {data}")


def find_first(root: Path, suffix: str) -> Path | None:
    matches = sorted(p for p in root.rglob("*") if p.is_file() and p.name.endswith(suffix))
    return matches[0] if matches else None


def copy_images(extracted_dir: Path, image_dir: Path) -> int:
    image_dir.mkdir(parents=True, exist_ok=True)
    count = 0
    for path in sorted(extracted_dir.rglob("*")):
        if path.is_file() and path.suffix.lower() in {".png", ".jpg", ".jpeg", ".webp"}:
            destination = image_dir / path.name
            if destination.exists():
                stem = path.stem
                suffix = path.suffix
                idx = 2
                while destination.exists():
                    destination = image_dir / f"{stem}_{idx}{suffix}"
                    idx += 1
            shutil.copy2(path, destination)
            count += 1
    return count


def write_text_output(extracted_dir: Path, text_path: Path) -> Path:
    markdown = find_first(extracted_dir, ".md")
    if markdown is None:
        content_list = find_first(extracted_dir, "_content_list.json")
        if content_list is None:
            content_list = find_first(extracted_dir, "content_list.json")
        if content_list is None:
            fail("MinerU 结果中未找到 Markdown 或 content_list.json")
        items = json.loads(content_list.read_text(encoding="utf-8"))
        parts = []
        for item in items if isinstance(items, list) else []:
            if isinstance(item, dict):
                text = item.get("text") or item.get("content")
                if isinstance(text, str) and text.strip():
                    parts.append(text.strip())
        text_path.write_text("\n\n".join(parts), encoding="utf-8")
        return content_list

    text_path.write_text(markdown.read_text(encoding="utf-8"), encoding="utf-8")
    return markdown


def copy_json_artifacts(extracted_dir: Path, cache_dir: Path, citekey: str) -> None:
    for path in sorted(extracted_dir.rglob("*.json")):
        destination = cache_dir / f"{citekey}_mineru_{path.name}"
        shutil.copy2(path, destination)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("citekey")
    parser.add_argument("pdf_path")
    parser.add_argument("text_path")
    parser.add_argument("image_dir")
    parser.add_argument("cache_dir")
    parser.add_argument("--token", default=os.environ.get("MINERU_API_TOKEN") or os.environ.get("MINERU_TOKEN"))
    parser.add_argument("--api-base", default=os.environ.get("MINERU_API_BASE", DEFAULT_API_BASE))
    parser.add_argument("--model-version", default=os.environ.get("MINERU_MODEL_VERSION", "vlm"))
    parser.add_argument("--language", default=os.environ.get("MINERU_LANGUAGE", "ch"))
    parser.add_argument("--page-ranges", default=os.environ.get("MINERU_PAGE_RANGES", ""))
    parser.add_argument("--poll-interval", type=int, default=int(os.environ.get("MINERU_POLL_INTERVAL", "5")))
    parser.add_argument("--timeout", type=int, default=int(os.environ.get("MINERU_TIMEOUT", "900")))
    parser.add_argument("--enable-formula", default=os.environ.get("MINERU_ENABLE_FORMULA", "true"))
    parser.add_argument("--enable-table", default=os.environ.get("MINERU_ENABLE_TABLE", "true"))
    parser.add_argument("--is-ocr", default=os.environ.get("MINERU_IS_OCR", "false"))
    args = parser.parse_args()

    if not args.token:
        fail("未配置 MINERU_API_TOKEN 或 MINERU_TOKEN", code=3)

    citekey = args.citekey
    pdf_path = Path(args.pdf_path).expanduser().resolve()
    text_path = Path(args.text_path).expanduser().resolve()
    image_dir = Path(args.image_dir).expanduser().resolve()
    cache_dir = Path(args.cache_dir).expanduser().resolve()

    if not pdf_path.is_file():
        fail(f"PDF 不存在: {pdf_path}")

    text_path.parent.mkdir(parents=True, exist_ok=True)
    image_dir.mkdir(parents=True, exist_ok=True)
    cache_dir.mkdir(parents=True, exist_ok=True)

    api_base = args.api_base.rstrip("/")
    file_payload: dict[str, Any] = {
        "name": pdf_path.name,
        "data_id": citekey,
        "is_ocr": as_bool(args.is_ocr),
    }
    if args.page_ranges:
        file_payload["page_ranges"] = args.page_ranges

    payload = {
        "enable_formula": as_bool(args.enable_formula, default=True),
        "enable_table": as_bool(args.enable_table, default=True),
        "language": args.language,
        "model_version": args.model_version,
        "files": [file_payload],
    }

    print(f"MinerU: requesting upload URL for {pdf_path.name}", flush=True)
    upload_data = first_data(
        request_json("POST", f"{api_base}/file-urls/batch", args.token, payload)
    )
    batch_id = upload_data.get("batch_id")
    file_urls = upload_data.get("file_urls")
    if not isinstance(batch_id, str) or not isinstance(file_urls, list) or not file_urls:
        fail(f"MinerU 上传 URL 返回格式异常: {upload_data}")
    upload_url = file_urls[0]
    if not isinstance(upload_url, str):
        fail(f"MinerU 上传 URL 不是字符串: {upload_data}")

    print("MinerU: uploading PDF", flush=True)
    upload_pdf(upload_url, pdf_path)

    deadline = time.monotonic() + args.timeout
    result: dict[str, Any] | None = None
    while time.monotonic() < deadline:
        time.sleep(max(1, args.poll_interval))
        batch_data = first_data(
            request_json("GET", f"{api_base}/extract-results/batch/{batch_id}", args.token)
        )
        result = first_extract_result(batch_data)
        state = str(result.get("state", "")).lower()
        print(f"MinerU: state={state or 'unknown'}", flush=True)
        if state in TERMINAL_SUCCESS:
            break
        if state in TERMINAL_FAILURE:
            fail(f"MinerU 解析失败: {result}", code=2)
    else:
        fail(f"MinerU 解析超时，batch_id={batch_id}", code=2)

    if result is None:
        fail("MinerU 未返回解析结果")

    full_zip_url = result.get("full_zip_url")
    if not isinstance(full_zip_url, str) or not full_zip_url:
        fail(f"MinerU 结果缺少 full_zip_url: {result}")

    zip_path = cache_dir / f"{citekey}_mineru_full.zip"
    extract_dir = cache_dir / f"{citekey}_mineru"
    if extract_dir.exists():
        shutil.rmtree(extract_dir)
    extract_dir.mkdir(parents=True, exist_ok=True)

    print("MinerU: downloading result zip", flush=True)
    download_file(full_zip_url, zip_path)
    with zipfile.ZipFile(zip_path) as archive:
        archive.extractall(extract_dir)

    source_text = write_text_output(extract_dir, text_path)
    image_count = copy_images(extract_dir, image_dir)
    copy_json_artifacts(extract_dir, cache_dir, citekey)

    metadata = {
        "citekey": citekey,
        "batch_id": batch_id,
        "model_version": args.model_version,
        "language": args.language,
        "result": result,
        "zip_path": str(zip_path),
        "extract_dir": str(extract_dir),
        "text_source": str(source_text),
        "text_path": str(text_path),
        "image_dir": str(image_dir),
        "image_count": image_count,
    }
    (cache_dir / f"{citekey}_mineru_result.json").write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    print(f"✅ MinerU 提取完成: {text_path}")
    print(f"✅ MinerU 图片/元素保存至: {image_dir} ({image_count} files)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
