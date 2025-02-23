# -------------------------------------------------------------------- #
####                      General data processing                   ####
# -------------------------------------------------------------------- #
# find overlapping terms between two vectors
find_overlap <- function(x,db,tolower=T){
  if(tolower){
    return(x[tolower(x) %in% tolower(db)])
  }else{
    return(x[x %in% db])
  }
}

# update RV value according to the input
input2rv <- function(id){
  if(!is.null(input[[id]])){
    rv[[id]] <- input[[id]]
  }
}

# pass value rv if input is.null
ifelse_rv <- function(id){
  if(is.null(input[[id]])){
    rv[[id]]
  }else{
    input[[id]]
  }
}

# pass value rv if input is.na
ifelse_rv_na <- function(id){
  if(is.na(input[[id]])){
    rv[[id]]
  }else{
    input[[id]]
  }
}

# update numeric RV only if min-max range
update_numericRV <- function(
  id, min = 0, max = Inf
){
  value <- ifelse_rv_na(id)
  if(value < min){value <- rv[[id]]}else{rv[[id]] <- value}
  if(value > max){value <- rv[[id]]}else{rv[[id]] <- value}
  return(value)
}

# waiting message for withProgress if data processing takes too long
# Example use: withProgress(message = wait_msg("Autodetecting and converting gene IDs..."),{})
wait_msg <- function(msg, msg_base=" This might take a while. Please wait a minute. Thank you."){
  paste0(
    msg,
    msg_base
  )
}

# enable extensions, scrolling X and Y, and customizing Y scren height
#   df_no(df,extensions=c('Scroller'), scrollY = "380px", scroller = TRUE, scrollX=TRUE)
# example:
# in the UI element:
#   dataTableOutput("")
# in the server element:
#   DT::renderDataTable({
#       df_no(df)
#   })

df_no <- function(df,extensions=c('Scroller'), dom = NULL, buttons = NULL, scrollY = "380px", scroller = TRUE, scrollX=TRUE){
  DT::datatable(df,
                extensions=extensions,
                # filter = list(position = "bottom", clear = T, plain = T),
                options = list(
                  # sDom  = '<"top">lrt<"bottom">ip',
                  dom = dom,
                  buttons = buttons, #, 'excel', 'print'
                  scrollY = scrollY,
                  scroller = scroller,
                  scrollX = scrollX
                ))
}

# -------------------------------------------------------------------- #
####                             UI elements                        ####
# -------------------------------------------------------------------- #


# # Function to draw an info box to guide the user along the pipeline
# You can pass html string into msg, e.g. : guide_box("<strong>This is a bold message</strong>")
# default color is blue
# default width is 12 (maximum), must be is an integer value
# To make it appear on condition, call it in a conditional renderUI({})
# Then, observeEvent to next tab:
# observeEvent(input$guide1,{updateTabItems(session, "menu1", "tab3")})

guide_box <- function(id,msg, color="warning", size="sm"){
  actionBttn(
    id,
    HTML(msg),
    icon=icon("angle-double-right"),
    style = "simple", color=color, size = size
    , block = T
  )
}


# # enhanced page progress infobox
# call in renderUI on the server side. you need to wrap this in a box
# 
# id: id of the list display (<ul>)
# prompt: shown in bold 
# msg: a vector of strings
# conditions: a vector of conditionals (T = condition fulfilled). should be SAME length as msg. 
# button renders only when all conditions are fulfilled.
# bttn_id: id of the button (use in observeEvent to jump to next tab)
# bttn_text: display text of the button
#
# example: 
# progress_box(id="infobox_1", prompt="To-dos:",
# msg=c("1. Search a valid GSE number", "2. Select a platform", "3. Read the study information", "4. This is a sample message", "This is another sample message"), 
# condition=c(!is.null(rv$gse_all), !is.null(rv$plat_id), !is.null(rv$plat_id), !is.null(rv$plat_id),!is.null(rv$plat_id)),
# bttn_id="next_p1", bttn_text="Continue to next panel"
# )

progress_box <- function(id, prompt, msg, condition, bttn_id, bttn_text="Continue to next panel"){
  
  icon <- vector(mode="list", length=length(msg))
  for(i in 1:length(msg)){
    # get icon
    if (condition[[i]]==T){
      icon[[i]] <- "<i class='fa fa-check' style='color:green;'></i>"
      msg[[i]] <- paste0("<span style='color:gray;'><strike>",msg[[i]],"</strike></span>")
    } else {
      icon[[i]] <- "<i class='fa fa-check' style='color:white;'></i>"
    }
  }
  display <- paste0("<li>", msg, icon, "</li>")
  display <- paste0(display, collapse="")
  if (all(condition)){
    bttn <- actionBttn(bttn_id, bttn_text, icon=icon("angle-double-right"), style="simple", color="primary", size="xs")
  } else {bttn <- ""}
  div(
    tags$head(tags$style(
      HTML(paste0("
        #",id," {margin-top:5px; margin-bottom:5px;padding-inline-start: 15px;display:inline;}
        ul#",id," li {display:inline; margin-right:30px;}
        ul#",id," i {margin-left:5px}"))
    )),
    HTML(paste0("<strong>",prompt,"</strong><ul id='",id,"'>", display,"
                  </ul>")),
    bttn
  )
}

# a link icon, need to wrap in HTML
# example: HTML(paste0("Visit eVITTA at ",link_icon("evitta_link","https://tau.cmmt.ubc.ca/eVITTA/")))
link_icon <- function(id, link, title="Click to visit", icon="fas fa-external-link-alt", color="#00c0ef", style=""){
  sprintf(
    '<a href="%s" target="_blank"><i class="%s" id="%s" style = "color:%s"></i></a>'
    ,link,icon,id,color)
}

# ------------- notification panel ------------------
panel_null <- function(text = "Data available upon selection of a platform."){
  box(
    title = span( icon("exclamation"), "Notification"), status = "warning", width=6,
    text
  )
}

# -------------------------------------------------------------------- #
####                          Data parsing                          ####
# -------------------------------------------------------------------- #
# summarize gpl info when GSEMatrix = F
summarize_gpl_F <- function(gse){
  ids <- c()
  out <- GPLList(gse) %>%
    lapply(., function(x) {
      metadata <- Meta(x)
      id <- metadata[["geo_accession"]]
      ids <- c(ids, id)
      gsmlist <- Filter(function(gsm) {Meta(gsm)$platform_id==id},GSMList(gse))
      samplen <- length(gsmlist)
      query <- c("organism", "molecule", "strategy")
      tempp <- Meta(gsmlist[[1]])
      for (nn in query){
        fn <- tempp[grep(nn, names(tempp))]
        if (length(fn)>0){
          assign(nn, paste(unique(fn[[1]]), collapse=", ")) # wrap in paste to ensure atomic
        } else {
          assign(nn, "")
        }
      }
      type <- paste(Meta(gse)$type, collapse=", ") # wrap in paste to ensure atomic
      rv$gpl_type <- c(rv$gpl_type, type)
      rv$gpl_count <- c(rv$gpl_count, Meta(gsmlist[[1]])$channel_count)
      rv$organism <- organism
      c(ID=id, Organism=organism, Samples=samplen, Type=type, Molecule=molecule, Strategy=strategy)
    })
  
  out
}


# requires the transform_vector() function in global
# parse characteristics columns from GSE 
# and gather into named list of named vectors (char_list)
# sample output:
# $GSM245051
#          Gender             Age          Tissue 
#        "female" "Premenopausal" "Normal Breast" 
# 
# $GSM245052
#          Gender             Age          Tissue 
#        "female" "Premenopausal" "Normal Breast" 
# 
# note: this guards against cases where many characteristics dimensions are condensed in one string
# e.g. "Gender: female, Age: Premenopausal, Tissue: Normal Breast"

extract_char_list <- function(#gse,
                              oneline_guard= T, # to guard against one-line characteristics
                              sep_guard = ", ", # delimiter of one-line characteristics
                              replace_empty=T, # whether or not to replace empty string as NA
                              keyword="characteristics" # the substring to filter our characteristics columns
){
  
  # tidy characteristics
  char_list <- data.frame(t(data.frame(rv$pdata) %>% dplyr::select(contains(keyword)))) #pData(phenoData(gse))
  colnames(char_list) <- rv$all_samples
  
  if (replace_empty==T){
    char_list[char_list==""] <- NA
  }
  
  if (oneline_guard==T){
    if(rv$getgeo_mode){
      char_list <- lapply(char_list, function(x){paste(x, collapse=sep_guard)}) # squeeze down to one dimension
    }else{
      char_list <- lapply(char_list, function(x){paste(unlist(x), collapse=sep_guard)}) # squeeze down to one dimension
    }
      char_list <- lapply(char_list, function(x){strsplit(x, sep_guard)[[1]]}) # restore dimensionality
  }
  
  char_list <- as.list(char_list)
  char_list <- lapply(char_list, function(x){
    x[x!="NA"]
  }) # remove NA vars at this step
  
  # map list of characters into dataframe format (those not found = NA)
  char_list <- lapply(char_list, function(x){
    transform_vector(x, ": ")
  })
  
  
  char_list
  
  
}


# construct a dataframe from a char_list output
# outputs a dataframe (the design matrix,  rv$dmdf)
# rows are GSM numbers; columns are variables; entries are levels

char_mat_from_list <- function(char_list,
                               column_class = "factor", # only factor now
                               keep_single_factor_vars = T, # default T
                               fill_na_with_string=T, # whether to fill NA with fill_string
                               fill_string ="N/A" # string to fill NA with
){
  # get var names
  chars <- names(table(unlist(lapply(char_list, names))))
  
  ls <- lapply(char_list,function(x){
    xx<- rep(NA, length(chars))
    names(xx) <- chars
    xx[names(x)] <- x
    xx
  })
  # ls
  char_mat <- data.frame(t(data.frame(ls)))
  
  
  if (keep_single_factor_vars==F){
    # get rid of single factor columns ; kept by default
    to_keep <- function(x) any(is.numeric(x), length(unique(x)) > 1)
    char_mat <- Filter(to_keep, char_mat)
  }
  
  if (fill_na_with_string==T){
    # fill NAs with string?? (optional)
    char_mat[is.na(char_mat)] <- fill_string
    char_mat[char_mat=="NA"] <- fill_string
  }
  
  # convert cols type. currently, all is converted to factor
  # in the future: integers >> numeric, char >> factor
  char_mat[] <- lapply(char_mat, function(x) {
    # if (column_class == "factor"){
    as.factor(x)
    # } else if (column_class == "numeric and factor"){ # disabled
    # if(is.integer(x) | is.numeric(x)) {
    #     as.numeric(x) 
    # } else {
    # as.factor(x)
    # }
    # }
  })
  char_mat 
}

# ---------- convenience df functions: ---------------

# convert rownames to first column
rown_to_firstcol <- function(df, colname="Name"){
  ot <- cbind("Name"=rownames(df), df)
  colnames(ot)[[1]] <- colname
  rownames(ot) <- seq(1, nrow(ot))
  ot
}


# convert first column to rownames
firstcol_to_rown <- function(df){
  ot <- df[-1]
  rownames(ot) <- df[[1]]
  ot
}



# -------------------------------------------------------------------- #
####                   DE and visualization                         ####
# -------------------------------------------------------------------- #

# basic function to filter DE table
filter_df <- function(
  df = rv$deg,q_cutoff=input$tl_q,logfc_cutoff=input$tl_logfc
){
  # filter table according to q & logFC
  df %>%
    dplyr::filter(get(fdr_column()) < q_cutoff, abs(get(fc_column()))>=logfc_cutoff)
}

# mutate digits to 2 decimals in DE table
mutate_df <- function(
  df = filter_df()
){
  genes = rownames(df)
  
  col_names <- colnames(df)
  string1 <- find_overlap(col_names,string1_db)
  string2 <- find_overlap(col_names,string2_db)
  
  df <- df %>% 
    dplyr::mutate_at(string1,function(x) round(x, digits = 1)) %>%
    dplyr::mutate_at(string2,function(x) scientific(x, digits = 2))

  rownames(df) = genes
  
  return(df)
}

# ------------- visualization: volcano -------------------

# input table for volcano plots
volcano_df <- function(
  df = rv$deg,q_cutoff=rv$plot_q,logfc_cutoff=rv$plot_logfc
){
  # genes
  genes = rownames(df)
  
  # mutate 0 to a small value
  df = df %>%
    mutate_if(is.numeric,  ~replace(., . == 0, 0.0000000001))
  
  # threshold by q & logfc cutoffs
  threshold_OE <- df[[fdr_column()]] < q_cutoff & abs(df[[fc_column()]])>=logfc_cutoff
  df$threshold <- threshold_OE
  
  # add rownames
  rownames(df) = genes
  
  return(df)
}

# basic function to plot static volcano
volcano_basic <- function(
  df,q_cutoff,logfc_cutoff,text="no"
){
  # pre-set volcano dot colors
  if(rv$plot_label == "threshold"){
    v_col <- c("grey","red")
  }else if(rv$plot_label == "top"){
    v_col <- c("blue","grey","red")
  }else if(rv$plot_label == "manual"){
    v_col <- c("grey","red")
  }
  
  fig <- ggplot(df) +
    geom_point(aes(x=.data[[fc_column()]],y=-log10(.data[[fdr_column()]]),colour=threshold)) +
    scale_colour_manual(values = v_col) +
    xlab(fc_column()) + ylab(paste0("-log10(",fdr_column(),")")) +
    theme_minimal() +
    theme(legend.position="none",
          plot.title = element_text(size = rel(1.5), hjust = 0.5),
          axis.title = element_text(size = rel(1.5)),
          axis.text = element_text(size = rel(1.25))
    )
  
  if(rv$show_padj){
    fig <- fig + geom_hline(yintercept=-log10(q_cutoff), linetype=rv$v_threshold_line, color="darkgrey")
  }
  if(rv$show_logfc){
    fig <- fig + geom_vline(xintercept=c(-logfc_cutoff,logfc_cutoff), linetype=rv$v_threshold_line, color="darkgrey") 
  }
  
  if(text=="yes"){
    fig <- fig +
      geom_text_repel(data = df[which(df$threshold!="grey"),],size=5,
                      aes(x=.data[[fc_column()]],y=-log10(df[which(df$threshold!="grey"),][[fdr_column()]]),label=genelabels)
                      ,max.overlaps = getOption("ggrepel.max.overlaps", default = 20)
      )
  }
  
  return(fig)
}

# basic function to plot different modes of volcano
volcano_ggplot <- function(
  df=volcano_df(),q_cutoff=rv$plot_q,logfc_cutoff=rv$plot_logfc
){
  # plot by threshold
  if(rv$plot_label == "threshold"){
    fig <- volcano_basic(df,q_cutoff,logfc_cutoff,text="no")
    
    rv$v_success = "yes"
    return(fig)
    
    # plot by top genes
  }else if(rv$plot_label == "top"){
    no_down = rv$volcano_down
    no_up = rv$volcano_up
    
    # order df by top down regulations
    df_ordered = df[order(df[[fc_column()]],df[[fdr_column()]]),]
    y_genes = rownames(df_ordered)
    labels_down = rev(y_genes[1:no_down])
    
    # order df by top up regulations
    df_ordered = df[order(-df[[fc_column()]],df[[fdr_column()]]),]
    y_genes = rownames(df_ordered)
    labels_up = y_genes[1:no_up]
    
    # calculate # not labeled
    no_unlabel = nrow(df_ordered) - no_down - no_up
    # Blake added these two lines to avoid that # of not labeled to be below 0
    if(no_unlabel <= 0){
      no_unlabel = nrow(df_ordered)
      labels_up = NULL
      labels_down = NULL
    }
    
    # create genelabels
    df_ordered$genelabels = c(labels_up,rep("",no_unlabel),labels_down)
    
    df_ordered$threshold = c(rep("red",length(labels_up)),rep("grey",no_unlabel),rep("blue",length(labels_down))) #df_ordered$genelabels != ""
    
    fig <- volcano_basic(df_ordered,q_cutoff,logfc_cutoff,text="yes")
    
    rv$v_success = "yes"
    return(fig)
    
    # plot by manual selection of genes    
  }else if(rv$plot_label == "manual"){
    in_genes = rv$gene_lists_v
    
    if(is.null(in_genes)==F && length(in_genes)>0){
      # re-threshold
      threshold_OE = rownames(df) %in% in_genes
      threshold_OE <- sapply(threshold_OE, function(x){
        ifelse(x, "red", "grey")
      })
      df$threshold <- threshold_OE

      # add gene labels
      df$genelabels = ""
      df$genelabels[which(df$threshold=="red")] = rownames(df)[which(df$threshold=="red")]

      fig <- volcano_basic(df,q_cutoff,logfc_cutoff,text="yes")
      
      rv$v_success = "yes"
      return(fig)
    }
  }
  
}

volcano_plotly <- function(
  df=volcano_df(),q_cutoff=rv$plot_q,logfc_cutoff=rv$plot_logfc
){
  
  fig <- ggplot(df) +
    geom_point(aes(x=.data[[fc_column()]],y=-log10(.data[[fdr_column()]]),colour=threshold,
                   text=paste0(
                     "<b>",rownames(df),"</b>\n",
                     fc_column(),"=",signif(.data[[fc_column()]],digits=3),"\n",
                     fdr_column(),"=",signif(.data[[fdr_column()]],digits=3)
                   ))) +
    scale_colour_manual(values = c("grey","red")) +
    xlab(fc_column()) + ylab(paste0("-log10(",fdr_column(),")")) +
    theme_minimal() +
    theme(legend.position = "none",
          plot.title = element_text(size = rel(1.5), hjust = 0.5),
          axis.title = element_text(size = rel(1.25)))
  
  if(rv$show_padj){
    fig <- fig + geom_hline(yintercept=-log10(q_cutoff), linetype=rv$v_threshold_line)
  }
  if(rv$show_logfc){
    fig <- fig + geom_vline(xintercept=c(-logfc_cutoff,logfc_cutoff), linetype=rv$v_threshold_line)
  }
  
  fig <- ggplotly(fig,tooltip = "text")
  
  rv$v_success = "yes"
  return(fig)
}

# ------------- visualization: heatmap -------------------
# filtered DEG table for heatmaps
hm_df <- function(
  df = rv$deg,q_cutoff=rv$plot_q,logfc_cutoff=rv$plot_logfc
){
  # filter table according to q & logFC
  df = df %>%
    dplyr::filter(get(fdr_column()) < q_cutoff, abs(get(fc_column()))>=logfc_cutoff)
  
  # genes
  genes = rownames(df)
  
  #  mutate 0 to a small value
  df = df %>%
    mutate_if(is.numeric,  ~replace(., . == 0, 0.0000000001))
  
  # add rownames
  rownames(df) = genes
  
  # order df according to logFC & FDR
  # df = df[order(-df[[fc_column()]],df[[fdr_column()]]),] 
  df = df %>% dplyr::arrange(across(matches(fc_column())))
  
  # original table if manual selection of genes
  if(rv$plot_label == "manual"){
    df = rv$deg %>% dplyr::arrange(across(matches(fc_column())))
  }
  
  return(df)
}

# filtered count table for heatmaps
hm_count <- function(
  df = hm_df(),counts = rv$deg_counts
){
  genes = rownames(df)
  counts = data.frame(counts[match(genes,rownames(counts)),],stringsAsFactors = F)
  
  # Blake editted these two lines for Manual upload
  if(rv$run_mode == "auto"){
    if(rv$h_y_name == "title"){
      samples = colnames(counts) %>%
        translate_sample_names(.,  rv$pdata[c("title", "geo_accession")],  "title")
      
      colnames(counts) = samples
    }
  } else {
    samples = colnames(counts)
    colnames(counts) = samples
  }
  
  if(rv$plot_label_hm == "top"){
    # top up regulated genes
    genes_up = df %>% dplyr::arrange(desc(across(matches(fc_column())))) %>% #df[order(-df[[fc_column()]],df[[fdr_column()]]),]
      head(.,n=rv$volcano_up) %>%
      rownames(.)
    
    # top down regulated genes
    genes_down = df %>% dplyr::arrange(across(matches(fc_column()))) %>% #df[order(df[[fc_column()]],df[[fdr_column()]]),]
      head(.,n=rv$volcano_down) %>%
      rownames(.)
    
    # combine genes
    genes = c(genes_up,genes_down)
    
    # filter counts
    counts = counts[match(genes,rownames(counts)),]
    
  }else if(rv$plot_label == "manual"){
    # filter counts
    counts = counts[match(rv$gene_lists_v,rownames(counts)),]
  }
  
  return(counts)
}

# function to plot heatmaps
hm_plot <- function(
  counts=hm_count(),df = hm_df()
){
  if(is.null(counts) | nrow(counts)<1){
    return(NULL)
  }else{
    samples = colnames(counts)
    titlex = "Expression"
    
    # prepare colorscale
    # req(is.null(rv$h_cscale)==F)
    useColorscale <- suppressWarnings(makePlotlyColorscale(get(rv$h_cscale), "even", rev=rv$h_cscale_rev))
    # if divergent colorscale, center at 0; if sequential, no centering
    if (rv$h_cscale %in% divScalesList){centerVal=0} else {centerVal=NULL}
    
    # if applicable, log2 transform count matrix
    if(rv$h_log == "yes"){
      counts = log2(counts+1)
      
      titlex = "Log2(expression+1)"
    }
    
    # if applicable, z-score transform count matrix
    if(rv$h_zscore == "yes"){
      counts = t(apply(counts,1,scale))
      colnames(counts) = samples
      
      titlex = "Z-score-transformed log2(expression+1)"
      
    }
    
    # make matrix for plot
    dat <- expand.grid(y = rownames(counts), x = colnames(counts))
    dat$z <- unlist(as.data.frame(counts),recursive = T)
    req(length(dat$z)>0)
    
    # genes and their logFC & FDR info
    genes = rownames(counts)
    df = df[match(genes,rownames(df)),]
    logFCs = rep(signif(df[[fc_column()]],digits = 3),ncol(counts))
    FDRs = rep(signif(df[[fdr_column()]],digits = 3),ncol(counts))
    
    # combine into text
    textx = paste0(fc_column(),": ",logFCs,"<br>",fdr_column(),": ",FDRs)
    
    
    fig <- plot_ly() %>%
      add_trace(data = dat, x = ~x, y = ~y, z = ~z, type = "heatmap",
                # colorscale  = cscale_zscore,
                colorscale = useColorscale,
                zauto = T, zmid= centerVal, 
                colorbar = list(title = list(text=titlex, side = "right")),
                text = textx,
                hovertemplate = paste('Gene: <b>%{y}</b><br><br>',
                                      'Sample: %{x}<br>',
                                      'Value: %{z:.3f}<br><br>',
                                      '%{text}'
                )
      )
    
    fig <- fig %>% layout(
      xaxis = list(title = "", showticklabels = T),
      yaxis = list(title = "", showticklabels = F)
      # ,margin = list(l=200)
    )
    
    rv$h_success = "yes"
    return(fig)
    
  }
}

# ------------- visualization: violin/box -------------------
# data for violin/box plot
vb_data <- function(
  gene=rv$a_gene,counts = rv$deg_counts
){
  counts = as.data.frame(counts) %>% dplyr::filter(rownames(counts)==rv$a_gene)
  
  # if applicable, log2 transform counts
  if(rv$a_log == "yes"){
    counts = log2(counts+1)
  }
  
  counts_c = counts %>% dplyr::select(one_of(rv$samples_c)) %>% unlist(.)
  counts_t = counts %>% dplyr::select(one_of(rv$samples_t)) %>% unlist(.)
  
  r1 <- data.frame(x=c(rep(rv$c_level,length(rv$samples_c))),y=counts_c);row.names(r1) <- NULL
  r2 <- data.frame(x=c(rep(rv$t_level,length(rv$samples_t))),y=counts_t);row.names(r2) <- NULL
  
  rr <- rbind(r1,r2)
  
  rr$x = factor(rr$x,levels=c(rv$c_level,rv$t_level))
  
  return(rr)
}

# violin plot
data_summary <- function(x,k=rv$a_k) {
  m <- mean(x)
  ymin <- m - k * sd(x)
  ymax <- m + k * sd(x)
  return(c(y=m,ymin=ymin,ymax=ymax))
}

violin_plt <- function(y_label){
  rr=vb_data()
  
  p <- ggplot(rr,aes(x=x,y=y,color=x)) +
    geom_violin(trim=FALSE) +
    scale_color_manual(values=c("blue","orange")) +
    stat_summary(fun.data=data_summary,geom="pointrange", color="grey") +
    geom_jitter(height = 0, width = 0.1) +
    labs(title=rv$a_gene,y=y_label,x="") +
    theme_classic() +
    theme(legend.position="none",
          plot.title = element_text(size = rel(1.5), hjust = 0.5),
          axis.title = element_text(size = rel(1.5)),
          axis.text = element_text(size = rel(1.5))
    )
  
  rv$a_success = "yes"
  return(p)
}

# box plot
box_plt <- function(y_label){
  rr=vb_data()
  
  p<-ggplot(rr,aes(x=x,y=y)) + 
    geom_boxplot(color=c("blue","orange")) +
    labs(title=rv$a_gene,y=y_label,x="") +
    theme_classic() +
    theme(legend.position="none",
          plot.title = element_text(size = rel(1.5), hjust = 0.5),
          axis.title = element_text(size = rel(1.5)),
          axis.text = element_text(size = rel(1.5))
    )
  
  rv$a_success = "yes"
  return(p)
  
  
}

# ================ initialize demo RVs =================
init_demo <- function(){
  if(rv$run_mode == "auto"){
    # initialize all required rv for a demo run
    rv$demo_acc = "GSE147507"
    rv$gse_all = readRDS(paste0(getwd(),"/rvs/gse_all.rds"))
    rv$geo_accession <- "GSE147507"
    rv$platforms = readRDS(paste0(getwd(),"/rvs/platforms.rds"))
    rv$plat_id <- 1
    rv$gpl_summary <- readRDS(paste0(getwd(),"/rvs/gpl_summary.rds"))
    rv$gpl_choices <- readRDS(paste0(getwd(),"/rvs/gpl_choices.rds"))
    rv$dmdf <- readRDS(paste0(getwd(),"/rvs/dmdf.rds"))
    rv$all_samples <- readRDS(paste0(getwd(),"/rvs/all_samples.rds"))
    # rv$samples <- readRDS(paste0(getwd(),"/rvs/samples.rds"))
    rv$pdata <- readRDS(paste0(getwd(),"/rvs/pdata.rds"))
    rv$fddf <- readRDS(paste0(getwd(),"/rvs/fddf.rds"))
    rv$sup_source <- readRDS(paste0(getwd(),"/rvs/sup_source.rds"))
    rv$suplist <- readRDS(paste0(getwd(),"/rvs/suplist.rds"))
    rv$deg <- readRDS(paste0(getwd(),"/rvs/deg.rds"))
    rv$deg_counts <- readRDS(paste0(getwd(),"/rvs/deg_counts.rds"))
    rv$c_var <- readRDS(paste0(getwd(),"/rvs/c_var.rds"))
    rv$c_level <- readRDS(paste0(getwd(),"/rvs/c_level.rds"))
    rv$t_level <- readRDS(paste0(getwd(),"/rvs/t_level.rds"))
    rv$samples_c <- readRDS(paste0(getwd(),"/rvs/samples_c.rds"))
    rv$samples_t <- readRDS(paste0(getwd(),"/rvs/samples_t.rds"))
    rv$deg_pdata <- readRDS(paste0(getwd(),"/rvs/deg_pdata.rds"))
    rv$gpl_tooltips <- readRDS(paste0(getwd(),"/rvs/gpl_tooltips.rds"))
    rv$text <- readRDS(paste0(getwd(),"/rvs/text.rds"))
    rv$matrix_ready <- readRDS(paste0(getwd(),"/rvs/matrix_ready.rds")) 
    rv$samples <- readRDS(paste0(getwd(),"/rvs/samples.rds")) 
    rv$demo <- "yes"
  } else {
    variable_list <- c("fddf_o", "dmdf", "all_samples", "pdata", "fddf", "sup_source",
                       "suplist", "deg", "deg_counts", "c_var", "c_level", "t_level", "samples_c",
                       "samples_t", "deg_pdata", "gpl_tooltips", "text", "matrix_ready", "samples", "dmdf_samples")
    for(i in seq_along(variable_list)){
      rv[[variable_list[i]]] <- readRDS(paste0(getwd(), "/rvs2/", variable_list[i], ".rds"))
    }
    rv$demo <- "yes"
  }
  # rv$fddf_o <- readRDS(paste0(getwd(), "/rvs/fddf_o.rds"))
}

# unload example
init_demo_d <- function(){
  # uninitialize all required rv for a demo run
  updateTextInput(session,"geo_accession",value="")
  rv$gse_all = NULL
  rv$geo_accession <- NULL
  rv$platforms = NULL
  rv$plat_id <- NULL
  rv$gpl_summary <- NULL
  rv$gpl_choices <- NULL
  rv$dmdf <- NULL
  rv$all_samples <- NULL
  rv$samples <- NULL
  rv$pdata <- NULL
  rv$fddf <- NULL
  rv$sup_source <- NULL
  rv$suplist <- NULL
  rv$deg <- NULL
  rv$deg_counts <- NULL
  rv$c_var <- NULL
  rv$c_level <- NULL
  rv$t_level <- NULL
  rv$samples_c <- NULL
  rv$samples_t <- NULL
  rv$deg_pdata <- NULL
  rv$gpl_tooltips <- NULL
  rv$text <- NULL
  rv$matrix_ready <- NULL
  rv$demo <- ""
  
  # RVs in manual mode
  rv$fddf_o <- NULL
  rv$dmdf_samples <- NULL
}

init_choices <- function(){
  updateRadioButtons(session, inputId = "data_type", selected = "raw")
  updateSelectInput(session, inputId = "sp_select_var", selected = "strain")
}

init_choices2 <- function(){
  updateCheckboxGroupInput(session, inputId = "sp_select_levels", selected = c("N/A","USA-WA1/2020"))
}

init_choices3 <- function(){
  updatePickerInput(session, inputId = "samples_c_deg", selected = c("GSM4462342", "GSM4462343", "GSM4462344"))
  updatePickerInput(session, inputId = "samples_t_deg", selected = c("GSM4462345", "GSM4462346", "GSM4462347"))
}

init_choices4 <- function(){
  updateSelectizeInput(session, inputId = "aplot_genes", selected = "CXCL2")
  rv$a_gene = "CXCL2"
}

init_choices_manual <- function(){
  updateCheckboxGroupInput(session, inputId = "sp_select_levels", selected = c("NHBE", "A549"))
}

# =============== demo toggle button ===============
btn_demo <- function(id){
  if(rv$demo_n %% 2 == 1){
    label = "Example Run"
    icon = "play"
    color = "success"
    style = "bordered"
    size = "xs"
  }else{
    label = "Unload Example"
    icon = "trash-alt"
    color = "default"
    style = "minimal"
    size = "sm"
    
  }
  
  fixedPanel(
    bottom = 25,
    actionBttn(id,label
               ,block = TRUE
               ,style = style
               ,color = color
               ,size = size
               ,icon = icon(icon)
    )
    
  )
}

btn_demo_e <- function(){
  withProgress(message = 'Updating session ...',
               value = 1,{
    rv$demo_n = rv$demo_n + 1
    if(rv$demo_n %% 2 == 1){
      init_demo_d()
    }else{
      init_demo()
    }
  })
}

# the function that creates a confirm and a reset button
# add an oberveEvent to connect those buttons with their functions
confirm_and_reset_buttons <- function(confirm_id, reset_id){
  fluidRow(
    column(
      12,
      div(style = "display:inline-block;",
          bsButton(confirm_id, "Manual Upload",style="primary")
      ),
      div(style = "display:inline-block;",
          actionButton(reset_id, "Dismiss")  
      )
    )
    
  )
}
# the function to jump to the Manual Upload mode
confirm_and_jump <- function() {
  rv$dmdf <- NULL
  rv$fddf <- NULL
  rv$plat_id <- NULL
  removeModal()
  updateTabItems(session, inputId = "menu1", selected = "tab1")
  updateRadioButtons(session, inputId = "selected_mode", selected = "manual")
}

# check the value of numericInput, if it is between minimum and maximum
# parameters: input_id: input id; default: default value; integer check: would you like it to be integer or not
check_numericInput <- function(input_id, default, minimum = 1, maximum = NULL, integer_check = TRUE){
  n <- input[[input_id]]
  req(!is.na(n))
  if(is.null(maximum)){
    if(integer_check == TRUE){
      n <- floor(input[[input_id]]); if(n<minimum){n <- default}
    } else {
      n <- n; if(n<minimum){n <- default}
    }
  } else{
    if(integer_check == TRUE){
      n <- floor(input[[input_id]]); if(n<minimum || n>maximum){n <- default}
    } else {
      n <- n; if(n<minimum || n>maximum){n <- default}
    }
  }
  updateNumericInput(
    session,
    input_id,
    value = n
  )
}

check_numericInput_na <- function(input_id, number_of_error, variable_name){
  if(is.na(input[[input_id]])){
    shinyalert(paste0("Please enter a valid value for ", variable_name))
    number_of_error <- number_of_error + 1
  }
  return(number_of_error)
}