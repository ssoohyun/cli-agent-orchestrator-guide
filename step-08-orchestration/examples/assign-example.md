# Assign 모드 실습 예제

## 모드 개요

Assign 모드는 **비동기 작업 생성** 방식이다. 한 에이전트가 다른 에이전트에게 작업을 할당하고, 완료를 기다리지 않고 **즉시 다음 작업으로 진행**한다. 여러 에이전트에게 동시에 독립적인 작업을 분배할 때 적합하다.

## 시나리오 설명

supervisor가 developer에게 코드 작성을, reviewer에게 코드 리뷰를 동시에 할당하는 시나리오를 실습한다. 두 작업은 독립적으로 병렬 수행된다.

**워크플로우:**

```text
[code_supervisor] --"calculator.py 작성"--> [developer]
[code_supervisor] --즉시 다음 명령-->
[code_supervisor] --"코딩 스타일 리뷰"--> [reviewer]
[code_supervisor] --즉시 다음 작업 가능-->

                    [developer] --독립적으로 calculator.py 작성 중-->
                    [reviewer]  --독립적으로 코드 리뷰 수행 중-->
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

code_supervisor, developer, reviewer 세 에이전트를 모두 실행한다:

```bash
cao launch code_supervisor --provider kiro
cao launch developer --provider kiro
cao launch reviewer --provider kiro
```

에이전트가 정상적으로 실행되었는지 확인한다:

```bash
tmux list-sessions
```

예상 출력:

```text
code_supervisor_abc12: 1 windows (created ...)
developer_def34: 1 windows (created ...)
reviewer_ghi56: 1 windows (created ...)
```

## 실행 명령어

Assign 모드로 두 에이전트에게 동시에 작업을 할당한다:

```bash
# developer에게 코드 작성 할당
cao orchestrate assign \
  --from code_supervisor \
  --to developer \
  --task "calculator.py 파일에 사칙연산(add, subtract, multiply, divide) 함수를 작성하세요. divide 함수는 0으로 나누는 경우 ZeroDivisionError를 발생시키세요."

# reviewer에게 코드 리뷰 할당
cao orchestrate assign \
  --from code_supervisor \
  --to reviewer \
  --task "현재 프로젝트의 Python 파일들을 검토하고, PEP 8 스타일 가이드 준수 여부와 docstring 작성 여부를 확인하세요."
```

두 명령어는 각각 즉시 반환되며, developer와 reviewer는 독립적으로 작업을 수행한다.

## 예상 결과

### code_supervisor 에이전트

- 두 작업을 할당한 후 **즉시 다른 작업을 수행할 수 있는 상태**가 된다
- developer와 reviewer의 작업 완료를 기다리지 않는다

### developer 에이전트

- code_supervisor로부터 작업 지시를 수신한다
- `calculator.py` 파일을 생성하고 사칙연산 함수를 작성한다
- reviewer와 독립적으로 작업을 수행한다

### reviewer 에이전트

- code_supervisor로부터 리뷰 지시를 수신한다
- 프로젝트의 Python 파일들을 검토한다
- developer와 독립적으로 작업을 수행한다

### 생성될 파일 예시 (calculator.py)

```python
def add(a, b):
    """두 수를 더한다."""
    return a + b


def subtract(a, b):
    """두 수를 뺀다."""
    return a - b


def multiply(a, b):
    """두 수를 곱한다."""
    return a * b


def divide(a, b):
    """두 수를 나눈다. b가 0이면 ZeroDivisionError를 발생시킨다."""
    if b == 0:
        raise ZeroDivisionError("0으로 나눌 수 없습니다")
    return a / b
```

## 결과 확인 방법

### tmux 세션으로 확인

Assign 모드는 비동기이므로 각 에이전트의 세션을 개별적으로 확인한다:

```bash
# 모든 활성 세션 목록 확인
tmux list-sessions
```

developer 세션에 접속하여 코드 작성 상태를 확인한다:

```bash
tmux attach -t developer_def34
```

세션에서 빠져나오려면 `Ctrl+B` → `D`를 누른다.

reviewer 세션에 접속하여 리뷰 진행 상태를 확인한다:

```bash
tmux attach -t reviewer_ghi56
```

> 여러 터미널 창을 열어 각 에이전트 세션에 동시에 접속하면 병렬 작업 진행을 실시간으로 관찰할 수 있다.

### 생성된 파일 확인

developer가 작성한 파일이 존재하는지 확인한다:

```bash
ls -la calculator.py
cat calculator.py
```

### 로그 확인

CAO 로그에서 Assign 작업의 할당 기록을 확인한다:

```bash
grep "assign" ~/.cao/logs/latest.log
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

> 다음 실습(Send Message 모드)을 바로 진행하려면 에이전트를 종료하지 않고 그대로 사용해도 된다.
