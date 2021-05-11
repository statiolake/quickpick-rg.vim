let g:quickpick_rg = 1

function! s:default_option(name, value)
    let g:[a:name] = get(g:, a:name, a:value)
endfunction

" Options
call s:default_option('quickpick#pickers#rg#command', 'rg --vimgrep %s')
call s:default_option('quickpick#pickers#rg#item_limit', 100)
call s:default_option('quickpick#pickers#rg#use_quickfix', 1)
call s:default_option('quickpick#pickers#rg#quickfix_auto_open', 1)
" Options END

let s:last_input = ''

function! quickpick#pickers#rg#open() abort
    let s:last_input = ''
    call quickpick#open({
        \   'on_change': function('s:on_change'),
        \   'on_accept': function('s:on_accept'),
        \ })
endfunction

function! s:find_occurrences(query) abort
    if empty(a:query)
        return []
    endif
    let command = printf(
        \ g:quickpick#pickers#rg#command, shellescape(a:query))
    return uniq(sort(split(system(command), '\n')))
endfunction

function! s:on_change(data, name) abort
    let s:last_input = a:data['input']

    " quickpick.vim becomes too slow for too many items. Take the first few
    " items when items are too many. The maximum number of items can be
    " configured by global variable g:quickpick#pickers#rg#item_limit.
    let item_limit = g:quickpick#pickers#rg#item_limit
    call quickpick#items(s:find_occurrences(a:data['input'])[0:item_limit])
endfunction

function! s:convert_to_qfentry(line) abort
    let entry = split(a:line, ':')
    if len(entry) >= 4
        let filename = entry[0]
        let lnum = entry[1]
        let col = entry[2]
        let text = join(entry[3:], '')
        return {
            \     'filename': filename,
            \     'lnum': lnum,
            \     'col': col,
            \     'text': text,
            \ }
    else
        echoerr "cannot parse selected entry: " . a:line
    endif
endfunction

function! s:on_accept(data, name) abort
    call quickpick#close()
    if len(a:data['items']) > 0
        let occurrences = s:find_occurrences(s:last_input)
        let idx = index(occurrences, a:data['items'][0])
        if g:quickpick#pickers#rg#use_quickfix
            call setqflist(map(
                \ copy(occurrences),
                \ 's:convert_to_qfentry(v:val)'))
            if g:quickpick#pickers#rg#quickfix_auto_open
                copen
            endif
            execute 'cc ' . string(idx + 1)
        else
            let entry = s:convert_to_qfentry(a:data['items'][0])
            execute printf('edit +call\ cursor(%d,%d) %s',
                \ entry['lnum'], entry['col'], fnameescape(entry['path']))
        endif
    endif
endfunction
