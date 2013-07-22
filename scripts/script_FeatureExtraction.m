% This script will do some Feature Extraction on a set of images

% Author: Nicholas McCarthy
% Date created: 11/06/2013
% Date run: x/x/x

%% DETAILS

% Images processed

% Output files

% Features extracted

% 
env.temp_dir = [pwd '\temp\'];

%% SETUP

images = getFiles(env.image_dir, 'Suffix', '.tif', 'Wildcard', '.8.tif');          % Wildcard so it selects the large .SCN layer image
masks = getFiles(env.image_dir, 'Suffix', '.tif', 'Wildcard', 'mask-PT.gs');

WILDCARD = 'fe.HISTOGRAM'; % date;

output_dir = strcat(env.dataset_dir, WILDCARD, '-', date, '/');

if ~exist(output_dir, 'dir')        % If no directory for this date
    fprintf('Output directory %s does not exist. Creating it.\n', output_dir);
    mkdir(output_dir);               % Create it .. 
end

tilesize = 256;
    
D_length = 2079159;         % Preallocating number of rows when blockproc'ing 20 initial PCRC images. 
        
%% INIT Full feature set
% % 
% profile on;
% 
% distances = [1 2 4];
% numlevels = [16 32 64];
% 
% haralick_func_rgb = @(I) extract_haralick_features(I, 'NumLevels', numlevels, 'Distances', distances);
% haralick_labels_rgb = label_haralick_features('Channels', {'R', 'G', 'B'}, 'NumLevels', numlevels, 'Distances', distances, 'Prefix', 'rgb', 'UseStrings', true);
% 
% histogram_func_rgb = @(I) extract_histogram_features(I, 'NumLevels', numlevels); % same numlevels as haralick features
% histogram_labels_rgb = label_histogram_features('Channels', {'R', 'G', 'B'}, 'NumLevels', numlevels, 'Prefix', 'rgb', 'UseStrings', true);
% 
% haralick_func_lab = @(I) extract_haralick_features(rgb2cielab(I), 'NumLevels', numlevels, 'Distances', distances');
% haralick_labels_lab = label_haralick_features('Channels', {'L', 'A', 'B'}, 'NumLevels', numlevels, 'Distances', distances, 'Prefix', 'lab', 'UseStrings', true);
% 
% histogram_func_lab = @(I) extract_histogram_features(rgb2cielab(I), 'NumLevels', numlevels); % same numlevels as haralick features
% histogram_labels_lab = label_histogram_features('Channels', {'L', 'A', 'B'}, 'NumLevels', numlevels, 'Prefix', 'lab', 'UseStrings', true);
% 
% functions = {haralick_func_rgb haralick_func_lab histogram_func_rgb histogram_func_lab};
% labels = {haralick_labels_rgb{:} haralick_labels_lab{:} histogram_labels_rgb{:} histogram_labels_lab{:}};
% 
% FE = FeatureExtractor(functions, labels);
% 
% func_fe = FE.BlockProcHandle;
% 
% profile off;
% profile report;


% Ensure your local setup allows this ..
if matlabpool('size') == 0
    matlabpool local 4
end
    
%% Histogram feature set

% numlevels = [16 32 64];
numlevels = [16 32];
distances = [1 2 4];

% Histogram features
histogram_func_rgb = @(I) extract_histogram_features(I, 'NumLevels', numlevels);
histogram_labels_rgb = label_histogram_features('Channels', {'R', 'G', 'B'}, 'NumLevels', numlevels, 'Prefix', 'rgb', 'UseStrings', true);

histogram_func_lab = @(I) extract_histogram_features(rgb2cielab(I), 'NumLevels', numlevels);
histogram_labels_lab = label_histogram_features('Channels', {'L', 'A', 'B'}, 'NumLevels', numlevels, 'Prefix', 'lab', 'UseStrings', true);

% Haralick features
haralick_func_rgb = @(I) extract_haralick_features(I, 'NumLevels', numlevels, 'Distances', distances);
haralick_labels_rgb = label_haralick_features('Channels', {'R', 'G', 'B'}, 'NumLevels', numlevels, 'Distances', distances, 'Prefix', 'rgb', 'UseStrings', true);

haralick_func_lab = @(I) extract_haralick_features(rgb2cielab(I), 'NumLevels', numlevels, 'Distances', distances);
haralick_labels_lab = label_haralick_features('Channels', {'L', 'A', 'B'}, 'NumLevels', numlevels, 'Distances', distances, 'Prefix', 'lab', 'UseStrings', true);

% CICM Features
PC = PixelClassifier;
cicm_func = @(I) PC.GetAllFeatures(I);
cicm_labels = lower(PC.GetAllFeatureLabels);


% Entropy check
entropy_func = @(I) entropy(I);
entropy_label = {'entropy'};

%========================

functions = {  histogram_func_rgb   } % haralick_func_lab };
labels = [  histogram_labels_rgb   ]; %haralick_labels_lab ];

FE = FeatureExtractor(functions, labels);

func_fe = FE.BlockProcHandle;

%========================


%% RUN

% profile on;
% data = zeros(D_length, length(FE.Features));  % Pre-allocate on an image
% by image basis rather than the entire set .. Running out of memory. 

% row_idx = 1;
   
for i = 1:length(images)
    
    imagepath = images{i};
    imageinfo = imfinfo(images{i});
 
    fprintf('Current Image: %s \n', imagepath);
    
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
    
%     % There is a single data struct for each image, so the lines below are
%     % not needed .. 
    %row_end = row_idx + size(FV,1)-1;       % End row of new data to be allocated
    %data(row_idx:row_end ,:) = FV;          % Allocate new data ..
    %row_idx = row_idx + length(FV);         % Update row_idx 

    data = FV;
%     
%     message = num2str(any(FV));
%     title = strcat('Matlab Processing:  ', num2str(i), '/', num2str(length(images)));
%     sendmail('nicholas.mccarthy@gmail.com', title, message);

    % save 'data' struct as .mat file on an image by image basis
    matfile = strcat(env.temp_dir, 'image-', num2str(i), '_temp_data.mat');
    save(matfile, 'data');
    
end

% profile off;
% profile report;

%% OUTPUT 

% Generate single column csvs with column names as filenames
for h = 1:length(FE.Features)
    filename = strcat(output_dir, FE.Features{h}, '.csv');
    fid = fopen(filename, 'w+');
    fclose(fid);
end

for i = 1:length(images)  % for each image
    
    fprintf('image %d \n', i);
    
    matfile = strcat(env.temp_dir, 'image-', num2str(i), '_temp_data.mat');
    load(matfile);                                                                                                      % loads 'data' struct
    
    for c = 1:size(data, 2)                                                                                         % Append each column
        
        filename = strcat(output_dir, FE.Features{c}, '.csv');                                       % Column filename 
        fid = fopen(filename, 'a');                                                                               % Open to append
        
        for r = 1:size(data, 1)                                                                                     %  For each row in 'data'
            
            fprintf(fid,   '%0.9f\n', data(r, c));                                                               % append it to file
            
        end
        fclose(fid);
        
    end
  
end


% This function works for a single data matrix, not appending to multiple
% ones :( 
% writeMatrixToCSV(data, FE.Features, output_dir);

%% CLEANUP

sendmail('nicholas.mccarthy@gmail.com', 'Processing complete', 'Adios');

%%