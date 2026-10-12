from hashlib import sha1
from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[2]
PROJECT = ROOT / "RemoteStatsMonitor.xcodeproj/project.pbxproj"
ACTION = "Widget/Configuration/WidgetServerAction.swift"


def identifier(key: str) -> str:
    return sha1(key.encode()).hexdigest()[:24].upper()


def object_block(project: str, object_id: str) -> str:
    match = re.search(rf'"{object_id}" = \{{(.*?)\n\t\t\}};', project, re.DOTALL)
    if match is None:
        raise AssertionError(f"Missing generated Xcode project object {object_id}")
    return match.group(1)


project = PROJECT.read_text()
file_reference = identifier("file:" + ACTION)

for target in ("RemoteStatsMonitor", "RemoteStatsMonitorWidget"):
    build_file = identifier(f"source:{target}:{ACTION}")
    source_phase = identifier("sources:" + target)

    assert file_reference in object_block(project, build_file), (
        f"{ACTION} is missing from the {target} target's build files"
    )
    assert build_file in object_block(project, source_phase), (
        f"{ACTION} is not compiled into the {target} target"
    )

print("Widget action intent is compiled into both the app and widget extension.")
