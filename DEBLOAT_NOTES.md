# Linutil Debloat Notes (No UI/Behavior Change Target)

## 1) Remove redundant `checkEscalationTool` calls
- `checkEnv` already invokes escalation setup in `core/tabs/common-script.sh`.
- Many scripts call both `checkEnv` and `checkEscalationTool` directly.
- Debloat action: remove direct `checkEscalationTool` call where immediately paired with `checkEnv`.
- Expected impact: line-count reduction with no functional change.

## 2) Remove redundant `common-script.sh` sourcing in monitor scripts
- Monitor-control scripts source both `../utility_functions.sh` and `../../common-script.sh`.
- But `utility_functions.sh` already sources `../common-script.sh`.
- Debloat action: remove duplicate `. ../../common-script.sh` from monitor-control scripts.
- Expected impact: cleaner dependency chain, no behavior change.

## 3) Consolidate duplicate `confirm_action` implementations
- `core/tabs/utils/monitor-control/disable_monitor.sh` defines local `confirm_action`.
- A shared `confirm_action` already exists in `utility_functions.sh`.
- Debloat action: drop local duplicate and use shared helper.
- Expected impact: consistency + fewer lines, same prompt behavior.

## 4) Simplify `set_resolutions.sh` temp-file flow
- Current flow includes read/append against the same temp file, making logic noisy and fragile.
- Debloat action: rewrite resolution list indexing/selection path more directly.
- Constraint: preserve prompt text and final `xrandr` action semantics.
- Expected impact: safer logic and lower script complexity.

## 5) Extract shared install/uninstall menu helper
- Emulator and design-tool scripts repeat near-identical menu scaffolding.
- Debloat action: introduce a common shell helper for 2-option install/uninstall menu handling.
- Migrate scripts in batches (emulators first, then design tools).
- Expected impact: significant line reduction and easier maintenance.

## 6) Normalize incorrect prompt ranges (`[1-3]` vs 2 options)
- Multiple scripts show `Enter your choice [1-3]` while only showing 2 menu items.
- Debloat action: align prompt range text with actual options.
- Expected impact: UX correctness with minimal change.

## Suggested execution order
1. Mechanical cleanup: items 1 and 2.
2. Monitor-control cleanup: items 3 and 4.
3. Shared abstraction + migration: items 5 and 6.
