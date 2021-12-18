let g:quickpick_rg = 1

function! s:default_option(name, value) abort
    let g:[a:name] = get(g:, a:name, a:value)
endfunction

" Options
call s:default_option('quickpick#pickers#rg#command', 'rg --vimgrep %s')
call s:default_option('quickpick#pickers#rg#item_limit', 100)
call s:default_option('quickpick#pickers#rg#use_quickfix', 1)
call s:default_option('quickpick#pickers#rg#quickfix_auto_open', 1)
" Options END

function! quickpick#pickers#rg#open() abort
    let s:last_result = []
    call quickpick#open({
        \      'on_change': function('s:on_change'),
        \      'on_accept': function('s:on_accept'),
        \      'filter': 0,
        \ })
endfunction

function! s:escape(query) abort
    return '"' .. substitute(a:query, '"', '\\"', 'g') .. '"'
endfunction

function! s:find_occurrences(query, callback) abort
    if empty(a:query)
        return []
    endif
    let command = printf(
        \ g:quickpick#pickers#rg#command, s:escape(a:query))

    if exists('s:last_job_id')
        call s:stop(s:last_job_id)
    endif
    let ctx = {'buf': []}
    let s:last_job_id = s:exec(
        \ command, 0, function('s:on_event_during_finding', [ctx, a:callback]))
endfunction

let s:trim_mask = join(map(range(0x21), 'nr2char(v:val)'), '')
function! s:trim_ends(result) abort
    return map(a:result, 'trim(v:val, s:trim_mask, 2)')
endfunction

function! s:on_event_during_finding(ctx, callback, id, data, event) abort
    if a:event ==# 'stdout'
        " quickpick.vim becomes too slow for too many items. Take the first
        " few items when items are too many. The maximum number of items can
        " be configured by global variable g:quickpick#pickers#rg#item_limit.
        if len(a:ctx['buf']) < g:quickpick#pickers#rg#item_limit
            call extend(a:ctx['buf'], a:data)
        endif
    endif

    " Show progress even if the search is not yet fully completed.
    call a:callback(s:trim_ends(a:ctx['buf']), a:event ==# 'exit')
endfunction

function! s:on_find_result(result, finished) abort
    let item_limit = g:quickpick#pickers#rg#item_limit
    let s:last_result = uniq(sort(
        \ filter(copy(a:result[0:item_limit]), '!empty(v:val)')))

    " Do not modify states when window is already closed
    if quickpick#results_winid()
        call quickpick#items(s:last_result)
        if a:finished
            call quickpick#busy(0)
        endif
    endif
endfunction

function! s:start_finding(input, ...) abort
    call s:find_occurrences(a:input, function('s:on_find_result'))
endfunction

function! s:on_change(data, name) abort
    call quickpick#busy(1)
    if exists('s:search_timer')
        call timer_stop(s:search_timer)
    endif

    " Start finding lazily.
    let s:search_timer = timer_start(250, function('s:start_finding', [a:data['input']]))
endfunction

function! s:convert_to_qfentry(line) abort
    let entry = split(a:line, ':')
    if len(entry) >= 4
        let filename = entry[0]
        let lnum = entry[1]
        let col = entry[2]
        let text = join(entry[3:], ':')
        return {
            \     'filename': filename,
            \     'lnum': lnum,
            \     'col': col,
            \     'text': text,
            \ }
    else
        echoerr 'cannot parse selected entry: ' . a:line
    endif
endfunction

function! s:on_accept(data, name) abort
    call quickpick#close()
    if len(a:data['items']) > 0
        let occurrences = s:last_result
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

" vim8/neovim jobs wrapper {{{
function! s:stop(id) abort
    if !has('nvim')
        call job_stop(a:id)
    else
        call jobstop(a:id)
    endif
endfunction

" Copied and modified based on: <https://github.com/prabirshrestha/quickpick-npm.vim/blob/2a6fbddf3eab06bd838eb8c9ff330cdfe0820cbd/autoload/quickpick/pickers/npm/utils.vim>
function! s:exec(cmd, str, callback) abort
    if has('nvim')
        return jobstart(a:cmd, {
                \ 'on_stdout': function('s:on_nvim_job_event', [a:str, a:callback]),
                \ 'on_stderr': function('s:on_nvim_job_event', [a:str, a:callback]),
                \ 'on_exit': function('s:on_nvim_job_event', [a:str, a:callback]),
                \ 'stdin': 'null',
            \ })
    else
        let l:info = { 'close': 0, 'exit': 0, 'exit_code': -1 }
        let l:jobopt = {
            \ 'out_cb': function('s:on_vim_job_event', [l:info, a:str, a:callback, 'stdout']),
            \ 'err_cb': function('s:on_vim_job_event', [l:info, a:str, a:callback, 'stderr']),
            \ 'exit_cb': function('s:on_vim_job_event', [l:info, a:str, a:callback, 'exit']),
            \ 'close_cb': function('s:on_vim_job_close_cb', [l:info, a:str, a:callback]),
            \ 'in_io': 'null',
        \ }
        if has('patch-8.1.350')
          let l:jobopt['noblock'] = 1
        endif
        return job_start(a:cmd, l:jobopt)
    endif
endfunction

function! s:on_nvim_job_event(str, callback, id, data, event) abort
    if (a:event ==# 'exit')
        call a:callback(a:id, a:data, a:event)
    elseif a:str
        " convert array to string since neovim uses array split by \n by default
        call a:callback(a:id, join(a:data, "\n"), a:event)
    else
        call a:callback(a:id, a:data, a:event)
    endif
endfunction

function! s:on_vim_job_event(info, str, callback, event, id, data) abort
    if a:event ==# 'exit'
        let a:info['exit'] = 1
        let a:info['exit_code'] = a:data
        let a:info['id'] = a:id
        if a:info['close'] && a:info['exit']
            " for more info refer to :h job-start
            " job may exit before we read the output and output may be lost.
            " in unix this happens because closing the write end of a pipe
            " causes the read end to get EOF.
            " close and exit has race condition, so wait for both to complete
            call a:callback(a:id, a:data, a:event)
        endif
    elseif a:str
        call a:callback(a:id, a:data, a:event)
    else
        " convert string to array since vim uses string by default
        call a:callback(a:id, split(a:data, "\n", 1), a:event)
    endif
endfunction

function! s:on_vim_job_close_cb(info, str, callback, channel) abort
    let a:info['close'] = 1
    if a:info['close'] && a:info['exit']
        call a:callback(a:info['id'], a:info['exit_code'], 'exit')
    endif
endfunction
" }}}
