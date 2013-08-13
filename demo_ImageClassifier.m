%% This script will serve as a demo for the TileClassifier and
% ImageClassifier objects. 


%% ImageClassifier
% How to setup an ImageClassifier object and examples of using it to
% classify an entire image and display the resulting heatmap / likelihood
% scene (for multiple classes).

ModelFilepath = 'models/model_NaiveBayes_TIS-CAN_HISTOGRAM.mat';

loaded = load(ModelFilepath);

model = loaded.model;
clear loaded;

%% TileClassifier
% How to setup a TileClassifier object and examples of using it to classify
% a single tile


% Setting up Feature Extractor
numlevels = [16 32 64];
distances = [1 2 4];

histogram_func_rgb = @(I) extract_histogram_features(I, 'NumLevels', numlevels);
histogram_labels_rgb = label_histogram_features('Channels', {'R', 'G', 'B'}, 'NumLevels', numlevels, 'Prefix', 'rgb', 'UseStrings', true);

haralick_func_rgb = @(I) extract_haralick_features(I, 'NumLevels', numlevels, 'Distances', distances);
haralick_labels_rgb = label_haralick_features('Channels', {'R', 'G', 'B'}, 'NumLevels', numlevels, 'Distances', distances, 'Prefix', 'rgb', 'UseStrings', true);

functions = { histogram_func_rgb  haralick_func_rgb  };
labels       = [ histogram_labels_rgb  haralick_labels_rgb ];

myfeatureextractor = FeatureExtractor(functions, labels);

% Setting up model
% Previously trained, saved to disk

ModelFilepath = 'tile.classifier/models/model.mat';

loaded = load(ModelFilepath);

mymodel = loaded.NB;
clear loaded;

TC = TileClassifier(mymodel, myfeatureextractor, 'Description', 'Uses histogram+haralick rgb features');
