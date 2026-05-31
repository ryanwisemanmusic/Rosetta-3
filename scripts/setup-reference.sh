#!/usr/bin/env bash
# Populate .rosetta3 with gitignored reference material (Windows SDK, third-party sources).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REF="${ROOT}/.rosetta3"

mkdir -p "${REF}/include/win32" "${REF}/third_party"

clone_if_missing() {
    local url="$1"
    local dest="$2"
    if [[ -d "${dest}/.git" ]] || [[ -f "${dest}/README.md" ]] || [[ -f "${dest}/LICENSE" ]]; then
        echo "  ok  ${dest}"
        return 0
    fi
    echo "  clone ${url} -> ${dest}"
    git clone --depth 1 "${url}" "${dest}"
}

echo "==> Windows 10 SDK headers (tpn/winsdk-10)"
if [[ ! -d "${REF}/winsdk-10/10.0.10240.0" ]]; then
    clone_if_missing "https://github.com/tpn/winsdk-10.git" "${REF}/winsdk-10"
else
    echo "  ok  ${REF}/winsdk-10"
fi

echo "==> Third-party: AvxToNeon (was a git submodule)"
clone_if_missing "https://github.com/kunpengcompute/AvxToNeon.git" "${REF}/third_party/AvxToNeon"

echo ""
echo "Reference tree ready under ${REF}"
echo "Open build/Rosetta3.code-workspace for IntelliSense inside .rosetta3."
