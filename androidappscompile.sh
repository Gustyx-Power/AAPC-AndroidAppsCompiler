#!/data/data/com.termux/files/usr/bin/bash
# AndroidAppsCompile by Gustyx-Power
# Simple Android project selector + Gradle build helper for Termux

APP_NAME="AndroidAppsCompile by Gustyx-Power"
APPS_DIR="/sdcard/AppsCompile"
BUILDS_DIR="$APPS_DIR/Builds"

print_banner() {
  clear
  echo "========================================"
  echo "  $APP_NAME"
  echo "========================================"
  echo
}

ensure_storage() {
  if [ ! -d "/sdcard" ]; then
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
  if [ -z "$ANDROID_SDK_ROOT" ] && [ -z "$ANDROID_HOME" ]; then
    echo "[!] ANDROID_SDK_ROOT / ANDROID_HOME are not set."
    echo "    Make sure you have run the installer and sourced your shell rc."
    echo
  else
    echo "[i] Android SDK environment detected."
    echo "    ANDROID_SDK_ROOT: ${ANDROID_SDK_ROOT:-$ANDROID_HOME}"
    echo
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
    4) return 1 ;; # go back to project selection
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

  echo "=== Starting build in mode: $mode ==="
  echo

  case "$mode" in
    normal)
      ./gradlew assembleDebug
      ;;
    stacktrace)
      ./gradlew assembleDebug --stacktrace
      ;;
    detail)
      ./gradlew assembleDebug --stacktrace --info
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