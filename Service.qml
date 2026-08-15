import QtQuick
import Quickshell.Io

// One shared reader for every bar instance. Failed refreshes preserve the last good
// queue snapshot so a transient command failure never turns known work into an
// empty panel; state/message still make that staleness explicit to the UI.
Item {
  id: root

  property var settings: ({})
  property bool opened: false
  property bool refreshing: false
  property bool refreshQueued: false
  property string state: "loading"
  property string message: "Loading Atoshell queue"
  property var snapshot: ({
    state: "loading",
    project: { name: "", path: "" },
    counts: { active: 0, ready: 0, blocked: 0 },
    active: [], ready: [], blocked: [], generated_at: ""
  })
  property string _stdout: ""
  property string _stderr: ""

  readonly property bool hasData: snapshot && snapshot.state === "ok"
  readonly property string helperPath: Qt.resolvedUrl("bin/atoshell-snapshot").toString().replace(/^file:\/\//, "")
  readonly property string projectPath: String(setting("projectPath", "~") || "~").trim()
  readonly property int configuredIntervalSec: intSetting("refreshIntervalSec", 15, 5, 300)
  readonly property int effectiveIntervalSec: opened ? 3 : configuredIntervalSec

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function intSetting(name, fallback, minimum, maximum) {
    var value = parseInt(String(setting(name, fallback)), 10)
    if (!isFinite(value)) value = fallback
    return Math.max(minimum, Math.min(maximum, value))
  }

  function displayMessage(value, fallback) {
    var normalized = String(value || fallback || "").replace(/\s+/g, " ").trim()
    return normalized.length > 240 ? normalized.slice(0, 237) + "…" : normalized
  }

  function refresh() {
    if (snapshotProcess.running) {
      refreshQueued = true
      return
    }
    refreshQueued = false
    refreshing = true
    _stdout = ""
    _stderr = ""
    snapshotProcess.command = [root.helperPath, root.projectPath]
    snapshotProcess.running = true
  }

  function apply(raw) {
    var payload
    try {
      payload = JSON.parse(String(raw || ""))
    } catch (error) {
      state = "invalid-data"
      message = "The Atoshell helper returned unreadable data."
      return
    }

    var nextState = String(payload.state || "invalid-data")
    if (nextState === "ok") {
      snapshot = payload
      state = "ok"
      message = ""
      return
    }

    // Keep the last good snapshot but tell the panel that it is stale.
    state = nextState
    message = displayMessage(payload.message, "Atoshell queue unavailable")
    if (!hasData) snapshot = payload
  }

  onProjectPathChanged: refreshSoon.restart()

  Timer {
    id: refreshSoon
    interval: 80
    repeat: false
    onTriggered: root.refresh()
  }

  Timer {
    interval: root.effectiveIntervalSec * 1000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Process {
    id: snapshotProcess
    running: false
    command: []
    stdout: StdioCollector {
      id: stdoutCollector
      waitForEnd: true
      onStreamFinished: root._stdout = text
    }
    stderr: StdioCollector {
      id: stderrCollector
      waitForEnd: true
      onStreamFinished: root._stderr = text
    }
    onExited: function(exitCode) {
      root.refreshing = false
      var output = String(stdoutCollector.text || root._stdout || "")
      if (output.trim() !== "") root.apply(output)
      else {
        root.state = "helper-error"
        root.message = root.displayMessage(stderrCollector.text || root._stderr, "Atoshell helper produced no output")
      }
      if (root.refreshQueued) {
        root.refreshQueued = false
        Qt.callLater(root.refresh)
      }
    }
  }
}
