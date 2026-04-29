#!/bin/bash
#
# CAO 통합 환경 검증 스크립트
#
# 모든 의존성(WSL, Ubuntu, Python, tmux, uv, CAO, Kiro CLI)의
# 설치 상태를 한 번에 확인하고 종합 결과를 출력합니다.
#
# 사용법:
#   bash ./scripts/verify-all.sh
#
# 종료 코드:
#   0 = 모든 검증 통과
#   1 = 하나 이상 실패
#
# 요구사항: 10.1, 10.5

# --- 색상 코드 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# --- 카운터 ---
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
TOTAL=0

# --- 결과 저장 (출력용) ---
declare -a RESULT_LINES=()
declare -a FAIL_GUIDES=()

# ============================================================
# 유틸리티 함수
# ============================================================

check_version_gte() {
    # 시맨틱 버전을 비교합니다. current >= required이면 0을 반환합니다.
    #
    # 사용법: check_version_gte <CURRENT_VERSION> <REQUIRED_VERSION>
    #   반환값: 0 = current >= required, 1 = current < required
    local current="${1}"
    local required="${2}"

    # 숫자와 점만 남기기 (예: "3.2a" -> "3.2", "next-3.4" -> "3.4")
    current="$(echo "${current}" | grep -oE '[0-9]+(\.[0-9]+)*' | head -1)"
    required="$(echo "${required}" | grep -oE '[0-9]+(\.[0-9]+)*' | head -1)"

    if [[ -z "${current}" ]]; then
        return 1
    fi
    if [[ -z "${required}" ]]; then
        return 0
    fi

    IFS='.' read -ra cur_parts <<< "${current}"
    IFS='.' read -ra req_parts <<< "${required}"

    local max_len=${#req_parts[@]}
    if (( ${#cur_parts[@]} > max_len )); then
        max_len=${#cur_parts[@]}
    fi

    for (( i=0; i<max_len; i++ )); do
        local cur_val="${cur_parts[$i]:-0}"
        local req_val="${req_parts[$i]:-0}"

        if (( cur_val > req_val )); then
            return 0
        elif (( cur_val < req_val )); then
            return 1
        fi
    done

    return 0
}

record_pass() {
    # 통과 항목을 기록합니다.
    local item="$1"
    local detail="$2"
    RESULT_LINES+=("$(printf "${GREEN}║  [PASS] %-14s - %-27s${NC}" "${item}" "${detail}")")
    PASS_COUNT=$((PASS_COUNT + 1))
    TOTAL=$((TOTAL + 1))
}

record_fail() {
    # 실패 항목을 기록합니다.
    local item="$1"
    local detail="$2"
    local guide="$3"
    RESULT_LINES+=("$(printf "${RED}║  [FAIL] %-14s - %-27s${NC}" "${item}" "${detail}")")
    if [[ -n "${guide}" ]]; then
        FAIL_GUIDES+=("$(printf "${YELLOW}  → %s를 참조하여 %s 문제를 해결하세요.${NC}" "${guide}" "${item}")")
    fi
    FAIL_COUNT=$((FAIL_COUNT + 1))
    TOTAL=$((TOTAL + 1))
}

record_skip() {
    # 건너뛴 항목을 기록합니다 (해당 환경이 아닌 경우).
    local item="$1"
    local detail="$2"
    RESULT_LINES+=("$(printf "${GRAY}║  [SKIP] %-14s - %-27s${NC}" "${item}" "${detail}")")
    SKIP_COUNT=$((SKIP_COUNT + 1))
    TOTAL=$((TOTAL + 1))
}

# ============================================================
# 검증 항목
# ============================================================

check_wsl() {
    # WSL 환경 확인 (/proc/version에서 microsoft/wsl 키워드 검색)
    if [[ -f /proc/version ]]; then
        local proc_version
        proc_version="$(cat /proc/version)"
        if echo "${proc_version}" | grep -qiE '(microsoft|wsl)'; then
            # WSL 버전 추출 시도
            local wsl_ver="WSL 2"
            if command -v wsl.exe &>/dev/null; then
                local ver_output
                ver_output="$(wsl.exe --version 2>/dev/null | head -1 | tr -d '\r' || true)"
                if [[ -n "${ver_output}" ]]; then
                    local ver_num
                    ver_num="$(echo "${ver_output}" | grep -oE '[0-9]+(\.[0-9]+)*' | head -1)"
                    if [[ -n "${ver_num}" ]]; then
                        wsl_ver="버전 ${ver_num}"
                    fi
                fi
            fi
            record_pass "WSL 2" "${wsl_ver}"
            return
        fi
    fi
    record_skip "WSL 2" "WSL 환경이 아닙니다"
}

check_ubuntu() {
    # Ubuntu 버전 확인 (lsb_release, >= 20.04)
    if command -v lsb_release &>/dev/null; then
        local ubuntu_ver
        ubuntu_ver="$(lsb_release -r -s 2>/dev/null)"

        if [[ -n "${ubuntu_ver}" ]]; then
            if check_version_gte "${ubuntu_ver}" "20.04"; then
                record_pass "Ubuntu" "${ubuntu_ver} LTS"
            else
                record_fail "Ubuntu" "${ubuntu_ver} (최소 20.04 필요)" "step-01-wsl-setup/README.md"
            fi
        else
            record_fail "Ubuntu" "버전 확인 불가" "step-01-wsl-setup/README.md"
        fi
    else
        record_fail "Ubuntu" "lsb_release 미설치" "step-01-wsl-setup/README.md"
    fi
}

check_python() {
    # Python 버전 확인 (python3 --version, >= 3.10)
    if command -v python3 &>/dev/null; then
        local py_ver
        py_ver="$(python3 --version 2>&1 | awk '{print $2}')"
        if check_version_gte "${py_ver}" "3.10"; then
            record_pass "Python" "${py_ver}"
        else
            record_fail "Python" "${py_ver} (최소 3.10 필요)" "step-02-python/README.md"
        fi
    else
        record_fail "Python" "미설치" "step-02-python/README.md"
    fi
}

check_tmux() {
    # tmux 버전 확인 (tmux -V, >= 3.3)
    if command -v tmux &>/dev/null; then
        local tmux_ver
        tmux_ver="$(tmux -V 2>&1 | awk '{print $2}')"
        if check_version_gte "${tmux_ver}" "3.3"; then
            record_pass "tmux" "${tmux_ver}"
        else
            record_fail "tmux" "버전 ${tmux_ver} (최소 3.3 필요)" "step-03-tmux/README.md"
        fi
    else
        record_fail "tmux" "미설치" "step-03-tmux/README.md"
    fi
}

check_uv() {
    # uv 설치 확인 (uv --version)
    # PATH에 없을 수 있으므로 일반적인 경로도 확인
    if [[ -f "${HOME}/.local/bin/uv" ]]; then
        export PATH="${HOME}/.local/bin:${PATH}"
    fi
    if [[ -f "${HOME}/.cargo/bin/uv" ]]; then
        export PATH="${HOME}/.cargo/bin:${PATH}"
    fi

    if command -v uv &>/dev/null; then
        local uv_ver
        uv_ver="$(uv --version 2>&1 | awk '{print $2}')"
        record_pass "uv" "${uv_ver}"
    else
        record_fail "uv" "미설치" "step-04-uv/README.md"
    fi
}

check_cao() {
    # CAO 설치 확인 (cao --help 또는 cao --version)
    if command -v cao &>/dev/null; then
        local cao_ver
        cao_ver="$(cao --version 2>&1 || echo "설치됨")"
        # cao --version 출력이 길 수 있으므로 첫 줄만 사용
        cao_ver="$(echo "${cao_ver}" | head -1)"
        if [[ ${#cao_ver} -gt 25 ]]; then
            cao_ver="설치됨"
        fi
        record_pass "CAO" "${cao_ver}"
    else
        record_fail "CAO" "미설치" "step-05-cao/README.md"
    fi
}

check_kiro_cli() {
    # Kiro CLI 설치 확인 (kiro-cli --version)
    if command -v kiro-cli &>/dev/null; then
        local kiro_ver
        kiro_ver="$(kiro-cli --version 2>&1 || echo "설치됨")"
        kiro_ver="$(echo "${kiro_ver}" | head -1)"
        if [[ ${#kiro_ver} -gt 25 ]]; then
            kiro_ver="설치됨"
        fi
        record_pass "Kiro CLI" "${kiro_ver}"
    else
        record_fail "Kiro CLI" "미설치" "step-06-kiro-cli/README.md"
    fi
}

# ============================================================
# 결과 출력
# ============================================================

print_results() {
    # 설계 문서의 검증 결과 출력 형식(테이블)을 따릅니다.
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        CAO 환경 검증 결과                    ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════╣${NC}"

    for line in "${RESULT_LINES[@]}"; do
        echo -e "${line}║"
    done

    echo -e "${CYAN}╠══════════════════════════════════════════════╣${NC}"

    local checked=$((PASS_COUNT + FAIL_COUNT))
    if [[ ${FAIL_COUNT} -eq 0 ]]; then
        echo -e "${GREEN}║  결과: ${PASS_COUNT}/${checked} 통과 ✓                          ║${NC}"
    else
        echo -e "${RED}║  결과: ${PASS_COUNT}/${checked} 통과, ${FAIL_COUNT}개 실패                  ║${NC}"
    fi

    echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"

    # 실패 항목에 대한 가이드 안내 출력
    if [[ ${#FAIL_GUIDES[@]} -gt 0 ]]; then
        echo ""
        echo -e "${YELLOW}--- 실패 항목 해결 안내 ---${NC}"
        for guide in "${FAIL_GUIDES[@]}"; do
            echo -e "${guide}"
        done
        echo ""
        echo -e "${YELLOW}  전체 트러블슈팅 가이드: step-10-troubleshooting/README.md${NC}"
    fi

    echo ""
}

# ============================================================
# 메인 실행
# ============================================================

# 모든 검증 항목 실행
check_wsl
check_ubuntu
check_python
check_tmux
check_uv
check_cao
check_kiro_cli

# 결과 테이블 출력
print_results

# 종료 코드: 0 = 모든 검증 통과, 1 = 하나 이상 실패
if [[ ${FAIL_COUNT} -gt 0 ]]; then
    exit 1
else
    exit 0
fi
