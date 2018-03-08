function [model, sigma4lab, mu4lab, sigma4f, mu4f, I4f] = train_eachROI(labels,trainingvox,param)
%train_eachROI produces the SLiR model for all the labels with all the DNN
%layers given

layercount = param.layercount;
featurenum = param.featurecount;

for layer = 1:layercount

    for feat = 1:featurenum
        % extract label
        traininglabel = labels{layer,feat};
        
        [temporal_model, sigma4label,mu4label, sigma4feat, mu4feat, I, ~]=...
            train_SLiR(trainingvox,traininglabel,param);
        pause(1);
        model(layer,feat)=temporal_model;
        sigma4lab(layer,feat,:)=sigma4label;
        mu4lab(layer,feat,:) = mu4label;
        sigma4f(layer,feat,:)=sigma4feat;
        mu4f(layer,feat,:) = mu4feat;
        I4f(layer,feat,:) = I;
    end
end





