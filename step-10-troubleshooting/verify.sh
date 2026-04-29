#!/bin/bash
# Step 10: 통합 환경 검증 - scripts/verify-all.sh 래퍼 스크립트
# 이 스크립트는 프로젝트 루트의 scripts/verify-all.sh를 호출하여
# 모든 의존성(WSL, Python, tmux, uv, CAO, Kiro CLI)을 한 번에 검증합니다.
# 종료 코드: verify-all.sh의 종료 코드를 그대로 전달합니다.

# 프로젝트 루트 디렉토리 결정 (이 스크립트 위치 기준 두 단계 상위)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

VERIFY_ALL="$PROJECT_ROOT/scripts/verify-all.sh"

if [ -f "$VERIFY_ALL" ]; then
    bash "$VERIFY_ALL"
    exit $?
else
    echo "============================================"
    echo " scripts/verify-all.sh가 아직 존재하지 않습니다."
    echo " Task 11 완료 후 사용할 수 있습니다."
    echo "============================================"
    echo ""
    echo "통합 검증 스크립트는 다음 작업에서 생성됩니다:"
    echo "  → Task 11: 통합 검증 스크립트 생성 (scripts/verify-all.sh)"
    echo ""
    echo "개별 단계 검증은 각 step 디렉토리의 verify.sh를 실행하세요:"
    echo "  bash step-01-wsl-setup/verify.sh"
    echo "  bash step-02-python/verify.sh"
    echo "  bash step-03-tmux/verify.sh"
    echo "  ..."
    exit 1
fi
