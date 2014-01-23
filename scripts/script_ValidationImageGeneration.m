% Generates the images resulting from feature extraction and classification
% on the PCRC validation image set. 

%% Setup

% matlabpool
if matlabpool('size') == 0
    matlabpool local 4;
end

dataset_path = [env.base_dir '/datasets/ICPR_features_2.arff'];

images = getFiles([env.data_dir '/PCRC_Validation_Images/'], 'Suffix', 'tiff', 'Wildcard', 'HE.tiff');

temp_dir = [env.temp_dir '/temp_VALIDATION_HARALICK'];

output_dir = [env.data_dir '/Validation_Heatmaps/'];

model_dir = [env.data_dir '/models/'];

tilesize = 256;

%% Load dataset

D = wekaLoadArff(dataset_path);

% Features used are just LAB q{16, 64} d(1) (I think, needs to be checked)
feature_set_idx = [106:120, 181:195, 226:240, 301:315, 346:360, 421:435, D.classIndex+1];

% Subset D to selected features
feature_set_str = regexprep(num2str(feature_set_idx), '\s*', ',');   % Replace whitespace with single comma
remove_filter_options = ['-R ' feature_set_str ' -V'];
D = wekaApplyFilter(D, 'weka.filters.unsupervised.attribute.Remove', remove_filter_options);

% Sort attributes alphabetically!
D = wekaSortAttributes(D);  

wekaSaveArff('VALIDATION_training_features.arff', D);

%% LOAD ARFF 

D = wekaLoadArff('VALIDATION_training_features.arff');

D = wekaApplyFilter(D, 'weka.filters.unsupervised.instance.Resample', '-S 1998 -Z 50'); % Resample dataset by 50%

%% Model training

classifier_type = 'trees.RandomForest';
classifier_options = '-I 50 -K 7 ' ;
classifier_identifier = 'rf1';

classifier_type = 'bayes.NaiveBayes';
classifier_options = '-O' ;
classifier_identifier = 'nb1';

% Save model using type, options and identifier
model_path = [model_dir classifier_identifier '-' classifier_type '.model'];

fprintf('\tTraining classifier .. \n');
fprintf('Model: %s \n', classifier_type);
fprintf('Options: %s \n', classifier_options);
model = wekaTrainModel(D, classifier_type, classifier_options);
disp('Completed!');

overwrite = true;
wekaSaveModel(model_path, model, overwrite);

%% LOAD MODEL

model = wekaLoadModel(model_path);


%% Load image feature sets and generate images
% 
% features = wekaListAttributes(D);
% features = cellfun(@(x) strsplit(x, ' '), features, 'UniformOutput', false);
% features = cellfun(@(x) x(2), features)';
% features(end) = [];

% Create the image colourmap
numClasses = 7;
cmap = jet(numClasses); 
cmap(1, :) =[1 1 1]; % NON values in index 1
cmap(2, :) =[1 0.75 1];% TIS values in index 2

loaded = load([temp_dir '/features.mat']);
features = loaded.features; clear loaded;

for i = [2:5 7:24 26:length(images)];
    
    fprintf('Generating dataset and image for [%d/%d]\n', i, length(images));
    
    % Path to original image file
    tiff_path = images{i};
    
    image_info = imfinfo(tiff_path);
    image_info = image_info(1);
    
    T = Tiff(tiff_path);
    T.setDirectory(7);
    T_rgb = T.readRGBAImage();
    
    % Get number of blocks processed in this image
    blocksWidth = ceil( (image_info.Width) / tilesize ) ;
    blocksHeight = ceil( (image_info.Height) / tilesize ) ;
    numBlocks = blocksWidth * blocksHeight;
    
    % Remove full path 
    image_name = fliplr(strtok(fliplr(tiff_path), '/'));
    
    % Get path to .mat file
    matfile = strcat(temp_dir, '/', num2str(i), '_', regexprep(image_name, '.tiff', ''), '_temp_data.mat');
    
    % Load image data
    loaded = load(matfile);
    image_data = loaded.data; clear loaded;
        
    % Convert data to weka ARFF type
    ID = matlab2weka('image_data', features, image_data);

    ID.insertAttributeAt(D.classAttribute, ID.numAttributes);
    ID.setClassIndex(ID.numAttributes-1);
    
    % And sort attributes alphabetically
    ID = wekaSortAttributes(ID); % Sorts alphabetically, with class at end
    
    %%%%%%%%%%%%%%%%%%%%%%%
    % GENERATION OF IMAGE %
    %%%%%%%%%%%%%%%%%%%%%%%
    
    [classPreds classProbs confusionMatrix] = wekaClassify(ID, model);
    
    I = reshape(classPreds, blocksHeight, blocksWidth);
    
    unique(I)
  
%     NON_tiles = I == 0;
%     TIS_tiles = I == 1;
%          
%     numVals = 1;
%     I = I + 1; % Remove 0 entries .. 
%     maxPoss = 1:numClasses; % i.e. 0:6
%         
%     Ui = maxPoss;
%     remap_image = @(x) find(Ui == x);
%     
%     I = arrayfun(remap_image, I, 'UniformOutput', true);

    
    stats = calculateGleason(I);
    
%     I = medfilt2(I, [3 3]);
    
    I_rgb = index2rgb_direct(I+1, cmap);
            
%     colorbar('YTickLabel', {'NON','TIS','G3','G34', 'G4','G45','G5'});
    
    fprintf('Writing image .. \n');
    
    output_thumb = [output_dir regexprep(image_name, 'tiff', 'thumb.png')];
    output_file = [output_dir regexprep(image_name, 'tiff', [classifier_identifier '.png'])];
    output_txt = [output_dir regexprep(image_name, 'tiff', 'stats.txt')];
    
    imwrite(T_rgb, output_thumb);
    imwrite(I_rgb, output_file);
    
%     fid = fopen(output_txt, 'w+');
%     
%     fprintf(fid, 'total area: %d \n', stats.image_area);
%     fprintf(fid, 'tissue area: %d \n', stats.tissue_area);
%     fprintf(fid, 'cancer area: %d \n', stats.cancer_area);
%     fprintf(fid, 'cancer:tissue ratio: %d \n', stats.cancer_tissue_ratio);
%     fprintf(fid, 'primary grade: %s \n', stats.PRIMARY_grade);
%     fprintf(fid, 'secondary grade: %s \n', stats.SECONDARY_grade);
%     fprintf(fid, 'gleason score: %d \n', stats.GLEASON_score);
%     fprintf(fid, 'distinct regions: %d \n', stats.num_distinct_regions);
%     
%     fclose(fid);
    
end


