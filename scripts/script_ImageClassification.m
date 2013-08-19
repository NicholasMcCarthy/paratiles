% Script to create a model from a set of features, classify an image and
% display it

env.weka_dir = [env.root_dir '/weka/weka.jar'];
javaaddpath(env.weka_dir);
javaaddpath([env.root_dir '/weka/libsvm.jar']);

import weka.*;

%% Get images

% images = getFiles(env.training_image_dir, 'Wildcard', '.scn');

images = getFiles(env.image_dir, 'Wildcard', '.8.tif');

%% Start matlabpool

if matlabpool('size') == 0
    matlabpool local 4
end

%% Loading a dataset 

disp('Loading dataset..');tic;
dataset_path = [env.dataset_dir 'G3-G4-G5-TIS_HISTOGRAM.arff'];
D = loadARFF(dataset_path);

toc
%% Training a classifier

disp('Training classifier ..');tic;
classifier_type = 'functions.LibSVM';

model = trainWekaClassifier(D, classifier_type);
toc

sendmail('nicholas.mccarthy@gmail.com', 'SVM Training complete', 'Fucking finally');

%% Read image .. 

disp('Reading image ..');tic;
image_idx = 1;  % The sample image to use

image_paths = unpackTiff(images{image_idx}, [8 10], true); % Unpacks scn image, returns path to 

toc

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

this = IC;

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

save('image_1-blockproc_features.mat', 'FV');

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


%%      
load fisheriris

svmStruct = svmtrain(meas(1:100,:),species(1:100),'showplot',true);

C = svmclassify(svmStruct,X(P.test,:),'showplot',true);

errRate = sum(Y(P.test)~= C)/P.TestSize  %mis-classification rate

conMat = confusionmat(Y(P.test),C) % the confusion matrix

data_set = matlab2weka('iris data', {'f1', 'f2', 'f3', 'f4'}, meas)

species_attribute = javaObject('weka.core.Attribute', 'species');

matlab2weka('species', {'species'}, species);

data_set.insertAttributeAt(species_attribute, data_set.numAttributes);

insertatt = @(data, i) data.instance(i)

test_model = weka