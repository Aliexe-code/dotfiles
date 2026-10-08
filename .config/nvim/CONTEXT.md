# CONTEXT.md — Neovim Zig IDE

Date: 2026-09-17
Host: CachyOS, NVIM 0.12.5 (vim.pack), Zig 0.16.0, ZLS (probe Mason/pacman/source)

## Glossary

- **Leader** — `space` (`vim.g.mapleader = ' '` `init.lua:98`). All IDE actions under `<leader>`.
- **Zig IDE** — `lua/custom/plugins/zig.lua:1` owns Zig: ZLS LSP, `zig` CLI, `build.zig` vs file mode.
- **Project root** — nearest `build.zig` / `build.zig.zon` upward, else `.git`, else file dir. Used for `zig build` vs `zig run` auto-detect.
- **ZLS** — Zig Language Server. Probed `mason/bin/zls` → `zls` on PATH. Config `init.lua:939` `zls` entry, `filetypes = { zig, zir }`, `root_markers = { build.zig, build.zig.zon, .git }`.
- **Zoom** — previous `<leader>z` `[Z]oom` `init.lua:342` now on `<leader>Z` (`Zi`/`Zo`/`Z0`) + `Ctrl+=/-` to free `<leader>z` for Zig.
- **Treesitter** — `init.lua:1184` parsers include `zig` (`v,odin,go,zig`).
- **Format** — `conform.nvim` `init.lua:1026` : `enabled_filetypes.zig = true`, `formatters_by_ft.zig = { zigfmt, lsp_fallback }`, `formatters.zigfmt = zig fmt $FILENAME` `stdin=false`.

## Decisions (see ADRs)

- ADR-001: Reclaim `<leader>z` for Zig (`<leader>Z` for Zoom)
- ADR-002: Auto-detect `build.zig` vs file-mode for run/build/test
- ADR-003: ZLS via Mason-first, fallback to pacman/source with mismatch warning
- ADR-004: `conform` file-mode `zig fmt` + LSP fallback, diagnostics via ZLS only

## Keymaps — `<leader>z` group

`zr` Run, `zR` Run with args, `zb` Build ReleaseFast, `zB` Build pick (Debug/Safe/Small/native), `zt` Test, `za` Ast-check, `zc` Check, `zf` Format, `zF` Fetch, `zi` Init, `zv` Version/env, `zd`/`zD` diagnostics, `zs`/`zS` symbols, `zh`/`zH` hover, `zA` code_action, `zn` rename, `zg` goto def, `zq` quickfix. Toggleterm float `direction=float` same as `vlang.lua:66`/`odin.lua:43`.

## Verification

- `zig version` 0.16.0, `zls --version` should match minor (if 0.15.1, `checkhealth` will warn, build from source: `git clone https://github.com/zigtools/zls && zig build -Doptimize=ReleaseFast`)
- `:Mason` should list `zls` if registry has it; else `pacman -S zls` (CachyOS) then `:checkhealth lsp`
- `:Telescope keymaps` shows `<leader>z` Zig group, `<leader>Z` Zoom group
