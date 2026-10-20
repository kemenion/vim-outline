" vim-outline: a small, dependency-free Markdown outline.
" The parser only understands ATX headings (# .. ######) and skips fenced
" code blocks. It deliberately does not try to be a full Markdown parser.

let s:states = {}

" --- Small helpers ---------------------------------------------------------

function! s:state() abort
  let state = get(t:, 'v_outline_state', {})
  if !s:is_open(state)
    return {}
  endif
  for win in win_findbuf(state.tree)
    if win_id2tabwin(win)[0] == tabpagenr()
      return state
    endif
  endfor
  return {}
endfunction

function! s:is_markdown(buf) abort
  return getbufvar(a:buf, '&filetype') ==# 'markdown'
        \ || bufname(a:buf) =~? '\.\%(md\|markdown\|mdown\|mkd\)$'
endfunction

function! s:is_open(state) abort
  return !empty(a:state)
        \ && get(a:state, 'tree', 0) > 0
        \ && bufexists(a:state.tree)
        \ && !empty(win_findbuf(a:state.tree))
endfunction

function! s:tree_window(state) abort
  if empty(a:state) || get(a:state, 'tree', 0) <= 0
    return 0
  endif
  let wins = win_findbuf(a:state.tree)
  for win in wins
    if win_id2tabwin(win)[0] == tabpagenr()
      return win
    endif
  endfor
  return empty(wins) ? 0 : wins[0]
endfunction

function! s:body_window(state) abort
  let body = get(a:state, 'body', 0)
  if body <= 0 || !bufexists(body)
    return 0
  endif
  for win in win_findbuf(body)
    if win_id2tabwin(win)[0] == tabpagenr()
      return win
    endif
  endfor
  return 0
endfunction

" Keep the outline attached to the current buffer.  The body does not have to
" be Markdown; non-Markdown bodies keep working with the Tab toggle and simply
" render an empty outline.
function! s:follow(state, buf) abort
  if a:buf <= 0 || a:buf == a:state.tree || !bufexists(a:buf)
    return
  endif
  if get(a:state, 'body', 0) != a:buf
    let a:state.body = a:buf
    let a:state.tick = -1
    let a:state.reset_view = 1
  endif
  call s:map_body(a:state)
endfunction

" Install the document-local Tab mapping.  An existing buffer-local mapping is
" saved so it can be restored when the outline is closed.
function! s:map_body(state) abort
  let body = get(a:state, 'body', 0)
  if body <= 0 || body != bufnr('%') || body == a:state.tree
        \ || !bufexists(body)
    return
  endif

  let mapped = get(a:state, 'mapped_bodies', [])
  if index(mapped, body) < 0
    call add(mapped, body)
    let a:state.mapped_bodies = mapped
  endif

  let key = get(a:state, 'tab_key', '<Tab>')
  if get(b:, 'v_outline_body_tab_mapped', 0)
        \ && maparg(key, 'n') =~# 'v_outline#focus_tree'
    return
  endif

  if !get(b:, 'v_outline_body_tab_saved', 0)
    let saved = maparg(key, 'n', 0, 1)
    if !empty(saved) && get(saved, 'buffer', 0)
          \ && get(saved, 'rhs', '') !~# 'v_outline#focus_tree'
      let b:v_outline_body_saved_tab = saved
    endif
    let b:v_outline_body_tab_saved = 1
  endif

  execute 'nnoremap <buffer> <silent> ' . key
        \ . ' :<C-u>call v_outline#focus_tree()<CR>'
  let b:v_outline_body_tab_mapped = 1
  let b:v_outline_body_tab_key = key
endfunction

function! v_outline#detach_body() abort
  if !get(b:, 'v_outline_body_tab_mapped', 0)
    return
  endif

  let key = get(b:, 'v_outline_body_tab_key', '<Tab>')
  if maparg(key, 'n') =~# 'v_outline#focus_tree'
    execute 'silent! nunmap <buffer> ' . key
    let saved = get(b:, 'v_outline_body_saved_tab', {})
    if !empty(saved) && exists('*mapset')
      try
        call mapset('n', 0, saved)
      catch
      endtry
    endif
  endif

  unlet! b:v_outline_body_tab_mapped
  unlet! b:v_outline_body_tab_key
  unlet! b:v_outline_body_saved_tab
  unlet! b:v_outline_body_tab_saved
endfunction

function! s:detach_body(state) abort
  let bodies = copy(get(a:state, 'mapped_bodies', []))
  let body = get(a:state, 'body', 0)
  if body > 0 && index(bodies, body) < 0
    call add(bodies, body)
  endif

  for buf in bodies
    if buf <= 0 || !bufexists(buf)
      continue
    endif
    for win in win_findbuf(buf)
      call win_execute(win, 'call v_outline#detach_body()')
    endfor
  endfor
  let a:state.mapped_bodies = []
endfunction

function! s:open_body_window(state) abort
  let body = get(a:state, 'body', 0)
  if body <= 0 || !bufexists(body)
    return 0
  endif

  let win = s:body_window(a:state)
  if win > 0
    return win
  endif

  " Do not replace the tree window: its buffer is 'bufhidden=wipe'.
  let tree_win = s:tree_window(a:state)
  if tree_win <= 0
    return 0
  endif
  call win_gotoid(tree_win)
  silent! rightbelow vertical split
  execute 'silent! buffer ' . body
  if bufnr('%') != body
    silent! close
    return 0
  endif
  return win_getid()
endfunction

function! s:leave_tree(state) abort
  if bufnr('%') == get(a:state, 'tree', 0)
    let a:state.tree_view = winsaveview()
  endif
endfunction

" The document line for the outline line under the cursor.
function! s:heading_lnum(state) abort
  let lnums = getbufvar(a:state.tree, 'v_outline_lnums', [])
  return get(lnums, line('.') - 1, 0)
endfunction

" Center a document heading in window {win} without changing the current
" window.  noautocmd keeps preview-only cursor moves out of other plugins.
function! s:center_heading(win, lnum) abort
  try
    call win_execute(a:win, 'noautocmd call cursor(' . a:lnum . ', 1)')
    call win_execute(a:win, 'noautocmd normal! zvzz')
  catch
  endtry
endfunction

" The absolute cursor line in the tree belongs to the previous document.
" Put the new document's outline at the top and forget the old saved view.
function! s:reset_tree_view(state) abort
  let win = s:tree_window(a:state)
  if win > 0
    try
      call win_execute(win, 'normal! gg')
      call win_execute(win, 'normal! zt')
    catch
    endtry
  endif
  let a:state.tree_view = {}
endfunction

function! s:cleanup(state) abort
  if empty(a:state)
    return
  endif
  if get(a:state, 'timer', -1) != -1
    call timer_stop(a:state.timer)
    let a:state.timer = -1
  endif

  call s:detach_body(a:state)

  " Window-local matches outlive the scratch buffer if the window is reused.
  let win = get(a:state, 'tree_win', 0)
  if win > 0 && win_id2tabwin(win)[0] > 0
    for id in get(a:state, 'matches', [])
      try
        call win_execute(win, 'silent! call matchdelete(' . id . ')')
      catch
      endtry
    endfor
  endif

  let key = string(get(a:state, 'tree', -1))
  if has_key(s:states, key)
    call remove(s:states, key)
  endif
  if get(get(t:, 'v_outline_state', {}), 'tree', 0) == get(a:state, 'tree', 0)
    unlet! t:v_outline_state
  endif
endfunction

" --- Public entry points ---------------------------------------------------

function! v_outline#highlight() abort
  highlight default link VOutlineHeading Function
  highlight default link VOutlineTree NonText
  highlight default link VOutlineEmpty Comment
endfunction

function! v_outline#toggle(...) abort
  let state = s:state()

  if a:0 > 0 && a:1 !=# ''
    let width = str2nr(a:1)
    if width <= 0
      echoerr 'V: width must be a positive number'
      return
    endif
    let width = max([10, width])
    let g:v_outline_width = width
    if s:is_open(state)
      call s:resize(state, width)
      call s:refresh(state, 1)
      return
    endif
  elseif s:is_open(state)
    call s:close(state)
    return
  endif

  call s:open()
endfunction

function! v_outline#refresh() abort
  let state = s:state()
  if s:is_open(state)
    let buf = bufnr('%')
    if buf != state.tree
      call s:follow(state, buf)
    endif
    call s:refresh(state, 1)
  endif
endfunction

" --- Window and buffer setup ----------------------------------------------

function! s:open() abort
  let body = bufnr('%')

  let old = get(t:, 'v_outline_state', {})
  if !empty(old)
    call s:cleanup(old)
  endif

  let width = max([10, get(g:, 'v_outline_width', 30)])
  let last_win = win_getid()
  let tab_key = get(g:, 'v_outline_tab_key', '<Tab>')
  if tab_key ==# ''
    let tab_key = '<Tab>'
  endif

  leftabove vertical new
  silent! wincmd H

  let state = {
        \ 'body': body,
        \ 'tree': bufnr('%'),
        \ 'tree_win': win_getid(),
        \ 'last_win': last_win,
        \ 'matches': [],
        \ 'tick': -1,
        \ 'depth': -1,
        \ 'timer': -1,
        \ 'closing': 0,
        \ 'tab_key': tab_key,
        \ 'tree_view': {},
        \ 'reset_view': 0,
        \ 'mapped_bodies': [],
        \ }

  let state.matches = s:setup(tab_key)
  let t:v_outline_state = state
  let s:states[string(state.tree)] = state
  call s:resize(state, width)
  call s:refresh(state, 1)
endfunction

function! s:setup(tab_key) abort
  call v_outline#highlight()

  setlocal buftype=nofile
  setlocal bufhidden=wipe
  setlocal noswapfile
  setlocal undolevels=-1
  setlocal nobuflisted
  setlocal nonumber norelativenumber
  setlocal signcolumn=no
  setlocal foldcolumn=0
  setlocal nolist
  setlocal wrap linebreak breakindent
  setlocal breakindentopt=shift:2
  setlocal cursorline
  setlocal winfixwidth
  setlocal noscrollbind nocursorbind
  setlocal nospell
  setlocal nomodifiable
  setlocal statusline=%{b:v_outline_title}
  setlocal filetype=

  silent! execute 'file ' . fnameescape('[Outline:' . bufnr('%') . ']')
  let b:v_outline_lnums = []
  let b:v_outline_title = 'Outline'

  nnoremap <buffer> <silent> <CR> :<C-u>call v_outline#preview()<CR>
  execute 'nnoremap <buffer> <silent> ' . a:tab_key
        \ . ' :<C-u>call v_outline#focus_body()<CR>'
  nnoremap <buffer> <silent> q :<C-u>call v_outline#close()<CR>

  " All heading levels share one color; the level markers still show depth.
  let matches = []
  call add(matches, matchadd('VOutlineHeading', '^  \%(\. \)*\zs|.*', 10))
  call add(matches, matchadd('VOutlineTree', '^  \\zs\\%(\\. \\)*|', 15))
  call add(matches, matchadd('VOutlineEmpty', '^No headings$', 20))
  return matches
endfunction

function! s:resize(state, width) abort
  let win = s:tree_window(a:state)
  if win <= 0
    return
  endif
  call win_execute(win, 'silent! vertical resize ' . max([10, a:width]))
endfunction

" --- Parsing ---------------------------------------------------------------

" trim() is used for the tree text.  Vim's trim() only knows ASCII whitespace,
" but notes often contain an ideographic or non-breaking space after a hashes-
" only heading marker.  Remove those too.
let s:space_chars = ' \t\r\n' . nr2char(0x3000) . nr2char(0x00a0)
function! s:trim(text) abort
  let text = substitute(a:text, '^[' . s:space_chars . ']\+', '', '')
  return substitute(text, '[' . s:space_chars . ']\+$', '', '')
endfunction

function! s:front_matter_end(buf) abort
  let first = get(getbufline(a:buf, 1), 0, '')
  if first !~# '^---[ \t]*$'
    return 0
  endif

  " Only skip a front matter block when it looks like YAML.  A document that
  " merely starts with a horizontal rule should still be outlined normally.
  let has_key = 0
  let lnum = 1
  for line in getbufline(a:buf, 2, 50)
    let lnum += 1
    if line =~# '^\%(---\|\.\.\.\)[ \t]*$'
      return has_key ? lnum : 0
    endif
    if line =~# '^[A-Za-z0-9_.-]\+:'
      let has_key = 1
    endif
  endfor
  return 0
endfunction

" A Setext title must be a paragraph line.  Do not mistake a heading, fence,
" list item, table row, blockquote, or another underline for a title.
function! s:is_setext_title(line) abort
  let line = a:line
  if line =~# '^ \{4,}\|^\t'
    return 0
  endif
  if line =~# '^ \{0,3}#'
    return 0
  endif
  if line =~# '^ \{0,3}\(`\{3,}\|[~]\{3,}\)'
    return 0
  endif
  if line =~# '^ \{0,3}[=-]\+[ \t]*$'
    return 0
  endif
  if line =~# '^ \{0,3}>'
    return 0
  endif
  if line =~# '^ \{0,3}\%([-*+]\|\d\+[.)]\)[ \t]\+'
    return 0
  endif
  if line =~# '^ \{0,3}|'
    return 0
  endif
  if line =~# '^ \{0,3}<'
    return 0
  endif
  if line =~# '^ \{0,3}\%([-*_][ \t]*\)\{3,}$'
    return 0
  endif
  if line =~# '^ \{0,3}\[[^]]\+\]:'
    return 0
  endif
  return 1
endfunction

function! s:parse(buf, max_level) abort
  " Match ATX headings, fenced-code markers, and possible Setext underlines
  " in one C-level scan.  The negative lookahead stops "#####" from being
  " mistaken for a level-4 heading.
  let atx_pat = '#\{1,' . a:max_level . '}\%(#\)\@!'
  let atx_fence_pat = '\%(' . atx_pat . '\|`\{3,}\|[~]\{3,}\)'
  " Group 1 is an ATX/fence marker, group 2 is its text, and group 3 is a
  " Setext underline.  Setext underlines must contain nothing but the marker.
  let item_pat = '^ \{0,3}\%(\(' . atx_fence_pat
        \ . '\)\(.*\)$\|\(=\+\|-\+\)[ \t]*$\)'

  if exists('*matchbufline')
    " One C-level scan returns every candidate line, in order.  The trailing
    " .* makes matchbufline() return the complete line, so no getbufline()
    " call is needed for each candidate.
    let items = matchbufline(a:buf, item_pat, 1, '$')
  else
    " Fallback for old Vim versions without matchbufline().
    let items = []
    let i = 0
    for line in getbufline(a:buf, 1, '$')
      let i += 1
      if line =~# item_pat
        call add(items, {'lnum': i, 'text': line})
      endif
    endfor
  endif

  if empty(items)
    return []
  endif

  let fm_end = s:front_matter_end(a:buf)
  let nodes = []
  let in_fence = 0
  let fence_char = ''
  let fence_len = 0
  let setext_lnum = 0

  for m in items
    let lnum = m.lnum
    if fm_end > 0 && lnum <= fm_end
      continue
    endif

    let line = m.text
    let parts = matchlist(line, item_pat)
    if empty(parts)
      continue
    endif

    let marker = parts[1] ==# ''
          \ ? parts[3] : substitute(parts[1], '\s\+$', '', '')
    let rest = parts[2]

    if in_fence
      " A closing fence uses the same character and is at least as long as
      " the opening fence.  Anything else after it must be whitespace.
      if marker[0] ==# fence_char
            \ && strlen(marker) >= fence_len
            \ && s:trim(rest) ==# ''
        let in_fence = 0
      endif
      continue
    endif

    if marker[0] ==# '#'
      let text = s:trim(rest)
      if text =~# '^#\+$'
        " A heading such as "# ###" consists only of a closing sequence.
        let text = ''
      else
        let text = substitute(text, '[' . s:space_chars . ']\+#\+$', '', '')
        let text = s:trim(text)
      endif
      if text ==# ''
        let text = '(untitled)'
      endif
      call add(nodes, {
            \ 'lnum': lnum,
            \ 'level': strlen(marker),
            \ 'text': text,
            \ })
    elseif marker[0] ==# '`' || marker[0] ==# '~'
      " A backtick fence's info string may not contain a backtick.  Lines
      " such as ```inline``` are inline code, not an opening fence.
      if marker[0] ==# '`' && rest =~# '`'
        continue
      endif
      let in_fence = 1
      let fence_char = marker[0]
      let fence_len = strlen(marker)
    else
      " Setext underline.  It is only a heading when the preceding line is
      " ordinary paragraph text; otherwise it is a thematic break or a fence
      " of some other kind.
      if s:trim(rest) !=# ''
        continue
      endif
      let title_lnum = lnum - 1
      if title_lnum < 1 || title_lnum == setext_lnum
        continue
      endif
      let prev = get(getbufline(a:buf, title_lnum), 0, '')
      if s:trim(prev) ==# '' || !s:is_setext_title(prev)
        continue
      endif
      call add(nodes, {
            \ 'lnum': title_lnum,
            \ 'level': marker[0] ==# '=' ? 1 : 2,
            \ 'text': s:trim(prev),
            \ })
      let setext_lnum = title_lnum
    endif
  endfor

  return nodes
endfunction

" --- Rendering -------------------------------------------------------------

function! s:render(state, nodes, title, empty_text) abort
  let tree = a:state.tree
  if tree <= 0 || !bufexists(tree)
    return
  endif

  let shown = []
  for node in a:nodes
    if node.level <= a:state.depth
      call add(shown, node)
    endif
  endfor

  let lines = []
  let lnums = []
  if empty(shown)
    let lines = [a:empty_text]
  else
    for node in shown
      call add(lines, '  ' . repeat('. ', node.level - 1) . '|' . node.text)
      call add(lnums, node.lnum)
    endfor
  endif

  let reset_view = get(a:state, 'reset_view', 0)
  let old_lnum = 0
  if !reset_view && bufnr('%') == tree
    let old_lnum = get(getbufvar(tree, 'v_outline_lnums', []), line('.') - 1, 0)
  endif

  let old_len = len(getbufline(tree, 1, '$'))
  let new_len = len(lines)
  call setbufvar(tree, '&modifiable', 1)
  if new_len > old_len
    call appendbufline(tree, old_len, repeat([''], new_len - old_len))
  endif
  call setbufline(tree, 1, lines)
  if new_len < old_len
    call deletebufline(tree, new_len + 1, old_len)
  endif
  call setbufvar(tree, '&modifiable', 0)
  call setbufvar(tree, 'v_outline_lnums', lnums)
  call setbufvar(tree, 'v_outline_title', a:title)

  if reset_view
    call s:reset_tree_view(a:state)
    let a:state.reset_view = 0
  endif

  if old_lnum > 0 && !empty(lnums) && bufnr('%') == tree
    let idx = len(lnums) - 1
    for i in range(len(lnums))
      if lnums[i] >= old_lnum
        let idx = i
        break
      endif
    endfor
    call cursor(idx + 1, 1)
  endif
endfunction

function! s:refresh(state, force) abort
  if !s:is_open(a:state)
    return
  endif

  let body = a:state.body
  if body > 0 && bufexists(body) && !bufloaded(body)
    try
      call bufload(body)
    catch
    endtry
  endif
  if body <= 0 || !bufexists(body) || !s:is_markdown(body)
    let a:state.tick = -1
    let a:state.depth = -1
    call s:render(a:state, [], 'Outline', '')
    return
  endif

  let depth = max([1, min([6, get(g:, 'v_outline_depth', 3)])])
  let tick = getbufvar(body, 'changedtick')
  if !a:force && tick == a:state.tick && depth == a:state.depth
    return
  endif

  try
    let nodes = s:parse(body, depth)
  catch
    echohl ErrorMsg
    echomsg 'V: ' . v:exception
    echohl None
    return
  endtry

  let a:state.tick = tick
  let a:state.depth = depth

  let visible_count = 0
  for node in nodes
    if node.level <= depth
      let visible_count += 1
    endif
  endfor

  let name = fnamemodify(bufname(body), ':t')
  if name ==# ''
    let name = 'Markdown'
  endif
  call s:render(a:state, nodes, name . ' · ' . visible_count, 'No headings')
endfunction

" --- Autocmd callbacks and navigation --------------------------------------

function! v_outline#on_bufenter() abort
  let state = s:state()
  if !s:is_open(state)
    call v_outline#detach_body()
    return
  endif

  let buf = bufnr('%')
  if buf == state.tree
    return
  endif

  call s:follow(state, buf)
  call s:refresh(state, 0)
endfunction

function! v_outline#on_text_changed() abort
  let state = s:state()
  if !s:is_open(state) || bufnr('%') != state.body
    return
  endif

  if state.timer != -1
    call timer_stop(state.timer)
  endif
  let state.timer = timer_start(120, function('s:debounced', [state.tree]))
endfunction

function! s:debounced(tree, timer) abort
  let state = get(s:states, string(a:tree), {})
  if empty(state) || get(state, 'timer', -1) != a:timer
    return
  endif
  let state.timer = -1
  if s:is_open(state)
    call s:refresh(state, 0)
  endif
endfunction

function! v_outline#on_bufwipe(buf) abort
  if a:buf <= 0
    return
  endif

  for key in keys(s:states)
    let state = s:states[key]
    if get(state, 'tree', 0) == a:buf
      call s:cleanup(state)
    elseif get(state, 'body', 0) == a:buf
      let state.body = 0
      let state.tick = -1
      if s:is_open(state)
        call s:render(state, [], 'Outline', '')
      endif
    endif
  endfor
endfunction

" Tab from the outline: jump to the heading selected in the outline.
function! v_outline#focus_body() abort
  let state = s:state()
  if !s:is_open(state) || bufnr('%') != state.tree
    return
  endif

  let lnum = s:heading_lnum(state)
  call s:leave_tree(state)
  let win = s:open_body_window(state)
  if win <= 0
    return
  endif
  call win_gotoid(win)
  if lnum > 0
    call cursor(min([lnum, line('$')]), 1)
    normal! zvzz
  endif
  call s:map_body(state)
endfunction

function! v_outline#focus_tree() abort
  let state = s:state()
  if empty(state) || bufnr('%') != get(state, 'body', -1)
    call v_outline#detach_body()
    return
  endif

  let win = s:tree_window(state)
  if win <= 0
    return
  endif
  call win_gotoid(win)

  let view = get(state, 'tree_view', {})
  if !empty(view)
    try
      call winrestview(view)
    catch
    endtry
  endif
endfunction

" <CR>: center the selected heading in the document, but keep the cursor in
" the outline.  Tab then moves into the document at that heading.
function! v_outline#preview() abort
  let state = s:state()
  if !s:is_open(state) || bufnr('%') != state.tree
    return
  endif

  let lnum = s:heading_lnum(state)
  if lnum <= 0
    return
  endif

  let tree_win = s:tree_window(state)
  let win = s:open_body_window(state)
  if win <= 0
    return
  endif
  call s:center_heading(win, lnum)

  " s:open_body_window() may have created and entered a new split.
  if tree_win > 0
    call win_gotoid(tree_win)
  endif
endfunction

" Kept for compatibility.  <CR> now previews instead of jumping.
function! v_outline#jump() abort
  call v_outline#preview()
endfunction

function! v_outline#close() abort
  let state = s:state()
  if !empty(state)
    call s:close(state)
    return
  endif

  " Clean up a state whose outline window disappeared without BufWipeout.
  let stale = get(t:, 'v_outline_state', {})
  if !empty(stale)
    call s:cleanup(stale)
  endif
endfunction

function! s:close(state) abort
  if empty(a:state) || get(a:state, 'closing', 0)
    return
  endif
  let a:state.closing = 1

  if get(a:state, 'timer', -1) != -1
    call timer_stop(a:state.timer)
    let a:state.timer = -1
  endif

  call s:detach_body(a:state)

  let win = s:tree_window(a:state)
  if win > 0
    let info = getwininfo(win)
    if !empty(info) && info[0].width > 0
      let g:v_outline_width = info[0].width
    endif
    try
      call win_execute(win, 'silent! close')
    catch
    endtry
  endif

  if get(a:state, 'tree', 0) > 0 && bufexists(a:state.tree)
    execute 'silent! bwipeout! ' . a:state.tree
  endif

  let last = get(a:state, 'last_win', 0)
  let key = string(get(a:state, 'tree', -1))
  if has_key(s:states, key)
    call remove(s:states, key)
  endif
  if get(get(t:, 'v_outline_state', {}), 'tree', 0) == get(a:state, 'tree', 0)
    unlet! t:v_outline_state
  endif

  if last > 0 && win_id2tabwin(last)[0] > 0
    call win_gotoid(last)
  endif
endfunction
