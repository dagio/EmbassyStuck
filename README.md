### Install

`carthage bootstrap --platform ios --no-use-binaries --verbose --toolchain com.apple.dt.toolchain.Swift_3_0`

Note : Carthage builds are already in the repo.

### Test

`xcodebuild test -scheme "EmbassyStuck" -destination "platform=iOS Simulator,OS=10.3,name=iPhone 7" -resultBundlePath "/tmp/resultBundles" -enableCodeCoverage "YES" -configuration "Debug" ENABLE_TESTABILITY=YES SWIFT_VERSION=3.0 -project "EmbassyStuck.xcodeproj" ONLY_ACTIVE_ARCH=YES`
