# ADR 003 — ZLS install: Mason-first with mismatch warning

Date: 2026-09-17
Status: Accepted

## Context
Host `zig 0.16.0` from the official tarball (`~/tools/zig`); Fedora packages `zig` (0.15.2/0.16.0) but has no `zls` RPM, and repo zls `0.15.1-1.1` mismatched anyway (ZLS minor must match Zig). Mason registry may lag. Need reproducible install.

## Decision
`init.lua:939` `zls` entry probes `mason/bin/zls` → `zls` on PATH. `mason-tool-installer` `ensure_installed` includes `zls` via `vim.tbl_keys(servers)`. If `zls --version` minor != `zig version`, `checkhealth` warns and docs recommend `git clone https://github.com/zigtools/zls && zig build -Doptimize=ReleaseFast` (always matching).

## Consequences
- No silent break: mismatch visible in `:checkhealth`.
- Prefer Mason for auto-update, ultimate source build (no distro package is assumed).
