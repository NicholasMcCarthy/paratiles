% This is the main script for running feature extraction

% Author: Nicholas McCarthy (nicholas.mccarthy@gmail.com)
% Created: 27-05-2013
% Updated: 27-05-2013


%% Setup 
%--------
% Sets env vars, any other odds and ends

[data.images data.masks ] = get_image_files(env.image_dir); % env should be declared ..


%% Init
%------

image_tilesize = [256 256];
mask_tilesize = [16 16];

% matlabpool local 4;     % Open matlab pool for parallel processing
disp('Ready!');

%% EXTRACT CLASS LABELS

% Gets label and percentage coverage of annotation region. 
func_labels = @(block_struct) shiftdim(block_get_class_label(block_struct), -1);

idx_labels = [];        % Assigned label
idx_coverage = [];      % Coverage of label
idx_filenames = {};     % Filename of obs.

for i = 1:20 
    
    disp(i); tic;
    mask_filepath = strcat(env.image_dir, data.masks(i).name); % Get mask filepath

    % Blockproc mask image to get class labels
    G = blockproc(mask_filepath, mask_tilesize, func_labels, 'PadPartialBlocks', true); 
   
    [X Y Z] = size(G);
    G = reshape(G, X*Y, Z);
     
    idx_labels = vertcat(idx_labels, G(:,1));   % grayscale int8 values for each class
    idx_coverage = vertcat(idx_coverage, G(:,2));
    idx_filenames = vertcat(idx_filenames, cellstr(repmat(mask_filepath, length(G(:,1)), 1)));
    
    toc
    
    % convert class num values to labels  
end

% Converting uint8 values to string labels
interval = (255/8);

idx_labelsr = num2str(idx_labels);
idx_labelsr = cellstr(idx_labelsr);

idx_labelsr = regexprep(idx_labelsr, '28', 'G34');
idx_labelsr = regexprep(idx_labelsr, '56', 'G4');
idx_labelsr = regexprep(idx_labelsr, '85', 'G45');
idx_labelsr = regexprep(idx_labelsr, '113', 'G5');
idx_labelsr = regexprep(idx_labelsr, '141', 'INF')
idx_labelsr = regexprep(idx_labelsr, '170', 'ART');
idx_labelsr = regexprep(idx_labelsr, '198', 'TIS');
idx_labelsr = regexprep(idx_labelsr, '255', 'NON');
idx_labelsr = regexprep(idx_labelsr, '0', 'G3');

idx_labelsr = cellfun(@strtrim, idx_labelsr, 'UniformOutput', false);

idx_coverage = double(idx_coverage) ./ 255; % blockproc input uint8 problem workaround

% Creating class label dataset

D = dataset( {idx_filenames, 'filename'}, {idx_coverage, 'coverage'}, {idx_labelsr, 'label'})

save '../datasets/256/class_labels.mat' D

% sendmail('nicholas.mccarthy@gmail.com', 'Processing complete');

%% Checking output

U = unique(D.label);

label_counts = zeros(length(U), 1);

for u = 1:length(U)
    
    label_counts(u) = sum(strcmp(D.label, U{u}))
    
end
    
summary = dataset({U, 'label'}, {label_counts, 'counts'});

save '../datasets/256/class_labels_summary.mat' summary



