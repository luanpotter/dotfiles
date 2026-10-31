" Mappings shared by the vimrc and scripts/dp (which runs vim -u NONE)

"" clipboard config
if has('mac') || has('macunix')
  set clipboard+=unnamed
elseif has('clipboard')
  set clipboard=unnamedplus
elseif has('unix') && executable('wl-copy')
  function! s:CopyYankToClipboard() abort
    if v:event.operator !=# 'y'
      return
    endif

    let l:text = join(v:event.regcontents, "\n")
    if v:event.regtype ==# 'V'
      let l:text .= "\n"
    endif

    call system('wl-copy -t text/plain', l:text)
  endfunction

  augroup clipboard_yank
    autocmd!
    autocmd TextYankPost * call <SID>CopyYankToClipboard()
  augroup END

  " Load the system clipboard into the unnamed register before pasting
  function! s:PasteFromClipboard(cmd) abort
    let l:text = system('wl-paste --no-newline -t text/plain')
    if v:shell_error == 0
      " A trailing newline means a linewise copy (see CopyYankToClipboard)
      if l:text =~# "\n$"
        call setreg('"', l:text[:-2], 'V')
      else
        call setreg('"', l:text, 'v')
      endif
    endif
    return a:cmd
  endfunction

  nnoremap <expr> p <SID>PasteFromClipboard('p')
  nnoremap <expr> P <SID>PasteFromClipboard('P')
  xnoremap <expr> p <SID>PasteFromClipboard('p')
  xnoremap <expr> P <SID>PasteFromClipboard('P')
endif

"" x will never copy
nnoremap x "_x
xnoremap x "_x
vnoremap x "_x

"" d deletes into special register
nnoremap d "1d
xnoremap d "1d
vnoremap d "1d

"" = pastes from special register
nnoremap = "1p
xnoremap = "1p
vnoremap = "1p

" Copy/Paste
vmap <C-c> "+y
nmap <C-b> "+p

" Half-page scrolling
noremap <C-j> <C-d>
noremap <C-k> <C-u>

" WORD jumps
noremap <C-h> B
noremap <C-l> W
