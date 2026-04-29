# CLI Agent Orchestrator(CAO) 설치 및 사용 가이드

WSL(Ubuntu) 환경에서 [CLI Agent Orchestrator(CAO)](https://github.com/awslabs/cli-agent-orchestrator)를 설치하고, 4에이전트 하네스 패턴으로 멀티 에이전트 오케스트레이션을 실습할 수 있는 단계별 가이드입니다.

> CAO는 tmux + libtmux 기반으로 동작하므로 Linux/WSL 환경이 필수입니다. Windows 네이티브(PowerShell/cmd)에서는 사용할 수 없습니다.

## 사전 요구사항

- WSL 2 + Ubuntu 설치 완료
- 인터넷 연결
- 디스크 공간 5GB 이상

## 빠른 시작

WSL Ubuntu 터미널에서 원클릭 스크립트로 전체 환경을 설치합니다:

```bash
# 전체 의존성 한 번에 설치 (Python, tmux, uv, CAO, Kiro CLI)
bash scripts/setup-wsl.sh

# 설치 확인
bash scripts/verify-all.sh
```

이미 설치된 항목은 자동으로 건너뜁니다.

## 단계별 가이드

각 단계를 직접 따라하며 학습하고 싶다면 순서대로 진행하세요.

| 단계 | 이름 | 설명 | 소요 시간 |
| --- | --- | --- | --- |
| [step-01](step-01-wsl-setup/README.md) | WSL 환경 확인 | WSL 확인 및 기본 패키지 설정 | 5분 |
| [step-02](step-02-python/README.md) | Python 설치 | Python 3.10+ | 5분 |
| [step-03](step-03-tmux/README.md) | tmux 설치 | tmux 3.3+ (CAO 공식 스크립트) | 5분 |
| [step-04](step-04-uv/README.md) | uv 설치 | uv 패키지 관리자 | 5분 |
| [step-05](step-05-cao/README.md) | CAO 설치 | CLI Agent Orchestrator + 에이전트 프로필 | 5분 |
| [step-06](step-06-kiro-cli/README.md) | Kiro CLI 설정 | Kiro CLI 설치 및 프로바이더 설정 | 10분 |
| [step-07](step-07-first-run/README.md) | 첫 실행 | CAO 서버 시작 및 에이전트 실행 | 10분 |
| [step-08](step-08-orchestration/README.md) | 오케스트레이션 모드 | Handoff, Assign, Send Message 실습 | 20분 |
| [step-09](step-09-multi-agent-project/README.md) | 멀티 에이전트 하네스 | 4에이전트 하네스 패턴 협업 실습 | 30분 |
| [step-10](step-10-troubleshooting/README.md) | 트러블슈팅 | 통합 검증 및 문제 해결 | 필요 시 |

> 총 예상 소요 시간: 약 1시간 40분 (트러블슈팅 제외)

CAO의 전체 CLI 레퍼런스, 오케스트레이션 패턴, Flow 시스템, 크로스 프로바이더 설정 등 상세 내용은 [CAO 상세 사용 가이드](docs/cao-usage-guide.md)를 참고하세요. tmux가 처음이라면 [tmux 완전 가이드](docs/tmux-guide.md)부터 읽어보세요.

## 프로젝트 구조

```text
cli-agent-orchestrator-guide/
├── README.md                          # 이 파일
├── docs/
│   ├── cao-usage-guide.md             # CAO 상세 사용 가이드
│   └── tmux-guide.md                  # Windows(WSL)에서 tmux 완전 가이드
├── scripts/
│   ├── setup-wsl.sh                   # 원클릭 환경 설치 스크립트
│   └── verify-all.sh                  # 통합 환경 검증 스크립트
├── step-01-wsl-setup/                 # WSL 환경 확인
├── step-02-python/                    # Python 설치
├── step-03-tmux/                      # tmux 설치
├── step-04-uv/                        # uv 설치
├── step-05-cao/                       # CAO 설치
├── step-06-kiro-cli/                  # Kiro CLI 설정
├── step-07-first-run/                 # 첫 실행
├── step-08-orchestration/             # 오케스트레이션 모드 실습
│   └── examples/                      # 모드별 실습 예제
├── step-09-multi-agent-project/       # 4에이전트 하네스 실습
│   ├── profiles/                      # 에이전트 프로필 (supervisor, developer, reviewer, tester)
│   └── sample-project/                # 샘플 프로젝트
└── step-10-troubleshooting/           # 트러블슈팅
```

## 왜 CAO인가?

### 단일 에이전트의 한계

AI 코딩 에이전트 하나로 모든 작업을 처리하면 다음과 같은 문제가 생깁니다:

| 문제 | 설명 |
| --- | --- |
| 컨텍스트 윈도우 포화 | 코드 작성, 리뷰, 테스트를 한 세션에서 하면 대화가 길어지면서 초기 맥락을 잃음 |
| 역할 충돌 | "코드를 짜면서 동시에 객관적으로 리뷰하라"는 요구는 품질 저하로 이어짐 |
| 순차 처리 병목 | 모듈 A, B, C를 개발할 때 하나씩 순서대로 처리 → 시간 낭비 |
| 자기 검증의 맹점 | 자기가 짠 코드를 자기가 리뷰하면 같은 실수를 반복 |

### 스크립트로 직접 구현하면?

tmux + bash 스크립트로 멀티 에이전트를 직접 구현할 수도 있지만, 실제로 해보면 다음을 전부 만들어야 합니다:

- 에이전트별 tmux 세션 생성/종료 관리
- 각 CLI 도구(Kiro, Claude Code, Codex 등)마다 다른 출력 파싱 및 상태 감지
- 에이전트 간 메시지 전달 큐 (수신자가 바쁠 때 대기 처리)
- 동기/비동기 작업 패턴 구현
- 에러 복구 및 타임아웃 처리
- 프로바이더별 초기화 로직 차이 대응

이 인프라 코드만 수백~수천 줄이 되고, 프로바이더가 업데이트될 때마다 유지보수해야 합니다.

### CAO가 해결하는 것

CAO는 위의 인프라를 모두 내장하고, 사용자는 에이전트 프로필(마크다운 파일)만 작성하면 됩니다:

- **역할 분리** — supervisor/developer/reviewer/tester가 각자 독립 tmux 세션에서 자기 역할에 집중
- **병렬 처리** — `assign()`으로 여러 에이전트가 동시 작업, 완료 시 결과 자동 수집
- **품질 루프** — 코드 작성 → 리뷰 → 테스트의 자동화된 피드백 사이클
- **하네스 패턴** — supervisor가 중앙에서 handoff/assign/send_message를 조합하여 워크플로우 조율
- **크로스 프로바이더** — Kiro CLI로 supervisor를 돌리면서 Claude Code로 개발, Codex로 리뷰하는 식의 혼합 구성
- **선언적 설정** — 에이전트 역할을 마크다운 프로필로 정의하므로 코드 없이 워크플로우 변경 가능
- **자동 상태 관리** — 에이전트의 IDLE/PROCESSING/COMPLETED 상태를 자동 감지하고 메시지 큐잉 처리

## 용어집

| 용어 | 설명 |
| --- | --- |
| **CAO** | CLI Agent Orchestrator. tmux에서 여러 AI 에이전트 세션을 관리하는 오케스트레이션 시스템 |
| **WSL** | Windows Subsystem for Linux. Windows에서 Linux 환경을 실행하는 호환 계층 |
| **tmux** | 터미널 멀티플렉서. CAO가 에이전트 세션 관리에 사용 |
| **uv** | 고속 Python 패키지 관리자. CAO 설치에 사용 |
| **Kiro CLI** | AWS AI 코딩 에이전트 CLI. CAO의 기본 프로바이더 |
| **에이전트 프로필** | 에이전트의 역할과 행동을 정의하는 마크다운 파일 (YAML frontmatter + 시스템 프롬프트) |
| **하네스 패턴** | supervisor가 중앙에서 assign/handoff/send_message를 조합하여 워크플로우를 조율하는 방식 |
| **Handoff** | 동기식 작업 전달. 완료를 기다림 |
| **Assign** | 비동기식 작업 할당. 즉시 반환 |
| **Send Message** | 에이전트 간 직접 메시지 전송 |
