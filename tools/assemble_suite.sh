#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "usage: $0 <suite-name> [out-dir]" >&2
    exit 1
fi

SUITE_NAME="$1"
OUT_DIR="${2:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
SUITE_DIR="${ROOT_DIR}/app_testing/${SUITE_NAME}"

if [[ ! -d "${SUITE_DIR}" ]]; then
    echo "suite not found: ${SUITE_NAME}" >&2
    exit 1
fi

ASM_FAMILY=""
ASM_SOURCE=""
ASM_TOOL=""
ASM_FORMAT=""
ASM_REQUIRED="no"

load_suite_cfg() {
    local cfg_path="$1"
    [[ -f "${cfg_path}" ]] || return 0
    while IFS= read -r line || [[ -n "${line}" ]]; do
        line="${line%$'\r'}"
        [[ -z "${line}" ]] && continue
        [[ "${line}" =~ ^[[:space:]]*# ]] && continue
        local key="${line%%=*}"
        local value="${line#*=}"
        case "${key}" in
            ASM_FAMILY) ASM_FAMILY="${value}" ;;
            ASM_SOURCE) ASM_SOURCE="${value}" ;;
            ASM_TOOL) ASM_TOOL="${value}" ;;
            ASM_FORMAT) ASM_FORMAT="${value}" ;;
            ASM_REQUIRED) ASM_REQUIRED="${value}" ;;
        esac
    done < "${cfg_path}"
}

load_suite_cfg "${SUITE_DIR}/suite.cfg"

if [[ -z "${ASM_FAMILY}" || -z "${ASM_SOURCE}" ]]; then
    exit 0
fi

SOURCE_PATH="${SUITE_DIR}/${ASM_SOURCE}"
if [[ ! -f "${SOURCE_PATH}" ]]; then
    SOURCE_PATH="${ROOT_DIR}/app_testing/${ASM_SOURCE}"
fi
if [[ ! -f "${SOURCE_PATH}" ]]; then
    echo "assembler source not found for ${SUITE_NAME}: ${ASM_SOURCE}" >&2
    exit 1
fi

if [[ -z "${OUT_DIR}" ]]; then
    OUT_DIR="$(mktemp -d /tmp/rosetta3-asm.XXXXXX)"
fi
mkdir -p "${OUT_DIR}"

resolve_nasm() {
    if command -v nasm >/dev/null 2>&1; then
        command -v nasm
        return 0
    fi
    if [[ -x /usr/local/x86brew/bin/nasm ]]; then
        printf '%s\n' "/usr/local/x86brew/bin/nasm"
        return 0
    fi
    return 1
}

emit_unavailable() {
    local reason="$1"
    if [[ "${ASM_REQUIRED}" == "yes" ]]; then
        echo "  ✗ ${reason}" >&2
        exit 1
    fi
    echo "  ↷ ${reason}"
    return 0
}

case "${ASM_TOOL}" in
    nasm)
        NASM_BIN="$(resolve_nasm)" || {
            emit_unavailable "NASM requested for ${SUITE_NAME}, but no runnable nasm binary is available on this host"
            exit 0
        }
        local_out="${OUT_DIR}/${SUITE_NAME}.obj"
        format="${ASM_FORMAT:-win32}"
        echo "  → Assembling with NASM: ${ASM_SOURCE}"
        (
            cd "${SUITE_DIR}"
            "${NASM_BIN}" -f "${format}" "${ASM_SOURCE}" -o "${local_out}"
        )
        echo "    artifact: ${local_out}"
        ;;
    masm|masm-irvine32)
        emit_unavailable "MASM source detected for ${SUITE_NAME}, but the available MASM payloads are legacy DOS/Windows tools and are not directly runnable on this macOS host"
        ;;
    fasm)
        emit_unavailable "FASM source detected for ${SUITE_NAME}, but no runnable FASM binary is available in the current host environment"
        ;;
    "")
        exit 0
        ;;
    *)
        emit_unavailable "unknown assembler tool '${ASM_TOOL}' for ${SUITE_NAME}"
        ;;
esac
