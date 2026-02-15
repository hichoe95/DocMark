# DocMark

**AI 코딩 시대를 위한 아름다운 Mac 전용 문서 리더**

[English](README.md) | [한국어](README.ko.md)

![macOS](https://img.shields.io/badge/macOS-14%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange) ![License](https://img.shields.io/badge/license-MIT-green) ![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen)

<p align="center">
  <img src="docs/assets/screenshot.png" width="800" alt="DocMark Screenshot" />
  <br>
  <em>(스크린샷 준비 중)</em>
</p>

---

## 왜 DocMark인가요?

**바이브 코딩** 시대가 왔습니다. LLM이 코드를 쓰고, 개발자는 문서를 읽습니다.

대부분의 마크다운 뷰어는 에디터가 먼저, 리더가 나중입니다. DocMark는 처음부터 **읽기 전용**으로 설계되었습니다.

AI 코딩 에이전트(Claude Code, Cursor, OpenCode)를 사용하는 개발자를 위해 만들었습니다. 에이전트가 코드를 작성하는 동안, 여러분은 아키텍처 문서, ADR, API 레퍼런스를 읽습니다.

Electron 없이. Mac 네이티브 SwiftUI. 가볍고 빠르며, macOS에서 자연스럽습니다.

---

## 주요 기능

### 무료 기능

- **아름다운 마크다운 렌더링** — SwiftUI 네이티브 MarkdownView로 깔끔하고 빠른 렌더링
- **프로젝트 폴더 스캔** — 사이드바 트리 네비게이션으로 문서 구조 한눈에 파악
- **구문 강조 코드 블록** — 원클릭 복사 지원
- **Quick Open (⌘P)** — VS Code 스타일 파일 빠른 검색
- **전문 검색 (⌘K)** — SQLite FTS5 기반 전체 문서 검색
- **다크 / 라이트 모드** — 시스템 설정 자동 감지
- **GitHub 스타일 알림 블록** — NOTE, TIP, WARNING, IMPORTANT, CAUTION 지원
- **브레드크럼 내비게이션** — 이전/다음 문서 이동 (⌘[ / ⌘])
- **파일 감시** — 문서 변경 시 자동 새로고침
- **`.docsconfig.yaml` 지원** — 문서 구조 정의 및 커스터마이징

### 프로 기능

- **Mermaid 다이어그램 렌더링** — 플로차트, 시퀀스 다이어그램, 클래스 다이어그램 등
- **KaTeX 수식 렌더링** — 인라인 및 블록 수식 지원
- **목차 패널 (⌘T)** — 문서 구조 빠른 탐색
- **Git 브랜치 및 파일 변경 표시** — 현재 브랜치와 수정된 파일 확인
- **멀티 프로젝트 라이브러리 (⇧⌘L)** — 즐겨찾기, 고정, 최근 프로젝트 관리
- **프로젝트 간 검색** — 여러 프로젝트를 동시에 검색

---

## AI 에이전트 연동

DocMark는 AI 코딩 에이전트를 위한 **선택적 스킬**을 제공합니다. 에이전트가 `.docsconfig.yaml` 구조를 따르도록 학습되어, 문서를 자동으로 생성하고 업데이트할 수 있습니다.

**지원 에이전트:**
- Claude Code
- OpenCode

**설치 방법:**
1. DocMark 실행
2. 도구 메뉴 → 스킬 설치
3. 원클릭으로 에이전트 스킬 설치 완료

**참고:** 스킬은 선택 사항입니다. 없어도 DocMark는 완벽히 동작합니다.

### `.docsconfig.yaml` 예시

```yaml
version: "1.0"
project:
  name: "My Project"
documentation:
  root: "."
  sections:
    - id: "guides"
      path: "docs/guides"
      pattern: "*.md"
    - id: "adr"
      path: "docs/adr"
      pattern: "*.md"
      frontmatter_schema: "adr"
```

---

## 설치 방법

### DMG 다운로드

1. [GitHub Releases](https://github.com/hichoe95/DocMark/releases)에서 최신 버전 다운로드
2. `DocMark.app`을 Applications 폴더로 드래그
3. 실행

**참고:** 서명되지 않은 빌드는 Gatekeeper 경고가 표시될 수 있습니다. 우클릭 → 열기 → 열기를 선택하세요.

### 소스에서 빌드

```bash
git clone https://github.com/hichoe95/DocMark.git
cd DocMark
swift build -c release
./scripts/build-dmg.sh
open build/DocMark.app
```

**요구 사항:**
- macOS 14+ (Sonoma)
- Swift 5.9+

---

## 빠른 시작

1. DocMark 실행
2. 프로젝트 폴더 열기 (⌘O)
3. 사이드바에서 문서 탐색
4. ⌘P로 Quick Open, ⌘K로 검색
5. 아름답게 렌더링된 문서를 즐기세요

---

## 단축키

| 단축키 | 기능 |
|--------|------|
| ⌘O | 프로젝트 폴더 열기 |
| ⌘P | Quick Open (파일 빠른 검색) |
| ⌘K | 전문 검색 |
| ⌘T | 목차 패널 토글 |
| ⌘[ / ⌘] | 이전 / 다음 문서 |
| ⇧⌘L | 프로젝트 라이브러리 |

---

## 프로젝트 구조

```
DocMark/
├── Sources/DocMark/
│   ├── App/          # 앱 진입점, 상태 관리
│   ├── Core/         # 렌더링, 데이터베이스, 파일 감시
│   ├── Features/     # UI: 사이드바, 리더, 검색, 라이브러리
│   └── Models/       # Document, Project, FolderNode
├── Resources/        # 가이드, 샘플 프로젝트
├── skills/           # AI 에이전트 스킬
├── templates/        # 문서 템플릿
└── scripts/          # 빌드 스크립트
```

---

## 기술 스택

| 컴포넌트 | 기술 |
|----------|------|
| UI 프레임워크 | SwiftUI (macOS 14+) |
| 마크다운 렌더링 | MarkdownView 2.6.0 |
| 데이터베이스 | GRDB.swift (SQLite + FTS5) |
| YAML 파싱 | Yams 5.4.0 |
| 다이어그램 | Mermaid.js (WKWebView) |
| 수식 | KaTeX (WKWebView) |
| 빌드 | Swift Package Manager |

---

## 템플릿

DocMark는 일반적인 문서 유형을 위한 템플릿을 제공합니다:

- **ADR (아키텍처 의사결정 기록)** — 중요한 기술 결정 문서화
- **변경 로그** — Keep a Changelog 형식
- **API 문서** — 엔드포인트, 파라미터, 응답 예시
- **가이드 / 튜토리얼** — 단계별 설명 문서

`templates/` 디렉토리에서 확인할 수 있습니다.

---

## 기여하기

PR을 환영합니다! 큰 변경 사항은 이슈를 먼저 열어주세요.

**기여 가이드라인:**
- 기존 코드 스타일을 따라주세요
- 커밋 메시지는 명확하게 작성해주세요
- 새로운 기능은 문서와 함께 제출해주세요

---

## 라이선스

MIT License - 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

---

**문서를 읽는 개발자를 위해 만들었습니다.**
