# Step 06: Kiro CLI 설정

## 목표

Kiro CLI를 설치하고 CAO의 기본 에이전트 프로바이더로 설정하여, Kiro를 통해 에이전트 작업을 수행할 수 있도록 한다. Kiro CLI는 AWS에서 개발한 AI 코딩 에이전트의 CLI 버전이다.

## 예상 소요 시간

10분

## 사전 조건

- [Step 05: CAO 설치](../step-05-cao/README.md) 완료
- WSL Ubuntu 터미널 접속 가능
- 인터넷 연결 가능

## 설치 절차

### 1. 현재 Kiro CLI 설치 여부 확인

먼저 Kiro CLI가 이미 설치되어 있는지 확인한다:

```bash
kiro-cli --version
```

버전 정보가 출력되면 이미 설치된 것이므로 [4. 인증 설정](#4-인증-설정)으로 건너뛴다.

### 2. Kiro CLI 설치

WSL(Ubuntu) 환경에서는 두 가지 설치 방법 중 하나를 선택한다.

#### 방법 A: .deb 패키지 설치 (권장)

.deb 패키지를 다운로드하여 설치한다:

```bash
# 최신 .deb 패키지 다운로드
curl -fSL -o kiro-cli.deb https://desktop-release.kiro.dev/kiro-cli-latest-amd64.deb

# 패키지 설치
sudo dpkg -i kiro-cli.deb

# 의존성 문제 발생 시 자동 해결
sudo apt-get install -f -y

# 다운로드 파일 정리
rm kiro-cli.deb
```

#### 방법 B: Linux zip 설치

zip 파일을 다운로드하여 수동으로 설치한다:

```bash
# 최신 Linux zip 다운로드
curl -fSL -o kiro-cli.zip https://desktop-release.kiro.dev/kiro-cli-latest-linux-x64.zip

# 압축 해제
unzip kiro-cli.zip -d kiro-cli-extracted

# 실행 파일을 PATH에 포함된 디렉토리로 이동
sudo mv kiro-cli-extracted/kiro-cli /usr/local/bin/kiro-cli
sudo chmod +x /usr/local/bin/kiro-cli

# 다운로드 파일 정리
rm -rf kiro-cli.zip kiro-cli-extracted
```

### 3. 설치 확인

Kiro CLI가 정상적으로 설치되었는지 확인한다:

```bash
kiro-cli --version
```

예상 출력:

```text
kiro-cli/X.X.X
```

### 4. 인증 설정

Kiro CLI를 사용하려면 인증이 필요하다. 다음 명령어로 인증을 진행한다:

```bash
kiro-cli auth login
```

명령어를 실행하면 브라우저 인증 URL이 출력된다. 안내에 따라 인증을 완료한다:

1. 출력된 URL을 브라우저에서 연다
1. AWS Builder ID 또는 IAM Identity Center 계정으로 로그인한다
1. 인증 코드를 확인하고 승인한다
1. 터미널에 인증 성공 메시지가 표시된다

예상 출력:

```text
Opening browser for authentication...
Authorization code: XXXX-XXXX
Waiting for authorization...
Successfully authenticated.
```

> WSL 환경에서 브라우저가 자동으로 열리지 않을 수 있다. 이 경우 출력된 URL을 Windows 브라우저에 직접 붙여넣는다.

인증 상태를 확인한다:

```bash
kiro-cli auth status
```

### 5. 동작 확인 테스트

Kiro CLI가 정상적으로 설치되었는지 간단한 테스트를 수행한다:

```bash
kiro-cli --help
```

> CAO에서 Kiro CLI를 프로바이더로 사용하려면 에이전트 실행 시 `--provider kiro_cli` 옵션을 지정한다:
>
> ```bash
> cao launch code_supervisor --provider kiro_cli
> ```

## 예상 결과

- `kiro-cli --version` 실행 시 버전 정보가 출력된다
- `kiro-cli auth status` 실행 시 인증 상태가 확인된다

## 검증

Ubuntu 터미널에서 검증 스크립트를 실행한다:

```bash
bash verify.sh
```

예상 출력:

```text
[PASS] kiro-cli 명령어 - kiro-cli 명령어 사용 가능
[PASS] kiro-cli --version - 버전 정보 정상 출력 (X.X.X)
---
결과: 2/2 항목 통과
```

## 문제 해결

### "kiro-cli: command not found" 오류

Kiro CLI가 설치되었지만 PATH에 포함되지 않은 경우 발생한다:

```bash
# 설치 경로 확인
which kiro-cli 2>/dev/null || find /usr/local/bin /usr/bin ~/.local/bin -name "kiro-cli" 2>/dev/null

# PATH에 수동 추가 (zip 설치의 경우)
export PATH="/usr/local/bin:$PATH"
```

.deb 패키지로 재설치를 시도한다:

```bash
curl -fSL -o kiro-cli.deb https://desktop-release.kiro.dev/kiro-cli-latest-amd64.deb
sudo dpkg -i kiro-cli.deb
sudo apt-get install -f -y
rm kiro-cli.deb
```

### 인증 실패 또는 토큰 만료

인증 토큰이 만료되었거나 인증에 실패한 경우, 토큰을 재설정하고 다시 로그인한다:

```bash
# 기존 인증 정보 로그아웃
kiro-cli auth logout

# 다시 로그인
kiro-cli auth login
```

인증 캐시를 완전히 초기화해야 하는 경우:

```bash
# 인증 캐시 디렉토리 삭제
rm -rf ~/.kiro/auth 2>/dev/null
rm -rf ~/.config/kiro/auth 2>/dev/null

# 다시 로그인
kiro-cli auth login
```

### WSL에서 브라우저가 열리지 않는 경우

WSL 환경에서는 브라우저가 자동으로 열리지 않을 수 있다. `kiro-cli auth login` 실행 후 출력되는 URL을 복사하여 Windows 브라우저에서 직접 열어 인증을 완료한다.

## 다음 단계

Kiro CLI 설정이 완료되었다면 [Step 07: 첫 실행](../step-07-first-run/README.md)으로 진행한다.
