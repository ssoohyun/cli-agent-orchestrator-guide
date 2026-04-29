# Step 07: 첫 실행

## 목표

CAO 서버를 시작하고 첫 번째 에이전트를 실행하여 오케스트레이션 시스템이 정상적으로 동작하는 것을 확인한다. MCP 서버 시작, 에이전트 실행, tmux 세션 관리, 종료까지의 전체 흐름을 실습한다.

## 예상 소요 시간

10분

## 사전 조건

- [Step 06: Kiro CLI 설정](../step-06-kiro-cli/README.md) 완료
- WSL Ubuntu 터미널 접속 가능
- Kiro CLI 인증 완료 (`kiro-cli auth status`로 확인)

## 설치 절차

### 1. CAO MCP 서버 시작

CAO 오케스트레이션 시스템을 사용하려면 먼저 MCP 서버를 시작해야 한다. `cao-server` 명령어를 백그라운드로 실행한다:

```bash
cao-server &
```

예상 출력:

```text
CAO MCP Server starting on port 8000...
Server is ready.
```

서버가 정상적으로 시작되었는지 확인한다:

```bash
curl -s http://localhost:8000/health 2>/dev/null || echo "서버 응답 확인 중..."
```

> `cao-server`는 에이전트 간 통신을 중개하는 MCP(Model Context Protocol) 서버이다. 서버가 실행 중이어야 에이전트를 시작하고 오케스트레이션을 수행할 수 있다.

### 2. code_supervisor 에이전트 실행

MCP 서버가 실행 중인 상태에서 `cao launch` 명령어로 첫 번째 에이전트를 실행한다:

```bash
cao launch code_supervisor --provider kiro
```

예상 출력:

```text
Launching agent: code_supervisor
Provider: kiro
Session: code_supervisor_XXXXX
Agent launched successfully.
```

> `code_supervisor`는 다른 에이전트에게 작업을 지시하고 결과를 관리하는 감독자 역할의 에이전트이다. `--provider kiro` 옵션은 Kiro CLI를 에이전트 프로바이더로 사용하도록 지정한다.

### 3. tmux 세션 목록 확인

에이전트가 실행되면 tmux 세션이 생성된다. 현재 활성화된 세션 목록을 확인한다:

```bash
tmux list-sessions
```

예상 출력:

```text
code_supervisor_XXXXX: 1 windows (created Mon Jan 15 10:30:00 2024)
```

세션 이름은 `에이전트이름_고유ID` 형식으로 생성된다.

### 4. tmux 세션 접속

에이전트의 작업 상태를 실시간으로 확인하려면 해당 tmux 세션에 접속한다:

```bash
tmux attach -t code_supervisor_XXXXX
```

> `code_supervisor_XXXXX` 부분은 `tmux list-sessions`에서 확인한 실제 세션 이름으로 대체한다.

세션에 접속하면 에이전트의 터미널 출력을 실시간으로 볼 수 있다.

tmux 세션에서 빠져나오려면 (세션을 종료하지 않고 분리):

```text
Ctrl+B 를 누른 후 D 키를 누른다
```

> tmux 기본 조작법은 [Step 03: tmux 설치](../step-03-tmux/README.md)를 참고한다.

### 5. 에이전트 및 서버 종료

실습이 끝나면 모든 에이전트와 서버를 종료한다. `cao shutdown --all` 명령어로 실행 중인 모든 에이전트를 한 번에 종료할 수 있다:

```bash
cao shutdown --all
```

예상 출력:

```text
Shutting down all agents...
  - code_supervisor_XXXXX: stopped
All agents shut down successfully.
```

백그라운드에서 실행 중인 CAO 서버도 종료한다:

```bash
# cao-server 프로세스 종료
pkill -f cao-server
```

모든 프로세스가 종료되었는지 확인한다:

```bash
# 남아있는 cao 관련 프로세스 확인
ps aux | grep cao
```

### 6. 포트 충돌 해결

CAO 서버 시작 시 포트가 이미 사용 중이라는 오류가 발생할 수 있다:

```text
Error: Address already in use (port 8000)
```

이 경우 다음 방법으로 해결한다:

```bash
# 포트 8000을 사용 중인 프로세스 확인
lsof -i :8000

# 해당 프로세스 종료
kill $(lsof -t -i :8000)

# 또는 강제 종료
kill -9 $(lsof -t -i :8000)
```

프로세스를 종료한 후 다시 서버를 시작한다:

```bash
cao-server &
```

다른 포트를 사용해야 하는 경우:

```bash
cao-server --port 8001 &
```

> 포트를 변경한 경우 에이전트 실행 시에도 해당 포트를 지정해야 할 수 있다.

## 예상 결과

- `cao-server &` 실행 시 MCP 서버가 백그라운드에서 시작된다
- `cao launch code_supervisor --provider kiro` 실행 시 에이전트가 tmux 세션에서 시작된다
- `tmux list-sessions` 실행 시 에이전트 세션이 목록에 표시된다
- `tmux attach -t <session>` 실행 시 에이전트 터미널에 접속할 수 있다
- `cao shutdown --all` 실행 시 모든 에이전트가 종료된다

## 검증

Ubuntu 터미널에서 검증 스크립트를 실행한다:

```bash
bash verify.sh
```

> 검증 스크립트는 CAO 서버와 에이전트가 실행 중인 상태에서 실행해야 정확한 결과를 얻을 수 있다. 서버를 시작하고 에이전트를 실행한 후 검증 스크립트를 실행한다.

예상 출력:

```text
[PASS] cao-server 프로세스 - CAO 서버 실행 중
[PASS] tmux 세션 - 에이전트 세션 존재 (1개)
---
결과: 2/2 항목 통과
```

## 문제 해결

### "cao-server: command not found" 오류

CAO가 정상적으로 설치되어 있는지 확인한다:

```bash
which cao-server
cao --help
```

명령어를 찾을 수 없는 경우 PATH 설정을 확인한다:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

CAO를 재설치해야 하는 경우 [Step 05: CAO 설치](../step-05-cao/README.md)를 다시 진행한다.

### 에이전트 실행 실패

`cao launch` 명령어 실행 시 에이전트가 시작되지 않는 경우:

1. MCP 서버가 실행 중인지 확인한다:

```bash
ps aux | grep cao-server
```

1. 에이전트 프로필이 설치되어 있는지 확인한다:

```bash
ls ~/.cao/profiles/code_supervisor.yaml 2>/dev/null || echo "프로필 미설치"
```

1. Kiro CLI 인증 상태를 확인한다:

```bash
kiro-cli auth status
```

프로필이 없는 경우 다시 설치한다:

```bash
cao install-profiles
```

### tmux 세션이 보이지 않는 경우

에이전트를 실행했지만 `tmux list-sessions`에 세션이 표시되지 않는 경우:

```bash
# tmux 서버가 실행 중인지 확인
tmux has-session 2>/dev/null && echo "tmux 서버 실행 중" || echo "tmux 서버 미실행"

# tmux 버전 확인 (3.3 이상 필요)
tmux -V
```

tmux 버전이 3.3 미만인 경우 [Step 03: tmux 설치](../step-03-tmux/README.md)를 다시 진행한다.

### CAO 서버 연결 실패

에이전트가 MCP 서버에 연결하지 못하는 경우:

```bash
# 서버 포트 확인
lsof -i :8000

# 서버 재시작
pkill -f cao-server
sleep 2
cao-server &
```

## 다음 단계

첫 실행이 성공적으로 완료되었다면 [Step 08: 오케스트레이션 모드 실습](../step-08-orchestration/README.md)으로 진행한다.
