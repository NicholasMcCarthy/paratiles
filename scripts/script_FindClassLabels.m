% This is the main script for getting class labels of tiles in a set of images

% Author: Nicholas McCarthy (nicholas.mccarthy@gmail.com)
% Created: 27-05-2013
% Updated: 27-05-2013


%% Setup 
%--------
% Sets env vars, any other odds and ends

data.images = getFiles(env.image_dir, 'Suffix', '.tif', 'Wildcard', '.8.tif');
data.masks = getFiles(env.image_dir, 'Suffix', '.tif', 'Wildcard', 'mask-PT.gs');

%% Init
%------

image_tilesize = [256 256];
mask_tilesize = [16 16];

if matlabpool('size') == 0
    matlabpool local 4;     % Open matlab pool for parallel processing
end

%% EXTRACT CLASS LABELS

% Gets label and percentage coverage of annotation region. 
func_labels = @(block_struct) shiftdim(get_class_label(block_struct.data), -1);

idx_labels = [];        % Assigned label
idx_coverage = [];      % Coverage of label
idx_filenames = {};     % Filename of obs.

for i = 1:20 
    
    disp(i); tic;
    mask_filepath = data.masks{i}; % Get mask filepath

    % Blockproc mask image to get class labels
    G = blockproc(mask_filepath, mask_tilesize, func_labels, 'PadPartialBlocks', true); 
   
    [X Y Z] = size(G);
    G = reshape(G, X*Y, Z);
     
    idx_labels = vertcat(idx_labels, G(:,1));   % grayscale int8 values for each class
    idx_filenames = vertcat(idx_filenames, cellstr(repmat(mask_filepath, length(G(:,1)), 1)));
    
    toc
    
    % convert class num values to labels  
end

%%

labeldata = struct('labels', idx_labels, 'filenames', idx_filenames);

save('labeldata.mat', 'labeldata');


%% 
% Converting uint8 values to string labels
interval = (255/8);

idx_labelsr = num2str(idx_labels);
idx_labelsr = cellstr(idx_labelsr);

idx_labelsr = regexprep(idx_labelsr, '28', 'G34');
idx_labelsr = regexprep(idx_labelsr, '56', 'G4');
idx_labelsr = regexprep(idx_labelsr, '85', 'G45');
idx_labelsr = regexprep(idx_labelsr, '113', 'G5');
idx_labelsr = regexprep(idx_labelsr, '141', 'INF');
idx_labelsr = regexprep(idx_labelsr, '170', 'ART');
idx_labelsr = regexprep(idx_labelsr, '198', 'TIS');
idx_labelsr = regexprep(idx_labelsr, '255', 'NON');
idx_labelsr = regexprep(idx_labelsr, '0', 'G3');


idx_labelsr = cellfun(@strtrim, idx_labelsr, 'UniformOutput', false);

%% Writing to .csv

% Create files
output_dir = [env.dataset_dir 'class.info/'];
file_filename = [output_dir 'filenames.csv'];
file_labels = [output_dir 'labels2.csv'];

f1 = fopen(file_filename, 'a');
for i = 1:length(idx_labelsr)  % for each row
    
    fprintf(f1, '%s\n', idx_filenames{i});
    
end
fclose(f1);

f2 = fopen(file_labels, 'a');
for i = 1:length(idx_labelsr)  % for each row
    fprintf(f2, '%s\n', idx_labelsr{i});
end
fclose(f2);
