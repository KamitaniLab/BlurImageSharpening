% PlotFeatureGain reproduces figure 2 of the manuscript where it plots one
% scatter plot showing a represntative subject and DNN layer correlations
% (r_s and r_o) and also shows r_s and r_o for each blur level for both
% predicted and noise matched features. Finally it plots feature gain for
% each DNN layer and blur level across subjects from VC

%% Initialization
clear;
workDir = pwd;
results_file = 'Feature_Correlation.mat';
Subjects = {'Subject1', 'Subject2', 'Subject3', 'Subject4', 'Subject5'};
DNNlayers = {'DNN1', 'DNN2', 'DNN3', 'DNN4', 'DNN5', 'DNN6', 'DNN7', 'DNN8'};
modtxt = {'0%','6%', '12%','25%'}; %different blur levels
alpha = 0.05; %T-score cutoff percentile

%% Select representative results
% change those variables to change which representative result to view
% Note that in the manuscript rep_subject = 4 and rep_layer = 6
rep_subject = 4;
rep_layer   = 6;

%% Load noise matched features
fprintf('Loading noise matched features... \n');
load(fullfile(workDir,'results',results_file), 'ind', 'Test', ...
    'corrnoiseo','corrnoises','corrpreds', 'corrpredo',...
    'Subjects','DNNlayers','RoiNames');

%% Extract noise-matched VC features
roi = 8; 
fprintf('ROI is %s\n', RoiNames{roi});
for subject = 1:length(Subjects)
    for layer = 1:length(DNNlayers)
        matched_corrnoiseo(subject,layer,:) = corrnoiseo(ind(subject,roi,layer),layer,:);
        matched_corrnoises(subject,layer,:) = corrnoises(ind(subject,roi,layer),layer,:);
    end
end

%% Extract predicted feature correlation from VC
for subject = 1:length(Subjects)
    corrpredo_roi(subject, :,:) = squeeze(corrpredo(subject,roi,:,:));
    corrpreds_roi(subject, :,:) = squeeze(corrpreds(subject,roi,:,:));
end

%% Divide correlations for each blur level
m = Test(1).modification;
for mod = 1:length(modtxt)
    corrpredo_roi_mod(:,:,:,mod) = corrpredo_roi(:,:,(m == mod));
    corrpreds_roi_mod(:,:,:,mod) = corrpreds_roi(:,:,(m == mod));
end
% calculate delta_r_pred
corrpredd_roi_mod = corrpredo_roi_mod - corrpreds_roi_mod;

%% Calculate feature gain
% first calculate r_o - r_o_noise and r_s - r_s_noise
fprintf('Calculating feature gain...\n')
for subject = 1:length(Subjects)
    ofeat_gain(subject, :,:) = squeeze(corrpredo(subject,roi,:,:))...
        - squeeze(matched_corrnoiseo(subject,:,:));
    tfeat_gain(subject, :,:) = squeeze(corrpreds(subject,roi,:,:))...
        - squeeze(matched_corrnoises(subject,:,:));
end
for mod = 1:length(modtxt)
    ofeat_gain_m(:,:,:,mod) = ofeat_gain(:,:,(m == mod));
    tfeat_gain_m(:,:,:,mod) = tfeat_gain(:,:,(m == mod));
end
% the calculate feature gain
feature_gain = ofeat_gain_m - tfeat_gain_m;

%% Calculate means and data for plots
fprintf('Displaying plots for %s from %s\n',Subjects{rep_subject},DNNlayers{rep_layer});
% scatter plot data
Xdata = squeeze(corrpredo_roi(rep_subject, rep_layer,:));
Ydata = squeeze(corrpreds_roi(rep_subject, rep_layer,:));

Xdatamean = squeeze(mean(corrpredo_roi_mod(rep_subject,rep_layer,:,:),3));
Ydatamean = squeeze(mean(corrpreds_roi_mod(rep_subject,rep_layer,:,:),3));

% noise matched means
for mod = 1:length(modtxt)
    noise_o(mod) = squeeze(mean(matched_corrnoiseo(rep_subject,rep_layer,m == mod),3));
    noise_s(mod) = squeeze(mean(matched_corrnoises(rep_subject,rep_layer,m == mod),3));
end

% feature gain
feature_gain_modmean = squeeze(mean(feature_gain,3));
feature_gain_submean = squeeze(mean(feature_gain_modmean,1));
% feature gain confidence intervals
SEM = std(feature_gain_modmean,0,1)/sqrt(size(feature_gain_modmean,1)); % Standard Error
ts = tinv([alpha/2  1-alpha/2],size(feature_gain_modmean,1)-1); % T-Score
feature_gain_subci  = ts(2)*squeeze(SEM);

%% Plot results
HH = figure('units','centimeters','outerposition',[1 0 21 29.7],'Color',[1,1,1]);

subplot (8,2,1:2:6); hold on;
set(gca, 'fontsize', 10,'fontname', 'Arial');
colors = {[1,1,1]*0.1,[1,1,1]*0.4,[1,1,1]*0.7};
markershapes = {'o', '^', 's'};
% plot all points for each blur
for mod = 2:length(modtxt) % skip original
    scatter(Xdata((m == mod)),Ydata((m == mod)),...
        30,'filled',markershapes{mod-1},'MarkerFaceColor',colors{mod-1},...
        'MarkerFaceAlpha',0.7);
end

legend(modtxt(2:length(modtxt)),'Location','NorthWest');

% plot mean point of each blur level
for mod = 2:length(modtxt)  % skip original

    scatter(Xdatamean(mod),Ydatamean(mod), 50, 'Marker',markershapes{mod-1}, ...
        'LineWidth', 2,'MarkerEdgeColor', 'k','MarkerFaceColor','w','MarkerFaceAlpha',0.7);

end

set(gca, 'XTick' , -0.5:0.5:0.5,'YTick' , -0.5:0.5:0.5);
axis equal;
xlim([-0.3,0.7]); ylim([-0.3,0.7]); 
line([-1,0.6],[-1,0.6],'LineWidth',1, 'Color','k');

subplot (8,2,7:2:10); hold on;
set(gca, 'fontsize', 10,'fontname', 'Arial');
plot(Xdatamean,'Color',[0,0,0], 'LineWidth', 1);
plot(Ydatamean,'Color',[0.7,0.7,0.7], 'LineWidth', 1);
ylim([0,0.3]);
ylabel ('Correlation:\newlinedecoded features');
set(gca, 'XTick' , 1:length(modtxt), 'XTickLabel', modtxt);
xlabel('Blur level')
xlim([0.5, 4.5]);
set(gca,'XColor', [0,0,0],'YColor', [0,0,0]);
legend({'r_o', 'r_s'},'Location','NorthEast');

subplot (8,2,13:2:16); hold on;
set(gca, 'fontsize', 10,'fontname', 'Arial');
plot(noise_o,'Color',[0,0,0], 'LineWidth', 1);
plot(noise_s,'Color',[0.7,0.7,0.7], 'LineWidth', 1);
ylim([0,0.3]);
ylabel ('Correlation:\newlinenoise-matched features');
set(gca, 'XTick' , 1:length(modtxt), 'XTickLabel', modtxt);
xlabel('Blur level')
xlim([0.5, 4.5]);
set(gca,'XColor', [0,0,0],'YColor', [0,0,0]);

for layer = 1:length(DNNlayers)
    subplot (8,2,18-2*layer); hold on;
    set(gca, 'fontsize', 10,'fontname', 'Arial');
    bar(feature_gain_submean(layer,2:length(modtxt)),'EdgeColor', 'none');
    errorbar(feature_gain_submean(layer,2:length(modtxt)),...
        feature_gain_subci(layer,2:length(modtxt)),'.k');
    ylim([-0.1,0.3]);
    if layer == 4
        ylabel('Feature gain (\Deltar_{decode} - \Deltar_{noise})');
    end
    if layer == 1
        set(gca, 'XTick' , 1:3, 'XTickLabel', modtxt(2:end));
    end
    colormap('gray');
    set(gca,'XColor', [0,0,0],'YColor', [0,0,0]);
    
end