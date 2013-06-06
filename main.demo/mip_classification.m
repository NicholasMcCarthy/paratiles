% This script reads in a CSV file (one of the main_subset.csvs) then
% sets up training and test sets by selecting from N classes in I images. 

%% Setup
dir_path = '/media/Data/PCRC_Dataset/datasets/';

mip_256 = [dir_path 'mip_256_main_subset.csv'];
mip_512 = [dir_path 'mip_512_main_subset.csv'];

% Read CSV file
datasheet = csvread(mip_256);
labels = datasheet(:,end);

%
% Might need to write custom textscan script to read csv with 437 columns
% (for brevity)
%

%% Construct test and training sets

% Select N rows by indices from datasheet for each class 


%% One-versus-rest image classification
% Train set: All obs. from 
% Test set: Select all rows from one image


%% Classification

% for each image i in set of images I
%   Construct one-versus-rest training and test sets
%   Train RandomForest / NaiveBayes / RandomFerns / Multi-class SVM on training set
%   Classify on test set
%   Profit
% end

% NaiveBayes classifier
NBModel = NaiveBayes.fit(datasheet(trainingVector, :), labels(trainingVector, :));
NBPred = NBModel.predict(datasheet(testVector, :));

[ConfusionMatrix, Order] = confusionmat(labels(:, trainingVector)', NBPred);

NB_errorVector = (NBPred == labels(trainingVector, :));
NB_error = sum(NB_errorVector) / length(NB_errorVector);

% SVM classifier
SVMModel = svmtrain(datasheet(trainingVector, :), labels(trainingVector)');
SVMPred = svmclassify(SVMModel, datasheet(testVector, :));

SVM_errorVector = (SVMPred == datasheet(testVector)');
SVM_error = sum(SVM_errorVector) / length(SVM_errorvector);

% kNearest-Neighbour classifier
kNNModel = ClassificationKNN.fit(datasheet(trainingVector, :), labels(trainingVector)', 'NumNeighbors', 10);
kNNPred = kNNModel.predict(datasheet(testVector, :));

kNN_errorVector = (kNNPred == labels(testVector)');
kNN_error = sum(kNN_errorVector) / length(kNN_errorVector);


%% Feature selection