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

load '../datasets/256/class_labels.mat'
load '../datasets/256/class_labels_summary.mat'


%% EXTRACT HARALICK FEATURES

numlevels = [8 16 32 64];       % Quantization levels for GLCM 
distances = [1 2 4 8];          % Pixel distances for GLCM

% Generate column headers for haralick features using same arguments
feature_labels = label_haralick_features({'R', 'G', 'B'}, numlevels, distances); 

% Call to haralick function. Shiftdim to move features into 3rd dim
func_haralick = @(block_struct) shiftdim(extract_haralick_features(block_struct.data, numlevels, distances), -1)


fresults = struct();

for i = 1:20 %length(images); % Last image and mask need to be added and processed
   
    image_filepath = strcat(env.image_dir, data.images(i).name);
    mask_filepath = strcat(env.image_dir, data.masks(i).name);

    disp(image_filepath);
    G = blockproc(image_filepath, image_tilesize, func_haralick, 'PadPartialBlocks', true); 
    
    [X Y Z] = size(G);       % Get image feature vector dimensions ..
    
    G = reshape(G, X*Y, Z);  % Reshape to feature vector format .. 
    
    fresults(i).image = image_filepath;
    fresults(i).rows = G;
    toc
end

% Generate column headers for haralick features using same arguments
feature_labels = label_haralick_features({'GS'}, numlevels, distances); 


% Create dataset object

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


%% EXTRACT SHAPE / CICM FEATURES

PC = PixelClassifier();         % PixelClassifier class

image_path = strcat(pwd, '/test_rgb_image.jpeg'); % Features won't make any sense with this image, but here goes
I = imread(image_path);                        
tilesize = 16;
numlevels = [8 16 32 64];
distances = [1 2 4 8];
 
func_cicm = @(block_struct) shiftdim(PC.GetAllFeatures(block_struct.data), -1); 
 
fv = blockproc(I, [tilesize tilesize], func_cicm);  % image_path not working here ??

fv = reshape(fv, size(fv, 1) * size(fv, 2), size(fv, 3));   % reshape the matrix returned from blockproc to a feature vector form
 
fv_labels = PC.GetAllFeatureLabels(); 
 
mydataset = mymat2dataset(fv, fv_labels);


%% EXTRACT GABOR FEATURES


%% Tidy
%--------
% Post processing clean up





%% Roughwork area
