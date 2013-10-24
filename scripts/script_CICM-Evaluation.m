% This script is for messing about with Weka stuff

env.weka_dir = [env.root_dir '/weka/weka.jar']
javaaddpath(env.weka_dir);
javaaddpath([env.root_dir '/weka/libsvm.jar']);

D1_path = [env.dataset_dir 'G3-G4_pp1.arff'];
D2_path = [env.dataset_dir 'G3-G4_pp2.arff'];
D3_path = [env.dataset_dir 'G3-G4_pp3.arff'];

dataset_paths = {D1_path, D2_path, D3_path};

import weka.classifiers.Evaluation;

%% Iterate through dataset s ..

for i = 1:3

    % Load dataset
    dataset_path = dataset_paths{i};
    fprintf('Loading: %s\n',dataset_path)
    
    D = wekaLoadArff(dataset_path);

    D.setClassIndex(D.numAttributes-1);

    % Filter dataset (subsample)
%     filter_type = 'weka.filters.unsupervised.instance.Resample';
%     filter_options = '-S 1998 -Z 20';
%     disp('Filtering dataset')
%     E = wekaApplyFilter(D, filter_type, filter_options);
% 
%     % Train model
    classifier_type = 'bayes.NaiveBayes';
    classifier_options = '-O -D';
%     disp('Training model.');
%     model = wekaTrainModel(E, classifier_type, classifier_options); 
% 
%     % Evaluate model
%     disp('Evaluating model.');
%     [predictedClass, classProbs, confusionMatrix] = wekaClassify(D,model);
% 
%     errorRate = sum(D.attributeToDoubleArray(D.classIndex) ~= predictedClass)/D.numInstances;
% 
%     fprintf('Error rate: %f \n', errorRate);
%     confusionMatrix

    disp('Cross-validating model.');
    
    wekaCrossValidate(D, classifier_type, classifier_options, 5);

end

%%

% Information gain 


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
