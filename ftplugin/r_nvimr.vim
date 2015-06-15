
if exists("g:disable_r_ftplugin") || !has("nvim")
    finish
endif

" Source scripts common to R, Rnoweb, Rhelp, Rmd, Rrst and rdoc files:
runtime R/common_global.vim
if exists("g:rplugin_failed")
    finish
endif

" Some buffer variables common to R, Rnoweb, Rhelp, Rmd, Rrst and rdoc files
" need be defined after the global ones:
runtime R/common_buffer.vim

function! GetRCmdBatchOutput()
    if filereadable(s:routfile)
        let curpos = getpos(".")
        if g:R_routnotab == 1
            exe "split " . s:routfile
            set filetype=rout
            exe "normal! \<c-w>\<c-p>"
        else
            exe "tabnew " . s:routfile
            set filetype=rout
            normal! gT
        endif
    else
        call RWarningMsg("The file '" . s:routfile . "' is not readable.")
    endif
endfunction

" Run R CMD BATCH on current file and load the resulting .Rout in a split
" window
function! ShowRout()
    let s:routfile = expand("%:r") . ".Rout"
    if bufloaded(s:routfile)
        exe "bunload " . s:routfile
        call delete(s:routfile)
    endif

    " if not silent, the user will have to type <Enter>
    silent update

    if has("win32")
        let rcmd = 'Rcmd.exe BATCH --no-restore --no-save "' . expand("%") . '" "' . s:routfile . '"'
    else
        let rcmd = g:rplugin_R . " CMD BATCH --no-restore --no-save '" . expand("%") . "' '" . s:routfile . "'"
    endif

    call jobstart(rcmd, {'on_exit': function('GetRCmdBatchOutput')})
endfunction

" Convert R script into Rmd, md and, then, html.
function! RSpin()
    update
    call g:SendCmdToR('require(knitr); .vim_oldwd <- getwd(); setwd("' . expand("%:p:h") . '"); spin("' . expand("%:t") . '"); setwd(.vim_oldwd); rm(.vim_oldwd)')
endfunction

" Default IsInRCode function when the plugin is used as a global plugin
function! DefaultIsInRCode(vrb)
    return 1
endfunction

let b:IsInRCode = function("DefaultIsInRCode")

"==========================================================================
" Key bindings and menu items

call RCreateStartMaps()
call RCreateEditMaps()

" Only .R files are sent to R
call RCreateMaps("ni", '<Plug>RSendFile',     'aa', ':call SendFileToR("silent")')
call RCreateMaps("ni", '<Plug>RESendFile',    'ae', ':call SendFileToR("echo")')
call RCreateMaps("ni", '<Plug>RShowRout',     'ao', ':call ShowRout()')

" Knitr::spin
" -------------------------------------
call RCreateMaps("ni", '<Plug>RSpinFile',     'ks', ':call RSpin()')

call RCreateSendMaps()
call RControlMaps()
call RCreateMaps("nvi", '<Plug>RSetwd',        'rd', ':call RSetWD()')


" Menu R
if has("gui_running")
    runtime R/gui_running.vim
    call MakeRMenu()
endif

call RSourceOtherScripts()

if exists("b:undo_ftplugin")
    let b:undo_ftplugin .= " | unlet! b:IsInRCode"
else
    let b:undo_ftplugin = "unlet! b:IsInRCode"
endif


" map magrittr piping operator
inoremap >> %>%<Space>
inoremap <> %<>%<Space>

imap <C-e> <Plug>RCompleteArgs
imap <C-p> <Plug>RCompleteArgs
imap <C-q> <Plug>RSendLine
vmap <C-q> <Plug>RESendSelection
nmap <C-q> <Plug>RDSendLine
nmap <LocalLeader>rf <Plug>RStart
nmap <LocalLeader>rw <Plug>RSaveClose
nmap <LocalLeader>rq <Plug>RClose
nmap <LocalLeader>ro <Plug>RListSpace
nmap <LocalLeader>ro <Plug>RUpdateObjBrowser
nmap <LocalLeader>= <Plug>ROpenLists
nmap <LocalLeader>- <Plug>RCloseLists
nmap <LocalLeader>so <Plug>RDSendLineAndInsertOutput
nmap <LocalLeader>sr <Plug>RNRightPart
nmap <LocalLeader>sl <Plug>RNLeftPart
nmap <LocalLeader>sf <Plug>RSendFunction
nmap <LocalLeader>rh <Plug>RHelp
nmap <LocalLeader>ra <Plug>RShowArgs
nmap <LocalLeader>st <Plug>RObjectStr
nmap <LocalLeader>rl <Plug>RListSpace
nmap <LocalLeader>rx <Plug>RClearAll
nmap <LocalLeader>rc <Plug>RRightComment
nmap <LocalLeader>rd <Plug>RSetwd
nnoremap <silent> <LocalLeader>gc :call g:SendCmdToR("gc()")<CR>
nnoremap <silent> <LocalLeader>gw :call g:SendCmdToR("getwd()")<CR>
nnoremap <silent> <LocalLeader>si :call g:SendCmdToR("save.image()")<CR>
nmap <LocalLeader>cr <Plug>RRightComment
nmap <LocalLeader>co <Plug>RToggleComment

nnoremap <silent> <LocalLeader>wb :call RAction("which_binary")<CR>
nnoremap <silent> <LocalLeader>rn :call RAction("readnames")<CR>:vert sb Data/objbrowser.R<CR>:set nowrap<cr>:e<CR>gg 
nnoremap <silent> <LocalLeader>st :call RAction("str")<CR>
nnoremap <silent> <LocalLeader>et :call RAction("ls.str")<CR>
nnoremap <silent> <LocalLeader>gl :call RAction("glimpse")<CR>
nnoremap <silent> <LocalLeader>le :call RAction("length")<CR>
nnoremap <silent> <LocalLeader>di :call RAction("dim")<CR>
nnoremap <silent> <LocalLeader>cl :call RAction("class")<CR>
nnoremap <silent> <LocalLeader>hh :call RAction("head")<CR>
nnoremap <silent> <LocalLeader>tl :call RAction("tail")<CR>
nnoremap <silent> <LocalLeader>qp :call RAction("qplot")<CR>
nnoremap <silent> <LocalLeader>rm :call RAction("rm")<CR>
nnoremap <silent> <LocalLeader>ta :call RAction("table")<CR>
nnoremap <silent> <LocalLeader>dl :call RAction("delete")<CR>
nnoremap <silent> <LocalLeader>cn :call RAction("colnames")<CR>
nnoremap <silent> <LocalLeader>pr :call RAction("parent.env")<CR>
nnoremap <silent> <LocalLeader>en :call RAction("environment")<CR>
nnoremap <silent> <LocalLeader>wh :call RAction("Where")<CR>
nnoremap <silent> <LocalLeader>ga :call RAction("getAnywhere")<CR>
nnoremap <silent> <LocalLeader>qu :call RAction("quantile")<CR>
nnoremap <silent> <LocalLeader>at :call RAction("attributes")<CR>
nnoremap <silent> <LocalLeader>os :call RAction("object.size")<CR>
nnoremap <silent> <LocalLeader>de :call RAction("Desc")<CR>
nnoremap <silent> <LocalLeader>dr :call RAction("df2rds")<CR>
nnoremap <silent> <LocalLeader>or :call RAction("obj2rds")<CR>
nnoremap <silent> <LocalLeader>lr :call RAction("list2rds")<CR>
nnoremap <silent> <LocalLeader>ri :call RAction("rdsinit")<CR>
nnoremap <silent> <LocalLeader>sp :call RAction("screenreg")<CR>:call RAction("plotreg")<CR>
nnoremap <silent> <LocalLeader>sm :call RAction("stargazer_md")<CR>
nnoremap <silent> <LocalLeader>nd :call RAction("n_distinct")<CR>
nnoremap <silent> <LocalLeader>na :call RAction("names")<CR>
nnoremap <silent> <LocalLeader>pp :call RAction("print")<CR>
nnoremap <silent> <LocalLeader>;; :call RAction("summary")<CR>
nnoremap <silent> <LocalLeader>tr :call RAction("screenreg")<CR>

nnoremap <silent> <LocalLeader>wd :call g:SendCmdToR("wd()")<CR>
nnoremap <silent> <LocalLeader>dm :call g:SendCmdToR("dev_mode()")<CR>
nnoremap <silent> <LocalLeader>in :call g:SendCmdToR("install()")<CR>
nnoremap <silent> <LocalLeader>la :call g:SendCmdToR("load_all()")<CR>
nnoremap <silent> <LocalLeader>dc :call g:SendCmdToR("document()")<CR>
nnoremap <silent> <LocalLeader>bt :call g:SendCmdToR("rtags(recursive = T, ofile='TAGS');etags2ctags('TAGS', 'Rtags')")<CR>
nnoremap <silent> <LocalLeader>ct :call g:SendCmdToR("system('ctags --languages=C,Fortran,Java,Tcl -R -f RsrcTags ./Rtags')")<CR>
nnoremap <silent> <LocalLeader>dg :call RAction("debug")<CR>
nnoremap <silent> <LocalLeader>do :call RAction("debugonce")<CR>
nnoremap <silent> <LocalLeader>mt :call RAction("mtrace")<CR>
nnoremap <silent> <LocalLeader>mo :call RAction("mtrace.off")<CR>

nnoremap <silent> <LocalLeader>ic :RInsert

nmap <LocalLeader>r- <LocalLeader>-<LocalLeader>ro<Esc>gg<cr><cr>
nmap <LocalLeader>r= <LocalLeader>=<LocalLeader>ro<Esc>gg<cr><cr>
nnoremap <LocalLeader>rv :e ~/.vim/bundle/vim-R-plugin/ftplugin/r.vim<cr>
