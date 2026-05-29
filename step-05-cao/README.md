# Step 05: CAO 설치

## 목표

CLI Agent Orchestrator(CAO)를 설치하고 기본 에이전트 프로필을 설정하여 멀티 에이전트 오케스트레이션을 시작할 수 있도록 한다. CAO는 tmux 터미널에서 여러 AI 에이전트 세션을 관리하는 경량 오케스트레이션 시스템이다.

## 예상 소요 시간

5분

## 사전 조건

- [Step 04: uv 설치](../step-04-uv/README.md) 완료
- WSL Ubuntu 터미널 접속 가능
- 인터넷 연결 가능

## 설치 절차

### 1. 현재 CAO 설치 여부 확인

먼저 CAO가 이미 설치되어 있는지 확인한다:

```bash
cao --help
```

CAO가 설치되어 있다면 사용 가능한 명령어 목록이 출력된다. 출력이 나타나면 이미 설치된 것이므로 [3. 기본 에이전트 프로필 설치](#3-기본-에이전트-프로필-설치)로 건너뛴다.

### 2. CAO 설치

uv tool install 명령어를 사용하여 CAO를 설치한다:

```bash
uv tool install git+https://github.com/awslabs/cli-agent-orchestrator.git@main --upgrade
```

설치가 완료되면 다음과 유사한 메시지가 출력된다:

```text
Resolved X packages in Xs
Installed X packages in Xs
 + cli-agent-orchestrator==X.X.X
Installed 2 executables: cao, cao-server
```

### 3. 설치 확인

CAO가 정상적으로 설치되었는지 확인한다:

```bash
cao --help
```

예상 출력:

```text
usage: cao [-h] {launch,shutdown,list,send-message,...} ...

CLI Agent Orchestrator - Multi-agent orchestration system
...
```

`cao --version` 명령어로도 확인할 수 있다:

```bash
cao --version
```

> CAO 버전에 따라 `--version` 옵션이 지원되지 않을 수 있다. 이 경우 `cao --help`로 설치를 확인한다.

### 4. 기본 에이전트 프로필 설치

CAO에서 사용할 기본 에이전트 프로필을 설치한다. 이 명령어는 `code_supervisor`, `developer`, `reviewer` 세 가지 프로필을 설치한다:

```bash
cao install-profiles
```

> CAO 버전에 따라 `install-profiles`가 지원되지 않을 수 있다. 이 경우 각각 설치해주면 된다.

```bash
cao install code_supervisor
cao install developer
cao install reviewer
```

예상 출력:

```text
Installing default agent profiles...
  - code_supervisor
  - developer
  - reviewer
Profiles installed successfully.
```

> 프로필은 `~/.cao/profiles/` 디렉토리에 설치된다.

설치된 프로필을 확인한다:

```bash
ls ~/.cao/profiles/
```

예상 출력:

```text
code_supervisor.yaml  developer.yaml  reviewer.yaml
```

## 예상 결과

- `cao --help` 실행 시 CAO 명령어 도움말이 출력된다
- `cao install-profiles` 실행 후 `~/.cao/profiles/` 디렉토리에 `code_supervisor`, `developer`, `reviewer` 프로필이 생성된다

## 검증

Ubuntu 터미널에서 검증 스크립트를 실행한다:

```bash
bash verify.sh
```

예상 출력:

```text
[PASS] cao 명령어 - cao 명령어 사용 가능
[PASS] cao --help - cao 도움말 정상 출력
[PASS] code_supervisor 프로필 - 설치됨
[PASS] developer 프로필 - 설치됨
[PASS] reviewer 프로필 - 설치됨
---
결과: 5/5 항목 통과
```

## 문제 해결

### "cao: command not found" 오류

CAO가 설치되었지만 PATH에 포함되지 않은 경우 발생한다. 다음 방법을 순서대로 시도한다:

1. uv tool 설치 경로를 PATH에 추가한다:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

2. 셸 설정 파일에 영구적으로 추가한다:

```bash
# bash 사용자
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# zsh 사용자
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

3. 위 방법이 동작하지 않으면 CAO를 재설치한다:

```bash
uv tool install git+https://github.com/awslabs/cli-agent-orchestrator.git@main --upgrade --force
```

### uv tool install 실패

uv가 정상적으로 설치되어 있는지 먼저 확인한다:

```bash
uv --version
```

uv가 동작하지 않으면 [Step 04: uv 설치](../step-04-uv/README.md)를 다시 진행한다.

네트워크 문제로 GitHub 저장소에 접근할 수 없는 경우:

```bash
# GitHub 연결 확인
ping -c 2 github.com

# DNS 확인
nslookup github.com
```

### 에이전트 프로필 설치 실패

`cao install-profiles` 명령어가 실패하는 경우:

```bash
# 프로필 디렉토리를 수동으로 생성
mkdir -p ~/.cao/profiles

# CAO를 재설치하고 프로필을 다시 설치
uv tool install git+https://github.com/awslabs/cli-agent-orchestrator.git@main --upgrade --force
cao install-profiles
```

### 프로필 디렉토리 위치 확인

프로필이 다른 경로에 설치되었을 수 있다. 다음 명령어로 확인한다:

```bash
# 일반적인 프로필 경로
ls ~/.cao/profiles/ 2>/dev/null
ls ~/.config/cao/profiles/ 2>/dev/null
```

## 다음 단계

CAO 설치가 완료되었다면 [Step 06: Kiro CLI 설정](../step-06-kiro-cli/README.md)으로 진행한다.
