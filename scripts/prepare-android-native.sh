#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
JAVA_DIR="$ROOT/android/app/src/main/java/com/digiarz/app"
mkdir -p "$JAVA_DIR"
cp "$ROOT/android-native/BiometricCredentialPlugin.java" "$JAVA_DIR/BiometricCredentialPlugin.java"
MAIN="$JAVA_DIR/MainActivity.java"
if [[ ! -f "$MAIN" ]]; then echo "Capacitor MainActivity.java not found" >&2; exit 1; fi
python3 - "$MAIN" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text()
needle="public class MainActivity extends BridgeActivity {"
replacement="""public class MainActivity extends BridgeActivity {
    @Override
    public void onCreate(android.os.Bundle savedInstanceState) {
        registerPlugin(BiometricCredentialPlugin.class);
        super.onCreate(savedInstanceState);
    }
"""
if "registerPlugin(BiometricCredentialPlugin.class)" not in s:
    if needle not in s: raise SystemExit("Unexpected Capacitor MainActivity template")
    s=s.replace(needle,replacement,1)
p.write_text(s)
PY
GRADLE="$ROOT/android/app/build.gradle"
python3 - "$GRADLE" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text()
dependency='implementation "androidx.biometric:biometric:1.1.0"'
if dependency not in s:
    needle="dependencies {"
    if needle not in s: raise SystemExit("Gradle dependencies block not found")
    s=s.replace(needle,needle+"\n    "+dependency,1)
p.write_text(s)
PY
