#!/bin/zsh

# Stop at the first failed step, so a failed archive never ends up in the
# xcframework.
set -e

if [ -d "DZNetworking.xcframework" ]
then
  rm -r DZNetworking.xcframework
fi

# Archiving a Swift package puts only the binary and Info.plist in the
# framework. The Swift module stays in DerivedData, and without it apps can't
# `import DZNetworking`. This copies it into the framework's Modules folder.
#
# Usage: copy_swift_module <archive name> <build products folder>
copy_swift_module() {
  local archive=$1
  local productsFolder=$2
  local framework="archives/${archive}.xcarchive/Products/usr/local/lib/DZNetworking.framework"
  local module="DerivedData/Build/Intermediates.noindex/ArchiveIntermediates/DZNetworking/BuildProductsPath/${productsFolder}/DZNetworking.swiftmodule"

  if [ ! -d "${module}" ]
  then
    echo "Error: Swift module not found at ${module}" >&2
    exit 1
  fi

  if [ -d "${framework}/Versions/A" ]
  then
    # macOS frameworks keep their contents in Versions/A, with links at the top level.
    mkdir -p "${framework}/Versions/A/Modules"
    cp -R "${module}" "${framework}/Versions/A/Modules/"
    ln -sfh Versions/Current/Modules "${framework}/Modules"
  else
    mkdir -p "${framework}/Modules"
    cp -R "${module}" "${framework}/Modules/"
  fi
}

xcodebuild archive \
 -scheme DZNetworking \
 -destination "generic/platform=iOS" \
 -archivePath "archives/DZNetworking-iOS" \
 SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
 -derivedDataPath ./DerivedData
copy_swift_module DZNetworking-iOS Release-iphoneos

xcodebuild archive \
 -scheme DZNetworking \
 -destination "generic/platform=iOS Simulator" \
 -archivePath "archives/DZNetworking-iOSSim" \
 SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
 -derivedDataPath ./DerivedData
copy_swift_module DZNetworking-iOSSim Release-iphonesimulator

xcodebuild archive \
 -scheme DZNetworking \
 -destination "generic/platform=macOS" \
 -archivePath "archives/DZNetworking-macOS" \
 SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
 -derivedDataPath ./DerivedData
copy_swift_module DZNetworking-macOS Release

# Build xcframework
xcodebuild -create-xcframework \
 -allow-internal-distribution \
 -framework ./archives/DZNetworking-iOS.xcarchive/Products/usr/local/lib/DZNetworking.framework \
 -debug-symbols "${PWD}/archives/DZNetworking-iOS.xcarchive/dSYMs/DZNetworking.framework.dSYM" \
 -framework ./archives/DZNetworking-iOSSim.xcarchive/Products/usr/local/lib/DZNetworking.framework \
 -debug-symbols "${PWD}/archives/DZNetworking-iOSSim.xcarchive/dSYMs/DZNetworking.framework.dSYM" \
 -framework ./archives/DZNetworking-macOS.xcarchive/Products/usr/local/lib/DZNetworking.framework \
 -debug-symbols "${PWD}/archives/DZNetworking-macOS.xcarchive/dSYMs/DZNetworking.framework.dSYM" \
 -output DZNetworking.xcframework
