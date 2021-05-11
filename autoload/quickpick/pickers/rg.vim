if !exists('g:quickpick_rg_command')
    let g:quickpick_rg_command = 'rg --vimgrep "%s"'
endif

let g:quickpick_rg = 1

let s:prev_input = ''

function! quickpick#pickers#rg#open() abort
    call quickpick#open({
        \   'on_change': function('s:on_change'),
        \   'on_accept': function('s:on_accept'),
        \   'input': s:prev_input,
        \   'items': s:find_occurrences(s:prev_input),
        \ })
endfunction

function! s:find_occurrences(query) abort
    if empty(a:query)
        return []
    endif
    let command = printf(g:quickpick_rg_command, shellescape(a:query))
    return uniq(sort(split(system(command), '\n')))
endfunction

function! s:on_change(data, name) abort
    let s:prev_input = a:data['input']

    " quickpick.vim becomes too slow for too many items. Take the first few
    " items when items are too many. The maximum number of items can be
    " configured by global variable g:quickpick#pickers#rg#item_limit.
    let item_limit = get(g:, 'quickpick#pickers#rg#item_limit', 100)
    call quickpick#items(s:find_occurrences(a:data['input'])[0:item_limit])
endfunction

function! s:on_accept(data, name) abort
    call quickpick#close()
    if len(a:data['items']) > 0
        let entry = split(a:data['items'][0], ':')
        if len(entry) >= 4
            let path = entry[0]
            let line = entry[1]
            let col = entry[2]
            execute printf('edit +call\ cursor(%d,%d) %s',
                        \ line, col, fnameescape(path))
            " execute 'echomsg ' . a:data['items'][0]
        else
            echomsg "cannot parse selected entry: " . a:data['items'][0]
        endif
    endif
endfunction
