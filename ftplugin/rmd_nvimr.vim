
if exists("g:disable_r_ftplugin") || !has("nvim")
    finish
endif


" Source scripts common to R, Rrst, Rnoweb, Rhelp and Rdoc:
runtime R/common_global.vim
if exists("g:rplugin_failed")
    finish
endif

" Some buffer variables common to R, Rmd, Rrst, Rnoweb, Rhelp and Rdoc need to
" be defined after the global ones:
runtime R/common_buffer.vim

function! RmdIsInRCode(vrb)
    let chunkline = search("^[ \t]*```[ ]*{r", "bncW")
    let docline = search("^[ \t]*```$", "bncW")
    if chunkline > docline && chunkline != line(".")
        return 1
    else
        if a:vrb
            call RWarningMsg("Not inside an R code chunk.")
        endif
        return 0
    endif
endfunction

function! RmdPreviousChunk() range
    let rg = range(a:firstline, a:lastline)
    let chunk = len(rg)
    for var in range(1, chunk)
        let curline = line(".")
        if RmdIsInRCode(0)
            let i = search("^[ \t]*```[ ]*{r", "bnW")
            if i != 0
                call cursor(i-1, 1)
            endif
        endif
        let i = search("^[ \t]*```[ ]*{r", "bnW")
        if i == 0
            call cursor(curline, 1)
            call RWarningMsg("There is no previous R code chunk to go.")
            return
        else
            call cursor(i+1, 1)
        endif
    endfor
    return
endfunction

function! RmdNextChunk() range
    let rg = range(a:firstline, a:lastline)
    let chunk = len(rg)
    for var in range(1, chunk)
        let i = search("^[ \t]*```[ ]*{r", "nW")
        if i == 0
            call RWarningMsg("There is no next R code chunk to go.")
            return
        else
            call cursor(i+1, 1)
        endif
    endfor
    return
endfunction

function! RMakeRmd(t)
    update

    if a:t == "odt"
        if has("win32")
            let g:rplugin_soffbin = "soffice.exe"
        else
            let g:rplugin_soffbin = "soffice"
        endif
        if !executable(g:rplugin_soffbin)
            call RWarningMsg("Is Libre Office installed? Cannot convert into ODT: '" . g:rplugin_soffbin . "' not found.")
            return
        endif
    endif

    let rmddir = expand("%:p:h")
    if has("win32")
        let rmddir = substitute(rmddir, '\\', '/', 'g')
    endif
    if a:t == "default"
        let rcmd = 'nvim.interlace.rmd("' . expand("%:t") . '", rmddir = "' . rmddir . '"'
    else
        let rcmd = 'nvim.interlace.rmd("' . expand("%:t") . '", outform = "' . a:t .'", rmddir = "' . rmddir . '"'
    endif
    if (g:R_openhtml  == 0 && a:t == "html_document") || (g:R_openpdf == 0 && (a:t == "pdf_document" || a:t == "beamer_presentation"))
        let rcmd .= ", view = FALSE"
    endif
    let rcmd = rcmd . ', envir = ' . g:R_rmd_environment . ')'
    call g:SendCmdToR(rcmd)
endfunction

" Send Rmd chunk to R
function! SendRmdChunkToR(e, m)
    if RmdIsInRCode(0) == 0
        call RWarningMsg("Not inside an R code chunk.")
        return
    endif
    let chunkline = search("^[ \t]*```[ ]*{r", "bncW") + 1
    let docline = search("^[ \t]*```", "ncW") - 1
    let lines = getline(chunkline, docline)
    let ok = RSourceLines(lines, a:e)
    if ok == 0
        return
    endif
    if a:m == "down"
        call RmdNextChunk()
    endif
endfunction

let b:IsInRCode = function("RmdIsInRCode")
let b:PreviousRChunk = function("RmdPreviousChunk")
let b:NextRChunk = function("RmdNextChunk")
let b:SendChunkToR = function("SendRmdChunkToR")

"==========================================================================
" Key bindings and menu items

call RCreateStartMaps()
call RCreateEditMaps()
call RCreateSendMaps()
call RControlMaps()
call RCreateMaps("nvi", '<Plug>RSetwd',        'rd', ':call RSetWD()')

" Only .Rmd files use these functions:
call RCreateMaps("nvi", '<Plug>RKnit',          'kn', ':call RKnit()')
call RCreateMaps("nvi", '<Plug>RMakeRmd',       'kr', ':call RMakeRmd("default")')
call RCreateMaps("nvi", '<Plug>RMakePDFK',      'kp', ':call RMakeRmd("pdf_document")')
call RCreateMaps("nvi", '<Plug>RMakePDFKb',     'kl', ':call RMakeRmd("beamer_presentation")')
call RCreateMaps("nvi", '<Plug>RMakeHTML',      'kh', ':call RMakeRmd("html_document")')
call RCreateMaps("nvi", '<Plug>RMakeODT',       'ko', ':call RMakeRmd("odt")')
call RCreateMaps("ni",  '<Plug>RSendChunk',     'cc', ':call b:SendChunkToR("silent", "stay")')
call RCreateMaps("ni",  '<Plug>RESendChunk',    'ce', ':call b:SendChunkToR("echo", "stay")')
call RCreateMaps("ni",  '<Plug>RDSendChunk',    'cd', ':call b:SendChunkToR("silent", "down")')
call RCreateMaps("ni",  '<Plug>REDSendChunk',   'ca', ':call b:SendChunkToR("echo", "down")')
call RCreateMaps("n",  '<Plug>RNextRChunk',     'gn', ':call b:NextRChunk()')
call RCreateMaps("n",  '<Plug>RPreviousRChunk', 'gN', ':call b:PreviousRChunk()')

" Menu R
if has("gui_running")
    runtime R/gui_running.vim
    call MakeRMenu()
endif

let g:rplugin_has_pandoc = 0
let g:rplugin_has_soffice = 0

call RSetPDFViewer()

call RSourceOtherScripts()

if exists("b:undo_ftplugin")
    let b:undo_ftplugin .= " | unlet! b:IsInRCode b:PreviousRChunk b:NextRChunk b:SendChunkToR"
else
    let b:undo_ftplugin = "unlet! b:IsInRCode b:PreviousRChunk b:NextRChunk b:SendChunkToR"
endif


" map magrittr piping operator
inoremap >> %>%<Space>
inoremap <> %<>%<Space>

" Insert inline r chunk
nnoremap <leader>rr ^i`r<Space><Esc>$i<Space>`<Esc>

imap <C-e> <Plug>RCompleteArgs
imap <C-q> <Plug>RSendLine
vmap <C-q> <Plug>RESendSelection
nmap <C-q> <Plug>RDSendLine
nmap <LocalLeader>rf <Plug>RStart
nmap <LocalLeader>rw <Plug>RSaveClose
nmap <LocalLeader>rq <Plug>RClose
nmap <LocalLeader>ro <Plug>RUpdateObjBrowser
nmap <LocalLeader>so <Plug>RDSendLineAndInsertOutput
nmap <LocalLeader>sr <Plug>RNRightPart
nmap <LocalLeader>sl <Plug>RNLeftPart
nmap <LocalLeader>sf <Plug>RESendFunction
nmap <LocalLeader>rh <Plug>RHelp
nmap <LocalLeader>ra <Plug>RShowArgs
nmap <LocalLeader>st <Plug>RObjectStr
nmap <LocalLeader>rl <Plug>RListSpace
nmap <LocalLeader>rx <Plug>RClearAll
nmap <LocalLeader>kh :call RMakeRmd('html_document')<cr>
nmap <LocalLeader>kp :call RMakeRmd('pdf_document')<cr>
nnoremap <silent> <LocalLeader>gc :call g:SendCmdToR("gc()")<CR>
nnoremap <silent> <LocalLeader>gw :call g:SendCmdToR("getwd()")<CR>
nnoremap <silent> <LocalLeader>si :call g:SendCmdToR("save.image()")<CR>
nmap <LocalLeader>cr <Plug>RRightComment
nmap <LocalLeader>co <Plug>RToggleComment
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
nnoremap <silent> <LocalLeader>wb :call RAction("which_binary")<CR>
nnoremap <silent> <LocalLeader>mb :call RAction("make_binary")<CR>
nnoremap <silent> <LocalLeader>rn :call RAction("readnames")<CR>:vert sb objbrowser.R<CR>:vertical res 60<CR>:set nowrap<cr>:e<CR>gg 
nnoremap <silent> <LocalLeader>de :call RAction("Desc")<CR>
nnoremap <silent> <LocalLeader>dr :call RAction("df2rds")<CR>
nnoremap <silent> <LocalLeader>or :call RAction("obj2rds")<CR>
nnoremap <silent> <LocalLeader>lr :call RAction("list2rds")<CR>
nnoremap <silent> <LocalLeader>ri :call RAction("rdsinit")<CR>
nnoremap <silent> <LocalLeader>sm :call RAction("stargazer_md")<CR>
nnoremap <silent> <LocalLeader>nd :call RAction("n_distinct")<CR>
nnoremap <silent> <LocalLeader>na :call RAction("names")<CR>
nnoremap <silent> <LocalLeader>pp :call RAction("print")<CR>
nnoremap <silent> <LocalLeader>;; :call RAction("summary")<CR>
nnoremap <silent> <LocalLeader>tr :call RAction("screenreg")<CR>
nnoremap <silent> <LocalLeader>xx :RStop<CR>
nnoremap <silent> <LocalLeader>ri :RInsert
nnoremap <LocalLeader>rv :e ~/.vim/bundle/vim-R-plugin/ftplugin/rmd.vim<cr>

nmap <LocalLeader>r- <LocalLeader>-<LocalLeader>ro<Esc>gg<cr><cr>
nmap <LocalLeader>r= <LocalLeader>=<LocalLeader>ro<Esc>gg<cr><cr>
