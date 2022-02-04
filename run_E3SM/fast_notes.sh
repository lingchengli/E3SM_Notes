
Load module in Constance (Important), not need in compy
suggested module load 
module purge
module load python/anaconda3.6 (make sure python version > 2.7)
module load svn/1.11.1
module load ncl/6.6.2
module load matlab/2018a
module load nco/4.8.0
module load gcc/7.3.0
module load hdf5
module load intel/19.0.3
module load mvapich2/2.3.2
module load netcdf/4.7.4
You may get errors if you load two MPI or compiler modules. For example two different versions of intel 
Currently Loaded Module files:
1) python/anaconda2.7(default) 3) ncl/6.6.2 5) nco/4.8.0 7) intel/15.0.1(default) 9) hdf5/1.8.13
2) svn/1.11.1 4) matlab/2018a 6) gcc/7.3.0 8) mvapich2/2.1a 10) netcdf/4.7.4
Constance job
HPC How-To Articles
Job Scheduler
view your allocation
module load sbank,
module load sbank
Running a Job on the HPC Cluster#3.e.SubmittingaJobtoaQueue
Squeue see job status.
squeue -u username
Allocation: gbalance -u
Compy
https://e3sm.org/model/running-e3sm/supported-machines/compy-pnnl/
Get E3SM code
>git clone -b maint-1.0 --recursive https://github.com/E3SM-Project/E3SM.git

--recursive, --recurse-submodules

After the clone is created, initialize all submodules within, using their default settings. This is equivalent to running git submodule update --init --recursive immediately after the clone is finished

cd /E3SM. You may not need these steps, may gives you errors (see here: https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/adding-a-new-ssh-key-to-your-github-account):
git fetch origin 
git checkout origin/master
git submodule update --init --recursive
git clone https://github.com/E3SM-Project/E3SM.git e3sm_trial
cd e3sm_trial
git fetch origin
git checkout origin/master
git submodule update --init --recursive
Create new case
cd /E3SM/cime/scripts
create new case. CIME reference: http://esmci.github.io/cime/versions/master/html/users_guide/create-a-case.html;https://escomp.github.io/CESM/release-cesm2/quickstart.html
./create_newcase --case directory --res f19_g17 --compset I1850Clm50Sp

Compset. http://esmci.github.io/cime/versions/master/html/users_guide/compsets.html#compsets
Detail configs
./query_config --h This will show a help message with information and options for the command 
./query_config --compsets clm Will list all the “I” compsets available. All list: http://www.cesm.ucar.edu/models/cesm2/config/compsets.html
./query_config --grids Will list all the available model grids. All list http://www.cesm.ucar.edu/models/cesm2/config/grids.html, e.g., IGSWCRDCTCBC, f45_g37
Case Example 
FATES: --res CLM_USRDAT, point simulation.
regional
e.g., ./create_newcase --casename --res hcru_hcru --mach compy --compset I20TRGSWCNPRDCTCBC --project esmd --compiler intel
./create_newcase --case /pic/scratch/lili400/E3SM/test1 --res hcru_hcru --compset IGSWCRDCTCBC
ERROR: inputdata root is not a directory: /pic/projects/climate/csmdata/. Contact the computing support (rc-support@pnnl.gov) to get access, and also add you into some projects for job submission.
./create_newcase --case /pic/scratch/lili400/E3SM/test3 --res hcru_hcru --compset ICLM45
Compy: ./create_newcase --case /qfs/people/lili400/compy/scratch/E3SM/IGCLM45 --res hcru_hcru --mach compy --compset IELM --project rgma
Compy: ./create_newcase --case /qfs/people/lili400/compy/scratch/E3SM/IELM2 --res hcru_hcru --mach compy --compset IELM --project rgma
Build the case 
know the *.XML files 
after build take a look at the xml files for further information

most used ./env_run.xml, env_batch, env_match_pes
modify the information in env_*.xml
./xmlquery NTASKS,STOP_N,STOP_OPTION,JOB_WALLCLOCK_TIME,,REST_N,REST_OPTION,RESUBMIT
./xmlchange NTASKS=512,STOP_N=1,STOP_OPTION=nyears,JOB_WALLCLOCK_TIME="20:00:00",RUN_STARTDATE="2000-01-01",REST_N=1,REST_OPTION=nyears,RESUBMIT=10
Change the output directory
Output directory. All output data is initially written to $RUNDIR. Unless you explicitly turn off short-term archiving, files are moved to $DOUT_S_ROOT at the end of a successful model run. Users generally should turn off short-term archiving when developing new code.
./xmlchange DOUT_S=TRUE
./xmlquery RUNDIR
DOUT_S_ROOT = $RUNDIR/output. user defined output, /compyfs/$USER/e3sm_scratch/archive/$CASE/output
RUN_STARTDATE works only when $CONTINUE_RUN=FALSE
modify the "DATA_MODE" for forcing choice. ..
modify the user_nl_elm
modify the output files. e.g., hist_mfilt  = 1, 30,  28, 24 hist_nhtfrq = 0, -24, -6, -1
./case.setup
http://esmci.github.io/cime/versions/master/html/users_guide/setting-up-a-case.html
Script used to set up the case (create the case.run script, Macros file and user_nl_xxx files). 
Configured the model and created the files to modify options & input data. make sure the loaded modules are right.

./case.build;
modify the env_build.xml before build. http://esmci.github.io/cime/versions/master/html/users_guide/building-a-case.html. 
The env_build.xml variables control various aspects of building the executable. Most of the variables should not be modified. 
set the env_run.xml file
create /bld: /pic/scratch/$USER/csmruns/$CASE/bld, e.g., e3sm.exe
create /run: /pic/scratch/$USER/csmruns/$CASE/run,
set the Job submission
./xmlquery describe. http://esmci.github.io/cime/versions/master/html/Tools_user/xmlquery.html?highlight=case%20run
env_workflow.xml, determine the job submission for different run-type
<group id="case.run">, <entry id="prereq" value="$BUILD_COMPLETE and not $TEST">, BUILD_COMPLETE=TRUE (means after build and generate env_build.xml)
CHARGE_ACCOUNT, PROJECT,walltime/JOB_WALLCLOCK_TIME, JOB_QUEUE
./xmlchange JOB_WALLCLOCK_TIME=02:00:00 --subgroup case.run
<group id="case.st_archive">, <entry id="dependency" value="case.run or case.test">, <entry id="prereq" value="$DOUT_S"> 

CHARGE_ACCOUNT, PROJECT,walltime/JOB_WALLCLOCK_TIME, JOB_QUEUE

./xmlchange JOB_WALLCLOCK_TIME=00:10:00 --subgroup case.st_archive


check the input data. 
check_input_data located in each case directory is called, and it attempts to locate all required input data for the case based upon file lists generated by components. If the required data is not found on local disk in $DIN_LOC_ROOT, then the data will be downloaded automatically by the scripts or it can be downloaded by the user by invoking check_input_data with the --download command argument. If you want to download the input data manually you should do it before you build CESM.
Input data config: /people/lili400/work/test2/E3SM/cime/config/e3sm/config_inputdata.xml; use /cesm/config, if e3sm not works.
Review the following directories and files, whose locations can be found with xmlquery (note: xmlquery can be run with a list of comma separated names and no spaces): ./xmlquery RUNDIR,CASE,CASEROOT,DOUT_S,DOUT_S_ROOT,DIN_LOC_ROOT

Run the case
./case.submit. http://esmci.github.io/cime/versions/master/html/users_guide/running-a-case.html
./preview_run
./xmlquery NTASKS,NTHRDS,ROOTPE

./xmlchange 
./xmlchange NTASKS=30,NTHRDS=4
./xmlchange JOB_WALLCLOCK_TIME=02:00:00
> ./case.submit
output files. 
output name, http://www.cesm.ucar.edu/models/cesm2/naming_conventions.html#modelOutputLocations
For h (history) files, the second and third characters of the pattern h* signify a unique data stream that corresponds to a namelist value defining the time period frequency 
Resubmit
After a successful first run, set the env_run.xml variable $CONTINUE_RUN to TRUE before resubmitting or the job will not progress. 
./xmlchange CONTINUE_RUN=TRUE ?. This variable determines if the run is a restart run from the last tiemstep
You may also need to modify the env_run.xml variables $STOP_OPTION, $STOP_N and/or $STOP_DATE as well as $REST_OPTION, $REST_N and/or $REST_DATE, and $RESUBMIT before resubmitting.
Customizing. https://escomp.github.io/ctsm-docs/versions/release-clm5.0/html/users_guide/setting-up-and-running-a-case/customizing-the-clm-configuration.html#user-namelist
Output directory. All output data is initially written to $RUNDIR. Unless you explicitly turn off short-term archiving, files are moved to $DOUT_S_ROOT at the end of a successful model run. Users generally should turn off short-term archiving when developing new code.

DOUT_S = TRUE
DOUT_S_ROOT = user defined output, /compyfs/$USER/e3sm_scratch/archive/$CASE/output
Files information
xmlchange and xmlquery to modify or query the *xml files

env_build.xml

Sets model build settings. This includes component resolutions and component compile-time configuration options. You must run the case.build command after changing this file.

env_run.xml. Sets runtime settings such as length of run, frequency of restarts, output of coupler diagnostics, and short-term and long-term archiving. This file can be edited at any time before a job starts.

the input data directory
<entry id="DIN_LOC_ROOT" value="directory you can modify">, default: /pic/projects/climate/csmdata/
ATM: <entry id="DIN_LOC_ROOT_CLMFORC" value="$DIN_LOC_ROOT/atm/datm7">
CLM: default /pic/projects/climate/csmdata/lnd/clm2
input data list. 
Buildconf/$component.input_data_list files. e.g., Buildconf/clm.input_data_list
check the input data, ./check_input_data
Input data directory, default: 
/pic/projects/climate/csmdata/
/pic/projects/climate/csmdata/lnd/clm2/
/pic/projects/climate/csmdata/atm/datm7

set the $RUNDIR and $EXEROOT
set the RUN date:
RUN_STARTDATE
After build. ./CaseDocs: *_in, e.g.,  land_in, datm_in

Directory that contains all the component namelists for the run. This is for reference only and files in this directory SHOULD NOT BE EDITED since they will be overwritten at build time and runtime.

After build. user_nl_clm ~ namelist
change the surface data
e.g., fsurdat = 'directory/filename'. surfdata_BEW_sparse_grid_c200930_evergreen.nc'
Question
DATA Models
overview. https://esmci.github.io/cime/versions/maint-5.6/html/data_models/introduction.html
DATM. 
Reference
CIME: http://esmci.github.io/cime/versions/master/html/index.html
CESM: https://escomp.github.io/CESM/release-cesm2/index.html
http://www.cgd.ucar.edu/events/2019/ctsm/files/practical1-lombardozzi.pdf
https://e3sm.org/model/running-e3sm/e3sm-quick-start/
https://escomp.github.io/ctsm-docs/versions/release-clm5.0/html/users_guide/setting-up-and-running-a-case/choosing-a-compset.html
