# -------------- TAB 3 -------------------

body_filters <- tabItem(tabName = "tab_filters",
                        fluidRow(
                          
                          column(3,
                                 box(id="select_n_panel",
                                   title = span(strong("2.1."),icon("vials"),"Select datasets"), status = "primary", solidHeader = F, width=12, collapsible=T,
                                   
                                   div(id="n0_1", uiOutput("select_df_p2"), style="word-break:break-all;"),
                                   div(id="n0_2", style="height:60px",
                                       uiOutput("n_shared")
                                   ),
                                   
                                   div(id="n0_3",
                                       actionButton("n_use_data", "Confirm", class = "btn-warning")
                                   )
                                   
                                   ),
                                 
                                 box(id="f_global",
                                     title = span(strong("2.2."),icon("filter"),"Apply filters"), status = "primary", solidHeader = F, width=12, collapsible=T, collapsed=T,
                                     uiOutput("f_apply_filters_panel"),
                                     
                                     
                                     ),
                                 collapseInput(inputId = "f_global_iscollapsed", boxId = "f_global"),
                                 
                                 
                                 ),
                          
                          
                          column(9,
                                 
                                 uiOutput("f_filtering_ui")
                                 
                                 )
                        ),
                 # fluidRow(
                 #   column(12,
                 #          box(
                 #            title = span(icon("cut"),"Apply Filters"), status = "primary", solidHeader = F, width=12,
                 #            # uiOutput("ui_n_gls_opt"),
                 #            hr(),
                 #            "Display gene lists here"
                 #          )
                 #   )
                 # )
                 # ,
                 fixedPanel(
                   style = "z-index:9999",
                   uiOutput("f_floating_buttons"),
                   right = 30,
                   bottom = 30
                 )
                 
                 
)


