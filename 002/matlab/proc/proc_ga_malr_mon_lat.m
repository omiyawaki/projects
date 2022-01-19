function proc_ga_malr_mon_lat(type, par)

    prefix = make_prefix(type, par);
    prefix_proc = make_prefix_proc(type, par);
    foldername = make_savedir_proc(type, par);

    load(sprintf('%s/grid.mat', prefix)); % read grid data
    load(sprintf('%s/dtdzsi.mat', prefix));
    load(sprintf('%s/malrsi.mat', prefix));

    if strcmp(type, 'gcm')
        if contains(par.model, 'GISS-E2')
            dtdzsi = permute(dtdzsi, [2 1 3 4]);
            dtdzsi = interp1(grid.dim3.lat_zg, dtdzsi, grid.dim3.lat);
            dtdzsi = permute(dtdzsi, [2 1 3 4]);
        end
    end

    ga_diff_orig = dtmdzsi - dtdzsi; % moist adiabatic lapse rate minus actual lapse rate
    
    %load(sprintf('%s/pa_si.mat', prefix)); pasi_orig = pa_si; clear pa_si; % read temp in si coordinates
    load(sprintf('%s/srfc.mat', prefix)); % load surface data
    load(sprintf('%s/masks.mat', prefix_proc)); % load land and ocean masks

    if strcmp(par.lat_interp, 'std')
        lat = par.lat_std;
    else
        lat = grid.dim3.lat;
    end

    % interpolate ta to standard lat grid
    ga_diff_orig = permute(ga_diff_orig, [2 1 3 4]);
    ga_diff_orig = interp1(grid.dim3.lat, ga_diff_orig, lat);
    ga_diff_orig = permute(ga_diff_orig, [2 1 3 4]);

    %pasi_orig = permute(pasi_orig, [2 1 3 4]);
    %pasi_orig = interp1(grid.dim3.lat, pasi_orig, lat);
    %pasi_orig = permute(pasi_orig, [2 1 3 4]);

    ga_diff_sm.lo = ga_diff_orig; % surface is already masked in standard sigma coordinates
    %pasi_sm.lo = pasi_orig; % surface is already masked in spndard sigma coordinates

    ga_diff_sm.lo = permute(ga_diff_sm.lo, [1 2 4 3]); % bring plev to last dimension

    %pasi_sm.lo = permute(pasi_sm.lo, [1 2 4 3]); % bring plev to last dimension

    mask_vert.land = repmat(mask.land, [1 1 1 size(ga_diff_sm.lo, 4)]);
    mask_vert.ocean = repmat(mask.ocean, [1 1 1 size(ga_diff_sm.lo, 4)]);

    ga_diff_sm.l = ga_diff_sm.lo .* mask_vert.ocean;
    ga_diff_sm.o = ga_diff_sm.lo .* mask_vert.land;

    for l = par.land_list; land = l{1}; % over land, over ocean, or both
    % for l = {'lo'}; land = l{1}; % over land, over ocean, or both
        ga_diff.(land)= squeeze(nanmean(ga_diff_sm.(land), 1)); % zonal average
        %pasi.(land)= squeeze(nanmean(pasi_sm.(land), 1)); % zonal average
    end

    for l = par.land_list; land = l{1}; % over land, over ocean, or both
    % for l = {'lo'}; land = l{1}; % over land, over ocean, or both
        % take time averages
        for t = {'ann', 'djf', 'jja', 'mam', 'son'}; time = t{1};
            if strcmp(time, 'ann')
                ga_diff_t.(land).(time) = squeeze(nanmean(ga_diff_sm.(land), 3));
                %pasi_t.(land).(time) = squeeze(nanmean(pasi_sm.(land), 3));
            elseif strcmp(time, 'djf')
                ga_diff_shift.(land) = circshift(ga_diff_sm.(land), 1, 3);
                %pasi_shift.(land) = circshift(pasi_sm.(land), 1, 3);
                ga_diff_t.(land).(time) = squeeze(nanmean(ga_diff_shift.(land)(:,:,1:3,:), 3));
                %pasi_t.(land).(time) = squeeze(nanmean(pasi_shift.(land)(:,:,1:3,:), 3));
            elseif strcmp(time, 'jja')
                ga_diff_t.(land).(time) = squeeze(nanmean(ga_diff_sm.(land)(:,:,6:8,:), 3));
                %pasi_t.(land).(time) = squeeze(nanmean(pasi_sm.(land)(:,:,6:8,:), 3));
            elseif strcmp(time, 'mam')
                ga_diff_t.(land).(time) = squeeze(nanmean(ga_diff_sm.(land)(:,:,3:5,:), 3));
                %pasi_t.(land).(time) = squeeze(nanmean(pasi_sm.(land)(:,:,3:5,:), 3));
            elseif strcmp(time, 'son')
                ga_diff_t.(land).(time) = squeeze(nanmean(ga_diff_sm.(land)(:,:,9:11,:), 3));
                %pasi_t.(land).(time) = squeeze(nanmean(pasi_sm.(land)(:,:,9:11,:), 3));
            end
        end
    end

    % save filtered data
    printname = [foldername 'ga_diff_mon_lat'];
    save(printname, 'ga_diff', 'lat', '-v7.3');
    %if par.do_surf; save(printname, 'ga_diff', 'lat');
    %else save(printname, 'ga_diff', 'pasi', 'lat', '-v7.3'); end

    printname = [foldername 'ga_diff_lon_lat'];
    save(printname, 'ga_diff_t', 'lat', '-v7.3');
    %else save(printname, 'ga_diff_t', 'pasi_t', 'lat', '-v7.3'); end
end % compute mon x lat temperature field
