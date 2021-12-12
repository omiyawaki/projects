from cl_in import *

####################################
## CMIP5
####################################
# models = ['MPI-ESM-LR']
# sim = 'rcp85'
# yr_span = '200601-230012'
# sim = 'historical'
# yr_span='186001-200512'
# refclim = 'hist-30'

# HISTORICAL RUNS
sim = 'historical'
yr_span = '186001-200512'
refclim = 'hist-30'
# models = ['ACCESS1-0', 'ACCESS1-3', 'bcc-csm1-1', 'bcc-csm1-1-m', 'BNU-ESM', 'CanESM2', 'CCSM4', 'CESM1-BGC', 'CESM1-CAM5', 'CMCC-CESM', 'CMCC-CM', 'CMCC-CMS', 'CNRM-CM5', 'CSIRO-Mk3-6-0', 'FGOALS-g2', 'GFDL-CM3', 'GFDL-ESM2G', 'GFDL-ESM2M', 'GISS-E2-H', 'GISS-E2-H-CC', 'GISS-E2-R', 'GISS-E2-R-CC', 'HadGEM2-CC', 'HadGEM2-ES', 'inmcm4', 'IPSL-CM5A-LR', 'IPSL-CM5A-MR', 'IPSL-CM5B-LR', 'MIROC5', 'MIROC-ESM', 'MIROC-ESM-CHEM', 'MPI-ESM-LR', 'MPI-ESM-MR', 'MRI-CGCM3', 'MRI-ESM1', 'NorESM1-M', 'NorESM1-ME']

# STANDARD RCP8.5 RUNS, OUT TO 2100
# sim = 'rcp85'
# yr_span = '200601-210012'
# refclim = 'hist-30'
# models = ['ACCESS1-0', 'ACCESS1-3', 'bcc-csm1-1', 'bcc-csm1-1-m', 'BNU-ESM', 'CanESM2', 'CCSM4', 'CESM1-BGC', 'CESM1-CAM5', 'CMCC-CESM', 'CMCC-CM', 'CMCC-CMS', 'CNRM-CM5', 'CSIRO-Mk3-6-0', 'FGOALS-g2', 'GFDL-CM3', 'GFDL-ESM2G', 'GFDL-ESM2M', 'GISS-E2-H', 'GISS-E2-H-CC', 'GISS-E2-R', 'GISS-E2-R-CC', 'HadGEM2-CC', 'HadGEM2-ES', 'inmcm4', 'IPSL-CM5A-LR', 'IPSL-CM5A-MR', 'IPSL-CM5B-LR', 'MIROC5', 'MIROC-ESM', 'MIROC-ESM-CHEM', 'MPI-ESM-LR', 'MPI-ESM-MR', 'MRI-CGCM3', 'MRI-ESM1', 'NorESM1-M', 'NorESM1-ME']

# # EXTENDED RCP8.5 RUNS, TO 2300
# yr_span = '200601-229912'
# sim = 'rcp85'
# refclim = 'hist-30'
# models = ['HadGEM2-ES', 'GISS-E2-H', 'GISS-E2-R', 'bcc-csm1-1', 'CCSM4', 'CNRM-CM5', 'CSIRO-Mk3-6-0', 'MPI-ESM-LR', 'IPSL-CM5A-LR']
# models = ['HadGEM2-ES', 'bcc-csm1-1', 'CCSM4', 'CNRM-CM5', 'CSIRO-Mk3-6-0', 'MPI-ESM-LR', 'IPSL-CM5A-LR']
models = ['HadGEM2-ES', 'bcc-csm1-1', 'CNRM-CM5', 'CSIRO-Mk3-6-0', 'MPI-ESM-LR', 'IPSL-CM5A-LR']
# models = ['MPI-ESM-LR']
# models = ['HadGEM2-ES']

####################################
## ERA
####################################
# models = [None]
# sim = 'era5'
# yr_span='1979_2019'
# refclim = 'init'

mmm = 1
annmean = 0
# timemeans = ['djfmean', 'mammean', 'jjamean', 'sonmean']
timemeans = ['ymonmean-30']
latbnd = (80,90)
viewplt = 0
try_load = 0
legend = 1

for timemean in timemeans:
    if mmm:

        cl_in(sim, annmean=annmean, viewplt=viewplt, model=models, yr_span=yr_span, timemean=timemean, refclim=refclim, try_load=try_load, latbnd=latbnd, legend=legend)

    else:
        for model in models:
            print(model)

            cl_in(sim, annmean=annmean, viewplt=viewplt, model=model, yr_span=yr_span, timemean=timemean, refclim=refclim, try_load=try_load, latbnd=latbnd, legend=legend)

