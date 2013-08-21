% Script to create a model from a set of features, classify an image and
% display it

env.weka_dir = [env.root_dir '/weka/weka.jar'];
javaaddpath(env.weka_dir);
javaaddpath([env.root_dir '/weka/libsvm.jar']);

import weka.*;

%% Get images

images = getFiles(env.training_image_dir, 'Wildcard', '.scn');

% images = getFiles(env.image_dir, 'Wildcard', '.9.tif');

%% Start matlabpool

if matlabpool('size') == 0
    matlabpool local 4
end

%% Loading a dataset 

dataset_path = [env.dataset_dir 'G3-G4-G5-TIS_HISTOGRAM.arff'];

fprintf('Loading dataset: %s \n', dataset_path); 

tic;
D = wekaLoadArff(dataset_path);
toc;

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
options = '-B 0 -seed 1998'

model = wekaTrainModel(D, classifier_type, options);

model.setProbabilityEstimates(true);

[classPreds classProbs confusionMatrix] = wekaClassify(D, model);

% model.getOptions

% Save model !
% wekaSaveModel('./NaiveBayes_fisheriris.model', model)

%% Filtering a dataset 



