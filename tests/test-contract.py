#!/usr/bin/env python3
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
manifest = json.loads((ROOT / "manifest.json").read_text(encoding="utf-8"))
readme = (ROOT / "README.md").read_text(encoding="utf-8")

assert manifest["schemaVersion"] == 1
assert manifest["id"] == "geekkingcloud.atoshell"
assert manifest["name"] == "Atoshell Queue"
assert manifest["version"] == "1.0.0"
assert set(manifest["kinds"]) == {"bar-widget", "service"}
assert manifest["entryPoints"] == {"barWidget": "BarWidget.qml", "service": "Service.qml"}
assert (ROOT / "LICENSE").read_text(encoding="utf-8").startswith("Mozilla Public License Version 2.0")
assert "omarchy plugin remove geekkingcloud.atoshell" in readme
assert "https://github.com/GeekKingCloud/atoshell" in readme
widget = manifest["barWidget"]
assert widget["defaultSection"] == "right"
assert widget["allowMultiple"] is False
schema = {item["key"]: item for item in widget["schema"]}
assert schema["projectPath"]["type"] == "path"
assert schema["refreshIntervalSec"]["type"] == "integer"

for name in ("BarWidget.qml", "Service.qml", "TicketRow.qml", "QueueSummary.qml", "AtoshellMark.qml"):
    path = ROOT / name
    assert path.is_file(), f"missing {name}"
    source = path.read_text(encoding="utf-8")
    assert not re.search(r'#[0-9a-fA-F]{6}', source), f"hard-coded color in {name}"

assert (ROOT / "assets" / "atoshell-mark.svg").is_file(), "missing canonical Atoshell vector mark"

mark = (ROOT / "AtoshellMark.qml").read_text(encoding="utf-8")
assert "property color frameColor" in mark
assert "property color promptColor" in mark
assert "fillColor: root.frameColor" in mark
assert mark.count("fillColor: root.promptColor") == 2
assert "PathSvg" in mark, "runtime mark should preserve the canonical hand-drawn paths"
assert "onFrameColorChanged: scheduleShapeRebuild()" in mark
assert "onPromptColorChanged: scheduleShapeRebuild()" in mark
assert "shapeLoader.active = false" in mark, "theme switches must rebuild the tiny cached Shape"

helper = (ROOT / "bin" / "atoshell-snapshot").read_text(encoding="utf-8")
assert 'cd -- "$project"' in helper
assert 'atoshell list "$scope" --json' in helper
assert "timeout --kill-after" in helper

bar = (ROOT / "BarWidget.qml").read_text(encoding="utf-8")
assert "KeyboardPanel" in bar
assert "PanelKeyCatcher" in bar
assert "PanelHero" in bar
assert bar.count("AtoshellMark {") == 2
assert bar.count("frameColor: Color.accent") == 2
assert bar.count("promptColor: root.foreground") == 2
assert "useActiveColor" not in bar
assert "activeColor:" not in bar, "queue state must not recolor anything beyond the mark frame"
assert 'assets/atoshell-mark.svg' not in bar, "fixed-color brand SVG must not drive the runtime mark"
assert "ACTIVE" in bar and "UP NEXT" in bar and "BLOCKED" in bar
assert "textFormat: Text.PlainText" in bar

service = (ROOT / "Service.qml").read_text(encoding="utf-8")
assert 'command = [root.helperPath, root.projectPath]' in service
assert "StdioCollector" in service
assert "last good" in service.lower()
assert "displayMessage" in service

assert "Model.autoTextSafe" in bar

ticket_row = (ROOT / "TicketRow.qml").read_text(encoding="utf-8")
assert "isBlocked" in ticket_row
assert "Model.blockedReason" in ticket_row

print("plugin contract: ok")
