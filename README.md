# vim-outline

A tiny, dependency-free Markdown outline for Vim.

- Sidebar outline of ATX and Setext headings
- VOoM-style level markers (`. ` and `|`) make the hierarchy easy to scan
- Native search and navigation: `/`, `?`, `n`, `N`, `j`, `k`
- `<CR>` centers the selected heading in the document, focus stays in the outline
- `<Tab>` jumps to the selected heading, or switches back to the outline
- Configurable depth and width
- Follows the active Markdown buffer and refreshes after edits
- Per-tab outlines
- Compact Markdown source highlighting whose H1 matches the outline green
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
| `<CR>` | Center the selected heading in the document (focus stays in the outline) |
| `<Tab>` | Jump to the selected heading; from the document, switch back to the outline |
| `q` | Close the outline |

`<CR>` previews the heading: the document window scrolls so that the heading is
in the middle, but the cursor stays in the outline. Press `<Tab>` to move into
the document at that heading. `<Tab>` from the document switches back to the
outline and restores its cursor and view. On the empty outline of a non-Markdown
buffer, `<Tab>` only switches windows.

The outline stays open when you jump. Search is plain Vim search, so
`incsearch`, `hlsearch`, and all your normal search settings work.

## Configuration

```vim
" Show headings up to level 3 (1-6). Default: 3
let g:v_outline_depth = 3

" Outline width in columns (minimum 10). Default: 30
let g:v_outline_width = 30

" Key used to jump to the selected heading / switch back. Default: <Tab>
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

## Markdown source highlighting

When this plugin comes before `$VIMRUNTIME` in `runtimepath`, its compact
`syntax/markdown.vim` is used for Markdown buffers. It covers the syntax that is
common in notes without loading a large external grammar:

- ATX and Setext headings with level-specific colors
- YAML front matter
- fenced backtick/tilde code blocks, including the info-string language
- inline code, escapes, bold, italic, bold-italic, and strikethrough
- links, images, reference links, autolinks, bare URLs, and footnotes
- HTML tags/entities, list and task-list markers, blockquotes, rules, and tables

The H1 foreground deliberately uses a green matched to the outline's default
`VOutlineHeading` color (`#9ece6a`), so headings in the document and in the
outline read as one system.
Lower levels move through teal, cyan, blue, and muted purple; delimiters and
punctuation remain dim so body text stays dominant. The palette is a cool
low-glare dark theme and also provides 256-color fallbacks.

```vim
" Set to 0 to fall back to Vim's built-in Markdown syntax.
let g:v_outline_markdown_syntax = 1

" Make all Markdown heading levels follow VOutlineHeading as well.
let g:v_outline_markdown_unified_headings = 0

" Optional overrides.  A value is [gui-fg, cterm-fg, attrs, gui-bg, cterm-bg];
" only the first two entries are required.
let g:v_outline_markdown_palette = {
      \ 'markdownH1': ['#9ece6a', '149', 'bold'],
      \ 'markdownCode': ['#e0af68', '179', '', '#1f2335', '235'],
      \ }

" Files up to this many lines get exact from-start synchronization.
let g:v_outline_markdown_fromstart_limit = 5000

" Bounded context for larger files; keeps scrolling cheap.
let g:v_outline_markdown_minlines = 200

" Always parse from the start (exact, but O(file size)).
let g:v_outline_markdown_fromstart = 0
```

Large files do not parse from line 1 on every redraw: the highlighter uses
bounded syntax synchronization with a one-line break limit. In a local Vim 9.1
benchmark on a 100,000-line Markdown file, opening and forcing syntax parsing at
the end of the buffer was faster than Vim's stock Markdown syntax; ordinary
notes still use exact from-start synchronization by default.

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
