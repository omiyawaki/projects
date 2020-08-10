clc; clear variables; close all;

addpath(genpath('/project2/tas1/miyawaki/matlab'));

%% set parameters
par.erai.yr_span = '2000_2012'; % spanning years for ERA-Interim
par.era5.yr_span = '1979_2019'; % spanning years for ERA5
par.gcm.yr_span = 30; % number of years that I am considering in the GCM climatology
par.ceres.yr_span = '200003-201302'; % spanning years for ERA5
par.era.vars.rad = {'ssr', 'str', 'tsr', 'ttr'}; % radiation variables to read
par.era.vars.pe = {'cp', 'lsp', 'e'}; % radiation variables to read
par.era.vars.div = {'p85.162', 'p84.162', 'p83.162'}; % radiation variables to read
par.era.vars.div_txt = {'divg', 'divq', 'divt'}; % radiation variables to read
par.era.vars.stf = {'sshf', 'slhf'}; % surface turbulent flux variables to read
par.era.vars.vert = {'t'}; % 3d variables to read (t = temp)
par.era.vars.srfc = {'sp', 't2m', 'd2m'}; % surface variables to read (sp = surface pressure, t2m = 2m temp, d2m = 2m dew point temp)
par.gcm.vars.rad = {'rsus', 'rsds', 'rlus', 'rlds', 'rsdt', 'rsut', 'rlut'}; % radiation variables to read
par.gcm.vars.pe = {'prc', 'pr', 'evspsbl'}; % radiation variables to read
par.gcm.vars.stf = {'hfss', 'hfls'}; % surface turbulent flux variables to read
par.gcm.vars.vert = {'ta', 'va'}; % 3d variables to read
par.gcm.vars.srfc = {'ps', 'ts', 'tas', 'hurs'}; % surface variables to read (sp = surface pressure, t2m = 2m temp, d2m = 2m dew point temp)
par.ceres.vars.rad = {'sfc_net_sw_all_mon', 'sfc_net_lw_all_mon', 'toa_sw_all_mon', 'solar_mon', 'toa_lw_all_mon'}; % radiation variables to read
par.ceres.vars.rad_txt = {'ssr', 'str', 'tsur', 'tsdr', 'ttr'}; % radiation variables to read
gcm_info
% standard z coordinate for interpolation
par.z = [0:500:20e3]';
par.si = linspace(1,1e-2,1e2);
% useful constants
par.cpd = 1005.7; par.Rd = 287; par.L = 2.501e6; par.g = 9.81;

%% call functions
type='era5';
% run_func(type, par);
for k=1:length(par.gcm_models); par.model=par.gcm_models{k};
    type='gcm';
    run_func(type, par);
end

%% define functions
function run_func(type, par)
    % read_grid(type, par) % grid, i.e. lon, lat, plev
    % read_rad(type, par) % radiation fluxes
    % read_pe(type, par) % hydrological variables, e.g. precip, evap
    % read_div(type, par) % divergence terms to calculate MSE flux divergence
    % read_stf(type, par) % surface turbulent fluxes
    % read_srfc(type, par) % other surface variables, e.g. 2-m temperature, surface pressure
    % make_tempz(type, par) % convert temp from plev to z
    make_tempsi(type, par) % convert temp from plev to sigma
end
function read_grid(type, par)
    % read data net SW and LW radiation data downloaded from Era5
    % first read lon and lat vectors since this is different from the Donohoe grid
    if any(strcmp(type, {'era5', 'erai'}))
        grid.dim2.lon = double(ncread(sprintf('/project2/tas1/miyawaki/projects/002/data/raw/%s/rad/%s_rad_%s.ymonmean.nc', type, type, par.(type).yr_span), 'longitude'));
        grid.dim2.lat = double(ncread(sprintf('/project2/tas1/miyawaki/projects/002/data/raw/%s/rad/%s_rad_%s.ymonmean.nc', type, type, par.(type).yr_span), 'latitude'));
        grid.dim3 = grid.dim2;
        grid.dim3.plev = 10^2*double(ncread(sprintf('/project2/tas1/miyawaki/projects/002/data/raw/%s/temp/%s_temp_%s.ymonmean.nc', type, type, par.(type).yr_span), 'level')); % multiply by 100 to convert hPa to Pa
        grid.dim3.z = par.z;
        grid.dim3.si = par.si;
        save(sprintf('/project2/tas1/miyawaki/projects/002/data/read/%s/grid.mat', type), 'grid')
    elseif strcmp(type, 'gcm')
        file.dim2=dir(sprintf('/project2/tas1/miyawaki/projects/002/data/raw/gcm/%s/%s_Amon_%s_piControl_r1i1p1_*.nc', par.model, 'tas', par.model));
        file.dim3=dir(sprintf('/project2/tas1/miyawaki/projects/002/data/raw/gcm/%s/%s_Amon_%s_piControl_r1i1p1_*.nc', par.model, 'ta', par.model));
        fullpath.dim2=sprintf('%s/%s', file.dim2.folder, file.dim2.name);
        fullpath.dim3=sprintf('%s/%s', file.dim3.folder, file.dim3.name);
        grid.dim2.lon=ncread(fullpath.dim2, 'lon');
        grid.dim3.lon=ncread(fullpath.dim3, 'lon');
        grid.dim2.lat=ncread(fullpath.dim2, 'lat');
        grid.dim3.lat=ncread(fullpath.dim3, 'lat');
        grid.dim3.plev=ncread(fullpath.dim3, 'plev');
        grid.dim3.z = par.z;
        grid.dim3.si = par.si;
        newdir=sprintf('/project2/tas1/miyawaki/projects/002/data/read/gcm/%s', par.model);
        if ~exist(newdir, 'dir'); mkdir(newdir); end
        filename='grid.mat';
        save(sprintf('%s/%s', newdir, filename), 'grid');
    elseif strcmp(type, 'ceres')
        grid.dim2.lon = double(ncread(sprintf('/project2/tas1/miyawaki/projects/002/data/raw/%s/CERES_EBAF_Ed4.1_Subset_%s.ymonmean.nc', type, par.(type).yr_span), 'lon'));
        grid.dim2.lat = double(ncread(sprintf('/project2/tas1/miyawaki/projects/002/data/raw/%s/CERES_EBAF_Ed4.1_Subset_%s.ymonmean.nc', type, par.(type).yr_span), 'lat'));
        save(sprintf('/project2/tas1/miyawaki/projects/002/data/read/%s/grid.mat', type), 'grid')
    end

    % save grid
end
function read_rad(type, par)
    if strcmp(type, 'erai') | strcmp(type, 'era5')
        rad_vars=par.era.vars.rad;
        for i=1:length(rad_vars)
            % dimensions are (lon x lat x time)
            % time is sequenced as id(1) = jan, step 00-12, id(2) = jan, step 12-24, id(3) = feb, step 00-12, etc.
            rad.(rad_vars{i}) = double(ncread(sprintf('/project2/tas1/miyawaki/projects/002/data/raw/%s/rad/%s_rad_%s.ymonmean.nc', type, type, par.(type).yr_span), rad_vars{i}));
            % the data is originally reported as J m^-2 per day, so
            % divide by 86400 s to get the conventional W m^-2 flux
            % over the full day
            rad.(rad_vars{i}) = rad.(rad_vars{i})/86400;
        end
        save(sprintf('/project2/tas1/miyawaki/projects/002/data/read/%s/rad.mat', type), 'rad', 'rad_vars');
        if strcmp(type, 'era5')
            for i=1:length(rad_vars)
                rad.(rad_vars{i}) = ncread(sprintf('/project2/tas1/miyawaki/projects/002/data/raw/%s/rad/%s_rad_%s.ymonmean.nc', type, type, par.erai.yr_span), rad_vars{i});
                rad.(rad_vars{i}) = rad.(rad_vars{i})/86400;
            end
            save(sprintf('/project2/tas1/miyawaki/projects/002/data/read/%s/rad_2000_2012.mat', type), 'rad', 'rad_vars');
        end
    elseif strcmp(type, 'gcm')
        rad_vars=par.gcm.vars.rad;
        for i=1:length(par.gcm.vars.rad); var = par.gcm.vars.rad{i};
            file=dir(sprintf('/project2/tas1/miyawaki/projects/002/data/raw/gcm/%s/%s_Amon_%s_piControl_r1i1p1_*.ymonmean.nc', par.model, var, par.model));
            fullpath=sprintf('%s/%s', file.folder, file.name);
            rad.(var)=ncread(fullpath, var);
        end
        newdir=sprintf('/project2/tas1/miyawaki/projects/002/data/read/gcm/%s', par.model);
        if ~exist(newdir, 'dir'); mkdir(newdir); end
        filename='rad.mat';
        save(sprintf('%s/%s', newdir, filename), 'rad', 'rad_vars');
    elseif strcmp(type, 'ceres')
        rad_vars = par.ceres.vars.rad;
        rad_vars_txt = par.ceres.vars.rad_txt;
        for i=1:length(rad_vars)
            rad.(rad_vars_txt{i}) = double(ncread(sprintf('/project2/tas1/miyawaki/projects/002/data/raw/%s/CERES_EBAF_Ed4.1_Subset_%s.ymonmean.nc', type, par.(type).yr_span), rad_vars{i}));
        end
        save(sprintf('/project2/tas1/miyawaki/projects/002/data/read/%s/rad.mat', type), 'rad');

        for i=1:length(rad_vars)
            rad.(rad_vars_txt{i}) = double(ncread(sprintf('/project2/tas1/miyawaki/projects/002/data/raw/%s/CERES_EBAF_Ed4.1_Subset_200101-200912.ymonmean.nc', type), rad_vars{i}));
        end
        save(sprintf('/project2/tas1/miyawaki/projects/002/data/read/%s/rad_2001_2009.mat', type), 'rad');
    end
end
function read_pe(type, par)
    if strcmp(type, 'era5') | strcmp(type, 'erai')
        pe_vars=par.era.vars.pe;
        for i=1:length(pe_vars)
            % dimensions are (lon x lat x time)
            pe.(pe_vars{i}) = double(ncread(sprintf('/project2/tas1/miyawaki/projects/002/data/raw/%s/pe/%s_pe_%s.ymonmean.nc', type, type, par.(type).yr_span), pe_vars{i}));
            % the data is originally reported as m (depth) per day, so
            % divide by 86400 s and multiply by 1000 kg/m^3 to get the
            % conventional kg/m^2/s mass flux over the full day
            pe.(pe_vars{i}) = pe.(pe_vars{i})/86400*1e3;
        end
        save(sprintf('/project2/tas1/miyawaki/projects/002/data/read/%s/pe.mat', type), 'pe', 'pe_vars');

    elseif strcmp(type, 'gcm')
        pe_vars=par.gcm.vars.pe;
        for i=1:length(par.gcm.vars.pe); var = par.gcm.vars.pe{i};
            file=dir(sprintf('/project2/tas1/miyawaki/projects/002/data/raw/gcm/%s/%s_Amon_%s_piControl_r1i1p1_*.ymonmean.nc', par.model, var, par.model));
            fullpath=sprintf('%s/%s', file.folder, file.name);
            pe.(var)=ncread(fullpath, var);
        end
        newdir=sprintf('/project2/tas1/miyawaki/projects/002/data/read/gcm/%s', par.model);
        if ~exist(newdir, 'dir'); mkdir(newdir); end
        filename='pe.mat';
        save(sprintf('%s/%s', newdir, filename), 'pe', 'pe_vars');
    end
end
function read_div(type, par)
    if strcmp(type, 'era5')
        div_vars=par.era.vars.div;
        div_vars_txt=par.era.vars.div_txt;
        for i=1:length(div_vars)
            % dimensions are (lon x lat x time)
            div.(div_vars_txt{i}) = double(ncread(sprintf('/project2/tas1/miyawaki/projects/002/data/raw/%s/div/%s_div_%s.ymonmean.nc', type, type, par.(type).yr_span), div_vars{i}));
            div.(div_vars_txt{i}) = div.(div_vars_txt{i});
        end
        save(sprintf('/project2/tas1/miyawaki/projects/002/data/read/%s/div.mat', type), 'div', 'div_vars');

    else
        error('Divergence data are only available for ERA5.');
    end
end
function read_stf(type, par)
    if strcmp(type, 'era5') | strcmp(type, 'erai')
        stf_vars=par.era.vars.stf;
        for i=1:length(stf_vars)
            % dimensions are (lon x lat x time)
            stf.(stf_vars{i}) = double(ncread(sprintf('/project2/tas1/miyawaki/projects/002/data/raw/%s/stf/%s_stf_%s.ymonmean.nc', type, type, par.(type).yr_span), stf_vars{i}));
            % the data is originally reported as J m^-2 per day, so
            % divide by 86400 s to get the conventional W m^-2 flux
            % over the full day
            stf.(stf_vars{i}) = stf.(stf_vars{i})/86400;
        end
        save(sprintf('/project2/tas1/miyawaki/projects/002/data/read/%s/stf.mat', type), 'stf', 'stf_vars');

        if strcmp(type, 'era5')
            for i=1:length(stf_vars)
                stf.(stf_vars{i}) = ncread(sprintf('/project2/tas1/miyawaki/projects/002/data/raw/%s/stf/%s_stf_%s.ymonmean.nc', type, type, par.erai.yr_span), stf_vars{i});
                stf.(stf_vars{i}) = stf.(stf_vars{i})/86400;
            end
            save(sprintf('/project2/tas1/miyawaki/projects/002/data/read/%s/stf_2000_2012.mat', type), 'stf', 'stf_vars');
        end
    elseif strcmp(type, 'gcm')
        stf_vars=par.gcm.vars.stf;
        for i=1:length(par.gcm.vars.stf); var = par.gcm.vars.stf{i};
            file=dir(sprintf('/project2/tas1/miyawaki/projects/002/data/raw/gcm/%s/%s_Amon_%s_piControl_r1i1p1_*.ymonmean.nc', par.model, var, par.model));
            fullpath=sprintf('%s/%s', file.folder, file.name);
            stf.(var)=ncread(fullpath, var);
        end
        newdir=sprintf('/project2/tas1/miyawaki/projects/002/data/read/gcm/%s', par.model);
        if ~exist(newdir, 'dir'); mkdir(newdir); end
        filename='stf.mat';
        save(sprintf('%s/%s', newdir, filename), 'stf', 'stf_vars');
    end
end
function read_srfc(type, par)
    if strcmp(type, 'era5') | strcmp(type, 'erai')
        srfc_vars=par.era.vars.srfc;
        for i=1:length(srfc_vars); var = srfc_vars{i};
            % dimensions are (lat x time); note that the data is already zonally averaged
            srfc.(var) = double(squeeze(ncread(sprintf('/project2/tas1/miyawaki/projects/002/data/raw/%s/srfc/%s_srfc_%s.ymonmean.nc', type, type, par.(type).yr_span), srfc_vars{i})));

            if strcmp(var, 'sp'); % create surface geopotential height using surface pressure data
                prefix=sprintf('/project2/tas1/miyawaki/projects/002/data/read/%s', type);
                load(sprintf('%s/grid.mat', prefix)); % read grid data
                file=dir(sprintf('/project2/tas1/miyawaki/projects/002/data/raw/%s/zg/%s_zg_%s.ymonmean.nc', type, type, par.(type).yr_span));
                fullpath=sprintf('%s/%s', file.folder, file.name);
                zg = ncread(fullpath, 'z');
                zg = permute(zg, [3 1 2 4]);
                pb=CmdLineProgressBar("Calculating zs..."); % track progress of this loop
                for lo = 1:length(grid.dim2.lon)
                    pb.print(lo, length(grid.dim2.lon));
                    for la = 1:length(grid.dim2.lat)
                        for mo = 1:12
                            srfc.zs(lo,la,mo) = interp1(grid.dim3.plev, zg(:,lo,la,mo), srfc.sp(lo,la,mo), 'linear', 'extrap');
                        end
                    end
                end
            end

        end
        save(sprintf('/project2/tas1/miyawaki/projects/002/data/read/%s/srfc.mat', type), 'srfc', 'srfc_vars');

    elseif strcmp(type, 'gcm')
        srfc_vars=par.gcm.vars.srfc;
        for i=1:length(par.gcm.vars.srfc); var = par.gcm.vars.srfc{i};
            file=dir(sprintf('/project2/tas1/miyawaki/projects/002/data/raw/gcm/%s/%s_Amon_%s_piControl_r1i1p1_*.ymonmean.nc', par.model, var, par.model));
            fullpath=sprintf('%s/%s', file.folder, file.name);
            if ~exist(fullpath)
                if strcmp(var, 'hurs')
                    file=dir(sprintf('/project2/tas1/miyawaki/projects/002/data/raw/gcm/%s/%s_Amon_%s_piControl_r1i1p1_*.nc', par.model, 'hur', par.model));
                    fullpath=sprintf('%s/%s', file.folder, file.name);
                    hur=ncread(fullpath, 'hur');
                    load(sprintf('/project2/tas1/miyawaki/projects/002/data/read/gcm/%s/grid.mat', par.model));
                    if ~isequal(grid.dim2.lon, grid.dim3.lon); hur=interp1(grid.dim3.lon, hur, grid.dim2.lon); end; % interpolate to 2D lon if different from 3D
                    hur=permute(hur, [2 1 3 4]); % bring lat to first dim
                    if ~isequal(grid.dim2.lat, grid.dim3.lat); hur=interp1(grid.dim3.lat, hur, grid.dim2.lat); end;
                    hur=permute(hur, [3 2 1 4]); % bring plev to first dim
                    pb=CmdLineProgressBar("Calculating hurs..."); % track progress of this loop
                    for id_lon=1:length(grid.dim2.lon)
                        pb.print(id_lon, length(grid.dim2.lon));
                        for id_lat=1:length(grid.dim2.lat)
                            for id_time=1:size(srfc.ps, 3)
                                srfc.hurs(id_lon, id_lat, id_time)=interp1(grid.dim3.plev, hur(:,id_lon,id_lat,id_time), srfc.ps(id_lon, id_lat, id_time), 'linear', 'extrap');
                            end
                        end
                    end
                else
                    error(sprintf('The file for variable %s does not exist. Check in the raw data folder to see if you forgot to download the file.'))
                end
            else
                srfc.(var)=ncread(fullpath, var);

                if strcmp(var, 'ps'); % create surface geopotential height using surface pressure data
                    prefix=sprintf('/project2/tas1/miyawaki/projects/002/data/read/%s/%s', type, par.model);
                    load(sprintf('%s/grid.mat', prefix)); % read grid data
                    file=dir(sprintf('/project2/tas1/miyawaki/projects/002/data/raw/gcm/%s/%s_Amon_%s_piControl_r1i1p1_*.ymonmean.nc', par.model, 'zg', par.model));
                    fullpath=sprintf('%s/%s', file.folder, file.name);
                    zg = ncread(fullpath, 'zg');
                    zg = permute(zg, [3 1 2 4]);
                    pb=CmdLineProgressBar("Calculating zs..."); % track progress of this loop
                    for lo = 1:length(grid.dim2.lon)
                        pb.print(lo, length(grid.dim2.lon));
                        for la = 1:length(grid.dim2.lat)
                            for mo = 1:12
                                srfc.zs(lo,la,mo) = interp1(grid.dim3.plev, zg(:,lo,la,mo), srfc.ps(lo,la,mo), 'linear', 'extrap');
                            end
                        end
                    end
                end

            end
        end
        newdir=sprintf('/project2/tas1/miyawaki/projects/002/data/read/gcm/%s', par.model);
        if ~exist(newdir, 'dir'); mkdir(newdir); end
        filename='srfc.mat';
        save(sprintf('%s/%s', newdir, filename), 'srfc', 'srfc_vars');
    end
end
function make_tempz(type, par)
    if any(strcmp(type, {'era5', 'erai'}))
        prefix=sprintf('/project2/tas1/miyawaki/projects/002/data/read/%s', type);
        prefix_proc=sprintf('/project2/tas1/miyawaki/projects/002/data/proc/%s', type);
        file=dir(sprintf('/project2/tas1/miyawaki/projects/002/data/raw/%s/temp/%s_temp_%s.ymonmean.nc', type, type, par.(type).yr_span));
        fullpath=sprintf('%s/%s', file.folder, file.name);
        temp = ncread(fullpath, 't');
        file=dir(sprintf('/project2/tas1/miyawaki/projects/002/data/raw/%s/zg/%s_zg_%s.ymonmean.nc', type, type, par.(type).yr_span));
        fullpath=sprintf('%s/%s', file.folder, file.name);
        zg = ncread(fullpath, 'z');
    elseif strcmp(type, 'gcm')
        prefix=sprintf('/project2/tas1/miyawaki/projects/002/data/read/%s/%s', type, par.model);
        prefix_proc=sprintf('/project2/tas1/miyawaki/projects/002/data/proc/%s/%s', type, par.model);
        var = 'ta';
        file=dir(sprintf('/project2/tas1/miyawaki/projects/002/data/raw/gcm/%s/%s_Amon_%s_piControl_r1i1p1_*.ymonmean.nc', par.model, var, par.model));
        fullpath=sprintf('%s/%s', file.folder, file.name);
        temp = ncread(fullpath, var);
        var = 'zg';
        file=dir(sprintf('/project2/tas1/miyawaki/projects/002/data/raw/gcm/%s/%s_Amon_%s_piControl_r1i1p1_*.ymonmean.nc', par.model, var, par.model));
        fullpath=sprintf('%s/%s', file.folder, file.name);
        zg = ncread(fullpath, var);
    end

    load(sprintf('%s/grid.mat', prefix)); % read grid data

    temp = permute(temp, [3 1 2 4]);
    zg = permute(zg, [3 1 2 4]);

    pb=CmdLineProgressBar("Calculating tempz..."); % track progress of this loop
    for lo = 1:length(grid.dim3.lon)
        pb.print(lo, length(grid.dim3.lon));
        for la = 1:length(grid.dim3.lat)
            for mo = 1:12
                tempz(:,lo,la,mo) = interp1(zg(:,lo,la,mo), temp(:,lo,la,mo), grid.dim3.z);
            end
        end
    end

    tempz = permute(tempz, [2 3 1 4]); % reorder to lon x lat x z x mon

    if any(strcmp(type, {'era5', 'erai'})); newdir=sprintf('/project2/tas1/miyawaki/projects/002/data/read/%s', type);
    elseif strcmp(type, 'gcm'); newdir=sprintf('/project2/tas1/miyawaki/projects/002/data/read/gcm/%s', par.model); end;
    if ~exist(newdir, 'dir'); mkdir(newdir); end
    filename='tempz.mat';
    save(sprintf('%s/%s', newdir, filename), 'tempz', '-v7.3');
end
function make_tempsi(type, par)
    if any(strcmp(type, {'era5', 'erai'}))
        prefix=sprintf('/project2/tas1/miyawaki/projects/002/data/read/%s', type);
        prefix_proc=sprintf('/project2/tas1/miyawaki/projects/002/data/proc/%s', type);
        file=dir(sprintf('/project2/tas1/miyawaki/projects/002/data/raw/%s/temp/%s_temp_%s.ymonmean.nc', type, type, par.(type).yr_span));
        fullpath=sprintf('%s/%s', file.folder, file.name);
        ta_orig = ncread(fullpath, 't');
    elseif strcmp(type, 'gcm')
        prefix=sprintf('/project2/tas1/miyawaki/projects/002/data/read/%s/%s', type, par.model);
        prefix_proc=sprintf('/project2/tas1/miyawaki/projects/002/data/proc/%s/%s', type, par.model);
        var = 'ta';
        file=dir(sprintf('/project2/tas1/miyawaki/projects/002/data/raw/gcm/%s/%s_Amon_%s_piControl_r1i1p1_*.ymonmean.nc', par.model, var, par.model));
        fullpath=sprintf('%s/%s', file.folder, file.name);
        ta_orig = ncread(fullpath, var);
    end

    load(sprintf('%s/grid.mat', prefix)); % read grid data
    load(sprintf('%s/srfc.mat', prefix)); % load surface data

    % create surface mask
    if strcmp(type, 'era5') | strcmp(type, 'erai')
        ps_vert = repmat(srfc.ps, [1 1 1 size(ta_orig, 3)]); % dims (lon x lat x time x plev)
        ps_vert = permute(ps_vert, [1 2 4 3]); % dims (lon x lat x plev x time)
        pa = double(permute(repmat(grid.dim3.plev, [1 size(srfc.ps)]), [2 3 1 4]));
    elseif strcmp(type, 'gcm')
        ps_vert = repmat(srfc.ps, [1 1 1 size(ta_orig, 3)]); % dims (lon x lat x time x plev)
        ps_vert = permute(ps_vert, [1 2 4 3]); % dims (lon x lat x plev x time)
        pa = permute(repmat(grid.dim3.plev, [1 size(srfc.ps)]), [2 3 1 4]);
    end
    sm = nan(size(ta_orig));
    sm(pa < ps_vert) = 1;
    ta_sm = ta_orig.*sm; % filter ta with surface mask

    % add tsurf data and interpolate to higher resolution vertical grid
    [pa_plus ta_plus] = deal(nan([size(pa,1), size(pa,2) size(pa,3)+1 size(pa,4)])); % create empty grid with one extra vertical level
    pa_plus(:,:,1:end-1,:) = pa; % populate with standard pressure grid
    ta_plus(:,:,1:end-1,:) = ta_sm; % populate with standard atmospheric temperature
    pa_plus(:,:,end,:) = ps_vert(:,:,1,:); % add surface pressure data into standard pressure grid
    ta_plus(:,:,end,:) = srfc.ts(:,:,:); % add surface temperature data
    pa_plus = permute(pa_plus, [3 1 2 4]); % bring plev dimension to front
    ta_plus = permute(ta_plus, [3 1 2 4]); % bring plev dimension to front
    [pa_plus sort_index] = sort(pa_plus, 1, 'descend'); % sort added surface pressure such that pressure decreases monotonically
    tai_sm = nan(length(par.si), size(pa, 1), size(pa, 2), size(pa, 4));
    pb = CmdLineProgressBar("Sorting and interpolating temperature to new standard grid...");
    for lo=1:size(pa_plus,2)
        pb.print(lo, size(pa_plus,2));
        for la=1:size(pa_plus,3)
            for mo=1:size(pa_plus,4)
                ta_plus(:,lo,la,mo) = ta_plus(sort_index(:,lo,la,mo),lo,la,mo); % sort temperature (has to be in loop because sort_index works for vector calls only)
                tempsi(:,lo,la,mo) = interp1(pa_plus(:,lo,la,mo)/ps_vert(lo,la,1,mo), ta_plus(:,lo,la,mo), grid.dim3.si);
            end
        end
    end
    clear pa_plus ta_plus; % clear unneeded variables

    tempsi = permute(tempsi, [2 3 1 4]); % reorder to lon x lat x si x mon

    if any(strcmp(type, {'era5', 'erai'})); newdir=sprintf('/project2/tas1/miyawaki/projects/002/data/read/%s', type);
    elseif strcmp(type, 'gcm'); newdir=sprintf('/project2/tas1/miyawaki/projects/002/data/read/gcm/%s', par.model); end;
    if ~exist(newdir, 'dir'); mkdir(newdir); end
    filename='tempsi.mat';
    save(sprintf('%s/%s', newdir, filename), 'tempsi', '-v7.3');
end
