Call_RCST_Octave_Scripts = function(comid_arg, input_dir_arg, split_parm_arg){
  require(processx)
  
  #proc <- processx::process$new("Octave", c("./run_wrapper.m", paste0("comid_", comid_arg), paste0(input_dir_arg), as.numeric(split_parm_arg)), stdout = "|")
  #processx::run("Octave", c("./run_wrapper.m", paste0("comid_", comid_arg), paste0(input_dir_arg), as.numeric(split_parm_arg)), stdout = "|")
  processx::run("octave", c("./run_wrapper.m", paste0("comid_", comid_arg), paste0(input_dir_arg), as.numeric(split_parm_arg)), stdout = "|")

  
  # Not returning the message to R console. Messages will be logged into output directory.
}