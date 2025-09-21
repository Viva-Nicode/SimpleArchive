rm -rf resultBundle
rm -rf resultBundle.xcresult

SIMULATOR_NAME="iPhone 16 Pro (test)"
SIMULATOR_ID=$(ruby getSimulatorMatchingCondition.rb "$SIMULATOR_NAME" "18-0")
BUNDLE_ID="org.azurelight.SimpleArchive"
BOOTED=$(xcrun simctl list 'devices' | grep "$SIMULATOR_NAME (" | head -1  | grep "Booted" -c)

open -a simulator

if [ $BOOTED -eq 0 ]
then
  xcrun simctl boot $SIMULATOR_ID
fi

xcrun simctl uninstall $SIMULATOR_ID $BUNDLE_ID

set -e -o pipefail
xcodebuild -project /Users/nicode./myDesktop/SimpleArchive/SimpleArchive.xcodeproj \
  -scheme SimpleArchive \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -testPlan UnitTestPlan \
  -derivedDataPath build/ \
  -resultBundlePath resultBundle \
  test
