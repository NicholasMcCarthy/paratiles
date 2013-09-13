% Script to create a model from a set of features, classify an image and
% display it


%% SETUP 

% Import weka thingies, just in case
import weka.*;

% Start matlabpool
if matlabpool('size') == 0
    matlabpool local 4
end

%% Loading a dataset 

dataset_path = [env.dataset_dir 'all-classes_lab-shape-cicm.arff'];

fprintf('Loading dataset: %s \n', dataset_path); 

tic
% Full dataset
D = wekaLoadArff(dataset_path); 
toc

fprintf('Original dataset: %i features, %i instances \n', D.numAttributes, D.numInstances);

fprintf('Reducing dataset size.');
tic;
% Filtered dataset (for training)
E = wekaApplyFilter(D, 'weka.filters.unsupervised.instance.Resample', '-S 1998 -Z 10');
toc;

fprintf('Reduced dataset: %i features, %i instances \n', E.numAttributes, E.numInstances);

%% Training SVM Classifier

classifier_type = 'functions.LibSVM';
options = '-B 1 -seed 1998';

% Warning: using -h 0 may be faster (-h shrinking: whether to use shrinking heuristics, 0 or 1 (default 1))

disp('Training classifier on reduced dataset.')
tic;
model = wekaTrainModel(E, classifier_type, options);
model.setProbabilityEstimates(true);
toc;

%% Training NaiveBayes classifier

%            Valid options are:
%  -K
%   Use kernel density estimator rather than normal
%   distribution for numeric attributes
%  -D
%   Use supervised discretization to process numeric attributes
%  
%  -O
%   Display model in old format (good when there are many classes)


classifier_type = 'bayes.NaiveBayes';
options = '-O' ;

disp('Training classifier on reduced dataset.')
tic;
model = wekaTrainModel(E, classifier_type, options);
toc;

%% Test Classifier

disp('Testing classifier on larger dataset.');
tic;
[classPreds classProbs confusionMatrix] = wekaClassify(D, model);


errorRate = sum(D.attributeToDoubleArray(D.classIndex) ~= classPreds)/D.numInstances;

toc;

%% Save classifier model

model_dir = [env.dropbox, '/paratiles/models/'];

model_ver = '1.1';
model_name = [classifier_type '-' regexprep(fliplr(strtok(fliplr(dataset_path), '/')), 'arff', [model_ver '.model'])]

model_path = [model_dir model_name];

wekaSaveModel(model_path, model);

%% Cross-validate model on full dataset

% res = wekaCrossValidate(model, D);

model = wekaLoadModel([env.dropbox 'paratiles/models/weka_SVM.model'])

% Not sure if this was trained with option '-B 1'
model.setProbabilityEstimates(true);

loaded = load('image_1_weka_format-features.mat')
image_data = loaded.FVa; clear loaded;

import java.util.List;

label_attribute = javaObject('weka.core.Attribute', javaObject('java.lang.String', 'label') );

image_data.insertAttributeAt(label_attribute, image_data.numAttributes);


[classPreds classProbs confusionMatrix] = wekaClassify(image_data, model);


%% Generate image datasets and classify -> output classProbs etc 

% Generate 
output_dir = [env.root_dir '/cls_data-' ver '/']

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

images = getFiles(env.training_image_dir, 'Wildcard', '.scn');

for i = 1:length(images)

    disp(i);
    image_path = images{i};

    % Get image info 
    disp('Retrieving image info ..');tic;
    ifd_paths = unpackTiff(image_path, 8, 1);       % Unpack image
    imageinfo = imfinfo(ifd_paths{1});              % Get big layer info
    repackTiff(image_path);                         % Repack image 
    toc;
    width = imageinfo.Width;
    height = imageinfo.Height;
    tilesize = 256;

    numBlocks = ceil( (width) / tilesize ) * ceil( (height) / tilesize)
    
    % Generate image dataset .. 
    feature_dirs = {'datasets/HARALICK_LAB', 'datasets/SHAPE.features', ...
                    'datasets/HISTOGRAM_LAB', 'datasets/CICM-r1.features'};

    label_path = 'datasets/class.info/labels.csv';
    filenames_path = 'datasets/class.info/filenames.csv';
    sel_path = fliplr(strtok(fliplr(image_path), '/'));

    [dataset_name status cmdout] = GenerateImageDataset( env.root_dir, 'Directory', feature_dirs, 'Image', sel_path, ... 
                            'Labels', label_path, 'Filenames', filenames_path, 'AssignIDs', 0, 'AssignClasses', 1);
    
    dataset_path = [env.root_dir '/' dataset_name];  
    
    image_data = wekaLoadArff(dataset_path);
    
    disp('Classifying image ..');tic;
    
    [classPreds classProbs confusionMatrix] = wekaClassify(image_data, model);
    toc;

    % Reshape classPreds to image dimensions .. 
    numXtiles = ceil(width / 256);
    numYtiles = ceil(height / 256);
    cls_image = reshape(classPreds, numYtiles, numXtiles);
    
    image_cls_data = struct('classPreds', classPreds, 'classProbs', classProbs, 'confusionMatrix', confusionMatrix, 'image', cls_image);
    
    data_path = [output_dir regexprep(sel_path, '.scn', '-NaiveBayes_cls-data.mat')]
    
    save(data_path, 'image_cls_data');
    
end

sendmail('nicholas.mccarthy@gmail.com', 'Image classification data', 'Completado! Oy vey!');

%% BELOW HERE IS NOW ROUGHWORK


%% Training a classifier

classifier_type = 'functions.LibSVM';
classifier_options = '-B 1';

fprintf('Training classifier: %s [%s] \n', classifier_type, classifier_options);

tic;

model = trainWekaClassifier(D, classifier_type, classifier_options);
model.setProbabilityEstimates(true);    % Shouldn't be needed with set option string, but whatever ..

toc;

% sendmail('nicholas.mccarthy@gmail.com', 'SVM Training complete', 'Fucking finally');

%% Read image .. 


image_idx = 1;  % The sample image to use
image_scn = images{image_idx};

disp('Unpacking image: %s [%i]\n', image_scn, image_idx);

tic;

image_paths = unpackTiff(images{image_idx}, [8 10], true); % Unpacks scn image, returns path to 

toc;

%% Create FeatureExtractor for same features ..
% NOTE: This is just using histogram features for the time being (and
% convenience) 

numlevels = [16 32 64];

histogram_func_rgb = @(I) extract_histogram_features(I, 'NumLevels', numlevels);
histogram_labels_rgb = label_histogram_features('Channels', {'R', 'G', 'B'}, 'NumLevels', numlevels, 'Prefix', 'rgb', 'UseStrings', true);

functions = { histogram_func_rgb };
labels    = [ histogram_labels_rgb ] ;

FE = FeatureExtractor(functions, labels);

% Create ImageClassifier object (includes Blockproc function)
desc =  'An imageclassifier using NaiveBayes and histogram features';

IC = ImageClassifier(model, FE, desc);

ImageFilePath = image_paths{1};

%% The ImageClassifier predictionMap function .. 

this = IC; % This code block will be moved into ImageClassifier.predict function once ready .. 

imageinfo = imfinfo(ImageFilePath);

% Get number of blocks processed in this image
numBlocks = ceil( (imageinfo.Width) / this.Tilesize ) * ceil( (imageinfo.Height) / this.Tilesize);
 
% Get blockproc handle for FeatureExtraction function 
fe_handle = IC.FeatureExtractor.BlockProcHandle;

fprintf('Performing feature extraction on %i blocks .. \n', numBlocks); 

tic;
% Perform feature extraction using blockproc
FV = blockproc(ImageFilePath, [this.Tilesize this.Tilesize], this.FeatureExtractor.BlockProcHandle);
toc

% save('image_1-blockproc_features.mat', 'FV');

FVo = FV;

% -----------------------------------

disp('Classifying tiles ..');
tic;

% load('image_1-blockproc_features.mat');

% Dimensions for probability map
[Xd Yd Zd] = size(FV);

% Reshape FV from map to feature vector matrix
FV = reshape(FV, Xd * Yd, Zd);   

% Re-sort columns of FV by SortIndex
FV = FV(:,this.SortIndex);

% -----------------------------------
% Convert matlab feature vector matric to weka Instances class

tic
FVa = matlab2weka('ImageFilePath', this.FeatureNames, FV);

% Create empty label attribute
label_attribute = javaObject('weka.core.Attribute', javaObject('java.lang.String', 'label'));

% Add label attribute to end of Instances feature vector. Attribute values
% will be '?'
FVa.insertAttributeAt(label_attribute, FVa.numAttributes);

toc

%% -----------------------------------
%% Classifying with matlab svmTrain
% [mdata,featureNames,targetNDX,stringVals,relationName]
[FVc FVlabels]  = weka2matlab(D);

svmModel = svmtrain(FV, <TrainclassLabels>, '-b 1 -c <someCValue> -g <someGammaValue>');



%% 
numClasses = length(model.distributionForInstance(FVa.instance(1)));

classProbs = zeros(numBlocks, numClasses+1);
model.setProbabilityEstimates(true);

tic
% For each instance / tile .. 
for t = 0:FVa.numInstances-1
    
    % Check if it's a zero-vector (i.e. skipped)
    if (~any(FVa.instance(t).toDoubleArray))
        classProbs(t+1,1) = 1;
    else
        classProbs(t+1,:) = [0 (model.distributionForInstance(FVa.instance(t)))'];
    end
end
toc

[prob,predictedClass] = max(classProbs,[],2);

predictedClass = predictedClass - 1;

%% Convert probability vector to map .. 

G = reshape(predictedClass, Xd, Yd);

cmap = jet(numClasses+1);

imshow(G, cmap);

%% Display results side-by-side

thumb_image = imread(image_paths{2});

figure;
subplot(121), imshow(thumb_image);
subplot(122), imshow(G, cmap);


%% Clean up tiff files

repackTiff(image_paths{1})


%% Saving and loading Weka models to Matlab

% Java imports
import weka.core.Attribute;
import weka.core.FastVector;
import java.lang.String;
import java.util.List;

% Load dataset
load fisheriris % loads 'meas', 'species'

% Convert meas and species to ARFF Dataset
D = matlab2weka('fisheriris', {'f1', 'f2', 'f3', 'f4'}, meas);
S = matlab2weka('species', {'species'}, species);
D = D.mergeInstances(D, S); % Easier than creating species as separate instances 
D.setClassIndex(4); 

E = D;

%% Old-fashioned cross-fold validation

avgError = wekaCrossValidate(E, 'functions.LibSVM', 5, 1998)

E = wekaApplyFilter(E, 'weka.filters.unsupervised.instance.StratifiedRemoveFolds', '-S 1998');

%% Create model
classifier_type = 'functions.LibSVM';
options = '-B 0 -seed 1998';

model = wekaTrainModel(D, classifier_type, options);

model.setProbabilityEstimates(true);

[classPreds classProbs confusionMatrix] = wekaClassify(D, model);

% model.getOptions

% Save model !
% wekaSaveModel('./NaiveBayes_fisheriris.model', model)

%% Filtering a dataset 



