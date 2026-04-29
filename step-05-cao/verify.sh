#!/bin/bash
# Step 05: CAO 설치 검증 스크립트
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

# --- PATH 보정: .bashrc가 로드되지 않는 환경에서도 동작하도록 ---
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
[[ -d "$HOME/.cargo/bin" ]] && export PATH="$HOME/.cargo/bin:$PATH"
[[ -f "$HOME/.local/bin/env" ]] && source "$HOME/.local/bin/env" 2>/dev/null

# 1. cao 명령어 존재 확인
if command -v cao &>/dev/null; then
    print_pass "cao 명령어" "cao 명령어 사용 가능"
else
    print_fail "cao 명령어" "cao 명령어를 찾을 수 없습니다. 설치 방법:
  → uv tool install git+https://github.com/awslabs/cli-agent-orchestrator.git@main --upgrade
  → export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# 2. cao --help 동작 확인
if cao --help &>/dev/null; then
    print_pass "cao --help" "cao 도움말 정상 출력"
else
    print_fail "cao --help" "cao --help 실행에 실패했습니다. CAO를 재설치하세요:
  → uv tool install git+https://github.com/awslabs/cli-agent-orchestrator.git@main --upgrade --force"
fi

# 3. 에이전트 프로필 설치 확인
# CAO는 여러 경로에 프로필을 저장할 수 있음
AGENT_CONTEXT_DIR="$HOME/.aws/cli-agent-orchestrator/agent-context"
AGENT_STORE_DIR="$HOME/.aws/cli-agent-orchestrator/agent-store"
PROFILE_DIR="$HOME/.cao/profiles"
ALT_PROFILE_DIR="$HOME/.config/cao/profiles"

PROFILES=("code_supervisor" "developer" "reviewer")

for profile in "${PROFILES[@]}"; do
    found=false
    for dir in "$AGENT_CONTEXT_DIR" "$AGENT_STORE_DIR" "$PROFILE_DIR" "$ALT_PROFILE_DIR"; do
        if [ -d "$dir" ]; then
            if [ -f "$dir/${profile}.md" ] || \
               [ -f "$dir/${profile}.yaml" ] || \
               [ -f "$dir/${profile}.yml" ]; then
                found=true
                break
            fi
        fi
    done

    if [ "$found" = true ]; then
        print_pass "$profile 프로필" "설치됨"
    else
        print_fail "$profile 프로필" "프로필 파일을 찾을 수 없습니다. 설치 방법:
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
