# Step 01: WSL 환경 확인 및 기본 패키지 설정

## 목표

WSL Ubuntu 환경이 정상 동작하는지 확인하고, CAO 설치에 필요한 기본 패키지를 설정한다.

## 예상 소요 시간

5분

## 사전 조건

- WSL 2 + Ubuntu가 설치되어 있어야 한다
- 인터넷 연결

## 설치 절차

### 1. WSL 환경 확인

Ubuntu 터미널에서 WSL 환경인지 확인한다:

```bash
cat /proc/version
```

출력에 `microsoft` 또는 `WSL`이 포함되어 있으면 정상이다:

```text
Linux version 5.15.x.x-microsoft-standard-WSL2 ...
```

### 2. Ubuntu 버전 확인

```bash
lsb_release -a
```

예상 출력:

```text
Distributor ID: Ubuntu
Description:    Ubuntu 22.04.x LTS
Release:        22.04
```

> Ubuntu 20.04 이상이면 된다.

### 3. 기본 패키지 업데이트 및 설치

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git build-essential
```

## 예상 결과

- `/proc/version`에 `microsoft` 또는 `WSL` 키워드가 포함된다
- `lsb_release -a`로 Ubuntu 20.04 이상이 확인된다
- `curl`, `wget`, `git`, `build-essential`이 설치되어 있다

## 검증

```bash
bash verify.sh
```

예상 출력:

```text
[PASS] WSL 환경 - WSL 2 환경에서 실행 중
[PASS] Ubuntu 버전 - Ubuntu 22.04.x LTS
[PASS] curl - 설치됨
[PASS] wget - 설치됨
[PASS] git - 설치됨
[PASS] build-essential - 설치됨
---
결과: 6/6 항목 통과
```

## 문제 해결

### "apt update" 실행 시 네트워크 오류

WSL DNS 설정 문제일 수 있다:

```bash
sudo sh -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'
```

### Ubuntu 버전이 20.04 미만인 경우

최신 Ubuntu 배포판을 설치하는 것을 권장한다.

## 다음 단계

[Step 02: Python 설치](../step-02-python/README.md)로 진행한다.
