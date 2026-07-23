# Firebase App Distribution 설정 (iOS)

## 설치 전 요구사항

- Xcode 13.0 이상
- CocoaPods
- Firebase 서비스 계정 키 (JSON)

## 1. CocoaPods 설치 (이미 완료)

Podfile에 `FirebaseAppDistribution` 추가됨:

```bash
cd PawWatch
pod install
```

## 2. Firebase 서비스 계정 키 준비

1. [Firebase Console](https://console.firebase.google.com) 접속
2. PawWatch 프로젝트 선택
3. ⚙️ 프로젝트 설정 → 서비스 계정
4. "새로운 비공개 키 생성" 클릭
5. JSON 다운로드

## 3. fastlane으로 배포 (권장)

### fastlane 설치

```bash
sudo gem install fastlane -NV
cd PawWatch
fastlane init
```

### Fastfile 구성

`ios/fastlane/Fastfile`:

```ruby
default_platform(:ios)

platform :ios do
  desc "Firebase App Distribution 배포"
  lane :distribute do
    build_app(
      workspace: "PawWatch.xcworkspace",
      scheme: "PawWatch",
      configuration: "Debug",
      destination: "generic/platform=iOS",
      derivedDataPath: "build",
      archivePath: "build/PawWatch.xcarchive",
      export_options: {
        method: "development",
        signingStyle: "automatic"
      }
    )

    firebase_app_distribution(
      app: "1:YOUR_PROJECT_ID:ios:YOUR_APP_ID",
      ipa_path: "build/PawWatch.ipa",
      firebase_cli_token: "YOUR_FIREBASE_CLI_TOKEN",
      testers: "coooldoggy@gmail.com",
      release_notes: "New release with gallery and KakaoTalk sharing features"
    )
  end
end
```

### Firebase CLI 토큰 생성

```bash
firebase login:ci
# 토큰을 복사하여 위의 YOUR_FIREBASE_CLI_TOKEN에 붙여넣기
```

### 배포 실행

```bash
fastlane ios distribute
```

## 4. Xcode에서 직접 배포 (대안)

### 빌드 및 아카이브

1. Xcode에서 PawWatch 프로젝트 열기
2. Product → Build For → Any iOS Device (arm64)
3. Product → Archive

### Firebase에 배포

1. Window → Organizer
2. 생성한 Archive 선택
3. Distribute App → App Distribution 선택
4. 지시사항 따르기

## 5. 테스터 관리

### Firebase Console에서 추가

1. Firebase Console → App Distribution → Testers
2. + Add testers 클릭
3. 이메일 입력 (정규표현식 가능, 예: `.*@example.com`)
4. 초대 전송

### 테스터가 받는 것

- 초대 이메일
- TestFlight 링크 (자동으로 생성)
- 앱 다운로드 및 설치 가능

## 트러블슈팅

| 문제 | 해결방법 |
|------|--------|
| "Firebase CLI token not found" | `firebase login:ci` 다시 실행, 토큰 확인 |
| Xcode 서명 에러 | Signing & Capabilities에서 Team 및 Bundle ID 확인 |
| 테스터가 빌드를 못 받음 | 테스터 이메일 정확성 확인, 초대 수락 확인 |
| Archive 생성 실패 | CocoaPods `pod install` 다시 실행, Xcode 캐시 정리 |

## 앱 ID 찾기

```bash
# Firebase Console에서:
# 1. PawWatch 프로젝트 → 설정 → 앱
# 2. iOS 앱 클릭
# 3. 앱 ID 복사 (형식: 1:PROJECT_ID:ios:APP_ID)

# 또는 터미널에서:
firebase projects:list
firebase apps:list --project=YOUR_PROJECT_ID
```

## .gitignore 설정

```bash
# Firebase CLI 토큰 및 서비스 계정 키 보호
echo "FIREBASE_CLI_TOKEN" >> .gitignore
echo "**/serviceAccount*.json" >> .gitignore
```
