#!/bin/sh
set -eu

PROJECT="SamsungRemotePro.xcodeproj"
SCHEME="SamsungRemotePro"
ARCHIVE_PATH="$(pwd)/build/SamsungRemotePro.xcarchive"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "Erreur : Xcode/xcodebuild est requis."
  exit 1
fi

mkdir -p build
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Release -archivePath "$ARCHIVE_PATH" archive
echo "Archive créée : $ARCHIVE_PATH"
echo "Pour un IPA, fournissez un ExportOptions.plist correspondant à votre équipe de signature puis utilisez xcodebuild -exportArchive."
