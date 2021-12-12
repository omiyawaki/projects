import sys
import os
sys.path.append('/project2/tas1/miyawaki/projects/003/scripts')
from misc.translate import translate_varname
from misc.dirnames import get_datadir
from misc.filenames import *
from misc import par
import numpy as np
import pickle
from netCDF4 import Dataset

def save_r1(sim, **kwargs):
    # computes R1
    # sim is the name of the simulation, e.g. rcp85

    model = kwargs.get('model') # name of model
    zonmean = kwargs.get('zonmean', 'zonmean') # do zonal mean? (bool)
    timemean = kwargs.get('timemean', 'yearmean') # do annual mean? (bool)
    yr_span = kwargs.get('yr_span') # considered span of years
    refclim = kwargs.get('refclim', 'hist-30') # reference climate from which to compute deviations (init is first time step, hist-30 is the last 30 years of the historical run)
    try_load = kwargs.get('try_load', 1)

    # directory to save pickled data
    datadir = get_datadir(sim, model=model, yr_span=yr_span)

    # initialize dictionaries
    file = {}
    grid = {}
    flux = {}

    # counter so grid is only loaded once
    loaded_grid = 0

    # variable names
    if sim == 'echam':
        varnames = ['trad0', 'srad0', 'trads', 'srads', 'ahfl', 'ahfs']
    elif sim == 'era5':
        varnames = ['ssr', 'str', 'tsr', 'ttr', 'slhf', 'sshf', 'cp', 'lsp']
    else:
        varnames = ['rlut', 'rsdt', 'rsut', 'rsus', 'rsds', 'rlds', 'rlus', 'hfls', 'hfss', 'pr']

    # load all variables required to compute R1
    for varname in varnames:
        file[varname] = filenames_raw(sim, varname, model=model, timemean=timemean, yr_span=yr_span)

        if loaded_grid == 0:
            grid = {}
            grid['lat'] = file[varname].variables['lat'][:]
            grid['lon'] = file[varname].variables['lon'][:]
            loaded_grid = 1

        flux[translate_varname(varname)] = np.squeeze(file[varname].variables[varname][:])
        if sim == 'era5':
            flux[translate_varname(varname)] = flux[translate_varname(varname)]/86400

    if sim == 'era5' or sim == 'echam':
        flux['ra'] = flux['trad0'] + flux['srad0'] - flux['trads'] - flux['srads'] 
        flux['hfls'] = -flux['hfls']
        flux['hfss'] = -flux['hfss']
        flux['pr'] = flux['prc'] + flux['prl']
    else:
        flux['ra'] = flux['rsdt'] - flux['rsut'] - flux['rlut'] + flux['rsus'] - flux['rsds'] + flux['rlus'] - flux['rlds']

    flux['stg_adv'] = flux['ra'] + flux['hfls'] + flux['hfss']
    flux['stg_adv_dse'] = flux['ra'] + par.Lv*flux['pr'] + flux['hfss']

    if zonmean:
        for fluxname in flux:
            flux[fluxname] = np.mean(flux[fluxname], 2)

    r1 = flux['stg_adv']/flux['ra']
    stg_adv = flux['stg_adv']
    ra = flux['ra']
    
    # linearly decompose r1 seasonality
    r1_dc = {}

    if refclim == 'init':
        r1_dc['dr1'] = r1 - r1[0,...] # r1 deviation from first year
        ra_tavg = ra[0,...]
        stg_adv_tavg = stg_adv[0,...]
    elif refclim == 'hist-30':
        sim_ref='historical'
        timemean_ref='ymonmean-30'
        yr_span_ref='186001-200512'

        datadir_ref = get_datadir(sim_ref, model=model, yr_span=yr_span_ref)

        # location of pickled historical R1 data
        r1_file_ref = remove_repdots('%s/r1.%s.%s.pickle' % (datadir_ref, zonmean, timemean_ref))
        ra_file_ref = remove_repdots('%s/ra.%s.%s.pickle' % (datadir_ref, zonmean, timemean_ref))
        stg_adv_file_ref = remove_repdots('%s/stg_adv.%s.%s.pickle' % (datadir_ref, zonmean, timemean_ref))

        if not (os.path.isfile(r1_file_ref) and try_load):
            save_r1(sim_ref, model=model, zonmean=zonmean, timemean=timemean_ref, yr_span=yr_span_ref, refclim='init')

        [r1_ref, grid_ref] = pickle.load(open(r1_file_ref, 'rb'))
        [ra_ref, _] = pickle.load(open(ra_file_ref, 'rb'))
        [stg_adv_ref, _] = pickle.load(open(stg_adv_file_ref, 'rb'))
        
        if timemean == 'djfmean':
            r1_ref = np.mean(np.roll(r1_ref,1,axis=0)[0:3], 0)
            ra_ref = np.mean(np.roll(ra_ref,1,axis=0)[0:3], 0)
            stg_adv_ref = np.mean(np.roll(stg_adv_ref,1,axis=0)[0:3], 0)
        elif timemean == 'mammean':
            r1_ref = np.mean(r1_ref[2:5], 0)
            ra_ref = np.mean(ra_ref[2:5], 0)
            stg_adv_ref = np.mean(stg_adv_ref[2:5], 0)
        elif timemean == 'jjamean':
            r1_ref = np.mean(r1_ref[5:8], 0)
            ra_ref = np.mean(ra_ref[5:8], 0)
            stg_adv_ref = np.mean(stg_adv_ref[5:8], 0)
        elif timemean == 'sonmean':
            r1_ref = np.mean(r1_ref[8:11], 0)
            ra_ref = np.mean(ra_ref[8:11], 0)
            stg_adv_ref = np.mean(stg_adv_ref[8:11], 0)

        r1_dc['dr1'] = r1 - r1_ref # r1 deviation from first year
        ra_tavg = ra_ref
        stg_adv_tavg = stg_adv_ref

    r1_dc['dyn'] = (stg_adv - stg_adv_tavg) / ra_tavg # dynamic component
    r1_dc['rad'] = - stg_adv_tavg / (ra_tavg**2) * (ra - ra_tavg) # radiative component
    r1_dc['res'] = r1_dc['dr1'] - ( r1_dc['dyn'] + r1_dc['rad'] )

    pickle.dump([r1, grid], open(remove_repdots('%s/r1.%s.%s.pickle' % (datadir, zonmean, timemean)), 'wb'))
    pickle.dump([r1_dc, grid], open(remove_repdots('%s/r1_dc.%s.%s.pickle' % (datadir, zonmean, timemean)), 'wb'))
    pickle.dump([ra, grid], open(remove_repdots('%s/ra.%s.%s.pickle' % (datadir, zonmean, timemean)), 'wb'))
    pickle.dump([stg_adv, grid], open(remove_repdots('%s/stg_adv.%s.%s.pickle' % (datadir, zonmean, timemean)), 'wb'))
    pickle.dump([flux, grid], open(remove_repdots('%s/flux.%s.%s.pickle' % (datadir, zonmean, timemean)), 'wb'))

    rlut = None; rsdt = None; rsut = None; rsus = None; rsds = None; rlds = None; rlus = None;
