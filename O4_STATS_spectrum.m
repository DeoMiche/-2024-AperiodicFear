clearvars; clc

load('UTILITIES/EGI_layout.mat')
load('UTILITIES/EGI_204_chanlocs.mat')
load('UTILITIES/EGI_neighbours.mat')

eeg_dir_fn = '../DATA/FOOOF';
eeg_fn = dir(fullfile(eeg_dir_fn, '*.mat'));
eeg_fn = {eeg_fn.name}';
eeg_fn = eeg_fn(~(startsWith(eeg_fn, '._')));

load(fullfile(eeg_dir_fn, eeg_fn{1}))

ft_data = struct();
ft_data.time = FOOOF{1}{1}.freqs;
ft_data.dimord = 'chan_time';
ft_data.label = layout.label(1:end-3); % labels_204(1:end-1);
data_group1 = {};
data_group2 = {};

chan2plot = 117;

for i_subj = 1:36
    load(fullfile(eeg_dir_fn, eeg_fn{i_subj}))
    tmp = squeeze(struct2cell([FOOOF{1}{:}]));
    ape_params = cell2mat(tmp(7,:)');

    ape_chan(i_subj, 1,:) = ape_params(chan2plot,:);
    ft_data.avg = ape_params;
    data_group1{end+1} = ft_data;
    
    tmp = squeeze(struct2cell([FOOOF{2}{:}]));
    ape_params = cell2mat(tmp(7,:)');
    
    ape_chan(i_subj, 2,:) = ape_params(chan2plot,:);
    ft_data.avg = ape_params;
    data_group2{end+1} = ft_data;
    
end

%% STATS

cfg         = [];
cfg.method           = 'montecarlo'; %'analytic'; 
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
cfg.clusteralpha     = 0.05;
cfg.clusterstatistic = 'maxsum';
cfg.clustertail      = 0;
[stat] = ft_timelockstatistics(cfg, data_group1{:}, data_group2{:});

%% VISUALIZE

% chan2plot = 117;
freq = FOOOF{1}{1}.freqs;

figure
subplot(121); hold on
x = [1:203];
y = ft_data.time;
contourf(y, x, 1-stat_prob, [ 1:999]/1000, 'LineWidth', 2, 'LineColor', 'none')
contourf(y, x, stat_tvalue, 'LineWidth', 2, 'LineColor', 'none')
contour(y, x, stat.prob < .05, [1, 1], 'LineWidth', 2, 'LineColor', [1 1 1])
h = colorbar;
h.Label.String = 't-value';
colormap magma
axis square
ix_label = isnan(str2double(ft_data.label));
ix_tick = round(linspace(1,203, sum(ix_label)));
ix_tick = ix_label;
yticks(x(ix_tick))
yticklabels(ft_data.label(ix_label))
xlabel('Frequency (Hz)')
ylabel('Electrode')

subplot(122); hold on
plot(freq, squeeze(mean(ape_chan(:,1,:))), 'Color', [0.6328    0.1879    0.4953], 'LineWidth', 2);
plot(freq, squeeze(mean(ape_chan(:,2,:))), 'Color', [0.9846    0.5207    0.3767],'LineWidth', 2);
yLim = ylim;
H = stat.mask(chan2plot,:);
H = stat.prob(chan2plot,:)<.05;
H2 = stat_prob(chan2plot,:)<.05;
plot(freq(H), ones(sum(H), 1)*1.02*yLim(1), 'rs', 'MarkerSize', 2, 'MarkerFaceColor', [1 0 0])
plot(freq(H2), ones(sum(H2), 1) *yLim(1), 'ks', 'MarkerSize', 2, 'MarkerFaceColor', [0 0 0])
ylim([3.9 7.5])
legend({'neutral', 'fear', 'p corrected', 'p<.05'})
axis square
% colorbar
xlabel('Frequency (Hz)')
ylabel('PSD')
title('Oz')

colormap magma

