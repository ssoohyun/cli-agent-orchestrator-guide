# Step 10: 통합 검증 및 트러블슈팅

## 목표

전체 설치 환경을 한 번에 검증하고, 자주 발생하는 문제에 대한 해결 방법을 제공한다.

## 예상 소요 시간

5~10분 (검증), 문제 해결 시 추가 시간 소요

## 사전 조건

- Step 01 ~ Step 09까지의 가이드를 진행한 상태
- WSL 터미널 접속 가능

## 통합 환경 검증

### verify-all.sh 실행

프로젝트 루트에서 통합 검증 스크립트를 실행한다:

```bash
bash scripts/verify-all.sh
```

### 예상 출력 (모든 항목 통과 시)

```text
╔══════════════════════════════════════════════╗
║        CAO 환경 검증 결과                      ║
╠══════════════════════════════════════════════╣
║ [PASS] WSL 2          - 버전 2.0.9           ║
║ [PASS] Ubuntu         - 22.04 LTS            ║
║ [PASS] Python         - 3.12.3               ║
║ [PASS] tmux           - 3.4                  ║
║ [PASS] uv             - 0.5.1                ║
║ [PASS] CAO            - 설치됨                ║
║ [PASS] Kiro CLI       - 설치됨                ║
╠══════════════════════════════════════════════╣
║ 결과: 7/7 통과                                ║
╚══════════════════════════════════════════════╝
```

### 실패 항목이 있는 경우

실패한 항목에 대해 해당 가이드 단계로 안내하는 메시지가 출력된다:

```text
[FAIL] tmux - 버전 3.2a (최소 3.3 필요)
  → step-03-tmux/README.md를 참조하여 tmux를 업그레이드하세요.
```

각 실패 항목의 안내에 따라 해당 단계의 가이드를 다시 진행한다.

---

## 트러블슈팅 가이드

### WSL 관련 문제

#### 네트워크 문제 (DNS 설정)

**증상:** `apt update`나 `curl` 실행 시 네트워크 연결 실패

```text
Temporary failure resolving 'archive.ubuntu.com'
```

**해결 방법:**

```bash
# DNS 수동 설정
sudo rm /etc/resolv.conf
sudo bash -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'
sudo bash -c 'echo "nameserver 8.8.4.4" >> /etc/resolv.conf'

# 자동 덮어쓰기 방지
sudo bash -c 'echo "[network]" > /etc/wsl.conf'
sudo bash -c 'echo "generateResolvConf = false" >> /etc/wsl.conf'
```

설정 후 WSL 터미널을 닫고 다시 열어 확인한다:

```bash
ping -c 3 google.com
```

#### 권한 문제

**증상:** 파일 권한 문제로 스크립트 실행 불가

```text
bash: ./verify.sh: Permission denied
```

**해결 방법:**

```bash
chmod +x verify.sh
```

#### PATH 충돌 문제

**증상:** WSL에서 Windows PATH가 포함되어 명령어 충돌 발생

**해결 방법:**

```bash
sudo bash -c 'echo "[interop]" >> /etc/wsl.conf'
sudo bash -c 'echo "appendWindowsPath = false" >> /etc/wsl.conf'
```

WSL 터미널을 닫고 다시 열면 적용된다.

---

### Python 관련 문제

#### 버전 충돌

**증상:** `python3 --version`이 3.10 미만을 표시하거나 여러 Python 버전이 혼재

```text
Python 3.8.10
```

**해결 방법:**

1. deadsnakes PPA를 추가하고 Python 3.12를 설치한다:

```bash
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt update
sudo apt install python3.12 python3.12-venv python3.12-dev -y
```

2. 기본 python3를 변경한다:

```bash
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1
sudo update-alternatives --config python3
```

3. 버전을 확인한다:

```bash
python3 --version
```

#### venv 문제

**증상:** `python3 -m venv` 실행 시 오류 발생

```text
Error: Command '['/path/to/venv/bin/python3', '-m', 'ensurepip', ...]' returned non-zero exit status 1.
```

**해결 방법:**

```bash
sudo apt install python3-venv python3-pip -y
```

특정 Python 버전의 venv 패키지가 필요한 경우:

```bash
sudo apt install python3.12-venv -y
```

---

### tmux 관련 문제

#### 빌드 의존성 누락

**증상:** CAO 공식 tmux 설치 스크립트 실행 시 빌드 오류

```text
configure: error: "libevent not found"
```

또는:

```text
configure: error: "curses not found"
```

**해결 방법:**

빌드에 필요한 의존성을 수동으로 설치한다:

```bash
sudo apt install -y build-essential libevent-dev libncurses5-dev libncursesw5-dev bison pkg-config
```

이후 tmux 설치 스크립트를 다시 실행한다:

```bash
bash <(curl -s https://raw.githubusercontent.com/awslabs/cli-agent-orchestrator/refs/heads/main/tmux-install.sh)
```

#### 버전 호환성

**증상:** `tmux -V` 출력이 3.3 미만

```text
tmux 3.2a
```

**해결 방법:**

기존 tmux를 제거하고 CAO 공식 스크립트로 재설치한다:

```bash
sudo apt remove tmux -y
bash <(curl -s https://raw.githubusercontent.com/awslabs/cli-agent-orchestrator/refs/heads/main/tmux-install.sh)
```

설치 후 새 터미널을 열거나 셸을 재시작한다:

```bash
exec $SHELL
tmux -V
```

**증상:** tmux 세션 내에서 한글이 깨짐

**해결 방법:**

로케일 설정을 확인하고 UTF-8을 설정한다:

```bash
sudo apt install locales -y
sudo locale-gen ko_KR.UTF-8
export LANG=ko_KR.UTF-8
```

`~/.bashrc`에 영구 적용:

```bash
echo 'export LANG=ko_KR.UTF-8' >> ~/.bashrc
source ~/.bashrc
```

---

### uv 관련 문제

#### PATH 미설정

**증상:** `uv --version` 실행 시 명령어를 찾을 수 없음

```text
uv: command not found
```

**해결 방법:**

1. uv 설치 경로를 확인한다:

```bash
ls ~/.local/bin/uv
```

2. PATH에 추가한다:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

3. 또는 `~/.cargo/bin`에 설치된 경우:

```bash
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

4. 설치를 확인한다:

```bash
uv --version
```

#### 셸 재시작 필요

**증상:** uv 설치 직후 명령어가 인식되지 않음

**해결 방법:**

uv 설치 스크립트 실행 후 셸을 재시작해야 PATH가 적용된다:

```bash
# 방법 1: 셸 재시작
exec $SHELL

# 방법 2: 새 터미널 열기
# WSL 터미널을 닫고 다시 연다

# 방법 3: 수동으로 PATH 로드
source ~/.bashrc
```

---

### CAO 관련 문제

#### 서버 포트 충돌

**증상:** `cao-server` 실행 시 포트가 이미 사용 중이라는 오류

```text
Address already in use
```

또는 CAO 서버가 시작되지 않음

**해결 방법:**

1. 사용 중인 포트를 확인한다:

```bash
lsof -i :8000
```

2. 해당 프로세스를 종료한다:

```bash
kill -9 <PID>
```

3. 이전 CAO 서버 프로세스가 남아있는 경우 모두 종료한다:

```bash
cao shutdown --all
pkill -f cao-server
```

4. CAO 서버를 다시 시작한다:

```bash
cao-server
```

#### 에이전트 시작 실패

**증상:** `cao launch` 명령어 실행 시 에이전트가 시작되지 않음

```text
Error: Failed to launch agent
```

**해결 방법:**

1. CAO 서버가 실행 중인지 확인한다:

```bash
cao status
```

2. CAO 서버가 실행 중이 아니라면 먼저 시작한다:

```bash
cao-server &
```

3. 에이전트 프로필이 설치되어 있는지 확인한다:

```bash
cao profile list
```

4. 프로필이 없으면 설치한다:

```bash
cao profile install
```

5. tmux가 정상 동작하는지 확인한다:

```bash
tmux new-session -d -s test-session
tmux list-sessions
tmux kill-session -t test-session
```

6. 에이전트 프로바이더(Kiro CLI)가 설정되어 있는지 확인한다:

```bash
which kiro-cli
```

#### 프로필 설치 실패

**증상:** `cao profile install` 실행 시 오류

**해결 방법:**

1. 인터넷 연결을 확인한다:

```bash
ping -c 3 github.com
```

2. CAO를 최신 버전으로 업그레이드한다:

```bash
uv tool install git+https://github.com/awslabs/cli-agent-orchestrator.git@main --upgrade
```

3. 프로필 설치를 다시 시도한다:

```bash
cao profile install
```

#### tmux 세션 오류

**증상:** CAO 에이전트 세션이 비정상적으로 남아있거나 접속 불가

```text
sessions should be nested with care, unset $TMUX to force
```

**해결 방법:**

1. 모든 CAO 에이전트를 종료한다:

```bash
cao shutdown --all
```

2. 남아있는 tmux 세션을 확인하고 정리한다:

```bash
tmux list-sessions
tmux kill-server
```

3. tmux 서버를 완전히 종료한 후 다시 시작한다:

```bash
tmux kill-server
cao-server &
cao launch code_supervisor --provider kiro-cli
```

> tmux 세션 내부에서 다른 tmux 세션에 접속하려면 `$TMUX` 환경변수를 해제해야 한다:
>
> ```bash
> unset TMUX
> tmux attach -t <세션이름>
> ```

---

### Kiro CLI 관련 문제

#### 인증 실패

**증상:** Kiro CLI 실행 시 인증 오류

```text
Error: Authentication failed
```

또는:

```text
Error: Invalid credentials
```

**해결 방법:**

1. Kiro CLI 인증을 다시 수행한다:

```bash
kiro-cli auth login
```

2. 브라우저에서 인증 페이지가 열리면 로그인을 완료한다.

3. WSL에서 브라우저가 열리지 않는 경우, 출력된 URL을 Windows 브라우저에 직접 붙여넣는다.

4. 인증 상태를 확인한다:

```bash
kiro-cli auth status
```

#### 토큰 만료

**증상:** 이전에 정상 동작하던 Kiro CLI가 갑자기 인증 오류 발생

**해결 방법:**

1. 기존 인증 정보를 초기화한다:

```bash
kiro-cli auth logout
```

2. 다시 로그인한다:

```bash
kiro-cli auth login
```

3. 토큰이 정상적으로 갱신되었는지 확인한다:

```bash
kiro-cli auth status
```

> 토큰은 일정 시간이 지나면 자동으로 만료된다. 장시간 사용하지 않은 후에는 다시 로그인이 필요할 수 있다.

#### Kiro CLI 설치 실패

**증상:** `.deb` 패키지 설치 시 오류

```text
dpkg: error processing package kiro-cli
```

**해결 방법:**

1. 의존성 문제를 해결한다:

```bash
sudo apt --fix-broken install -y
```

2. 패키지를 다시 설치한다:

```bash
sudo dpkg -i kiro-cli_*.deb
```

3. 또는 Linux zip 방식으로 설치한다:

```bash
# .deb 대신 zip 파일을 다운로드하여 수동 설치
unzip kiro-cli-linux-x64.zip -d ~/.local/bin/
chmod +x ~/.local/bin/kiro-cli
```

---

## 일반적인 디버깅 팁

### 로그 확인

원클릭 스크립트 실행 시 생성된 로그 파일을 확인한다:

```bash
# WSL 설정 스크립트 로그
cat setup-wsl.log
```

### 환경 변수 확인

```bash
# PATH 확인
echo $PATH

# 특정 명령어 위치 확인
which python3
which tmux
which uv
which cao
which kiro-cli
```

### WSL 완전 재시작

문제가 지속되면 WSL 터미널을 닫고 다시 열어본다. 그래도 안 되면 검증 스크립트를 실행한다:

```bash
bash scripts/verify-all.sh
```

---

## 검증

이 단계의 검증 스크립트를 실행한다:

```bash
bash step-10-troubleshooting/verify.sh
```

이 스크립트는 `scripts/verify-all.sh`를 호출하여 전체 환경을 검증한다.

## 다음 단계

모든 검증이 통과되면 CAO 환경 설정이 완료된 것이다. [Step 08: 오케스트레이션 모드 실습](../step-08-orchestration/README.md)과 [Step 09: 멀티 에이전트 협업 프로젝트](../step-09-multi-agent-project/README.md)를 통해 실습을 진행한다.
