css_addons <- tags$head(
  tags$style(HTML(paste0(
    
    # fixes large datatables flashing and adds margin on bottom
    "#n_ins_tbl{min-height: 480px;margin-bottom: 30px;}
      #single_tbl{min-height: 480px;margin-bottom: 30px;}
      #single_gl_tbl{min-height: 480px;margin-bottom: 30px;}"
    ,
    # fixes textareainput box in multiple dropdown
    "#n_igl{width: 200px;height: 100px;overflow-y: scroll;resize: none;}"
    ,
    # fixes visnetwork footer
    "#vis_network{margin-bottom:35px;}"
    ,
    # fixes modal padding
    ".modal-body {
            position: relative;
            padding: 15px;
            margin: 0px 10px 0px 10px;
        }",
    # fixes modal footer
    ".modal-footer {
            border-top-color: #f4f4f4;
            margin: 0px 20px 0px 20px;
      }",
    # fixes warning button color
    ".btn-warning {
          background-color: #f39c12;
          border-color: #e08e0b;
          color: white;
      }",
    # fixes primary button color
    ".btn-primary {
        background-color: #2c6eaf;
        border-color: #184d82;
        color: white;
      }",
    # fixed delete deg panel top margin
    "#delete_deg .shiny-input-container{
        margin-top: -20px;
      }",
    
    # fixes guide button left/right margins
    "#guide_1a {margin: 0 1em 0 1em;}",
    
    # fixes word wrap of input gene list widget
    "#n_igl_nm {word-break: break-word;}",
    
    # fix some tooltips width within narrow divs
    "#ui_intersections .tooltip.bottom{
      width:120px;} 
      #n_ins_view .tooltip.right{
      width:180px;} 
      #nxy_sc_dflogic .tooltip.right{
      width:200px;} 
      #nxyz_sc_dflogic .tooltip.right{
      width:200px;} 
    "
    
    
  )))
)