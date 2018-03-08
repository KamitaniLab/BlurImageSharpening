function [predicted_label true_label param] = test_SLiR(model,feature4test,label4test,sigma4label,mu4label,sigma4feat,mu4feat,I,param)
%test_SLiR applies the SLiR model to predict labels from feature4test


if ~isfield(param,'zscore4label')
    param.zscore4label=1;
end
if ~isfield(param,'zscore4feature')
    param.zscore4feature=1;
end

if param.zscore4feature
    
    feature4test=(feature4test-ones(size(feature4test,1),1)*mu4feat')./(ones(size(feature4test,1),1)*sigma4feat');
end

if param.numFeatures~=size(feature4test,2);
    
    feature4test=feature4test(:,I(1:param.numFeatures));
end

param4SLiR.data_norm =0;

feature4testInSLiR=[feature4test ones(size(feature4test,1),1)];
predicted_label=(predict_output(feature4testInSLiR', model, param4SLiR))';

true_label=label4test-mu4label;
predicted_label=(predicted_label.*sigma4label);
