# this script will generate a file 'R.xml' for auto-completion
# in Notepad++
cat("Creating R Autocompletion for Notepad++\n")

{# load some packages to the search path:
  cat("  Loading Base and Recommended Packages . . .\n")
  pkgs <- installed.packages()[, 'Priority']
  pkgs<-names(pkgs)[!is.na(pkgs)]
  pb<-txtProgressBar(0,length(pkgs), style=3)
  for(pkg in pkgs){
    suppressPackageStartupMessages(library(pkg, character.only=T, quietly=T, verbose=F))
    if(inherits(pb, "txtProgressBar"))
      setTxtProgressBar(pb,getTxtProgressBar(pb)+1)
  }  
  close(pb)
}
# you may load any installed packages here
# sapply(c('animation', 'ggplot2'), library, character.only = TRUE)

cat('<?xml version="1.0" encoding="Windows-1252" ?>
<!--
@author  Yihui Xie - http://yihui.name
@date    2010-08-17
@url     http://yihui.name/en/2010/08/auto-completion-in-notepad-for-r-script/
-->
<NotepadPlus>
   <AutoComplete language="R">
       <Environment ignoreCase="no" startFunc="(" stopFunc=")" paramSeparator="," terminal=";" additionalWordChar = "."/>
', file = 'R.xml')

# want to restore?
# pkg0 <- search()
# env0 <- Sys.getenv()
# dll0 <- sapply(getLoadedDLLs(), "[[", "path")

# deal with special HTML/XML characters
htmlspecialchars <- function(string) {
    x = c("&", '"', "<", ">")
    subx = c("&amp;", "&quot;", "&lt;", "&gt;")
    for (i in seq_along(x)) {
        string = gsub(x[i], subx[i], string, fixed = TRUE)
    }
    string
}

strFun <- 
'       <KeyWord name="%s" func="yes">
           <Overload retVal="function">
%s
           </Overload>
       </KeyWord>
'

strNoFun <- 
'       <KeyWord name="%s" />
'

findfuns <- function(x) {
    #message(x)
    #flush.console()
    env <- paste("package", x, sep = ":")
    nm <- ls(env, all.names = FALSE)
    idx <- grep("[<>&@:\\?\\{\\(\\)\\[\\^\\*\\$!%/\\|\\+=~\\-]", 
        nm)
    if (length(idx)) 
        nm <- nm[-idx]
    idx <- grep("^(\\._|\\.\\.)", nm)
    if (length(idx)) 
        nm <- nm[-idx]
    names(nm) <- nm
    res <- lapply(nm, function(fun) {
        obj <- get(fun, envir = as.environment(env))
        if (mode(obj) == "function") {
            if (is.null(formals(obj))) 
              NULL
            else sapply(formals(obj), function(param) {
              ifelse(is.character(param), shQuote(param, "sh"), 
                gsub("\"", "'", as.character(as.expression(param))))
            })
        }
        else NULL
    })
    res <- sapply(res, function(obj) {
        if (is.null(obj)) 
            NULL
        else {
            paste(rep(c(rep("",3), "\n               "), length.out = length(obj)), htmlspecialchars(ifelse(obj == "", names(obj), 
              paste(names(obj), obj, sep = " = "))), sep = "")
        }
    })
    # lapply(setdiff(search(), pkg0), detach, character.only = TRUE)
    # do.call(Sys.setenv, as.list(env0))
    # dll1 <- setdiff(sapply(getLoadedDLLs(), '[[', 'path'),
    #    dll0)
    # Cairo-related DLLs can cause conflicts (e.g. Cairo & RGtk2), so unload them
    # if (length(idx <- grep('Cairo', dll1))) {
    #     lapply(dll1[idx], dyn.unload)
    # }
    if(inherits(pb, "txtProgressBar"))
      setTxtProgressBar(pb,getTxtProgressBar(pb)+1)
    res
}

# Important! needs to sort in the 'C' locale
invisible(Sys.setlocale(, "C"))
{
cat("  finding function names . . .\n")
pl<-.packages(all.available = FALSE)
pb<-txtProgressBar(0,length(pl),style=3)
z <- lapply(.packages(all.available = FALSE), findfuns)
close(pb)
}
zz <- list()
for (i in 1:length(z)) zz <- c(zz, z[[i]])
nm <- sort(unique(names(zz)))
res <- list()
for (i in nm) res[i] <- zz[i]
res[["."]] <- NULL
nm <- names(res)
{ cat("  Writing to R.xml\n")
pb <- txtProgressBar(0, length(res), style=3)
for (i in 1:length(res)) {
    obj <- res[[i]]
    cat(if (length(obj) == 0) 
        sprintf(strNoFun, nm[i])
    else sprintf(strFun, nm[i], paste(sprintf("               <Param name=\"%s\" />", 
        obj), collapse = "\n")), file = "R.xml", append = TRUE)
    setTxtProgressBar(pb, i)
} 
close(pb)
}
cat('   </AutoComplete>
</NotepadPlus>
', file = 'R.xml', append = TRUE)

