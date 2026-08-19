import QtQuick
import qs.Commons
import qs.Ui
import "Model.js" as Model

CursorSurface {
  id: root

  property var ticket: null
  property string queueState: "ready"
  property bool selected: false
  property color foreground: Color.popups.text
  property string fontFamily: Style.font.family

  signal chosen()

  readonly property string blockedReason: Model.blockedReason(ticket)
  readonly property bool isBlocked: blockedReason !== ""
  readonly property color stateColor: isBlocked || queueState === "blocked"
    ? Color.urgent
    : (queueState === "active" ? Color.accent : foreground)
  readonly property color dim: Qt.darker(foreground, 1.5)
  readonly property string progress: isBlocked || queueState === "blocked"
    ? (blockedReason || Model.latestProgress(ticket))
    : Model.latestProgress(ticket)

  hasCursor: selected
  borderSpec: Border.none()
  implicitHeight: rowContent.implicitHeight + Style.space(10)

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.chosen()
  }

  Row {
    id: rowContent
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: Style.space(10)
    anchors.rightMargin: Style.space(10)
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.space(9)

    Text {
      anchors.top: labels.top
      anchors.topMargin: Style.space(1)
      text: root.isBlocked || root.queueState === "blocked" ? "󰅖" : (root.queueState === "active" ? "󰔟" : "󰄬")
      color: root.stateColor
      font.family: root.fontFamily
      font.pixelSize: Style.font.subtitle
    }

    Column {
      id: labels
      width: parent.width - Style.space(28)
      spacing: Style.space(2)

      Row {
        width: parent.width
        spacing: Style.space(7)

        Text {
          id: ticketId
          text: "#" + (root.ticket ? String(root.ticket.id || "") : "")
          textFormat: Text.PlainText
          color: root.stateColor
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          font.bold: true
        }

        Text {
          width: parent.width - ticketId.width - parent.spacing
          text: root.ticket ? String(root.ticket.title || "Untitled ticket") : ""
          textFormat: Text.PlainText
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          font.bold: root.queueState === "active"
          elide: Text.ElideRight
        }
      }

      Text {
        width: parent.width
        text: Model.ticketMeta(root.ticket)
        textFormat: Text.PlainText
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        elide: Text.ElideRight
      }

      Text {
        visible: root.progress !== ""
        width: parent.width
        text: root.progress
        textFormat: Text.PlainText
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        elide: Text.ElideRight
      }
    }
  }
}
