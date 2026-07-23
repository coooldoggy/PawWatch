# GitHub Actions Firebase Distribution 설정 (iOS)

## 개요
이 가이드는 GitHub Actions를 사용해 자동으로 Firebase App Distribution에 앱을 배포하는 방법을 설명합니다.

## 필수 준비사항

### 1. Firebase 서비스 계정 키 생성

1. [Firebase Console](https://console.firebase.google.com) 접속
2. 프로젝트 선택 → ⚙️ 프로젝트 설정
3. **서비스 계정** 탭 선택
4. **새로운 비공개 키 생성** 클릭
5. JSON 파일 다운로드

### 2. Firebase CLI 토큰 생성

```bash
firebase login:ci
# 브라우저에서 로그인 후 토큰 복사
```

### 3. GoogleService-Info.plist Base64 인코딩

```bash
base64 -i PawWatch/GoogleService-Info.plist | pbcopy
# 또는
cat PawWatch/GoogleService-Info.plist | base64
```

### 4. GitHub Repository Secrets 설정

1. GitHub Repository → **Settings** → **Secrets and variables** → **Actions**
2. **New repository secret** 클릭
3. 다음 secrets 추가:

| Name | 값 |
|------|-----|
| `FIREBASE_ADMIN_KEY` | Firebase 서비스 계정 키 JSON 전체 내용 |
| `FIREBASE_CLI_TOKEN` | `firebase login:ci`로 생성한 토큰 |
| `GOOGLE_SERVICE_INFO_PLIST` | GoogleService-Info.plist를 Base64로 인코딩한 값 |

### 5. fastlane 설정

`fastlane/Fastfile` 생성:

```ruby
default_platform(:ios)

platform :ios do
  desc "Firebase App Distribution 배포"
  lane :distribute do
    setup_ci if is_ci
    
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
      firebase_cli_token: ENV["FIREBASE_CLI_TOKEN"],
      testers: "coooldoggy@gmail.com",
      release_notes: "Automated release via GitHub Actions"
    )
  end
end
```

**YOUR_PROJECT_ID와 YOUR_APP_ID 찾기:**
```bash
firebase projects:list
firebase apps:list --project=YOUR_PROJECT_ID
```

또는 Firebase Console에서:
1. 프로젝트 설정 → 앱
2. iOS 앱 선택
3. 앱 ID 형식: `1:PROJECT_ID:ios:APP_ID`

## 워크플로우 실행

### GitHub UI에서 수동 실행

1. Repository → **Actions** 탭
2. **Firebase App Distribution - iOS** 선택
3. **Run workflow** 클릭
4. Build type 선택 (debug/release)
5. **Run workflow** 클릭

### Workflow 자동 실행 (선택사항)

`.github/workflows/firebase-distribution-ios.yml`을 수정하여 푸시/릴리스에 자동 실행:

```yaml
on:
  push:
    branches: [main]
    paths:
      - 'PawWatch/**'
      - 'Podfile'
      - 'fastlane/**'
```

## Apple Developer Team 설정 (필요한 경우)

만약 자동 서명이 실패하는 경우:

### 1. fastlane match 사용

`fastlane/Fastfile` 수정:

```ruby
lane :distribute do
  setup_ci if is_ci
  
  # Development 인증서 및 프로비저닝 프로필 동기화
  match(
    type: "development",
    app_identifier: "com.example.pawwatch",
    readonly: is_ci
  )
  
  build_app(...)
end
```

### 2. GitHub Actions에서 Apple Developer 인증

GitHub Secrets에 추가:
- `MATCH_PASSWORD`: fastlane match 암호
- `APPLE_ID`: Apple Developer ID
- `APPLE_PASSWORD`: Apple Developer 비밀번호 (앱별 비밀번호 권장)

## 트러블슈팅

| 문제 | 해결방법 |
|------|--------|
| `FIREBASE_ADMIN_KEY not found` | GitHub Secrets에서 확인 |
| `FIREBASE_CLI_TOKEN not found` | `firebase login:ci` 다시 실행하고 토큰 갱신 |
| `GOOGLE_SERVICE_INFO_PLIST not found` | Base64 인코딩된 값이 정확한지 확인 |
| **Build 실패** | `pod install` 다시 실행, Xcode에서 로컬 빌드 테스트 |
| **Xcode 서명 에러** | Xcode: Signing & Capabilities → Team 확인 |
| **Archive 생성 실패** | `CocoaPods`가 최신인지 확인: `sudo gem install cocoapods` |
| **테스터가 빌드를 못 받음** | Firebase Console → App Distribution → Testers에서 이메일 확인 |
| **Pod 설치 실패 (GitHub Actions)** | `macos-latest` 이미지가 Ruby와 CocoaPods 포함 |

## 로컬 테스트

배포 전에 로컬에서 테스트:

```bash
# CocoaPods 설치
pod install

# fastlane 설치
sudo gem install fastlane

# fastlane 실행 (Firebase CLI 토큰 필요)
export FIREBASE_CLI_TOKEN="your-token"
fastlane ios distribute
```

## 주의사항

- ⚠️ **firebase-admin-key.json, FIREBASE_CLI_TOKEN, GoogleService-Info.plist은 절대 git에 커밋하지 마세요**
- Secrets는 GitHub Actions 로그에 마스킹됩니다
- Firebase CLI 토큰은 시간이 지나면 만료될 수 있으니 주기적으로 갱신하세요
- 버전 번호 자동 증가는 추가 설정 필요 (fastlane increment_build_number 등)

## .gitignore 설정

프로젝트 루트 `.gitignore`에 다음 추가:

```
# Secrets
firebase-admin-key.json
FIREBASE_CLI_TOKEN
GoogleService-Info.plist

# fastlane
fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots/**/*.png
fastlane/test_output

# CocoaPods
Pods/
Podfile.lock
```

## 다음 단계

1. 위의 모든 secrets 설정 완료
2. Workflow 탭에서 수동으로 테스트 실행
3. 첫 배포 후 테스터가 제대로 빌드를 받는지 확인
4. 성공 후 자동 트리거 설정 (선택사항)
