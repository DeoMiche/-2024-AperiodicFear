load('UTILITIES/EGI_layout.mat')
load('UTILITIES/EGI_204_chanlocs.mat')

eeg_dir_fn = '../DATA/FOOOF';
% eeg_dir_fn = '../DATA/NEW/FOOOF';
eeg_fn = dir(fullfile(eeg_dir_fn, '*.mat'));
eeg_fn = {eeg_fn.name}';
eeg_fn = eeg_fn(~(startsWith(eeg_fn, '._')));

%% ORGANIZE DATA

ft_data = struct();
ft_data.time = 0;
ft_data.dimord = 'chan_time';
ft_data.label = layout.label(1:end-3); % labels_204(1:end-1);
data_group1 = {};
data_group2 = {};

chan2plot = 117;
param2use = 2; % 1=offset; 2=slope
for i_subj = 1:36
    load(fullfile(eeg_dir_fn, eeg_fn{i_subj}))
    tmp = squeeze(struct2cell([FOOOF{1}{:}]));
    ape_params = cell2mat(tmp(1,:)');

    % get ap fit of chan2plot for plot
    
    ape_chan(i_subj, 1) = ape_params(chan2plot,param2use); 
    ape_chans(i_subj, :, 1) = ape_params(:,param2use);
    ft_data.avg = ape_params(:,param2use);
    data_group1{end+1} = ft_data;
    
    tmp = squeeze(struct2cell([FOOOF{2}{:}]));
    ape_params = cell2mat(tmp(1,:)');
    
    ape_chan(i_subj, 2) = ape_params(chan2plot,param2use);
    ape_chans(i_subj, :, 2) = ape_params(:,param2use);
    ft_data.avg = ape_params(:,param2use);
    data_group2{end+1} = ft_data;
   
end

%% STATS
cfg_neighb        = [];
cfg_neighb.method = 'triangulation';
cfg_neighb.layout = layout;
% cfg_neighb.neighbourdist        = 0.2;
neighbours        = ft_prepare_neighbours(cfg_neighb);

cfg         = [];
cfg.method           = 'montecarlo';
cfg.statistic        = 'depsamplesT';
cfg.correctm         = 'no'; %'cluster';
cfg.minnbchan        = 1;
cfg.neighbours       = neighbours;
cfg.tail             = 0;
cfg.alpha            = 0.025;
cfg.numrandomization = 1000; 'all';

nSubj  = length(data_group1);
ivar   = repmat(1:nSubj, 1,2)';
uvar   = [ones(1,nSubj) ones(1,nSubj)*2]';
cfg.design = [ivar uvar];
cfg.ivar   = 2;
cfg.uvar   = 1;

[stat] = ft_timelockstatistics(cfg, data_group1{:}, data_group2{:});
stat_tvalue = stat.stat;
stat_prob = stat.prob;

cfg.correctm         = 'cluster';
cfg.clusteralpha     = 0.025;
cfg.clusterstatistic = 'maxsum';
cfg.clustertail      = 0;
[stat] = ft_timelockstatistics(cfg, data_group1{:}, data_group2{:});

%% VISUALIZE

figure
topoplot(stat_tvalue, chanlocs, 'style', 'map',  'electrodes', 'on', ...
    'maplimits', [ 0 4 ], ...
    'emarker2', {find(stat.mask), '.','k',14,1}, 'gridscale', 256);
h = colorbar;
h.Label.String = "t-value";
colormap magma


% ape_plot = squeeze(mean(mean(ape_chans, 1),3));
% figure
% topoplot(ape_plot, chanlocs, 'style', 'map',  'electrodes', 'on', ...
%     'maplimits', [ min(ape_plot) max(ape_plot) ], ...
%     'gridscale', 256);
% h = colorbar;
% h.Label.String = "t-value";









