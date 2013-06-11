% This is the main script for running feature extraction

% Author: Nicholas McCarthy (nicholas.mccarthy@gmail.com)
% Created: 27-05-2013
% Updated: 05-06-2013

%% Setup 
%--------
% Sets env vars, any other odds and ends

[data.images data.masks ] = get_image_files(env.image_dir); % env should be declared ..

%% Init
%--------
% Init vars for run

% Load classifier model (??? Not sure on best implementation of this. Think
% it would be wise to start with an assumption of parallel models

% Set tilesize for blockproc command

image_tilesize = [256 256];
mask_tilesize = [16 16];

D_size = 2079159;           %Number of obs in tiling of all 20 images at 256px^2 

% matlabpool local 3;       % Open matlab pool for parallel processing

disp('Ready!');

%% EXTRACT CLASS LABELS

% moved to gen_class_labels.m

% load '../datasets/256/class_labels.mat'
% load '../datasets/256/class_labels_summary.mat'
%% USING FEATUREEXTRACTOR 

clear FE;

%% FeatureExtractor using 1 feature on grayscale image

clear FE;

gs_image = imread('pout.tif');          % The image to extract features from

FE = FeatureExtractor(@(x) mean(mean(x)), {'mean'}); % Creating the FeatureExtractor object

FV = FE.ExtractFeatures(gs_image);              % Extracting features

mydataset = mymat2dataset(FV, FE.Features)       % Converting features and labels to dataset (for viewing)

%% FeatureExtractor using 3 features on RGB image

clear FE;

rgb_image = imread('hestain.png');

func1 = @(x) mean(mean(mean(x)));  % 3 means to get mean pixel value in all 3 channels .. (dumb example)
func2 = @(x) min(min(min(x)));
func3 = @(x) max(max(max(x)));

funcs = {func1, func2, func3};
labels = {'mean', 'min', 'max'};

FE = FeatureExtractor(funcs, labels);

FV = FE.ExtractFeatures(rgb_image);

mydataset = mymat2dataset(FV, labels)

%% FeatureExtractor using many Haralick features 

clear FE;
rgb_image = imread('hestain.png');

distances = [1 2 4];
numlevels = [8 16 32];

haralick_func = @(I) extract_haralick_features(I, 'NumLevels', numlevels, 'Distances', distances);
labels = label_haralick_features('Channels', {'R', 'G', 'B'}, 'NumLevels', numlevels, 'Distances', distances, 'UseStrings', true);

FE = FeatureExtractor(haralick_func, labels);

FV = FE.ExtractFeatures(rgb_image);

mydataset = mymat2dataset(FV, labels)


%% FeatureExtractor using Haralick + Channel Statistics features

clear FE;
rgb_image = imread('hestain.png');

distances = [1 2 4];
numlevels = [8 16 32];

haralick_func = @(I) extract_haralick_features(I, 'NumLevels', numlevels, 'Distances', distances);
haralick_labels = label_haralick_features('Channels', {'R', 'G', 'B'}, 'NumLevels', numlevels, 'Distances', distances, 'UseStrings', true);

histogram_func = @(I) extract_histogram_features(I, 'NumLevels', numlevels); % same numlevels as haralick features
histogram_labels = label_histogram_features('Channels', {'R', 'G', 'B'}, 'NumLevels', numlevels, 'UseStrings', true);

functions = {haralick_func histogram_func};
labels = {haralick_labels{:} histogram_labels{:}};

FE = FeatureExtractor(functions, labels);

FV = FE.ExtractFeatures(rgb_image);

mydataset = mymat2dataset(FV, labels)


%% FeatureExtractor using Haralick + CICM + Histogram features

clear FE;
rgb_image = imread('hestain.png');

distances = [1 2 4 8];
numlevels = [16 32 64];

haralick_func = @(I) extract_haralick_features(I, 'NumLevels', numlevels, 'Distances', distances);
haralick_labels = label_haralick_features('Channels', {'R', 'G', 'B'}, 'NumLevels', numlevels, 'Distances', distances, 'UseStrings', true);

% PC = PixelClassifer; % Should move this to the same path .. 
cicm_func = @(I) PC.GetAllFeatures(I);
cicm_labels = PC.GetAllFeatureLabels;

histogram_func = @(I) extract_histogram_features(I, 'NumLevels', numlevels); % same numlevels as haralick features
histogram_labels = label_histogram_features('Channels', {'R', 'G', 'B'}, 'NumLevels', numlevels, 'UseStrings', true);

functions = {haralick_func cicm_func histogram_func};
labels = {haralick_labels{:} cicm_labels{:} histogram_labels{:}};

FE = FeatureExtractor(functions, labels);

FV = FE.ExtractFeatures(rgb_image);

mydataset = mymat2dataset(FV, labels)


%% FeatureExtractor + blockproc


% SETTING UP IMAGE 

clear FE;
rgb_image = imread('hestain.png');
rgb_image = repmat(rgb_image, 10);  % Make the image a lot bigger, just for funsies

% SET FUNCTION PARAMETERS (HARALICK AND HISTOGRAM FEATURES)

distances = [1 2 4 8];
numlevels = [16 32 64];

% CREATE FUNCTION HANDLES AND CORRESPONDING LABEL VECTORS

haralick_func = @(I) extract_haralick_features(I, 'NumLevels', numlevels, 'Distances', distances);
haralick_labels = label_haralick_features('Channels', {'R', 'G', 'B'}, 'NumLevels', numlevels, 'Distances', distances, 'UseStrings', true);

% PC = PixelClassifer; % Should move this to the same path .. 
cicm_func = @(I) PC.GetAllFeatures(I);
cicm_labels = PC.GetAllFeatureLabels;

histogram_func = @(I) extract_histogram_features(I, 'NumLevels', numlevels); % same numlevels as haralick features
histogram_labels = label_histogram_features('Channels', {'R', 'G', 'B'}, 'NumLevels', numlevels, 'UseStrings', true);


% CREATE FEATUREEXTRACTOR OBJECT

functions = {haralick_func cicm_func histogram_func};
labels = {haralick_labels{:} cicm_labels{:} histogram_labels{:}};

FE = FeatureExtractor(functions, labels);
 
% CREATE FEATUREEXTRACTOR HANDLE W/ SHIFTDIM FOR BLOCKPROC 
func_fe1 = @(block_struct) shiftdim(FE.ExtractFeatures(block_struct.data), -1); 
func_fe2 = FE.BlockProcHandle;

tilesize = 256;

fv1 = blockproc(rgb_image, [tilesize tilesize], func_fe1);  
fv1 = reshape(fv, size(fv, 1) * size(fv, 2), size(fv, 3)); % Previous examples just had single rows returned, this is a matrix so requires reshaping
mydataset1 = mymat2dataset(fv, labels); % FE.Features or labels 

fv2 = blockproc(rgb_image, [tilesize tilesize], func_fe2);  
fv2 = reshape(fv, size(fv, 1) * size(fv, 2), size(fv, 3)); % Previous examples just had single rows returned, this is a matrix so requires reshaping
mydataset2 = mymat2dataset(fv, labels); % FE.Features or labels 


%% Extracting Haralick Features

% Example Usage (single image, grayscale)
% 
%  I = imread('pout.tif');
%  numlevels = [8 16 32 64];
%  distances = [1 2 4 8];
%  feature_vector = extract_haralick_features(I, numlevels, distances)
%  feature_labels = label_haralick_features({'GS'}, numlevels, distances, false)
%  % Channel labels must be specified manually for labeling 
%  mydataset = mymat2dataset(feature_vector, feature_labels);

% Example Usage (blockproc, RGB)

% I_path = strcat(pwd, '/test_rgb_image.jpeg');
% tilesize = 16;
% numlevels = [8 16 32 64];
% distances = [1 2 4 8];
% 
% % shiftdim is used to move the feature vector of each tile into Z-dim
% func_haralick = @(block_struct) shiftdim(extract_haralick_features(block_struct.data, numlevels, distances), -1); 
% 
% fv = blockproc(I_path, [tilesize tilesize], func_haralick);
% 
% fv = reshape(fv, size(fv, 1) * size(fv, 2), size(fv, 3));   % reshape the matrix returned from blockproc to a feature vector form
% 
% fv_labels = label_haralick_features({'R', 'G', 'B'}, numlevels, distances);
% 
% mydataset = mymat2dataset(fv, fv_labels);


%

%% EXTRACT GABOR FEATURES


%% Tidy
%--------
% Post processing clean up





%% Roughwork area
