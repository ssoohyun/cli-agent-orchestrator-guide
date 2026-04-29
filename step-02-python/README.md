# Step 02: Python 설치

## 목표

WSL Ubuntu 환경에 Python 3.10 이상을 설치하여 CAO(CLI Agent Orchestrator)의 Python 의존성을 충족한다.

## 예상 소요 시간

5분

## 사전 조건

- [Step 01: WSL 환경 사전 준비](../step-01-wsl-setup/README.md) 완료
- WSL Ubuntu 터미널 접속 가능

## 설치 절차

### 1. 현재 Python 버전 확인

Ubuntu 터미널에서 다음 명령어를 실행하여 Python이 이미 설치되어 있는지 확인한다:

```bash
python3 --version
```

Python이 설치되어 있다면 다음과 같은 출력이 나타난다:

```text
Python 3.12.3
```

> 버전이 3.10 이상이면 [4. pip 설치 확인](#4-pip-설치-확인)으로 건너뛴다.

### 2. Python 3.10+ 설치

Ubuntu 22.04 이상에는 Python 3.10+가 기본 포함되어 있다. 설치되어 있지 않거나 버전이 낮은 경우 다음 명령어를 실행한다:

```bash
sudo apt update
sudo apt install -y python3 python3-pip python3-venv
```

> **참고:** Ubuntu 20.04를 사용하는 경우 deadsnakes PPA를 추가하여 최신 Python을 설치할 수 있다:
>
> ```bash
> sudo add-apt-repository ppa:deadsnakes/ppa -y
> sudo apt update
> sudo apt install -y python3.12 python3.12-venv python3.12-dev
> ```

### 3. Python 버전 재확인

설치 후 버전을 다시 확인한다:

```bash
python3 --version
```

예상 출력:

```text
Python 3.12.3
```

> 버전 번호는 설치 시점에 따라 다를 수 있으나, 3.10 이상이면 된다.

### 4. pip 설치 확인

pip(Python 패키지 관리자)가 함께 설치되었는지 확인한다:

```bash
pip3 --version
```

예상 출력:

```text
pip 24.0 from /usr/lib/python3/dist-packages/pip (python 3.12)
```

pip가 설치되어 있지 않다면 다음 명령어로 설치한다:

```bash
sudo apt install -y python3-pip
```

## 예상 결과

- `python3 --version` 실행 시 Python 3.10 이상의 버전 정보가 출력된다
- `pip3 --version` 실행 시 pip 버전 정보가 출력된다

## 검증

Ubuntu 터미널에서 검증 스크립트를 실행한다:

```bash
bash verify.sh
```

예상 출력:

```text
[PASS] Python 설치 - Python 3.12.3
[PASS] Python 버전 - 3.12.3 (최소 3.10 이상)
[PASS] pip 설치 - pip 24.0
---
결과: 3/3 항목 통과
```

## 문제 해결

### "python3: command not found" 오류

Python이 설치되어 있지 않다. 다음 명령어로 설치한다:

```bash
sudo apt update
sudo apt install -y python3 python3-pip python3-venv
```

### Python 버전이 3.10 미만인 경우

Ubuntu 20.04 이하를 사용 중일 수 있다. deadsnakes PPA를 통해 최신 Python을 설치한다:

```bash
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt update
sudo apt install -y python3.12 python3.12-venv python3.12-dev
```

설치 후 기본 python3 명령어를 업데이트한다:

```bash
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1
```

### "pip3: command not found" 오류

pip를 별도로 설치한다:

```bash
sudo apt install -y python3-pip
```

또는 다음 명령어로 설치할 수 있다:

```bash
python3 -m ensurepip --upgrade
```

## 다음 단계

Python 설치가 완료되었다면 [Step 03: tmux 설치](../step-03-tmux/README.md)로 진행한다.
