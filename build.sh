#!/bin/zsh

if [ -d "DZNetworking.xcframework" ] 
then
  rm -r DZNetworking.xcframework
fi

xcodebuild archive \
 -scheme DZNetworking \
 -destination "generic/platform=iOS" \
 -archivePath "archives/DZNetworking-iOS" \
 SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
 -derivedDataPath ./DerivedData

xcodebuild archive \
 -scheme DZNetworking \
 -destination "generic/platform=iOS Simulator" \
 -archivePath "archives/DZNetworking-iOSSim" \
 SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
 -derivedDataPath ./DerivedData

xcodebuild archive \
 -scheme DZNetworking \
 -destination "generic/platform=macOS" \
 -archivePath "archives/DZNetworking-macOS" \
 SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
 -derivedDataPath ./DerivedData

# Build xcframework
xcodebuild -create-xcframework \
 -allow-internal-distribution \
 -framework ./archives/DZNetworking-iOS.xcarchive/Products/usr/local/lib/DZNetworking.framework \
 -debug-symbols "${PWD}/archives/DZNetworking-iOS.xcarchive/dSYMs/DZNetworking.framework.dSYM" \
 -framework ./archives/DZNetworking-iOSSim.xcarchive/Products/usr/local/lib/DZNetworking.framework \
 -debug-symbols "${PWD}/archives/DZNetworking-iOSSim.xcarchive/dSYMs/DZNetworking.framework.dSYM" \
 -framework ./archives/DZNetworking-macOS.xcarchive/Products/usr/local/lib/DZNetworking.framework \
 -output DZNetworking.xcframework