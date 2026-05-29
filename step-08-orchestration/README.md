# Step 08: 오케스트레이션 모드 실습

## 목표

CAO의 세 가지 오케스트레이션 모드(Handoff, Assign, Send Message)를 이해하고 실습한다. 각 모드의 동작 방식과 차이점을 파악하여 에이전트 간 협업 시나리오에 적합한 모드를 선택할 수 있도록 한다.

## 예상 소요 시간

20분

## 사전 조건

- [Step 07: 첫 실행](../step-07-first-run/README.md) 완료
- CAO MCP 서버 실행 중 (`cao-server &`)
- 에이전트 프로필 설치 완료 (`code_supervisor`, `developer`, `reviewer`)

서버가 실행 중인지 확인한다:

```bash
ps aux | grep cao-server
```

서버가 실행 중이 아니라면 먼저 시작한다:

```bash
cao-server &
```

## 오케스트레이션 모드 개요

CAO는 에이전트 간 작업을 조율하는 세 가지 오케스트레이션 모드를 제공한다. 각 모드는 작업의 성격과 에이전트 간 관계에 따라 선택한다.

| 모드 | 동작 방식 | 작업 흐름 | 적합한 상황 |
| --- | --- | --- | --- |
| **Handoff** | 동기식 | A → B (A는 B 완료를 기다림) | 순차적 작업, 결과 의존성이 있는 경우 |
| **Assign** | 비동기식 | A → B (A는 즉시 다음 작업 진행) | 병렬 작업, 독립적인 작업 분배 |
| **Send Message** | 직접 통신 | A ↔ B (에이전트 간 메시지 교환) | 정보 공유, 상태 확인, 피드백 전달 |

## Handoff 모드 (동기식 작업 전달)

### 개념

Handoff 모드는 한 에이전트가 작업을 다른 에이전트에게 **전달하고 완료를 기다리는** 동기식 오케스트레이션 방식이다. 작업을 전달한 에이전트는 대상 에이전트가 작업을 완료할 때까지 대기하며, 완료 결과를 받은 후 다음 작업을 진행한다.

**동작 흐름:**

```text
[에이전트 A] --작업 전달--> [에이전트 B]
[에이전트 A] <--대기중--
[에이전트 B] --작업 수행 중--
[에이전트 B] --완료 결과--> [에이전트 A]
[에이전트 A] --다음 작업 진행-->
```

**사용 시나리오:**

- supervisor가 developer에게 코드 작성을 요청하고, 완료된 코드를 받아 reviewer에게 전달하는 경우
- 이전 작업의 결과가 다음 작업의 입력으로 필요한 순차적 워크플로우

### 실행 방법

먼저 에이전트를 실행한다:

```bash
cao launch code_supervisor --provider kiro
cao launch developer --provider kiro
```

> `Error: Missing option '--agents'.` 에러가 발생하면 다음 명령어로 실행한다.

기본 provider는 kiro_cli이므로 명시 안하면 kiro_cli로 실행된다.  
클로드로 하려면 `--provider claude_code`라고 붙여주면 된다.

```bash
cao launch --agents code_supervisor
cao launch --agents developer
```

Handoff 모드로 작업을 전달한다:

```bash
cao orchestrate handoff \
  --from code_supervisor \
  --to developer \
  --task "hello.py 파일에 'Hello, World!'를 출력하는 Python 스크립트를 작성하세요"
```

> 자세한 실습 예제는 [examples/handoff-example.md](examples/handoff-example.md)를 참고한다.

### 결과 확인

Handoff 작업의 진행 상태와 결과를 확인하는 방법:

```bash
# developer 에이전트의 tmux 세션에서 작업 진행 상태 확인
tmux list-sessions
tmux attach -t developer_XXXXX
```

세션에서 빠져나오려면 `Ctrl+B` → `D`를 누른다.

## Assign 모드 (비동기 작업 생성)

### 개념

Assign 모드는 에이전트가 작업을 생성하고 **즉시 다음 작업으로 진행하는** 비동기식 오케스트레이션 방식이다. 작업을 할당한 에이전트는 대상 에이전트의 완료를 기다리지 않으므로, 여러 에이전트에게 동시에 작업을 분배할 수 있다.

**동작 흐름:**

```text
[에이전트 A] --작업 할당--> [에이전트 B]
[에이전트 A] --즉시 다음 작업-->
[에이전트 A] --작업 할당--> [에이전트 C]
[에이전트 A] --즉시 다음 작업-->
                              [에이전트 B] --독립적으로 작업 수행-->
                              [에이전트 C] --독립적으로 작업 수행-->
```

**사용 시나리오:**

- supervisor가 여러 developer에게 서로 다른 모듈 개발을 동시에 할당하는 경우
- 작업 간 의존성이 없어 병렬 처리가 가능한 경우

### 실행 방법

에이전트를 실행한다 (이미 실행 중이면 건너뛴다):

```bash
cao launch code_supervisor --provider kiro
cao launch developer --provider kiro
cao launch reviewer --provider kiro
```

Assign 모드로 작업을 할당한다:

```bash
cao orchestrate assign \
  --from code_supervisor \
  --to developer \
  --task "utils.py 파일에 두 수를 더하는 add 함수를 작성하세요"

cao orchestrate assign \
  --from code_supervisor \
  --to reviewer \
  --task "기존 코드의 코딩 스타일을 검토하세요"
```

> 자세한 실습 예제는 [examples/assign-example.md](examples/assign-example.md)를 참고한다.

### 결과 확인

Assign 작업은 비동기로 실행되므로 각 에이전트의 세션을 개별적으로 확인한다:

```bash
# 모든 에이전트 세션 목록 확인
tmux list-sessions

# 각 에이전트 세션에 접속하여 작업 상태 확인
tmux attach -t developer_XXXXX
# Ctrl+B → D 로 빠져나온 후
tmux attach -t reviewer_XXXXX
```

## Send Message 모드 (에이전트 직접 통신)

### 개념

Send Message 모드는 에이전트 간에 **직접 메시지를 전송하는** 통신 방식이다. 작업 전달이 아닌 정보 공유, 상태 확인, 피드백 전달 등에 사용한다. 메시지를 받은 에이전트는 내용을 참고하여 현재 작업에 반영할 수 있다.

**동작 흐름:**

```text
[에이전트 A] --메시지 전송--> [에이전트 B]
[에이전트 B] --메시지 수신 및 참고-->
[에이전트 B] --응답 메시지--> [에이전트 A] (선택적)
```

**사용 시나리오:**

- reviewer가 developer에게 코드 리뷰 피드백을 전달하는 경우
- supervisor가 에이전트에게 작업 우선순위 변경을 알리는 경우
- 에이전트 간 진행 상황을 공유하는 경우

### 실행 방법

에이전트를 실행한다 (이미 실행 중이면 건너뛴다):

```bash
cao launch developer --provider kiro
cao launch reviewer --provider kiro
```

Send Message 모드로 메시지를 전송한다:

```bash
cao orchestrate send-message \
  --from reviewer \
  --to developer \
  --message "add 함수에 타입 힌트를 추가하고, docstring을 작성해 주세요"
```

> 자세한 실습 예제는 [examples/send-message-example.md](examples/send-message-example.md)를 참고한다.

### 결과 확인

메시지 수신 여부를 대상 에이전트의 세션에서 확인한다:

```bash
# developer 세션에 접속하여 메시지 수신 확인
tmux attach -t developer_XXXXX
```

세션에서 빠져나오려면 `Ctrl+B` → `D`를 누른다.

## 실행 결과 확인 방법

오케스트레이션 모드 실습 후 결과를 확인하는 두 가지 방법을 정리한다.

### tmux 세션 확인

tmux 세션을 통해 각 에이전트의 실시간 작업 상태를 확인할 수 있다.

```bash
# 1. 활성 세션 목록 확인
tmux list-sessions
```

예상 출력:

```text
code_supervisor_abc12: 1 windows (created Mon Jan 15 10:30:00 2024)
developer_def34: 1 windows (created Mon Jan 15 10:30:05 2024)
reviewer_ghi56: 1 windows (created Mon Jan 15 10:30:10 2024)
```

```bash
# 2. 특정 에이전트 세션에 접속
tmux attach -t developer_def34

# 3. 세션 간 전환 (tmux 내부에서)
# Ctrl+B → S 를 누르면 세션 목록이 표시되고 선택하여 전환할 수 있다

# 4. 세션에서 빠져나오기 (세션 유지)
# Ctrl+B → D
```

> 여러 에이전트의 작업을 동시에 모니터링하려면 별도의 터미널 창을 열어 각각 다른 세션에 접속하면 편리하다.

### 출력 로그 확인

에이전트의 작업 로그를 통해 오케스트레이션 결과를 확인할 수 있다.

```bash
# CAO 로그 디렉토리 확인
ls ~/.cao/logs/

# 최근 로그 파일 내용 확인
cat ~/.cao/logs/latest.log

# 특정 에이전트의 로그만 필터링
grep "developer" ~/.cao/logs/latest.log

# 실시간 로그 모니터링
tail -f ~/.cao/logs/latest.log
```

> 로그 파일 경로는 CAO 설정에 따라 다를 수 있다. `cao --help`로 로그 관련 옵션을 확인한다.

## 검증

Ubuntu 터미널에서 검증 스크립트를 실행한다:

```bash
bash verify.sh
```

> 검증 스크립트는 CAO 서버와 에이전트 프로필이 준비된 상태에서 실행해야 한다.

예상 출력:

```text
[PASS] cao-server 프로세스 - CAO 서버 실행 중
[PASS] 에이전트 프로필 - code_supervisor 설치됨
[PASS] 에이전트 프로필 - developer 설치됨
[PASS] 에이전트 프로필 - reviewer 설치됨
---
결과: 4/4 항목 통과
```

## 문제 해결

### "cao orchestrate: command not found" 오류

CAO가 정상적으로 설치되어 있는지 확인한다:

```bash
cao --help
```

`orchestrate` 서브커맨드가 목록에 없는 경우 CAO를 최신 버전으로 업그레이드한다:

```bash
uv tool install git+https://github.com/awslabs/cli-agent-orchestrator.git@main --upgrade
```

### 에이전트 간 통신 실패

오케스트레이션 명령어 실행 시 에이전트 간 통신이 실패하는 경우:

1. MCP 서버가 실행 중인지 확인한다:

```bash
ps aux | grep cao-server
```

2. 대상 에이전트가 실행 중인지 확인한다:

```bash
tmux list-sessions
```

3. 서버와 에이전트를 재시작한다:

```bash
cao shutdown --all
pkill -f cao-server
sleep 2
cao-server &
cao launch code_supervisor --provider kiro
cao launch developer --provider kiro
```

### Handoff 모드에서 응답이 없는 경우

대상 에이전트가 작업을 처리하지 못하고 있을 수 있다:

```bash
# 대상 에이전트 세션에 접속하여 상태 확인
tmux attach -t developer_XXXXX
```

에이전트가 오류 상태인 경우 해당 에이전트를 재시작한다:

```bash
cao shutdown developer_XXXXX
cao launch developer --provider kiro
```

### tmux 세션이 너무 많은 경우

실습 중 세션이 누적된 경우 모든 에이전트를 종료하고 다시 시작한다:

```bash
# 모든 에이전트 종료
cao shutdown --all

# 남아있는 tmux 세션 정리
tmux kill-server

# 서버 재시작 후 필요한 에이전트만 실행
cao-server &
cao launch code_supervisor --provider kiro
cao launch developer --provider kiro
```

## 다음 단계

세 가지 오케스트레이션 모드를 이해했다면 [Step 09: 멀티 에이전트 협업 프로젝트](../step-09-multi-agent-project/README.md)로 진행하여 실제 프로젝트에서 여러 에이전트가 협업하는 워크플로우를 실습한다.
