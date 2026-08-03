# iOS Build Setup & Troubleshooting

## Quick Build (After Fresh Clone)

```bash
# 1. Install dependencies
pod install --repo-update

# 2. Clean all Xcode caches
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# 3. Build
xcodebuild clean build -workspace PawWatch.xcworkspace -scheme PawWatch
```

## If Build Still Fails

### Issue: Module map files not found

**Cause:** Xcode DerivedData cached with old paths

**Solution:**
```bash
# Step 1: Clean everything
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf Pods
rm Podfile.lock

# Step 2: Reinstall pods
pod deintegrate
pod install --repo-update

# Step 3: Clean Xcode
xcodebuild clean -workspace PawWatch.xcworkspace -scheme PawWatch

# Step 4: Build fresh
xcodebuild build -workspace PawWatch.xcworkspace -scheme PawWatch
```

### Issue: "no such module 'UIKit'"

**Cause:** CocoaPods pod integration failed

**Solution:**
```bash
# Close Xcode first
killall Xcode

# Clean pods and reinstall
rm -rf Pods
rm Podfile.lock
pod install --repo-update

# Reopen Xcode
open PawWatch.xcworkspace
```

## Building in Xcode GUI

1. **Close Xcode completely**
   ```bash
   killall Xcode
   ```

2. **Clean pods**
   ```bash
   rm -rf Pods Podfile.lock
   pod install --repo-update
   ```

3. **Clean DerivedData**
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   ```

4. **Open workspace (NOT project)**
   ```bash
   open PawWatch.xcworkspace
   ```

5. **In Xcode:**
   - Product → Clean Build Folder (Cmd+Shift+K)
   - Product → Build (Cmd+B)

## Successful Build Indicators

✅ BUILD SUCCESSFUL message  
✅ No module map errors  
✅ No "no such module" errors  
✅ No Swift compilation errors  
✅ App builds to Products/Debug

## Build Troubleshooting Checklist

- [ ] Using .xcworkspace (NOT .xcodeproj)
- [ ] Pods folder exists with all dependencies
- [ ] CocoaPods version is up-to-date (`pod --version`)
- [ ] Xcode version is current
- [ ] DerivedData has been completely removed
- [ ] M1/M2 Mac? Use arm64 architecture
- [ ] Minimum iOS deployment target is 14.0+

## Verified Working Configuration

- **macOS:** 15.5 or later
- **Xcode:** 16.0 or later
- **CocoaPods:** 1.13 or later
- **iOS Deployment Target:** 14.0+
- **Swift Version:** 5.0+

## Getting Help

If build still fails:
1. Run `pod repo update` and try again
2. Check `pod repo-update` and `pod outdated`
3. Run `pod spec lint` to validate pod specs
4. Check Xcode build logs: Report Navigator → View Details

