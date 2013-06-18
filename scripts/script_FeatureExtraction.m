% This script will do some Feature Extraction on a set of images

% Author: Nicholas McCarthy
% Date created: 11/06/2013
% Date run: x/x/x

%% DETAILS

% Images processed

% Output files

% Features extracted

% 

%% SETUP

images = getFiles(env.image_dir, 'Suffix', '.tif', 'Wildcard', '.8.');          % Wildcard so it selects the large .SCN layer image
masks = getFiles(env.image_dir, 'Suffix', '.tif', 'Wildcard', 'mask-PT.gs');
 
output_dir = strcat(env.dataset_dir, 'fe.', date, '/');

if ~exist(output_dir, 'dir')        % If no directory for this date
    fprintf('Output directory %s does not exist. Creating it.\n', output_dir);
    mkdir(output_dir);               % Create it .. 
end

tilesize = 256;

D_length = 2079159;         % Preallocating number of rows when blockproc'ing 20 initial PCRC images. 
        
%% INIT Full feature set
% 
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
% 
% % matlabpool

%% Histogram feature set

numlevels = [16 32 64];

% RGB Features
histogram_func_rgb = @(I) extract_histogram_features(I, 'NumLevels', numlevels);
histogram_labels_rgb = label_histogram_features('Channels', {'R', 'G', 'B'}, 'NumLevels', numlevels, 'Prefix', 'rgb', 'UseStrings', true);

% CIELab Features
histogram_func_lab = @(I) extract_histogram_features(rgb2cielab(I), 'NumLevels', numlevels);
histogram_labels_lab = label_histogram_features('Channels', {'L', 'A', 'B'}, 'NumLevels', numlevels, 'Prefix', 'lab', 'UseStrings', true);

functions = {histogram_func_rgb histogram_func_lab };
labels = [histogram_labels_rgb histogram_labels_lab];

FE = FeatureExtractor(functions, labels);

func_fe = FE.BlockProcHandle;

%% RUN

profile on;

data = zeros(D_length, length(FE.Features));
row_idx = 1;

for i = 1:length(images)
    
    imagepath = images{i};
    fprintf('Current Image: %s \n', imagepath);
    
    FV = blockproc(imagepath, [tilesize tilesize], func_fe);
    
    FV = reshape(FV, size(FV, 1) * size(FV, 2), size(FV, 3));   
    
    row_end = row_idx + size(FV,1)-1;       % End row of new data to be allocated
    disp('eh?');
    data(row_idx:row_end ,:) = FV;          % Allocate new data ..
    disp('bar');
    row_idx = row_idx + length(FV);         % Update row_idx 
    
    
    title = strcat('Matlab Processing:  ', num2str(i), '/', num2str(length(images)));
    sendmail('nicholas.mccarthy@gmail.com', title, 'Aloha');
    
end

profile off;
profile report;

%% OUTPUT 

writeMatrixToCSV(data, FE.Features, output_dir);


%% CLEANUP

sendmail('nicholas.mccarthy@gmail.com', 'Processing complete', 'Adios');

%%