; modify the fornm !!
; it is different between the forcing and land domain files
; i.e., mask, and fraction. from value mask = frac

begin
  ; gedir = "/qfs/people/lili400/compy/project/ICoM/ELM_subregion/data/"
  indir = "/compyfs/lili400/project/ICoM/data/conus_1k/surf/"
  otdir = "/compyfs/lili400/project/ICoM/data/conus_1k/surf/"
  gedir = "/compyfs/lili400/project/ICoM/data/conus_1k/gee/"
  
  ;;;;;;  land mask prepare or the domain mask  ;;;;;;;
  if (False) then

    fout = otdir + "conus1k_mask.nc"
    system("/bin/rm -f " + fout)
    print("  Out: " + fout)
    fo = addfile(fout, "c")
    fo@creation_data=systemfunc("date")
    fo@information="NLDAS 1k mask Created by Lingcheng LI"

    ; 1) input the hi soil data data
    ;; mask if soil totoal .eq. 0
    f1 = addfile(indir + "conus1k_Soil.nc","r")
    lat = f1->lat
    lon = f1->lon

    mask_1k = new((/dimsizes(lat),dimsizes(lon)/),integer)
    mask_1k = 1

    stxt = (f1->clay(0,:,:)) + (f1->silt(0,:,:)) + (f1->sand(0,:,:))
    copy_VarMeta(f1->clay(0,:,:),stxt)
    printVarSummary(stxt)

    mask_1k = where(stxt.gt.0,mask_1k,0)
    printVarSummary(mask_1k)

    ;; 2) if lulc is water
    f1 = addfile(indir + "conus1k_LULC.nc","r")
    water = f1->lulc(17,:,:)
    mask_1k = where(water.eq.0,mask_1k,0)

    ;; 3) nldas urban data is valide
    f1 = addfile(indir + "surfdata.nldas_8thT1k.nc","r")
    urban = f1->URBAN_REGION_ID
    mask_1k = where(urban.gt.0,mask_1k,0)

    mask_1k := toint(mask_1k)

    ;; 3) nldas urban data is valide
    f1 = addfile(gedir + "mean_of_Elevation.nc","r")
    elev = f1->Band1
    mask_1k = where(elev.lt.5000,mask_1k,0)

    mask_1k := toint(mask_1k)
    mask_1k = nameDim(mask_1k,(/"lat","lon"/),"land mask 1","")
    mask_1k&lat = lat
    mask_1k&lon = lon

    fo->mask = mask_1k ;({28:32},{-93:-89})
    ; fo->urban = urban ;({28:32},{-93:-89})
    ; fo->stxt  = stxt ;({28:32},{-93:-89})
    ; fo->water = water ;({28:32},{-93:-89})
    ;; NLDAS mask

  end if

  f1 = addfile(otdir + "conus1k_mask.nc","r")
  mask_1k = f1->mask
  lat_1k  = f1->lat
  lon_1k  =  f1->lon
  printVarSummary(mask_1k)

  ;;;;;;;;; make domain file ;;;;;;;
  if True then

    fout = otdir + "domain_conus_1k.nc"
    system("/bin/rm -f " + fout)
    print("  Out: " + fout)
    fo = addfile(fout, "c")
    fo@creation_data=systemfunc("date")
    fo@information="NLDAS 1k domain Created by Lingcheng LI"

    f1 = addfile(indir + "surfdata.nldas_8thT1k.nc","r")
    lat = f1->lat
    lon = f1->lon
    ; AREA = f1->AREA
    ; printVarSummary(AREA)

    xc = new( (/dimsizes(lat),dimsizes(lon)/), double )
    yc = xc
    xc = nameDim(xc,(/"nj","ni"/),"longitude of grid cell center","degrees_east")
    yc = nameDim(yc,(/"nj","ni"/),"latitude of grid cell center","degrees_north")

    xv = new( (/dimsizes(lat),dimsizes(lon),4/), double )
    yv = xv
    xv = nameDim(xv,(/"nj","ni","nv"/),"longitude of grid cell verticies","degrees_east")
    yv = nameDim(yv,(/"nj","ni","nv"/),"latitude of grid cell verticies","degrees_north")

    do yi = 0, dimsizes(lat)-1
      xc(yi,:) = (/lon/)
    end do
    do xi = 0, dimsizes(lon)-1
      yc(:,xi) = (/lat/)
    end do

    do i = 0, 3
      xv(:,:,i) = (/xc/)
      yv(:,:,i) = (/yc/)
    end do

    mask1 := nameDim(toint(mask_1k),(/"nj","ni"/),"domain mask","unitless")
    frac   = nameDim(mask_1k,(/"nj","ni"/),"fraction of grid cell that is active","unitless")
    AREA = nameDim(tofloat(mask_1k),(/"nj","ni"/),"area of grid cell in radians squared","radian2")
    AREA = (/ 0.000001 /)

    fo->xc = xc
    fo->yc = yc
    fo->xv = xv
    fo->yv = yv
    fo->mask = mask1
    fo->area = AREA
    fo->frac = frac
    
    exit

  end if

  ;;;; process LAI ;;;;
  var_lai := (/"MONTHLY_LAI","MONTHLY_SAI","MONTHLY_HEIGHT_TOP","MONTHLY_HEIGHT_BOT"/)
  if False then
      ; lulc
      f3 = addfile(indir + "conus1k_LULC.nc","r")
      lulc_1k = f3->lulc
      printVarSummary(lulc_1k)

      f3 = addfile(indir + "conus1k_SAI_LAI.nc","r")
      lai_1k = tofloat( f3->lai )
      sai_1k = tofloat( f3->sai )
      printVarSummary(lai_1k)

      ;;; 4 dimension
      if False then
        fout = otdir + "surfdat_LAI4_1k.nc"
        system("/bin/rm -f " + fout)
        setfileoption("nc","Format","NetCDF4")
        print("  Out: " + fout)
        fo = addfile(fout, "c")
        fo@creation_data=systemfunc("date")
        fo@information="NLDAS 1k domain Created by Lingcheng LI"

        ;; 2) monthly LAI, SAI
        lai_1k_m = new((/12,17,dimsizes(lat_1k),dimsizes(lon_1k)/),float)
        lai_1k_m = (/ 0. /)
        sai_1k_m  = lai_1k_m
        topH_1k_m = lai_1k_m
        botH_1k_m = lai_1k_m

        printVarSummary(lulc_1k(0,:,:))
        printVarSummary(lai_1k(0,:,:))

        do ti = 0, 16 ; natural pft
          do mi = 0, 11;
            print(ti+": mon "+mi)
            lai_1k_m(mi,ti,:,:) = tofloat( where(lulc_1k(ti,:,:).eq.1, lai_1k(mi,:,:), 0.) )
            sai_1k_m(mi,ti,:,:) = tofloat( where(lulc_1k(ti,:,:).eq.1, sai_1k(mi,:,:), 0.) )
          end do ;
        end do ; pfts
        delete(lai_1k_m@_FillValue)
        delete(sai_1k_m@_FillValue)
        lai_1k_m = where(lai_1k_m.gt.100 .or.lai_1k_m.lt.0, 0,lai_1k_m)
        sai_1k_m = where(sai_1k_m.gt.100 .or.sai_1k_m.lt.0, 0,sai_1k_m)
        lai_1k_m = nameDim(lai_1k_m,(/"time","pft","lat","lon"/),"monthy LAI for vegetation PFT","")
        sai_1k_m = nameDim(sai_1k_m,(/"time","pft","lat","lon"/),"monthy SAI for vegetation PFT","")
        printVarSummary(lai_1k_m)
        printVarSummary(sai_1k_m)
        ;lai_1k_sum = dim_sum_n_Wrap(lai_1k_m(7,:,:,:),0)

        f5 = addfile("/compyfs/inputdata/lnd/clm2/rawdata/pftlandusedyn.0.5x0.5.simyr1850-2005.c090630/mksrf_lai_global_c090506.nc","r")
        var_sf := getfilevarnames(f5)
        lw_ht_bot = tofloat( f5->MONTHLY_HEIGHT_BOT )
        lw_ht_top = tofloat( f5->MONTHLY_HEIGHT_TOP )

        do ti = 0,16
          topH_1k_m(:,ti,:,:) = (/ lw_ht_top(5,ti,150,250) /)
          botH_1k_m(:,ti,:,:) = (/ lw_ht_bot(5,ti,150,250) /)
        end do
        delete(topH_1k_m@_FillValue)
        delete(botH_1k_m@_FillValue)

        topH_1k_m = where(topH_1k_m.gt.200 .or.topH_1k_m.lt.0, 0,topH_1k_m)
        botH_1k_m = where(botH_1k_m.gt.200 .or.botH_1k_m.lt.0, 0,botH_1k_m)
        topH_1k_m = nameDim(topH_1k_m,(/"time","pft","lat","lon"/),"monthly height top","")
        botH_1k_m = nameDim(botH_1k_m,(/"time","pft","lat","lon"/),"monthly height bot","m")
        printVarSummary(topH_1k_m)
        printVarSummary(botH_1k_m)

        fo->MONTHLY_LAI = lai_1k_m
        fo->MONTHLY_SAI = sai_1k_m
        fo->MONTHLY_HEIGHT_BOT = botH_1k_m
        fo->MONTHLY_HEIGHT_TOP = topH_1k_m
      end if

      ;;; 3 dimension
      if True then
        fout = otdir + "surfdat_LAI3_1k.nc"
        system("/bin/rm -f " + fout)
        setfileoption("nc","Format","NetCDF4")
        print("  Out: " + fout)
        fo = addfile(fout, "c")
        fo@creation_data=systemfunc("date")
        fo@information="NLDAS 1k domain Created by Lingcheng LI"

        ;; 2) monthly LAI, SAI
        lai_1k_m = new((/12,dimsizes(lat_1k),dimsizes(lon_1k)/),float)
        lai_1k_m = (/ 0. /)
        sai_1k_m  = lai_1k_m
        topH_1k_m = lai_1k_m
        botH_1k_m = lai_1k_m
        printVarSummary(lulc_1k(0,:,:))
        printVarSummary(lai_1k(0,:,:))

        lai_1k_m = lai_1k
        sai_1k_m = sai_1k

        lai_1k_m = where(lai_1k_m.gt.100 .or.lai_1k_m.lt.0, 0,lai_1k_m)
        sai_1k_m = where(sai_1k_m.gt.100 .or.sai_1k_m.lt.0, 0,sai_1k_m)
        lai_1k_m = nameDim(lai_1k_m,(/"time","lat","lon"/),"monthy LAI for vegetation PFT","")
        sai_1k_m = nameDim(sai_1k_m,(/"time","lat","lon"/),"monthy SAI for vegetation PFT","")
        printVarSummary(lai_1k_m)
        printVarSummary(sai_1k_m)
        ;lai_1k_sum = dim_sum_n_Wrap(lai_1k_m(7,:,:,:),0)

        f5 = addfile("/compyfs/inputdata/lnd/clm2/rawdata/pftlandusedyn.0.5x0.5.simyr1850-2005.c090630/mksrf_lai_global_c090506.nc","r")
        var_sf := getfilevarnames(f5)

        lw_ht_bot = tofloat( f5->MONTHLY_HEIGHT_BOT )
        lw_ht_top = tofloat( f5->MONTHLY_HEIGHT_TOP )
        printVarSummary(lw_ht_top)

        do yi = 0, dimsizes(lat_1k)-1 ; natural pft
          print(", "+yi)
          do xi = 0, dimsizes(lon_1k)-1 ; natural pft
            idx1 := maxind(lulc_1k(0:16,yi,xi))
            ; print(", "+idx1)
            topH_1k_m(:,yi,xi) = (/ lw_ht_top(5,idx1,150,250) /)
            botH_1k_m(:,yi,xi) = (/ lw_ht_bot(5,idx1,150,250) /)
          end do ;
        end do ;
        delete(topH_1k_m@_FillValue)
        delete(botH_1k_m@_FillValue)

        topH_1k_m = where(topH_1k_m.gt.200 .or.topH_1k_m.lt.0, 0,topH_1k_m)
        botH_1k_m = where(botH_1k_m.gt.200 .or.botH_1k_m.lt.0, 0,botH_1k_m)
        topH_1k_m = nameDim(topH_1k_m,(/"time","lat","lon"/),"monthly height top","")
        botH_1k_m = nameDim(botH_1k_m,(/"time","lat","lon"/),"monthly height bot","m")
        printVarSummary(topH_1k_m)
        printVarSummary(botH_1k_m)

        fo->MONTHLY_LAI = lai_1k_m
        fo->MONTHLY_SAI = sai_1k_m
        fo->MONTHLY_HEIGHT_BOT = botH_1k_m
        fo->MONTHLY_HEIGHT_TOP = topH_1k_m

      end if
      exit
  end if

  ;;;; process LULC ;;;;
  var_lulc:= (/"PCT_NATVEG","PCT_NAT_PFT","PCT_LAKE","PCT_WETLAND","PCT_GLACIER","PCT_URBAN"/)
  if False then
    f1 = addfile(indir + "surfdata.nldas_8thT1k.nc","r")
    var_t = getfilevarnames(f1)
    print(var_t)

    fout = otdir + "surfdat_LULC_1k.nc"
    system("/bin/rm -f " + fout)
    setfileoption("nc","Format","NetCDF4")
    print("  Out: " + fout)
    fo = addfile(fout, "c")
    fo@creation_data=systemfunc("date")
    fo@information="NLDAS 1k domain Created by Lingcheng LI"

    ; 1) input the high data
    f3 = addfile(indir + "conus1k_LULC.nc","r")
    lulc = f3->lulc
    lat  = f3->lat
    lon  = f3->lon

    delete(lulc@_FillValue)
    lulc := todouble( where(lulc.gt.0,lulc,0.) )
    printVarSummary(lulc)
    ; sum to 100 and non-negative value
    lulc_sum := dim_sum_n_Wrap(lulc,0)
    do ti = 0, 20
      lulc(ti,:,:) = lulc(ti,:,:) / lulc_sum * todouble(100.)
    end do
    lulc_sum := dim_sum_n_Wrap(lulc,0)
    print("lulc_sum: "+num(lulc_sum.eq.100.) +", "+ num(lulc_sum.lt.100.)+", "+ num(lulc_sum.lt.99.) +", "+ num(lulc_sum.lt.0.)+", "+ num(lulc_sum.gt.100.)+", "+ num(lulc_sum.gt.101.) )

    ;;;;;;;  adjust non vegatation pct  ;;;;;;;
    ;; 0=< PCT_NONVEG <= 100
    ;; non missing value !!!
    PCT_LAKE    = lulc(17,:,:)
    PCT_WETLAND = lulc(18,:,:)
    PCT_GLACIER = lulc(19,:,:)
    PCT_URBANt  = lulc(20,:,:)
    PCT_LAKE    = where(PCT_LAKE.gt.0,   PCT_LAKE,   0.)
    PCT_WETLAND = where(PCT_WETLAND.gt.0,PCT_WETLAND,0.)
    PCT_GLACIER = where(PCT_GLACIER.gt.0,PCT_GLACIER,0.)
    PCT_URBANt  = where(PCT_URBANt.gt.0, PCT_URBANt, 0.)

    PCT_NONVEG  = PCT_LAKE + PCT_WETLAND + PCT_GLACIER + PCT_URBANt
    printVarSummary(PCT_NONVEG)
    PCT_NONVEG  = where(PCT_NONVEG.eq.0,-9999,PCT_NONVEG)
    PCT_NONVEG@_FillValue = -9999.

    PCT_LAKE    = (/ where(PCT_NONVEG.gt.100, todouble(PCT_LAKE/PCT_NONVEG),    PCT_LAKE) /)
    PCT_WETLAND = (/ where(PCT_NONVEG.gt.100, todouble(PCT_WETLAND/PCT_NONVEG), PCT_WETLAND) /)
    PCT_GLACIER = (/ where(PCT_NONVEG.gt.100, todouble(PCT_GLACIER/PCT_NONVEG), PCT_GLACIER) /)
    PCT_URBANt  = (/ where(PCT_NONVEG.gt.100, todouble(PCT_URBANt/PCT_NONVEG) , PCT_URBANt)  /)
    delete([/PCT_LAKE@_FillValue, PCT_WETLAND@_FillValue, PCT_GLACIER@_FillValue, PCT_URBANt@_FillValue/])
    PCT_LAKE    = where(PCT_LAKE.gt.0,   PCT_LAKE,   0.)
    PCT_WETLAND = where(PCT_WETLAND.gt.0,PCT_WETLAND,0.)
    PCT_GLACIER = where(PCT_GLACIER.gt.0,PCT_GLACIER,0.)
    PCT_URBANt  = where(PCT_URBANt.gt.0, PCT_URBANt, 0.)

    PCT_NONVEG  = PCT_LAKE + PCT_WETLAND + PCT_GLACIER + PCT_URBANt
    PCT_NONVEG  = nameDim(PCT_NONVEG,(/"lat","lon"/),"non natural vegetation percentage","unitless")
    print("PCT_NONVEG1: "+" , "+num(.not.ismissing(PCT_NONVEG))+" , "+num(ismissing(PCT_NONVEG))+" , "+num(PCT_NONVEG.eq.100.)+" , "+num(PCT_NONVEG.gt.100.)+" , "+num(PCT_NONVEG.lt.0.))

    PCT_NATVEG = 100 - PCT_LAKE - PCT_WETLAND - PCT_GLACIER - PCT_URBANt
    PCT_NATVEG = where(PCT_NATVEG.ge.0,PCT_NATVEG,0.)
    ;print("PCT_NATVEG  "+get_unique_values(toint(PCT_NATVEG)))
    print("PCT_NATVEG2: "+" , "+num(.not.ismissing(PCT_NATVEG))+" , "+num(ismissing(PCT_NATVEG))+" , "+num(PCT_NATVEG.eq.100.)+" , "+num(PCT_NATVEG.gt.100.)+" , "+num(PCT_NATVEG.lt.0.))

    ; double check
    ; check the variabless ralationship
    PCT_TOT_ck = PCT_NATVEG + PCT_LAKE + PCT_WETLAND + PCT_GLACIER + PCT_URBANt   ; equal 100
    PCT_TOT_ck = nameDim(PCT_TOT_ck,(/"lat","lon"/),"Total percentage of land cover","unitless")
    print("PCT_TOT_ck:  "+get_unique_values(PCT_TOT_ck)+", "+ num(PCT_TOT_ck.lt.100.))
    ;print("PCT_TOT_ck: "+num(PCT_TOT_ck.lt.100.) +", "+ num(PCT_TOT_ck.gt.100.) +", "+ num(PCT_TOT_ck.eq.100.)+", "+ num(.not.ismissing(PCT_TOT_ck))+", "+ num(ismissing(PCT_TOT_ck)) )

    ; check all variables
    printMinMax(PCT_NATVEG,0)
    printMinMax(PCT_LAKE,0)
    printMinMax(PCT_WETLAND,0)
    printMinMax(PCT_GLACIER,0)
    printMinMax(PCT_URBANt,0)

    PCT_LAKE = nameDim(PCT_LAKE,(/"lat","lon"/),"lake percent","%")
    PCT_GLACIER = nameDim(PCT_GLACIER,(/"lat","lon"/),"glacier percent","%")
    PCT_NATVEG  = nameDim(PCT_NATVEG,(/"lat","lon"/),"natural vegetation percent","%")
    PCT_WETLAND = nameDim(PCT_WETLAND,(/"lat","lon"/),"wetland percent","%")
    PCT_URBANt  = nameDim(PCT_URBANt,(/"lat","lon"/),"total urban","%")
    PCT_URBANt&lat = lat
    PCT_URBANt&lon = lon
    printVarSummary(PCT_LAKE)
    printVarSummary(PCT_GLACIER)
    printVarSummary(PCT_NATVEG)
    printVarSummary(PCT_WETLAND)

    ;;; 2) Natural PFT ;;;
    PCT_NAT_PFT = lulc(0:16,:,:)
    delete(PCT_NAT_PFT@_FillValue)
    PCT_NAT_PFT = where(PCT_NAT_PFT.gt.0,PCT_NAT_PFT,0.)
    PCT_NAT_PFT(0,:,:) = 100. - dim_sum_n(PCT_NAT_PFT(1:16,:,:),0)

    ptf_sum := dim_sum_n_Wrap(PCT_NAT_PFT,0)
    do ti = 0, 16
      PCT_NAT_PFT(ti,:,:) = PCT_NAT_PFT(ti,:,:) / ptf_sum * 100.
    end do
    PCT_NAT_PFT = where(PCT_NAT_PFT.ge.0, PCT_NAT_PFT, 0.)
    PCT_NAT_PFT(0,:,:) = 100. - dim_sum_n(PCT_NAT_PFT(1:16,:,:),0)

    ptf_sum := dim_sum_n_Wrap(PCT_NAT_PFT,0)
    print("ptf_sum: "+get_unique_values(ptf_sum)+", "+num(ptf_sum.eq.100.) +", "+ num(ptf_sum.lt.100.)+", "+ num(ptf_sum.lt.99.) +", "+ num(ptf_sum.lt.0.)+", "+ num(ptf_sum.gt.100.)+", "+ num(ptf_sum.gt.101.) )

    PCT_NAT_PFT = nameDim(PCT_NAT_PFT,(/"pft","lat","lon"/),"natural pft percent (sum=100)","%")
    printVarSummary(PCT_NAT_PFT)

    ;;; lake, wetland, glacier ;;;
    tmp0 := f1->PCT_LAKE
    tmp0 = (/PCT_LAKE/)
    fo->PCT_LAKE = tmp0

    tmp0 := f1->PCT_WETLAND
    tmp0 = (/PCT_WETLAND/)
    fo->PCT_WETLAND = tmp0

    tmp0 := f1->PCT_GLACIER
    tmp0 = (/PCT_GLACIER/)
    fo->PCT_GLACIER = tmp0

    tmp0 := f1->PCT_NATVEG
    tmp0 = (/PCT_NATVEG/)
    fo->PCT_NATVEG = tmp0

    tmp0 := f1->PCT_NAT_PFT
    tmp0 = (/PCT_NAT_PFT/)
    fo->PCT_NAT_PFT = tmp0

    ;; urban
    ;;; 2) assign urban ;;;
    PCT_URBAN = f1->PCT_URBAN
    PCT_URBAN(2,:,:) = (/ PCT_URBANt - dim_sum_n(PCT_URBAN(0:1,:,:),0)      /)
    PCT_URBAN(0,:,:) = (/ where(PCT_URBAN(2,:,:).lt.0, 0, PCT_URBAN(0,:,:)) /)
    PCT_URBAN(1,:,:) = (/ where(PCT_URBAN(2,:,:).lt.0, 0, PCT_URBAN(1,:,:)) /)
    PCT_URBAN(2,:,:) = (/ where(PCT_URBAN(2,:,:).lt.0, PCT_URBANt, PCT_URBAN(2,:,:)) /)

    fo->PCT_URBAN = PCT_URBAN
    exit
  end if

  ;;;;;;;;; make surface file ;;;;;;;
  skp_v0 = (/"time","mxsoil_color","mxsoil_order","natpft"/)
  var_grud = (/"STD_ELEV", "SLOPE","TOPO"/) ; why without TOPO
  var_soil = (/"PCT_CLAY","PCT_SAND","ORGANIC"/)
  var_lulc:= (/"PCT_NATVEG","PCT_NAT_PFT","PCT_LAKE","PCT_WETLAND","PCT_GLACIER","PCT_URBAN",\
               "MONTHLY_LAI","MONTHLY_SAI","MONTHLY_HEIGHT_TOP","MONTHLY_HEIGHT_BOT"/)

  if True then
    ;; input the 1k NLDAS data
    f1 = addfile(indir + "surfdata.nldas_8thT1k.nc","r")
    var_t = getfilevarnames(f1)
    print(var_t)

    fout = otdir + "surfdat_conus_1k_3d.nc"
    system("/bin/rm -f " + fout)
    setfileoption("nc","Format","NetCDF4")
    print("  Out: " + fout)
    fo = addfile(fout, "c")
    fo@creation_data=systemfunc("date")
    fo@information="NLDAS 1k domain Created by Lingcheng LI"
    glattr = getvaratts(f1)  ; attribute
    do i=0,dimsizes(glattr)-1
      fo@$glattr(i)$ = f1@$glattr(i)$
    end do

    ;; MASK
    var_msk = (/"PFTDATA_MASK","LATIXY","LONGXY"/)
    if True then
      tmp0 := f1->PFTDATA_MASK
      tmp0 = (/mask_1k/)
      fo->PFTDATA_MASK = tmp0

      lat_1k := nameDim(tofloat(lat_1k),(/"lat"/), "lat", "degrees north")
      lon_1k := nameDim(tofloat(lon_1k),(/"lon"/), "lon", "degrees east" )

      latxy_1k = new((/dimsizes(lat_1k),dimsizes(lon_1k)/),float)
      lonxy_1k = new((/dimsizes(lat_1k),dimsizes(lon_1k)/),float)
      do gi = 0, dimsizes(lat_1k)-1
        latxy_1k(gi,:) = (/ lat_1k(gi) /)
      end do
      do gi = 0, dimsizes(lon_1k)-1
        lonxy_1k(:,gi) = (/ lon_1k(gi) /)
      end do
      latxy_1k = nameDim(latxy_1k,(/"lat","lon"/), "latitude-2d",  "degrees north")
      lonxy_1k = nameDim(lonxy_1k,(/"lat","lon"/), "longitude-2d", "degrees east" )
      fo->LATIXY = latxy_1k
      fo->LONGXY = lonxy_1k
    end if

    ;; direct varialbes
    vars_1d = (/"time","mxsoil_color","mxsoil_order","natpft"/) ;
    if True then
      do vi = 0, dimsizes(vars_1d) - 1
         vari = vars_1d(vi)
         fo->$vari$ = f1->$vari$
      end do
    end if

    ;; TOPO variables
    var_grud = (/"STD_ELEV", "SLOPE","TOPO"/)
    if True then
      f3 = addfile( gedir + "mean_of_Elevation.nc","r")
      TOPO = f3->Band1
      f3 = addfile( gedir + "slope2.nc","r")
      SLOPE = f3->Band1
      f3 = addfile( gedir + "std_of_Elevation.nc","r")
      STD_ELEV = f3->Band1

      delete_VarAtts(TOPO,(/"_FillValue","_FillValue_original"/))
      delete_VarAtts(SLOPE,(/"_FillValue","_FillValue_original"/))
      delete_VarAtts(STD_ELEV,(/"_FillValue","_FillValue_original"/))
      TOPO := tofloat( where(TOPO.lt.5000, TOPO, 0) )
      SLOPE := tofloat( where(SLOPE.lt.5000, SLOPE, 0) )
      STD_ELEV := tofloat( where(STD_ELEV.lt.5000, STD_ELEV, 0) )

      tmp0 := f1->TOPO
      tmp0 = (/TOPO/)
      fo->TOPO = tmp0

      tmp0 := f1->SLOPE
      tmp0 = (/SLOPE/)
      fo->SLOPE = tmp0

      tmp0 := f1->STD_ELEV
      tmp0 = (/STD_ELEV/)
      fo->STD_ELEV = tmp0
    end if

    ;; update SOIL data
    var_soil = (/"PCT_CLAY","PCT_SAND","ORGANIC"/)
    if (True) then
      ;; input the soil data
      f3 = addfile(indir + "conus1k_Soil.nc","r")
      PCT_CLAY = f3->clay(0:9,:,:)
      PCT_SAND = f3->sand(0:9,:,:)
      ORGANIC  = f3->ocd(0:9,:,:)

      tmp0 := f1->PCT_CLAY
      tmp0 = (/PCT_CLAY/)
      fo->PCT_CLAY = tmp0

      tmp0 := f1->PCT_SAND
      tmp0 = (/PCT_SAND/)
      fo->PCT_SAND = tmp0

      tmp0 := f1->ORGANIC
      tmp0 = (/ORGANIC/)
      fo->ORGANIC = tmp0
    end if

    ;; update LULC ;;
    var_lulc:= (/"PCT_NATVEG","PCT_NAT_PFT","PCT_LAKE","PCT_WETLAND","PCT_GLACIER","PCT_URBAN"/)
    if True then
      ; 1) input the high data
      f3 = addfile(indir + "surfdat_LULC_1k.nc","r")
      do vi = 0, dimsizes(var_lulc)-1
        vari = var_lulc(vi)
        fo->$vari$ = f3->$vari$
      end do
    end if

    ;; update LAI ;;
    var_lai := (/"MONTHLY_LAI","MONTHLY_SAI","MONTHLY_HEIGHT_TOP","MONTHLY_HEIGHT_BOT"/)
    if True then
      ; 1) input the high data
      if True then  ; 3d
        f3 = addfile(indir + "surfdat_LAI3_1k.nc","r")
        do vi = 0, dimsizes(var_lai)-1
          vari = var_lai(vi)
          fo->$vari$ = f3->$vari$
        end do
      end if

      if False then  ; 4d
        f3 = addfile(indir + "surfdat_LAI4_1k.nc","r")
        do vi = 0, dimsizes(var_lai)-1
          vari = var_lai(vi)
          fo->$vari$ = f3->$vari$
        end do
      end if

    end if

    ;;;; other variables ;;;;
    vars_skip := venn2_union(var_msk,vars_1d)
    vars_skip := venn2_union(vars_skip,var_grud)
    vars_skip := venn2_union(vars_skip,var_soil)
    vars_skip := venn2_union(vars_skip,var_lulc)
    vars_skip := venn2_union(vars_skip,var_lai)
    printVarSummary(vars_skip)

    do vi = 0, dimsizes(var_t)-1
      print(vi+"  **"+var_t(vi)+" **")
      vari = var_t(vi)

      if (any(vars_skip.eq.vari)) then
         continue
      else
        fo->$vari$ = f1->$vari$
      end if

    end do
    exit


  end if







  exit



  flg_pft = "" ;"_WS2BDT0"  ;

  ;;;; soil texture, soil organic matter ;;;;
  ;; mksrf_fsoitex, mksrf_forganic
  if (False) then
    ; 1) input the high data
    f1 = addfile(indir + "icom_Soil_1km.nc","r")
    var_1k = getfilevarnames(f1)
    print(var_1k)

    lat_1k = f1->lat
    lon_1k = f1->lon
    clay_1k = f1->clay
    sand_1k = f1->sand
    silt_1k = f1->silt
    ocd_1k  = f1->ocd
    ocd_1k  = where(ocd_1k.lt.130,ocd_1k,130)  ; important !!!!
    dzsol_1k = (/ 0.0175, 0.0451, 0.0906, 0.1655, 0.2891, 0.4929,0.8289,1.3828, 2.2961, 3.8019, \  ; -> 2.00
                  6.2845, 10.3775, 17.1259, 28.252, 42.1032/)
    dzsol_1k = nameDim(dzsol_1k,(/"number_of_layers"/),"soil layer thicness","m")

    latxy_1k = new((/dimsizes(lat_1k),dimsizes(lon_1k)/),double)
    lonxy_1k = new((/dimsizes(lat_1k),dimsizes(lon_1k)/),double)
    do gi = 0, dimsizes(lat_1k)-1
      latxy_1k(gi,:) = lat_1k(gi)
    end do
    do gi = 0, dimsizes(lon_1k)-1
      lonxy_1k(:,gi) = lon_1k(gi)
    end do
    latxy_1k = nameDim(latxy_1k,(/"lat","lon"/), "latitude-2d", "degrees north")
    lonxy_1k = nameDim(lonxy_1k,(/"lat","lon"/), "longitude-2d", "degrees east" )
    printVarSummary(latxy_1k)
    printVarSummary(lonxy_1k)

    nlat_1k = dimsizes(lat_1k)
    nlon_1k = dimsizes(lon_1k)
    LAT = lat_1k
    LON = lon_1k
    LATIXY = latxy_1k
    LONGXY = lonxy_1k
    ;LANDMASK  = mask_1k
    ZSOI  = dzsol_1k
    DZSOI = ZSOI

    do i = 1, dimsizes(DZSOI) - 1
      DZSOI(i) = ZSOI(i) - ZSOI(i-1)
    end do

    ZSOI  = nameDim(ZSOI, "number_of_layers","soil layer depth","m")
    DZSOI = nameDim(DZSOI,"number_of_layers","soil layer thickness","m")

    EDGEN = (/ max(lat_1k) + ( lat_1k(nlat_1k-1) - lat_1k(nlat_1k-2))/2. /)
    EDGEN = nameDim(EDGEN,"ncl_scalar", "northern edge of surface grid", "degrees north")

    EDGES = (/ min(lat_1k) - ( lat_1k(1) - lat_1k(0))/2. /)
    EDGES = nameDim(EDGES,"ncl_scalar", "southern edge of surface grid", "degrees north")

    EDGEE = (/ max(lon_1k) + ( lon_1k(nlon_1k-1) - lon_1k(nlon_1k-2))/2. /)
    EDGEE = nameDim(EDGEE,"ncl_scalar", "eastern edge of surface grid", "degrees east")

    EDGEW = (/ min(lon_1k) - ( lon_1k(1) - lon_1k(0))/2. /)
    EDGEW = nameDim(EDGEW,"ncl_scalar", "western edge of surface grid", "degrees east")

    PCT_SAND = sand_1k
    PCT_CLAY = clay_1k
    PCT_SILT = silt_1k
    ORGANIC = ocd_1k
    PCT_SAND = nameDim(PCT_SAND,(/"number_of_layers","lat","lon"/),"percent sand","%")
    PCT_CLAY = nameDim(PCT_CLAY,(/"number_of_layers","lat","lon"/),"percent clay","%")
    ORGANIC  = nameDim(ORGANIC,(/"number_of_layers","lat","lon"/) ,"Organic soil density at soil levels","kg OM/m3(assumed carbon content 0.58 gC per gOM)")
    printVarSummary(PCT_SAND)
    printVarSummary(PCT_CLAY)
    printVarSummary(ORGANIC)

    PCT_sum = PCT_SAND(0,:,:) + PCT_CLAY(0,:,:) + PCT_SILT(0,:,:)
    LANDMASK = where(PCT_sum.gt.0, 1, 0)
    LANDMASK = nameDim(LANDMASK,(/"lat","lon"/),"land mask","unitless")
    printVarSummary(LANDMASK)

    ; 2) input the soil organic file
    if (False) then
      ;; reference data
      ; f3 = addfile("/compyfs/inputdata/lnd/clm2/rawdata/mksrf_organic_10level_5x5min_ISRIC-WISE-NCSCD_nlev7_c120830.nc","r")
      ; var_sf := getfilevarnames(f3)
      ; print("********** Soil organic *********")
      ; print(var_sf)

      ;; output the soil organic
      fout = otdir + "mksrf_soilogc_1km_10level_icom.nc"
      system("/bin/rm -f " + fout)
      print("  Out: " + fout)
      fo := addfile(fout, "c")
      fo@creation_data=systemfunc("date")
      fo@information="SOIL organic carbon density 5hm from soil grid. Created by Lingcheng LI"
      fo@data_source="SoilGrids — global gridded soil information https://www.isric.org/explore/soilgrids"
      fo->LAT = LAT
      fo->LON = LON
      fo->LATIXY = LATIXY
      fo->LONGXY = LONGXY
      fo->EDGEN = EDGEN
      fo->EDGES = EDGES
      fo->EDGEE = EDGEE
      fo->EDGEW = EDGEW
      fo->ZSOI = ZSOI(0:9)
      fo->DZSOI= DZSOI(0:9)
      fo->LANDMASK = LANDMASK
      fo->ORGANIC = ORGANIC(0:9,:,:)
    end if

    ; 2) input the soil texutre example  file
    if (True) then
      ; f2 = addfile( "/compyfs/inputdata/lnd/clm2/rawdata/mksrf_soitex.10level.c010119.nc","r")
      ; var_sf := getfilevarnames(f2)
      ; print("********** Soil texture ********* ")
      ; print(var_sf)
      ; mapunit = f2->MAPUNITS
      ; eg_sand = f2->PCT_SAND
      ; printVarSummary(eg_sand)

      ;; output the soil texture
      fout = otdir + "mksrf_soiltex_15level_icom.nc"
      system("/bin/rm -f " + fout)
      print("  Out: " + fout)
      fo := addfile(fout, "c")
      fo@creation_data=systemfunc("date")
      fo@information="SOIL texture 5hm from soil grid. Created by Lingcheng LI"
      fo@data_source="SoilGrids — global gridded soil information https://www.isric.org/explore/soilgrids"
      fo->LAT = LAT
      fo->LON = LON
      fo->LATIXY = LATIXY
      fo->LONGXY = LONGXY
      fo->ZSOI = ZSOI;(0:9)
      fo->DZSOI= DZSOI;(0:9)
      fo->LANDMASK = LANDMASK
      fo->PCT_SAND = PCT_SAND;(0:9,:)
      fo->PCT_CLAY = PCT_CLAY;(0:9,:)
      fo->ORGANIC = ORGANIC;(0:9,:,:)
    end if ; soil texture
    exit
  end if

  ;;;; 3) land use and land cover ;;;;
  ;; mksrf_flakwat, mksrf_fwetlnd, mksrf_fmax, mksrf_fglacier, mksrf_urban
  if (True) then

    ; 0)input the land mask
    f1 = addfile( otdir + "icom_1km_mask.nc","r")
    mask_1k = f1->mask

    ; 1) input the high data
    f1 = addfile(indir + "icom_LULC_1km"+flg_pft+".nc","r")
    var_1k = getfilevarnames(f1)
    print(var_1k)

    lat_1k = f1->lat
    lon_1k = f1->lon
    lulc   = f1->lulc
    latxy_1k = new((/dimsizes(lat_1k),dimsizes(lon_1k)/),double)
    lonxy_1k = new((/dimsizes(lat_1k),dimsizes(lon_1k)/),double)
    do gi = 0, dimsizes(lat_1k)-1
      latxy_1k(gi,:) = lat_1k(gi)
    end do
    do gi = 0, dimsizes(lon_1k)-1
      lonxy_1k(:,gi) = lon_1k(gi)
    end do
    latxy_1k = nameDim(latxy_1k,(/"lat","lon"/),  "latitude-2d", "degrees north")
    lonxy_1k = nameDim(lonxy_1k,(/"lat","lon"/), "longitude-2d", "degrees east" )
    printVarSummary(latxy_1k)
    printVarSummary(lonxy_1k)

    nlat_1k = dimsizes(lat_1k)
    nlon_1k = dimsizes(lon_1k)
    LAT = lat_1k
    LON = lon_1k
    LATIXY = latxy_1k
    LONGXY = lonxy_1k
    LANDMASK  = mask_1k

    EDGEN = (/ max(lat_1k) + ( lat_1k(nlat_1k-1) - lat_1k(nlat_1k-2))/2. /)
    EDGEN = nameDim(EDGEN,"ncl_scalar", "northern edge of surface grid", "degrees north")

    EDGES = (/ min(lat_1k) - ( lat_1k(1) - lat_1k(0))/2. /)
    EDGES = nameDim(EDGES,"ncl_scalar", "southern edge of surface grid", "degrees north")

    EDGEE = (/ max(lon_1k) + ( lon_1k(nlon_1k-1) - lon_1k(nlon_1k-2))/2. /)
    EDGEE = nameDim(EDGEE,"ncl_scalar", "eastern edge of surface grid", "degrees east")

    EDGEW = (/ min(lon_1k) - ( lon_1k(1) - lon_1k(0))/2. /)
    EDGEW = nameDim(EDGEW,"ncl_scalar", "western edge of surface grid", "degrees east")

    delete(lulc@_FillValue)
    lulc := todouble( where(lulc.gt.0,lulc,0.) )
    printVarSummary(lulc)
    ; sum to 100 and non-negative value
    lulc_sum := dim_sum_n_Wrap(lulc,0)
    do ti = 0, 20
      lulc(ti,:,:) = lulc(ti,:,:) / lulc_sum * todouble(100.)
    end do
    lulc_sum := dim_sum_n_Wrap(lulc,0)
    print("lulc_sum: "+num(lulc_sum.eq.100.) +", "+ num(lulc_sum.lt.100.)+", "+ num(lulc_sum.lt.99.) +", "+ num(lulc_sum.lt.0.)+", "+ num(lulc_sum.gt.100.)+", "+ num(lulc_sum.gt.101.) )

    ;;;;;;;  adjust non vegatation pct  ;;;;;;;
    ;; 0=< PCT_NONVEG <= 100
    ;; non missing value !!!
    PCT_LAKE    = lulc(17,:,:)
    PCT_WETLAND = lulc(18,:,:)
    PCT_GLACIER = lulc(19,:,:)
    PCT_URBANt  = lulc(20,:,:)
    PCT_LAKE    = where(PCT_LAKE.gt.0,   PCT_LAKE,   0.)
    PCT_WETLAND = where(PCT_WETLAND.gt.0,PCT_WETLAND,0.)
    PCT_GLACIER = where(PCT_GLACIER.gt.0,PCT_GLACIER,0.)
    PCT_URBANt  = where(PCT_URBANt.gt.0, PCT_URBANt, 0.)

    PCT_NONVEG  = PCT_LAKE + PCT_WETLAND + PCT_GLACIER + PCT_URBANt
    printVarSummary(PCT_NONVEG)
    PCT_NONVEG  = where(PCT_NONVEG.eq.0,-9999,PCT_NONVEG)
    PCT_NONVEG@_FillValue = -9999.

    PCT_LAKE    = (/ where(PCT_NONVEG.gt.100, todouble(PCT_LAKE/PCT_NONVEG),    PCT_LAKE) /)
    PCT_WETLAND = (/ where(PCT_NONVEG.gt.100, todouble(PCT_WETLAND/PCT_NONVEG), PCT_WETLAND) /)
    PCT_GLACIER = (/ where(PCT_NONVEG.gt.100, todouble(PCT_GLACIER/PCT_NONVEG), PCT_GLACIER) /)
    PCT_URBANt  = (/ where(PCT_NONVEG.gt.100, todouble(PCT_URBANt/PCT_NONVEG) , PCT_URBANt)  /)
    delete([/PCT_LAKE@_FillValue, PCT_WETLAND@_FillValue, PCT_GLACIER@_FillValue, PCT_URBANt@_FillValue/])
    PCT_LAKE    = where(PCT_LAKE.gt.0,   PCT_LAKE,   0.)
    PCT_WETLAND = where(PCT_WETLAND.gt.0,PCT_WETLAND,0.)
    PCT_GLACIER = where(PCT_GLACIER.gt.0,PCT_GLACIER,0.)
    PCT_URBANt  = where(PCT_URBANt.gt.0, PCT_URBANt, 0.)

    PCT_NONVEG  = PCT_LAKE + PCT_WETLAND + PCT_GLACIER + PCT_URBANt
    PCT_NONVEG  = nameDim(PCT_NONVEG,(/"lat","lon"/),"non natural vegetation percentage","unitless")
    print("PCT_NONVEG1: "+" , "+num(.not.ismissing(PCT_NONVEG))+" , "+num(ismissing(PCT_NONVEG))+" , "+num(PCT_NONVEG.eq.100.)+" , "+num(PCT_NONVEG.gt.100.)+" , "+num(PCT_NONVEG.lt.0.))

    PCT_NATVEG = 100 - PCT_LAKE - PCT_WETLAND - PCT_GLACIER - PCT_URBANt
    PCT_NATVEG = where(PCT_NATVEG.ge.0,PCT_NATVEG,0.)
    ;print("PCT_NATVEG  "+get_unique_values(toint(PCT_NATVEG)))
    print("PCT_NATVEG2: "+" , "+num(.not.ismissing(PCT_NATVEG))+" , "+num(ismissing(PCT_NATVEG))+" , "+num(PCT_NATVEG.eq.100.)+" , "+num(PCT_NATVEG.gt.100.)+" , "+num(PCT_NATVEG.lt.0.))

    ; double check
    ; check the variabless ralationship
    PCT_TOT_ck = PCT_NATVEG + PCT_LAKE + PCT_WETLAND + PCT_GLACIER + PCT_URBANt   ; equal 100
    PCT_TOT_ck = nameDim(PCT_TOT_ck,(/"lat","lon"/),"Total percentage of land cover","unitless")
    print("PCT_TOT_ck:  "+get_unique_values(PCT_TOT_ck)+", "+ num(PCT_TOT_ck.lt.100.))
    ;print("PCT_TOT_ck: "+num(PCT_TOT_ck.lt.100.) +", "+ num(PCT_TOT_ck.gt.100.) +", "+ num(PCT_TOT_ck.eq.100.)+", "+ num(.not.ismissing(PCT_TOT_ck))+", "+ num(ismissing(PCT_TOT_ck)) )

    ; check all variables
    printMinMax(PCT_NATVEG,0)
    printMinMax(PCT_LAKE,0)
    printMinMax(PCT_WETLAND,0)
    printMinMax(PCT_GLACIER,0)
    printMinMax(PCT_URBANt,0)

    PCT_LAKE = nameDim(PCT_LAKE,(/"lat","lon"/),"lake percent","%")
    PCT_GLACIER = nameDim(PCT_GLACIER,(/"lat","lon"/),"glacier percent","%")
    PCT_NATVEG  = nameDim(PCT_NATVEG,(/"lat","lon"/),"natural vegetation percent","%")
    PCT_WETLAND = nameDim(PCT_WETLAND,(/"lat","lon"/),"wetland percent","%")
    PCT_URBANt  = nameDim(PCT_URBANt,(/"lat","lon"/),"total urban","%")
    PCT_URBANt&lat = LAT
    PCT_URBANt&lon = LON
    printVarSummary(PCT_LAKE)
    printVarSummary(PCT_GLACIER)
    printVarSummary(PCT_NATVEG)
    printVarSummary(PCT_WETLAND)

    ;;; 2) Natural PFT ;;;
    PCT_NAT_PFT = lulc(0:16,:,:)
    delete(PCT_NAT_PFT@_FillValue)
    PCT_NAT_PFT = where(PCT_NAT_PFT.gt.0,PCT_NAT_PFT,0.)
    PCT_NAT_PFT(0,:,:) = 100. - dim_sum_n(PCT_NAT_PFT(1:16,:,:),0)

    ptf_sum := dim_sum_n_Wrap(PCT_NAT_PFT,0)
    do ti = 0, 16
      PCT_NAT_PFT(ti,:,:) = PCT_NAT_PFT(ti,:,:) / ptf_sum * 100.
    end do
    PCT_NAT_PFT = where(PCT_NAT_PFT.ge.0, PCT_NAT_PFT, 0.)
    PCT_NAT_PFT(0,:,:) = 100. - dim_sum_n(PCT_NAT_PFT(1:16,:,:),0)

    ptf_sum := dim_sum_n_Wrap(PCT_NAT_PFT,0)
    print("ptf_sum: "+get_unique_values(ptf_sum)+", "+num(ptf_sum.eq.100.) +", "+ num(ptf_sum.lt.100.)+", "+ num(ptf_sum.lt.99.) +", "+ num(ptf_sum.lt.0.)+", "+ num(ptf_sum.gt.100.)+", "+ num(ptf_sum.gt.101.) )

    PCT_NAT_PFT = nameDim(PCT_NAT_PFT,(/"pft","lat","lon"/),"natural pft percent (sum=100)","%")
    printVarSummary(PCT_NAT_PFT)

    ; 1) lake
    if (True) then
      f2 = addfile("/compyfs/inputdata/lnd/clm2/rawdata/mksrf_LakePnDepth_3x3min_simyr2004_c111116.nc","r")
      var_sf := getfilevarnames(f2)
      print("********** lake *********")
      print(var_sf)

      ;; from low to hi resolution
      lw_lat = f2->LAT
      lw_lon = f2->LON
      lw_lat&lat = lw_lat
      lw_lon&lon = lw_lon
      printVarSummary(lw_lat)

      lw_lakemask = tofloat( f2->LAKEDATAMASK )
      lw_lakedept = tofloat( f2->LAKEDEPTH )
      lw_lakemask = nameDim(lw_lakemask,(/"lat","lon"/),"Mask indicating real lake depth data found in gridcell","unitless")
      lw_lakedept = nameDim(lw_lakedept,(/"lat","lon"/),"Lake Depth (default = 10m)","m")
      lw_lakemask&lat = lw_lat
      lw_lakemask&lon = lw_lon
      lw_lakedept&lat = lw_lat
      lw_lakedept&lon = lw_lon
      printVarSummary(lw_lakemask)
      printVarSummary(lw_lakedept)

      lw_latS = lw_lat( ind_nearest_coord(min(lat_1k),lw_lat,0) )
      lw_latN = lw_lat( ind_nearest_coord(max(lat_1k),lw_lat,0) )
      lw_lonW = lw_lon( ind_nearest_coord(min(lon_1k),lw_lon,0) )
      lw_lonE = lw_lon( ind_nearest_coord(max(lon_1k),lw_lon,0) )
      print("lw_latS: "+lw_latS + " < "+ min(lat_1k))
      print("lw_latN: "+lw_latN + " > "+ max(lat_1k))
      print("lw_lonW: "+lw_lonW + " < "+ min(lon_1k))
      print("lw_lonE: "+lw_lonE + " > "+ max(lon_1k))

      lw_lat1 := lw_lat({lw_latS:lw_latN})
      lw_lon1 := lw_lon({lw_lonW:lw_lonE})
      print(dimsizes(lw_lat1) + ", " + dimsizes(lw_lon1))

      hi_lakemask = LATIXY
      hi_lakemask&lat = LAT
      hi_lakemask&lon = LON

      hi_lakedept = hi_lakemask
      hi_lakedept = 10.
      hi_lakemask = 0

      do i = 0, dimsizes(lw_lat1)-1
        do j = 0, dimsizes(lw_lon1)-1
          print( i+"/"+(dimsizes(lw_lat1)-1)+", "+j+"/"+(dimsizes(lw_lon1)-1) )
          ilat_S = lw_lat1(i) - (lw_lat1(1) - lw_lat1(0))/2.
          ilat_N = lw_lat1(i) + (lw_lat1(1) - lw_lat1(0))/2.
          ilon_W = lw_lon1(j) - (lw_lon1(1) - lw_lon1(0))/2.
          ilon_E = lw_lon1(j) + (lw_lon1(1) - lw_lon1(0))/2.

          hi_lakemask({ilat_S:ilat_N},{ilon_W:ilon_E}) = lw_lakemask({lw_lat1(i)},{lw_lon1(j)})
          hi_lakedept({ilat_S:ilat_N},{ilon_W:ilon_E}) = lw_lakedept({lw_lat1(i)},{lw_lon1(j)})
        end do ; lat
      end do ; lon
      hi_lakemask = nameDim(hi_lakemask,(/"lat","lon"/),"Mask indicating real lake depth data found in gridcell","unitless")
      hi_lakedept = nameDim(hi_lakedept,(/"lat","lon"/),"Lake Depth (default = 10m)","unitless")
      printVarSummary(hi_lakemask)
      printVarSummary(hi_lakedept)
      print(num(ismissing(hi_lakemask)))
      print(num(ismissing(hi_lakedept)))

      ;; lake
      ; fout = otdir + "mksrf_lakewat_1km_icom.nc"
      ; system("/bin/rm -f " + fout)
      ; print("  Out: " + fout)
      ; fo := addfile(fout, "c")
      ; fo@creation_data=systemfunc("date")
      ; fo@information="Lake percentage, Created by Lingcheng LI"
      ; fo@data_source="MODIS LC5 https://developers.google.com/earth-engine/datasets/catalog/MODIS_006_MCD12Q1"
      ; fo->LAT = LAT
      ; fo->LON = LON
      ; fo->LATIXY = LATIXY
      ; fo->LONGXY = LONGXY
      ; fo->EDGEN = EDGEN
      ; fo->EDGES = EDGES
      ; fo->EDGEE = EDGEE
      ; fo->EDGEW = EDGEW
    end if

    ; 2) natural PFT
    if (False) then
      f2 = addfile("/compyfs/inputdata/lnd/clm2/rawdata/LUT_LUH2_HIST_LUH1f_07082020/LUT_LUH2_historical_2010_c07082020.nc","r")
      var_sf := getfilevarnames(f2)
      print("********** natureal PFT *********")
      print(var_sf)

      ;; from low to hi resolution
      lw_lat := f2->LAT
      lw_lon := f2->LON
      lw_lat&lat = lw_lat
      lw_lon&lon = lw_lon
      printVarSummary(lw_lat)

      lw_harvst_vh1 = f2->HARVEST_VH1
      lw_harvst_vh2 = f2->HARVEST_VH2
      lw_harvst_sh1 = f2->HARVEST_SH1
      lw_harvst_sh2 = f2->HARVEST_SH2
      lw_harvst_sh3 = f2->HARVEST_SH3
      lw_grazing    = f2->GRAZING

      lw_harvst_vh1&lat = lw_lat
      lw_harvst_vh1&lon = lw_lon
      lw_harvst_vh2&lat = lw_lat
      lw_harvst_vh2&lon = lw_lon
      lw_harvst_sh1&lat = lw_lat
      lw_harvst_sh1&lon = lw_lon
      lw_harvst_sh2&lat = lw_lat
      lw_harvst_sh2&lon = lw_lon
      lw_harvst_sh3&lat = lw_lat
      lw_harvst_sh3&lon = lw_lon
      lw_grazing&lat = lw_lat
      lw_grazing&lon = lw_lon

      lw_latS = lw_lat( ind_nearest_coord(min(lat_1k),lw_lat,0) )
      lw_latN = lw_lat( ind_nearest_coord(max(lat_1k),lw_lat,0) )
      lw_lonW = lw_lon( ind_nearest_coord(min(lon_1k),lw_lon,0) )
      lw_lonE = lw_lon( ind_nearest_coord(max(lon_1k),lw_lon,0) )
      print("lw_latS: "+lw_latS + " < "+ min(lat_1k))
      print("lw_latN: "+lw_latN + " > "+ max(lat_1k))
      print("lw_lonW: "+lw_lonW + " < "+ min(lon_1k))
      print("lw_lonE: "+lw_lonE + " > "+ max(lon_1k))

      lw_lat1 := lw_lat({lw_latS:lw_latN})
      lw_lon1 := lw_lon({lw_lonW:lw_lonE})
      print(dimsizes(lw_lat1) + ", " + dimsizes(lw_lon1))

      hi_harvst_vh1 = LATIXY
      hi_harvst_vh1&lat = LAT
      hi_harvst_vh1&lon = LON
      hi_harvst_vh2 = hi_harvst_vh1
      hi_harvst_sh1 = hi_harvst_vh1
      hi_harvst_sh2 = hi_harvst_vh1
      hi_harvst_sh3 = hi_harvst_vh1
      hi_grazing    = hi_harvst_vh1

      do i = 0, dimsizes(lw_lat1)-1
        do j = 0, dimsizes(lw_lon1)-1
          print( i+"/"+(dimsizes(lw_lat1)-1)+", "+j+"/"+(dimsizes(lw_lon1)-1) )
          ilat_S = lw_lat1(i) - (lw_lat1(1) - lw_lat1(0))/2.
          ilat_N = lw_lat1(i) + (lw_lat1(1) - lw_lat1(0))/2.
          ilon_W = lw_lon1(j) - (lw_lon1(1) - lw_lon1(0))/2.
          ilon_E = lw_lon1(j) + (lw_lon1(1) - lw_lon1(0))/2.

          hi_harvst_vh1({ilat_S:ilat_N},{ilon_W:ilon_E}) = lw_harvst_vh1({lw_lat1(i)},{lw_lon1(j)})
          hi_harvst_vh2({ilat_S:ilat_N},{ilon_W:ilon_E}) = lw_harvst_vh2({lw_lat1(i)},{lw_lon1(j)})
          hi_harvst_sh1({ilat_S:ilat_N},{ilon_W:ilon_E}) = lw_harvst_sh1({lw_lat1(i)},{lw_lon1(j)})
          hi_harvst_sh2({ilat_S:ilat_N},{ilon_W:ilon_E}) = lw_harvst_sh2({lw_lat1(i)},{lw_lon1(j)})
          hi_harvst_sh3({ilat_S:ilat_N},{ilon_W:ilon_E}) = lw_harvst_sh3({lw_lat1(i)},{lw_lon1(j)})
          hi_grazing({ilat_S:ilat_N},{ilon_W:ilon_E})    = lw_grazing({lw_lat1(i)},{lw_lon1(j)})
        end do ; lat
      end do ; lon
      hi_harvst_vh1 = nameDim(hi_harvst_vh1,(/"lat","lon"/),"harvest from primary forest"," ")
      hi_harvst_vh2 = nameDim(hi_harvst_vh2,(/"lat","lon"/),"harvest from primary non-forest"," ")
      hi_harvst_sh1 = nameDim(hi_harvst_sh1,(/"lat","lon"/),"harvest from secondary mature-forest"," ")
      hi_harvst_sh2 = nameDim(hi_harvst_sh2,(/"lat","lon"/),"harvest from secondary young-forest"," ")
      hi_harvst_sh3 = nameDim(hi_harvst_sh3,(/"lat","lon"/),"harvest from secondary non-forest"," ")
      hi_grazing = nameDim(hi_grazing,(/"lat","lon"/),"grazing of herbacous pfts","")
      printVarSummary(hi_harvst_vh1)
      printVarSummary(hi_harvst_sh1)

      ;; output the soil organic
      fout = otdir + "mksrf_natpft_1km_icom"+flg_pft+".nc"
      system("/bin/rm -f " + fout)
      print("  Out: " + fout)
      fo := addfile(fout, "c")
      fo@creation_data=systemfunc("date")
      fo@information="Nature PFT, Created by Lingcheng LI"
      fo@data_source="MODIS LC5 https://developers.google.com/earth-engine/datasets/catalog/MODIS_006_MCD12Q1"
      fo->LAT = LAT
      fo->LON = LON
      fo->LATIXY = LATIXY
      fo->LONGXY = LONGXY
      fo->EDGEN = EDGEN
      fo->EDGES = EDGES
      fo->EDGEE = EDGEE
      fo->EDGEW = EDGEW
      fo->LANDMASK= LANDMASK
      fo->PCT_PFT= PCT_NAT_PFT

      fo->HARVEST_VH1 = hi_harvst_vh1
      fo->HARVEST_VH2 = hi_harvst_vh2
      fo->HARVEST_SH1 = hi_harvst_sh1
      fo->HARVEST_SH2 = hi_harvst_sh2
      fo->HARVEST_SH3 = hi_harvst_sh3
      fo->GRAZING = hi_grazing

    end if

    ; 3) wetland
    if (False) then
      f2 = addfile("/compyfs/inputdata/lnd/clm2/rawdata/mksrf_lanwat.050425.nc","r")
      var_sf := getfilevarnames(f2)
      print("********** wetland *********")
      print(var_sf)

      ;; output the soil organic
      fout = otdir + "mksrf_wetland_1km_icom.nc"
      system("/bin/rm -f " + fout)
      print("  Out: " + fout)
      fo := addfile(fout, "c")
      fo@creation_data=systemfunc("date")
      fo@information="wetland percentage, Created by Lingcheng LI"
      fo@data_source="MODIS LC5 https://developers.google.com/earth-engine/datasets/catalog/MODIS_006_MCD12Q1"
      fo->LAT = LAT
      fo->LON = LON
      fo->LATIXY = LATIXY
      fo->LONGXY = LONGXY
      fo->EDGEN = EDGEN
      fo->EDGES = EDGES
      fo->EDGEE = EDGEE
      fo->EDGEW = EDGEW
      fo->LANDMASK= LANDMASK
      fo->PCT_LAKE = PCT_LAKE
      fo->PCT_WETLAND = PCT_WETLAND

    end if

    ; 4) glacier
    if (False) then
      f2 = addfile("/compyfs/inputdata/lnd/clm2/rawdata/mksrf_glacier_3x3min_simyr2000.c120926.nc","r")
      var_sf := getfilevarnames(f2)
      print("********** glacier *********")
      print(var_sf)

      fout = otdir + "mksrf_glacier_1km_icom.nc"
      system("/bin/rm -f " + fout)
      print("  Out: " + fout)
      fo := addfile(fout, "c")
      fo@creation_data=systemfunc("date")
      fo@information="glacier percentage, Created by Lingcheng LI"
      fo@data_source="MODIS LC5 https://developers.google.com/earth-engine/datasets/catalog/MODIS_006_MCD12Q1"
      fo->LAT = LAT
      fo->LON = LON
      fo->LATIXY = LATIXY
      fo->LONGXY = LONGXY
      fo->EDGEN = EDGEN
      fo->EDGES = EDGES
      fo->EDGEE = EDGEE
      fo->EDGEW = EDGEW
      fo->LANDMASK= LANDMASK
      fo->PCT_GLACIER = PCT_GLACIER

    end if

    ; 5) urban
    if (True) then
      f2 = addfile("/compyfs/inputdata/lnd/clm2/rawdata/mksrf_urban_0.05x0.05_simyr2000.c120621.nc","r")
      var_sf := getfilevarnames(f2)
      print("********** vegetation *********")
      print(var_sf)

      ;; from low to hi resolution
      lw_lat := f2->LAT
      lw_lon := f2->LON
      lw_lat&lat = lw_lat
      lw_lon&lon = lw_lon
      printVarSummary(lw_lat)

      lw_REGION_ID = f2->REGION_ID
      lw_PCT_URBAN= f2->PCT_URBAN
      lw_REGION_ID&lat = lw_lat
      lw_REGION_ID&lon = lw_lon
      lw_PCT_URBAN&lat = lw_lat
      lw_PCT_URBAN&lon = lw_lon

      lw_latS := lw_lat( ind_nearest_coord(min(lat_1k),lw_lat,0) )
      lw_latN := lw_lat( ind_nearest_coord(max(lat_1k),lw_lat,0) )
      lw_lonW := lw_lon( ind_nearest_coord(min(lon_1k),lw_lon,0) )
      lw_lonE := lw_lon( ind_nearest_coord(max(lon_1k),lw_lon,0) )

      if (lw_latS.gt.min(lat_1k)) then
        lw_latS = lw_latS - (lw_lat(1) - lw_lat(0))/2.
      end if
      if (lw_latN.lt.max(lat_1k)) then
        lw_latN = lw_latN + (lw_lat(1) - lw_lat(0))/2.
      end if
      if (lw_lonW.gt.max(lon_1k)) then
        lw_lonW = lw_lonW - (lw_lon(1) - lw_lon(0))/2.
      end if
      if (lw_lonE.lt.max(lon_1k)) then
        lw_lonE = lw_lonE + (lw_lon(1) - lw_lon(0))/2.
      end if

      print("lw_latS: "+lw_latS + " < "+ min(lat_1k))
      print("lw_latN: "+lw_latN + " > "+ max(lat_1k))
      print("lw_lonW: "+lw_lonW + " < "+ min(lon_1k))
      print("lw_lonE: "+lw_lonE + " > "+ max(lon_1k))

      lw_lat1 := lw_lat({lw_latS:lw_latN})
      lw_lon1 := lw_lon({lw_lonW:lw_lonE})
      print(dimsizes(lw_lat1) + ", " + dimsizes(lw_lon1))

      REGION_ID = LATIXY
      REGION_ID = nameDim(REGION_ID,(/"lat","lon"/), "Region ID", "unitless")
      REGION_ID&lat = LAT
      REGION_ID&lon = LON

      ;;; 2) assign urban ;;;
      PCT_URBAN = new((/3,dimsizes(LAT),dimsizes(LON)/),double)
      PCT_URBAN = nameDim(PCT_URBAN,(/"density_class","lat","lon"/), "percent urban", "%")
      PCT_URBAN&lat = LAT
      PCT_URBAN&lon = LON
      PCT_URBAN = 0.
      delete(PCT_URBAN@_FillValue)

      do i = 0, dimsizes(lw_lat1)-1
        do j = 0, dimsizes(lw_lon1)-1
          print( i+"/"+(dimsizes(lw_lat1)-1)+", "+j+"/"+(dimsizes(lw_lon1)-1) )
          ilat_S := lw_lat1(i) - (lw_lat1(1) - lw_lat1(0))/2.
          ilat_N := lw_lat1(i) + (lw_lat1(1) - lw_lat1(0))/2.
          ilon_W := lw_lon1(j) - (lw_lon1(1) - lw_lon1(0))/2.
          ilon_E := lw_lon1(j) + (lw_lon1(1) - lw_lon1(0))/2.

          ;; ID
            REGION_ID({ilat_S:ilat_N},{ilon_W:ilon_E}) = (/ lw_REGION_ID({lw_lat1(i)},{lw_lon1(j)}) /)

            ;; pct
            tmp_t := PCT_URBANt({ilat_S:ilat_N},{ilon_W:ilon_E})
            tmp0 := tmp_t
            tmp0 = 0
            tmp1 := tmp0
            tmp0 := (/ lw_PCT_URBAN(0,{lw_lat1(i)},{lw_lon1(j)}) /)
            tmp1 := (/ lw_PCT_URBAN(1,{lw_lat1(i)},{lw_lon1(j)}) /)
            tmp2 := (/ PCT_URBANt({ilat_S:ilat_N},{ilon_W:ilon_E}) - (tmp0 + tmp1) /)

            PCT_URBAN(0,{ilat_S:ilat_N},{ilon_W:ilon_E}) = (/ tmp0 /)
            PCT_URBAN(1,{ilat_S:ilat_N},{ilon_W:ilon_E}) = (/ tmp1 /)
            PCT_URBAN(2,{ilat_S:ilat_N},{ilon_W:ilon_E}) = (/ tmp2 /)

            PCT_URBAN(0,{ilat_S:ilat_N},{ilon_W:ilon_E}) = (/ where(tmp2.lt.0, 0., tmp0)    /)
            PCT_URBAN(1,{ilat_S:ilat_N},{ilon_W:ilon_E}) = (/ where(tmp2.lt.0, 0., tmp1)    /)
            PCT_URBAN(2,{ilat_S:ilat_N},{ilon_W:ilon_E}) = (/ where(tmp2.lt.0, tmp_t, tmp2) /)
        end do ; lat
      end do ; lon

      printVarSummary(REGION_ID)
      printVarSummary(PCT_URBAN)

      ; ;; output the soil organic
        ; fout = "/compyfs/lili400/project/ICoM/data/elm_1k/mksrf_urban_1km_icom.nc"
        ; system("/bin/rm -f " + fout)
        ; print("  Out: " + fout)
        ; fo := addfile(fout, "c")
        ; fo@creation_data=systemfunc("date")
        ; fo@information="Lake percentage, Created by Lingcheng LI"
        ; fo@data_source="MODIS LC5 https://developers.google.com/earth-engine/datasets/catalog/MODIS_006_MCD12Q1"
        ; fo->LAT = LAT
        ; fo->LON = LON
        ; fo->LATIXY = LATIXY
        ; fo->LONGXY = LONGXY
        ; fo->EDGEN = EDGEN
        ; fo->EDGES = EDGES
        ; fo->EDGEE = EDGEE
        ; fo->EDGEW = EDGEW
        ; fo->LANDMASK= LANDMASK
        ; fo->PCT_URBAN = PCT_URBAN
        ; fo->REGION_ID = REGION_ID
        ;
        ; tmp_var = (/"CANYON_HWR", "WTLUNIT_ROOF", "WTROAD_PERV", "EM_ROOF", "EM_WALL", \
        ;             "EM_IMPROAD", "EM_PERROAD", "ALB_ROOF", "ALB_WALL", "ALB_IMPROAD", \
        ;             "ALB_PERROAD", "HT_ROOF", "WIND_HGT_CANYON", "TK_ROOF", "TK_WALL", \
        ;             "TK_IMPROAD", "CV_ROOF", "CV_WALL", "CV_IMPROAD", "NLEV_IMPROAD",  \
        ;             "THICK_ROOF", "THICK_WALL", "T_BUILDING_MIN", "T_BUILDING_MAX"/)
        ;
        ; do vi = 0, dimsizes(tmp_var) - 1
        ;   vari = tmp_var(vi)
        ;   fo->$vari$ = f2->$vari$
        ; end do

      ;; output the soil organic
      fout = otdir + "mksrf_lulc_icom.nc"
      system("/bin/rm -f " + fout)
      print("  Out: " + fout)
      fo := addfile(fout, "c")
      fo@creation_data=systemfunc("date")
      fo@information="Lake percentage, Created by Lingcheng LI"
      fo@data_source="MODIS LC5 https://developers.google.com/earth-engine/datasets/catalog/MODIS_006_MCD12Q1"

      fo->LANDMASK= LANDMASK
      fo->PCT_LAKE = PCT_LAKE

      fo->LAKEDATAMASK = hi_lakemask
      fo->LAKEDEPTH = hi_lakedept

      fo->PCT_NAT_PFT = PCT_NAT_PFT
      fo->PCT_NATVEG  = PCT_NATVEG
      fo->PCT_WETLAND = PCT_WETLAND
      fo->PCT_GLACIER = PCT_GLACIER

      ;urban
      fo->PCT_URBAN = PCT_URBAN
      fo->REGION_ID = REGION_ID

      tmp_var = (/"CANYON_HWR", "WTLUNIT_ROOF", "WTROAD_PERV", "EM_ROOF", "EM_WALL", \
                  "EM_IMPROAD", "EM_PERROAD", "ALB_ROOF", "ALB_WALL", "ALB_IMPROAD", \
                  "ALB_PERROAD", "HT_ROOF", "WIND_HGT_CANYON", "TK_ROOF", "TK_WALL", \
                  "TK_IMPROAD", "CV_ROOF", "CV_WALL", "CV_IMPROAD", "NLEV_IMPROAD",  \
                  "THICK_ROOF", "THICK_WALL", "T_BUILDING_MIN", "T_BUILDING_MAX"/)

      do vi = 0, dimsizes(tmp_var) - 1
        vari = tmp_var(vi)
        fo->$vari$ = f2->$vari$
      end do

      exit
    end if

    exit
  end if

  ;; 4) LAI, SAI, canopy height
  if (False) then

    ; 0)input the land mask
    f1 = addfile(otdir + "icom_1km_mask.nc","r")
    mask_1k = f1->mask

    ; lulc
    f1 = addfile(indir + "icom_LULC_1km"+flg_pft+".nc","r")
    lulc_1k = f1->lulc
    printVarSummary(lulc_1k)

    ; 1) input the high data
    f1 = addfile(indir + "icom_SAI_LAI_1km.nc","r")
    var_1k = getfilevarnames(f1)
    print(var_1k)

    lat_1k = tofloat( f1->lat )
    lon_1k = tofloat( f1->lon )
    lai_1k = tofloat( f1->lai )
    sai_1k = tofloat( f1->sai )

    lat_1k = nameDim(lat_1k,(/"lat"/), "lat", "degrees north")
    lon_1k = nameDim(lon_1k,(/"lon"/), "lon", "degrees east" )
    printVarSummary(lai_1k)

    latxy_1k = new((/dimsizes(lat_1k),dimsizes(lon_1k)/),float)
    lonxy_1k = new((/dimsizes(lat_1k),dimsizes(lon_1k)/),float)
    do gi = 0, dimsizes(lat_1k)-1
      latxy_1k(gi,:) = lat_1k(gi)
    end do
    do gi = 0, dimsizes(lon_1k)-1
      lonxy_1k(:,gi) = lon_1k(gi)
    end do
    latxy_1k = nameDim(latxy_1k,(/"lat","lon"/), "latitude-2d",  "degrees north")
    lonxy_1k = nameDim(lonxy_1k,(/"lat","lon"/), "longitude-2d", "degrees east" )
    printVarSummary(latxy_1k)
    printVarSummary(lonxy_1k)

    nlat_1k = dimsizes(lat_1k)
    nlon_1k = dimsizes(lon_1k)
    LAT = lat_1k
    LON = lon_1k
    LATIXY = latxy_1k
    LONGXY = lonxy_1k
    LANDMASK = mask_1k

    EDGEN = tofloat( (/ max(lat_1k) + ( lat_1k(nlat_1k-1) - lat_1k(nlat_1k-2))/2. /) )
    EDGEN = nameDim(EDGEN,"ncl_scalar", "northern edge of surface grid", "degrees north")

    EDGES = tofloat( (/ min(lat_1k) - ( lat_1k(1) - lat_1k(0))/2. /) )
    EDGES = nameDim(EDGES,"ncl_scalar", "southern edge of surface grid", "degrees north")

    EDGEE = tofloat( (/ max(lon_1k) + ( lon_1k(nlon_1k-1) - lon_1k(nlon_1k-2))/2. /)  )
    EDGEE = nameDim(EDGEE,"ncl_scalar", "eastern edge of surface grid", "degrees east")

    EDGEW = tofloat( (/ min(lon_1k) - ( lon_1k(1) - lon_1k(0))/2. /) )
    EDGEW = nameDim(EDGEW,"ncl_scalar", "western edge of surface grid", "degrees east")

    print("Coordinate: "+EDGES+"-"+EDGEN+", "+EDGEE+"-"+EDGEW)

    ;; 2) monthly LAI, SAI
    lai_1k_m = new((/12,17,dimsizes(lat_1k),dimsizes(lon_1k)/),float)
    lai_1k_m = (/ 0. /)
    sai_1k_m  = lai_1k_m
    topH_1k_m = lai_1k_m
    botH_1k_m = lai_1k_m

    printVarSummary(lulc_1k(0,:,:))
    printVarSummary(lai_1k(0,:,:))

    do ti = 0, 16 ; natural pft
      do mi = 0, 11;
        print(ti+": mon "+mi)
        lai_1k_m(mi,ti,:,:) = tofloat( where(lulc_1k(ti,:,:).eq.1, lai_1k(mi,:,:), 0.) )
        sai_1k_m(mi,ti,:,:) = tofloat( where(lulc_1k(ti,:,:).eq.1, sai_1k(mi,:,:), 0.) )
      end do ;
    end do ; pfts
    delete(lai_1k_m@_FillValue)
    delete(sai_1k_m@_FillValue)
    lai_1k_m = where(lai_1k_m.gt.100 .or.lai_1k_m.lt.0, 0,lai_1k_m)
    sai_1k_m = where(sai_1k_m.gt.100 .or.sai_1k_m.lt.0, 0,sai_1k_m)
    lai_1k_m = nameDim(lai_1k_m,(/"time","pft","lat","lon"/),"monthy LAI for vegetation PFT","")
    sai_1k_m = nameDim(sai_1k_m,(/"time","pft","lat","lon"/),"monthy SAI for vegetation PFT","")
    printVarSummary(lai_1k_m)
    printVarSummary(sai_1k_m)
    ;lai_1k_sum = dim_sum_n_Wrap(lai_1k_m(7,:,:,:),0)

    f2 = addfile("/compyfs/inputdata/lnd/clm2/rawdata/pftlandusedyn.0.5x0.5.simyr1850-2005.c090630/mksrf_lai_global_c090506.nc","r")
    var_sf := getfilevarnames(f2)
    print(var_sf)
    lw_ht_bot = tofloat( f2->MONTHLY_HEIGHT_BOT )
    lw_ht_top = tofloat( f2->MONTHLY_HEIGHT_TOP )

    do ti = 0,16
      topH_1k_m(:,ti,:,:) = (/ lw_ht_top(5,ti,150,250) /)
      botH_1k_m(:,ti,:,:) = (/ lw_ht_bot(5,ti,150,250) /)
    end do
    delete(topH_1k_m@_FillValue)
    delete(botH_1k_m@_FillValue)

    topH_1k_m = where(topH_1k_m.gt.200 .or.topH_1k_m.lt.0, 0,topH_1k_m)
    botH_1k_m = where(botH_1k_m.gt.200 .or.botH_1k_m.lt.0, 0,botH_1k_m)
    topH_1k_m = nameDim(topH_1k_m,(/"time","pft","lat","lon"/),"monthly height top","")
    botH_1k_m = nameDim(botH_1k_m,(/"time","pft","lat","lon"/),"monthly height bot","m")
    printVarSummary(topH_1k_m)
    printVarSummary(botH_1k_m)

    fout = otdir + "mksrf_laisai_1km_icom"+flg_pft+".nc"
    system("/bin/rm -f " + fout)
    print("  Out: " + fout)
    setfileoption("nc","Format","NetCDF4Classic") ; NetCDF4
    fo := addfile(fout, "c")
    fo@creation_data=systemfunc("date")
    fo@information="Lake percentage, Created by Lingcheng LI"
    fo@data_source="MODIS LC5 https://developers.google.com/earth-engine/datasets/catalog/MODIS_006_MCD12Q1"

    fo->LAT = LAT
    fo->LON = LON
    fo->LATIXY = LATIXY
    fo->LONGXY = LONGXY
    fo->EDGEN = EDGEN
    fo->EDGES = EDGES
    fo->EDGEE = EDGEE
    fo->EDGEW = EDGEW
    fo->LANDMASK = LANDMASK
    fo->MONTHLY_LAI = lai_1k_m
    fo->MONTHLY_SAI = sai_1k_m
    fo->MONTHLY_HEIGHT_BOT = botH_1k_m
    fo->MONTHLY_HEIGHT_TOP = topH_1k_m
    exit
  end if

  ;;;;;; 5) topo, ;;;;;;;;
  ;;;;;; update, mksrf_flndtopo ;;;;;;
  if (True) then
    ; 0)input the land mask
    f1 = addfile( otdir + "icom_1km_mask.nc","r")
    mask_1k = f1->mask

    ; 1) input the high data
    f1 = addfile( gedir + "mean_of_Elevation.nc","r")
    var_1k = getfilevarnames(f1)
    print(var_1k)

    lat_1k = f1->lat
    lon_1k = f1->lon
    dem_1k = f1->Band1

    f1 = addfile( gedir + "slope2.nc","r")
    var_1k = getfilevarnames(f1)
    print(var_1k)

    slp_1k = f1->Band1

    latxy_1k = new((/dimsizes(lat_1k),dimsizes(lon_1k)/),double)
    lonxy_1k = new((/dimsizes(lat_1k),dimsizes(lon_1k)/),double)
    do gi = 0, dimsizes(lat_1k)-1
      latxy_1k(gi,:) = lat_1k(gi)
    end do
    do gi = 0, dimsizes(lon_1k)-1
      lonxy_1k(:,gi) = lon_1k(gi)
    end do
    latxy_1k = nameDim(latxy_1k,(/"lat","lon"/), "latitude-2d",  "degrees north")
    lonxy_1k = nameDim(lonxy_1k,(/"lat","lon"/), "longitude-2d", "degrees east" )
    printVarSummary(latxy_1k)
    printVarSummary(lonxy_1k)

    nlat_1k = dimsizes(lat_1k)
    nlon_1k = dimsizes(lon_1k)
    LAT = lat_1k
    LON = lon_1k
    LATIXY = latxy_1k
    LONGXY = lonxy_1k
    LANDMASK  = mask_1k

    EDGEN = (/ max(lat_1k) + ( lat_1k(nlat_1k-1) - lat_1k(nlat_1k-2))/2. /)
    EDGEN = nameDim(EDGEN,"ncl_scalar", "northern edge of surface grid", "degrees north")

    EDGES = (/ min(lat_1k) - ( lat_1k(1) - lat_1k(0))/2. /)
    EDGES = nameDim(EDGES,"ncl_scalar", "southern edge of surface grid", "degrees north")

    EDGEE = (/ max(lon_1k) + ( lon_1k(nlon_1k-1) - lon_1k(nlon_1k-2))/2. /)
    EDGEE = nameDim(EDGEE,"ncl_scalar", "eastern edge of surface grid", "degrees east")

    EDGEW = (/ min(lon_1k) - ( lon_1k(1) - lon_1k(0))/2. /)
    EDGEW = nameDim(EDGEW,"ncl_scalar", "western edge of surface grid", "degrees east")

    dem_1k = nameDim(dem_1k,(/"lat","lon"/),"ground elevation","m")
    printVarSummary(dem_1k)

    slp_1k = nameDim(slp_1k,(/"lat","lon"/),"ground slope","m")
    printVarSummary(slp_1k)

    f2 = addfile("/compyfs/inputdata/lnd/clm2/rawdata/topodata_10min_USGS_071205.nc","r")
    var_sf := getfilevarnames(f2)
    print("********** elevation *********")
    print(var_sf)

    NUMLON = new(dimsizes(LAT),integer)
    NUMLON = dimsizes(LON)
    NUMLON = nameDim(NUMLON,(/"lat"/),"number of grid cells at each latitude","unitless")

    ; flag_topo = 1
    if (True) then
      ;; output the soil organic
      fout = otdir + "mksrf_topo_icom.nc"
      system("/bin/rm -f " + fout)
      print("  Out: " + fout)
      fo := addfile(fout, "c")
      fo@creation_data=systemfunc("date")
      fo@information="SOIL organic carbon density 5hm from soil grid. Created by Lingcheng LI"
      fo@data_source="SoilGrids — global gridded soil information https://www.isric.org/explore/soilgrids"
      fo->LAT = LAT
      fo->LON = LON
      fo->LATIXY = LATIXY
      fo->LONGXY = LONGXY
      ; fo->EDGEN = EDGEN
      ; fo->EDGES = EDGES
      ; fo->EDGEE = EDGEE
      ; fo->EDGEW = EDGEW
      fo->TOPO   = dem_1k
      fo->NUMLON = NUMLON
      fo->ELEVATION = dem_1k
      fo->SLOPE     = slp_1k
      fo->LANDMASK = LANDMASK
    end if

    if (False) then
      ;; output the soil organic
      fout = otdir + "mksrf_ftopostats_1km_icom.nc"
      system("/bin/rm -f " + fout)
      print("  Out: " + fout)
      fo := addfile(fout, "c")
      fo@creation_data=systemfunc("date")
      fo@information="SOIL organic carbon density 5hm from soil grid. Created by Lingcheng LI"
      fo@data_source="SoilGrids — global gridded soil information https://www.isric.org/explore/soilgrids"
      fo->LATITUDE = LAT
      fo->LONGITUDE = LON
      fo->LATIXY = LATIXY
      fo->LONGXY = LONGXY
      fo->EDGEN = EDGEN
      fo->EDGES = EDGES
      fo->EDGEE = EDGEE
      fo->EDGEW = EDGEW
      fo->ELEVATION = dem_1k
      fo->SLOPE     = slp_1k
      fo->LANDMASK = LANDMASK
    end if

  end if

end
