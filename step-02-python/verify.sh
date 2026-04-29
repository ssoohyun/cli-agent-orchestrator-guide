#!/bin/bash
# Step 02: Python 환경 검증 스크립트
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

# 1. Python 설치 확인
if command -v python3 &>/dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    print_pass "Python 설치" "Python $PYTHON_VERSION"
else
    print_fail "Python 설치" "python3 명령어를 찾을 수 없습니다 (sudo apt install -y python3)"
fi

# 2. Python 버전 확인 (3.10 이상)
if command -v python3 &>/dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    MAJOR=$(echo "$PYTHON_VERSION" | cut -d. -f1)
    MINOR=$(echo "$PYTHON_VERSION" | cut -d. -f2)

    if [ "$MAJOR" -ge 3 ] 2>/dev/null && [ "$MINOR" -ge 10 ] 2>/dev/null; then
        print_pass "Python 버전" "$PYTHON_VERSION (최소 3.10 이상)"
    else
        print_fail "Python 버전" "$PYTHON_VERSION (최소 3.10 필요). 업그레이드 방법:
  → sudo add-apt-repository ppa:deadsnakes/ppa -y
  → sudo apt update
  → sudo apt install -y python3.12 python3.12-venv python3.12-dev
  → sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1"
    fi
else
    print_fail "Python 버전" "Python이 설치되어 있지 않아 버전을 확인할 수 없습니다"
fi

# 3. pip 설치 확인
if command -v pip3 &>/dev/null; then
    PIP_VERSION=$(pip3 --version 2>&1 | awk '{print $2}')
    print_pass "pip 설치" "pip $PIP_VERSION"
else
    print_fail "pip 설치" "pip3 명령어를 찾을 수 없습니다 (sudo apt install -y python3-pip)"
fi

# 결과 요약
echo "---"
echo "결과: ${PASS_COUNT}/${TOTAL} 항목 통과"

if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
else
    exit 0
fi
