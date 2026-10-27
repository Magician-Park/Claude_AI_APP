# 팜카고 (Claude_AI_APP)

농업 화물의 요청, 배차, 운송, 정산 흐름을 설계하고 구현하는 앱 프로젝트입니다. 저장소 루트에는 Codex와 함께 다음 작업을 구체화할 수 있는 분할형 개발 워크스페이스가 포함되어 있습니다.

## 빠른 시작

Node.js 20 이상에서 별도 패키지 설치 없이 실행됩니다.

```bash
npm start
```

브라우저에서 `http://127.0.0.1:4173`을 열면 다음 화면을 볼 수 있습니다.

- 왼쪽: 개발 프롬프트 작성, 로컬 기록, 클립보드 복사
- 오른쪽: 전체 화면 설계와 클릭 가능한 PWA 데모 전환
- 가운데 구분선: 드래그하거나 방향키로 패널 너비 조절

프롬프트는 외부 서버로 전송되지 않습니다. `저장 & 복사` 후 현재 Codex 작업에 붙여넣어 개발을 이어가면 됩니다.

주소나 포트를 바꾸려면 `FARMCARGO_HOST`, `FARMCARGO_PORT` 환경 변수를 설정하세요. 기본값은 `127.0.0.1:4173`입니다.

## 프로젝트 구조

```text
.
├── index.html                  # 개발 워크스페이스
├── workspace.css              # 워크스페이스 UI와 반응형 레이아웃
├── workspace.js               # 프롬프트 기록, 미리보기 전환, 리사이저
├── transport-categories.*     # 데모·설계 보드의 공통 화물 선택 UI
├── scripts/dev-server.mjs     # 무의존성 로컬 정적 서버
├── farm-cargo-mockups.html    # 전체 핵심 화면 설계
├── app-demo.html              # 클릭 가능한 PWA 시연
├── manifest.json / sw.js      # PWA 설정
└── app/
    ├── lib/                   # Flutter 실제 앱 소스
    ├── assets/cargo_catalog.json # 앱·데모에서 함께 사용하는 화물 분류
    ├── test/                  # 화물 분류·요청 및 기존 오더 이동 테스트
    └── pubspec.yaml           # Flutter 의존성과 앱 설정
```

## Flutter 앱 실행

현재 저장소에는 Flutter 소스·분류 데이터·테스트가 포함되어 있습니다. 웹 플랫폼 구성이 없는 작업 환경에서는 먼저 `app`에서 `flutter create --platforms=web --project-name=farm_cargo .`로 실행 구성을 준비하세요. 기존 `lib`, `assets`, `test`, `pubspec.yaml`은 보존하고 생성 결과를 확인한 뒤 아래 명령을 실행합니다.

```bash
cd app
flutter pub get
flutter run -d chrome
```

기본 진입점은 `app/lib/main.dart`입니다. 로비의 `운송 요청하기`에서 화물을 고르고 요청 내용을 확인할 수 있습니다. 저장한 요청은 현재 앱 실행 동안 로비에 표시됩니다. 실제 서버 배차나 영구 저장과는 연결되어 있지 않습니다.

## 운송 화물 분류

기존 곡물·퇴비·비료 탭을 화물 종류 → 관련 업체·거점 → 세부 분류 → 품목으로 교체했습니다.

- 배합사료: 팜스코의 안성·정읍·칠곡·보령·제주 거점과 선진 군산공장
- 원료·첨가제: 대상 군산공장의 사료용 아미노산·당류
- 식품 원료·제분 부산물: 삼양사 아산공장의 밀가루·프리믹스·소맥피, SPC에 납품하는 밀가루 등 제빵 원료
- 농산 원물: 국산 담뱃잎과 직접 입력하는 출하자·상차지

SPC는 완제품 식품 출하가 아닌 제빵 원료 납품처로 표시하며, 실제 상차지와 SPC 납품 거점을 구분합니다. 소맥피는 삼양사 아산공장의 제분 부산물·사료 원료로 구분합니다. `app/assets/cargo_catalog.json`을 Flutter, 클릭 데모, 설계 보드가 함께 사용합니다. 분류를 바꾸면 이전 업체·품목 선택을 초기화합니다.

## 점검

```bash
npm run check
cd app && flutter analyze
flutter test
```

## 개발 기준

- `app/lib/`: 실제 제품 동작의 기준
- `farm-cargo-mockups.html`: 전체 UX와 시각 설계의 기준
- `app-demo.html`: 이해관계자용 클릭 시연의 기준
- 루트 워크스페이스: 위 세 영역을 비교하고 다음 작업을 작성하는 도구

제품 흐름이 바뀌면 Flutter 코드와 관련 시연 화면이 서로 어긋나지 않는지 함께 확인합니다.
