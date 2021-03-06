﻿% This script will do some Feature Extraction on a set of images

% Author: Nicholas McCarthy
% Date created: 11/06/2013
% Date run: x/x/x

%% SETUP

images = getFiles(env.image_dir, 'Suffix', '.tif', 'Wildcard', '.8.tif');          % Wildcard so it selects the large .SCN layer image
% masks = getFiles(env.image_dir, 'Suffix', '.tif', 'Wildcard', 'mask-PT.gs');

WILDCARD = 'fe.OBJECT'; % date;

% output_dir = strcat(env.dataset_dir, WILDCARD, '-', date, '/');

% if ~exist(output_dir, 'dir')        % If no directory for this date
%     fprintf('Output directory %s does not exist. Creating it.\n', output_dir);
%     mkdir(output_dir);               % Create it .. 
% end

temp_dir = [env.root_dir '/temp_GLCV-D1_NL16_LAB/'];

tilesize = 256;
    
D_length = 2079159;         % Preallocating number of rows when blockproc'ing 20 initial PCRC images. 

% Ensure your local setup allows this ..
if matlabpool('size') == 0
    matlabpool local 4
end

    
%% DEFINE FEATURE SETS TO BE EXTRACTED

% numlevels = [16 32 64];
numlevels = [32]; %32];
distances = [1 2]; %4];

%--------- MISSING FEATURE SETS --- % 

% haralick_func_rgb1 = @(I) extract_haralick_features(I, 'NumLevels', [16 32], 'Distances', [1 2]);
% haralick_labels_rgb1 = label_haralick_features('Channels', {'R', 'G', 'B'}, 'NumLevels', [16 32], 'Distances', [1 2], 'Prefix', 'rgb', 'UseStrings', true);
% 
% haralick_func_lab1 = @(I) extract_haralick_features(rgb2cielab(I), 'NumLevels', [64], 'Distances', [4]);
% haralick_labels_lab1 = label_haralick_features('Channels', {'L', 'A', 'B'}, 'NumLevels', [64], 'Distances', [4], 'Prefix', 'lab', 'UseStrings', true);
% 

% Histogram features
% histogram_func_rgb = @(I) extract_histogram_features(I, 'NumLevels', numlevels);
% histogram_labels_rgb = label_histogram_features('Channels', {'R', 'G', 'B'}, 'NumLevels', numlevels, 'Prefix', 'rgb', 'UseStrings', true);
% 
% histogram_func_lab = @(I) extract_histogram_features(rgb2cielab(I), 'NumLevels', [16 32 64]);
% histogram_labels_lab = label_histogram_features('Channels', {'L', 'A', 'B'}, 'NumLevels', [16 32 64], 'Prefix', 'lab', 'UseStrings', true);
% 
% % Haralick features
% haralick_func_rgb = @(I) extract_haralick_features(I, 'NumLevels', [64], 'Distances', [1 2 4]);
% haralick_labels_rgb = label_haralick_features('Channels', {'R', 'G', 'B'}, 'NumLevels', [64], 'Distances', [1 2 4], 'Prefix', 'rgb', 'UseStrings', true);
% 
% haralick_func_lab = @(I) extract_haralick_features(rgb2cielab(I), 'NumLevels', [16 64], 'Distances', [1 2 4]);
% haralick_labels_lab = label_haralick_features('Channels', {'L', 'A', 'B'}, 'NumLevels', [16 64], 'Distances', [1 2 4], 'Prefix', 'lab', 'UseStrings', true);

% GLCM Feature Vector

D = 1;
offsets =  [ 0 D ; -D D ; -D 0 ; -D -D ];      % Offsets for 0, 45, 90, 135 degree angles
graylimits = [0 255];                          % Default gray limits . .
numlevels = 16;                                 % Default number of bins

% Anon func for single channel
glcm_func_c = @(Ic) GLCMVector(Ic, 'Offsets', offsets, 'GrayLimits', graylimits, 'NumLevels', numlevels);
% Multi-channel anon func to consolidate 
glcm_func = @(I) [glcm_func_c(I(:,:,1)) glcm_func_c(I(:,:,2)) glcm_func_c(I(:,:,3)) ];
% Anon func to convert srgb2lab
glcm_func_cs = @(I) glcm_func(rgb2cielab(I));

glcm_labels = {};
channel_str = {'R', 'G', 'B'};

i = 1;
for c = 1:3
    for x = 1:numlevels
        for y = x:numlevels
            feature_label = sprintf('%c_D%i_NL%i_%i_%i', channel_str{c}, D, numlevels, x, y);
            glcm_labels{i} = feature_label;
            i = i +1;
        end
    end
end

% % CICM Features
% PC = PixelClassifier;
% cicm_func = @(I) PC.GetAllFeaturesv2(I);
% cicm_labels = lower(PC.GetAllFeatureLabelsv2);

% 
% 
% % Entropy check
% entropy_func = @(I) entropy(I);
% entropy_label = {'entropy'};

%========================

functions = { glcm_func }; 
labels = [  glcm_labels ]; %haralick_labels_lab ];

FE = FeatureExtractor(functions, labels);

func_fe = FE.BlockProcHandle;

%========================

%% RUN

% profile on;

for i = 2:length(images)
    
    imagepath = images{i};
    imageinfo = imfinfo(images{i});
 
    fprintf('%d] %s \n', i, imagepath);
    
    % Get number of blocks processed in this image
    numBlocks = ceil( (imageinfo.Width) / tilesize ) * ceil( (imageinfo.Height) / tilesize);
    
    % Pre-allocate 'data' struct
    data = zeros(numBlocks, length(FE.Features));
    
    % Blockproc
    tic
    
    FV = blockproc(imagepath, [tilesize tilesize], func_fe);
    
    mytime = toc;
    % Reshape from image to feature vector
    FV = reshape(FV, size(FV, 1) * size(FV, 2), size(FV, 3));   
    
    data = FV;

    % save 'data' struct as .mat file on an image by image basis
    matfile = strcat(temp_dir, 'image-', num2str(i), '_temp_data.mat');
    save(matfile, 'data');
    
    msg = sprintf('%s data written \n', matfile);
    title = sprintf('Feature Extraction: Image %i', i);
    sendmail('nicholas.mccarthy@gmail.com', title, msg);
end

disp('Done!');

% profile off;
% profile report;

%% OUTPUT 

output_dir = [env.root_dir '/datasets/GLCMVector_LAB_D1_NL64/']

% Generate single column csvs with column names as filenames
for h = 1:length(FE.Features)
    filename = strcat(output_dir, FE.Features{h}, '.csv');
    fid = fopen(filename, 'w+');
    fclose(fid);
end

linesWritten = 0;
columnsWritten = 0;
totalLines = 0;

for i = 1:length(images)                        % for each image
    
    fprintf('image %d \n', i);
    
    matfile = strcat(temp_dir, 'image-', num2str(i), '_temp_data.mat');
    load(matfile);                                                      % loads 'data' struct
    
    size(data)
    columnsWritten = 0;
    totalLines = totalLines + size(data, 1);

    for c = 1:size(data, 2)                                             % Append each column
        
        filename = strcat(output_dir, FE.Features{c}, '.csv');          % Column filename 
        fid = fopen(filename, 'a');                                     % Open to append
        
        for r = 1:size(data, 1)                                         %  For each row in 'data'
            
            fprintf(fid,   '%0.9f\n', data(r, c));                      % append it to file
            
            linesWritten = linesWritten + 1;
        end
        
        fclose(fid);
        
    end
    fprintf('%i lines written \n', linesWritten);
end

fprintf('Each csv file should have %i lines \n', totalLines);

% Verify number of lines per csv file

for h = 1:length(FE.Features)
    filename = strcat(output_dir, FE.Features{h}, '.csv');
    
    cmd = sprintf('grep -c ^$ %s', filename);
    
    [status result] = system(cmd);
    
    result = str2double(result);
    
    if result ~= 0
        fprintf('%s has %i empty lines .. \n', filename, result);
    end
end

disp('Finishing writing column csv files .. ')

% sendmail('nicholas.mccarthy@gmail.com', 'Finished writing CSV files ..', 'Adios');

% This function works for a single data matrix, not appending to multiple
% ones :( 
% writeMatrixToCSV(data, FE.Features, output_dir);

%% CLEANUP

sendmail('nicholas.mccarthy@gmail.com', 'Processing complete', 'Adios');

%%