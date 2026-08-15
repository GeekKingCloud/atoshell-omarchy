#!/usr/bin/env python3
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
manifest = json.loads((ROOT / "manifest.json").read_text())
readme = (ROOT / "README.md").read_text()

assert manifest["schemaVersion"] == 1
assert manifest["id"] == "geekkingcloud.atoshell"
assert manifest["name"] == "Atoshell Queue"
assert set(manifest["kinds"]) == {"bar-widget", "service"}
assert manifest["entryPoints"] == {"barWidget": "BarWidget.qml", "service": "Service.qml"}
assert (ROOT / "LICENSE").read_text().startswith("Mozilla Public License Version 2.0")
assert "omarchy plugin remove geekkingcloud.atoshell" in readme
assert "https://github.com/GeekKingCloud/atoshell" in readme
widget = manifest["barWidget"]
assert widget["defaultSection"] == "right"
assert widget["allowMultiple"] is False
schema = {item["key"]: item for item in widget["schema"]}
assert schema["projectPath"]["type"] == "path"
assert schema["refreshIntervalSec"]["type"] == "integer"

for name in ("BarWidget.qml", "Service.qml", "TicketRow.qml", "QueueSummary.qml"):
    path = ROOT / name
    assert path.is_file(), f"missing {name}"
    source = path.read_text()
    assert not re.search(r'#[0-9a-fA-F]{6}', source), f"hard-coded color in {name}"

assert (ROOT / "assets" / "atoshell-mark.svg").is_file(), "missing canonical Atoshell vector mark"

helper = (ROOT / "bin" / "atoshell-snapshot").read_text()
assert 'cd -- "$project"' in helper
assert 'atoshell list "$scope" --json' in helper
assert "timeout --kill-after" in helper

bar = (ROOT / "BarWidget.qml").read_text()
assert "KeyboardPanel" in bar
assert "PanelKeyCatcher" in bar
assert "PanelHero" in bar
assert 'assets/atoshell-mark.svg' in bar
assert "ACTIVE" in bar and "UP NEXT" in bar and "BLOCKED" in bar
assert "textFormat: Text.PlainText" in bar

service = (ROOT / "Service.qml").read_text()
assert 'command = [root.helperPath, root.projectPath]' in service
assert "StdioCollector" in service
assert "last good" in service.lower()
assert "displayMessage" in service

assert "Model.autoTextSafe" in bar

ticket_row = (ROOT / "TicketRow.qml").read_text()
assert "isBlocked" in ticket_row
assert "Model.blockedReason" in ticket_row

print("plugin contract: ok")
