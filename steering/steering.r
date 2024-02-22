# R steering file for modified "rapid-climate-stress-testing (RCST)" scripts, written by Donny Kim.
# San Diego State University, dkim8398@sdsu.edu (donnykim27@gmail.com)

# It calls modified version of Matlab/Octave scripts written by Keirnan Fowler, University of Melbourne, fowler.k@unimelb.edu.au
# Overall workflow or sequence of calling functions follows the example_run.m file written by Fowler.

# Integrated framework for rapid climate stress testing on a monthly timestep
# by Keirnan Fowler, Natasha Ballis, Avril Horne, Andrew John, Rory Nathan and Murray Peel 
# Licence: CC BY 3.0 - see https://creativecommons.org/licenses/by/3.0/au/


### ============================================================================
### Octave environment setup
# This R script is designed to govern the work flow of using modified version of Fowler's scripts (RCST) that only targets P and T.
# This R script will invoke system command to call the Octave scripts to run.

### Instruction for setting environment:
# 1. Install GNU Octave (https://octave.org/download.html)
#    Once Octave is installed in your device, you need to add it to system PATH. I assume the OS to be Windows 10.
# 2. Identify the path to the folder containing the binary of Octave (e.g. "C:\Program Files\GNU Octave\Octave-7.1.0\mingw64\bin")
# 3. Multiple options exists to add new PATH. FYI: https://stackoverflow.com/questions/9546324/adding-a-directory-to-the-path-environment-variable-in-windows
#    HOWEVER, the most safest way would be using Windows GUI.
# 4. Click Windows "Start" button -> type "Edit the System Environment Variables" to search and open it -> check you are under the "Advanced" tab
#    -> click "Environment Variables" -> Either in "User Variables" or "System Variables" Click variable called “Path” and click “Edit…”
#    -> Click “New” -> Copy and paste the path to Octave binary folder (e.g. "C:\Program Files\GNU Octave\Octave-7.1.0\mingw64\bin").
# 5. Now we are ready.
### environment setup end=======================================================




### ============================================================================
### Step 1: reformatting RF predictor for RCST inputs
### No need to run after processed it for the first time
library(tidyverse)

# Set working directory
#setwd('C:/Workspace/rapid-climate-stress-testing-SCCWRP/steering/'); getwd();
setwd('G:/RB9/rapid-climate-stress-testing-SCCWRP/steering'); getwd();
#setwd('/mnt/g/RB9/rapid-climate-stress-testing-SCCWRP/steering'); getwd();

# Source the functions
source('../R/utils.R')
# Note that directories for saving csv files of climate inputs are hard-coded in each function.
# To change the saving directory, edit it in "../R/utils.R".


# Creating inputs from RFpredictors format compiled by SCCWRP (RB9)
#RFpredictor_df <- read.csv('../RF_predictor/2022-03-28_RF_predictors_RB9_COMIDS.csv')[,1:45] # we only need column 1 to 45.
RFpredictor_df <- read.csv('../RF_predictor/NHD_COMIDs_RB9_SD_comid_predictor_data.csv')[,1:45] # we only need column 1 to 45.
colnames(RFpredictor_df) <- tolower(colnames(RFpredictor_df))

RB9_comid_list <- (RFpredictor_df %>% distinct(comid))$comid#[1:10] # Trying on 5 comids for test purpose

RCST_inputs_from_compiled_RFpredictors(RFpredictor_df, RB9_comid_list) # Run it. Ignore the dir.create warning.# In testing stage, I limited it to only 5 COMIDS.


# Creating inputs from raw RFpredictors format created by Ted Grantham
# I am just going to randomly call it a "raw" version.
# Because climate data files are scattered in different csv files, unlike SCCWRP compiled version of predictor inputs, we need to do this in loop.

dir.create('../hist_raw') # As function will be looping around multiple files, it is better to create directory once here.
comid_list_raw_FULL <- list.files(path = '../CA_All_COMID_descriptors_Ted/', full.names = F, recursive = T, ignore.case = TRUE) %>% 
  sub(pattern = "(.*)\\..*$", replacement = "\\1") %>% as.array() %>% as.integer()

comid_list_raw_RB9 <- intersect(comid_list_raw_FULL, RB9_comid_list)   # Subsetting 10 comids for test purpose.
comid_list<- comid_list_raw_FULL %>% as.list(as.numeric()) # Subsetting 10 comids for test purpose.
write.csv(comid_list_raw, paste0('../hist_raw/comid_list_raw.csv'),  row.names = FALSE, quote=FALSE, col.names = FALSE) # Save the list of comids

# Loop it.
for (i in 1:length(comid_list_raw)){
  RCST_inputs_from_raw_RFpredictors(comid_list_raw[i])
}

### Note:
# If you want to parallelize this step 1... (which is unnecessary)
# Use future_pmap ("furrr" package) for processing SCCWRP compiled predictors
# Use mcapply ("parallel" package) for processing Ted's raw predictors

### Step 1 end==================================================================




### ============================================================================
### Step 2: Setting RCST run options
# Before running RCST, there are 2 options that needs to be defined by user in Octave scripts


### 2. run_wrapper.m
### "run_wrapper.m" is the main wrapper that governs the workflow in RCST Octave scripts.
### While basic arguments are passed from R (steering.r), stress-test space needs to be manually set in "run_wrapper.m".
# 2-a. Open "rapid-climate-stress-testing-SCCWRP\steering\run_wrapper.m".
# 2-b. Navigate to line 144~147. To get a better idea of how the stress test space should be set, check line 130~143, and Fowler et al (2022).
# 2-c. Set the stress test space as desired, save, and close.


### 1. comid_info.m
### "run_wrapper.m" calls and pass comid argument to "comid_info function" to generate "info" data variable. 
# 1-a. Open "rapid-climate-stress-testing-SCCWRP\steering\comid_info.m". You'll see multiple lines commented out.
# 1-b. Only thing that needs any attention is line 23 (pars.WaterYearStart_clim) & 27 (pars.StochRepLen_yrs).
# 1-c. When you set the WY start month and desired number of year to generate stochastic climate, save and close.

### Step 2 end==================================================================




### ============================================================================
### Step 3: Calling Octave wrapper that governs the RCST code run.

### For the SCCWRP project, RCST code is heavily modified from original version.
# Followings are the summary of important modifications:
# 1. Wrapper function (run_wrapper.m): Overall process is reorganized to fit the purpose of SCCWRP RF project and built as a function. 
#    R can call this wrapper function and pass down the simple argument(s).
# 2. Any steps or components related to rainfall-runoff model are inactive/removed/commented-out.
# 3. RCST saves final outputs (stochastically generated & perturbed climate variables) as CSV files (TS_P & TS_T) for each comid.
#    Modified scripts can process PET, if monthly PET input is available.
# 4. Additional Octave functions are implemented to handle the "table" datatype from MATLAB

### RCST scripts are complicated;
# Numerous small functions invoke the other functions in sequence.
# Therefore, it is not simple to keep track of the actual workflow by simply reading through the scripts.
# When making any edits on MATLAB/Octave scripts, please be extra cautious how one function can invoke/affect other functions
# (and their inputs, arguments, and outputs). 


# Start by setting and checking working directory
#setwd('C:/Workspace/rapid-climate-stress-testing-SCCWRP/steering/'); getwd();
setwd('G:/RB9/rapid-climate-stress-testing-SCCWRP/steering'); getwd();
#setwd('/mnt/g/RB9/rapid-climate-stress-testing-SCCWRP/steering'); getwd();

library(processx);
library(tictoc);


# SNIPPET: example to show the basic method calling Octave script through processx package.
# Possibly DON'T run, unless want to check out how it works for the first time.
{
  output <- character(0)
  proc <- processx::process$new("octave", c("./run_wrapper.m", "comid_10000042", "hist_raw", 2), stdout = "|")
  processx::run("octave", c("./run_wrapper.m", "comid_10000042", "hist_raw", 2), stdout = "|")  

  # Real-time message from Octave
  while (proc$is_alive()) {
    Sys.sleep(1)
    now <- Sys.time()
    tmstmp <- sprintf("# [%s]", format(now, format = "%T"))
    thisout <- proc$read_output_lines()
    if (length(thisout)) {
      output <- c(output, thisout)
      message(tmstmp, " Msg from Ocatve:\n", paste0("#> ", thisout), "  ")
    }
  }
  rm(now, tmstmp, thisout, output)
}

# In real runs, we are using "processx::run" instead of "processx::process$new" to avoid dropping bomb to the system:
# e.g.: processx::run("Octave", c("./run_wrapper.m", "comid_10000042", "hist_raw", 2), stdout = "|")


# Importing function that uses processx::run for parallel-loop processing
source('../R/Call_RCST_Octave_Scripts.R')
  # e.g.: Call_RCST_Octave_Scripts = function(comid_arg = 1000042, input_dir_arg = "hist_raw", split_parm_arg = 2){}
  # comid_arg: character or integer, input_dir_arg = character, split_parm_arg = integer


### Parallel run
# Load essential libraries for parallelization
library(parallel); library(doParallel); library(foreach);

# Make cluster and register it.
#cl <- parallel::makeCluster(detectCores()/2) # don't set makeCluster(n) too high on laptops.
cl <- parallel::makeCluster(32) # don't set makeCluster(n) too high on laptops.
# When using powerful computer, it is OK to set it as high as "detectCores() - 2"
registerDoParallel(cl)

# Run the loop in parallel using foreach
comid_list = RB9_comid_list[97:2116] #1:529, 530:1059, 1060:1587, 1588:2116

tic()
foreach(i = seq_along(comid_list), .combine = 'c') %dopar% {
  Call_RCST_Octave_Scripts(comid_list[i], "hist", 2) # When running with climate input generated from Ted's RFpredictor
  log_message(paste("Processed item:", i))
}
toc()

parallel::stopCluster(cl) # Important to do this.


### EXTRA: you can swap out the below with line 163~165
foreach(i = seq_along(comid_list), .combine = 'c') %dopar% {
  Call_RCST_Octave_Scripts(comid_list[i], "hist", 2) # When running with climate input generated from SCCWRP compiled RFpredictor
}
### Step 3 end==================================================================
# Chat-GPT suggested optimization
library(future); library(tictoc);
comid_list = RB9_comid_list[97:2116] #1:529, 530:1059, 1060:1587, 1588:2116


{
  # Plan for using multiple background R sessions
  plan(future::multisession, workers = 32)
  
  # Function to process a single comid
  process_comid <- function(comid) {
    result <- Call_RCST_Octave_Scripts(comid, "hist", 2)
    log_message(paste("Processed item:", comid))
    return(result)
  }
  
  tic()
  
  # Create a list of futures for each comid
  futures <- vector("list", length(comid_list))
  for (i in seq_along(comid_list)) {
    futures[[i]] <- future(process_comid(comid_list[i]))
  }
  
  # Wait for the tasks to complete
  values <- lapply(futures, value)
  
  toc()
}









### Step 4: Verify comids
comid_list_out <- list.dirs(path = '../out/', full.names = F, recursive = T) 
comid_list_out <- comid_list_out[!grepl(paste(c("/"), collapse = "|"), comid_list_out)] 
comid_list_out <- gsub(".*_(\\d+)$", "\\1", comid_list_out)
missing_out <- RB9_comid_list[!(RB9_comid_list %in% comid_list_out)] %>% as.numeric()

{
  output <- character(0)
  proc <- processx::process$new("octave", c("./run_wrapper.m", paste0("comid_", missing_out), "hist", 2), stdout = "|")

  # Real-time message from Octave
  while (proc$is_alive()) {
    Sys.sleep(1)
    now <- Sys.time()
    tmstmp <- sprintf("# [%s]", format(now, format = "%T"))
    thisout <- proc$read_output_lines()
    if (length(thisout)) {
      output <- c(output, thisout)
      message(tmstmp, " Msg from Ocatve:\n", paste0("#> ", thisout), "  ")
    }
  }
  rm(now, tmstmp, thisout, output)
}

#%>% 
  sub(pattern = "(.*)\\..*$", replacement = "\\1") #%>% as.array() %>% as.integer()
