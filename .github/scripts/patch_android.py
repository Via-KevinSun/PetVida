"""Ajusta a pasta android/ gerada pelo `flutter create` para o PetVida
(permissões, receivers de notificações locais e desugaring)."""
import re
import sys
from pathlib import Path

root = Path(sys.argv[1] if len(sys.argv) > 1 else "app/android")

# ---------- AndroidManifest.xml ----------
manifest = root / "app/src/main/AndroidManifest.xml"
m = manifest.read_text(encoding="utf-8")

perms = (
    '\n    <uses-permission android:name="android.permission.INTERNET"/>'
    '\n    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>'
    '\n    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>'
)
receivers = (
    '\n        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>'
    '\n        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">'
    '\n            <intent-filter><action android:name="android.intent.action.BOOT_COMPLETED"/></intent-filter>'
    '\n        </receiver>\n    '
)

if "POST_NOTIFICATIONS" not in m:
    m, n = re.subn(r"(<manifest[^>]*>)", lambda x: x.group(1) + perms, m, count=1)
    assert n == 1, "tag <manifest> não encontrada"
if "ScheduledNotificationReceiver" not in m:
    m, n = re.subn(r"</application>", lambda x: receivers + "</application>", m, count=1)
    assert n == 1, "tag </application> não encontrada"
manifest.write_text(m, encoding="utf-8")

# ---------- app/build.gradle(.kts) ----------
gradle = root / "app/build.gradle.kts"
kts = gradle.exists()
if not kts:
    gradle = root / "app/build.gradle"
g = gradle.read_text(encoding="utf-8")

if "coreLibraryDesugaring" not in g:
    flag = "isCoreLibraryDesugaringEnabled = true" if kts else "coreLibraryDesugaringEnabled true"
    g, n = re.subn(r"(compileOptions\s*\{)", lambda x: x.group(1) + "\n        " + flag, g, count=1)
    assert n == 1, "bloco compileOptions não encontrado"
    dep = ('coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")' if kts
           else "coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'")
    g += "\n\ndependencies {\n    " + dep + "\n}\n"
gradle.write_text(g, encoding="utf-8")
print("Android ajustado:", manifest, gradle)
