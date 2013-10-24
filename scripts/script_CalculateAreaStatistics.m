% Takes in a classified tilemap and calculates area statistics:
% Percentage tissue (of entire image)
% Percentage Cancer (of tissue)
% Percentage high (3+4, 4, 4+5, 5) versus low (3) cancer.

%% Setup

images = getFiles(env.training_image_dir, 'Suffix', '.scn');    

% Get contents of pipelines directory 
dirContents = dir([pwd '/pipelines/']);
% Remove contents that are not directories, have FAILED in the dir name or are '.' or '..' 
pipeline_list_idx = arrayfun(@(x) x.isdir && ~any([ strcmp(x.name, {'.', '..'}) strfind(x.name, 'FAILED') ]), dirContents);
pipeline_list = dirContents(pipeline_list_idx);
pipeline_list = struct2cell(pipeline_list); % Convert to cell array
pipeline_list = pipeline_list(1,:)';        % Take first row (the name field) and convert to cols

% Default is first directory found (if exists);
pipeline_ver = pipeline_list{1};
pipeline_dir = ['pipelines/' pipeline_ver '/'];

%% Calculating statistics ..

for i = 1:length(images);
    
    image_path = images{i};
    image_name = fliplr(strtok(fliplr(image_path), '/'));
    cls_data_path = [pipeline_dir 'data/' regexprep(image_name, '.scn', '_cls-data.mat') ];
    
    % Load saved data
    loaded = load(cls_data_path);
    image_cls_data = loaded.image_cls_data;
    clear('loaded');
    
    I = image_cls_data.image;
    
    gridSize = size(I, 1) * size(I, 2);
    
    tissue_area = sum(sum(I ~= 0));
    tissue_pct= tissue_area / gridSize;
    
    NORMAL_area = sum(sum(I==1));
    CANCER_area = sum(sum(I>1));
    
    NORMAL_pct = NORMAL_area / tissue_area;
    CANCER_pct = CANCER_area / tissue_area;
    
    G3  = sum(sum(I==2));
    G34 = sum(sum(I==3));
    G4  = sum(sum(I==4));
    G45 = sum(sum(I==5));
    G5  = sum(sum(I==6));
    
    G3_pct  = G3  / tissue_area;
    G34_pct = G34 / tissue_area;
    G4_pct  = G4  / tissue_area;
    G45_pct = G45 / tissue_area;
    G5_pct  = G5  / tissue_area;
    
    fprintf('Total area: %0.4f \n Tissue area: %0.4f \n Normal: %0.4f \n Cancer: %0.4f\n', gridSize, tissue_area, NORMAL_area, CANCER_area);
    fprintf('----------\n');
    
    fprintf('NORMAL: %0.4f \n G3: %0.4f \n G34: %0.4f \n G4: %0.4f \n G45: %0.4f \n G5: %0.4f\n ', NORMAL_pct, G3_pct, G34_pct, G4_pct, G45_pct, G5_pct);
        
    
    
end