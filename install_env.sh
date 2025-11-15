#!/data/data/com.termux/files/usr/bin/bash
# AndroidAppsCompile Environment Installer
# by Gustyx-Power

APP_NAME="AndroidAppsCompile Environment Installer"

# Termux aarch64 builds from lzhiyong/termux-ndk
SDK_URL="https://github.com/lzhiyong/termux-ndk/releases/download/android-sdk/android-sdk-aarch64.zip"
NDK_URL="https://github.com/lzhiyong/termux-ndk/releases/download/android-ndk/android-ndk-r27b-aarch64.zip"

SDK_DIR="$PREFIX/opt/android-sdk"
NDK_DIR="$PREFIX/opt/android-ndk-r27b"

print_banner() {
  clear
  echo "========================================"
  echo "  $APP_NAME"
  echo "========================================"
  echo
}

print_banner

echo "[1] Updating Termux packages..."
pkg update -y && pkg upgrade -y

echo
echo "[2] Installing required packages (OpenJDK, git, unzip, wget, gradle, aapt2)..."
pkg install -y openjdk-17 git unzip wget gradle aapt2

echo
echo "[3] Checking storage access..."
if [ ! -d "/sdcard" ]; then
  echo "[!] /sdcard is not accessible."
  echo "    Run this first in Termux: termux-setup-storage"
  echo "    Then re-run this installer."
  exit 1
else
  echo "[✓] /sdcard is accessible."
fi

echo
echo "[4] Checking Android SDK at: $SDK_DIR"

if [ -d "$SDK_DIR" ]; then
  echo "[i] Existing Android SDK detected."
else
  echo "[i] No Android SDK found at $SDK_DIR."

  read -rp "Download and install Android SDK for Termux now? (y/N): " ans_sdk

  case "$ans_sdk" in
    y|Y)
      mkdir -p "$PREFIX/opt"
      cd "$PREFIX/opt" || exit 1

      echo "[i] Downloading Android SDK..."
      wget -O android-sdk-aarch64.zip "$SDK_URL"

      if [ $? -ne 0 ]; then
        echo "[!] Failed to download Android SDK ZIP."
        exit 1
      fi

      echo "[i] Extracting Android SDK..."
      unzip -q android-sdk-aarch64.zip -d "$PREFIX/opt"
      rm -f android-sdk-aarch64.zip

      if [ ! -d "$SDK_DIR" ]; then
        echo "[!] Expected SDK directory not found: $SDK_DIR"
        exit 1
      fi

      echo "[✓] Android SDK installed at: $SDK_DIR"
      ;;
    *)
      echo "[!] Skipping Android SDK installation."
      echo "    You must install/configure it manually later."
      ;;
  esac
fi

echo
echo "[5] Checking Android NDK at: $NDK_DIR"

if [ -d "$NDK_DIR" ]; then
  echo "[i] Existing Android NDK detected."
else
  echo "[i] No Android NDK found at $NDK_DIR."
  echo "    NDK is optional unless your projects use native C/C++ code."

  read -rp "Download and install Android NDK for Termux now? (y/N): " ans_ndk

  case "$ans_ndk" in
    y|Y)
      mkdir -p "$PREFIX/opt"
      cd "$PREFIX/opt" || exit 1

      echo "[i] Downloading Android NDK..."
      wget -O android-ndk-r27b-aarch64.zip "$NDK_URL"

      if [ $? -ne 0 ]; then
        echo "[!] Failed to download Android NDK ZIP."
        exit 1
      fi

      echo "[i] Extracting Android NDK..."
      unzip -q android-ndk-r27b-aarch64.zip -d "$PREFIX/opt"
      rm -f android-ndk-r27b-aarch64.zip

      if [ ! -d "$NDK_DIR" ]; then
        echo "[!] Expected NDK directory not found: $NDK_DIR"
        exit 1
      fi

      echo "[✓] Android NDK installed at: $NDK_DIR"
      ;;
    *)
      echo "[!] Skipping Android NDK installation."
      ;;
  esac
fi

echo
echo "[6] Writing environment variables..."

# Prefer zsh if exists, fallback to bash
SHELL_RC="$HOME/.bashrc"
[ -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.zshrc"

if ! grep -q "AndroidAppsCompile SDK/NDK config" "$SHELL_RC" 2>/dev/null; then
  {
    echo ""
    echo "# AndroidAppsCompile SDK/NDK config"
    echo "export ANDROID_SDK_ROOT=\"$SDK_DIR\""
    echo "export ANDROID_HOME=\"$SDK_DIR\""
    echo "export NDK_HOME=\"$NDK_DIR\""
    echo "export JAVA_HOME=\"$PREFIX/lib/jvm/java-17-openjdk\""
    echo "export PATH=\"\$JAVA_HOME/bin:\$PATH:\$ANDROID_SDK_ROOT/tools:\$ANDROID_SDK_ROOT/tools/bin:\$ANDROID_SDK_ROOT/platform-tools\""
  } >> "$SHELL_RC"
  echo "[✓] Environment variables appended to $SHELL_RC"
else
  echo "[i] Environment section already exists in $SHELL_RC. Skipping."
fi

echo
echo "[7] Checking Android SDK Platform 35 (for compileSdk 35)..."

if [ -d "$SDK_DIR" ]; then
  if [ -f "$SDK_DIR/platforms/android-35/android.jar" ]; then
    echo "[i] Android SDK Platform 35 already installed."
  else
    SDKMANAGER="$SDK_DIR/cmdline-tools/latest/bin/sdkmanager"
    if [ -x "$SDKMANAGER" ]; then
      echo "[i] Android SDK Platform 35 is not installed yet."
      read -rp "Install Android SDK Platform 35 and Build-Tools 35.0.0 now? (y/N): " ans_p35
      case "$ans_p35" in
        y|Y)
          echo "[i] Installing Android SDK Platform 35 and Build-Tools 35.0.0..."
          yes | "$SDKMANAGER" "platforms;android-35" "build-tools;35.0.0"
          if [ -f "$SDK_DIR/platforms/android-35/android.jar" ]; then
            echo "[✓] Android SDK Platform 35 installed successfully."
          else
            echo "[!] Platform 35 installation attempted but android.jar not found."
          fi
          ;;
        *)
          echo "[!] Skipping Platform 35 installation."
          echo "    If you use compileSdk 35, you must install it manually."
          ;;
      esac
    else
      echo "[!] sdkmanager not found or not executable at:"
      echo "    $SDK_DIR/cmdline-tools/latest/bin/sdkmanager"
      echo "    Platform 35 cannot be installed automatically."
    fi
  fi
else
  echo "[!] SDK directory $SDK_DIR does not exist, skipping Platform 35 check."
fi

echo
echo "To apply the new environment variables now, run:"
echo "  source $SHELL_RC"
echo
echo "========================================"
echo "  Environment setup finished."
echo "  You can now use AndroidAppsCompile tool."
echo "========================================"
echo
