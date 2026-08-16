import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root

  moduleName: "geekkingcloud.atoshell"
  ipcTarget: "geekkingcloud.atoshell"
  manageIpc: false

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.5)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property var svc: bar && bar.shell && typeof bar.shell.serviceFor === "function"
    ? bar.shell.serviceFor(moduleName)
    : null
  readonly property var snapshot: svc ? svc.snapshot : ({
    state: "loading",
    project: { name: "", path: "" },
    counts: { active: 0, ready: 0, blocked: 0 },
    active: [], ready: [], blocked: [], generated_at: ""
  })
  readonly property string serviceState: svc ? svc.state : "loading"
  readonly property string serviceMessage: svc ? svc.message : "Loading Atoshell queue"
  readonly property bool refreshing: svc ? svc.refreshing : false
  readonly property bool hasData: svc ? svc.hasData : false
  readonly property int maxTickets: intSetting("maxTicketsPerSection", 5, 1, 20)
  readonly property var visibleSnapshot: ({
    active: (snapshot.active || []).slice(0, maxTickets),
    ready: (snapshot.ready || []).slice(0, maxTickets),
    blocked: (snapshot.blocked || []).slice(0, maxTickets)
  })
  readonly property var navigationRows: Model.navigationRows(visibleSnapshot)
  readonly property int totalCount: Number((snapshot.counts || {}).active || 0)
    + Number((snapshot.counts || {}).ready || 0)
    + Number((snapshot.counts || {}).blocked || 0)

  property int cursor: -1
  property bool cursorActive: false

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function intSetting(name, fallback, minimum, maximum) {
    var value = parseInt(String(setting(name, fallback)), 10)
    if (!isFinite(value)) value = fallback
    return Math.max(minimum, Math.min(maximum, value))
  }

  function pushSettings() {
    if (svc && "settings" in svc) svc.settings = settings
  }

  function refresh() {
    if (svc && typeof svc.refresh === "function") svc.refresh()
  }

  function moveCursor(delta) {
    cursorActive = true
    if (navigationRows.length === 0) {
      cursor = -1
      return
    }
    if (cursor < 0) cursor = delta > 0 ? 0 : navigationRows.length - 1
    else cursor = Math.max(0, Math.min(navigationRows.length - 1, cursor + delta))
    scrollCursorIntoView()
  }

  function chooseTicket(id) {
    cursorActive = true
    for (var i = 0; i < navigationRows.length; i++) {
      if (Number(navigationRows[i].ticket.id) === Number(id)) {
        cursor = i
        scrollCursorIntoView()
        return
      }
    }
  }

  function ticketSelected(id) {
    return cursorActive && cursor >= 0 && cursor < navigationRows.length
      && Number(navigationRows[cursor].ticket.id) === Number(id)
  }

  function openProjectTerminal() {
    var path = snapshot && snapshot.project ? String(snapshot.project.path || "") : ""
    if (path === "") return
    Quickshell.execDetached(["setsid", "uwsm-app", "--", "xdg-terminal-exec", "--dir=" + path])
  }

  function scrollCursorIntoView() {
    if (!panelFlick || cursor < 0 || cursor >= navigationRows.length) return
    Qt.callLater(function() {
      var selectedId = Number(navigationRows[cursor].ticket.id)
      var item = null
      var repeaters = [activeRepeater, readyRepeater, blockedRepeater]
      for (var r = 0; r < repeaters.length && !item; r++) {
        for (var i = 0; i < repeaters[r].count; i++) {
          var candidate = repeaters[r].itemAt(i)
          if (candidate && candidate.ticket && Number(candidate.ticket.id) === selectedId) {
            item = candidate
            break
          }
        }
      }
      if (!item) return
      var point = item.mapToItem(panelFlick.contentItem, 0, 0)
      var margin = Style.space(8)
      if (point.y < panelFlick.contentY + margin) panelFlick.contentY = Math.max(0, point.y - margin)
      else if (point.y + item.height > panelFlick.contentY + panelFlick.height - margin)
        panelFlick.contentY = Math.min(panelFlick.contentHeight - panelFlick.height, point.y + item.height + margin - panelFlick.height)
    })
  }

  function generatedLabel() {
    var raw = String(snapshot.generated_at || "")
    if (raw === "") return serviceState === "loading" ? "READING QUEUE" : "WAITING FOR DATA"
    var stamp = new Date(raw)
    if (isNaN(stamp.getTime())) return "QUEUE SNAPSHOT"
    return "UPDATED " + Qt.formatTime(stamp, "HH:mm:ss")
  }

  onSvcChanged: pushSettings()
  onSettingsChanged: pushSettings()
  onNavigationRowsChanged: if (cursor >= navigationRows.length) cursor = navigationRows.length - 1
  onOpenedChanged: {
    cursor = -1
    cursorActive = false
    if (svc) svc.opened = opened
    if (opened) {
      refresh()
      if (panelFlick) panelFlick.contentY = 0
      Qt.callLater(function() { keyCatcher.forceActiveFocus() })
    }
  }

  IpcHandler {
    target: root.ipcTarget
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): string { root.refresh(); return "ok" }
    function status(): string { return root.serviceState }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: ""
    iconComponent: Component {
      Item {
        AtoshellMark {
          anchors.fill: parent
          frameColor: Color.accent
          promptColor: root.foreground
        }
        Rectangle {
          visible: Number((root.snapshot.counts || {}).blocked || 0) > 0
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          width: Math.max(4, Style.space(5))
          height: width
          radius: width / 2
          color: root.urgent
        }
      }
    }
    active: Number((root.snapshot.counts || {}).active || 0) > 0 || Number((root.snapshot.counts || {}).blocked || 0) > 0
    tooltipText: root.serviceState !== "ok" && root.serviceMessage !== ""
      ? Model.autoTextSafe(root.serviceMessage)
      : Model.barTooltip(root.snapshot, root.refreshing)
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton || buttonCode === Qt.MiddleButton) root.refresh()
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(420))
    contentHeight: panel.fittedContentHeight(content.implicitHeight, Style.space(640))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) { if (dy !== 0) root.moveCursor(dy) }
      onActivateRequested: root.openProjectTerminal()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(character) {
        var key = String(character || "").toLowerCase()
        if (key === "r") root.refresh()
        else if (key === "o" || key === "t") root.openProjectTerminal()
      }

      Flickable {
        id: panelFlick
        anchors.fill: parent
        contentWidth: width
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height

        Column {
          id: content
          width: panelFlick.width
          spacing: Style.space(12)

          PanelHero {
            id: hero
            width: parent.width
            title: "Atoshell"
            meta: root.snapshot.project && String(root.snapshot.project.name || "") !== ""
              ? Model.autoTextSafe(root.snapshot.project.name) + "  ·  " + root.generatedLabel()
              : root.generatedLabel()
            foreground: root.foreground
            fontFamily: root.fontFamily
            iconComponent: Component {
              Item {
                width: Style.space(30)
                height: width
                AtoshellMark {
                  anchors.fill: parent
                  frameColor: Color.accent
                  promptColor: root.foreground
                }
                Rectangle {
                  visible: Number((root.snapshot.counts || {}).blocked || 0) > 0
                  anchors.right: parent.right
                  anchors.bottom: parent.bottom
                  width: Style.space(6)
                  height: width
                  radius: width / 2
                  color: root.urgent
                }
              }
            }
            trailingControl: Component {
              Row {
                spacing: Style.space(3)
                PanelActionButton {
                  iconText: "󰆍"
                  tooltipText: "Open project terminal  (o)"
                  foreground: hero.foreground
                  onClicked: root.openProjectTerminal()
                }
                PanelActionButton {
                  iconText: "󰑐"
                  tooltipText: "Refresh  (r)"
                  foreground: hero.foreground
                  onClicked: root.refresh()
                  RotationAnimator on rotation {
                    running: root.refreshing
                    from: 0
                    to: 360
                    duration: 900
                    loops: Animation.Infinite
                  }
                }
              }
            }
          }

          QueueSummary {
            width: parent.width
            counts: root.snapshot.counts || ({ active: 0, ready: 0, blocked: 0 })
            foreground: root.foreground
            fontFamily: root.fontFamily
          }

          Rectangle {
            visible: root.serviceState !== "ok" && root.hasData
            width: parent.width
            height: staleText.implicitHeight + Style.space(12)
            radius: Style.cornerRadius
            color: Style.normalFillFor(root.urgent, Color.accent)
            Text {
              id: staleText
              anchors.fill: parent
              anchors.margins: Style.space(6)
              text: "Showing the last queue snapshot  ·  " + root.serviceMessage
              textFormat: Text.PlainText
              color: root.urgent
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }
          }

          Column {
            visible: root.serviceState !== "ok" && !root.hasData
            width: parent.width
            spacing: Style.space(5)
            Text {
              width: parent.width
              text: root.serviceState === "loading" ? "Reading the queue…" : root.serviceMessage
              textFormat: Text.PlainText
              color: root.serviceState === "loading" ? root.dim : root.urgent
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              wrapMode: Text.WordWrap
            }
            Text {
              visible: root.serviceState !== "loading"
              width: parent.width
              text: "Set the project folder from Setup › Plugins › Atoshell Queue."
              textFormat: Text.PlainText
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }
          }

          Column {
            visible: root.serviceState === "ok" && root.totalCount === 0
            width: parent.width
            spacing: Style.space(4)
            Text {
              text: "Queue clear"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
            }
            Text {
              width: parent.width
              text: "No active, ready, or blocked tickets. Atoshell has nothing waiting."
              textFormat: Text.PlainText
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              wrapMode: Text.WordWrap
            }
          }

          Column {
            visible: root.visibleSnapshot.active.length > 0
            width: parent.width
            spacing: Style.space(4)
            PanelSeparator { width: parent.width; foreground: root.foreground }
            PanelSectionHeader { text: "ACTIVE"; foreground: root.foreground; fontFamily: root.fontFamily }
            Repeater {
              id: activeRepeater
              model: root.visibleSnapshot.active
              TicketRow {
                required property var modelData
                width: parent.width
                ticket: modelData
                queueState: "active"
                selected: root.ticketSelected(modelData.id)
                foreground: root.foreground
                fontFamily: root.fontFamily
                onChosen: root.chooseTicket(modelData.id)
              }
            }
          }

          Column {
            visible: root.visibleSnapshot.ready.length > 0
            width: parent.width
            spacing: Style.space(4)
            PanelSeparator { width: parent.width; foreground: root.foreground }
            PanelSectionHeader { text: "UP NEXT"; foreground: root.foreground; fontFamily: root.fontFamily }
            Repeater {
              id: readyRepeater
              model: root.visibleSnapshot.ready
              TicketRow {
                required property var modelData
                width: parent.width
                ticket: modelData
                queueState: "ready"
                selected: root.ticketSelected(modelData.id)
                foreground: root.foreground
                fontFamily: root.fontFamily
                onChosen: root.chooseTicket(modelData.id)
              }
            }
          }

          Column {
            visible: root.visibleSnapshot.blocked.length > 0
            width: parent.width
            spacing: Style.space(4)
            PanelSeparator { width: parent.width; foreground: root.foreground }
            PanelSectionHeader { text: "BLOCKED"; foreground: root.foreground; fontFamily: root.fontFamily }
            Repeater {
              id: blockedRepeater
              model: root.visibleSnapshot.blocked
              TicketRow {
                required property var modelData
                width: parent.width
                ticket: modelData
                queueState: "blocked"
                selected: root.ticketSelected(modelData.id)
                foreground: root.foreground
                fontFamily: root.fontFamily
                onChosen: root.chooseTicket(modelData.id)
              }
            }
          }

          Text {
            visible: root.totalCount > root.navigationRows.length
            width: parent.width
            text: "+" + (root.totalCount - root.navigationRows.length) + " more tickets  ·  adjust the section limit in plugin settings"
            textFormat: Text.PlainText
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }

          Text {
            visible: root.hasData
            width: parent.width
            text: "j/k navigate  ·  enter/o terminal  ·  r refresh  ·  esc close"
            textFormat: Text.PlainText
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            horizontalAlignment: Text.AlignHCenter
          }
        }
      }
    }
  }
}
