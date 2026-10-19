# vim-outline

A tiny, dependency-free Markdown outline for Vim.

- Sidebar outline of ATX and Setext headings
- VOoM-style level markers (`. ` and `|`) make the hierarchy easy to scan
- Native search and navigation: `/`, `?`, `n`, `N`, `j`, `k`
- `<CR>` jumps to the heading in the Markdown buffer
- `<Tab>` switches between the outline and the document
- Configurable depth and width
- Follows the active Markdown buffer and refreshes after edits
- Per-tab outlines
- No Python, no external commands, no plugin dependencies

## Requirements

Vim 8.2 or newer. On Vim 9.1+ the parser uses the built-in
`matchbufline()` C function, so only a single fast scan of the buffer is
needed. Older versions use a Vimscript fallback.

## Installation

Copy or link this repository into your `runtimepath`, for example:

```sh
git clone https://github.com/kemenion/vim-outline \
  ~/.vim/pack/plugins/start/vim-outline
```

Or use any plugin manager that can add a local/remote plugin directory.

No mappings are installed globally. Add one if you like:

```vim
nnoremap <silent> <Leader>v :V<CR>
```

## Usage

Open any buffer and run:

```vim
:V
```

The outline opens on the left and focus moves into it. For a Markdown buffer,
its headings are listed. In a non-Markdown buffer, the outline opens as an
empty sidebar instead of reporting an error. Run `:V` again (from either
window) to close it.

Headings are decorated by level, using the same style as the old VOoM plugin:

```text
  |Project
  . |Install
  . . |Deep
```

```vim
:V 40
```

opens the outline at width 40, or resizes an already open outline to width 40.

Inside the outline:

| Key | Action |
| --- | --- |
| `j` / `k` | Move down / up using normal Vim motions |
| `/` `?` `n` `N` | Native Vim search |
| `<CR>` | Jump to the heading in the Markdown buffer |
| `<Tab>` | Switch between the outline and the document |
| `q` | Close the outline |

`<Tab>` only switches windows; it does not move the document cursor. It also
works from the empty outline of a non-Markdown buffer. When you return from the
document, the outline cursor and view are restored. `<CR>` remains the key that
jumps to the selected heading.

The outline stays open when you jump. Search is plain Vim search, so
`incsearch`, `hlsearch`, and all your normal search settings work.

## Configuration

```vim
" Show headings up to level 3 (1-6). Default: 3
let g:v_outline_depth = 3

" Outline width in columns (minimum 10). Default: 30
let g:v_outline_width = 30

" Key used to switch between outline and document. Default: <Tab>
let g:v_outline_tab_key = '<Tab>'
```

Changing `g:v_outline_depth` while an outline is open takes effect on the next
refresh. Run `:Vrefresh` to force it immediately.

The outline/document `<Tab>` mapping is buffer-local and only active while an
outline is open. Insert mode is not affected. If the document buffer already
has its own buffer-local `<Tab>` mapping, it is saved and restored when the
outline closes.

All heading levels use the same color: the heading text uses the
`VOutlineHeading` highlight group, which is linked to `Function` by default
(the same color as level-2 headings used before). The `. ` indents and `|`
separators use the `VOutlineTree` highlight group, which is linked to `NonText`
by default. Override either group to change its color.

The outline follows the current buffer in each tab. Markdown headings are
shown; non-Markdown buffers show an empty outline. Editing a heading updates
the outline automatically after a short debounce; there is no need to run a
command by hand.

## What is supported

- ATX headings: `#` through `######`
- Setext headings: text underlined with `===` (level 1) or `---` (level 2)
- VOoM-compatible ATX headings without a space after the hashes (`#Title`)
- Optional closing hashes (`# Title ###`)
- Headings indented by up to three spaces
- Ideographic and non-breaking spaces after the hashes are accepted
- Fenced code blocks (backtick or tilde fences) are skipped, so `#` lines
  and Setext underlines inside code blocks are not treated as headings
- YAML front matter at the top of the file is ignored
- Markdown is detected by `filetype=markdown` or by common extensions
  (`.md`, `.markdown`, `.mdown`, `.mkd`)

Intentionally not supported: HTML blocks and inline Markdown rendering.
Heading text is displayed as written (links, emphasis, and code spans are
not formatted).

## Performance

On Vim 9.1+ the parser does not walk the entire document in Vimscript: a
single `matchbufline()` call finds only candidate heading/fence/underline
lines. Results are cached by `changedtick`, and refresh is debounced while
typing.
A 100,000-line Markdown file with about 2,000 headings opened and refreshed in
roughly 70 ms in a Vim 9.1 test on Linux.

## License

MIT. See [LICENSE](LICENSE).
