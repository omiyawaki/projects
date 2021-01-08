function proc_ma_si(type, par)
% calculate moist adiabats
    % if strcmp(type, 'era5') | strcmp(type, 'erai') | strcmp(type, 'era5c')
    %     foldername = sprintf('/project2/tas1/miyawaki/projects/002/data/proc/%s/%s/eps_%g_ga_%g/', type, par.lat_interp, par.ep, par.ga);
    %     prefix=sprintf('/project2/tas1/miyawaki/projects/002/data/read/%s/%s', type, par.(type).yr_span);
    %     prefix_proc=sprintf('/project2/tas1/miyawaki/projects/002/data/proc/%s/%s', type, par.(type).yr_span);
    % elseif strcmp(type, 'merra2')
    %     foldername = sprintf('/project2/tas1/miyawaki/projects/002/data/proc/%s/%s/eps_%g_ga_%g/', type, par.lat_interp, par.ep, par.ga);
    %     prefix=sprintf('/project2/tas1/miyawaki/projects/002/data/read/%s/%s', type, par.(type).yr_span);
    %     prefix_proc=sprintf('/project2/tas1/miyawaki/projects/002/data/proc/%s/%s', type, par.(type).yr_span);
    % elseif strcmp(type, 'gcm')
    %     foldername = sprintf('/project2/tas1/miyawaki/projects/002/data/proc/%s/%s/%s/%s/eps_%g_ga_%g/', type, par.model, par.gcm.clim, par.lat_interp, par.ep, par.ga);
    %     prefix=sprintf('/project2/tas1/miyawaki/projects/002/data/read/%s/%s/%s', type, par.model, par.gcm.clim);
    %     prefix_proc=sprintf('/project2/tas1/miyawaki/projects/002/data/proc/%s/%s/%s', type, par.model, par.gcm.clim);
    % elseif strcmp(type, 'echam')
    %     foldername = sprintf('/project2/tas1/miyawaki/projects/002/data/proc/%s/%s/%s/eps_%g_ga_%g/', type, par.echam.clim, par.lat_interp, par.ep, par.ga);
    %     prefix=sprintf('/project2/tas1/miyawaki/projects/002/data/read/%s/%s', type, par.echam.clim);
    %     prefix_proc=sprintf('/project2/tas1/miyawaki/projects/002/data/proc/%s/%s/%s', type, par.echam.clim);
    % end

    foldername = make_savedir_proc_ep(type, par);
    prefix = make_prefix(type, par);
    prefix_proc = make_prefix_proc(type, par);

    load(sprintf('%s/grid.mat', prefix)); % read grid data
    load(sprintf('%s/srfc.mat', prefix)); % read surface variable data
    % load(sprintf('%s/%s/masks.mat', prefix_proc, par.lat_interp)); % load land and ocean masks
    load(sprintf('%s/eps_%g_ga_%g/rcae_alt_t.mat', prefix_proc, par.ep, par.ga)); % load rcae data

    if strcmp(par.lat_interp, 'std')
        lat = par.lat_std;
    else
        lat = grid.dim3.lat;
    end

    for fn = fieldnames(srfc)'
        srfc.(fn{1}) = permute(srfc.(fn{1}), [2 1 3]); % bring lat to front
        srfc.(fn{1}) = interp1(grid.dim2.lat, srfc.(fn{1}), lat); % interpolate to standard grid
        srfc.(fn{1}) = permute(srfc.(fn{1}), [2 1 3]); % reorder to original dims
        % for l = {'lo', 'l', 'o'}; land = l{1};
        for l = {'lo'}; land = l{1};
            if strcmp(land, 'lo'); srfc_n.(fn{1}).(land) = srfc.(fn{1});
            % elseif strcmp(land, 'l'); srfc_n.(fn{1}).(land) = srfc.(fn{1}).*mask.ocean; % filter out ocean
            % elseif strcmp(land, 'o'); srfc_n.(fn{1}).(land) = srfc.(fn{1}).*mask.land; % filter out land
            end
        end
    end

    f_vec = assign_fw(type, par);
    for f = f_vec; fw = f{1};
        for c = fieldnames(rcae_alt_t.lo.ann.(fw))'; crit = c{1};
            % for l = {'lo', 'l', 'o'}; land = l{1};
            for l = {'lo'}; land = l{1};
                % for t = {'ann', 'djf', 'jja', 'mam', 'son'}; time = t{1};
                for t = {'ann'}; time = t{1};
                    for re = {'rce', 'rae', 'rcae'}; regime = re{1};
                        for v = fieldnames(srfc)'; vname = v{1};
                            if strcmp(time, 'ann')
                                srfc_t.(land).(time).(vname) = squeeze(nanmean(srfc_n.(vname).(land), 3));
                            elseif strcmp(time, 'djf')
                                srfc_shift = circshift(srfc_n.(vname).(land), 1, 3);
                                srfc_t.(land).(time).(vname) = squeeze(nanmean(srfc_shift(:,:,1:3), 3));
                            elseif strcmp(time, 'jja')
                                srfc_t.(land).(time).(vname) = squeeze(nanmean(srfc_n.(vname).(land)(:,:,6:8), 3));
                            elseif strcmp(time, 'mam')
                                srfc_t.(land).(time).(vname) = squeeze(nanmean(srfc_n.(vname).(land)(:,:,3:5), 3));
                            elseif strcmp(time, 'son')
                                srfc_t.(land).(time).(vname) = squeeze(nanmean(srfc_n.(vname).(land)(:,:,9:11), 3));
                            end

                            filt.(land).(time).(fw).(crit).(regime) = nan(size(rcae_alt_t.(land).(time).(fw).(crit)));
                            if strcmp(regime, 'rce'); filt.(land).(time).(fw).(crit).(regime)(rcae_alt_t.(land).(time).(fw).(crit)==1)=1; % set RCE=1, elsewhere nan
                            elseif strcmp(regime, 'rae'); filt.(land).(time).(fw).(crit).(regime)(rcae_alt_t.(land).(time).(fw).(crit)==-1)=1; % set RAE=1, elsewhere nan
                            elseif strcmp(regime, 'rcae'); filt.(land).(time).(fw).(crit).(regime)(rcae_alt_t.(land).(time).(fw).(crit)==0)=1; % set RCAE=1, elsewhere nan
                            end

                            srfc_tf.(land).(time).(fw).(crit).(regime).(vname) = srfc_t.(land).(time).(vname) .* filt.(land).(time).(fw).(crit).(regime);

                            nanfilt.(regime) = nan(size(srfc_tf.(land).(time).(fw).(crit).(regime).(vname)));
                            nanfilt.(regime)(~isnan(srfc_tf.(land).(time).(fw).(crit).(regime).(vname))) = 1;

                            % take cosine-weighted average
                            for d = {'all', 'nh', 'sh', 'tp'}; domain = d{1};
                                if strcmp(regime, 'rce')
                                    if strcmp(domain, 'all')
                                        cosw = repmat(cosd(lat)', [size(nanfilt.(regime), 1) 1]);
                                        denm = srfc_tf.(land).(time).(fw).(crit).(regime).(vname);
                                        nume = nanfilt.(regime);
                                    elseif strcmp(domain, 'nh')
                                        cosw = repmat(cosd(lat(lat>0))', [size(nanfilt.(regime), 1) 1]);
                                        denm = srfc_tf.(land).(time).(fw).(crit).(regime).(vname)(:, lat>0);
                                        nume = nanfilt.(regime)(:, lat>0);
                                    elseif strcmp(domain, 'sh')
                                        cosw = repmat(cosd(lat(lat<0))', [size(nanfilt.(regime), 1) 1]);
                                        denm = srfc_tf.(land).(time).(fw).(crit).(regime).(vname)(:, lat<0);
                                        nume = nanfilt.(regime)(:, lat<0);
                                    elseif strcmp(domain, 'tp')
                                        cosw = repmat(cosd(lat(abs(lat)<10))', [size(nanfilt.(regime), 1) 1]);
                                        denm = srfc_tf.(land).(time).(fw).(crit).(regime).(vname)(:, abs(lat)<10);
                                        nume = nanfilt.(regime)(:, abs(lat)<10);
                                    end
                                elseif strcmp(regime, 'rae')
                                    if strcmp(domain, 'all')
                                        cosw = repmat(cosd(lat)', [size(nanfilt.(regime), 1) 1]);
                                        denm = srfc_tf.(land).(time).(fw).(crit).(regime).(vname);
                                        nume = nanfilt.(regime);
                                    elseif strcmp(domain, 'nh')
                                        cosw = repmat(cosd(lat(lat>0))', [size(nanfilt.(regime), 1) 1]);
                                        denm = srfc_tf.(land).(time).(fw).(crit).(regime).(vname)(:, lat>0);
                                        nume = nanfilt.(regime)(:, lat>0);
                                    elseif strcmp(domain, 'sh')
                                        cosw = repmat(cosd(lat(lat<0))', [size(nanfilt.(regime), 1) 1]);
                                        denm = srfc_tf.(land).(time).(fw).(crit).(regime).(vname)(:, lat<0);
                                        nume = nanfilt.(regime)(:, lat<0);
                                    end
                                elseif strcmp(regime, 'rcae')
                                    if strcmp(domain, 'all')
                                        cosw = repmat(cosd(lat)', [size(nanfilt.(regime), 1) 1]);
                                        denm = srfc_tf.(land).(time).(fw).(crit).(regime).(vname);
                                        nume = nanfilt.(regime);
                                    elseif strcmp(domain, 'nh')
                                        cosw = repmat(cosd(lat(lat>0))', [size(nanfilt.(regime), 1) 1]);
                                        denm = srfc_tf.(land).(time).(fw).(crit).(regime).(vname)(:, lat>0);
                                        nume = nanfilt.(regime)(:, lat>0);
                                    elseif strcmp(domain, 'sh')
                                        cosw = repmat(cosd(lat(lat<0))', [size(nanfilt.(regime), 1) 1]);
                                        denm = srfc_tf.(land).(time).(fw).(crit).(regime).(vname)(:, lat<0);
                                        nume = nanfilt.(regime)(:, lat<0);
                                    end
                                end

                                ma_si.(regime).(domain).(fw).(crit).(land).(time).(vname) = nansum(cosw.*denm, 2) ./ nansum(cosw.*nume, 2); % weighted meridional average
                                ma_si.(regime).(domain).(fw).(crit).(land).(time).(vname) = squeeze(nanmean(ma_si.(regime).(domain).(fw).(crit).(land).(time).(vname), 1)); % zonal average

                            end % end domain loop
                        end % end srfc variables loop

                    end % end RCE/RAE regime loop

                    if strcmp(type, 'era5') | strcmp(type, 'erai') | strcmp(type, 'era5c')
                        ma_si.rce.all.(fw).(crit).(land).(time).ta = calc_ma_dew_si(ma_si.rce.all.(fw).(crit).(land).(time), grid.dim3.plev, par, type, grid); % compute moist adiabat with dew_si point temperature
                        ma_si.rce.tp.(fw).(crit).(land).(time).ta = calc_ma_dew_si(ma_si.rce.tp.(fw).(crit).(land).(time), grid.dim3.plev, par, type, grid); % compute moist adiabat with dew_si point temperature
                        ma_si.rce.nh.(fw).(crit).(land).(time).ta = calc_ma_dew_si(ma_si.rce.nh.(fw).(crit).(land).(time), grid.dim3.plev, par, type, grid); % compute moist adiabat with dew_si point temperature
                        ma_si.rce.sh.(fw).(crit).(land).(time).ta = calc_ma_dew_si(ma_si.rce.sh.(fw).(crit).(land).(time), grid.dim3.plev, par, type, grid); % compute moist adiabat with dew_si point temperature
                        ma_si.rcae.all.(fw).(crit).(land).(time).ta = calc_ma_dew_si(ma_si.rcae.all.(fw).(crit).(land).(time), grid.dim3.plev, par, type, grid); % compute moist adiabat with dew_si point temperature
                        ma_si.rcae.nh.(fw).(crit).(land).(time).ta = calc_ma_dew_si(ma_si.rcae.nh.(fw).(crit).(land).(time), grid.dim3.plev, par, type, grid); % compute moist adiabat with dew_si point temperature
                        ma_si.rcae.sh.(fw).(crit).(land).(time).ta = calc_ma_dew_si(ma_si.rcae.sh.(fw).(crit).(land).(time), grid.dim3.plev, par, type, grid); % compute moist adiabat with dew_si point temperature
                    elseif strcmp(type, 'merra2')
ma_si.rce.all.(fw).(crit).(land).(time)
                        ma_si.rce.all.(fw).(crit).(land).(time).ta = calc_ma_dew_si(ma_si.rce.all.(fw).(crit).(land).(time), grid.dim3.plev, par, type, grid); % compute moist adiabat with dew_si point temperature
                        ma_si.rce.tp.(fw).(crit).(land).(time).ta = calc_ma_dew_si(ma_si.rce.tp.(fw).(crit).(land).(time), grid.dim3.plev, par, type, grid); % compute moist adiabat with dew_si point temperature
                        ma_si.rce.nh.(fw).(crit).(land).(time).ta = calc_ma_dew_si(ma_si.rce.nh.(fw).(crit).(land).(time), grid.dim3.plev, par, type, grid); % compute moist adiabat with dew_si point temperature
                        ma_si.rce.sh.(fw).(crit).(land).(time).ta = calc_ma_dew_si(ma_si.rce.sh.(fw).(crit).(land).(time), grid.dim3.plev, par, type, grid); % compute moist adiabat with dew_si point temperature
                        ma_si.rcae.all.(fw).(crit).(land).(time).ta = calc_ma_dew_si(ma_si.rcae.all.(fw).(crit).(land).(time), grid.dim3.plev, par, type, grid); % compute moist adiabat with dew_si point temperature
                        ma_si.rcae.nh.(fw).(crit).(land).(time).ta = calc_ma_dew_si(ma_si.rcae.nh.(fw).(crit).(land).(time), grid.dim3.plev, par, type, grid); % compute moist adiabat with dew_si point temperature
                        ma_si.rcae.sh.(fw).(crit).(land).(time).ta = calc_ma_dew_si(ma_si.rcae.sh.(fw).(crit).(land).(time), grid.dim3.plev, par, type, grid); % compute moist adiabat with dew_si point temperature
                    elseif strcmp(type, 'gcm')
                        ma_si.rce.all.(fw).(crit).(land).(time).ta = calc_ma_hurs_si(ma_si.rce.all.(fw).(crit).(land).(time), grid.dim3.plev, par, grid); % compute moist adiabat with RH
                        ma_si.rce.tp.(fw).(crit).(land).(time).ta = calc_ma_hurs_si(ma_si.rce.tp.(fw).(crit).(land).(time), grid.dim3.plev, par, grid); % compute moist adiabat with RH
                        ma_si.rce.nh.(fw).(crit).(land).(time).ta = calc_ma_hurs_si(ma_si.rce.nh.(fw).(crit).(land).(time), grid.dim3.plev, par, grid); % compute moist adiabat with RH
                        ma_si.rce.sh.(fw).(crit).(land).(time).ta = calc_ma_hurs_si(ma_si.rce.sh.(fw).(crit).(land).(time), grid.dim3.plev, par, grid); % compute moist adiabat with RH
                        ma_si.rcae.all.(fw).(crit).(land).(time).ta = calc_ma_hurs_si(ma_si.rcae.all.(fw).(crit).(land).(time), grid.dim3.plev, par, grid); % compute moist adiabat with RH
                        ma_si.rcae.nh.(fw).(crit).(land).(time).ta = calc_ma_hurs_si(ma_si.rcae.nh.(fw).(crit).(land).(time), grid.dim3.plev, par, grid); % compute moist adiabat with RH
                        ma_si.rcae.sh.(fw).(crit).(land).(time).ta = calc_ma_hurs_si(ma_si.rcae.sh.(fw).(crit).(land).(time), grid.dim3.plev, par, grid); % compute moist adiabat with RH
                    end

                end % end time average loop
            end % end land option loop
        end % end RCAE definition loop
    end % end MSE/DSE framework loop

    % save data into mat file
    printname = [foldername 'ma_si.mat'];
    if ~exist(foldername, 'dir')
        mkdir(foldername)
    end
    save(printname, 'ma_si');

end % process moist adiabat in RCE/RAE regimes
