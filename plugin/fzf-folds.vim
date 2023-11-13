if exists('g:loaded_fzf_folds') && g:loaded_fzf_folds
 finish
endif

function! s:fzFGetLine(path)
  if !empty(glob(a:path))
    if expand('%:p') ==# fnamemodify(a:path, ':p')
      return getline(1, '$')
    else
      return readfile(a:path)
    endif
  else
    return []
  endif
endfunction

function! s:fzFoldLineNumbers(path)
  let lines = s:fzFGetLine(a:path)
  let lnums = []
  let lnum = 1
  for l in lines
    if l =~# '\v^.*\{\{\{'
      call add(lnums, lnum)
    endif
    let lnum += 1
  endfor
  return lnums
endfunction

function! s:commandSurroundings()
  return split(substitute(substitute(substitute(&commentstring, '^$', '%s', ''), '\S\zs%s',' %s', '') ,'%s\ze\S', '%s ', ''), '%s')
endfunction

function! s:fzFolds()
  let lnums = s:fzFoldLineNumbers(expand('%:p'))
  let folds = []

  for l in lnums
    let ls = getline(l)
    let cmrs = s:commandSurroundings()
    for cmr in cmrs
     let ls = substitute(ls, escape(trim(cmr), '\/~ .*^[''$'), '', 'g')
    endfor

    call substitute(ls, '\v^.*(\{\{\{)@=', '\=add(folds, l . ":" . trim(submatch(0)))', '')
  endfor

  return uniq(sort(folds, 'n'))
endfunction

function! s:fzFSink(fold)
  echo a:fold
  let [lnum, rest] = split(a:fold, ':')
  call cursor(lnum, 0)
  normal! zvzz
endfunction

function! s:fzFoldsRun()
  try
    let folds = s:fzFolds()
  catch
    return s:fzfWarn(v:exception)
  endtry

  if !empty(folds)
    call fzf#run(fzf#wrap({'source': folds, 'sink': function('s:fzFSink')}))
  endif
endfunction

function! s:fzfWarn(message)
  echohl WarningMsg
  echom a:message
  echohl None
  return 0
endfunction

command! FzFolds call s:fzFoldsRun()

let g:loaded_fzf_folds = 1
