#!/bin/bash
# Step 08: 오케스트레이션 실습 환경 검증 스크립트
# CAO 서버 실행 상태와 에이전트 프로필 설치 여부를 확인한다
# 종료 코드: 0 = 모든 검증 통과, 1 = 하나 이상 실패
# 출력 형식:
#   [PASS] 항목명 - 상세 정보
#   [FAIL] 항목명 - 오류 설명 및 해결 안내
#   ---
#   결과: X/Y 항목 통과

PASS_COUNT=0
FAIL_COUNT=0
TOTAL=0

print_pass() {
    local item="$1"
    local detail="$2"
    echo "[PASS] $item - $detail"
    PASS_COUNT=$((PASS_COUNT + 1))
    TOTAL=$((TOTAL + 1))
}

print_fail() {
    local item="$1"
    local detail="$2"
    echo "[FAIL] $item - $detail"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    TOTAL=$((TOTAL + 1))
}

# --- PATH 보정 ---
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
[[ -d "$HOME/.cargo/bin" ]] && export PATH="$HOME/.cargo/bin:$PATH"
[[ -f "$HOME/.local/bin/env" ]] && source "$HOME/.local/bin/env" 2>/dev/null

# 1. CAO 서버 프로세스 실행 확인
if pgrep -f "cao-server" >/dev/null 2>&1; then
    print_pass "cao-server 프로세스" "CAO 서버 실행 중"
else
    print_fail "cao-server 프로세스" "CAO 서버가 실행 중이 아닙니다 (cao-server & 로 시작하세요)"
fi

# 2. 에이전트 프로필 설치 확인
AGENT_CONTEXT_DIR="$HOME/.aws/cli-agent-orchestrator/agent-context"
AGENT_STORE_DIR="$HOME/.aws/cli-agent-orchestrator/agent-store"
PROFILE_DIR="$HOME/.cao/profiles"
ALT_PROFILE_DIR="$HOME/.config/cao/profiles"

PROFILES=("code_supervisor" "developer" "reviewer")

for profile in "${PROFILES[@]}"; do
    found=false
    for dir in "$AGENT_CONTEXT_DIR" "$AGENT_STORE_DIR" "$PROFILE_DIR" "$ALT_PROFILE_DIR"; do
        if [ -d "$dir" ]; then
            if [ -f "$dir/${profile}.md" ] || [ -f "$dir/${profile}.yaml" ] || [ -f "$dir/${profile}.yml" ]; then
                found=true
                break
            fi
        fi
    done
    if [ "$found" = true ]; then
        print_pass "에이전트 프로필" "${profile} 설치됨"
    else
        print_fail "에이전트 프로필" "${profile} 프로필을 찾을 수 없습니다. 설치 방법:
  → cao install-profiles"
    fi
done

# 결과 요약
echo "---"
echo "결과: ${PASS_COUNT}/${TOTAL} 항목 통과"

if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
else
    exit 0
fi
