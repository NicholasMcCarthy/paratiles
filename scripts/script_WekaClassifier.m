% This script is for messing about with Weka stuff

env.weka_dir = [env.root_dir '/weka/weka.jar']
javaaddpath(env.weka_dir);
javaaddpath([env.root_dir '/weka/libsvm.jar']);

dataset_path = [env.dropbox 'G3-G34-G4-G45-G5_HISTOGRAM.arff'];


import weka.classifiers.Evaluation;

%% LOAD DATASET

tic
D = loadARFF(dataset_path);

D.setClassIndex(D.numAttributes-1);
toc



%% TRAIN CLASSIFIER

classifier_type = 'functions.LibSVM';
option_string = {'-b 1'}; % Returns class probabilities

model = trainWekaClassifier(D, 'functions.LibSVM', option_string);

% model = javaObject(classifier_type);
% model.buildClassifier(D);


%% Splitting dataset into test and training sets

D2 = D; % Copy the dataset

rand = java.util.Random(1988);

numFolds = 10;




%% Evaluation 

evaluator = weka.classifiers.Evaluation(D2);


A = Evaluation.crossValidateModel(model_obj, param);

opt1 = java.lang.String('-t');
opt2 = java.lang.String(dataset_path);

param = cat(1, opt1, opt2);

evaluator.evaluateModel(model_obj, param);

%% Training and test set

D2 = D;

D2.randomize(java.util.Random(1988));

trainSet = D2.trainCV(2, 1);
testSet = D2.testCV(2, 1);

classifier = trainWekaClassifier(trainSet, 'bayes.NaiveBayes');   

[predictedClass, classProbs, confusionMatrix] = wekaClassify(testSet,classifier);

errorRate = sum(testSet.attributeToDoubleArray(testSet.classIndex) ~= predictedClass)/testSet.numInstances;

fprintf('Error rate: %f \n', errorRate);
confusionMatrix

%% Cross validation

% Copy the dataset D into D2
D2 = D;      

% Create a java Random object for randomizing the data
rand = java.util.Random(1988);

% Randomize the data 
D2.randomize(rand); 

% Set number of folds
numFolds = 10;

% Perform CV
for n = 0:numFolds      % 0 for first fold ..
    
   train = D2.trainCV(numFolds, n); 
   test = D2.testCV(numFolds, n);           
   
   classifier = trainWekaClassifier(train, 'bayes.NaiveBayes');   
   
end

%% Performing cross-validation

averageError = wekaCrossValidate(D, 'bayes.NaiveBayes', 5);
