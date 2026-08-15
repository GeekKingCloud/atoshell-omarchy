import QtQuick 2.15
import QtQuick.Window 2.15
import "../Model.js" as Model

Window {
  visible: false
  function check(actual, expected, label) {
    if (actual !== expected) {
      console.error(label + ": expected " + expected + ", got " + actual)
      Qt.exit(1)
    }
  }

  Timer {
    interval: 0
    running: true
    repeat: false
    onTriggered: {
    check(Model.assigneeLabel({ accountable: ["agent-2"] }), "agent-2", "numbered agent")
    check(Model.assigneeLabel({ accountable: {0:"agent-qml", length:1} }), "agent-qml", "array-like QML agent list")
    check(Model.assigneeLabel({ accountable: ["[agent]"] }), "agent", "generic agent")
    check(Model.assigneeLabel({ accountable: [] }), "unassigned", "unassigned")
    check(Model.ticketMeta({ priority: "P1", size: "M", accountable: ["agent-2"] }), "P1  ·  M  ·  agent-2", "ticket meta")
    check(Model.latestProgress({ comments: [{author:"agent-1",text:"Started"},{author:"agent-2",body:"Tests passing"}] }), "agent-2: Tests passing", "latest comment")
    check(Model.latestProgress({ comments: {0:{author:"agent-qml",text:"Rendered"}, length:1} }), "agent-qml: Rendered", "array-like QML comments")
    check(Model.navigationRows({active:[{id:1}],ready:[{id:2}],blocked:[{id:3}]}).length, 3, "navigation rows")
    check(Model.autoTextSafe("<b>project</b>"), "‹b›project‹/b›", "shared AutoText surface escaping")
    check(Model.blockedReason({blocked_by:[{id:14,title:"Resolve lock"}]}), "Blocked by #14 Resolve lock", "blocked reason")
    console.log("model behavior: ok")
    Qt.quit()
    }
  }
}
