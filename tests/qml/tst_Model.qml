import QtQuick
import QtTest
import "../../Model.js" as Model

TestCase {
  name: "AtoshellModel"

  function test_assigneeLabel() {
    compare(Model.assigneeLabel({ accountable: ["agent-2"] }), "agent-2")
    compare(Model.assigneeLabel({ accountable: ["[agent]"] }), "agent")
    compare(Model.assigneeLabel({ accountable: [] }), "unassigned")
  }

  function test_ticketMeta() {
    compare(Model.ticketMeta({ priority: "P1", size: "M", accountable: ["agent-2"] }), "P1  ·  M  ·  agent-2")
  }

  function test_latestProgress() {
    var ticket = { comments: [
      { author: "agent-1", text: "Started" },
      { author: "agent-2", body: "Tests passing" }
    ] }
    compare(Model.latestProgress(ticket), "agent-2: Tests passing")
    compare(Model.latestProgress({ comments: [] }), "")
  }

  function test_flattenedRows() {
    var data = {
      active: [{ id: 1 }],
      ready: [{ id: 2 }, { id: 3 }],
      blocked: [{ id: 4 }]
    }
    var rows = Model.navigationRows(data)
    compare(rows.length, 4)
    compare(rows[0].section, "active")
    compare(rows[3].ticket.id, 4)
  }

  function test_autoTextSafe() {
    compare(Model.autoTextSafe("<b>project</b>"), "‹b›project‹/b›")
  }

  function test_blockedReason() {
    compare(Model.blockedReason({blocked_by: [{id: 14, title: "Resolve lock"}]}), "Blocked by #14 Resolve lock")
    compare(Model.blockedReason({blocked_by: []}), "")
  }
}
