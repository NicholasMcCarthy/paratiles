%
% Input: A block_struct object, part of the blockproc command
% Output: Class prediction
% Usage:
%           fun = @(block_struct) TileClassifier(block_struct); 
%           G = blockproc(I, [N,M], fun);

% Author: Nicholas McCarthy (nicholas.mccarthy@gmail.com)
% Created: 09-04-2013
% Updated: 09-04-2013

function [ PRED ] = TileClassifier( block_struct , model)

tic;
im_rgb = block_struct.data;                 % Assume image starts in RGB
im_lab = rgb2cielab(im_rgb);                % Convert to CIEL*a*b* format

[X Y Z]= size(im_rgb);                  % Tile dimensions

% Check image parameters (dimensions, etc)

%%%%%%%%%%%%%%%%%%%%%%
% Feature Extraction %
%%%%%%%%%%%%%%%%%%%%%%

% RGB Colour features
RGB_histogram_features = extract_histogram_features(im_rgb, [16 32 64 128 256]); 

% LAB Colour features
LAB_histogram_features = extract_histogram_features(im_lab, [16 32 64 128 256]); 

% RGB Texture features
RGB_texture_features = extract_haralick_features(im_rgb, [8 16 32]);

% LAB Texture features
LAB_texture_features = extract_haralick_features(im_lab, [8 16 32]);


%% Construct feature vector
FV = horzcat( RGB_histogram_features, LAB_histogram_features, RGB_texture_features, LAB_texture_features );


% 

end

