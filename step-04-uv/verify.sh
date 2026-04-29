#!/bin/bash
# Step 04: uv 설치 검증 스크립트
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

# 1. uv 설치 확인
if command -v uv &>/dev/null; then
    UV_VERSION=$(uv --version 2>&1)
    print_pass "uv 설치" "$UV_VERSION"
else
    print_fail "uv 설치" "uv 명령어를 찾을 수 없습니다. 설치 방법:
  → curl -LsSf https://astral.sh/uv/install.sh | sh
  → source \$HOME/.local/bin/env"
fi

# 2. PATH에 uv 설치 경로 포함 여부 확인
UV_LOCAL_BIN="$HOME/.local/bin"
UV_CARGO_BIN="$HOME/.cargo/bin"

if echo "$PATH" | tr ':' '\n' | grep -qE "^($UV_LOCAL_BIN|$UV_CARGO_BIN)$"; then
    print_pass "PATH 설정" "$HOME/.local/bin 또는 $HOME/.cargo/bin이 PATH에 포함됨"
else
    # uv 명령어가 동작하면 PATH에 다른 경로로 포함된 것일 수 있음
    if command -v uv &>/dev/null; then
        UV_PATH=$(which uv 2>/dev/null)
        print_pass "PATH 설정" "uv 경로: $UV_PATH"
    else
        print_fail "PATH 설정" "$HOME/.local/bin 또는 $HOME/.cargo/bin이 PATH에 포함되어 있지 않습니다. 해결 방법:
  → source \$HOME/.local/bin/env
  → 또는 셸 재시작: exec \$SHELL"
    fi
fi

# 결과 요약
echo "---"
echo "결과: ${PASS_COUNT}/${TOTAL} 항목 통과"

if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
else
    exit 0
fi
