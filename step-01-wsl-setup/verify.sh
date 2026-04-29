#!/bin/bash
# Step 01: WSL 환경 사전 준비 검증 스크립트
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

# 1. WSL 환경 확인
if grep -qi "microsoft\|wsl" /proc/version 2>/dev/null; then
    print_pass "WSL 환경" "WSL 2 환경에서 실행 중"
else
    print_fail "WSL 환경" "WSL 환경이 아닙니다. WSL에서 이 스크립트를 실행하세요."
fi

# 2. Ubuntu 버전 확인
if command -v lsb_release &>/dev/null; then
    UBUNTU_DESC=$(lsb_release -d -s 2>/dev/null)
    UBUNTU_VER=$(lsb_release -r -s 2>/dev/null)
    if [ -n "$UBUNTU_VER" ]; then
        MAJOR_VER=$(echo "$UBUNTU_VER" | cut -d. -f1)
        if [ "$MAJOR_VER" -ge 20 ] 2>/dev/null; then
            print_pass "Ubuntu 버전" "$UBUNTU_DESC"
        else
            print_fail "Ubuntu 버전" "$UBUNTU_DESC (20.04 이상 권장)"
        fi
    else
        print_fail "Ubuntu 버전" "버전 정보를 확인할 수 없습니다"
    fi
else
    print_fail "Ubuntu 버전" "lsb_release 명령어를 찾을 수 없습니다 (sudo apt install lsb-release)"
fi

# 3. 기본 패키지 확인
PACKAGES=("curl" "wget" "git" "build-essential")

for pkg in "${PACKAGES[@]}"; do
    if [ "$pkg" = "build-essential" ]; then
        if dpkg -s build-essential &>/dev/null; then
            print_pass "$pkg" "설치됨"
        else
            print_fail "$pkg" "미설치 (sudo apt install -y build-essential)"
        fi
    else
        if command -v "$pkg" &>/dev/null; then
            print_pass "$pkg" "설치됨"
        else
            print_fail "$pkg" "미설치 (sudo apt install -y $pkg)"
        fi
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
