# quickpick-rg.vim

`rg` (ripgrep) picker for [quickpick.vim](https://github.com/prabirshrestha/quickpick.vim).

## Install

```vim
Plug 'prabirshrestha/quickpick.vim'
Plug 'statiolake/quickpick-rg.vim'
```

## Usage

Just type `:Prg` and your search query.

## Options

- `g:quickpick#pickers#rg#command`

    The command to use for each search query. You can use (but not tested) any
    kind of binary printing in vimgrep style. In this option, `%s` is replaced
    by the actual query.

    default: `'rg --vimgrep %s'`

- `g:quickpick#pickers#rg#item_limit`

    The maximum number of items to show in quickpick window. Too many makes it
    too slow. No effect to the quickfix lists.

    default: `100`

- `g:quickpick#pickers#rg#use_quickfix`

    If true, set the results to the quickfix so that you can go next occurrence
    easily.

    default: `1`

- `g:quickpick#pickers#rg#quickfix_auto_open`

    If true, the quickfix window automatically opened when you accept the
    query.

    default: `1`
