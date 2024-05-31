#!/bin/bash

# Variables
APP_NAME="gamebase.app"
EXECUTABLE_NAME="gamebase"
LIB_PATH="/usr/local/lib"
DEVELOPER_ID="Developer ID Application: Your Name (Team ID)"  # Replace with your actual developer ID

# gcc -O3 -o myapp -std=c11 -v -I bin bin/main.c -lhl  -L /usr/local/lib /usr/local/lib/uv.hdll /usr/local/lib/fmt.hdll /usr/local/lib/sdl.hdll /usr/local/lib/ui.hdll /usr/local/lib/mysql.hdll /usr/local/lib/openal.hdll /usr/local/lib/ssl.hdll /usr/local/lib/sqlite.hdll

haxe compile_native.hxml
gcc -O3 -o ${EXECUTABLE_NAME} -std=c11 -v -I bin bin/main.c -lhl -L /usr/local/lib /usr/local/lib/*.hdll -L /opt/homebrew/opt/libuv/lib -luv


# Create necessary directories
rm -rf "${APP_NAME}"
mkdir "${APP_NAME}"
mkdir -p "${APP_NAME}/Contents/MacOS"
mkdir -p "${APP_NAME}/Contents/Frameworks"
mkdir -p "${APP_NAME}/Contents/Resources"

# Move the executable
mv "${EXECUTABLE_NAME}" "${APP_NAME}/Contents/MacOS/"

# Copy the libraries
cp "${LIB_PATH}/libhl.dylib" "${APP_NAME}/Contents/Frameworks/"
cp "${LIB_PATH}/fmt.hdll" "${APP_NAME}/Contents/Frameworks/"
cp "${LIB_PATH}/mysql.hdll" "${APP_NAME}/Contents/Frameworks/"
cp "${LIB_PATH}/sdl.hdll" "${APP_NAME}/Contents/Frameworks/"
cp "${LIB_PATH}/sqlite.hdll" "${APP_NAME}/Contents/Frameworks/"
cp "${LIB_PATH}/ssl.hdll" "${APP_NAME}/Contents/Frameworks/"
cp "${LIB_PATH}/ui.hdll" "${APP_NAME}/Contents/Frameworks/"
cp "${LIB_PATH}/uv.hdll" "${APP_NAME}/Contents/Frameworks/"
cp "${LIB_PATH}/openal.hdll" "${APP_NAME}/Contents/Frameworks/"
cp "/opt/homebrew/opt/libuv/lib/libuv.1.dylib" "${APP_NAME}/Contents/Frameworks/"

# Create Info.plist
cat > "${APP_NAME}/Contents/Info.plist" <<EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${EXECUTABLE_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.yourcompany.helloworld</string>
    <key>CFBundleName</key>
    <string>HelloWorld</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.12</string>
</dict>
</plist>
EOL

# Create PkgInfo
echo -n 'APPL????' > "${APP_NAME}/Contents/PkgInfo"

# Adjust rpath
install_name_tool -add_rpath @executable_path/../Frameworks "${APP_NAME}/Contents/MacOS/${EXECUTABLE_NAME}"

# Update library paths if needed
install_name_tool -change @rpath/libhl.dylib @executable_path/../Frameworks/libhl.dylib "${APP_NAME}/Contents/MacOS/${EXECUTABLE_NAME}"
install_name_tool -change fmt.hdll @executable_path/../Frameworks/fmt.hdll "${APP_NAME}/Contents/MacOS/${EXECUTABLE_NAME}"
install_name_tool -change mysql.hdll @executable_path/../Frameworks/mysql.hdll "${APP_NAME}/Contents/MacOS/${EXECUTABLE_NAME}"
install_name_tool -change sdl.hdll @executable_path/../Frameworks/sdl.hdll "${APP_NAME}/Contents/MacOS/${EXECUTABLE_NAME}"
install_name_tool -change sqlite.hdll @executable_path/../Frameworks/sqlite.hdll "${APP_NAME}/Contents/MacOS/${EXECUTABLE_NAME}"
install_name_tool -change ssl.hdll @executable_path/../Frameworks/ssl.hdll "${APP_NAME}/Contents/MacOS/${EXECUTABLE_NAME}"
install_name_tool -change ui.hdll @executable_path/../Frameworks/ui.hdll "${APP_NAME}/Contents/MacOS/${EXECUTABLE_NAME}"
install_name_tool -change uv.hdll @executable_path/../Frameworks/uv.hdll "${APP_NAME}/Contents/MacOS/${EXECUTABLE_NAME}"
install_name_tool -change openal.hdll @executable_path/../Frameworks/openal.hdll "${APP_NAME}/Contents/MacOS/${EXECUTABLE_NAME}"
install_name_tool -change /opt/homebrew/opt/libuv/lib/libuv.1.dylib @executable_path/../Frameworks/libuv.1.dylib "${APP_NAME}/Contents/MacOS/${EXECUTABLE_NAME}"

# Sign the app
codesign --deep --force --verify --verbose --sign "${DEVELOPER_ID}" "${APP_NAME}"

rm -rf bin/"${APP_NAME}"
mv "${APP_NAME}" bin/"${APP_NAME}"

echo "App bundle ${APP_NAME} has been set up successfully."

