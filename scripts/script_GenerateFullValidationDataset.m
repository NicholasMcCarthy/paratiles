% Gets all of the features extracted from non-empty tiles in the validation
% image dataset. 

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

%% Load training dataset

D = wekaLoadArff('VALIDATION_training_features.arff');

D = wekaApplyFilter(D, 'weka.filters.unsupervised.instance.Resample', '-S 1998 -Z 50'); % Resample dataset by 50%

D = wekaSortAttributes(D); % Sorts alphabetically, with class at end


%% Compile validation dataset


% features = wekaListAttributes(D);
% features = cellfun(@(x) strsplit(x, ' '), features, 'UniformOutput', false);
% features = cellfun(@(x) x(2), features)';
% features(end) = [];
% 
% % Create the image colourmap
% numClasses = 7;
% cmap = jet(numClasses); 
% cmap(1, :) =[1 1 1]; % NON values in index 1
% cmap(2, :) =[1 0.75 1];% TIS values in index 2

loaded = load([temp_dir '/features.mat']);
features = loaded.features; clear loaded;
% features{end} = 'label';

data = zeros(0,length(features));

for i = [2:5 7:24 26:length(images)];
    
    fprintf('Generating dataset and image for [%d/%d]\n', i, length(images));
    
    % Path to original image file
    tiff_path = images{i};
    
    % Remove full path 
    image_name = fliplr(strtok(fliplr(tiff_path), '/'));
    
    % Get path to .mat file
    matfile = strcat(temp_dir, '/', num2str(i), '_', regexprep(image_name, '.tiff', ''), '_temp_data.mat');
    
    % Load image data
    loaded = load(matfile);
    image_data = loaded.data; clear loaded;
    
    sSize = size(image_data, 1);
    
    % Subset to non-empty tiles
    image_data(all(image_data==0, 2), :) = [];
    
    eSize = size(image_data, 1);
    
    fprintf('Selected %d of %d instances \n', eSize, sSize);
    
    data = [data ; image_data];
 
end
    
% Convert data to weka ARFF type
ID = matlab2weka('validation_image_data', features, data);

ID.insertAttributeAt(D.classAttribute, ID.numAttributes);
ID.setClassIndex(ID.numAttributes-1);

% And sort attributes alphabetically
ID = wekaSortAttributes(ID); % Sorts alphabetically, with class at end


%% Save ARFF

arff_filename = 'VALIDATION_image_features.arff';

wekaSaveArff(arff_filename, ID);

%% Model training

classifier_type = 'trees.RandomForest';
classifier_options = '-I 50 -K 7 ' ;
classifier_identifier = 'rf1';

% classifier_type = 'bayes.NaiveBayes';
% classifier_options = '-O' ;
% classifier_identifier = 'nb1';

fprintf('\tTraining classifier .. \n');
fprintf('Model: %s \n', classifier_type);
fprintf('Options: %s \n', classifier_options);

model = wekaTrainModel(D, classifier_type, classifier_options);

disp('Completed!');

% Classify validation datasets (and check class distributions)

[classPreds classProbs confusionMatrix] = wekaClassify(ID, model);


% Save model using type, options and identifier
model_path = [model_dir classifier_identifier '-' classifier_type '.model'];


overwrite = true;
wekaSaveModel(model_path, model, overwrite);

%% LOAD MODEL

model = wekaLoadModel(model_path);

