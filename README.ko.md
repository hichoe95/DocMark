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

DocMark는 **AI 에이전트가 문서를 쓰고, 여러분은 읽기만 하면 되는** 워크플로우를 위해 설계되었습니다.

### 동작 방식

```
┌─────────────────────────────────────────────────────────┐
│  1. 문서 구조 정의              .docsconfig.yaml        │
│  2. AI 에이전트가 문서 작성     설정에 맞춰 자동 생성   │
│  3. DocMark로 열기              아름답게 읽기            │
└─────────────────────────────────────────────────────────┘
```

**1단계 — `.docsconfig.yaml`로 문서 구조를 정의합니다:**

```yaml
version: "1.0"
project:
  name: "My Project"
documentation:
  root: "."
  sections:
    - id: "guides"
      title: "가이드"
      path: "docs/guides"
      pattern: "*.md"
      frontmatter_schema: "guide"
    - id: "adr"
      title: "아키텍처 의사결정 기록"
      path: "docs/adr"
      pattern: "*.md"
      frontmatter_schema: "adr"
frontmatter_schemas:
  adr:
    required: [status, date, deciders]
    status_values: [proposed, accepted, deprecated, superseded]
  guide:
    required: [title]
    optional: [difficulty, estimated_time]
    difficulty_values: [beginner, intermediate, advanced]
```

**2단계 — AI 코딩 에이전트에 스킬을 설치합니다:**

| 에이전트 | 설치 방법 | 스킬 위치 |
|----------|-----------|-----------|
| Claude Code | 도구 → Claude Code 스킬 설치 | `~/.claude/skills/docmark/SKILL.md` |
| OpenCode | 도구 → OpenCode 스킬 설치 | `~/.opencode/skills/docmark/skill.yaml` |

스킬이 설치되면 에이전트가 자동으로:
- `.docsconfig.yaml`을 읽어 프로젝트 문서 구조를 파악합니다
- 새 문서를 올바른 디렉토리에 생성합니다 (`docs/adr/`, `docs/guides/` 등)
- 필수 frontmatter 필드를 포함합니다 (status, date, title 등)
- 일관된 형식과 템플릿을 따릅니다

**3단계 — DocMark로 프로젝트를 열고 읽으세요.** 끝입니다.

에이전트가 `docs/adr/0003-switch-to-postgres.md`를 적절한 frontmatter와 함께 생성합니다. DocMark를 열면 사이드바의 ADR 섹션에 바로 나타나고, 아름답게 렌더링된 아키텍처 의사결정 기록을 읽을 수 있습니다. 편집도, 포맷팅도 필요 없습니다 — 그냥 읽기만 하면 됩니다.

### 예시: 에이전트에게 ADR 작성 요청하기

Claude Code에게 이렇게 말합니다:

> "PostgreSQL로 데이터베이스를 전환하는 ADR을 작성해줘"

에이전트는 (DocMark 스킬이 설치된 상태에서) `.docsconfig.yaml`을 읽고, ADR 스키마를 찾아서 다음과 같이 생성합니다:

```markdown
---
status: proposed
date: 2025-02-15
deciders: [Engineering Team]
---

# PostgreSQL로 전환

## Context
현재 SQLite 데이터베이스가 확장성 한계에 도달하고 있습니다...

## Decision
프로덕션 환경에서 PostgreSQL로 마이그레이션합니다...

## Consequences
**긍정적:** 동시 쓰기 성능 향상, 고급 쿼리 기능
**부정적:** 인프라 복잡도 증가
```

이 파일은 `docs/adr/0003-switch-to-postgres.md`에 저장됩니다 — 설정에서 지정한 바로 그 위치입니다. DocMark를 열면 사이드바에 이미 나타나 있고, 깔끔하게 렌더링되어 있습니다.

### 스킬은 선택 사항입니다

이 모든 것은 선택적입니다. DocMark는 AI 연동 없이도 독립적인 문서 리더로 완벽하게 동작합니다. `.docsconfig.yaml` 없이도 마크다운 파일이 있는 폴더를 열기만 하면 됩니다.

### 문서 템플릿

DocMark는 `templates/` 디렉토리에 시작 템플릿을 제공합니다:

| 템플릿 | 용도 |
|--------|------|
| `adr.md` | 아키텍처 의사결정 기록 (상태, 맥락, 결정, 결과) |
| `changelog.md` | Keep a Changelog 형식의 변경 이력 |
| `api-doc.md` | API 엔드포인트 문서 (요청/응답 예시 포함) |
| `guide.md` | 단계별 튜토리얼 (난이도, 사전 요구사항 포함) |
| `docsconfig-template.yaml` | 프로젝트용 `.docsconfig.yaml` 시작 템플릿 |

AI 에이전트가 이 템플릿을 참고하여 문서를 작성합니다. 직접 사용할 수도 있습니다.

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
