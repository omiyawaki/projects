function read_ahfres(type, par)
% read sea ice depth
    if any(strcmp(type, {'era5', 'erai', 'era5c'})) % only for MPI-ESM-LR
        % dimensions are (lon x lat x time)
        sn = double(ncread(sprintf('/project2/tas1/miyawaki/projects/002/data/raw/%s/sn/%s_sn_%s.ymonmean.nc', type, type, par.(type).yr_span), 'fal'));
        save(sprintf('/project2/tas1/miyawaki/projects/002/data/read/%s/sn.mat', type), 'sn');
    elseif strcmp(type, 'gcm') & strcmp(par.model, 'MPI-ESM-LR') % only for MPI-ESM-LR
        for i=1:length(par.gcm.vars.rad); var = par.gcm.vars.rad{i};
            prefix=sprintf('/project2/tas1/miyawaki/projects/002/data/read/%s/%s', type, par.model);
            file=dir(sprintf('/project2/tas1/echam6/piControl/BOT_piControl_r1i1p1-P_1900_1949.nc'));
            fullpath=sprintf('%s/%s', file.folder, file.name);
            sn=double(ncread(fullpath, 'ahfres'));
            lat=double(ncread(fullpath, 'lat'));
            lon=double(ncread(fullpath, 'lon'));
        end
        load(sprintf('%s/grid.mat', prefix)); % read grid data
        sn = interp1(lon, sn, grid.dim2.lon); % interpolate to MPI-ESM-LR longitude grid
        sn = permute(sn, [2 1 3]); % bring lat to 1st
        sn = interp1(lat, sn, grid.dim2.lat); % interpolate to MPI-ESM-LR latitude grid
        sn = permute(sn, [2 1 3]); % bring lat back to 2nd
        newdir=sprintf('/project2/tas1/miyawaki/projects/002/data/read/gcm/%s', par.model);
        if ~exist(newdir, 'dir'); mkdir(newdir); end
        filename='sn.mat';
        save(sprintf('%s/%s', newdir, filename), 'sn');
    elseif strcmp(type, 'echam')
        if contains(par.echam.clim, 'rp000')
            file=dir(sprintf('/project2/tas1/ockham/data11/tas/echam-aiv_rcc_6.1.00p1/%s/BOT_%s_0020_39.nc', par.echam.clim, par.echam.clim));
        else
            file=dir(sprintf('/project2/tas1/miyawaki/projects/002/data/raw/echam/BOT*_%s_*.ymonmean.nc', par.echam.clim));
        end
        fullpath=sprintf('%s/%s', file.folder, file.name);
        ahfres=double(ncread(fullpath, 'ahfres'));
        newdir=sprintf('/project2/tas1/miyawaki/projects/002/data/read/echam/%s', par.echam.clim);
        if ~exist(newdir, 'dir'); mkdir(newdir); end
        filename='ahfres.mat';
        save(sprintf('%s/%s', newdir, filename), 'ahfres');
    end
end
