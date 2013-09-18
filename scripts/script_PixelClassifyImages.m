% This script will convert a set of images using the pixel classifier

% Author: Nicholas McCarthy
% Date created: 03/07/2013

%% SETUP

images = getFiles(env.image_dir, 'Suffix', '.tif', 'Wildcard', '.8.tif');          % Wildcard so it selects the large .SCN layer image

output_dir = [env.image_dir 'pixel-classified/'];

tilesize = 1024; % Irrelevant for this purpose, this seems reasonable 

% Ensure your local setup allows this ..
if matlabpool('size') == 0
    matlabpool local 4
end

%% Set up Pixel Classifier

PC1 = PixelClassifier; % Default NB model 

PC2 = PixelClassifier('models/NB-PixelClassifier-CD.mat'); % Colour Deconvolution model ..

% PC.NucleiProcSize = 100; % Smaller than default as the .9.tifs are 20x magnification

%% Run pixelclassifier on test images

test_images = getFiles([env.root_dir '/test.images/'], 'Suffix', 'tif');

for i = 1:length(images)
    
    image_path = test_images{i};
    
    I = imread(image_path);
    
    I = I(:,:, 1:3);
    
    I_cd = ColourDeconvolve(I);
    
    G = PC1.ClassifyImage(I);
    G2 = PC1.ProcessImage(G);
    
    H = PC2.ClassifyImage(I_cd);
    
    cmap = jet(5);
    
    subplot(221), imshow(I);
    subplot(222), imshow(I_cd);
    subplot(223), imshow(G, cmap);
    subplot(224), imshow(G2, cmap);
    
end


%% RUN BLOCKPROC AND PIXEL-CLASSIFY IMAGES

% Function handle for blockproc
cls_image = @(I) PC.ClassifyImage(I.data)

% profile on;
   
for i = 1:length(images)
    
    imagepath = images{i};
    
    % Concat output_dir with regex replaced filename (8.tif -> PC8.tif) 
    outputpath = [output_dir regexprep(fliplr(strtok(fliplr(images{i}), '/')), '.8.tif', '.PC8.tif')]   % .. don't ask 
    fprintf('Current Image: %s \n', imagepath);
    
    % Blockproc
    tic
    blockproc(imagepath, [tilesize tilesize], cls_image, 'Destination', outputpath);
    toc
    
    sendmail('nicholas.mccarthy@gmail.com', strcat(num2str(i), ' : processing complete'), strcat(imagepath, ' has been pixel classified, booyah!'));
    
end

% profile off;
% profile report;

%% CLEANUP

sendmail('nicholas.mccarthy@gmail.com', 'Processing complete', 'Adios');

%%