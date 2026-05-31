#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "usage: $0 <suite-name> <output-binary>" >&2
    exit 1
fi

SUITE_NAME="$1"
OUTPUT_BIN="$2"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
SUITE_DIR="${ROOT_DIR}/app_testing/${SUITE_NAME}"

if [[ ! -d "${SUITE_DIR}" ]]; then
    echo "suite not found: ${SUITE_NAME}" >&2
    exit 1
fi

INCLUDE_DIR="include"
SHIM_WIN32_DIR="${INCLUDE_DIR}/shims/win32"
SHIM_MACOS_DIR="${INCLUDE_DIR}/shims/macos"
ZIG_LIB="zig-out/lib/librosetta3_zig.a"
DEFAULT_CC="clang"
DEFAULT_CXX="c++"
DEFAULT_CFLAGS="-Wall -Wextra -Wno-ignored-attributes"

if [[ "$(uname -s)" == "Darwin" ]]; then
    COMMON_INCLUDES=("-I${SHIM_MACOS_DIR}" "-I${SHIM_WIN32_DIR}" "-I${INCLUDE_DIR}")
else
    COMMON_INCLUDES=("-I${SHIM_WIN32_DIR}" "-I${INCLUDE_DIR}")
fi

SUITE_CC=""
SUITE_CFLAGS=""
SUITE_LDFLAGS=""
SUITE_LINK_ZIG="auto"
SUITE_INTERACTIVE="no"
SUITE_SOURCES=""

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
            SUITE_CC) SUITE_CC="${value}" ;;
            SUITE_CFLAGS) SUITE_CFLAGS="${value}" ;;
            SUITE_LDFLAGS) SUITE_LDFLAGS="${value}" ;;
            SUITE_LINK_ZIG) SUITE_LINK_ZIG="${value}" ;;
            SUITE_INTERACTIVE) SUITE_INTERACTIVE="${value}" ;;
            SUITE_SOURCES) SUITE_SOURCES="${value}" ;;
        esac
    done < "${cfg_path}"
}

load_suite_cfg "${SUITE_DIR}/suite.cfg"

ensure_zig_lib() {
    if [[ ! -f "${ROOT_DIR}/${ZIG_LIB}" ]]; then
        ( cd "${ROOT_DIR}" && zig build --build-file build/build.zig install )
    fi
}

link_zig="${SUITE_LINK_ZIG}"
if [[ "${link_zig}" == "auto" ]]; then
    if [[ -f "${ROOT_DIR}/${ZIG_LIB}" ]] && grep -rl 'zig_bridge' "${SUITE_DIR}" --include='*.c' --include='*.cpp' &>/dev/null; then
        link_zig="yes"
    else
        link_zig="no"
    fi
fi
if [[ "${link_zig}" == "yes" ]]; then
    ensure_zig_lib
fi
if [[ "${SUITE_LDFLAGS}" == *"librosetta_window.a"* && "${link_zig}" == "no" ]]; then
    ensure_zig_lib
    link_zig="yes"
fi

declare -a sources=()
if [[ -n "${SUITE_SOURCES}" ]]; then
    read -ra sources <<< "${SUITE_SOURCES}"
else
    while IFS= read -r -d '' f; do
        sources+=("$(basename "${f}")")
    done < <(find "${SUITE_DIR}" -maxdepth 1 \( -name '*.c' -o -name '*.cpp' \) -print0 | sort -z)
fi

if [[ ${#sources[@]} -ne 1 ]]; then
    echo "suite ${SUITE_NAME} must resolve to exactly one source file to export a single EXE package" >&2
    exit 1
fi

src_name="${sources[0]}"
src_path="app_testing/${SUITE_NAME}/${src_name}"
ext="${src_name##*.}"
if [[ -n "${SUITE_CC}" ]]; then
    cc="${SUITE_CC}"
elif [[ "${ext}" == "cpp" ]]; then
    cc="${DEFAULT_CXX}"
else
    cc="${DEFAULT_CC}"
fi

mkdir -p "$(dirname "${OUTPUT_BIN}")"

tmp_obj="${OUTPUT_BIN}.o"
trap 'rm -f "${tmp_obj}"' EXIT

declare -a compile_cmd=("${cc}")
if [[ "${cc}" == *"clang++"* ]]; then
    compile_cmd+=("-std=c++11")
fi
read -ra _default_flags <<< "${DEFAULT_CFLAGS}"
compile_cmd+=("${_default_flags[@]}")
compile_cmd+=("${COMMON_INCLUDES[@]}")
if [[ -n "${SUITE_CFLAGS}" ]]; then
    read -ra _suite_flags <<< "${SUITE_CFLAGS}"
    compile_cmd+=("${_suite_flags[@]}")
fi
compile_cmd+=("-c" "${src_path}" "-o" "${tmp_obj}")

( cd "${ROOT_DIR}" && "${compile_cmd[@]}" )

declare -a link_cmd=("${cc}")
if [[ "${cc}" == *"clang++"* ]]; then
    link_cmd+=("-std=c++11")
fi
link_cmd+=("${tmp_obj}")
if [[ "${link_zig}" == "yes" ]]; then
    link_cmd+=("${ZIG_LIB}")
fi
if [[ -n "${SUITE_LDFLAGS}" ]]; then
    read -ra _ldflags <<< "${SUITE_LDFLAGS}"
    link_cmd+=("${_ldflags[@]}")
fi
if [[ "${SUITE_LDFLAGS}" == *"librosetta_window.a"* ]]; then
    link_cmd+=("-lobjc")
fi
link_cmd+=("-o" "${OUTPUT_BIN}")

( cd "${ROOT_DIR}" && "${link_cmd[@]}" )
printf '%s\n' "${OUTPUT_BIN}"
