" vim-outline: a small, dependency-free Markdown outline.
" Maintainer: kemenion
" License: MIT

if exists('g:loaded_v_outline')
  finish
endif
let g:loaded_v_outline = 1

if !exists('g:v_outline_depth')
  let g:v_outline_depth = 3
endif
if !exists('g:v_outline_width')
  let g:v_outline_width = 30
endif
if !exists('g:v_outline_tab_key')
  let g:v_outline_tab_key = '<Tab>'
endif

command! -nargs=? -bar V call v_outline#toggle(<q-args>)
command! -bar Vrefresh call v_outline#refresh()

augroup v_outline
  autocmd!
  autocmd BufEnter * call v_outline#on_bufenter()
  autocmd TextChanged,TextChangedI * call v_outline#on_text_changed()
  autocmd BufWipeout * call v_outline#on_bufwipe(str2nr(expand('<abuf>')))
  autocmd ColorScheme * call v_outline#highlight()
augroup END

call v_outline#highlight()
