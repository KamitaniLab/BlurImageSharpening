% EstimateMatchedNoise calculates the correlations between predcited
% features and true features, additionally it performs the noise matching
% algorithm and find noise matched correlations as well. This enables the
% calculation of feature gain in the next scripts

%% Initialization
clear;
rng('default');
workDir = pwd;
noisestep = -0.1; %to adjust resolution of noise matching
features_file = 'Predicted_features.mat';
Subjects = {'Subject1', 'Subject2', 'Subject3', 'Subject4', 'Subject5'};
DNNlayers = {'DNN1', 'DNN2', 'DNN3', 'DNN4', 'DNN5', 'DNN6', 'DNN7', 'DNN8'};
modtxt = {'0%','6%', '12%','25%'}; %different blur levels
feat_per_layer = 1000;
SNR = 10:noisestep:-100; %create the additive noise SNR levels
saveFileName = 'Feature_Correlation.mat';

%% Load decoded features
fprintf('Loading decoded features...\n');
load(fullfile(workDir,'results',features_file),'pred_feat','true_feat',...
    'Test', 'Subjects','DNNlayers','RoiNames');

m = Test(1).modification; %extract blur level (aligned among all subjects)

%% Extract true features of stimulus and original images
tfeat = true_feat;
ofeat = tfeat(:,:,m == 1); %features of original images only
ofeat = repelem(ofeat, 1,1,length(modtxt));

%% Initialize noise-added features
noised_matsize = [length(SNR), size(ofeat)]; %prepare a matrix for each noise level
ofeat_noise = zeros(noised_matsize);
corrnoiseo = zeros(length(SNR),8,size(ofeat,3)); %for storing correlation values of noisy features
corrnoises = zeros(length(SNR),8,size(ofeat,3));
ofeatcorrmean = zeros(length(SNR),length(DNNlayers), length(modtxt)); %for mean values of correlation

%% Calculate correlation values for predicted features (r_s & r_o)
fprintf('Calculating correlation of decoded features...\n');
for subject = 1:length(Subjects)
    for roi = 1:length(RoiNames)
        pfeat = pred_feat{subject,roi}; 
        for layer = 1:length(DNNlayers)
            % calculate correlation of feature patterns for each image
            for img = 1:size(ofeat,3) 
                tempp = squeeze(pfeat(layer,:,img)); %predicted features
                tempt = squeeze(tfeat(layer,:,img)); %true stimulus img features
                tempo = squeeze(ofeat(layer,:,img)); %true original img features
                % correlation calculation
                corrpreds(subject,roi,layer,img) = corr(tempp', tempt'); %r_s
                corrpredo(subject,roi,layer,img) = corr(tempp', tempo'); %r_o
            end
        end
    end
end

%% Add noise to true features and calculate correlation
% corrlation between noisy true features and true noiseless features is
% calculated here
fprintf('Creating noisy features...\n');
for s = 1:length(SNR)
    for layer = 1:length(DNNlayers)
        for img = 1:size(ofeat,3)
            temp = squeeze(tfeat(layer,:,img)); %true feature extraction
            temp1 = awgn(temp,SNR(s),'measured'); %noise addition
            tempo = squeeze(ofeat(layer,:,img)); %original true feature
            %corrlation calculation
            corrnoiseo(s,layer,img) = corr(temp1',tempo'); % r_o_noisy for different noise levels
            corrnoises(s,layer,img) = corr(temp1',temp'); % r_s_noisy for different noise levels
            
        end
    end
end


%% calculate mean correlaion of noisy features and predicted features with true features
% for each subject and each noise level
for s = 1:(length(SNR))
    for layer = 1:length(DNNlayers)
        for mod = 1:length(modtxt) %calculate mean for each blur level
            % noisy features
            ofeatcorrmean(s,layer,mod) = mean(squeeze(corrnoiseo(s,layer,(m == mod))));
            %predicted features are different for each subject and ROI
            for roi = 1:length(RoiNames)        
                for subject = 1:length(Subjects)
                    origmean_sub(subject,roi,layer,mod) = ...
                        mean(squeeze(corrpredo(subject,roi,layer,(m == mod))));
                end
            
            end
           
        end
    end
end

%% Find matching noise level
% For each ROI and subject find the noise level where the correlation of
% noisy features of original images with true DNN features is similar to
% that of predicted features.
% If no level is found (due to negative correlation), take the noise level
% that reduced correlation to zero
fprintf('Noise matching...\n');
ind = [];
for roi = 1:length(RoiNames)
    %extract only original stimulus image correlation
    ofeat_orig = squeeze(ofeatcorrmean(:,:,1));
    pred_orig_mean = squeeze(origmean_sub(:,:,:,1));
    
    for layer = 1:length(DNNlayers)
        for subject = 1:length(Subjects)
            % find the point where difference between correlations is
            % minimum
            Diff = abs(ofeat_orig(:,layer) - pred_orig_mean(subject,roi,layer));
            equal_pt = find(Diff == min(Diff));
            
            if pred_orig_mean(subject,roi,layer) >= 0
                % if correlation is positive means that point is the point
                % of noise matching
                ind(subject,roi,layer) = equal_pt(1);
            else
                % In case actual correlation is negative then there is no
                % noise-matching so we take the point where correlation
                % reaches zero.
                Diff = ofeat_orig(:,layer);
                equal_pt = find(Diff < 0);
                % save the location of noise matching level
                ind(subject,roi,layer) = equal_pt(1);
            end
        end
    end
end
fprintf('Saving results...\n');
save(fullfile(workDir,'results',saveFileName), 'ind', 'Test', ...
    'corrnoiseo','corrnoises','corrpreds', 'corrpredo', ...
    'Subjects','DNNlayers','RoiNames', '-v7.3');
fprintf('Done!\n');
