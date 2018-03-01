% GetStarted script runs all the scripts sequentially in the correct order
% to reach plotting figure 2 in the manuscript

%% train decoders
TrainFeatureDecoders;
pause(1);

%% Apply decoders to predict features
PredictFeatures;
pause(1);

%% Noise matching
EstimateMatchedNoise;
pause(1);

%% Feature gain calculation and plot
PlotFeatureGain;