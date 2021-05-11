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

- `g:quickpick_rg_command`

   The command to use for each search query. You can use (but not tested) any
   kind of binary printing in vimgrep style.

   default: `'rg --vimgrep "%s"'`
