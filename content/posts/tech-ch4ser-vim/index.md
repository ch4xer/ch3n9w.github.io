---
title: ch3n9w 的 vim
author: ch3n9w
date: 2019-04-22 02:05:35
categories: 技术
typora-root-url: ../
---

# ch3n9w 的 vim 

> 本篇文章中的插件均已过时, 不推荐使用

《程序员修炼之道》中有一句话:``最好是精通一种编辑器，并将其用于所有编辑任务。如果不坚持使用一种编辑器，可能会面临现代的巴别特大混乱。`` ，实质今日，深以为然。而自从接触vim之后我一直都保持着有空折腾折腾的好习惯，它的简洁和高度自由让人着迷，围绕着vim衍生出的插件数不胜数。奈何插件繁多的同时也意味着选择的困难和配置的繁琐。为了准备以后可能出现的突发情况比如配置丢失或者重新安装，特在此以实现特定功能为主题，记录自己配置vim的过程。

<!--more-->

------

相比较vim, neovim的速度更快.

为了调动食欲,先上效果图:

![image-20211114141133313](image-20211114141133313.png)

![image-20211114141143513](image-20211114141143513.png)

vim下打开终端

![image-20211114141151758](image-20211114141151758.png)

## 以下内容是配置

### 安装（vim-plug）

```shell
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

### ~/.config/nvim/init.vim

```shell
" c to caplock , add XKBOPTIONS="caps:escape" in /etc/default/keyboard

" 让进入vim的时候显示绝对行号,当进入编辑模式的时候也显示绝对行号,但是从编辑模式回到普通模式的时候切换到相对行号
set number
augroup relative_numbser
 autocmd!
 autocmd InsertEnter * :set norelativenumber
 autocmd InsertLeave * :set relativenumber
augroup END

set wildmenu
" 忽略大小写
set ignorecase
set shell=/bin/zsh

" font and icons for vim
set encoding=utf8
" set guifont=DroidSansMono\ Nerd\ Font\ 11
autocmd User Startified setlocal buflisted


" leader键映射
let mapleader="\<Space>"
map <leader>w :w<CR>
map <leader>q :q!<CR>
map <leader>r :call Runit()<CR>
" 设定函数,自动根据文件类型来调用相应的解释器来执行代码
func Runit()
    if &filetype == 'php'
	exec "!time php %"
    elseif &filetype == 'python'
	exec "!time python %"
    elseif &filetype == 'c'
	exec "!gcc % -o %<"
	exec "!time sudo ./%<"
    elseif &filetype == 'cpp'
	exec "!g++ % -o %<"
	exec "!time ./%<"
    endif
endfunc
"
" set shift width
set shiftwidth=4
set scrolloff=6
" 启动鼠标
set mouse=n

map <ScrollWheelUp> <C-Y>
map <ScrollWheelDown> <C-E>

" 关于多窗口的键位映射
map vs :vs 
map sp :sp 
map <leader>l <C-w>l
map <leader>h <C-w>h
map <leader>j <C-w>j
map <leader>k <C-w>k

map <leader>L <C-w>L
map <leader>H <C-w>H
map <leader>J <C-w>J
map <leader>K <C-w>K

" 终端模式
map te :vs<CR><C-w>L:te<CR>A
tnoremap <esc> <C-\><C-n>

" 关于多标签模式的设定
map tn :tabnew 
map L :tabnext<CR>
map H :tabprev<CR>

" 代码折叠
set foldmethod=indent
set foldlevel=99

"
" 高亮当前的行和列
set cursorcolumn
set cursorline
highlight CursorLine   cterm=NONE ctermbg=black ctermfg=green
highlight CursorColumn cterm=NONE ctermbg=black ctermfg=green 

" 这段代码可以让每次打开文件的时候将光标定位到上一次所在的位置
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

" 引入插件
source ~/.vim/plugins.vim
" 这个是为了在编写python的时候方便在vim内部浏览python文档而添加的，在github上有
" source ~/.vim/pydoc.vim/ftplugin/python_pydoc.vim
```

### ~/.vim/plugins.vim

```
call plug#begin('~/.vim/plugged')

" 代码补全插件
" Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'ncm2/ncm2'
Plug 'ncm2/ncm2-jedi' 
Plug 'ncm2/ncm2-bufword'
Plug 'ncm2/ncm2-path'
Plug 'roxma/nvim-yarp'
Plug 'phpactor/phpactor' ,  {'do': 'composer install', 'for': 'php'}
Plug 'phpactor/ncm2-phpactor'
" 外观插件
Plug 'KeitaNakamura/neodark.vim'
Plug 'cocopon/iceberg.vim'
Plug 'vim-airline/vim-airline'
Plug 'ryanoasis/vim-devicons'
" 代码结构显示
Plug 'vim-scripts/taglist.vim'
" 代码标记,并且可以在标记之间跳转
Plug 'MattesGroeger/vim-bookmarks'
" 目录树
Plug 'scrooloose/nerdtree'
" 括号自动补全
Plug 'jiangmiao/auto-pairs'
" 快速注释
Plug 'scrooloose/nerdcommenter'
 " 花里胡哨的小插件，可以让打字发出音乐
" Plug 'skywind3000/vim-keysound'
call plug#end()

" Plugin setting
"
source /home/ch3n9w/.vim/plugset/nerdtree.vim
source /home/ch3n9w/.vim/plugset/ncm2.vim
source /home/ch3n9w/.vim/plugset/bookmark.vim
source /home/ch3n9w/.vim/plugset/airline.vim
source /home/ch3n9w/.vim/plugset/taglists.vim
source /home/ch3n9w/.vim/plugset/autopair.vim
source /home/ch3n9w/.vim/plugset/nerdcomment.vim
" source ~/.vim/plugset/keysound.vim
```

#### ~/.vim/plugset/ncm2.vim

```
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <CR> (pumvisible() ? "\<c-y>\<cr>": "\<CR>")
autocmd BufEnter * call ncm2#enable_for_buffer()
set completeopt=noinsert,menuone,noselect
let ncm2#popup_delay = 5
let g:ncm2#matcher = "substrfuzzy"
let g:ncm2_jedi#python_version = 3
let g:ncm2#match_highlight = 'sans-serif'
```



#### ~/.vim/plugset/airline.vim

```
"if you want to enable solarized theme ,quote the snipeet
" 这段代码让vim支持插件所需的色彩
if (empty($TMUX))
  if (has("nvim"))
    "For Neovim 0.1.3 and 0.1.4 < https://github.com/neovim/neovim/pull/2198 >
    let $NVIM_TUI_ENABLE_TRUE_COLOR=1
  endif
  "For Neovim > 0.1.5 and Vim > patch 7.4.1799 < https://github.com/vim/vim/commit/61be73bb0f965a895bfb064ea3e55476ac175162 >
  "Based on Vim patch 7.4.1770 (`guicolors` option) < https://github.com/vim/vim/commit/8a633e3427b47286869aa4b96f2bfc1fe65b25cd >
  " < https://github.com/neovim/neovim/wiki/Following-HEAD#20160511 >
  if (has("termguicolors"))
    set termguicolors
  endif
endif

"airline setting 
let g:airline_symbols = {}
let g:airline_left_sep = ''
let g:airline_left_alt_sep = ''
let g:airline_right_sep = ''
let g:airline_right_alt_sep = ''
let g:airline_symbols.branch = ''
let g:airline_symbols.readonly = ''
let g:airline_symbols.linenr = ''
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#show_buffers = 0
let g:airline#extensions#tabline#show_tabs = 1
let g:airline#extensions#tabline#fnamemod = ':t'
let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '|'
"
" 主题设置
" color schema
"主题设置为冰山主题
" colorscheme iceberg 
" let g:airline_theme='iceberg'
" let g:lightline = {'colorscheme': 'iceberg'}
"
" 设置主题为onedark
colorscheme neodark
```

#### ~/.vim/plugset/nerdcomment.vim

```
" comment plugin setting
"comment followed a space
let g:NERDSpaceDelims=1
```

#### ~/.vim/plugset/autopair.vim

```
" autopair setting
let g:AutoPairsShortcutJump = '<S-Tab>'
let g:AutoPairsShortcutFastWrap='<C-z>'
```

#### ~/.vim/plugset/nerdtree.vim

```
" T                 打开nerdree窗口，在左侧栏显示
map T :NERDTreeToggle<CR><leader>l

"close vim if the only window left open is a NERDTree
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
```

#### ~/.vim/plugset/keysound.vim

```
"launch with vim
let g:keysound_enable = 1

"set default sound
let g:keysound_theme = 'default'
" let g:keysound_theme = 'typewriter'
" let g:keysound_theme = 'sword'
" let g:keysound_theme = 'mario'
" let g:keysound_theme = 'bubble'


" set python version
let g:keysound_py_version = 2

"volumn setting
" 其实设置这么大,早就超过极限了
let g:keysound_volumn = 100000
```

### ~/.vim/plugset/taglists.vim

```
map <leader>t :TlistToggle<CR> "设置召唤键
let Tlist_WinWidth=30        "设置taglist宽度
let Tlist_Exit_OnlyWindow=1  "tagList窗口是最后一个窗口，则退出Vim
let Tlist_Use_Right_Window   = 0

" 不同时显示多个文件的 tag ，只显示当前文件的

" let Tlist_Show_One_File=1

"让当前不被编辑的文件的方法列表自动折叠起来

let Tlist_File_Fold_Auto_Close=1
```

### ~/.vim/plugset/bookmark.vim

```
let g:bookmark_sign = '>>'
let g:bookmark_highlight_lines = 1
" unmap mp
nmap mN <Plug>BookmarkPrev
```



## 源码审计

```
sudo apt install ctags
#切到待审计文件夹下的根目录下,执行
ctags -R
生成全局的标签文件
然后我们进入一个代码文件,光标放在某一个函数名或者是宏上,按下Ctrl + ], vim就可以自动切换到该函数定义处,要返回只需要按下Ctrl + o  或者 Ctrl + t
```



```
sudo apt-get install xcape
# make CapsLock behave like Ctrl:
setxkbmap -option ctrl:nocaps
# make short-pressed Ctrl behave like Escape:
xcape -e 'Control_L=Escape'
```

see the link below:

http://tiborsimko.org/capslock-escape-control.html

由于这样的做法会让caplock反应变慢,因此我不用这种方法,而是传统的修改keyboard文件来达到简单的esc映射效果.
