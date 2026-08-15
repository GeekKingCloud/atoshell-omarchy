# Repository guidance

This repository contains only the Omarchy Quattro integration for Atoshell. The authoritative Atoshell CLI, ticket model, queue ranking, blockers, and storage behavior live in the separate `GeekKingCloud/atoshell` repository.

## Scope

- Keep this plugin a small, read-only queue monitor.
- Do not copy Atoshell ticket or ranking logic into QML or this repository.
- Read queue state only through documented Atoshell JSON commands.
- Do not parse or mutate `.atoshell` files directly.
- Do not add ticket mutation, agent orchestration, a database, or a daemon without an explicit product decision.
- Keep all process invocations as argument arrays; never interpolate project paths into shell command strings.
- Preserve the last good snapshot when a refresh fails and visibly mark it stale.
- Render Atoshell-provided text as plain text.

## Integration boundary

`bin/atoshell-snapshot` locates `atoshell` through `PATH`, runs it from the configured project directory, and emits one normalized JSON envelope for `Service.qml`. Changes to that envelope require synchronized adapter, QML model, fixture, and contract-test updates.

For changes to Atoshell CLI semantics or JSON output, make the source change and tests in the Atoshell repository first. This repository should adapt to that public contract rather than reimplement it.

## Quattro conventions

- Target Omarchy Quattro v4.0.0 or newer.
- Prefer components from `qs.Ui` and tokens from `qs.Commons` over custom surfaces or hard-coded styling.
- Keep the bar widget quiet and glanceable; detailed information belongs in the keyboard panel.
- Preserve multi-monitor behavior, outside-click dismissal, keyboard navigation, and active-theme inheritance.

## Verification

Run from the repository root:

```bash
bash tests/test-snapshot.sh
python3 tests/test-contract.py
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qmlscene tests/model-smoke.qml
shellcheck -x bin/atoshell-snapshot tests/test-snapshot.sh
omarchy plugin validate .
```

For UI changes, also load the plugin through real Quickshell against the pinned Quattro component tree and inspect the closed and open states. Do not treat the HTML reference preview as runtime verification.

## Publishing

The plugin is intended to remain a dedicated one-plugin repository so Omarchy can clone, validate, enable, and update it normally. Cross-link it with the main Atoshell repository; do not vendor either repository into the other.
