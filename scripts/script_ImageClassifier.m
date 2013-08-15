% Script for creating and testing an ImageClassifier object


images = getFiles(env.training_image_dir, 'Wildcard', '.scn');

%% Load TIS-CAN_HISTOGRAM model object

import weka.core.*;

image_path = images{1};
model_path = [env.root_dir '/models/model_NaiveBayes_TIS-CAN_HISTOGRAM.mat'];

S = unpackTiff(image_path, [8 10], 1);
disp('Finished unpacking .. ');

% L = unpackTiff(image_path, 8, 1);


%% Get bounding box for larger image region ..

I = imread(S{2}); % Read the smaller image

level = graythresh(I);

T = im2bw(I, level);
T1 = T; % reverse black and white values

T2 = imopen(T1, strel('disk', 7));
T3 = ~imfill(~T2, 8, 'holes');
% T3 = imerode(T3, strel('disk', 5));

% figure;
subplot(141), imshow(I), title('Original image');
subplot(142), imshow(T1), title('Thresholded image');
subplot(143), imshow(T2), title('imopen(disk, 7)');
subplot(144), imshow(T3), title('imfill(8 conn, "holes"');

%% Get connected components

CC = bwconncomp(~T3);
CC_orig = CC;

min_size = 256 * 256; % Number of pixels in at least one tile

% Remove areas that are smaller than the tilesize .. 
for i = fliplr(1:CC.NumObjects) % Avoids resizing array while working on it ..
    if length(CC.PixelIdxList{i}) < min_size
        CC.PixelIdxList(i) = [];     % remove cell entry 
        CC.NumObjects = CC.NumObjects - 1
    end
end

L = uint8(zeros(size(T)));

for i = 1:CC.NumObjects
   L(CC.PixelIdxList{i}) = i; 
end

cmap = jet(CC.NumObjects+1); % +1 for background ..
figure, imshow(L, cmap), title('Selected ROIs for bounding box');

%% Get bounding box coordinates

check_dimensions = @(W, H, w, h) W / H == w / h;    % Checks images have same proportions .. 
check_scale_factor = @(W, H, w, h) W / w == H / h;  % Checks image dimensions scale linearly ..

% Get region props 
RP = regionprops(L); % Are now the bounding box coordinates for the small resolution image

% Selecting just one ROI ..

ROI_idx = 4;
ROI = RP(ROI_idx);
coords = ROI.BoundingBox;

ROI_bw = false(size(T2));
ROI_bw(CC.PixelIdxList{ROI_idx}) = 1; 

coords = round(coords);

% S_pr_coords = {[ coords(4) coords(2)], [coords(1) coords(3)]};
% I_roi = imread(S{2}, 'PixelRegion', S_pr_coords); 

figure, imshow(ROI_bw), title('Selected ROIs for bounding box');
% figure, imshow(I_roi);


%%
% Read image info
L_info = imfinfo(S{1});
S_info = imfinfo(S{2});

% Check image scales correctly and has correct dimensions
[Lw Lh Sw Sh] = deal(L_info.Width, L_info.Height, S_info.Width, S_info.Height);

if ~check_dimensions(Lw, Lh, Sw, Sh) || ~check_scale_factor(Lw, Lh, Sw, Sh);
    disp('Ruh roh, error with image dimensions..');
end



% Get scale factor, scale bounding box coordinates .. 
scaleFactor = Lw / Sw;
scoords = scaleCoordinates(coords, scaleFactor)

% idea :
% Push coordinates out so its a multiple of tilesize (256) .. 

% ROI area
area = (scoords(3) - scoords(1)) * (scoords(2) - scoords(4)); 
% ROI dimensions
[ROI_x ROI_y] = deal( (scoords(3) - scoords(1)), ( scoords(2) - scoords(4) ) ) ;

fprintf('Selected ROI\nArea: %d\nDimensions: %d x %d\n', area, ROI_x, ROI_y);

%% Reading ROI area .. 

rows = [scoords(4) scoords(2)]; %i.e. Y coordinates
cols = [scoords(1) scoords(3)]; % i.e. X coordinates


pr_coords = {rows, cols};
tic
I = imread(S{1}, 'PixelRegion', pr_coords);
toc
figure, imshow(I);


%% Rescaling image coordinates



%% Sampling image

%% Loading model, functions, feature extractor etc ..

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