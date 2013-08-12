% Script for creating and testing an ImageClassifier object

%% Load TIS-CAN_HISTOGRAM model object

import weka.core.*;

image_path = [env.image_dir 'PCRC-BIMS_672-10S-B_B1-HE.8.tif'];
model_path = [env.root_dir '/models/model_NaiveBayes_TIS-CAN_HISTOGRAM.mat'];

% Load model
loaded = load(model_path);
model = loaded.model;
clear loaded

% Create FeatureExtractor 
numlevels = [16 32 64];

histogram_func_rgb = @(I) extract_histogram_features(I, 'NumLevels', numlevels);
histogram_labels_rgb = label_histogram_features('Channels', {'R', 'G', 'B'}, 'NumLevels', numlevels, 'Prefix', 'rgb', 'UseStrings', true);

functions   = { histogram_func_rgb      };
labels      = [ histogram_labels_rgb    ];

FE = FeatureExtractor(functions, labels);

IC = ImageClassifier(model, FE);

G = IC.predictionMap(image_path);

%% Create FeatureExtractor object

% These will be subject to change as more features are added .. 

numlevels = [16 32 64];
distances = [1 2]; %4];

% Histogram features
histogram_func_rgb = @(I) extract_histogram_features(I, 'NumLevels', [16 32 64]);
histogram_labels_rgb = label_histogram_features('Channels', {'R', 'G', 'B'}, 'NumLevels', [16 32 64], 'Prefix', 'rgb', 'UseStrings', true);

% histogram_func_lab = @(I) extract_histogram_features(rgb2cielab(I), 'NumLevels', [16 32 64]);
% histogram_labels_lab = label_histogram_features('Channels', {'L', 'A', 'B'}, 'NumLevels', [16 32 64], 'Prefix', 'lab', 'UseStrings', true);

% Haralick features
haralick_func_rgb = @(I) extract_haralick_features(I, 'NumLevels', [16 32], 'Distances', [1 2]);
haralick_labels_rgb = label_haralick_features('Channels', {'R', 'G', 'B'}, 'NumLevels', [16 32], 'Distances', [1 2], 'Prefix', 'rgb', 'UseStrings', true);

haralick_func_lab = @(I) extract_haralick_features(rgb2cielab(I), 'NumLevels', [32], 'Distances', [1 2]);
haralick_labels_lab = label_haralick_features('Channels', {'L', 'A', 'B'}, 'NumLevels', [32], 'Distances', [1 2], 'Prefix', 'lab', 'UseStrings', true);

% % CICM Features
PC = PixelClassifier;
cicm_func = @(I) PC.GetAllFeatures(I);
cicm_labels = lower(PC.GetAllFeatureLabels);

functions = { histogram_func_rgb haralick_func_rgb haralick_func_lab cicm_func }; % haralick_func_lab };
labels = [  histogram_labels_rgb haralick_labels_rgb haralick_labels_lab cicm_labels  ]; %haralick_labels_lab ];

FE = FeatureExtractor(functions, labels);

func_fe = FE.BlockProcHandle;

%% 

IC = ImageClassifier(model, FE);