% This is the main script for running feature extraction

% Author: Nicholas McCarthy (nicholas.mccarthy@gmail.com)
% Created: 27-05-2013
% Updated: 11-06-2013

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

clear FE;

% SETTING UP IMAGE 
rgb_image = imread('hestain.png');
rgb_image = repmat(rgb_image, 10);  % Make the image a lot bigger, just for funsies (and also for blockproc)

% SET FUNCTION PARAMETERS (HARALICK AND HISTOGRAM FEATURES)
distances = [1 2 4 8];
numlevels = [16 32 64];

disp('Size of image:');
size(rgb_image)

disp('Setting up FeatureExtractor');
tic
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
func_fe = FE.BlockProcHandle;

toc

tilesize = 256;
disp('Running blockproc');
tic;
FV = blockproc(rgb_image, [tilesize tilesize], func_fe);  
toc

disp('Converting to dataset');
tic;
FV = reshape(FV, size(FV, 1) * size(FV, 2), size(FV, 3));   % Previous examples just had single rows returned, this is a matrix so requires reshaping
mydataset = mymat2dataset(FV, labels);                      % FE.Features or labels 
toc

disp('Writing to output file:');
% WRITE DATASET TO COLUMNS OF CSV FILES
test_folder = strcat(env.dataset_dir, 'fe_demo/')       % Put files into folder fe_demo in the set dataset_dir
writeDatasetToCSV(mydataset, test_folder);

%% EXTRACT GABOR FEATURES


%% Tidy
%--------
% Post processing clean up





%% Roughwork area
