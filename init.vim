" Configuration file for vim
set modelines=0		" CVE-2007-2438

" Normally we use vim-extensions. If you want true vi-compatibility
" remove change the following statements
set nocompatible	" Use Vim defaults instead of 100% vi compatibility
set backspace=2		" more powerful backspacing

" Don't write backup file if vim is being called by "crontab -e"
au BufWrite /private/tmp/crontab.* set nowritebackup nobackup
" Don't write backup file if vim is being called by "chpass"
au BufWrite /private/etc/pw.* set nowritebackup nobackup

let skip_defaults_vim=1


" above is the default setting when installing neovim. Will not change it
" following is my setting
set nu
set autoindent
set softtabstop=4 expandtab shiftwidth=4
set autoindent
set showcmd
set ignorecase smartcase

filetype plugin indent on


" set the derminal working at the current directory
autocmd BufEnter * silent! lcd %:p:h

" you have to define your <leader> key very early
" as if you define your leader key to be <spc> 
" later than your map key which used <Leader>
" then you probably find that this map won't working.
let mapleader = ' '

" function to enabling the same plugin (at different fork), primarily
" for vscode neovim extension.
" to use it, you need to copy two lines of installation commamnd
" in !exists('g:vscode') branch, as you need to call
" `:PlugInstall` in nvim terminal to install the fork for Vscode
function! Cond(Cond, ...)
  let opts = get(a:000, 0, {})
  return a:Cond ? opts : extend(opts, { 'on': [], 'for': [] })
endfunction



let g:CONDA_PATHNAME = "/opt/homebrew/Caskroom/miniforge/base"

" condition brach for different setting in nvim terminal and vscode
if !exists('g:vscode')

    let $NVIM_TUI_ENABLE_TRUE_COLOR=1
    set termguicolors
    set guifont=Code_new_Roman_Nerd_Font_Complete:h17

    call plug#begin()

        " Set the Theme for nvim
        " Plug 'folke/tokyonight.nvim', { 'branch': 'main' }
        Plug 'altercation/vim-colors-solarized'

        " Set the theme for statusbar
        Plug 'nvim-lualine/lualine.nvim'

        " Set the advanced text editing and jumping plug
        " Plug 'easymotion/vim-easymotion'
        Plug 'searleser97/vim-sneak'
        Plug 'tpope/vim-surround'
        " Plug 'preservim/nerdcommenter'
        Plug 'tpope/vim-commentary'
        Plug 'tpope/vim-repeat'
        " Plug 'vim-scripts/argtextobj.vim'
        Plug 'michaeljsmith/vim-indent-object'
        Plug 'wellle/targets.vim'
        Plug 'Raimondi/delimitMate'

        " Tree sitter for enhanced text obj and syntax capturality
        Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
        Plug 'nvim-treesitter/nvim-treesitter-textobjects'
        Plug 'p00f/nvim-ts-rainbow'

        " Set markdown syntax highlighting
        Plug 'vim-pandoc/vim-pandoc-syntax', {'for': ['r', 'rmarkdown', 'python', 'markdown.pandoc']}
        Plug 'vim-pandoc/vim-rmarkdown', {'for': ['rmarkdown']}
        Plug 'iamcco/markdown-preview.nvim' , { 'do': 'cd app && yarn install'  }

        " Set FZF for file search
        " Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
        " Plug 'junegunn/fzf.vim'
        Plug 'nvim-lua/plenary.nvim'
        Plug 'nvim-telescope/telescope.nvim'
        Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }

        " a simple format code plugin
        Plug 'pappasam/vim-filetype-formatter', {'for': ['r', 'rmarkdown', 'python', 'markdown.pandoc']}
        Plug 'kdheepak/JuliaFormatter.vim', { 'for': 'julia'}

        " Very simple, naive completion
        " Plug 'skywind3000/vim-auto-popmenu'
        " Plug 'skywind3000/vim-dict'

        " Deal with input method, automatically changed to English
        " input method when switch to normal mode
        Plug 'milanglacier/smartim'
        
        " support browser
        " Plug 'glacambre/firenvim'

        " file explorer
        Plug 'kyazdani42/nvim-tree.lua'

        " LSP config
        Plug 'neovim/nvim-lspconfig'
        Plug 'hrsh7th/cmp-nvim-lsp'
        Plug 'hrsh7th/cmp-buffer'
        Plug 'hrsh7th/cmp-path'
        Plug 'hrsh7th/cmp-cmdline'
        Plug 'hrsh7th/nvim-cmp'

        " Completion
        Plug 'L3MON4D3/LuaSnip'
        Plug 'saadparwaiz1/cmp_luasnip'

        " Variables Outline
        Plug 'simrat39/symbols-outline.nvim'

        " REPL
        Plug 'jalvesaq/Nvim-R', {'for': ['r', 'rmarkdown']}
        Plug 'jalvesaq/vimcmdline'

        " Git
        Plug 'f-person/git-blame.nvim'

        
        Plug 'kyazdani42/nvim-web-devicons'


    call plug#end()

    " set shell=zsh

    "let g:tokyonight_style = "day"
    "colorscheme tokyonight

    syntax enable

    set background=light
    colorscheme solarized


    source ~/.config/nvim/conf_builtin_extend.vim

    lua require('conf_lualine')
    
    lua require("conf_treesitter")
    source ~/.config/nvim/conf_autofm.vim
    source ~/.config/nvim/conf_nvim_tree.vim
    lua require('conf_nvim_tree')
    lua require('conf_telescope')
    
    
    lua require('conf_cmp')
    lua require('conf_lspconfig')
    source ~/.config/nvim/conf_nvim-R.vim
    source ~/.config/nvim/conf_move_tabs.vim
    source ~/.config/nvim/conf_cmdline.vim
    lua require("conf_sym_otln")

    source ~/.config/nvim/conf_mkdp.vim
    source ~/.config/nvim/conf_sneak.vim
    
    
else 
    " configuration only valid in vscode neovim mode 

    
    call plug#begin()

        Plug 'searleser97/vim-sneak'

        Plug 'tpope/vim-surround'
        " Plug 'preservim/nerdcommenter'
        Plug 'tpope/vim-commentary'
        Plug 'tpope/vim-repeat'
        " Plug 'vim-scripts/argtextobj.vim'
        Plug 'wellle/targets.vim'
        " Plug 'michaeljsmith/vim-indent-object'

        " Tree sitter for enhanced text obj and syntax capturality
        Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
        Plug 'nvim-treesitter/nvim-treesitter-textobjects'

        " Deal with input method, automatically changed to English
        " input method when switch to normal mode
        Plug 'milanglacier/smartim'

    call plug#end()
    
    lua require("conf_treesitter")
    source ~/.config/nvim/conf_sneak.vim
    source ~/.config/nvim/conf_builtin_extend.vim
    
endif




