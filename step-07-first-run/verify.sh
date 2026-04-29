#!/bin/bash
# Step 07: 첫 실행 검증 스크립트
# CAO 서버 실행 상태와 에이전트 세션 존재 여부를 확인한다
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

# 1. CAO 서버 프로세스 실행 확인
if pgrep -f "cao-server" >/dev/null 2>&1; then
    print_pass "cao-server 프로세스" "CAO 서버 실행 중"
else
    print_fail "cao-server 프로세스" "CAO 서버가 실행 중이 아닙니다 (cao-server & 로 시작하세요)"
fi

# 2. tmux 세션 존재 여부 확인
if command -v tmux &>/dev/null; then
    SESSION_COUNT=$(tmux list-sessions 2>/dev/null | wc -l)
    if [ "$SESSION_COUNT" -gt 0 ]; then
        print_pass "tmux 세션" "에이전트 세션 존재 (${SESSION_COUNT}개)"
    else
        print_fail "tmux 세션" "활성 tmux 세션이 없습니다 (cao launch code_supervisor --provider kiro 로 에이전트를 실행하세요)"
    fi
else
    print_fail "tmux 세션" "tmux가 설치되어 있지 않습니다 (step-03-tmux 참조)"
fi

# 결과 요약
echo "---"
echo "결과: ${PASS_COUNT}/${TOTAL} 항목 통과"

if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
else
    exit 0
fi
