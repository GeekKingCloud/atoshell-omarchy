# UI research and v1 rationale

Research target: Omarchy **v4.0.0 (Quattro)**, released 2026-08-14. The implementation is based on the tagged source rather than screenshots or a generic “dark terminal” interpretation.

## Product posture

This is a **Monitor** surface first and an **Inspect** surface second:

- answer “what are the agents doing, what comes next, and what is stuck?” in one glance;
- keep ticket mutations in Atoshell and agent workflows;
- show progress already present in Atoshell (accountable agent + latest comment) rather than inventing process telemetry;
- stay useful when the panel is left open beside a coding session.

A kanban board, ticket editor, charts, and remote integrations would make the wrong surface and duplicate Atoshell.

## Authoritative Quattro findings

### Plugin lifecycle

Omarchy's [Shell Plugins manual at v4.0.0](https://github.com/basecamp/omarchy/blob/v4.0.0/manual/32-shell-plugins.md) establishes:

- a third-party plugin is one Git repository with `manifest.json` at its root;
- plugins install to `~/.config/omarchy/plugins/<id>/`;
- plugin code is unsandboxed inside the long-running shell;
- installation clones, validates, and enables; there is no install hook or sudo;
- updates are fast-forward Git pulls with validation and rollback;
- edits under the plugin directory hot-reload;
- a plugin may combine `bar-widget` and `service` kinds.

**Decision:** ship as a separate repository. Embedding it in Atoshell release assets would work against Omarchy's clone/update model and make installation bespoke. The repositories should cross-link, but remain separately versioned.

### Theme and tokens

The tagged [`Style.qml`](https://github.com/basecamp/omarchy/blob/v4.0.0/shell/Commons/Style.qml) and [`Color.qml`](https://github.com/basecamp/omarchy/blob/v4.0.0/shell/Commons/Color.qml) define the visual system:

- theme-bound roles: background, foreground, accent, urgent, muted, plus popup-specific text/background/border;
- system `monospace` alias, normally a Nerd Font, with 10/11/12/13/14/16/24/28 px semantic sizes at the default scale;
- spacing via `Style.space()` and named 2/3/4/6/8/10/12/14/18 px tokens, scaled with font and theme settings;
- corner radius comes from Hyprland rather than being hard-coded;
- default normal fill is 4%, hover/cursor fill 8%, selected fill 18%; cursor color transition is 60 ms;
- default horizontal bar is 26 px, with a 27 px icon slot and 16 px optical canvas.

**Decision:** production QML contains no hex colors and no independent font, radius, shadow, or spacing system. It binds to `Color`, `Style`, `Border`, and the live bar.

### Panel composition

The first-party [`omarchy.agents` panel](https://github.com/basecamp/omarchy/blob/v4.0.0/shell/plugins/agents/Panel.qml) is the closest reference surface. It uses:

- `BarIconButton` → `KeyboardPanel`;
- a 380 px content target and 640 px height cap;
- `PanelHero`, section headers, separators, a clipped `Flickable`, and explicit empty states;
- keyboard focus on open, arrows/tab/Escape, and direct single-letter refresh;
- restrained motion tied to state rather than decorative entrance sequences.

The shared [`PanelHero`](https://github.com/basecamp/omarchy/blob/v4.0.0/shell/Ui/PanelHero.qml) uses a 24 px mark, 14 px bold title, uppercase 10 px metadata with 1.2 px tracking, 14 px icon-to-copy gap, and compact trailing controls.

The shared [`CursorSurface`](https://github.com/basecamp/omarchy/blob/v4.0.0/shell/Ui/CursorSurface.qml) requires mouse hover and keyboard cursor to resolve to one visual state rather than painting independent highlights.

**Decision:** use the same primitives and interaction grammar. Width is 420 px rather than 380 because ticket titles, agent identity, and progress comments form a denser text hierarchy; the height cap remains 640 px.

### Window behavior

[`KeyboardPanel.qml`](https://github.com/basecamp/omarchy/blob/v4.0.0/shell/Ui/KeyboardPanel.qml) is a full-screen layer-shell surface with a visible card attached to the bar item. It handles focus priming, outside-click dismissal, screen fitting, bar-position-aware placement, and multi-monitor behavior.

**Decision:** do not create a custom popup window or animation. The plugin delegates those lifecycle and placement concerns to `KeyboardPanel`.

## Comparable plugin review

### omarchy-jira

[`tmn73/omarchy-jira`](https://github.com/tmn73/omarchy-jira) demonstrates that project-work UI can fit a native panel, but its remote Jira concerns—authentication, JQL/filter selection, avatars, and issue actions—produce much more configuration and chrome than a local Atoshell queue needs.

Useful pattern: concise issue rows and a service-backed panel.

Rejected for v1: remote-account setup, filter tabs, and action-heavy rows.

### omarchy-ticktick

[`SotoAugusto/omarchy-ticktick`](https://github.com/SotoAugusto/omarchy-ticktick) shows the cost of turning a glanceable task panel into an operator surface: quick add, completion, overdue logic, and account sync all compete with scanning.

Useful pattern: explicit loading/empty/error states and periodic refresh.

Rejected for v1: creation/completion controls and calendar/task-manager scope.

### omabench

[`modoterra/omabench`](https://github.com/modoterra/omabench) is a local developer-status panel. Its strongest lesson is to keep collection in a service and keep the panel theme-native and local-first.

Useful pattern: cheap local refresh and no external account dependency.

## Information hierarchy

1. **Bar glyph:** neutral when only ready work exists; accent when agents are active; urgent when blocked work exists. Tooltip carries counts so the bar keeps Quattro's icon-only rhythm.
2. **Hero:** Atoshell + current project + precise snapshot time. Refresh and project-terminal actions are compact trailing controls.
3. **Three-count strip:** Active / Ready / Blocked, all compact and equal in geometry. This is a queue legend, not a dashboard KPI treatment.
4. **Active:** first because it answers what agents are doing now. Bold title, accountable identity, latest progress comment.
5. **Up Next:** Atoshell-ranked ready work, preserving the CLI's order.
6. **Blocked:** urgent color and separate section, without dominating a healthy queue.
7. **Footer:** only keyboard help and overflow disclosure.

## State model

- **Loading:** quiet “Reading the queue…” copy; no fake zeroes.
- **Configured + empty:** “Queue clear” and the exact meaning of empty.
- **Configuration error:** actionable project-path setup guidance.
- **CLI/helper error with no data:** explicit error.
- **Refresh error with prior data:** preserve last good data and show a stale banner. Never translate “could not read” into “nothing queued.”
- **Refreshing:** rotate only the refresh glyph and update tooltip copy.

## Data and security decisions

- Use `atoshell list in-progress --json`, `list ready --json`, and `list blockers --json` rather than parsing `.atoshell` files or assuming customized status labels.
- Remove blocked IDs from Ready in the adapter; the sections are mutually understandable even if Atoshell's ready scope includes blocked tickets.
- Pass commands as argv arrays. The only shell boundary is the checked-in helper, which changes directory with `cd -- "$project"`.
- Render all ticket-controlled strings with `Text.PlainText`.
- No network access, tokens, telemetry, install hook, or write command.

## Motion posture

- Quattro's built-in cursor-color transition handles row navigation.
- Refresh uses one 900 ms rotation while work is in flight.
- No pulsing agent indicators, skeleton shimmer, scrolling marquees, or autonomous panel motion.
- Updates replace data in place instead of reordering with entrance animation.

## Slop diagnostic

**Score: 0/10.** No gradient, generic indigo, feature-tile marketing grid, decorative accent rail, blur, monument stats, repeated icon toppers, center-stack composition, default web typography, or wrong-surface hero. The compact summary cells are operational queue state, not ornamental KPIs.

## V1 boundary

Included:

- one configured project;
- active, ranked ready, and blocked queues;
- agent attribution and latest comment;
- 3-second open / configurable idle polling;
- theme-native bar, panel, keyboard behavior, and all core states;
- project-terminal shortcut.

Deferred until dogfooding proves a need:

- multi-project discovery/switching;
- file watches replacing polling;
- ticket details inspector;
- ticket mutations;
- desktop notifications;
- agent process/runtime telemetry outside Atoshell.
