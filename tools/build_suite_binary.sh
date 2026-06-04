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
WINDOW_LIB="librosetta_window.a"
CLI_LIB="librosetta_cli.a"
DEFAULT_OBJ="default_main.o"
WINDOW_STUB_SRC="src/graphics/common/window_runtime_stub.c"
DEFAULT_CC="clang"
DEFAULT_CXX="c++"
DEFAULT_CFLAGS="-Wall -Wextra -Wno-ignored-attributes"

if [[ "$(uname -s)" == "Darwin" ]]; then
    COMMON_INCLUDES=("-I${SHIM_MACOS_DIR}" "-I${SHIM_WIN32_DIR}" "-I${INCLUDE_DIR}")
else
    COMMON_INCLUDES=("-I${SHIM_WIN32_DIR}" "-I${INCLUDE_DIR}")
fi

SUITE_CC=""
SUITE_KIND="c"
SUITE_ENTRY=""
SUITE_CFLAGS=""
SUITE_LDFLAGS=""
SUITE_LINK_ZIG="auto"
SUITE_LINK_CLI="auto"
SUITE_INTERACTIVE="no"
SUITE_SOURCES=""
ASM_FAMILY=""
ASM_RUNTIME=""
ASM_SOURCE=""
ASM_INVOKED="no"
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
            SUITE_CC) SUITE_CC="${value}" ;;
            SUITE_KIND) SUITE_KIND="${value}" ;;
            SUITE_ENTRY) SUITE_ENTRY="${value}" ;;
            SUITE_CFLAGS) SUITE_CFLAGS="${value}" ;;
            SUITE_LDFLAGS) SUITE_LDFLAGS="${value}" ;;
            SUITE_LINK_ZIG) SUITE_LINK_ZIG="${value}" ;;
            SUITE_LINK_CLI) SUITE_LINK_CLI="${value}" ;;
            SUITE_INTERACTIVE) SUITE_INTERACTIVE="${value}" ;;
            SUITE_SOURCES) SUITE_SOURCES="${value}" ;;
            ASM_FAMILY) ASM_FAMILY="${value}" ;;
            ASM_RUNTIME) ASM_RUNTIME="${value}" ;;
            ASM_SOURCE) ASM_SOURCE="${value}" ;;
            ASM_INVOKED) ASM_INVOKED="${value}" ;;
            ASM_TOOL) ASM_TOOL="${value}" ;;
            ASM_FORMAT) ASM_FORMAT="${value}" ;;
            ASM_REQUIRED) ASM_REQUIRED="${value}" ;;
        esac
    done < "${cfg_path}"
}

load_suite_cfg "${SUITE_DIR}/suite.cfg"

if [[ -n "${ASM_FAMILY}" ]]; then
    printf '  → Assembler profile: %s' "${ASM_FAMILY}"
    if [[ -n "${ASM_RUNTIME}" ]]; then
        printf ' (%s)' "${ASM_RUNTIME}"
    fi
    printf '\n'
    if [[ -n "${ASM_SOURCE}" ]]; then
        printf '    source: %s\n' "${ASM_SOURCE}"
    fi
    if [[ "${ASM_INVOKED}" != "yes" ]]; then
        printf '    mode: translation layer reference, no external assembler invocation\n'
    fi
fi

if [[ "${ASM_INVOKED}" == "yes" ]]; then
    if ( cd "${ROOT_DIR}" && ./tools/assemble_suite.sh "${SUITE_NAME}" ); then
        :
    else
        asm_rc=$?
        if [[ ${asm_rc} -eq 134 ]]; then
            printf '  ✗ Assembler ABI validation aborted for suite: %s\n' "${SUITE_NAME}" >&2
        else
            printf '  ✗ Assembler stage failed for suite: %s (exit %d)\n' "${SUITE_NAME}" "${asm_rc}" >&2
        fi
        exit "${asm_rc}"
    fi
fi

is_cxx_compiler() {
    local cc_name
    cc_name="$(basename "$1")"
    [[ "$1" == *"++"* || "$cc_name" == "c++" ]]
}

ensure_zig_lib() {
    ( cd "${ROOT_DIR}" && env MACOSX_DEPLOYMENT_TARGET=13.0 zig build --build-file build/build.zig install )
}

ensure_window_lib() {
    ( cd "${ROOT_DIR}" && make window-lib >/dev/null )
}

ensure_default_obj() {
    ( cd "${ROOT_DIR}" && make default_main.o >/dev/null )
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
if [[ "${SUITE_LDFLAGS}" == *"librosetta_window.a"* ]]; then
    ensure_window_lib
fi

link_cli="${SUITE_LINK_CLI}"
if [[ "${link_cli}" == "auto" ]]; then
    if [[ "${SUITE_LDFLAGS}" == *"librosetta_window.a"* ]]; then
        link_cli="no"
    elif [[ -f "${ROOT_DIR}/${CLI_LIB}" ]]; then
        link_cli="yes"
    else
        link_cli="no"
    fi
fi

link_default_main="no"
if [[ "${SUITE_LDFLAGS}" == *"librosetta_window.a"* && "${SUITE_CFLAGS}" == *"-Dmain=rosetta_game_main"* ]]; then
    ensure_default_obj
    link_default_main="yes"
fi

needs_window_runtime="no"
needs_window_stub="no"
if [[ "${link_zig}" == "yes" ]]; then
    if [[ "${SUITE_LDFLAGS}" == *"librosetta_window.a"* ]]; then
        ensure_window_lib
        needs_window_runtime="yes"
        if [[ "${link_cli}" == "auto" || "${link_cli}" == "yes" ]]; then
            link_cli="no"
        fi
    else
        needs_window_stub="yes"
    fi
fi

if [[ "${SUITE_KIND}" == "zig" ]]; then
    if [[ -z "${SUITE_ENTRY}" ]]; then
        echo "suite ${SUITE_NAME} is SUITE_KIND=zig but has no SUITE_ENTRY" >&2
        exit 1
    fi

    mkdir -p "$(dirname "${OUTPUT_BIN}")"
    declare -a zig_cmd=(
        "zig" "build-exe" "${SUITE_ENTRY}"
        "-femit-bin=${OUTPUT_BIN}"
        "--cache-dir" "build/.zig-cache"
        "--global-cache-dir" "build/.zig-global-cache"
    )
    if [[ "${SUITE_LDFLAGS}" == *"librosetta_window.a"* ]]; then
        zig_cmd+=("-L." "-lrosetta_window" "-lc++" "-lobjc" "-framework" "Cocoa" "-framework" "Foundation")
    fi
    if [[ "${link_cli}" == "yes" ]]; then
        zig_cmd+=("-L." "-lrosetta_cli")
    fi
    if [[ "${link_zig}" == "yes" ]]; then
        zig_cmd+=("${ZIG_LIB}")
    fi
    zig_cmd+=("-lc")
    ( cd "${ROOT_DIR}" && "${zig_cmd[@]}" )
    printf '%s\n' "${OUTPUT_BIN}"
    exit 0
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
    compile_cc="${SUITE_CC}"
    link_cc="${SUITE_CC}"
elif [[ "${ext}" == "cpp" ]]; then
    compile_cc="${DEFAULT_CXX}"
    link_cc="${DEFAULT_CXX}"
elif [[ "${SUITE_LDFLAGS}" == *"librosetta_window.a"* || "${needs_window_runtime}" == "yes" ]]; then
    compile_cc="${DEFAULT_CC}"
    link_cc="${DEFAULT_CXX}"
else
    compile_cc="${DEFAULT_CC}"
    link_cc="${DEFAULT_CC}"
fi

mkdir -p "$(dirname "${OUTPUT_BIN}")"

tmp_obj="${OUTPUT_BIN}.o"
tmp_stub_obj="${OUTPUT_BIN}.window_stub.o"
trap 'rm -f "${tmp_obj}" "${tmp_stub_obj}"' EXIT

declare -a compile_cmd=("${compile_cc}")
if is_cxx_compiler "${compile_cc}"; then
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

if [[ "${needs_window_stub}" == "yes" ]]; then
    declare -a stub_cmd=("${DEFAULT_CC}")
    read -ra _stub_default_flags <<< "${DEFAULT_CFLAGS}"
    stub_cmd+=("${_stub_default_flags[@]}")
    stub_cmd+=("${COMMON_INCLUDES[@]}")
    stub_cmd+=("-c" "${WINDOW_STUB_SRC}" "-o" "${tmp_stub_obj}")
    ( cd "${ROOT_DIR}" && "${stub_cmd[@]}" )
fi

declare -a link_cmd=("${link_cc}")
if is_cxx_compiler "${link_cc}"; then
    link_cmd+=("-std=c++11")
fi
if [[ "${SUITE_LDFLAGS}" == *"librosetta_window.a"* || "${needs_window_runtime}" == "yes" ]]; then
    link_cmd+=("-fobjc-link-runtime")
fi
link_cmd+=("${tmp_obj}")
if [[ -n "${SUITE_LDFLAGS}" ]]; then
    read -ra _ldflags <<< "${SUITE_LDFLAGS}"
    link_cmd+=("${_ldflags[@]}")
fi
if [[ "${link_cli}" == "yes" ]]; then
    link_cmd+=("${CLI_LIB}")
fi
if [[ "${link_zig}" == "yes" ]]; then
    link_cmd+=("${ZIG_LIB}")
fi
if [[ "${needs_window_runtime}" == "yes" && "${SUITE_LDFLAGS}" != *"librosetta_window.a"* ]]; then
    link_cmd+=("${WINDOW_LIB}" "-lobjc" "-framework" "Cocoa" "-framework" "Foundation")
fi
if [[ "${needs_window_stub}" == "yes" ]]; then
    link_cmd+=("${tmp_stub_obj}")
fi
if [[ "${link_default_main}" == "yes" ]]; then
    link_cmd+=("${DEFAULT_OBJ}")
fi
link_cmd+=("-o" "${OUTPUT_BIN}")

( cd "${ROOT_DIR}" && "${link_cmd[@]}" )
printf '%s\n' "${OUTPUT_BIN}"
