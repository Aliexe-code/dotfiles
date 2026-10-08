# ADR 001 — Reclaim <leader>z for Zig IDE

Date: 2026-09-17
Status: Accepted

## Context
`init.lua:342` used `<leader>z` for Zoom (`zi`/`zo`/`z0`, which-key `[Z]oom`). User wants `space+z+run,build,test` for Zig, matching `<leader>v` (V) and `<leader>o` (Odin) patterns `lua/custom/plugins/vlang.lua:162`/`odin.lua:150`. On NVIM 0.12.5 with `vim.pack`, leader is `space`.

## Decision
- Move Zoom to `<leader>Z` (`Zi`/`Zo`/`Z0`, `+`/`-`) and `<leader>tz` legacy, keep `Ctrl+=/-` zoom `init.lua:330`.
- Free `<leader>z` for Zig group `[Z]ig` in `lua/custom/plugins/zig.lua:1` with `which-key` registration.
- `init.lua:352` updated from `{ '<leader>z', group = '[Z]oom' }` to `{ '<leader>Z', group = '[Z]oom' }`.

## Consequences
- Existing Zoom muscle memory shifts to `<leader>Z`; `Ctrl+=/-` unchanged.
- `<leader>z` mnemonic now consistent: `v`→V, `o`→Odin, `z`→Zig.
- Which-key shows two distinct groups, no clash.
