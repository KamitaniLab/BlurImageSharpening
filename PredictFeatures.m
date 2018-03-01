% PredictFeatures uses the models created by TrainFeatureDecoders script to
% decode the features of blurred images

%% Initialization
clear;
rng('default');
Subjects = {'Subject1', 'Subject2', 'Subject3', 'Subject4', 'Subject5'};
DNNlayers = {'DNN1', 'DNN2', 'DNN3', 'DNN4', 'DNN5', 'DNN6', 'DNN7', 'DNN8'};
feat_per_layer = 1000;
addpath(genpath(fullfile(pwd,'lib')));
workDir = pwd;
dataFolder = fullfile(workDir,'data');

%% Load image features
fprintf('Loading Image Features\n');
ImageFeatures = load(fullfile(dataFolder,'ImageFeatures.mat'), 'dataSet', 'metaData');
trtest = get_dataset(ImageFeatures.dataSet, ImageFeatures.metaData, 'TrTest');
imgcode_feat = get_dataset(ImageFeatures.dataSet, ImageFeatures.metaData, 'ImageCode');

imgcode_feat = imgcode_feat(trtest == 2);

for layer = 1:length(DNNlayers)
    selectCond = ['DNN_layer = ', num2str(layer)];
    image_features = select_feature(ImageFeatures.dataSet, ImageFeatures.metaData, selectCond);
    image_features = image_features(trtest == 2, :);
    for feat = 1:feat_per_layer
        labels{layer, feat} = image_features(:,feat);
    end
    
end

%% Load fMRI data and align with features
for subject = 1:length(Subjects)
    % load fRMI data file
    fprintf('Loading fMRI data from %s\n', Subjects{subject});
    load(fullfile(dataFolder,Subjects{subject}), 'dataSet', 'metaData', 'RoiNames', 'SubjectName');
    
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
        Test(subject).x{roi} = x(trtest == 2,:);
    end
    
    % align features and fMRI data for training data
    % add the category to the image code to sort images
    imgcode_cat = Test(subject).category(logical(Test(subject).condition))*100 + ...
        Test(subject).imgcode(logical(Test(subject).condition));
    % concatenate no-category and category image codes after adding
    % category
    imgcode = [Test(subject).imgcode(~Test(subject).condition) ; ...
        imgcode_cat];
    
    [~, ind] = sort(imgcode, 'ascend'); %feature imgcode is already sorted 
    Test(subject).imgcode = Test(subject).imgcode(ind);
    Test(subject).condition = Test(subject).condition(ind);
    Test(subject).modification = Test(subject).modification(ind);
    Test(subject).category = Test(subject).category(ind);
    Test(subject).correct = Test(subject).correct(ind);
    Test(subject).certain = Test(subject).certain(ind);
    
    for roi = 1:length(RoiNames)
        Test(subject).x{roi} = Test(subject).x{roi}(ind,:);
    end
end

%% Initialization of feature decoding training
param.numFeatures   = 500; %number of voxels for each ROI
param.Ntrain        = 20; % # of total training iteration (note that the number of iterations in the manuscript was 2000)
param.Nskip         = 20;     % skip steps for display info
param.layercount    = 8;    %number of layers
param.featurecount  = 1000; %number of features per layer

%% Create the list of decoders
subroicomb = combvec(1:length(Subjects),1:length(RoiNames));
subroicomb = subroicomb';
for combsr = 1:size(subroicomb,1)
    
    modelnames{combsr} = ...
        strcat(Subjects{subroicomb(combsr,1)}, '_', RoiNames{subroicomb(combsr,2)}, '.mat');

    
end

setupdir(fullfile(workDir,'results'));
%% Load decoders and predict features
for combsr = 1:size(subroicomb,1)
    analysisName = modelnames{combsr};
    fprintf('Feature decoding from %s started...\n', analysisName(1:end-4));
    testvox = Test(subroicomb(combsr,1)).x{subroicomb(combsr,2)};
    load(fullfile(workDir,'models', analysisName));
    [predictedf, truef] = test_eachROI(model, testvox, labels, sigma4label, mu4label, sigma4feat, mu4feat, I4feat, param);
    % feature array dimensions are in the form of (layer,feature,image)

    pred_feat{subroicomb(combsr,1),subroicomb(combsr,2)} = predictedf;
    
    fprintf('[Done] Feature decodeing from %s...\n', analysisName(1:end-4));
        
end
true_feat =   truef;
DateCreated = date;
fprintf('Feature decodeing done!\n');
fprintf('Saving...\n');
save(fullfile(workDir,'results','Predicted_features.mat'),'pred_feat','true_feat',...
    'Test', 'Subjects','DNNlayers','RoiNames','DateCreated', '-v7.3');
fprintf('Done!\n');