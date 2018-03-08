function [predicted_label, true_label] = test_eachROI(model,testvox,mod_labels,sigma4label,mu4label,sigma4feat,mu4feat,I4feat,param)
%test_eachROI applies the SLiR model for all the labels with all the DNN
%layers given

layercount = param.layercount;
featurenum = param.featurecount;

for layer = 1:layercount

    for feat = 1:featurenum
        
        testlabel = mod_labels{layer,feat};
        model_1   = squeeze(model(layer,feat));
        sigma4label_1 = squeeze(sigma4label(layer,feat,:));
        mu4label_1 = squeeze(mu4label(layer,feat,:));
        sigma4feat_1 = squeeze(sigma4feat(layer,feat,:));
        mu4feat_1 = squeeze(mu4feat(layer,feat,:));
        I = squeeze(I4feat(layer,feat,:));
        [temporal_predicted_label, temporal_true_label, ~]=...
            test_SLiR(model_1, testvox,testlabel,sigma4label_1, mu4label_1,...
            sigma4feat_1, mu4feat_1,I, param);

        predicted_label(layer,feat,:)=temporal_predicted_label;
        true_label(layer,feat,:)=temporal_true_label;
    end
end