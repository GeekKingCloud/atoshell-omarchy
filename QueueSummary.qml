import QtQuick
import qs.Commons

Row {
  id: root

  property var counts: ({ active: 0, ready: 0, blocked: 0 })
  property color foreground: Color.popups.text
  property string fontFamily: Style.font.family

  width: parent ? parent.width : implicitWidth
  spacing: Style.space(6)

  Repeater {
    model: [
      { label: "ACTIVE", value: Number(root.counts.active || 0), tone: Color.accent },
      { label: "READY", value: Number(root.counts.ready || 0), tone: root.foreground },
      { label: "BLOCKED", value: Number(root.counts.blocked || 0), tone: Color.urgent }
    ]

    Rectangle {
      required property var modelData
      width: (root.width - root.spacing * 2) / 3
      height: Style.space(52)
      radius: Style.cornerRadius
      color: Style.normalFillFor(modelData.tone, Color.accent)

      Column {
        anchors.centerIn: parent
        spacing: Style.space(1)

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: String(modelData.value)
          color: modelData.tone
          font.family: root.fontFamily
          font.pixelSize: Style.font.title
          font.bold: true
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: modelData.label
          color: Qt.darker(root.foreground, 1.45)
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: true
          font.letterSpacing: 0.8
        }
      }
    }
  }
}
