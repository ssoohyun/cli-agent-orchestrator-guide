# Step 04: uv 설치

## 목표

uv 패키지 관리자를 설치하여 CAO(CLI Agent Orchestrator)를 설치할 수 있도록 한다. uv는 Astral에서 개발한 고속 Python 패키지 관리자로, CAO 설치에 `uv tool install` 명령어를 사용한다.

## 예상 소요 시간

5분

## 사전 조건

- [Step 03: tmux 설치](../step-03-tmux/README.md) 완료
- WSL Ubuntu 터미널 접속 가능
- 인터넷 연결 가능

## 설치 절차

### 1. 현재 uv 설치 여부 확인

먼저 uv가 이미 설치되어 있는지 확인한다:

```bash
uv --version
```

uv가 설치되어 있다면 다음과 같은 출력이 나타난다:

```text
uv 0.7.12
```

> 버전이 출력되면 이미 설치된 것이므로 [예상 결과](#예상-결과)로 건너뛴다.

### 2. uv 공식 설치 스크립트 실행

uv 공식 설치 스크립트를 사용하여 설치한다:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

설치 스크립트가 완료되면 다음과 유사한 메시지가 출력된다:

```text
Downloading uv...
Installing to /home/<사용자명>/.local/bin...
Done!
```

### 3. PATH 환경변수 설정

uv 설치 스크립트는 `~/.local/bin`에 바이너리를 설치한다. 현재 셸 세션에서 바로 사용하려면 PATH를 갱신해야 한다:

```bash
source $HOME/.local/bin/env
```

> 이 명령어는 현재 셸 세션에만 적용된다. 새 터미널을 열 때마다 자동으로 적용되도록 하려면 아래 [셸 설정 파일에 PATH 추가](#셸-설정-파일에-path-추가)를 참고한다.

#### 셸 설정 파일에 PATH 추가

uv 설치 스크립트가 자동으로 셸 설정 파일(`.bashrc`, `.zshrc` 등)에 PATH를 추가하는 경우가 많다. 자동 추가가 되지 않았다면 수동으로 추가한다:

```bash
# bash 사용자
echo 'source $HOME/.local/bin/env' >> ~/.bashrc

# zsh 사용자
echo 'source $HOME/.local/bin/env' >> ~/.zshrc
```

설정 파일을 수정한 후 현재 셸에 적용한다:

```bash
source ~/.bashrc
```

### 4. 설치 확인

uv가 정상적으로 설치되었는지 확인한다:

```bash
uv --version
```

예상 출력:

```text
uv 0.7.12
```

> 버전 번호는 설치 시점에 따라 다를 수 있다.

## 예상 결과

- `uv --version` 실행 시 uv 버전 정보가 출력된다
- `which uv` 실행 시 `~/.local/bin/uv` 또는 `~/.cargo/bin/uv` 경로가 출력된다

## 검증

Ubuntu 터미널에서 검증 스크립트를 실행한다:

```bash
bash verify.sh
```

예상 출력:

```text
[PASS] uv 설치 - uv 0.7.12
[PASS] PATH 설정 - ~/.local/bin 또는 ~/.cargo/bin이 PATH에 포함됨
---
결과: 2/2 항목 통과
```

## 문제 해결

### "uv: command not found" 오류

uv가 설치되었지만 PATH에 포함되지 않은 경우 발생한다. 다음 방법을 순서대로 시도한다:

1. 현재 셸 세션에 PATH를 즉시 적용한다:

```bash
source $HOME/.local/bin/env
```

2. 위 명령어가 동작하지 않으면 셸을 재시작한다:

```bash
exec $SHELL
```

3. 그래도 동작하지 않으면 PATH를 수동으로 설정한다:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### 설치 스크립트 다운로드 실패

네트워크 문제로 설치 스크립트를 다운로드할 수 없는 경우:

```bash
# DNS 확인
ping -c 2 astral.sh

# curl이 설치되어 있는지 확인
which curl

# curl이 없으면 설치
sudo apt install -y curl
```

DNS가 정상이고 curl이 설치되어 있다면 설치 스크립트를 다시 실행한다.

### pip를 사용한 대안 설치

공식 설치 스크립트가 동작하지 않는 경우 pip로 설치할 수 있다:

```bash
pip install uv
```

> pip로 설치한 경우 바이너리 경로가 다를 수 있다. `which uv`로 경로를 확인한다.

## 다음 단계

uv 설치가 완료되었다면 [Step 05: CAO 설치](../step-05-cao/README.md)로 진행한다.
