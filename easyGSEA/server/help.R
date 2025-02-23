# the events trigger by pressing the help button on each tabs
observeEvent(input$help_tab1, {
  # check if a demo session
  if(rv$demo_mode == "gsea"){
    call_introjs(rbind(intros$R_pre,intros$R_post_with_conversion_table,intros$R_post))
  }else if(rv$demo_mode == "ora"){
    call_introjs(rbind(intros$R_pre_ora,intros$R_post_with_conversion_table_ora,intros$R_post_ora))
  }else if(rv$demo_mode == ""){
    # check the mode of analysis
    if(input$selected_mode == "gsea"){
      #first check if the user have upload a file
      if (is.null(rv$data_head)==T){
        call_introjs(intros$R_pre)
      } else {
        # if yes, check if the file has a conversion table
        if(!is.null(rv$gene_lists_mat1)){
          # load corresponding introjs for files with converison table
          call_introjs(rbind(intros$R_post_with_conversion_table,intros$R_post))
        }
        else{
          call_introjs(intros$R_post)
        }
      }
      # else it must be in ora mode
    } else {
      #first check if the user have upload a file
      if (is.null(rv$gene_lists_after)==T){
        call_introjs(intros$R_pre_ora)
      } else {
        # if yes, check if the file has a conversion table
        if(!is.null(rv$gene_lists_mat2)){
          # load corresponding introjs for files with converison table
          call_introjs(rbind(intros$R_post_with_conversion_table_ora,intros$R_post_ora))
        }
        else{
          call_introjs(intros$R_post_ora)
        }
      }
    }
  }
      


})

observeEvent(input$help_tab2, {
  # if (is.null(rv$fgseagg)==T){
  #   call_introjs(intros$ER_pre)
  # } else {
    # check if any of the diagram exists, if yes, go through them
    if(!is.null(rv$kegg_confirm)|| !is.null(rv$wp_confirm)|| !is.null(rv$reactome_confirm)){
      call_introjs(rbind(intros$ER_post,intros$ER_post_with_pathway))
    } else {
        call_introjs(intros$ER_post)
      }
  # }
})

observeEvent(input$help_tab3, {
  # if (is.null(rv$fgseagg)==T){
  #   call_introjs(intros$EN_pre)
  # } else {
    call_introjs(intros$EN_post)
  # }
})

observeEvent(input$help_tab4, {
  if (is.null(rv$fgseagg)==T){
    call_introjs(intros$D_pre)
  } else {
    call_introjs(intros$D_post)
  }
})

# the help buttons fixed on the each tab
output$floating_button_tab1 <- renderUI({
    div(
        actionBttn(
          inputId = "help_tab1", label=NULL,
          icon = icon("question"), style="material-circle", color="primary", size="lg"
        )
    )
})

output$floating_button_tab2 <- renderUI({
  req(is.null(rv$fgseagg)==F)
    div(
        actionBttn(
          inputId = "help_tab2", label=NULL,
          icon = icon("question"), style="material-circle", color="primary", size="lg"
        )
    )

})

output$floating_button_tab3 <- renderUI({
  req(is.null(rv$fgseagg)==F)
    div(
        actionBttn(
          inputId = "help_tab3", label=NULL,
          icon = icon("question"), style="material-circle", color="primary", size="lg"
        )
    )

})

output$floating_button_tab4 <- renderUI({
    div(
        actionBttn(
          inputId = "help_tab4", label=NULL,
          icon = icon("question"), style="material-circle", color="primary", size="lg"
        )
    )
})

# the function that call rintrojs
call_introjs <- function(file_name) {
  rintrojs::introjs(session, options = list(showStepNumbers=FALSE,
                                            steps = file_name)
  )
}
