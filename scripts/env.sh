#!/bin/bash
# Shared configuration loader for Zotero2Obsidian scripts.

z2o_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export Z2O_PROJECT_DIR="${Z2O_PROJECT_DIR:-$(cd "$z2o_script_dir/.." && pwd)}"

z2o_env_file="${Z2O_ENV_FILE:-$Z2O_PROJECT_DIR/.env}"
if [[ -f "$z2o_env_file" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$z2o_env_file"
    set +a
fi

z2o_path() {
    local base="$1"
    local value="$2"

    value="${value/#\~/$HOME}"
    if [[ "$value" == /* ]]; then
        printf '%s\n' "$value"
    else
        printf '%s/%s\n' "${base%/}" "$value"
    fi
}

z2o_python_bin() {
    if [[ -n "${PYTHON:-}" ]]; then
        printf '%s\n' "$PYTHON"
    elif command -v python >/dev/null 2>&1; then
        printf '%s\n' "python"
    else
        printf '%s\n' "python3"
    fi
}

z2o_relpath() {
    local target="$1"
    local start="$2"
    local python_bin
    python_bin="$(z2o_python_bin)"

    "$python_bin" - "$target" "$start" << 'PYEOF'
import os
import sys

print(os.path.relpath(sys.argv[1], sys.argv[2]))
PYEOF
}

z2o_join_path() {
    local base="${1%/}"
    local leaf="$2"

    if [[ "$base" == "." ]]; then
        printf '%s\n' "$leaf"
    else
        printf '%s/%s\n' "$base" "$leaf"
    fi
}

z2o_configure_paths() {
    local vault_arg="${1:-}"

    if [[ -n "$vault_arg" ]]; then
        Z2O_VAULT="$(z2o_path "$(pwd)" "$vault_arg")"
    elif [[ -n "${Z2O_VAULT:-}" ]]; then
        Z2O_VAULT="$(z2o_path "$(pwd)" "$Z2O_VAULT")"
    elif [[ -n "${OBSIDIAN_VAULT:-}" ]]; then
        Z2O_VAULT="$(z2o_path "$(pwd)" "$OBSIDIAN_VAULT")"
    else
        echo "❌ 未提供 vault_path，且 Z2O_VAULT / OBSIDIAN_VAULT 未设置" >&2
        echo "   请运行: cp .env.example .env，然后在 .env 中设置 Z2O_VAULT" >&2
        echo "   或临时传入 vault_path: ./scripts/paper.sh <citekey> /path/to/vault" >&2
        exit 1
    fi

    export Z2O_VAULT
    export OBSIDIAN_VAULT="$Z2O_VAULT"

    Z2O_NOTES_DIR="${Z2O_NOTES_DIR:-papers/notes}"
    Z2O_INDEX_DIR="${Z2O_INDEX_DIR:-papers/index}"
    Z2O_SUMMARY_DIR="${Z2O_SUMMARY_DIR:-knowledge/Summary}"
    Z2O_TEMP_DIR="${Z2O_TEMP_DIR:-.paper-cache}"
    Z2O_PDF_DIR="${Z2O_PDF_DIR:-assets/pdfs}"
    Z2O_IMAGE_DIR="${Z2O_IMAGE_DIR:-assets/png}"

    export Z2O_NOTES_DIR Z2O_INDEX_DIR Z2O_SUMMARY_DIR
    export Z2O_TEMP_DIR Z2O_PDF_DIR Z2O_IMAGE_DIR

    Z2O_NOTES_DIR_ABS="$(z2o_path "$Z2O_VAULT" "$Z2O_NOTES_DIR")"
    Z2O_INDEX_DIR_ABS="$(z2o_path "$Z2O_VAULT" "$Z2O_INDEX_DIR")"
    Z2O_SUMMARY_DIR_ABS="$(z2o_path "$Z2O_VAULT" "$Z2O_SUMMARY_DIR")"
    Z2O_TEMP_DIR_ABS="$(z2o_path "$Z2O_VAULT" "$Z2O_TEMP_DIR")"
    Z2O_PDF_DIR_ABS="$(z2o_path "$Z2O_VAULT" "$Z2O_PDF_DIR")"
    Z2O_IMAGE_DIR_ABS="$(z2o_path "$Z2O_VAULT" "$Z2O_IMAGE_DIR")"

    export Z2O_NOTES_DIR_ABS Z2O_INDEX_DIR_ABS Z2O_SUMMARY_DIR_ABS
    export Z2O_TEMP_DIR_ABS Z2O_PDF_DIR_ABS Z2O_IMAGE_DIR_ABS
}
