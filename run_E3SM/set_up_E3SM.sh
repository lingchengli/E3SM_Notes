#!/bin/sh
# change the lnd domain/forcing domain (the same files for IELM), and surface data to run region case

##############################
####     Start Control    ####
##############################
create_flag=1
usrset_flag=1
submit_flag=1
#GIT_HASH=`git log -n 1 --format=%h`

CASE_NAM=icom_test_surf_1D_t
CASE_DIR=/compyfs/lili400/e3sm_scratch
CASE_OUT=/compyfs/lili400/e3sm_scratch

RUN_YR_STR=1980
STOP_OPT=nyears
STOP_NTM=1
RESUB=0
NTSK_LND=320
#RUN_YR_END=2019

echo -e "\n---------------- E3SM Case: " $CASE_DIR/$CASE_NAM "----------------"
echo -e "---------------- Period:" $RUN_YR_STR" ~ "$RUN_YR_END ",  " Total: $(($STOP_NTM*($RESUB+1))) $STOP_OPT "\n"

# the DATM forcing
DATM_YR_STR=1980
DATM_YR_END=2019

##############################
####    create ELM case   ####
##############################
if [[ $create_flag -eq 1 ]]
then
  echo -e "\n---------------- Create Case ----------------\n"
  RESOLUT=ELMMOS_USRDAT #ELM_USRDAT #ELMMOS_USRDAT #
  COMPSET=IELM
  MACHINE=compy
  COMPILER=intel
  PROJECT=rgma

  SRC_DIR=/qfs/people/lili400/compy/project/ICoM/e3sm_trial #~/compy/E3SM_code/E3SM
  cd ${SRC_DIR}/cime/scripts

  rm -r ${CASE_DIR}/${CASE_NAM}
  rm -r ${CASE_OUT}/${CASE_NAM}
  ./create_newcase -case ${CASE_DIR}/${CASE_NAM} \
  -res ${RESOLUT} -compset ${COMPSET} -mach ${MACHINE} -project ${PROJECT}  #-compiler ${COMPILER}
  echo -e "\n-- RES " ${RESOLUT} " -- COMPSET " ${COMPSET} "\n"
fi

##############################
####   set ELM case   ####
##############################
if [[ $usrset_flag -eq 1 ]]
then

  echo -e "\n---------------- UserSet Case ----------------\n"

  cd ${CASE_DIR}/${CASE_NAM}

  ./xmlchange INFO_DBUG=2

  ./xmlchange NTASKS_LND=$NTSK_LND,JOB_WALLCLOCK_TIME="00:20:00"
  ./xmlchange JOB_WALLCLOCK_TIME="02:00:00" --subgroup case.run
  ./xmlchange JOB_QUEUE=short --subgroup case.run
  ./xmlquery  JOB_QUEUE,NTASKS_LND,JOB_WALLCLOCK_TIME

  ./xmlchange RUN_STARTDATE=$RUN_YR_STR-01-01
  ./xmlchange STOP_N=$STOP_NTM,STOP_OPTION=$STOP_OPT  # year period per run/resubmit
  ./xmlchange REST_N=3,REST_OPTION=nmonths
  ./xmlchange RESUBMIT=$RESUB
  ./xmlchange CONTINUE_RUN=FALSE
  ./xmlquery  RUN_STARTDATE,STOP_N,STOP_OPTION,RESUBMIT,REST_N,REST_OPTION

  # datm forcing period
  ./xmlchange DATM_MODE=CLMMOSARTTEST
  ./xmlchange DATM_CLMNCEP_YR_START=$DATM_YR_STR
  ./xmlchange DATM_CLMNCEP_YR_END=$DATM_YR_END
  ./xmlchange DATM_CLMNCEP_YR_ALIGN=$DATM_YR_STR
  #./xmlchange DLND_CPLHIST_YR_START=${YEAR_STR}
  #./xmlchange DLND_CPLHIST_YR_END=${YEAR_END}
  #./xmlchange DLND_CPLHIST_YR_ALIGN=${YEAR_STR}
  ./xmlquery  DATM_MODE,DATM_CLMNCEP_YR_START,DATM_CLMNCEP_YR_END,DATM_CLMNCEP_YR_ALIGN

  ./xmlchange DOUT_S=FALSE
  #./xmlchange DOUT_S=TRUE
  #dir_run=($(./xmlquery RUNDIR))
  #./xmlchange DOUT_S_ROOT=${dir_run[1]}/output
  #./xmlquery DOUT_S_ROOT

  # ./xmlchange LND_DOMAIN_PATH=/qfs/people/lili400/compy/project/ICoM/ELM-BGC/data/surface_data/elm_6km,LND_DOMAIN_FILE=domain_ICoM_6km.nc
  # ./xmlchange ATM_DOMAIN_PATH='$LND_DOMAIN_PATH',ATM_DOMAIN_FILE='$LND_DOMAIN_FILE'
  # ./xmlquery LND_DOMAIN_PATH,LND_DOMAIN_FILE,ATM_DOMAIN_PATH,ATM_DOMAIN_FILE

  ./xmlchange LND_DOMAIN_PATH=/qfs/people/lili400/compy/project/ICoM/ELM-BGC/data/surface_data/elm_6km,LND_DOMAIN_FILE=domain_ICoM_6km_1D.nc
  ./xmlchange ATM_DOMAIN_PATH='$LND_DOMAIN_PATH',ATM_DOMAIN_FILE='$LND_DOMAIN_FILE'
  ./xmlquery LND_DOMAIN_PATH,LND_DOMAIN_FILE,ATM_DOMAIN_PATH,ATM_DOMAIN_FILE

  ./xmlchange LND2ROF_FMAPNAME=/qfs/people/lili400/compy/project/ICoM/ELM-BGC/script/0.0_data_pros/0.3_mapping/LND2ROF_mapping_6km-MPAS.nc
  ./xmlchange ROF2LND_FMAPNAME=/qfs/people/lili400/compy/project/ICoM/ELM-BGC/script/0.0_data_pros/0.3_mapping/ROF2LND_mapping_MPAS-6k.nc
  #add inforamtion in user_nl_XXX , QFLX_EVAP_TOT!
  # ./xmlquery LND2ROF_FMAPNAME ATM2LND_SMAPNAME ATM2LND_FMAPNAME
  echo -e "-- update: user_nl_elm --"
cat >> user_nl_elm << EOF

!finidat = ''
fsurdat = '/qfs/people/lili400/compy/project/ICoM/ELM-BGC/data/surface_data/elm_6km/surfdata_ICoM_6km_1D.nc'
hist_empty_htapes = .true.

hist_fincl1 = 'RAIN','TBOT','BTRAN','FSAT','FH2OSFC','FSNO',\
'EFLX_LH_TOT','FSH','Qle','FCTR','FCEV','FGEV','QVEGT','QVEGE','QSOIL',\
'QRUNOFF','QOVER','QDRAI','QH2OSFC',\
'H2OSFC','H2OSOI','SOILLIQ','SOILICE','SOILWATER_10CM','H2OSNO','SNOWICE','SNOWLIQ',\
'TWS','DWB','ZWT','WA','QCHARGE','FPSN'

hist_nhtfrq = 0
hist_mfilt  = 1
EOF

  echo -e "-- update: user_nl_mosart --"
cat >> user_nl_mosart << EOF

frivinp_rtm = '/compyfs/xudo627/new_mesh/inputdata/MOSART_Mid-Atlantic_MPAS_c220107'
!frivinp_rtm = '/compyfs/lili400/project/HighR/data/mosart/NLDAS_mosart_8th_202102.nc'
do_rtm = .false.
inundflag = .false.
opt_elevprof = 1

!rtmhist_nhtfrq= 0,-3
!rtmhist_mfilt = 1, 8
!rtmhist_fincl1='OUTLETG','FLOODED_FRACTION','FLOODPLAIN_FRACTION','FLOODPLAIN_VOLUME','QSUR_LIQ','QSUB_LIQ','QGWL_LIQ','STORAGE_LIQ','Main_Channel_STORAGE_LIQ','RIVER_DISCHARGE_OVER_LAND_LIQ','RIVER_DISCHARGE_TO_OCEAN_LIQ'
!rtmhist_fincl2='OUTLETG','FLOODED_FRACTION','FLOODPLAIN_FRACTION','FLOODPLAIN_VOLUME','QSUR_LIQ','QSUB_LIQ','QGWL_LIQ','STORAGE_LIQ','Main_Channel_STORAGE_LIQ','RIVER_DISCHARGE_OVER_LAND_LIQ','RIVER_DISCHARGE_TO_OCEAN_LIQ'

EOF

  echo -e "-- update: user_nl_datm --"
cat >> user_nl_datm << EOF
mapalgo = "nn", "nn", "nn"
EOF

    #add inforamtion in user_nl_XXX , QFLX_EVAP_TOT!
  if [[ $create_flag -eq 1 ]]
  then

    echo -e "-- update: datm.streams --"
    ./case.setup
    cp ${CASE_DIR}/${CASE_NAM}/CaseDocs/datm.streams.txt.CLMMOSARTTEST ${CASE_DIR}/${CASE_NAM}/user_datm.streams.txt.CLMMOSARTTEST
    chmod +rw ${CASE_DIR}/${CASE_NAM}/user_datm.streams.txt.CLMMOSARTTEST
    sed -i "s@/compyfs/inputdata/share/domains/domain.clm@/compyfs/lili400/project/HighR/data/surface@g"  ${CASE_DIR}/${CASE_NAM}/user_datm.streams.txt.CLMMOSARTTEST
    sed -i "s@domain.lnd.nldas2_0224x0464_c110415.nc@domain.lnd.nldas_8th.nc@g"  ${CASE_DIR}/${CASE_NAM}/user_datm.streams.txt.CLMMOSARTTEST
    sed -i "s@/compyfs/inputdata/atm/datm7/NLDAS@/compyfs/lili400/project/HighR/data/nldas@g" ${CASE_DIR}/${CASE_NAM}/user_datm.streams.txt.CLMMOSARTTEST
    sed -i "s@clmforc.nldas.@clmforc.nldas.8th.@g"  ${CASE_DIR}/${CASE_NAM}/user_datm.streams.txt.CLMMOSARTTEST
  fi

fi

##############################
####   build&submit case  ####
##############################
if [[ $submit_flag -eq 1 ]]
then

  echo -e "\n---------------- Build&Submit Case ----------------\n"

  cd ${CASE_DIR}/${CASE_NAM}

  ./case.setup --reset

  ./case.build
exit
  ./case.submit

fi
