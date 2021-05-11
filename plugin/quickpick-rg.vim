if exists('g:quickpick_rg')
    finish
endif
let g:quickpick_rg = 1

command! Prg call quickpick#pickers#rg#open()
