# Send Message 모드 실습 예제

## 모드 개요

Send Message 모드는 에이전트 간 **직접 메시지를 전송하는** 통신 방식이다. 작업 전달이 아닌 정보 공유, 상태 확인, 피드백 전달 등에 사용한다. 메시지를 받은 에이전트는 내용을 참고하여 현재 작업에 반영할 수 있다.

## 시나리오 설명

reviewer가 developer에게 코드 개선 피드백을 전달하는 시나리오를 실습한다. reviewer가 코드 리뷰 결과를 developer에게 메시지로 보내면, developer는 피드백을 참고하여 코드를 개선한다.

**워크플로우:**

```text
[reviewer] --"타입 힌트 추가, 에러 처리 개선 피드백"--> [developer]
[developer] --메시지 수신, 피드백 내용 확인-->
[developer] --피드백 반영하여 코드 수정-->
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

developer와 reviewer 에이전트를 실행한다:

```bash
cao launch developer --provider kiro
cao launch reviewer --provider kiro
```

에이전트가 정상적으로 실행되었는지 확인한다:

```bash
tmux list-sessions
```

예상 출력:

```text
developer_def34: 1 windows (created ...)
reviewer_ghi56: 1 windows (created ...)
```

### 3. 사전 코드 준비 (선택)

피드백 시나리오를 더 현실적으로 만들기 위해, developer가 이전에 작성한 코드가 있다고 가정한다. 다음 파일이 프로젝트에 존재하는 상태에서 실습하면 효과적이다:

```python
# utils.py (developer가 이전에 작성한 코드)
def add(a, b):
    return a + b

def divide(a, b):
    return a / b
```

## 실행 명령어

Send Message 모드로 reviewer에서 developer에게 코드 개선 피드백을 전달한다:

```bash
cao orchestrate send-message \
  --from reviewer \
  --to developer \
  --message "utils.py 코드 리뷰 결과입니다. 다음 사항을 개선해 주세요: 1) 모든 함수에 타입 힌트를 추가하세요 (예: def add(a: float, b: float) -> float). 2) divide 함수에 0으로 나누는 경우의 에러 처리를 추가하세요. 3) 각 함수에 docstring을 작성하세요."
```

## 예상 결과

### reviewer 에이전트

- developer에게 메시지를 전송한 후 **자신의 작업을 계속 진행**할 수 있다
- 메시지 전송은 작업 할당이 아니므로 developer의 응답을 기다리지 않는다

### developer 에이전트

- reviewer로부터 피드백 메시지를 수신한다
- 메시지 내용을 참고하여 `utils.py` 코드를 개선한다
- 타입 힌트 추가, 에러 처리 추가, docstring 작성을 수행한다

### 개선된 파일 예시 (utils.py)

```python
def add(a: float, b: float) -> float:
    """두 수를 더한 결과를 반환한다."""
    return a + b


def divide(a: float, b: float) -> float:
    """두 수를 나눈 결과를 반환한다.

    Args:
        a: 피제수
        b: 제수

    Returns:
        나눗셈 결과

    Raises:
        ZeroDivisionError: b가 0인 경우
    """
    if b == 0:
        raise ZeroDivisionError("0으로 나눌 수 없습니다")
    return a / b
```

## 결과 확인 방법

### tmux 세션으로 확인

developer 에이전트의 세션에 접속하여 메시지 수신 및 코드 수정 과정을 확인한다:

```bash
# developer 세션에 접속
tmux attach -t developer_def34
```

세션 내에서 developer가 피드백을 수신하고 코드를 수정하는 과정을 관찰할 수 있다.

세션에서 빠져나오려면 `Ctrl+B` → `D`를 누른다.

reviewer 세션에서 메시지 전송 기록을 확인한다:

```bash
# reviewer 세션에 접속
tmux attach -t reviewer_ghi56
```

### 수정된 파일 확인

developer가 피드백을 반영하여 수정한 파일을 확인한다:

```bash
cat utils.py
```

타입 힌트, docstring, 에러 처리가 추가되었는지 확인한다.

### 로그 확인

CAO 로그에서 Send Message 작업의 전송 기록을 확인한다:

```bash
grep "send-message" ~/.cao/logs/latest.log
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

> 모든 오케스트레이션 모드 실습을 완료했다면 [Step 09: 멀티 에이전트 협업 프로젝트](../../step-09-multi-agent-project/README.md)로 진행한다.
