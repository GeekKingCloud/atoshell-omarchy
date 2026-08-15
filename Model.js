.pragma library

function text(value) {
  return value === undefined || value === null ? "" : String(value)
}

// Some shared Quattro components own their Text item and leave it in AutoText
// mode. Keep project/error labels from being interpreted as rich text there.
function autoTextSafe(value) {
  return text(value).replace(/</g, "‹").replace(/>/g, "›")
}

// Nested arrays arriving through QML var properties can be array-like
// QJSValues rather than native JavaScript arrays. Normalize both shapes.
function list(value) {
  if (!value || typeof value.length !== "number") return []
  var result = []
  for (var i = 0; i < value.length; i++) result.push(value[i])
  return result
}

function assigneeLabel(ticket) {
  var people = ticket ? list(ticket.accountable) : []
  if (people.length === 0) return "unassigned"
  var label = text(people[0])
  return label === "[agent]" ? "agent" : label.replace(/^@/, "")
}

function ticketMeta(ticket) {
  var parts = []
  if (ticket && text(ticket.priority)) parts.push(text(ticket.priority))
  if (ticket && text(ticket.size)) parts.push(text(ticket.size))
  parts.push(assigneeLabel(ticket))
  return parts.join("  ·  ")
}

function latestProgress(ticket) {
  var comments = ticket ? list(ticket.comments) : []
  if (comments.length === 0) return ""
  var comment = comments[comments.length - 1] || {}
  var body = text(comment.text || comment.body).replace(/\s+/g, " ").trim()
  if (body === "") return ""
  var author = text(comment.author).replace(/^@/, "")
  return author === "" ? body : author + ": " + body
}

function blockedReason(ticket) {
  var blockers = list(ticket && ticket.blocked_by)
  if (blockers.length === 0) return ""
  var labels = blockers.map(function(blocker) {
    var id = text(blocker && blocker.id)
    var title = text(blocker && blocker.title)
    return (id ? "#" + id : "") + (id && title ? " " : "") + title
  }).filter(function(label) { return label !== "" })
  return labels.length ? "Blocked by " + labels.join(", ") : ""
}

function navigationRows(snapshot) {
  var rows = []
  var sections = ["active", "ready", "blocked"]
  for (var s = 0; s < sections.length; s++) {
    var name = sections[s]
    var tickets = snapshot ? list(snapshot[name]) : []
    for (var i = 0; i < tickets.length; i++) rows.push({ section: name, ticket: tickets[i] })
  }
  return rows
}

function barTooltip(snapshot, refreshing) {
  if (refreshing) return "Refreshing Atoshell queue"
  if (!snapshot || snapshot.state === "loading") return "Atoshell queue"
  if (snapshot.state !== "ok") return text(snapshot.message) || "Atoshell queue unavailable"
  var c = snapshot.counts || {}
  if ((c.active || 0) === 0 && (c.ready || 0) === 0 && (c.blocked || 0) === 0) return "Atoshell queue is clear"
  return (c.active || 0) + " active  ·  " + (c.ready || 0) + " ready  ·  " + (c.blocked || 0) + " blocked"
}
