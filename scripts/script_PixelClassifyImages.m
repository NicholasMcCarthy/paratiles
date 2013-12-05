% This script will convert a set of images using the pixel classifier

% Author: Nicholas McCarthy
% Date created: 03/07/2013
% Last updated: 11/10/2013

%% SETUP


images_set1 = getFiles(env.training_image_dir, 'Wildcard', '.scn');
images_set2 = getFiles(env.validation_image_dir, 'Wildcard', '.tiff');

% selected_images = [ images_set1([5 8 18]) ; images_set2([6 21 32]) ]

selected_images = [ images_set1 ; images_set2 ];

if matlabpool('size') == 0
    matlabpool local 4;
end

tilesize = 512; % Irrelevant for this purpose, this seems reasonable 

% Ensure your local setup allows this ..
if matlabpool('size') == 0
    matlabpool local 4
end

% Set up Pixel Classifier
PC = PixelClassifier; % Default NB model 
% PC2 = PixelClassifier('models/NB-PixelClassifier-CD.mat'); % Colour Deconvolution model ..

%% Main

% Function handle for blockproc
pixelClassify = @(I) PC.ClassifyImage(I.data);

for i = 1:length(selected_images);
   
    image_path = selected_images{i};
    
    disp(image_path);

    % Determine filetype (.scn or .tiff)
    file_type = fliplr(strtok(fliplr(image_path), '.'));

    % Use different IFD depending on filetype
    if strcmp(file_type,'scn')
        use_IFD = 8;
    elseif strcmp(file_type, 'tiff')
        use_IFD = 1;
    end
    
    % Unpack base image, get path to selected IFD
    unpacked_images = unpackTiff(image_path, use_IFD, true)
    
    big_image = unpacked_images{1};
    
    output_image = regexprep(image_path, [ '.' file_type], '-pc.tif');
    
    blockproc(big_image, [512 512], pixelClassify, 'Destination', output_image);
    
    repackTiff(image_path);
    
    sendmail('nicholas.mccarthy@gmail.com', 'Pixel classification script', ['Beep boop: ' image_path]);
    
end


%% Run algorithm on pixel-classified images

pc_images = getFiles(env.training_image_dir, 'Wildcard', 'pc.tif');

processImage = @(I) PC.ProcessImage(I.data);

for i = 1:length(pc_images)
    
    image_path = pc_images{i};
    
    image_info = imfinfo(image_path);
    disp(image_path);
    
    output_image = regexprep(image_path, '-pc.tif', '-pc_processed.tif');
    
    fprintf('Writing output image to %s \n', output_image);
    
    blockproc(image_path, [8192 8192], processImage, 'Destination', output_image);
end
