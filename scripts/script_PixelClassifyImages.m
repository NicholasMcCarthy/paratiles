% This script will convert a set of images using the pixel classifier

% Author: Nicholas McCarthy
% Date created: 03/07/2013

%% SETUP

images = getFiles(env.image_dir, 'Suffix', '.tif', 'Wildcard', '.9.tif');          % Wildcard so it selects the large .SCN layer image

output_dir = [env.image_dir 'pixel-classified/']

tilesize = 1024; % Irrelevant for this purpose, this seems reasonable 

% Ensure your local setup allows this ..
matlabpool local 3

%% Set up Pixel Classifier

PC = PixelClassifier;
PC.ScaleOutput = 1;     % Scales index values to [0 255] 

cls_image = @(I) PC.ClassifyImage(I.data)

%% RUN BLOCKPROC AND PIXEL-CLASSIFY IMAGES

% profile on;
   
for i = 1:length(images)
    
    imagepath = images{i};
    
    % Concat output_dir with regex replaced filename (8.tif -> PC8.tif) 
    outputpath = [output_dir regexprep(fliplr(strtok(fliplr(images{1}), '/')), '.8.tif', '.PC8.tif')]   % .. don't ask 
    fprintf('Current Image: %s \n', imagepath);
    
    % Blockproc
    tic
    blockproc(imagepath, [tilesize tilesize], cls_image, 'Destination', outputpath);
    toc
    
end

% profile off;
% profile report;

%% CLEANUP

sendmail('nicholas.mccarthy@gmail.com', 'Processing complete', 'Adios');

%%