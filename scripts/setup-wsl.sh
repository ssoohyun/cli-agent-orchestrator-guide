#!/bin/bash
#
# CLI Agent Orchestrator(CAO) WSL 환경 자동 설정 스크립트
#
# WSL(Ubuntu) 환경에서 실행하여 Python, tmux, uv, CAO, Kiro CLI 등
# 모든 의존성을 한 번에 설치합니다.
#
# 사용법:
#   bash ./scripts/setup-wsl.sh
#
# 기능:
#   - WSL 환경 확인
#   - 인터넷 연결 확인
#   - 시스템 패키지 업데이트 (apt update/upgrade)
#   - Python 3.10+ 설치 (멱등성)
#   - tmux 3.3+ 설치 - CAO 공식 스크립트 (멱등성)
#   - uv 설치 및 PATH 설정 (멱등성)
#   - CAO 설치 및 에이전트 프로필 설치 (멱등성)
#   - Kiro CLI 설치 (멱등성)
#   - 전체 환경 검증 및 요약 출력
#   - 실행 로그 파일 저장 (setup-wsl.log)
#

set -uo pipefail

# --- 스크립트 디렉토리 및 로그 파일 경로 ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/setup-wsl.log"

# --- 단계 상태 추적 ---
declare -A STEP_STATUS
declare -A STEP_VERSION
TOTAL_STEPS=8

# --- 색상 코드 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# ============================================================
# 유틸리티 함수
# ============================================================

log_message() {
    # 타임스탬프가 포함된 메시지를 로그 파일과 콘솔에 기록합니다.
    #
    # 사용법: log_message <LEVEL> <MESSAGE>
    #   LEVEL: INFO, WARN, ERROR
    #   MESSAGE: 기록할 메시지
    local level="${1:-INFO}"
    local message="${2:-}"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    local log_entry="[${timestamp}] [${level}] ${message}"

    # 로그 파일에 기록
    echo "${log_entry}" >> "${LOG_FILE}"

    # 콘솔에 출력 (레벨별 색상 구분)
    case "${level}" in
        INFO)  echo -e "${CYAN}${log_entry}${NC}" ;;
        WARN)  echo -e "${YELLOW}${log_entry}${NC}" ;;
        ERROR) echo -e "${RED}${log_entry}${NC}" ;;
        *)     echo "${log_entry}" ;;
    esac
}

print_step() {
    # 현재 진행 단계 번호, 단계 이름, 진행 상태를 실시간으로 출력합니다.
    #
    # 사용법: print_step <STEP_NUMBER> <STEP_NAME> <STATUS>
    #   STATUS: running, completed, skipped, failed
    local step_number="${1}"
    local step_name="${2}"
    local status="${3}"
    local prefix="[${step_number}/${TOTAL_STEPS}]"
    local status_text=""
    local color=""

    case "${status}" in
        running)
            status_text="진행 중..."
            color="${YELLOW}"
            ;;
        completed)
            status_text="완료"
            color="${GREEN}"
            ;;
        skipped)
            status_text="건너뜀"
            color="${GRAY}"
            ;;
        failed)
            status_text="실패"
            color="${RED}"
            ;;
        *)
            status_text="${status}"
            color="${NC}"
            ;;
    esac

    echo -e "${color}${prefix} ${step_name} ... ${status_text}${NC}"
    log_message "INFO" "${prefix} ${step_name} ... ${status_text}"
}

check_version_gte() {
    # 시맨틱 버전을 비교합니다. current >= required이면 0을 반환합니다.
    #
    # 사용법: check_version_gte <CURRENT_VERSION> <REQUIRED_VERSION>
    #   반환값: 0 = current >= required, 1 = current < required
    #
    # 예시:
    #   check_version_gte "3.12.3" "3.10" && echo "OK"
    #   check_version_gte "3.2a" "3.3"   || echo "too old"
    local current="${1}"
    local required="${2}"

    # 숫자와 점만 남기기 (예: "3.2a" -> "3.2", "next-3.4" -> "3.4")
    current="$(echo "${current}" | grep -oE '[0-9]+(\.[0-9]+)*' | head -1)"
    required="$(echo "${required}" | grep -oE '[0-9]+(\.[0-9]+)*' | head -1)"

    # 빈 문자열 처리
    if [[ -z "${current}" ]]; then
        return 1
    fi
    if [[ -z "${required}" ]]; then
        return 0
    fi

    # major.minor.patch 분리
    IFS='.' read -ra cur_parts <<< "${current}"
    IFS='.' read -ra req_parts <<< "${required}"

    # 최대 깊이만큼 비교
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

    # 모든 부분이 동일하면 같은 버전 (current == required)
    return 0
}

# ============================================================
# 환경 확인 함수
# ============================================================

check_wsl_environment() {
    # WSL 환경에서 실행 중인지 확인합니다.
    # WSL이 아닌 경우 안내 메시지를 출력하고 스크립트를 중단합니다.
    log_message "INFO" "WSL 환경 확인 중..."

    if [[ -f /proc/version ]]; then
        local proc_version
        proc_version="$(cat /proc/version)"
        if echo "${proc_version}" | grep -qiE '(microsoft|wsl)'; then
            log_message "INFO" "WSL 환경 확인 완료"
            return 0
        fi
    fi

    log_message "ERROR" "이 스크립트는 WSL(Windows Subsystem for Linux) 환경에서 실행해야 합니다."
    log_message "ERROR" ""
    log_message "ERROR" "Ubuntu 터미널을 열어서 실행해 주세요."
    exit 1
}

check_internet() {
    # 인터넷 연결 상태를 확인합니다.
    # 연결 불가 시 오류 메시지를 출력하고 스크립트를 중단합니다.
    log_message "INFO" "인터넷 연결 확인 중..."

    # ping으로 확인
    if ping -c 1 -W 5 8.8.8.8 &>/dev/null; then
        log_message "INFO" "인터넷 연결 확인 완료 (ping)"
        return 0
    fi

    # curl로 재시도
    if command -v curl &>/dev/null; then
        if curl -s --connect-timeout 10 --max-time 15 https://www.google.com -o /dev/null 2>/dev/null; then
            log_message "INFO" "인터넷 연결 확인 완료 (curl)"
            return 0
        fi
    fi

    # wget으로 재시도
    if command -v wget &>/dev/null; then
        if wget -q --timeout=10 --spider https://www.google.com 2>/dev/null; then
            log_message "INFO" "인터넷 연결 확인 완료 (wget)"
            return 0
        fi
    fi

    log_message "ERROR" "인터넷 연결을 확인할 수 없습니다."
    log_message "ERROR" ""
    log_message "ERROR" "다음 사항을 확인해 주세요:"
    log_message "ERROR" "  1. Wi-Fi 또는 이더넷 연결 상태"
    log_message "ERROR" "  2. WSL 네트워크 설정 (DNS 등)"
    log_message "ERROR" "  3. 프록시 또는 방화벽 설정"
    log_message "ERROR" ""
    log_message "ERROR" "WSL DNS 문제 해결:"
    log_message "ERROR" "  echo 'nameserver 8.8.8.8' | sudo tee /etc/resolv.conf"
    exit 1
}

# ============================================================
# 의존성 설치 함수
# ============================================================

update_system_packages() {
    # 시스템 패키지 목록을 업데이트하고 기본 패키지를 업그레이드합니다.
    # apt update/upgrade는 멱등성이 보장됩니다.
    log_message "INFO" "시스템 패키지 업데이트 시작..."

    if sudo apt update -y >> "${LOG_FILE}" 2>&1 && \
       sudo apt upgrade -y >> "${LOG_FILE}" 2>&1; then
        STEP_STATUS["system-update"]="installed"
        STEP_VERSION["system-update"]="$(date '+%Y-%m-%d')"
        log_message "INFO" "시스템 패키지 업데이트 완료"
    else
        STEP_STATUS["system-update"]="failed"
        STEP_VERSION["system-update"]=""
        log_message "ERROR" "시스템 패키지 업데이트 실패"
        log_message "ERROR" "수동 해결: sudo apt update && sudo apt upgrade -y"
        log_message "ERROR" "DNS 문제일 수 있습니다: echo 'nameserver 8.8.8.8' | sudo tee /etc/resolv.conf"
        return 1
    fi
}

install_python() {
    # Python 3.10 이상을 설치합니다.
    # 이미 설치되어 있으면 건너뜁니다.
    local required_version="3.10"

    if command -v python3 &>/dev/null; then
        local current_version
        current_version="$(python3 --version 2>&1 | awk '{print $2}')"
        if check_version_gte "${current_version}" "${required_version}"; then
            STEP_STATUS["python"]="skipped"
            STEP_VERSION["python"]="${current_version}"
            log_message "INFO" "Python 이미 설치됨 (${current_version})"
            return 0
        fi
        log_message "WARN" "Python ${current_version} 설치됨 - ${required_version} 이상 필요, 업그레이드 진행"
    fi

    log_message "INFO" "Python 설치 시작..."
    if sudo apt install -y python3 python3-pip python3-venv >> "${LOG_FILE}" 2>&1; then
        local installed_version
        installed_version="$(python3 --version 2>&1 | awk '{print $2}')"
        STEP_STATUS["python"]="installed"
        STEP_VERSION["python"]="${installed_version}"
        log_message "INFO" "Python ${installed_version} 설치 완료"
    else
        STEP_STATUS["python"]="failed"
        STEP_VERSION["python"]=""
        log_message "ERROR" "Python 설치 실패"
        log_message "ERROR" "수동 해결: sudo apt install -y python3 python3-pip python3-venv"
        return 1
    fi
}

install_tmux() {
    # tmux 3.3 이상을 CAO 공식 스크립트로 설치합니다.
    # 이미 설치되어 있으면 건너뜁니다.
    local required_version="3.3"

    if command -v tmux &>/dev/null; then
        local current_version
        current_version="$(tmux -V 2>&1 | awk '{print $2}')"
        if check_version_gte "${current_version}" "${required_version}"; then
            STEP_STATUS["tmux"]="skipped"
            STEP_VERSION["tmux"]="${current_version}"
            log_message "INFO" "tmux 이미 설치됨 (${current_version})"
            return 0
        fi
        log_message "WARN" "tmux ${current_version} 설치됨 - ${required_version} 이상 필요, 업그레이드 진행"
    fi

    log_message "INFO" "tmux 설치 시작 (CAO 공식 스크립트)..."
    if bash <(curl -s https://raw.githubusercontent.com/awslabs/cli-agent-orchestrator/refs/heads/main/tmux-install.sh) >> "${LOG_FILE}" 2>&1; then
        # 새로 설치된 tmux 경로를 PATH에 반영
        export PATH="/usr/local/bin:${PATH}"
        if command -v tmux &>/dev/null; then
            local installed_version
            installed_version="$(tmux -V 2>&1 | awk '{print $2}')"
            STEP_STATUS["tmux"]="installed"
            STEP_VERSION["tmux"]="${installed_version}"
            log_message "INFO" "tmux ${installed_version} 설치 완료"
        else
            STEP_STATUS["tmux"]="installed"
            STEP_VERSION["tmux"]="설치됨 (버전 확인 불가)"
            log_message "WARN" "tmux 설치 완료 (버전 확인 불가 - 셸 재시작 필요할 수 있음)"
        fi
    else
        STEP_STATUS["tmux"]="failed"
        STEP_VERSION["tmux"]=""
        log_message "ERROR" "tmux 설치 실패"
        log_message "ERROR" "수동 해결: bash <(curl -s https://raw.githubusercontent.com/awslabs/cli-agent-orchestrator/refs/heads/main/tmux-install.sh)"
        log_message "ERROR" "또는 step-03-tmux/README.md의 수동 빌드 설치 방법을 참조하세요."
        return 1
    fi
}

install_uv() {
    # uv 패키지 관리자를 설치하고 PATH를 설정합니다.
    # 이미 설치되어 있으면 건너뜁니다.

    # 기존 PATH에 uv가 있을 수 있으므로 먼저 확인
    if [[ -f "${HOME}/.local/bin/uv" ]]; then
        export PATH="${HOME}/.local/bin:${PATH}"
    fi
    if [[ -f "${HOME}/.cargo/bin/uv" ]]; then
        export PATH="${HOME}/.cargo/bin:${PATH}"
    fi

    if command -v uv &>/dev/null; then
        local current_version
        current_version="$(uv --version 2>&1 | awk '{print $2}')"
        STEP_STATUS["uv"]="skipped"
        STEP_VERSION["uv"]="${current_version}"
        log_message "INFO" "uv 이미 설치됨 (${current_version})"
        return 0
    fi

    log_message "INFO" "uv 설치 시작..."
    if curl -LsSf https://astral.sh/uv/install.sh | sh >> "${LOG_FILE}" 2>&1; then
        # PATH 설정 반영
        if [[ -f "${HOME}/.local/bin/uv" ]]; then
            export PATH="${HOME}/.local/bin:${PATH}"
        fi
        if [[ -f "${HOME}/.cargo/bin/uv" ]]; then
            export PATH="${HOME}/.cargo/bin:${PATH}"
        fi

        if command -v uv &>/dev/null; then
            local installed_version
            installed_version="$(uv --version 2>&1 | awk '{print $2}')"
            STEP_STATUS["uv"]="installed"
            STEP_VERSION["uv"]="${installed_version}"
            log_message "INFO" "uv ${installed_version} 설치 완료"

            # .bashrc에 PATH 영구 등록
            if ! grep -q '\.local/bin' "${HOME}/.bashrc" 2>/dev/null; then
                echo '' >> "${HOME}/.bashrc"
                echo '# uv / CAO PATH (setup-wsl.sh에 의해 추가됨)' >> "${HOME}/.bashrc"
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${HOME}/.bashrc"
                log_message "INFO" ".bashrc에 PATH 영구 등록 완료"
            fi
        else
            STEP_STATUS["uv"]="installed"
            STEP_VERSION["uv"]="설치됨 (PATH 설정 필요)"
            log_message "WARN" "uv 설치 완료 (셸 재시작 후 PATH가 적용됩니다)"

            # .bashrc에 PATH 영구 등록
            if ! grep -q '\.local/bin' "${HOME}/.bashrc" 2>/dev/null; then
                echo '' >> "${HOME}/.bashrc"
                echo '# uv / CAO PATH (setup-wsl.sh에 의해 추가됨)' >> "${HOME}/.bashrc"
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${HOME}/.bashrc"
                log_message "INFO" ".bashrc에 PATH 영구 등록 완료"
            fi
        fi
    else
        STEP_STATUS["uv"]="failed"
        STEP_VERSION["uv"]=""
        log_message "ERROR" "uv 설치 실패"
        log_message "ERROR" "수동 해결: curl -LsSf https://astral.sh/uv/install.sh | sh"
        log_message "ERROR" "설치 후: export PATH=\"\${HOME}/.local/bin:\${PATH}\""
        return 1
    fi
}

install_cao() {
    # CAO를 uv tool install로 설치하고 에이전트 프로필을 설치합니다.
    # 이미 설치되어 있으면 건너뜁니다.

    if command -v cao &>/dev/null; then
        local current_version
        current_version="$(cao --version 2>&1 || echo "설치됨")"
        STEP_STATUS["cao"]="skipped"
        STEP_VERSION["cao"]="${current_version}"
        log_message "INFO" "CAO 이미 설치됨 (${current_version})"
        return 0
    fi

    log_message "INFO" "CAO 설치 시작..."
    if ! command -v uv &>/dev/null; then
        STEP_STATUS["cao"]="failed"
        STEP_VERSION["cao"]=""
        log_message "ERROR" "CAO 설치 실패 - uv가 설치되어 있지 않습니다."
        log_message "ERROR" "먼저 uv를 설치해 주세요: curl -LsSf https://astral.sh/uv/install.sh | sh"
        return 1
    fi

    if uv tool install "git+https://github.com/awslabs/cli-agent-orchestrator.git@main" --upgrade >> "${LOG_FILE}" 2>&1; then
        # uv tool bin 경로를 PATH에 추가
        export PATH="${HOME}/.local/bin:${PATH}"

        if command -v cao &>/dev/null; then
            local installed_version
            installed_version="$(cao --version 2>&1 || echo "설치됨")"
            STEP_STATUS["cao"]="installed"
            STEP_VERSION["cao"]="${installed_version}"
            log_message "INFO" "CAO 설치 완료 (${installed_version})"

            # 에이전트 프로필 설치
            log_message "INFO" "CAO 에이전트 프로필 설치 중..."
            if cao install-profiles >> "${LOG_FILE}" 2>&1; then
                log_message "INFO" "CAO 에이전트 프로필 설치 완료"
            else
                log_message "WARN" "CAO 에이전트 프로필 설치 실패 - 수동 실행: cao install-profiles"
            fi
        else
            STEP_STATUS["cao"]="installed"
            STEP_VERSION["cao"]="설치됨 (PATH 설정 필요)"
            log_message "WARN" "CAO 설치 완료 (셸 재시작 후 PATH가 적용됩니다)"
        fi
    else
        STEP_STATUS["cao"]="failed"
        STEP_VERSION["cao"]=""
        log_message "ERROR" "CAO 설치 실패"
        log_message "ERROR" "수동 해결: uv tool install git+https://github.com/awslabs/cli-agent-orchestrator.git@main --upgrade"
        log_message "ERROR" "네트워크 또는 uv 설정을 확인해 주세요."
        return 1
    fi
}

install_kiro_cli() {
    # Kiro CLI를 .deb 패키지로 설치합니다.
    # 이미 설치되어 있으면 건너뜁니다.

    if command -v kiro-cli &>/dev/null; then
        local current_version
        current_version="$(kiro-cli --version 2>&1 || echo "설치됨")"
        STEP_STATUS["kiro-cli"]="skipped"
        STEP_VERSION["kiro-cli"]="${current_version}"
        log_message "INFO" "Kiro CLI 이미 설치됨 (${current_version})"
        return 0
    fi

    log_message "INFO" "Kiro CLI 설치 시작..."
    local deb_url="https://desktop-release.kiro.dev/kiro-cli-latest-amd64.deb"
    local deb_path="/tmp/kiro-cli.deb"

    if curl -fSL -o "${deb_path}" "${deb_url}" >> "${LOG_FILE}" 2>&1; then
        if sudo dpkg -i "${deb_path}" >> "${LOG_FILE}" 2>&1; then
            # 의존성 문제 해결
            sudo apt-get install -f -y >> "${LOG_FILE}" 2>&1 || true
            rm -f "${deb_path}"

            if command -v kiro-cli &>/dev/null; then
                local installed_version
                installed_version="$(kiro-cli --version 2>&1 || echo "설치됨")"
                STEP_STATUS["kiro-cli"]="installed"
                STEP_VERSION["kiro-cli"]="${installed_version}"
                log_message "INFO" "Kiro CLI ${installed_version} 설치 완료"
            else
                STEP_STATUS["kiro-cli"]="installed"
                STEP_VERSION["kiro-cli"]="설치됨 (버전 확인 불가)"
                log_message "WARN" "Kiro CLI 설치 완료 (버전 확인 불가)"
            fi
        else
            rm -f "${deb_path}"
            # dpkg 실패 시 의존성 해결 시도
            sudo apt-get install -f -y >> "${LOG_FILE}" 2>&1 || true
            STEP_STATUS["kiro-cli"]="failed"
            STEP_VERSION["kiro-cli"]=""
            log_message "ERROR" "Kiro CLI 설치 실패 (dpkg)"
            log_message "ERROR" "수동 해결: sudo dpkg -i /tmp/kiro-cli.deb && sudo apt-get install -f -y"
            return 1
        fi
    else
        STEP_STATUS["kiro-cli"]="failed"
        STEP_VERSION["kiro-cli"]=""
        log_message "ERROR" "Kiro CLI 다운로드 실패"
        log_message "ERROR" "수동 해결: curl -fSL -o /tmp/kiro-cli.deb ${deb_url} && sudo dpkg -i /tmp/kiro-cli.deb"
        return 1
    fi
}

# ============================================================
# 요약 출력 및 환경 검증 함수
# ============================================================

# 의존성 이름 → 가이드 참조 매핑
declare -A GUIDE_REFERENCE
GUIDE_REFERENCE=(
    ["system-update"]="step-01-wsl-setup/README.md"
    ["python"]="step-02-python/README.md"
    ["tmux"]="step-03-tmux/README.md"
    ["uv"]="step-04-uv/README.md"
    ["cao"]="step-05-cao/README.md"
    ["kiro-cli"]="step-06-kiro-cli/README.md"
)

# 의존성 이름 → 표시 이름 매핑
declare -A DISPLAY_NAME
DISPLAY_NAME=(
    ["system-update"]="시스템 패키지"
    ["python"]="Python 3.10+"
    ["tmux"]="tmux 3.3+"
    ["uv"]="uv"
    ["cao"]="CAO"
    ["kiro-cli"]="Kiro CLI"
)

print_summary_table() {
    # 각 의존성의 설치 상태와 버전을 요약 테이블로 출력합니다.
    # STEP_STATUS, STEP_VERSION 연관 배열을 사용합니다.
    #
    # 요구사항: 13.16
    local pass_count=0
    local fail_count=0
    local total=0
    local items=("system-update" "python" "tmux" "uv" "cao" "kiro-cli")

    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          CAO WSL 환경 설정 결과 요약                    ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════╣${NC}"

    for item in "${items[@]}"; do
        total=$((total + 1))
        local status="${STEP_STATUS[$item]:-unknown}"
        local version="${STEP_VERSION[$item]:-}"
        local display="${DISPLAY_NAME[$item]:-$item}"
        local icon=""
        local color=""
        local detail=""

        case "${status}" in
            installed)
                icon="[PASS]"
                color="${GREEN}"
                detail="${version:+$version}"
                pass_count=$((pass_count + 1))
                ;;
            skipped)
                icon="[SKIP]"
                color="${GRAY}"
                detail="이미 설치됨${version:+ ($version)}"
                pass_count=$((pass_count + 1))
                ;;
            completed)
                icon="[PASS]"
                color="${GREEN}"
                detail="완료"
                pass_count=$((pass_count + 1))
                ;;
            failed)
                icon="[FAIL]"
                color="${RED}"
                detail="설치 실패"
                fail_count=$((fail_count + 1))
                ;;
            *)
                icon="[----]"
                color="${GRAY}"
                detail="미실행"
                fail_count=$((fail_count + 1))
                ;;
        esac

        printf "${color}║  %-6s %-16s - %-30s ║${NC}\n" "${icon}" "${display}" "${detail}"

        # 실패 항목에 대해 가이드 참조 출력
        if [[ "${status}" == "failed" ]]; then
            local guide="${GUIDE_REFERENCE[$item]:-}"
            if [[ -n "${guide}" ]]; then
                printf "${YELLOW}║         → %-45s ║${NC}\n" "${guide} 참조"
            fi
        fi
    done

    echo -e "${CYAN}╠══════════════════════════════════════════════════════════╣${NC}"
    if [[ ${fail_count} -eq 0 ]]; then
        printf "${GREEN}║  결과: %d/%d 항목 통과 ✓                                 ║${NC}\n" "${pass_count}" "${total}"
    else
        printf "${RED}║  결과: %d/%d 항목 통과, %d개 실패                          ║${NC}\n" "${pass_count}" "${total}" "${fail_count}"
    fi
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    log_message "INFO" "요약: ${pass_count}/${total} 항목 통과, ${fail_count}개 실패"
}

run_verification() {
    # 설치 완료 후 전체 환경 검증을 수행합니다.
    # 각 의존성의 존재 여부와 최소 버전 요구사항을 확인합니다.
    #
    # 요구사항: 13.19
    local verify_pass=0
    local verify_fail=0
    local verify_total=0
    local failed_items=()

    echo ""
    log_message "INFO" "=== 전체 환경 검증 시작 ==="
    echo -e "${CYAN}--- 전체 환경 검증 ---${NC}"

    # Python 검증
    verify_total=$((verify_total + 1))
    if command -v python3 &>/dev/null; then
        local py_ver
        py_ver="$(python3 --version 2>&1 | awk '{print $2}')"
        if check_version_gte "${py_ver}" "3.10"; then
            echo -e "${GREEN}  [PASS] Python - ${py_ver}${NC}"
            log_message "INFO" "[PASS] Python - ${py_ver}"
            verify_pass=$((verify_pass + 1))
        else
            echo -e "${RED}  [FAIL] Python - ${py_ver} (최소 3.10 필요)${NC}"
            log_message "ERROR" "[FAIL] Python - ${py_ver} (최소 3.10 필요)"
            verify_fail=$((verify_fail + 1))
            failed_items+=("python")
        fi
    else
        echo -e "${RED}  [FAIL] Python - 미설치${NC}"
        log_message "ERROR" "[FAIL] Python - 미설치"
        verify_fail=$((verify_fail + 1))
        failed_items+=("python")
    fi

    # tmux 검증
    verify_total=$((verify_total + 1))
    if command -v tmux &>/dev/null; then
        local tmux_ver
        tmux_ver="$(tmux -V 2>&1 | awk '{print $2}')"
        if check_version_gte "${tmux_ver}" "3.3"; then
            echo -e "${GREEN}  [PASS] tmux - ${tmux_ver}${NC}"
            log_message "INFO" "[PASS] tmux - ${tmux_ver}"
            verify_pass=$((verify_pass + 1))
        else
            echo -e "${RED}  [FAIL] tmux - ${tmux_ver} (최소 3.3 필요)${NC}"
            log_message "ERROR" "[FAIL] tmux - ${tmux_ver} (최소 3.3 필요)"
            verify_fail=$((verify_fail + 1))
            failed_items+=("tmux")
        fi
    else
        echo -e "${RED}  [FAIL] tmux - 미설치${NC}"
        log_message "ERROR" "[FAIL] tmux - 미설치"
        verify_fail=$((verify_fail + 1))
        failed_items+=("tmux")
    fi

    # uv 검증
    verify_total=$((verify_total + 1))
    if command -v uv &>/dev/null; then
        local uv_ver
        uv_ver="$(uv --version 2>&1 | awk '{print $2}')"
        echo -e "${GREEN}  [PASS] uv - ${uv_ver}${NC}"
        log_message "INFO" "[PASS] uv - ${uv_ver}"
        verify_pass=$((verify_pass + 1))
    else
        echo -e "${RED}  [FAIL] uv - 미설치${NC}"
        log_message "ERROR" "[FAIL] uv - 미설치"
        verify_fail=$((verify_fail + 1))
        failed_items+=("uv")
    fi

    # CAO 검증
    verify_total=$((verify_total + 1))
    if command -v cao &>/dev/null; then
        local cao_ver
        cao_ver="$(cao --version 2>&1 || echo "설치됨")"
        echo -e "${GREEN}  [PASS] CAO - ${cao_ver}${NC}"
        log_message "INFO" "[PASS] CAO - ${cao_ver}"
        verify_pass=$((verify_pass + 1))
    else
        echo -e "${RED}  [FAIL] CAO - 미설치${NC}"
        log_message "ERROR" "[FAIL] CAO - 미설치"
        verify_fail=$((verify_fail + 1))
        failed_items+=("cao")
    fi

    # Kiro CLI 검증
    verify_total=$((verify_total + 1))
    if command -v kiro-cli &>/dev/null; then
        local kiro_ver
        kiro_ver="$(kiro-cli --version 2>&1 || echo "설치됨")"
        echo -e "${GREEN}  [PASS] Kiro CLI - ${kiro_ver}${NC}"
        log_message "INFO" "[PASS] Kiro CLI - ${kiro_ver}"
        verify_pass=$((verify_pass + 1))
    else
        echo -e "${RED}  [FAIL] Kiro CLI - 미설치${NC}"
        log_message "ERROR" "[FAIL] Kiro CLI - 미설치"
        verify_fail=$((verify_fail + 1))
        failed_items+=("kiro-cli")
    fi

    echo ""
    echo -e "${CYAN}  검증 결과: ${verify_pass}/${verify_total} 통과${NC}"
    log_message "INFO" "검증 결과: ${verify_pass}/${verify_total} 통과"

    # 실패 항목별 해결 방법 안내 (요구사항: 13.20)
    if [[ ${verify_fail} -gt 0 ]]; then
        echo ""
        echo -e "${YELLOW}--- 실패 항목 해결 안내 ---${NC}"
        for item in "${failed_items[@]}"; do
            local display="${DISPLAY_NAME[$item]:-$item}"
            local guide="${GUIDE_REFERENCE[$item]:-}"
            echo -e "${YELLOW}  • ${display}: ${guide} 를 참조하여 수동 설치하세요.${NC}"
            log_message "WARN" "${display} 실패 → ${guide} 참조"
        done
        echo ""
        echo -e "${YELLOW}  전체 트러블슈팅 가이드: step-10-troubleshooting/README.md${NC}"
        log_message "WARN" "전체 트러블슈팅 가이드: step-10-troubleshooting/README.md"
        return 1
    fi

    return 0
}

ask_continue_or_abort() {
    # 설치 실패 시 사용자에게 계속 진행할지 중단할지 선택을 요청합니다.
    #
    # 사용법: ask_continue_or_abort <STEP_NAME>
    #   반환값: 0 = 계속 진행, 1 = 중단
    #
    # 요구사항: 13.17
    local step_name="${1}"
    echo ""
    echo -e "${YELLOW}⚠ '${step_name}' 단계에서 오류가 발생했습니다.${NC}"
    echo -e "${YELLOW}  다음 단계로 계속 진행하시겠습니까?${NC}"
    echo ""

    local choice=""
    while true; do
        read -rp "  계속 진행 (y) / 중단 (n): " choice
        case "${choice}" in
            [yY]|[yY][eE][sS])
                log_message "INFO" "사용자 선택: '${step_name}' 실패 후 계속 진행"
                return 0
                ;;
            [nN]|[nN][oO])
                log_message "INFO" "사용자 선택: '${step_name}' 실패 후 중단"
                return 1
                ;;
            *)
                echo -e "${YELLOW}  'y' 또는 'n'을 입력해 주세요.${NC}"
                ;;
        esac
    done
}

# ============================================================
# 오류 처리 트랩
# ============================================================

on_error() {
    local exit_code=$?
    local line_number="${1:-unknown}"
    log_message "ERROR" "스크립트 실행 중 오류가 발생했습니다. (라인: ${line_number}, 종료 코드: ${exit_code})"
    log_message "ERROR" "로그 파일을 확인해 주세요: ${LOG_FILE}"
    exit "${exit_code}"
}

trap 'on_error ${LINENO}' ERR

# ============================================================
# 메인 실행 블록
# ============================================================

log_message "INFO" "=== CAO WSL 환경 설정 스크립트 시작 ==="

# --- Step 1: WSL 환경 확인 ---
print_step 1 "WSL 환경 확인" "running"
check_wsl_environment
print_step 1 "WSL 환경 확인" "completed"
STEP_STATUS["wsl-check"]="completed"

# --- Step 2: 인터넷 연결 확인 ---
print_step 2 "인터넷 연결 확인" "running"
check_internet
print_step 2 "인터넷 연결 확인" "completed"
STEP_STATUS["internet-check"]="completed"

# --- Step 3: 시스템 패키지 업데이트 ---
print_step 3 "시스템 패키지 업데이트" "running"
if update_system_packages; then
    print_step 3 "시스템 패키지 업데이트" "completed"
else
    print_step 3 "시스템 패키지 업데이트" "failed"
    if ! ask_continue_or_abort "시스템 패키지 업데이트"; then
        print_summary_table
        log_message "INFO" "=== 사용자 요청으로 스크립트 중단 ==="
        exit 1
    fi
fi

# --- Step 4: Python 3.10+ 설치 ---
print_step 4 "Python 설치" "running"
if install_python; then
    if [[ "${STEP_STATUS["python"]}" == "skipped" ]]; then
        print_step 4 "Python 설치 (이미 설치됨: ${STEP_VERSION["python"]})" "skipped"
    else
        print_step 4 "Python 설치 (${STEP_VERSION["python"]})" "completed"
    fi
else
    print_step 4 "Python 설치" "failed"
    if ! ask_continue_or_abort "Python 설치"; then
        print_summary_table
        log_message "INFO" "=== 사용자 요청으로 스크립트 중단 ==="
        exit 1
    fi
fi

# --- Step 5: tmux 3.3+ 설치 ---
print_step 5 "tmux 설치" "running"
if install_tmux; then
    if [[ "${STEP_STATUS["tmux"]}" == "skipped" ]]; then
        print_step 5 "tmux 설치 (이미 설치됨: ${STEP_VERSION["tmux"]})" "skipped"
    else
        print_step 5 "tmux 설치 (${STEP_VERSION["tmux"]})" "completed"
    fi
else
    print_step 5 "tmux 설치" "failed"
    if ! ask_continue_or_abort "tmux 설치"; then
        print_summary_table
        log_message "INFO" "=== 사용자 요청으로 스크립트 중단 ==="
        exit 1
    fi
fi

# --- Step 6: uv 설치 ---
print_step 6 "uv 설치" "running"
if install_uv; then
    if [[ "${STEP_STATUS["uv"]}" == "skipped" ]]; then
        print_step 6 "uv 설치 (이미 설치됨: ${STEP_VERSION["uv"]})" "skipped"
    else
        print_step 6 "uv 설치 (${STEP_VERSION["uv"]})" "completed"
    fi
else
    print_step 6 "uv 설치" "failed"
    if ! ask_continue_or_abort "uv 설치"; then
        print_summary_table
        log_message "INFO" "=== 사용자 요청으로 스크립트 중단 ==="
        exit 1
    fi
fi

# --- Step 7: CAO 설치 ---
print_step 7 "CAO 설치" "running"
if install_cao; then
    if [[ "${STEP_STATUS["cao"]}" == "skipped" ]]; then
        print_step 7 "CAO 설치 (이미 설치됨: ${STEP_VERSION["cao"]})" "skipped"
    else
        print_step 7 "CAO 설치 (${STEP_VERSION["cao"]})" "completed"
    fi
else
    print_step 7 "CAO 설치" "failed"
    if ! ask_continue_or_abort "CAO 설치"; then
        print_summary_table
        log_message "INFO" "=== 사용자 요청으로 스크립트 중단 ==="
        exit 1
    fi
fi

# --- Step 8: Kiro CLI 설치 ---
print_step 8 "Kiro CLI 설치" "running"
if install_kiro_cli; then
    if [[ "${STEP_STATUS["kiro-cli"]}" == "skipped" ]]; then
        print_step 8 "Kiro CLI 설치 (이미 설치됨: ${STEP_VERSION["kiro-cli"]})" "skipped"
    else
        print_step 8 "Kiro CLI 설치 (${STEP_VERSION["kiro-cli"]})" "completed"
    fi
else
    print_step 8 "Kiro CLI 설치" "failed"
    if ! ask_continue_or_abort "Kiro CLI 설치"; then
        print_summary_table
        log_message "INFO" "=== 사용자 요청으로 스크립트 중단 ==="
        exit 1
    fi
fi

# --- 요약 출력 및 환경 검증 ---
print_summary_table

run_verification
verification_result=$?

if [[ ${verification_result} -ne 0 ]]; then
    log_message "WARN" "일부 항목이 검증에 실패했습니다. 위의 안내를 참조해 주세요."
fi

log_message "INFO" "=== CAO WSL 환경 설정 스크립트 완료 ==="
log_message "INFO" "로그 파일: ${LOG_FILE}"
