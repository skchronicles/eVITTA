# tabulate outputs of list function (for platform selection)
# --------------------------------------------------------
tabulate <- function(object, FUN){
  do.call(rbind, lapply(object, FUN))
}

# find columns that have one value and return named list of those values
find_repeating_values <- function(df){
  df <- df[vapply(df, function(x) length(unique(x)) == 1, logical(1L))] %>% mutate_all(unlist)
  as.list(df[1,])
}

# To transform named list to dataframe
# ---------------------------------------------------------
#   named_list_to_df(list, colnames)
# example:
#   named_list_to_df(gse_meta(), c("Field", "Value"))

named_list_to_df <- function(list, colnames){
  df <- data.frame(cbind(as.character(names(list)),
                         as.character(list)
  ))
  colnames(df) <- colnames
  df
}

# tidy df "field" columns
# ---------------------------------------------------------
tidy_field_col <- function(vector){
  # replace underscores
  vector <- unlist(lapply(vector, function(x){
    gsub("_"," ",x)
  }))
  # capitalize first word
  vector <- sub("(.)", "\\U\\1", vector, perl=TRUE)
  vector
}

# To extract all matched elements from named list
# --------------------------------------------------------
#   grep_multiple(to_match, grep_from, order=F)
# example:
#   grep_multiple(c("title", "study_type", "sample_count", "organism", "summary"), isolate(all_fields())$Field, order=T)
grep_multiple <- function(to_match, grep_from, order=F){
  if (order==F){
    matches <- unique(grep(paste(to_match,collapse="|"),
                           grep_from, value=TRUE))
  } else {
    matches <- unlist(lapply(to_match, function(x){
      grep(x, grep_from, value=TRUE)
    }))
  }
  
  matches
}

# transform characteristics column into named vector
# --------------------------------------------------------
transform_vector <- function(vector, sep=": "){
  ot = unlist(lapply(vector, function(x){
    if(is.na(x)==F){
      
      ss <- strsplit(x, sep)[[1]]
      out <- paste(ss[-1],collapse=": ")
      names(out) <- ss[[1]]
      
      return(out)
    }
  }))
  
  # check for duplicate variable names; if duplicated, add (1) (2) to the end
  if(length(unique(names(ot)))== length(names(ot))){
    ot
  } else {
    names(ot) <- rename_duplicates(names(ot), "_", "")
    ot
  }
  
}

# function to rename duplicate entries in a vector
# --------------------------------------------------------
# example:???rename_duplicates(c("a","a","a"), "_", "")
# > a_1 a_2 a_3

rename_duplicates <- function(vector, left, right){
  ave(as.character(vector), vector, FUN=function(x) if (length(x)>1) paste0(x[1], left, seq_along(x), right) else x[1])
}




# apply options to datatable. example: options = dt_options(80,F,F,T,T,T,10)
# To apply options to datatable. only works with ellipsis enabled
# ------------------------------------------------------------
#   dt_options (max_char, scrollX=F, scrollY=F, paging=T, searching=T, info=T, pageLength = 10, autoWidth=T)
# example:
#   renderDataTable({df}, plugins="ellipsis", options = dt_options(80,F,F,T,T,T,10))

dt_options <- function(max_char, scrollX=F, scrollY=F, paging=T, searching=T, info=T, pageLength = 10, autoWidth=T){
  list(scrollX=scrollX, scrollY=scrollY,
       paging=paging, searching=searching, info=info, pageLength = pageLength,
       autoWidth = autoWidth,
       columnDefs = list(
         list(
           targets = "_all",
           render = JS(paste0("$.fn.dataTable.render.ellipsis( ",max_char,", false )"))
         ))
  )
}



# To translate between sample names and GSE accessions (or other information in phenoData)
# ------------------------------------------------------------
#   translate_sample_names(original_vector, dict_df, output_type)
#
# example:
#   input = c("GSM3610107", "GSM3610108", "GSM3610109", "GSM3610110", "GSM3610111", "test")
# translate_sample_names(input,  rv$pdata[c("title", "geo_accession")],  "title")
# > "N2_AL_1", "hlh-30_AL_1", "N2_ARD_1", "hlh-30_ARD_1", "N2_AL_2", "test"
# anything not found is returned as is

translate_sample_names <- function(original_vector, dict_df, output_type){
  # try to match vector to every column in dict and get a score
  matches <- sort(unlist(lapply(dict_df, function(x){
    length(intersect(original_vector, x))
  })), decreasing = T)
  input_coln <- names(matches)[[1]] # this is the detected input column
  
  # translate according to dict df. if not found, preserve the original value
  output_vector <- unlist(lapply(original_vector, function(x){
    output_value <- dict_df[which(dict_df[[input_coln]]==x), ] %>% dplyr::select(all_of(output_type))
    if(nrow(output_value) < 1){
      return ("Name")
    }else{
      if (identical(output_value, character(0))) {
        return (x)
      } else {
        return (output_value)
      }
    }
    
  }))
  output_vector
}
# example input: "GSM3610107" "GSM3610108" "GSM3610109" "GSM3610110" "GSM3610111" "test"
# example output: "N2_AL_1"      "hlh-30_AL_1"  "N2_ARD_1"     "hlh-30_ARD_1" "N2_AL_2" "test"


# summarize gpl info.
#-------------------------------------
# returns a named list of named vectors, containing
# id, organism, molecule (both ch1), type, samplen
summarize_gpl <- function(gse){
  out <- lapply(seq_along(gse), function(i){
    tempp <- as.list(pData(phenoData(gse[[i]])))
    id <- annotation(gse[[i]])
    # only finds the ch1 organism.
    query <- c("organism", "molecule", "strategy")
    for (nn in query){
      fn <- tempp[grep(nn, names(tempp))]
      if (length(fn)>0){
        assign(nn, paste(unique(fn[[1]]), collapse=", ")) # wrap in paste to ensure atomic
        print(paste(unique(fn[[1]]), collapse=", "))
      } else {
        assign(nn, "")
      }
    }
    # get experiment type
    type <- paste(notes(experimentData(gse[[i]]))$type, collapse=", ") # wrap in paste to ensure atomic
    samplen <- length(sampleNames(gse[[i]]))
    c(ID=id, Organism=organism, Samples=samplen, Type=type, Molecule=molecule, Strategy=strategy)
  })
  names(out) <- tabulate(gse, annotation)
  out
}


# for a named vector or list, invert the names and values
#---------------------------------------------------
# useful for input choices.
invert_vector <- function(vector){
  out <- names(vector)
  names(out) <- vector
  out
}


# BStooltip for radiobutton choices
#--------------------------------------------------------------------------
# we need to construct some new function to replace the coarser bsTooltip.
# The new function is called radioTooltip and is basically a ripoff from bsTooltip. 
# It takes one more arguement, namely the choice of the radioButton you want the tooltip to be assigned to.
radioTooltip <- function(id, choice, title, placement = "bottom", trigger = "hover", options = NULL){
  
  options = shinyBS:::buildTooltipOrPopoverOptionsList(title, placement, trigger, options)
  options = paste0("{'", paste(names(options), options, sep = "': '", collapse = "', '"), "'}")
  bsTag <- shiny::tags$script(shiny::HTML(paste0("
    $(document).ready(function() {
      setTimeout(function() {
        $('input', $('#", id, "')).each(function(){
          if(this.getAttribute('value') == '", choice, "') {
            opts = $.extend(", options, ", {html: true});
            $(this.parentElement).tooltip('destroy');
            $(this.parentElement).tooltip(opts);
          }
        })
      }, 500)
    });
  ")))
  htmltools::attachDependencies(bsTag, shinyBS:::shinyBSDep)
}




# Function to call in place of dropdownMenu
# --------------------------------------------------------
dropdownMenuCustom <-     function (..., type = c("messages", "notifications", "tasks"),
                                    badgeStatus = "primary", icon = NULL, .list = NULL, customSentence)
{
  type <- match.arg(type)
  if (!is.null(badgeStatus)) shinydashboard:::validateStatus(badgeStatus)
  items <- c(list(...), .list)
  lapply(items, shinydashboard:::tagAssert, type = "li")
  dropdownClass <- paste0("dropdown ", type, "-menu")
  if (is.null(icon)) {
    icon <- switch(type, messages = shiny::icon("envelope"),
                   notifications = shiny::icon("warning"), tasks = shiny::icon("bars"))
  }
  numItems <- length(items)
  if (is.null(badgeStatus)) {
    badge <- NULL
  }
  else {
    badge <- span(class = paste0("label label-", badgeStatus),
                  numItems)
  }
  tags$li(
    class = dropdownClass,
    a(
      href = "#",
      class = "dropdown-toggle",
      `data-toggle` = "dropdown",
      icon
      # ,
      # badge
    ),
    tags$ul(
      class = "dropdown-menu",
      tags$li(
        class = "header",
        customSentence(numItems, type)
      ),
      tags$li(
        tags$ul(class = "menu", items)
      )
    )
  )
}

# ------------- add help buttons to labels (need to wrap again in HTML) ----------
# example of use: label=HTML("Label here", add_help("id1", style="padding:1px 1px 1px 1px;") )
add_help <- function(id, color="#00c0ef", style=""){
  out <- paste0("<i class='fa fa-question-circle' 
                style = 'color:",color,";
                font-size:medium;",style,"' 
                id='",id,"'></i>")
  
  HTML(out)
}

