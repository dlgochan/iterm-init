# iTerm2 + Oh My Zsh + Powerlevel10k Development Shell Setup

이 저장소는 macOS 환경에서 개발 생산성을 높이기 위해 **iTerm2**, **Oh My Zsh**, **Powerlevel10k**, 그리고 여러 유용한 Zsh 플러그인 및 CLI 툴을 자동으로 설치·구성하는 스크립트를 제공합니다.

---

## 📦 구성 요소

- **iTerm2** – macOS용 고급 터미널 에뮬레이터
- **Homebrew** – macOS 패키지 관리자
- **Oh My Zsh** – Zsh 설정/플러그인 관리 프레임워크
- **Powerlevel10k** – 빠르고 커스터마이징 가능한 Zsh 프롬프트 테마
- **플러그인**
  - `git` – Git 명령어 단축
  - `extract` – 다양한 압축파일 해제
  - `colored-man-pages` – `man` 페이지 컬러링
  - `zsh-autosuggestions` – 명령어 자동 제안
  - `zsh-syntax-highlighting` – 명령어 구문 하이라이팅
  - `autojump` – 자주 가는 디렉토리로 빠르게 이동
  - `fzf` – Fuzzy Finder
  - `history-substring-search` – 부분 문자열 기반 명령어 이력 검색
- **bat** – `cat` 대체 도구 (구문 하이라이팅 지원)

---

## ⚙️ 요구 사항

- macOS
- [Homebrew](https://brew.sh/) (스크립트가 자동 설치 지원)
- [GitHub CLI (`gh`)](https://cli.github.com/) – GitHub 레포 자동 생성/관리 시 필요 *(선택 사항)*

---

## 🚀 설치 방법

1. 저장소 클론:
    ```bash
    git clone https://github.com/dlgochan/iterm-init.git
    cd iterm-init
    ```

2. 실행 권한 부여:
    ```bash
    chmod +x setup_dev_shell.sh
    ```

3. 스크립트 실행:
    ```bash
    ./setup_dev_shell.sh
    ```

4. Powerlevel10k 설정 마법사 실행 (자동 실행 안 될 경우):
    ```bash
    p10k configure
    ```

---

## 📄 참고

- 스크립트 실행 후 `.zshrc`가 자동으로 백업됩니다:  
  `~/.zshrc.bak.<타임스탬프>`
- iTerm2 프로파일 Export/Import는 스크립트에 포함되어 있지 않습니다.
- **폰트**: Powerlevel10k 사용 시 [Nerd Fonts](https://www.nerdfonts.com/) 설치 권장 (예: JetBrainsMono Nerd Font).

---

## 📝 라이선스

MIT License
