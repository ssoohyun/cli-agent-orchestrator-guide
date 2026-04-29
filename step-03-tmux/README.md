# Step 03: tmux 설치

## 목표

tmux 3.3 이상을 설치하여 CAO(CLI Agent Orchestrator)가 멀티 에이전트 세션을 관리할 수 있도록 한다. CAO는 tmux를 사용하여 여러 에이전트를 독립된 터미널 세션에서 동시에 실행하고 관리한다.

## 예상 소요 시간

5분

## 사전 조건

- [Step 02: Python 설치](../step-02-python/README.md) 완료
- WSL Ubuntu 터미널 접속 가능
- 인터넷 연결 가능

## 설치 절차

### 1. 현재 tmux 버전 확인

먼저 tmux가 이미 설치되어 있는지 확인한다:

```bash
tmux -V
```

tmux가 설치되어 있다면 다음과 같은 출력이 나타난다:

```text
tmux 3.4
```

> 버전이 3.3 이상이면 [3. tmux 기본 조작법](#3-tmux-기본-조작법)으로 건너뛴다.

### 2. CAO 공식 tmux 설치 스크립트 실행

CAO에서 제공하는 공식 tmux 설치 스크립트를 사용하여 tmux 3.3 이상을 설치한다:

```bash
bash <(curl -s https://raw.githubusercontent.com/awslabs/cli-agent-orchestrator/refs/heads/main/tmux-install.sh)
```

설치가 완료되면 버전을 확인한다:

```bash
tmux -V
```

예상 출력:

```text
tmux 3.4
```

> 버전 번호는 설치 시점에 따라 다를 수 있으나, 3.3 이상이면 된다.

### 3. tmux 기본 조작법

CAO가 tmux 세션을 자동으로 관리하지만, 기본 조작법을 알아두면 디버깅과 모니터링에 유용하다.

#### 세션 생성

새로운 tmux 세션을 생성한다:

```bash
tmux new -s mysession
```

`mysession`은 세션 이름이다. 원하는 이름으로 변경할 수 있다.

#### 세션 디태치 (분리)

현재 세션에서 빠져나오되, 세션은 백그라운드에서 계속 실행된다:

```text
Ctrl+B 를 누른 후 D 키를 누른다
```

> `Ctrl+B`는 tmux의 기본 프리픽스 키이다. `Ctrl+B`를 먼저 누르고 손을 뗀 후 `D`를 누른다.

#### 세션 목록 확인

실행 중인 tmux 세션 목록을 확인한다:

```bash
tmux list-sessions
```

또는 줄여서:

```bash
tmux ls
```

#### 세션 어태치 (재접속)

백그라운드에서 실행 중인 세션에 다시 접속한다:

```bash
tmux attach -t mysession
```

#### 세션 종료

세션 내에서 다음 명령어를 입력하여 세션을 종료한다:

```bash
exit
```

또는 모든 세션을 한 번에 종료한다:

```bash
tmux kill-server
```

## 예상 결과

- `tmux -V` 실행 시 tmux 3.3 이상의 버전 정보가 출력된다
- `tmux new -s test` 명령어로 새 세션을 생성할 수 있다
- `Ctrl+B` → `D`로 세션에서 디태치할 수 있다

## 검증

Ubuntu 터미널에서 검증 스크립트를 실행한다:

```bash
bash verify.sh
```

예상 출력:

```text
[PASS] tmux 설치 - tmux 3.4
[PASS] tmux 버전 - 3.4 (최소 3.3 이상)
---
결과: 2/2 항목 통과
```

## 문제 해결

### CAO 공식 스크립트 실행 실패

네트워크 문제 또는 권한 문제로 공식 스크립트가 실패할 수 있다. 이 경우 소스에서 직접 빌드하여 설치한다:

```bash
# 빌드 의존성 설치
sudo apt update
sudo apt install -y libevent-dev ncurses-dev build-essential bison pkg-config

# tmux 소스 다운로드 및 빌드
cd /tmp
curl -LO https://github.com/tmux/tmux/releases/download/3.4/tmux-3.4.tar.gz
tar -xzf tmux-3.4.tar.gz
cd tmux-3.4
./configure && make
sudo make install
cd ~
```

빌드 완료 후 버전을 확인한다:

```bash
tmux -V
```

### "tmux: command not found" 오류

tmux가 설치되어 있지 않다. 위의 [2. CAO 공식 tmux 설치 스크립트 실행](#2-cao-공식-tmux-설치-스크립트-실행)을 따라 설치한다.

### tmux 버전이 3.3 미만인 경우

Ubuntu 기본 저장소의 tmux 버전이 낮을 수 있다. 기존 tmux를 제거하고 CAO 공식 스크립트로 재설치한다:

```bash
sudo apt remove -y tmux
bash <(curl -s https://raw.githubusercontent.com/awslabs/cli-agent-orchestrator/refs/heads/main/tmux-install.sh)
```

### 빌드 시 "libevent not found" 오류

빌드 의존성이 누락되었다. 다음 명령어로 설치한다:

```bash
sudo apt install -y libevent-dev ncurses-dev build-essential bison pkg-config
```

## 다음 단계

tmux 설치가 완료되었다면 [Step 04: uv 설치](../step-04-uv/README.md)로 진행한다.
