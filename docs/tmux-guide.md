# Windows(WSL)에서 tmux 완전 가이드

Windows에서 tmux를 쓰려면 WSL(Ubuntu) 안에서 실행해야 합니다. tmux는 Linux 프로그램이라 Windows 네이티브에서는 안 돌아가요.

## 들어가기 전에: tmux가 뭔데?

터미널 하나로 여러 작업을 동시에 하고 싶을 때 쓰는 도구입니다.

tmux 없이:
- 터미널 창 하나 = 작업 하나
- 창 닫으면 작업 끝
- SSH 끊기면 실행 중이던 거 다 날아감

tmux 있으면:
- 터미널 창 하나 안에서 여러 작업을 탭처럼 전환
- 창을 닫아도 작업이 백그라운드에서 계속 실행
- SSH 끊겨도 다시 접속하면 그대로 이어서 작업

CAO에서는 각 AI 에이전트가 tmux 세션 안에서 돌아갑니다. 그래서 tmux를 알아야 에이전트들을 모니터링할 수 있어요.

---

## 1단계: WSL 터미널 열기

Windows에서 tmux를 쓰려면 먼저 WSL에 들어가야 합니다.

방법 1: 시작 메뉴에서 "Ubuntu" 검색 → 클릭
방법 2: Windows Terminal 열고 Ubuntu 탭 선택
방법 3: 아무 터미널에서 `wsl` 입력

```text
C:\Users\you> wsl
markany@PC:~$    ← 여기가 WSL(Ubuntu) 안
```

이제부터 모든 명령어는 이 WSL 터미널 안에서 실행합니다.

---

## 2단계: tmux 기본 개념

tmux에는 3가지 계층이 있습니다:

```text
┌─────────────────────────────────────────────┐
│ 세션 (Session)                               │
│  ┌──────────────┐  ┌──────────────┐         │
│  │ 윈도우 1      │  │ 윈도우 2      │  ...   │
│  │ ┌────┬─────┐ │  │              │         │
│  │ │패인│패인 │ │  │              │         │
│  │ │ 1  │ 2   │ │  │              │         │
│  │ └────┴─────┘ │  │              │         │
│  └──────────────┘  └──────────────┘         │
└─────────────────────────────────────────────┘
```

- 세션(Session): 가장 큰 단위. 프로젝트 하나 = 세션 하나
- 윈도우(Window): 세션 안의 탭. 브라우저 탭이랑 비슷
- 패인(Pane): 윈도우 안에서 화면 분할. 한 화면을 반으로 쪼개는 것

CAO에서는:
- `cao launch` 하면 → 세션 1개 생성
- 각 에이전트 → 세션 안의 윈도우 1개

---

## 3단계: tmux 시작하기

### 새 세션 만들기

```bash
# 이름 없이 시작 (자동 번호 부여)
tmux

# 이름 지정해서 시작 (권장)
tmux new -s work
```

실행하면 화면 하단에 초록색 바가 나타납니다. 이게 tmux 안에 들어왔다는 표시예요.

```text
markany@PC:~$
                    ← 여기서 작업

[work] 0:bash*      ← 이 초록색 바가 tmux 상태 바
```

### tmux 안인지 확인하는 법

화면 맨 아래에 초록색(또는 설정에 따라 다른 색) 상태 바가 보이면 tmux 안입니다.
또는:

```bash
echo $TMUX
# 뭔가 출력되면 tmux 안, 빈 줄이면 tmux 밖
```

---

## 4단계: 프리픽스 키 이해하기 (가장 중요!)

tmux의 모든 단축키는 **프리픽스 키를 먼저 누르고** 그 다음에 명령 키를 누르는 2단계입니다.

기본 프리픽스 키: `Ctrl+B`

사용법:
1. `Ctrl+B`를 누른다 (동시에 누름)
2. 손을 뗀다
3. 명령 키를 누른다

> ⚠️ 가장 흔한 실수: `Ctrl+B+D`를 세 개 동시에 누르는 것. 절대 동시에 누르면 안 됩니다!

```text
❌ 틀린 방법: Ctrl + B + D 세 키를 동시에 누름
✅ 맞는 방법:
   1단계: Ctrl 누른 상태에서 B 누름 → 두 키 다 뗌
   2단계: (잠깐 쉬고) D만 누름
```

예시: 세션에서 빠져나오기 = `Ctrl+B` → `D`
1. `Ctrl` 키를 누른 상태에서 `B`를 누른다
2. 두 키 다 뗀다 (화면에 아무 변화 없는 게 정상!)
3. `D`를 누른다 → `[detached]` 메시지가 나오면 성공

> 이걸 문서에서는 `Ctrl+B → D` 또는 `C-b d`로 표기합니다.

---

## 5단계: 세션 관리 (가장 많이 쓰는 것)

### 세션에서 빠져나오기 (디태치)

tmux 세션을 종료하지 않고 빠져나옵니다. 세션은 백그라운드에서 계속 실행됩니다.

```text
Ctrl+B → D
```

화면이 원래 터미널로 돌아오고 이런 메시지가 나옵니다:

```text
[detached (from session work)]
markany@PC:~$
```

### 세션 목록 보기

```bash
tmux ls
# 또는
tmux list-sessions
```

출력 예시:

```text
work: 1 windows (created Tue Apr 22 10:30:00 2026)
cao-abc12345: 3 windows (created Tue Apr 22 10:35:00 2026)
```

### 세션에 다시 들어가기 (어태치)

```bash
# 마지막 세션에 접속
tmux attach

# 이름으로 접속
tmux attach -t work

# 줄여서
tmux a -t work
```

### 세션 종료

```bash
# 세션 안에서 종료
exit

# 밖에서 특정 세션 종료
tmux kill-session -t work

# 모든 세션 종료
tmux kill-server
```

---

## 6단계: 윈도우 관리 (탭처럼 사용)

세션 안에서 여러 윈도우를 만들어 탭처럼 전환할 수 있습니다.

### 새 윈도우 만들기

```text
Ctrl+B → C
```

하단 상태 바에 윈도우가 추가됩니다:

```text
[work] 0:bash  1:bash*
                    ↑ 현재 윈도우 (* 표시)
```

### 윈도우 전환

```text
Ctrl+B → N        다음 윈도우
Ctrl+B → P        이전 윈도우
Ctrl+B → 0        0번 윈도우로 이동
Ctrl+B → 1        1번 윈도우로 이동
Ctrl+B → 2        2번 윈도우로 이동
Ctrl+B → W        윈도우 목록 (화살표로 선택, Enter로 이동)
```

`Ctrl+B → W`가 가장 편합니다. 목록이 나오면 화살표 키로 선택하고 Enter:

```text
(0) 0: bash
(1) 1: bash        ← 화살표로 여기 선택하고 Enter
(2) 2: vim
```

### 윈도우 이름 바꾸기

```text
Ctrl+B → ,        이름 입력 후 Enter
```

### 윈도우 닫기

```bash
exit               # 또는 Ctrl+D
```

---

## 7단계: 패인 관리 (화면 분할)

하나의 윈도우를 여러 영역으로 쪼갤 수 있습니다.

### 화면 분할

```text
Ctrl+B → %        세로 분할 (좌|우)
Ctrl+B → "        가로 분할 (상/하)
```

세로 분할 후:

```text
┌──────────┬──────────┐
│          │          │
│  패인 1   │  패인 2   │
│          │          │
└──────────┴──────────┘
```

가로 분할 후:

```text
┌─────────────────────┐
│       패인 1         │
├─────────────────────┤
│       패인 2         │
└─────────────────────┘
```

### 패인 간 이동

```text
Ctrl+B → ←        왼쪽 패인으로
Ctrl+B → →        오른쪽 패인으로
Ctrl+B → ↑        위쪽 패인으로
Ctrl+B → ↓        아래쪽 패인으로
Ctrl+B → O        다음 패인으로 순환
Ctrl+B → ;        마지막 활성 패인으로
```

### 패인 크기 조절

```text
Ctrl+B → Ctrl+←   왼쪽으로 줄이기
Ctrl+B → Ctrl+→   오른쪽으로 늘리기
Ctrl+B → Ctrl+↑   위로 줄이기
Ctrl+B → Ctrl+↓   아래로 늘리기
```

> `Ctrl+B`를 누르고 뗀 다음, `Ctrl`을 다시 누른 상태에서 화살표를 누릅니다.

### 패인 닫기

```bash
exit               # 또는 Ctrl+D
```

### 패인 줌 (전체 화면 토글)

특정 패인을 전체 화면으로 확대했다가 다시 원래 크기로 돌릴 수 있습니다:

```text
Ctrl+B → Z        줌 토글 (다시 누르면 원래 크기)
```

---

## 8단계: 스크롤 (복사 모드)

tmux 안에서는 마우스 스크롤이 기본적으로 안 됩니다. 복사 모드에 들어가야 합니다.

### 스크롤하기

```text
Ctrl+B → [        복사 모드 진입
↑/↓               위아래 스크롤
PgUp/PgDn         페이지 단위 스크롤
q                  복사 모드 종료
```

### 텍스트 검색

복사 모드에서:

```text
/검색어            아래로 검색
?검색어            위로 검색
n                  다음 결과
N                  이전 결과
```

### 텍스트 복사

복사 모드에서:

```text
Space              선택 시작
화살표             선택 영역 확장
Enter              선택 영역 복사
Ctrl+B → ]         붙여넣기
```

---

## 9단계: 세션 간 전환 (CAO 에이전트 모니터링)

CAO를 쓰면 여러 세션이 생깁니다. 세션 간 전환이 중요해요.

### 방법 1: tmux 안에서 세션 전환

```text
Ctrl+B → S        세션 목록 표시
                   화살표로 선택, Enter로 전환
Ctrl+B → (        이전 세션
Ctrl+B → )        다음 세션
```

`Ctrl+B → S`를 누르면 이런 목록이 나옵니다:

```text
(0) + work: 1 windows
(1) + cao-abc12345: 3 windows    ← 여기서 Enter
    (0) + code_supervisor-7d1a: bash
    (1) + developer-8e2b: bash
    (2) + reviewer-9f3c: bash
```

화살표로 원하는 세션/윈도우를 선택하고 Enter를 누르면 바로 이동합니다.

### 방법 2: 디태치 후 다른 세션에 어태치

```text
Ctrl+B → D                    현재 세션에서 빠져나옴
tmux attach -t cao-abc12345   다른 세션에 접속
```

### 방법 3: 여러 터미널 창 사용

Windows Terminal에서 탭을 여러 개 열고 각각 다른 세션에 접속:

```bash
# 탭 1
wsl
tmux attach -t cao-abc12345    # supervisor 모니터링

# 탭 2
wsl
tmux attach -t cao-def67890    # developer 모니터링
```

---

## 10단계: CAO와 tmux 함께 쓰기

### CAO가 만드는 tmux 구조

```bash
cao launch --agents code_supervisor --auto-approve
```

이 명령어를 실행하면:

```text
세션: cao-abc12345
  └── 윈도우: code_supervisor-7d1a    ← 에이전트가 여기서 실행
```

supervisor가 다른 에이전트를 assign/handoff하면:

```text
세션: cao-abc12345
  ├── 윈도우: code_supervisor-7d1a
  ├── 윈도우: developer-8e2b          ← 자동 생성됨
  └── 윈도우: reviewer-9f3c           ← 자동 생성됨
```

### CAO 에이전트 모니터링 워크플로우

```bash
# 1. 세션 목록 확인
tmux ls

# 2. CAO 세션에 접속
tmux attach -t cao-abc12345

# 3. 윈도우 목록 보기 (어떤 에이전트가 있는지)
Ctrl+B → W

# 4. 원하는 에이전트 윈도우 선택 → Enter

# 5. 에이전트 작업 관찰 (스크롤하려면 Ctrl+B → [)

# 6. 다른 에이전트로 전환
Ctrl+B → N    (다음 윈도우)
# 또는
Ctrl+B → W    (목록에서 선택)

# 7. 모니터링 끝나면 빠져나오기
Ctrl+B → D
```

### 4에이전트 동시 모니터링 (화면 분할)

하나의 윈도우에서 4개 패인으로 분할하여 모든 에이전트를 동시에 볼 수 있습니다:

```bash
# 새 윈도우 만들기
tmux new-window -t cao-abc12345

# 4분할
Ctrl+B → %        # 세로 분할 (2개)
Ctrl+B → "        # 왼쪽 가로 분할 (3개)
Ctrl+B → →        # 오른쪽 패인으로 이동
Ctrl+B → "        # 오른쪽 가로 분할 (4개)
```

결과:

```text
┌──────────┬──────────┐
│supervisor│developer │
├──────────┼──────────┤
│ reviewer │  tester  │
└──────────┴──────────┘
```

각 패인에서 에이전트 로그를 tail:

```bash
# 각 패인에서 실행
tail -f ~/.aws/cli-agent-orchestrator/logs/terminal/<terminal-id>.log
```

---

## 단축키 치트시트

### 세션

| 키 | 동작 |
| --- | --- |
| `Ctrl+B → D` | 세션에서 빠져나오기 (디태치) |
| `Ctrl+B → S` | 세션 목록 |
| `Ctrl+B → (` | 이전 세션 |
| `Ctrl+B → )` | 다음 세션 |
| `Ctrl+B → $` | 세션 이름 변경 |

### 윈도우

| 키 | 동작 |
| --- | --- |
| `Ctrl+B → C` | 새 윈도우 |
| `Ctrl+B → N` | 다음 윈도우 |
| `Ctrl+B → P` | 이전 윈도우 |
| `Ctrl+B → W` | 윈도우 목록 |
| `Ctrl+B → 0~9` | 번호로 이동 |
| `Ctrl+B → ,` | 이름 변경 |
| `Ctrl+B → &` | 윈도우 닫기 (확인) |

### 패인

| 키 | 동작 |
| --- | --- |
| `Ctrl+B → %` | 세로 분할 |
| `Ctrl+B → "` | 가로 분할 |
| `Ctrl+B → 화살표` | 패인 이동 |
| `Ctrl+B → O` | 다음 패인 |
| `Ctrl+B → Z` | 줌 토글 |
| `Ctrl+B → X` | 패인 닫기 (확인) |
| `Ctrl+B → {` | 패인 위치 바꾸기 (왼쪽) |
| `Ctrl+B → }` | 패인 위치 바꾸기 (오른쪽) |

### 스크롤/복사

| 키 | 동작 |
| --- | --- |
| `Ctrl+B → [` | 복사 모드 진입 (스크롤) |
| `q` | 복사 모드 종료 |
| `↑/↓` | 스크롤 |
| `/검색어` | 검색 |
| `Space` | 선택 시작 |
| `Enter` | 복사 |
| `Ctrl+B → ]` | 붙여넣기 |

---

## 자주 하는 실수와 해결

### "Ctrl+B가 안 먹어요"

tmux 안에 있는지 확인하세요. 하단에 상태 바가 보여야 합니다. `echo $TMUX`로 확인.

### "화면이 멈췄어요"

`Ctrl+S`를 실수로 누르면 터미널이 멈춥니다. `Ctrl+Q`를 누르면 풀립니다.

### "tmux 안에서 tmux를 또 실행했어요"

```text
sessions should be nested with care, unset $TMUX to force
```

이미 tmux 안에 있는데 `tmux`를 또 실행하면 나오는 경고입니다. `Ctrl+B → D`로 빠져나온 후 다시 하세요.

### "마우스 스크롤이 안 돼요"

기본적으로 tmux에서 마우스 스크롤은 비활성화입니다. 활성화하려면:

```bash
# 현재 세션에서 임시 활성화
tmux set mouse on

# 영구 설정 (~/.tmux.conf에 추가)
echo "set -g mouse on" >> ~/.tmux.conf
```

마우스 모드를 켜면 패인 클릭, 드래그 리사이즈, 스크롤이 모두 마우스로 됩니다.

### "복사한 텍스트를 Windows 클립보드에 붙여넣고 싶어요"

WSL에서 tmux 복사 모드로 복사한 텍스트는 tmux 내부 버퍼에만 저장됩니다. Windows 클립보드로 보내려면:

```bash
# ~/.tmux.conf에 추가
bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "clip.exe"
```

또는 마우스 모드가 켜져 있으면 `Shift`를 누른 상태에서 드래그하면 Windows 기본 선택이 됩니다.
