#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: bash Hashing_Repo_Artifacts.sh [--output PATH] [--help]

Generate SHA-256 hashes for repository artifacts.

Defaults:
  - Hash all tracked files plus untracked files that are not ignored.
  - Exclude .git metadata and other common junk directories.
  - Emit a deterministic, sorted manifest.

Environment variables:
  HASH_OUTPUT_PATH        Write the manifest to a file in addition to stdout.
  HASH_EXCLUDE_PATTERNS   Colon-separated glob patterns to skip, e.g.:
                          '*.log:dist/**:node_modules/**'

Examples:
  bash Hashing_Repo_Artifacts.sh
  HASH_OUTPUT_PATH=repo.sha256 bash Hashing_Repo_Artifacts.sh
  HASH_EXCLUDE_PATTERNS='*.log:docs/generated/**' bash Hashing_Repo_Artifacts.sh
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

output_file=""
if [[ "${1:-}" == "--output" ]]; then
    if [[ $# -lt 2 ]]; then
        usage >&2
        exit 1
    fi
    output_file="$2"
    shift 2
fi

if [[ $# -ne 0 ]]; then
    usage >&2
    exit 1
fi

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$repo_root"

default_exclusions="
.git
.git/**
.gitignore
node_modules/**
__pycache__/**
.venv/**
venv/**
*.pyc
*.pyo
*.log
"

collect_files() {
    if git -C "$repo_root" rev-parse --show-toplevel >/dev/null 2>&1; then
        git -C "$repo_root" ls-files -z --cached --others --exclude-standard -- . | LC_ALL=C sort -z
        return
    fi

    find "$repo_root" \
        -type f \
        ! -path "$repo_root/.git/*" \
        ! -path "$repo_root/.git" \
        ! -path "$repo_root/.venv/*" \
        ! -path "$repo_root/venv/*" \
        ! -path "$repo_root/node_modules/*" \
        ! -path "$repo_root/__pycache__/*" \
        -print0 | LC_ALL=C sort -z
}

should_skip() {
    local rel_path="$1"

    for pattern in ${HASH_EXCLUDE_PATTERNS:-}; do
        [[ -z "$pattern" ]] && continue
        case "$rel_path" in
            $pattern)
                return 0
                ;;
        esac
    done

    local pattern
    while IFS= read -r pattern; do
        [[ -z "$pattern" ]] && continue
        case "$rel_path" in
            $pattern)
                return 0
                ;;
        esac
    done <<< "$default_exclusions"

    return 1
}

manifest_file="$(mktemp)"

while IFS= read -r -d '' file; do
    rel_path="${file#"$repo_root"/}"
    if [[ "$rel_path" == "$file" ]]; then
        rel_path="${file##*/}"
    fi

    if should_skip "$rel_path"; then
        continue
    fi

    hash_val="$(sha256sum -- "$file" | awk '{print $1}')"
    printf '%s  %s\n' "$hash_val" "$rel_path" >> "$manifest_file"
done < <(collect_files)

if [[ ! -s "$manifest_file" ]]; then
    echo "No repository artifacts matched the current selection." >&2
    rm -f "$manifest_file"
    exit 0
fi

cat "$manifest_file"

if [[ -n "$output_file" ]]; then
    mkdir -p "$(dirname -- "$output_file")"
    cp "$manifest_file" "$output_file"
    printf '\n[+] Wrote SHA-256 manifest to %s\n' "$output_file" >&2
fi

rm -f "$manifest_file"

echo "=============================================" >&2
echo "Hashing complete. Use the manifest to verify artifact integrity." >&2
echo "=============================================" >&2
