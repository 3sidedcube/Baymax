FRAMEWORK=Baymax

BUILD=build

FRAMEWORK_PATH=$FRAMEWORK.framework

# iOS

rm -Rf $BUILD

rm -f $FRAMEWORK.framework.tar.gz

xcodebuild archive -project $FRAMEWORK.xcodeproj -scheme $FRAMEWORK -sdk iphoneos SYMROOT=$BUILD

xcodebuild build -project $FRAMEWORK.xcodeproj -target $FRAMEWORK -sdk iphonesimulator SYMROOT=$BUILD

cp -RL $BUILD/Release-iphoneos $BUILD/Release-universal

cp -RL $BUILD/Release-iphonesimulator/$FRAMEWORK_PATH/Modules/$FRAMEWORK.swiftmodule/* $BUILD/Release-universal/$FRAMEWORK_PATH/Modules/$FRAMEWORK.swiftmodule

lipo -create $BUILD/Release-iphoneos/$FRAMEWORK_PATH/$FRAMEWORK $BUILD/Release-iphonesimulator/$FRAMEWORK_PATH/$FRAMEWORK -output $BUILD/Release-universal/$FRAMEWORK_PATH/$FRAMEWORK

tar -czv -C $BUILD/Release-universal -f $FRAMEWORK.tar.gz $FRAMEWORK_PATH $FRAMEWORK_PATH.dSYM
