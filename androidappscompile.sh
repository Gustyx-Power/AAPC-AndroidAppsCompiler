#!/data/data/com.termux/files/usr/bin/bash
# AndroidAppsCompile by Gustyx-Power
# Simple Android project selector + Gradle build helper for Termux or desktop

APP_NAME="AndroidAppsCompile by Gustyx-Power"
APPS_DIR="/sdcard/AppsCompile"
BUILDS_DIR="$APPS_DIR/Builds"

is_termux() {
  case "$PREFIX" in
    *com.termux*) return 0 ;;
    *)            return 1 ;;
  esac
}

print_banner() {
  clear
  echo "========================================"
  echo "  $APP_NAME"
  echo "========================================"
  echo

  if is_termux; then
    echo "[i] Environment: Termux (Android)"
  else
    echo "[i] Environment: non-Termux (desktop/WSL/etc.)"
  fi
  echo
}

ensure_storage() {
  if is_termux && [ ! -d "/sdcard" ]; then
    echo "[!] /sdcard is not accessible."
    echo "    Run: termux-setup-storage"
    exit 1
  fi
}

ensure_project_dirs() {
  if [ ! -d "$APPS_DIR" ]; then
    echo "[i] Creating project directory at: $APPS_DIR"
    mkdir -p "$APPS_DIR"
  fi

  if [ ! -d "$BUILDS_DIR" ]; then
    echo "[i] Creating builds directory at: $BUILDS_DIR"
    mkdir -p "$BUILDS_DIR"
  fi

  echo
  echo "[i] Put your Android Gradle projects here:"
  echo "    $APPS_DIR/<YourProject>"
  echo "    Each project must contain 'gradlew', 'app/' folder, etc."
  echo
}

check_android_env() {
  local sdk_root="${ANDROID_SDK_ROOT:-$ANDROID_HOME}"

  # fallback ke default SDK_DIR kalau env kosong
  if [ -z "$sdk_root" ]; then
    sdk_root="$PREFIX/opt/android-sdk"
  fi

  if [ ! -d "$sdk_root" ]; then
    echo "[!] Android SDK root not found at: $sdk_root"
    echo "    Make sure you have run the installer and sourced your shell rc."
    echo
    return
  fi

  echo "[i] Android SDK environment detected."
  echo "    SDK root: $sdk_root"

  if [ ! -f "$sdk_root/platforms/android-35/android.jar" ]; then
    echo "[!] android-35 platform not found (missing android.jar)."
    echo "    If you use compileSdk 35, run install_env.sh again"
    echo "    and choose to install Android SDK Platform 35."
  fi

  echo
}

prepare_gradle_args() {
  EXTRA_GRADLE_ARGS=()

  if is_termux; then
    # Tentukan SDK root dulu
    local sdk_root="${ANDROID_SDK_ROOT:-$ANDROID_HOME}"
    [ -z "$sdk_root" ] && sdk_root="$PREFIX/opt/android-sdk"

    # Kandidat AAPT2:
    local aapt2_buildtools="$sdk_root/build-tools/35.0.0/aapt2"
    local aapt2_termux="/data/data/com.termux/files/usr/bin/aapt2"

    if [ -x "$aapt2_buildtools" ]; then
      echo "[i] Using build-tools AAPT2: $aapt2_buildtools"
      EXTRA_GRADLE_ARGS+=("-Pandroid.aapt2FromMavenOverride=$aapt2_buildtools")
    elif [ -x "$aapt2_termux" ]; then
      echo "[i] Using Termux AAPT2: $aapt2_termux"
      EXTRA_GRADLE_ARGS+=("-Pandroid.aapt2FromMavenOverride=$aapt2_termux")
    else
      echo "[!] No local AAPT2 found."
      echo "    Gradle will try Maven AAPT2 (x86_64) → kemungkinan besar FAIL di ARM."
    fi
  else
    echo "[i] Non-Termux environment, using default Maven AAPT2."
  fi
}

list_projects() {
  echo "Available projects in $APPS_DIR:"
  echo

  PROJECTS=()
  local i=1

  for d in "$APPS_DIR"/*; do
    if [ -d "$d" ] && [ -f "$d/gradlew" ]; then
      PROJECTS+=("$d")
      echo "  [$i] $(basename "$d")"
      i=$((i+1))
    fi
  done

  if [ "${#PROJECTS[@]}" -eq 0 ]; then
    echo "  (No Gradle projects with 'gradlew' found in $APPS_DIR)"
    echo "  Copy your Android projects into this folder first."
    echo
    return 1
  fi

  echo
  return 0
}

select_project() {
  list_projects || return 1

  read -rp "Select project number (or 0 to exit): " choice

  if [ "$choice" = "0" ]; then
    echo "Exiting."
    exit 0
  fi

  if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
    echo "[!] Input must be a number."
    return 1
  fi

  idx=$((choice-1))

  if [ "$idx" -lt 0 ] || [ "$idx" -ge "${#PROJECTS[@]}" ]; then
    echo "[!] Invalid project number."
    return 1
  fi

  SELECTED_PROJECT="${PROJECTS[$idx]}"
  PROJECT_NAME="$(basename "$SELECTED_PROJECT")"

  echo
  echo "[i] Selected project: $PROJECT_NAME"
  echo "    Path: $SELECTED_PROJECT"
  echo
  return 0
}

build_menu() {
  echo "=== Build Menu for $PROJECT_NAME ==="
  echo "  [1] Normal compile (assembleDebug)"
  echo "  [2] Compile with error check (stacktrace)"
  echo "  [3] Compile with detailed error (stacktrace + info)"
  echo "  [4] Back to project selection"
  echo "  [0] Exit"
  echo
  read -rp "Choose an option: " action
  echo

  case "$action" in
    1) run_build "normal" ;;
    2) run_build "stacktrace" ;;
    3) run_build "detail" ;;
    4) return 1 ;; # back to project selection
    0) echo "Exiting."; exit 0 ;;
    *) echo "[!] Unknown option."; return 0 ;;
  esac
}

run_build() {
  local mode="$1"

  cd "$SELECTED_PROJECT" || {
    echo "[!] Failed to cd into selected project."
    return
  }

  if [ ! -f "./gradlew" ]; then
    echo "[!] 'gradlew' not found in this project."
    echo "    Make sure it is a proper Android Gradle project."
    return
  fi

  chmod +x ./gradlew

  prepare_gradle_args

  echo "=== Starting build in mode: $mode ==="
  echo

  case "$mode" in
    normal)
      bash ./gradlew "${EXTRA_GRADLE_ARGS[@]}" assembleDebug
      ;;
    stacktrace)
      bash ./gradlew "${EXTRA_GRADLE_ARGS[@]}" assembleDebug --stacktrace
      ;;
    detail)
      bash ./gradlew "${EXTRA_GRADLE_ARGS[@]}" assembleDebug --stacktrace --info
      ;;
  esac

  if [ $? -ne 0 ]; then
    echo
    echo "[!] BUILD FAILED. Check the error log above."
    echo "    Mode: $mode"
    echo
    return
  fi

  echo
  echo "[✓] BUILD SUCCESS."

  # Find debug APK
  APK_PATH=$(find app/build/outputs -name "*debug.apk" | head -n 1 2>/dev/null)

  if [ -n "$APK_PATH" ]; then
    echo "    Debug APK found at:"
    echo "      $APK_PATH"

    # Copy to Builds folder with a consistent name
    OUT_APK="$BUILDS_DIR/${PROJECT_NAME}-debug-latest.apk"
    cp "$APK_PATH" "$OUT_APK"
    echo
    echo "    Copied to:"
    echo "      $OUT_APK"
    echo "    (You can install/share this APK easily.)"
  else
    echo "    Could not automatically find a debug APK."
  fi

  echo
}

# ==== MAIN ====
print_banner
ensure_storage
ensure_project_dirs
check_android_env

while true; do
  if select_project; then
    while true; do
      if ! build_menu; then
        # back to project selection
        break
      fi
    done
  else
    echo
    echo "Fix your projects/folder, then run this tool again."
    exit 1
  fi
done