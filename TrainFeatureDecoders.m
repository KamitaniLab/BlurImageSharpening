%TrainFeatureDecoders.m script trains decoders to predict DNN features from
%fMRI data

%% Initialization
clear;
rng('default');
Subjects = {'Subject1', 'Subject2', 'Subject3', 'Subject4', 'Subject5'};
DNNlayers = {'DNN1', 'DNN2', 'DNN3', 'DNN4', 'DNN5', 'DNN6', 'DNN7', 'DNN8'};
feat_per_layer = 1000;
addpath(genpath(fullfile(pwd,'lib')));
workDir = pwd;
lockDir = fullfile(workDir,'tmp');

dataFolder = fullfile(workDir,'data');

%% Load image features
fprintf('Loading Image Features\n');
ImageFeatures = load(fullfile(dataFolder,'ImageFeatures.mat'), 'dataSet', 'metaData');
trtest = get_dataset(ImageFeatures.dataSet, ImageFeatures.metaData, 'TrTest');
imgcode_feat = get_dataset(ImageFeatures.dataSet, ImageFeatures.metaData, 'ImageCode');

imgcode_feat = imgcode_feat(trtest == 1);

for layer = 1:length(DNNlayers)
    selectCond = ['DNN_layer = ', num2str(layer)];
    image_features = select_feature(ImageFeatures.dataSet, ImageFeatures.metaData, selectCond);
    image_features = image_features(trtest == 1, :);
    for feat = 1:feat_per_layer
        labels{layer, feat} = image_features(:,feat);
    end
    
end


%% Load fMRI data
for subject = 1:length(Subjects)
    % load fRMI data file
    fprintf('Loading fMRI data from %s\n', Subjects{subject});
    load(fullfile(dataFolder,Subjects{subject}), 'dataSet', 'metaData', 'RoiNames', 'SubjectName');
    Train(subject).subjectname = SubjectName;
    Test(subject).subjectname = SubjectName;
    
    % load metadata
    imgcode = get_dataset(dataSet, metaData, 'ImageCode');
    modification = get_dataset(dataSet, metaData, 'Modification');
    condition = get_dataset(dataSet, metaData, 'Condition');
    correct = get_dataset(dataSet, metaData, 'Correct');
    certain = get_dataset(dataSet, metaData, 'Certain');
    category = get_dataset(dataSet, metaData, 'Category');
    trtest = get_dataset(dataSet, metaData, 'TrTest');
    
    % separate training from test data
    % training metadata
    Train(subject).imgcode = imgcode(trtest == 1);
    
    % test metadata
    Test(subject).imgcode = imgcode(trtest == 2);
    Test(subject).condition = condition(trtest == 2);
    Test(subject).modification = modification(trtest == 2);
    Test(subject).category = category(trtest == 2);
    Test(subject).correct = correct(trtest == 2);
    Test(subject).certain = certain(trtest == 2);
    
    % load voxels for each ROI and separate training and test data
    for roi = 1:length(RoiNames)
        selectCond = [RoiNames{roi} , '= 1'];
        x = select_feature(dataSet, metaData, selectCond);
        Train(subject).x{roi} = x(trtest == 1,:);
        Test(subject).x{roi} = x(trtest == 2,:);
    end
    
    % align features and fMRI data for training data
    [~, ind] = sort(Train(subject).imgcode, 'ascend'); %feature imgcode is already sorted from 1 to 1000
    Train(subject).imgcode = Train(subject).imgcode(ind);
    for roi = 1:length(RoiNames)
        Train(subject).x{roi} = Train(subject).x{roi}(ind,:);
    end
end

%% Initialization of feature decoding training
param.numFeatures   = 500; %number of voxels for each ROI
param.Ntrain        = 200; % # of total training iteration (note that the number of iterations in the manuscript was 2000)
param.Nskip         = 200;     % skip steps for display info
param.layercount    = 8;    %number of layers
param.featurecount  = 1000; %number of features per layer

%% Create the list of decoders to build
subroicomb = combvec(1:length(Subjects),1:length(RoiNames));
subroicomb = subroicomb';
for combsr = 1:size(subroicomb,1)
    
    modelnames{combsr} = ...
        strcat(Subjects{subroicomb(combsr,1)}, '_', RoiNames{subroicomb(combsr,2)}, '.mat');

    
end

%% Check if models already exist
model_exist = false(length(Subjects)*length(RoiNames),1);
if exist(fullfile(workDir,'models'))
    model_files = dir(fullfile(workDir,'models','*.mat'));
    for fi = 1:length(model_files)
        model_exist = model_exist | strcmp(model_files(fi).name,modelnames)';
        fprintf('Decoder %s model already exists... Skipped\n', model_files(fi).name(1:end-4));
    end
else
    mkdir(fullfile(workDir,'models'));
end

% remove decoders that already exist from creation list
subroicomb(model_exist,:) = [];
modelnames(model_exist) = [];

%% Train decoders and save them
for combsr = 1:size(subroicomb,1)
    analysisName = modelnames{combsr};
    % if model exists skip
    if exist(fullfile(workDir,'models',analysisName))
        fprintf('Decoder %s model already exists... Skipped\n', analysisName(1:end-4));
        continue;
    end
    
    % if locked then skip 
    if islocked(analysisName, lockDir)
        fprintf('Decoder %s training is already running... Skipped\n', analysisName(1:end-4));
        continue;
    end
    % lock current process
    lockcomput(analysisName, lockDir);
    % start training
    fprintf('Decoder %s training started\n', analysisName(1:end-4));
    trainingvox = Train(subroicomb(combsr,1)).x{subroicomb(combsr,2)};
    [model, sigma4label, mu4label, sigma4feat, mu4feat, I4feat] = train_eachROI(labels,trainingvox,param);
    
    % save model
    save(fullfile(workDir,'models',modelnames{combsr}),'model','sigma4label','mu4label','sigma4feat','mu4feat','I4feat', '-v7.3');
    fprintf('Decoder %s training finished\n', analysisName(1:end-4));
    unlockcomput(analysisName, lockDir);
        
end
fprintf('Decoders training finished!\n');