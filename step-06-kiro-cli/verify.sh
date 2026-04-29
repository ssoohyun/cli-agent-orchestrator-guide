#!/bin/bash
# Step 06: Kiro CLI 설정 검증 스크립트
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

# 1. kiro-cli 명령어 존재 확인
if command -v kiro-cli &>/dev/null; then
    print_pass "kiro-cli 명령어" "kiro-cli 명령어 사용 가능"
else
    print_fail "kiro-cli 명령어" "kiro-cli 명령어를 찾을 수 없습니다. 설치 방법:
  → curl -fSL -o kiro-cli.deb https://desktop-release.kiro.dev/kiro-cli-latest-amd64.deb
  → sudo dpkg -i kiro-cli.deb"
fi

# 2. kiro-cli --version 동작 확인
KIRO_VERSION=$(kiro-cli --version 2>/dev/null)
if [ $? -eq 0 ] && [ -n "$KIRO_VERSION" ]; then
    print_pass "kiro-cli --version" "버전 정보 정상 출력 ($KIRO_VERSION)"
else
    print_fail "kiro-cli --version" "kiro-cli 버전 확인에 실패했습니다. Kiro CLI를 재설치하세요:
  → curl -fSL -o kiro-cli.deb https://desktop-release.kiro.dev/kiro-cli-latest-amd64.deb
  → sudo dpkg -i kiro-cli.deb"
fi

# 결과 요약
echo "---"
echo "결과: ${PASS_COUNT}/${TOTAL} 항목 통과"

if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
else
    exit 0
fi
