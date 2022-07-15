Begin
    fil1 = "/compyfs/lili400/project/HighR/data/surface/surfdata.nldas_8th.nc"
    f1   = addfile(fil1,"r")
    src_lat := f1->lsmlat
    src_lon := f1->lsmlon
    printVarSummary(src_lon)

    f1 = addfile("/compyfs/lili400/project/ICoM/data/conus_1k/surf/surfdat_conus_1k_4d.nc","r")
    dst_lat := f1->lat
    dst_lon := f1->lon
    printVarSummary(dst_lon)

    srcGridName = otdir + "src_SCRIP_conus_8th.nc"
    dstGridName = otdir + "dst_SCRIP_conus_1k.nc"
    wgtFileName = otdir + "map_atm_8th_2_1k.nc"

    ;;; generate src SCRIPT file
    print("---- Generate SCRIPT ----")
    Opt                = True
    Opt@ForceOverwrite = True
    Opt@PrintTimings   = True
    ;Opt@Title          = "MODIS Grid"
    rectilinear_to_SCRIP(srcGridName,src_lat,src_lon,Opt)

    Opt                = True
    Opt@ForceOverwrite = True
    Opt@PrintTimings   = True
    ;Opt@Title          = "MODIS Grid"
    rectilinear_to_SCRIP(dstGridName,dst_lat,dst_lon,Opt)

    delete(Opt)

    ;; Generate the weights (mapping)
    print("---- Generate Mapping ----")
    Opt                      = True
    Opt@InterpMethod         = "conserve" ;"bilinear"     ; default
    Opt@ForceOverwrite       = True
    Opt@PrintTimings         = True
    
    ESMF_regrid_gen_weights(srcGridName,dstGridName,wgtFileName,Opt)
    ; system("ESMF_RegridWeightGen -m conserve --ignore_unmapped -s " + srcGridName +" -d "+dstGridName+ " -w "+wgtFileName)
    delete(Opt)
end
