# AAPC-AndroidAppsCompiler

**AAPC** is a small CLI tool designed to compile Android Gradle projects directly from an Android device using **Termux**.

It consists of two shell scripts:

- `install_env.sh` – prepares the Termux environment (OpenJDK, Gradle, Android SDK & optional NDK).
- `androidappscompile.sh` – interactive CLI to select projects and run Gradle debug builds with different error/detail levels.

Target use case:  
Developers who want to build Android apps on-device without opening a PC, or who want a lightweight build helper for multiple projects.


## Features

- 📁 **Project discovery**  
  Scans a dedicated directory on internal storage for Android Gradle projects that contain `gradlew`.

- 🔢 **Interactive project selection**  
  Shows a numbered list of available projects and lets you pick by number.

- ⚙️ **Build modes**  
  For the selected project, you can choose:
  - Normal compile (`assembleDebug`)
  - Compile with error stacktrace
  - Compile with detailed logs (`--stacktrace --info`)

- 📦 **APK export helper**  
  On successful build, the debug APK is:
  - Detected automatically under the project’s build outputs
  - Copied to a common `Builds` directory as  
    `<project-name>-debug-latest.apk`

- 🧩 **Environment installer**  
  `install_env.sh` can:
  - Install OpenJDK, Gradle, git, unzip, wget in Termux
  - Download & extract Android SDK for Termux (aarch64)
  - Optionally download & extract Android NDK for Termux (aarch64)
  - Append environment variables to your shell config (`ANDROID_SDK_ROOT`, `ANDROID_HOME`, `NDK_HOME`, `PATH`)

---

## Requirements

- Android device (64-bit / aarch64 recommended)
- [Termux](https://termux.dev/) from a trusted source (F-Droid or official)
- Android 9.0+ 
- Enough RAM for Gradle builds (4 GB+ is better, heavy projects may need more)
- Gradle-based Android projects (with `gradlew` and at least one Android module)


## Installation

1. **Clone this repository**
```shell
git clone https://github.com/Gustyx-Power>/AAPC-AndroidAppsCompiler.git
cd AAPC-AndroidAppsCompiler
```
2. **Make the scripts executable**
```shell
chmod +x install_env.sh
```
```shell
chmod +x androidappscompile.sh
```
3. **Run the environment installer**
```shell
bash install_env.sh
```
During this step:
- Required Termux packages (OpenJDK, git, unzip, wget, gradle) will be installed.
- You will be asked whether you want to download:
   - Android SDK for Termux (aarch64)
   - Android NDK for Termux (needed for native C/C++ projects)

4. **Apply environment variables**
After install_env.sh finishes, reload your shell config:
```bash
source ~/.bashrc
```
# or, if you use zsh:
```zsh
source ~/.zshrc
```

5. **Usage tools**
1. Prepare your projects
Place your Android Gradle projects in a dedicated directory on internal storage (for example under /sdcard/AppsCompile).
Each project should include its own gradlew wrapper and a standard Android module (e.g. an app module).

2. Launch the main tool
From the repository directory (or anywhere, if the script is in your $PATH):
```shell
bash androidappscompile.sh
```
4. Select a project
The tool will list all projects it detects and ask you to choose a number.

4. Choose a build mode
You can pick:
- Normal compile → `./gradlew assembleDebug`
- Compile with error check → `./gradlew assembleDebug --stacktrace`
- Detailed error → `./gradlew assembleDebug --stacktrace --info`

6. Get the APK
On successful build:
The debug APK is found in the project’s build output.
A copy is also placed in a common Builds directory as
<project-name>-debug-latest.apk, ready to install or share.


---
## Notes & Limitations

- Currently focused on **debug builds** (`assembleDebug`).
- **Release builds** (`assembleRelease`) require a proper signing config in your Gradle files and are not automated yet.
- Performance depends heavily on your device:
  - Large Kotlin/Compose projects can be slow and memory-hungry.
  - Long builds can heat up the device; consider taking breaks between builds.
- The Android SDK/NDK used by the installer comes from a third-party Termux-focused project (see Credits).

---

## Roadmap / Ideas

Possible future improvements:

- Menu options for:
  - `assembleRelease`
  - `clean` or `clean assembleDebug`
- Optional `--offline` flag for Gradle builds.
- Colored output (ANSI) for better readability.
- Simple config file for:
  - default build type
  - output paths
  - SDK/NDK locations

---

## Credits

- **Author / Maintainer**  
  **Gustyx-Power**  
  - Concept, shell scripts, project design, and overall idea.

- **Termux Android SDK/NDK (aarch64)**  
  [lzhiyong/termux-ndk](https://github.com/lzhiyong/termux-ndk)  
  - Provides prebuilt Android SDK & NDK for Termux aarch64, used by `install_env.sh`.

- **Termux Project**  
  [Termux](https://github.com/termux/termux-app)  
  - Terminal emulator & Linux environment for Android that makes this tool possible.
If you extend this tool or use it in your own workflow, feel free to add your name in a future **Contributors** section.
