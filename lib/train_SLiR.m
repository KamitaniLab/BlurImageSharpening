function [model, sigma4label, mu4label,sigma,mu, I,  param] = train_SLiR(feature4training,label4training,param)
%train_SLiR trains SLiR model to predict label4training from feature4training


if ~isfield(param,'zscore4label')
    param.zscore4label=1;
end
if ~isfield(param,'zscore4feature')
    param.zscore4feature=1;
end
if ~isfield(param,'numFeatures')
    param.numFeatures=size(feature4training,2);
end


if param.zscore4feature
    [feature4training mu sigma]=zscore(feature4training);
else
    mu = 0;
    sigma = 0;
    
end

if param.zscore4label
    [label4training mu4label sigma4label]=zscore(label4training);
else
    mu4label = 0;
    sigma4label = 0;
end
if param.numFeatures~=size(feature4training,2);
    C=corr(label4training,feature4training);
    [dummy I]=sort(abs(C),'descend');
    feature4training=feature4training(:,I(1:param.numFeatures));
    
end

param4SLiR.Ntrain = param.Ntrain; % # of total training iteration
param4SLiR.Nskip  = param.Nskip;     % skip steps for display info
param4SLiR.data_norm =0;
model=[];
feature4trainingInSLiR=[feature4training ones(size(feature4training,1),1)];

model = linear_map_sparse_cov(feature4trainingInSLiR',label4training', model, param4SLiR);


