# Handoff 모드 실습 예제

## 모드 개요

Handoff 모드는 **동기식 작업 전달** 방식이다. 한 에이전트가 다른 에이전트에게 작업을 전달하고, 해당 작업이 완료될 때까지 **대기**한 후 결과를 받아 다음 작업을 진행한다. 작업 간 의존성이 있는 순차적 워크플로우에 적합하다.

## 시나리오 설명

supervisor가 developer에게 Python 함수 작성을 요청하고, developer가 작업을 완료할 때까지 기다린 후 결과를 확인하는 시나리오를 실습한다.

**워크플로우:**

```text
[code_supervisor] --"fibonacci 함수 작성"--> [developer]
[code_supervisor] <--대기 중--
[developer] --fibonacci.py 작성 중--
[developer] --작성 완료, 결과 반환--> [code_supervisor]
[code_supervisor] --결과 확인 후 다음 작업 진행-->
```

## 사전 준비

### 1. CAO MCP 서버 시작

서버가 실행 중이 아니라면 먼저 시작한다:

```bash
cao-server &
```

서버 실행 상태를 확인한다:

```bash
ps aux | grep cao-server
```

### 2. 에이전트 실행

code_supervisor와 developer 에이전트를 실행한다:

```bash
cao launch code_supervisor --provider kiro
cao launch developer --provider kiro
```

에이전트가 정상적으로 실행되었는지 확인한다:

```bash
tmux list-sessions
```

예상 출력:

```text
code_supervisor_abc12: 1 windows (created ...)
developer_def34: 1 windows (created ...)
```

## 실행 명령어

Handoff 모드로 code_supervisor에서 developer에게 작업을 전달한다:

```bash
cao orchestrate handoff \
  --from code_supervisor \
  --to developer \
  --task "fibonacci.py 파일에 피보나치 수열의 n번째 값을 반환하는 fibonacci(n) 함수를 작성하세요. 재귀 방식이 아닌 반복문을 사용하고, n이 음수인 경우 ValueError를 발생시키세요."
```

## 예상 결과

### code_supervisor 에이전트

- 작업을 developer에게 전달한 후 **대기 상태**에 들어간다
- developer가 작업을 완료하면 결과를 수신한다
- 수신한 결과를 바탕으로 다음 작업을 결정할 수 있다

### developer 에이전트

- code_supervisor로부터 작업 지시를 수신한다
- `fibonacci.py` 파일을 생성하고 함수를 작성한다
- 작업 완료 후 결과를 code_supervisor에게 반환한다

### 생성될 파일 예시 (fibonacci.py)

```python
def fibonacci(n):
    """피보나치 수열의 n번째 값을 반환한다."""
    if n < 0:
        raise ValueError("n은 음수가 될 수 없습니다")
    if n <= 1:
        return n
    a, b = 0, 1
    for _ in range(2, n + 1):
        a, b = b, a + b
    return b
```

## 결과 확인 방법

### tmux 세션으로 확인

developer 에이전트의 세션에 접속하여 작업 진행 상태를 확인한다:

```bash
# developer 세션에 접속
tmux attach -t developer_def34
```

세션 내에서 developer가 코드를 작성하는 과정을 실시간으로 관찰할 수 있다.

세션에서 빠져나오려면 `Ctrl+B` → `D`를 누른다.

code_supervisor 세션에서 결과 수신 여부를 확인한다:

```bash
# code_supervisor 세션에 접속
tmux attach -t code_supervisor_abc12
```

### 생성된 파일 확인

developer가 작성한 파일이 존재하는지 확인한다:

```bash
ls -la fibonacci.py
cat fibonacci.py
```

### 로그 확인

CAO 로그에서 Handoff 작업의 전달 및 완료 기록을 확인한다:

```bash
grep "handoff" ~/.cao/logs/latest.log
```

## 정리

실습이 끝나면 에이전트를 종료한다:

```bash
# 모든 에이전트 종료
cao shutdown --all

# 서버 종료 (필요한 경우)
pkill -f cao-server
```

남아있는 tmux 세션이 있는지 확인한다:

```bash
tmux list-sessions
```

> 다음 실습(Assign 모드)을 바로 진행하려면 에이전트를 종료하지 않고 그대로 사용해도 된다.
