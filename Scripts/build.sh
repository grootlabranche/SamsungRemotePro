#!/bin/sh
set -eu

PROJECT="SamsungRemotePro.xcodeproj"
SCHEME="SamsungRemotePro"
DESTINATION="platform=iOS Simulator,name=iPhone 15 Pro"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "Erreur : Xcode/xcodebuild est requis. Ouvrez ce projet sur un Mac avec Xcode 16 ou plus récent."
  exit 1
fi

xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug -destination "$DESTINATION" build
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -destination "$DESTINATION" test
