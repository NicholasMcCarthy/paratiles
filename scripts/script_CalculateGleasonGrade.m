% This script will calculate Gleason Grade from an image.


% There are two types of images this will work on;
% 1. The original annotated masks - only the versions that have been
% converted to the same vclass indexes as the classified images
% 2. The classified images (heatmaps). 


%% Calculating gleason grade of mask


masks = getFiles(env.image_dir, 'Wildcard', 'mask-PT.idx');

grades = {'G3', 'G34', 'G4', 'G45', 'G5'};
grade_score = {3, 3.5, 4, 4.5, 5};
grade_idx = struct('G3', 2, 'G34', 3, 'G4', 4, 'G45',5, 'G5',6);


%%
figure;

data = cell(size(masks));
data{end} = struct('Tissue_area', NaN, 'G3_area', NaN, 'G34_area', NaN, 'G4_area', NaN, 'G45_area', NaN, 'G5_area', NaN);

for m = 1:length(masks);
   
    mask_path = masks{m};   % Path to mask index image
    
    M = imread(mask_path);   % Read mask index image
    
    stats = calculateGleason(M);
    
end