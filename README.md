# Blur Image Sharpening

This repository contains the demo code to reproduce the results in our manuscript: "[Sharpening of hierarchical visual feature representations of blurred images](https://www.biorxiv.org/content/early/2017/12/07/230078)". 
We demonstrate in this papar the sharpening effect occuring in the visual cortex to enhance the representation of viewed blurred images. For more details, please refer to the manuscript.

## Data

The fMRI data for five subjects (decoder training and blurred test images) and visual features of DNN layers from 1 to 8 (extracted via matconvnet) are available from [BrainLiner]().

### Prerequisites

These data are saved in the form of the [BrainDecoderToolbox2](https://github.com/KamitaniLab/BrainDecoderToolbox2/) format. This tool is needed to run the code.

This code was created and tested using MATLAB R2016a
Required MATLAB toolboxes:
* Neural Network Toolbox (v9.0)
* Statistics and Machine Learning Toolbox (v10.2)
* Communication System Toolbox (v6.2)


## Usage

The folder organization should be as follows

```
   ./ --+-- GetStarted.m (Runs all the codes in the correct sequence)
        |
        +-- TrainFeatureDecoders.m (Train the feature decoders)
        |
        +-- PredictFeatures.m (Use the trained feature decoders to predict features from test fMRI data)
        |
        +-- EstimateMatchedNoise.m (Apply the noise matching algorithm)
        |
        +-- PlotFeatureGain.m  (Computed feature gain and plot figure 2 from the manuscript)
        |
        data/ --+-- Subject1.mat (fMRI data, subject 1)
        |       |
        |       +-- Subject2.mat (fMRI data, subject 2)
        |       |
        |       +-- Subject3.mat (fMRI data, subject 3)
        |       |
        |       +-- Subject4.mat (fMRI data, subject 4)
        |       |
        |       +-- Subject5.mat (fMRI data, subject 5)
        |       |
        |       +-- ImageFeatures.mat (image features extracted with Matconvnet)
        |
        lib/ (contains all the support functions needed)
```


You can run GetStarted to apply all the functions in a sequential manner.

**However,** The function *TrainFeatureDecoders* takes a very long time and could instead be run in parallel for faster computations. It has the functionality to skip jobs that are already running on another cluster.
Trained decoder will be saved in **models** directory with the name *{SubjectID}_{ROI}.mat*.

Then when all decoders are trained (total 40), you can run the *PredictFeatures* script
Predicted features, will be saved in **results** folder with the name *Predicted_Features.mat*.

Then, you can run the noise matching code *EstimateMatchedNoise*
Noise matched features and correlations, will be saved in **results** folder with the name *Feature_Correlation.mat*.

Lastly, you can run the *PlotFeatureGain* script to create the figure showing representative feature correlations and feature gains. You can change the representative feature subjects and layers by changing the *rep_subject* and *rep_layer* variables in the script.

