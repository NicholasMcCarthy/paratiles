% This script will calculate Gleason Grade from an image.


% There are two types of images this will work on;
% 1. The original annotated masks - only the versions that have been
% converted to the same vclass indexes as the classified images
% 2. The classified images (heatmaps). 


%% Calculating gleason grade of mask


masks = getFiles(env.image_dir, 'Wildcard', 'mask-PT.idx');


%%
figure;

grades = {'G3', 'G34', 'G4', 'G45', 'G5'};
grade_score = {3, 3.5, 4, 4.5, 5};
grade_idx = struct('G3', 2, 'G34', 3, 'G4', 4, 'G45',5, 'G5',6);

data = cell(size(masks));
data{end} = struct('Tissue_area', NaN, 'G3_area', NaN, 'G34_area', NaN, 'G4_area', NaN, 'G45_area', NaN, 'G5_area', NaN);

for m = 1:length(masks);
   
    mask_path = masks{m};   % Path to mask index image
    
    M = imread(mask_path);   % Read mask index image
    
    %
    % Statistics calculated: 
    %
    
    % Total area of image (used for ratio calculation)
    image_area =  size(M, 1) * size(M, 2);
    
    % Tissue area (everything that is not light-microscope background)
    tissue_area = sum(sum(M~=0));
   
    
    % Areas of each gleason grade .. 
    G3_area     = sum(sum(M==grade_idx.G3));
    G34_area    = sum(sum(M==grade_idx.G34));
    G4_area     = sum(sum(M==grade_idx.G4));
    G45_area    = sum(sum(M==grade_idx.G45));
    G5_area     = sum(sum(M==grade_idx.G5));
    grade_areas = [G3_area, G34_area, G4_area, G45_area, G5_area];
    
     
    % Area of cancer-noncancer tissue
    cancer_area = sum(grade_areas);
    
    cancer_tissue_ratio = cancer_area / tissue_area;
    
    % Primary tumour grade
    PRIMARY_grade = grades{grade_areas == max(grade_areas)};
    PRIMARY_score = grade_score{grade_areas == max(grade_areas)};
    
    uv = unique(grade_areas);
    second = uv(end-1);
    
    % Secondary tumour grade
    SECONDARY_grade = grades{grade_areas == second};
    SECONDARY_score = grade_score{grade_areas == second};
    
    % Gleason score
    GLEASON_score = PRIMARY_score + SECONDARY_score;
    
    % Number of distinct tumour regions
    
    
    
end