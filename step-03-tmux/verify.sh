#!/bin/bash
# Step 03: tmux 설치 검증 스크립트
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

# 1. tmux 설치 확인
if command -v tmux &>/dev/null; then
    TMUX_VERSION_RAW=$(tmux -V 2>&1)
    print_pass "tmux 설치" "$TMUX_VERSION_RAW"
else
    print_fail "tmux 설치" "tmux 명령어를 찾을 수 없습니다. 설치 방법:
  → bash <(curl -s https://raw.githubusercontent.com/awslabs/cli-agent-orchestrator/refs/heads/main/tmux-install.sh)"
fi

# 2. tmux 버전 확인 (3.3 이상)
if command -v tmux &>/dev/null; then
    TMUX_VERSION_RAW=$(tmux -V 2>&1)
    # tmux -V 출력 예: "tmux 3.4" 또는 "tmux 3.3a"
    # 숫자 부분만 추출 (알파벳 접미사 제거)
    TMUX_VERSION=$(echo "$TMUX_VERSION_RAW" | grep -oP '\d+\.\d+')
    MAJOR=$(echo "$TMUX_VERSION" | cut -d. -f1)
    MINOR=$(echo "$TMUX_VERSION" | cut -d. -f2)

    if [ -n "$MAJOR" ] && [ -n "$MINOR" ]; then
        if [ "$MAJOR" -gt 3 ] 2>/dev/null || { [ "$MAJOR" -eq 3 ] 2>/dev/null && [ "$MINOR" -ge 3 ] 2>/dev/null; }; then
            print_pass "tmux 버전" "$TMUX_VERSION (최소 3.3 이상)"
        else
            print_fail "tmux 버전" "$TMUX_VERSION (최소 3.3 필요). 업그레이드 방법:
  → sudo apt remove -y tmux
  → bash <(curl -s https://raw.githubusercontent.com/awslabs/cli-agent-orchestrator/refs/heads/main/tmux-install.sh)"
        fi
    else
        print_fail "tmux 버전" "버전 정보를 파싱할 수 없습니다 ($TMUX_VERSION_RAW)"
    fi
else
    print_fail "tmux 버전" "tmux가 설치되어 있지 않아 버전을 확인할 수 없습니다"
fi

# 결과 요약
echo "---"
echo "결과: ${PASS_COUNT}/${TOTAL} 항목 통과"

if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
else
    exit 0
fi
