" vim-outline: a compact, fast Markdown highlighter.
"
" This file intentionally replaces Vim's runtime syntax/markdown.vim when the
" plugin directory comes before $VIMRUNTIME in 'runtimepath'.  It is designed
" for large notes: large buffers use a bounded syntax sync instead of parsing
" from the start of the file on every redraw.
"
" Set g:v_outline_markdown_syntax to 0 to fall back to Vim's built-in syntax.

if exists('b:current_syntax')
  finish
endif
if !get(g:, 'v_outline_markdown_syntax', 1)
  finish
endif

syntax clear
syntax case match

" --- Headings --------------------------------------------------------------

" ATX headings.  The level prefix and an optional closing sequence are
" delimiters; the heading text uses the per-level group.  #Title is accepted,
" matching vim-outline's parser.
syntax region markdownH1
      \ matchgroup=markdownH1Delimiter
      \ start=/^ \{0,3}#\%(#\)\@!/
      \ end=/[ \t]\+#\+[ \t]*$\|\ze$/
      \ oneline keepend
      \ contains=@markdownInline

syntax region markdownH2
      \ matchgroup=markdownH2Delimiter
      \ start=/^ \{0,3}##\%(#\)\@!/
      \ end=/[ \t]\+#\+[ \t]*$\|\ze$/
      \ oneline keepend
      \ contains=@markdownInline

syntax region markdownH3
      \ matchgroup=markdownH3Delimiter
      \ start=/^ \{0,3}###\%(#\)\@!/
      \ end=/[ \t]\+#\+[ \t]*$\|\ze$/
      \ oneline keepend
      \ contains=@markdownInline

syntax region markdownH4
      \ matchgroup=markdownH4Delimiter
      \ start=/^ \{0,3}####\%(#\)\@!/
      \ end=/[ \t]\+#\+[ \t]*$\|\ze$/
      \ oneline keepend
      \ contains=@markdownInline

syntax region markdownH5
      \ matchgroup=markdownH5Delimiter
      \ start=/^ \{0,3}#####\%(#\)\@!/
      \ end=/[ \t]\+#\+[ \t]*$\|\ze$/
      \ oneline keepend
      \ contains=@markdownInline

syntax region markdownH6
      \ matchgroup=markdownH6Delimiter
      \ start=/^ \{0,3}######\%(#\)\@!/
      \ end=/[ \t]\+#\+[ \t]*$\|\ze$/
      \ oneline keepend
      \ contains=@markdownInline

" Setext headings.  The title line and underline are one syntax match so the
" title is not accidentally treated as a normal paragraph.
syntax match markdownH1
      \ /^.\+\n=\{1,}[ \t]*$/
      \ contains=@markdownInline,markdownHeadingRule
syntax match markdownH2
      \ /^.\+\n-\{1,}[ \t]*$/
      \ contains=@markdownInline,markdownHeadingRule
syntax match markdownHeadingRule
      \ /^[=-]\+[ \t]*$/
      \ contained
" --- Rules, quotes, lists, and tables --------------------------------------

syntax match markdownRule
      \ /^ \{0,3}\%(\*[ \t]*\)\{3,}$/
syntax match markdownRule
      \ /^ \{0,3}\%(-[ \t]*\)\{3,}$/
syntax match markdownRule
      \ /^ \{0,3}\%(_[ \t]*\)\{3,}$/

syntax match markdownBlockquote
      \ /^ \{0,3}>[ \t]*/

syntax match markdownListMarker
      \ /^ \{0,3}[-+*][ \t]\+/
      \ nextgroup=markdownTaskTodo,markdownTaskDone,markdownTaskOther skipwhite
syntax match markdownOrderedListMarker
      \ /^ \{0,3}\d\{1,9}[.)][ \t]\+/
      \ nextgroup=markdownTaskTodo,markdownTaskDone,markdownTaskOther skipwhite

" A table row must contain at least one non-delimiter character, otherwise it
" is the header separator line handled below.  Pipes are colored only when the
" line is actually shaped like a table row.
syntax match markdownTableRow
      \ /^ \{0,3}|.*[^|: \t-].*|[ \t]*$/
      \ contains=markdownTableDelimiter,@markdownInline
syntax match markdownTableSeparator
      \ /^ \{0,3}|[|: \t-]\+$/
syntax match markdownTableDelimiter
      \ /|/
      \ contained

" --- YAML front matter -----------------------------------------------------

syntax region markdownFrontmatter
      \ matchgroup=markdownFrontmatterDelimiter
      \ start=/\%^---[ \t]*$/
      \ end=/^\%(---\|\.\.\.\)[ \t]*$/
      \ keepend
      \ contains=markdownFrontmatterKey,markdownFrontmatterValue

syntax match markdownFrontmatterKey
      \ /^[ \t]*[A-Za-z0-9_.-]\+\ze:/
      \ contained
syntax match markdownFrontmatterValue
      \ /:.*$/
      \ contained

" --- Inline code and escapes -----------------------------------------------

syntax match markdownEscape
      \ /\\[\\`*_{}\[\]()#+\-.!>~|]/

syntax region markdownCode
      \ matchgroup=markdownCodeDelimiter
      \ start=/\z(`\+\)/
      \ end=/\z1/
      \ oneline keepend
      \ contains=NONE

" --- Emphasis --------------------------------------------------------------

" The negative lookarounds keep single * from stealing the leading * of **,
" and prevent _emphasis_ inside identifiers_like_this.
syntax region markdownBoldItalic
      \ matchgroup=markdownBoldItalicDelimiter
      \ start=/\*\*\*\S\@=/
      \ end=/\S\@<=\*\*\*/
      \ oneline keepend
      \ contains=markdownCode,markdownEscape
syntax region markdownBoldItalic
      \ matchgroup=markdownBoldItalicDelimiter
      \ start=/\%(^\|[^0-9A-Za-z_]\)\zs___\S\@=\%(_\)\@!/
      \ end=/\S\@<=___\w\@!/
      \ oneline keepend
      \ contains=markdownCode,markdownEscape

syntax region markdownBold
      \ matchgroup=markdownBoldDelimiter
      \ start=/\*\*\S\@=\%(\*\)\@!/
      \ end=/\S\@<=\*\*\%(\*\)\@!/
      \ oneline keepend
      \ contains=markdownItalic,markdownCode,markdownEscape
syntax region markdownBold
      \ matchgroup=markdownBoldDelimiter
      \ start=/\%(^\|[^0-9A-Za-z_]\)\zs__\S\@=\%(_\)\@!/
      \ end=/\S\@<=__\w\@!/
      \ oneline keepend
      \ contains=markdownItalic,markdownCode,markdownEscape

syntax region markdownItalic
      \ matchgroup=markdownItalicDelimiter
      \ start=/\%(^\|[^*]\)\zs\*\%(\*\)\@!\S\@=/
      \ end=/\S\@<=\*\%(\*\)\@!/
      \ oneline keepend
      \ contains=markdownCode,markdownEscape
syntax region markdownItalic
      \ matchgroup=markdownItalicDelimiter
      \ start=/\%(^\|[^0-9A-Za-z_]\)\zs_\S\@=\%(_\)\@!/
      \ end=/\S\@<=_\w\@!/
      \ oneline keepend
      \ contains=markdownCode,markdownEscape

syntax region markdownStrike
      \ matchgroup=markdownStrikeDelimiter
      \ start=/\~\~\S\@=/
      \ end=/\S\@<=\~\~/
      \ oneline keepend
      \ contains=markdownCode,markdownEscape

" --- Links, images, URLs, and HTML -----------------------------------------

syntax region markdownImage
      \ matchgroup=markdownImageDelimiter
      \ start=/!\[/
      \ end=/\]/
      \ oneline keepend
      \ contains=@markdownInlineText
      \ nextgroup=markdownLinkUrl,markdownLinkRef skipwhite

syntax region markdownLinkText
      \ matchgroup=markdownLinkDelimiter
      \ start=/\[/
      \ end=/\]/
      \ oneline keepend
      \ contains=@markdownInlineText
      \ nextgroup=markdownLinkUrl,markdownLinkRef skipwhite

syntax region markdownLinkUrl
      \ matchgroup=markdownLinkUrlDelimiter
      \ start=/(/
      \ end=/)/
      \ oneline keepend
      \ contained
      \ contains=NONE

syntax region markdownLinkRef
      \ matchgroup=markdownLinkRefDelimiter
      \ start=/\[/
      \ end=/\]/
      \ oneline keepend
      \ contained
      \ contains=NONE

syntax match markdownAutomaticLink
      \ /<\%(https\?\|ftp\):\/\/[^<> \t]\+>/
syntax match markdownUrl
      \ /\%(https\?\|ftp\):\/\/[^<> \t]*/
syntax match markdownFootnote
      \ /\[\^[^]]\+\]/

syntax match markdownLinkRefDef
      \ /^ \{0,3}\[[^]]\+\]:[ \t]*/
      \ nextgroup=markdownUrl skipwhite

syntax match markdownHtmlTag
      \ /<\/\?[A-Za-z][A-Za-z0-9-]*\%(\s[^<>]*\)\?\/\?>/
syntax match markdownHtmlEntity
      \ /&\%(#[0-9]\+\|[A-Za-z][A-Za-z0-9]*\);/

syntax cluster markdownInlineText contains=
      \ markdownCode,markdownEscape,markdownBoldItalic,markdownBold,
      \ markdownItalic,markdownStrike,markdownAutomaticLink,markdownFootnote
syntax cluster markdownInline contains=
      \ @markdownInlineText,markdownLinkText,markdownImage,markdownUrl,
      \ markdownHtmlTag,markdownLinkRefDef

" --- Fenced code -----------------------------------------------------------

" Fenced code.  The external capture makes the closing fence at least as long
" as the opening one; extra closing characters are allowed by CommonMark.
syntax region markdownCodeBlock
      \ matchgroup=markdownCodeDelimiter
      \ start=/^ \{0,3}\z(`\{3,\}\)\ze[^`]*$/
      \ end=/^ \{0,3}\z1[`]*[ \t]*$/
      \ keepend
      \ contains=markdownCodeLanguage

syntax region markdownCodeBlock
      \ matchgroup=markdownCodeDelimiter
      \ start=/^ \{0,3}\z(\~\{3,\}\)\ze.*$/
      \ end=/^ \{0,3}\z1[~]*[ \t]*$/
      \ keepend
      \ contains=markdownCodeLanguage

syntax match markdownCodeLanguage
      \ /\%(^ \{0,3}`\{3,\}\)\@<=[^` \t].*/
      \ contained
syntax match markdownCodeLanguage
      \ /\%(^ \{0,3}\~\{3,\}\)\@<=[^~ \t].*/
      \ contained

" Optional; disabled by default because indented code is ambiguous with
" deeply nested lists.  Fenced code should be preferred in notes.
if get(g:, 'v_outline_markdown_indented_code', 0)
  syntax region markdownCodeBlock
        \ start=/^\%(\t\| \{4,}\)\S/
        \ end=/^\%( \{0,3}\S\|$\)/
        \ keepend
        \ contains=NONE
endif

" Task-list checkboxes.  Matching the box directly (instead of starting at
" the list marker) keeps priority over link text at the same column.
syntax match markdownTaskTodo /\[ \]/ contained
syntax match markdownTaskDone /\[[xX]\]/ contained
syntax match markdownTaskOther /\[-\]/ contained

" --- Highlight groups ------------------------------------------------------

" A cool, low-glare dark palette.  H1 deliberately matches the green used by
" VOutlineHeading; lower levels move through teal, cyan, and muted blue.
" Values are [gui foreground, cterm foreground, attributes, gui background,
" cterm background].  Entries may be shortened to two elements.
let s:palette = {
      \ 'markdownH1':          ['#9ece6a', '149', 'bold'],
      \ 'markdownH2':          ['#73daca', '80',  'bold'],
      \ 'markdownH3':          ['#7dcfff', '117', 'bold'],
      \ 'markdownH4':          ['#7aa2f7', '111', 'bold'],
      \ 'markdownH5':          ['#bb9af7', '141', 'bold'],
      \ 'markdownH6':          ['#a9b1d6', '146', 'bold'],
      \ 'markdownH1Delimiter': ['#565f89', '60'],
      \ 'markdownH2Delimiter': ['#565f89', '60'],
      \ 'markdownH3Delimiter': ['#565f89', '60'],
      \ 'markdownH4Delimiter': ['#565f89', '60'],
      \ 'markdownH5Delimiter': ['#565f89', '60'],
      \ 'markdownH6Delimiter': ['#565f89', '60'],
      \ 'markdownHeadingRule':  ['#565f89', '60'],
      \ 'markdownFrontmatterDelimiter': ['#565f89', '60'],
      \ 'markdownFrontmatterKey':       ['#7aa2f7', '111'],
      \ 'markdownFrontmatterValue':     ['#9ece6a', '149'],
      \ 'markdownCodeBlock':    ['#c0caf5', '252', '', '#1b2230', '235'],
      \ 'markdownCodeDelimiter': ['#565f89', '60'],
      \ 'markdownCodeLanguage': ['#7dcfff', '117', 'italic'],
      \ 'markdownCode':         ['#e0af68', '179', '', '#1f2335', '235'],
      \ 'markdownEscape':       ['#e0af68', '179'],
      \ 'markdownBold':         ['#f7768e', '204', 'bold'],
      \ 'markdownBoldDelimiter': ['#565f89', '60'],
      \ 'markdownBoldItalic':   ['#f7768e', '204', 'bold,italic'],
      \ 'markdownBoldItalicDelimiter': ['#565f89', '60'],
      \ 'markdownItalic':       ['#bb9af7', '141', 'italic'],
      \ 'markdownItalicDelimiter': ['#565f89', '60'],
      \ 'markdownStrike':       ['#737aa2', '60', 'strikethrough'],
      \ 'markdownStrikeDelimiter': ['#565f89', '60'],
      \ 'markdownLinkText':     ['#7aa2f7', '111'],
      \ 'markdownLinkDelimiter': ['#565f89', '60'],
      \ 'markdownImage':        ['#bb9af7', '141'],
      \ 'markdownImageDelimiter': ['#565f89', '60'],
      \ 'markdownLinkUrl':      ['#73daca', '80'],
      \ 'markdownLinkUrlDelimiter': ['#565f89', '60'],
      \ 'markdownLinkRef':      ['#7dcfff', '117'],
      \ 'markdownLinkRefDelimiter': ['#565f89', '60'],
      \ 'markdownAutomaticLink': ['#73daca', '80', 'underline'],
      \ 'markdownUrl':          ['#2ac3de', '80', 'underline'],
      \ 'markdownFootnote':     ['#bb9af7', '141'],
      \ 'markdownLinkRefDef':   ['#7aa2f7', '111'],
      \ 'markdownHtmlTag':      ['#f7768e', '204'],
      \ 'markdownHtmlEntity':   ['#e0af68', '179'],
      \ 'markdownListMarker':   ['#73daca', '80', 'bold'],
      \ 'markdownOrderedListMarker': ['#7dcfff', '117', 'bold'],
      \ 'markdownTaskTodo':     ['#e0af68', '179', 'bold'],
      \ 'markdownTaskDone':     ['#9ece6a', '149', 'bold'],
      \ 'markdownTaskOther':    ['#565f89', '60'],
      \ 'markdownBlockquote':   ['#565f89', '60'],
      \ 'markdownRule':         ['#565f89', '60'],
      \ 'markdownTableSeparator': ['#565f89', '60'],
      \ 'markdownTableDelimiter': ['#565f89', '60'],
      \ }


let s:user_palette = get(g:, 'v_outline_markdown_palette', {})
if type(s:user_palette) == type({})
  call extend(s:palette, s:user_palette)
endif

function! s:set_highlight(name, spec) abort
  if type(a:spec) != type([]) || len(a:spec) < 2
    return
  endif

  let l:cmd = 'highlight default ' . a:name
  if a:spec[0] !=# ''
    let l:cmd .= ' guifg=' . a:spec[0]
  endif
  if a:spec[1] !=# ''
    let l:cmd .= ' ctermfg=' . a:spec[1]
  endif
  if len(a:spec) > 4 && a:spec[3] !=# ''
    let l:cmd .= ' guibg=' . a:spec[3] . ' ctermbg=' . a:spec[4]
  endif
  if len(a:spec) > 2 && a:spec[2] !=# ''
    let l:cmd .= ' gui=' . a:spec[2] . ' cterm=' . a:spec[2]
  endif
  execute l:cmd
endfunction

for [s:group, s:spec] in items(s:palette)
  call s:set_highlight(s:group, s:spec)
endfor

if get(g:, 'v_outline_markdown_unified_headings', 0)
  for s:level in range(1, 6)
    execute 'highlight! link markdownH' . s:level . ' VOutlineHeading'
  endfor
endif

" --- Sync ------------------------------------------------------------------

" Parsing from the start is exact but O(file size); it is a good trade-off for
" ordinary notes only.  Large files use bounded incremental sync plus
" linebreaks, so a 100k-line buffer does not re-scan from line 1.
if get(g:, 'v_outline_markdown_fromstart', 0)
      \ || (get(g:, 'v_outline_markdown_fromstart_limit', 5000) > 0
      \     && line('$') <= get(g:, 'v_outline_markdown_fromstart_limit', 5000))
  syntax sync fromstart
else
  let s:minlines = max([20, get(g:, 'v_outline_markdown_minlines', 200)])
  execute 'syntax sync minlines=' . s:minlines
  syntax sync linebreaks=1
endif

let b:current_syntax = 'markdown'

