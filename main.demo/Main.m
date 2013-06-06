% This is the main script for running CAD analysis
% Performs feature extraction, labeling, etc

% Author: Nicholas McCarthy (nicholas.mccarthy@gmail.com)
% Created: 09-04-2013
% Updated: 09-04-2013


%% Setup 
%--------
% Sets env vars, any other odds and ends

[data.images data.masks ] = get_image_files(env.image_dir); % env should be declared ..


%% Read 
% %--------
% % Reads in .SCN image or pre-split .TIFF image. The pre-split .TIFF should be the 9th image in .SCN tiff directory.
% 
% % Select the image to process
% [filename, pathname] = uigetfile( ...
%     {'*.jpeg;*.jpg;*.tif;*.tiff;*.scn;*.svs','Image filetypes (*.jpg, *.jpeg, *.tif, *.scn, *.svs)';
%      '*.jpg',  'JPEG Image (*.jpg)'; ...
%      '*.tif',  'TIFF Image (*.tiff)'; ...
%      '*.scn',  'Leica SCN Image (*.scn)'; ...
%      '*.svs',  'Aperio SVS Image (*.scn)'; ...
%      '*.*',  'All Files (*.*)'}, ...
%      'Pick a file', ...
%      'MultiSelect', 'on');
% 
% % Needs a handler switch for different filetypes. Set to TIFF currently.
% im_filename = [pathname,filename];
% T = Tiff(im_filename, 'r');

%% Init
%--------
% Init vars for run

% Load classifier model (??? Not sure on best implementation of this. Think
% it would be wise to start with an assumption of parallel models

% anonymous fun (hehe) to pass block_struct to TileClassifier
fun = @(block_struct) TileClassifier(block_struct); 

myfunc = @(block_struct) [label coverage] = @block_get_class_label(block_struct); 
myfunc = @block_get_class_label;
% Set tilesize for blockproc command 
tilesize = 256;

%% Run
%--------
% Run the tile processing and classification

for i = 1:19 %length(images);
    
    image_filepath = strcat(env.image_dir, data.images(i).name);
    mask_filepath = strcat(env.image_dir, data.masks(i).name);

    T = Tiff(image_filepath);
    M = Tiff(mask_filepath);
    
    G = blockproc(mask_filepath, [16 16], myfunc);
    
end


%% Tidy
%--------
% Post processing clean up