# ADR 002 — Auto-detect build.zig vs file-mode

Date: 2026-09-17
Status: Accepted

## Context
Zig has two modes: project (`build.zig`/`build.zig.zon` with `zig build`, `zig build test`, `zig build run`) and single file (`zig run`, `zig build-exe`, `zig test`). Benchmarks `benchmarks/cpu/primes/zig/main.zig:1` are file-mode, but `zig init` projects use `build.zig`.

## Decision
`lua/custom/plugins/zig.lua:1` `project_root()` finds `build.zig`/`build.zig.zon` upward. Helpers auto-switch:
- `zr` Run: if `has_build_zig(root)` → `zig build run`, else `zig run <file>`
- `zb` Build: if project → `zig build -Doptimize=ReleaseFast`, else `zig build-exe -O ReleaseFast -femit-bin=out`
- `zt` Test: if project → `zig build test`, else `zig test <file>`
- `zB` prompts Optimize picker for both modes.

## Consequences
- Covers `v-vs-odin-benchmark` file benchmarks and future `zig init` without user switch.
- `zig build` args may need project-specific `-Doptimize`; default `ReleaseFast` matches bench `environment/optimization-flags.md:1`.
