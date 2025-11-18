# AI 가계부 분석 기능 설정 가이드

## 🎯 개요

Gemini 1.5 Flash를 활용한 AI 가계부 분석 기능이 구현되었습니다.

### 주요 기능

1. **🔍 멍청 비용 및 반복 지출 탐지 (습관 분석)**
   - 소액이지만 빈도가 높아 큰 돈이 되는 지출 패턴 분석
   - 예시: "이번 달에만 편의점을 15번 가셨네요. 1회 평균 6,000원씩 쓰면서 총 9만원이 나갔어요."

2. **⚠️ 전월 대비 급등 항목 경고 (변동 분석)**
   - 지난달 대비 비정상적으로 늘어난 카테고리 탐지
   - 예시: "지난달보다 '식비'가 30% (15만원) 더 나왔어요. 주로 주말 저녁 배달비가 원인이네요."

3. **🔮 월말 잔액 예측 (예산 방어)**
   - 현재 지출 속도로 월말까지 예산 유지 가능 여부 예측
   - 예시: "지금 속도로 돈을 쓰면 25일쯤 예산이 바닥날 거예요 🚨."

---

## 🔑 Gemini API 키 설정

### 1단계: API 키 발급

1. [Google AI Studio](https://makersuite.google.com/app/apikey)에 접속
2. "Create API Key" 버튼 클릭
3. 프로젝트 선택 또는 새 프로젝트 생성
4. API 키 복사

### 2단계: API 키 코드에 적용

`lib/services/gemini_service.dart` 파일을 열어 아래 부분을 수정하세요:

```dart
class GeminiService {
  // TODO: 실제 API 키로 교체하세요
  static const String _apiKey = 'YOUR_GEMINI_API_KEY_HERE';  // ← 여기에 발급받은 API 키 입력
  
  // ... 나머지 코드
}
```

**예시:**
```dart
static const String _apiKey = 'AIzaSyAbCdEfGhIjKlMnOpQrStUvWxYz1234567';
```

### 3단계: 보안 강화 (선택사항 - 권장)

API 키를 코드에 직접 넣는 대신 환경 변수로 관리하는 것이 안전합니다.

#### 방법 1: flutter_dotenv 사용

1. `pubspec.yaml`에 추가:
```yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

2. 프로젝트 루트에 `.env` 파일 생성:
```
GEMINI_API_KEY=your_actual_api_key_here
```

3. `.gitignore`에 `.env` 추가 (중요!)
```
.env
```

4. `gemini_service.dart` 수정:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  // ...
}
```

5. `main.dart`에서 초기화:
```dart
Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}
```

---

## 📱 사용 방법

### 메인 화면에서 접근

1. **상단 카테고리 버튼**
   - 메인 화면 상단의 "AI 분석" 버튼 클릭

2. **AI 분석 카드**
   - 메인 화면 하단의 "AI 가계부 분석" 카드 클릭

### AI 분석 화면

- 분석 시작 시 자동으로 로딩
- 새로고침 버튼으로 재분석 가능
- 이번 달/지난 달 지출 현황 요약
- AI의 상세 분석 결과 표시

---

## 🛠️ 구현 파일 구조

```
lib/
├── services/
│   └── gemini_service.dart          # Gemini API 서비스
├── screens/
│   ├── ai_analysis_screen.dart      # AI 분석 화면
│   └── main_screen_nologin.dart     # 메인 화면 (버튼 추가됨)
└── pubspec.yaml                     # google_generative_ai 패키지 추가됨
```

---

## 🧪 테스트

1. API 키 설정 확인
2. 앱 재시작
3. 메인 화면에서 "AI 분석" 버튼 클릭
4. 분석 결과 확인

---

## ⚠️ 주의사항

1. **API 키 보안**
   - API 키를 절대 GitHub에 업로드하지 마세요
   - `.env` 파일을 반드시 `.gitignore`에 추가하세요

2. **API 사용량**
   - Gemini 1.5 Flash는 무료 할당량이 있지만 제한적입니다
   - [Google AI Studio](https://makersuite.google.com/)에서 사용량 모니터링

3. **거래 내역 필요**
   - 분석을 위해 최소한 1개월의 거래 내역이 필요합니다
   - 더 많은 데이터가 있을수록 정확한 분석 가능

---

## 🐛 문제 해결

### "분석 중 오류가 발생했습니다"

1. API 키가 올바르게 설정되었는지 확인
2. 인터넷 연결 상태 확인
3. Firestore에 거래 내역이 있는지 확인
4. API 할당량이 남아있는지 확인

### "분석 결과를 생성할 수 없습니다"

1. Gemini API 응답이 비어있을 수 있습니다
2. 프롬프트를 더 구체적으로 수정해보세요
3. 거래 내역 데이터가 충분한지 확인

---

## 📝 커스터마이징

### 프롬프트 수정

`lib/services/gemini_service.dart`의 `_buildAnalysisPrompt()` 메서드에서 프롬프트를 수정할 수 있습니다.

### UI 커스터마이징

`lib/screens/ai_analysis_screen.dart`에서 화면 디자인을 수정할 수 있습니다.

---

## 📚 참고 자료

- [Gemini API 문서](https://ai.google.dev/docs)
- [Google AI Studio](https://makersuite.google.com/)
- [flutter_dotenv 문서](https://pub.dev/packages/flutter_dotenv)

---

## ✅ 체크리스트

- [ ] Gemini API 키 발급 완료
- [ ] `gemini_service.dart`에 API 키 입력
- [ ] 앱 실행 및 테스트
- [ ] API 키 보안 설정 (선택사항)
- [ ] 거래 내역 입력 (분석을 위해)

---

**구현 완료!** 🎉

이제 사용자는 AI가 분석한 지출 습관 피드백을 받을 수 있습니다.

