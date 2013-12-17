% This script performs LOI (Leave-one-image-out) cross-validation on a
% dataset


%% SETUP 

% Import weka thingies, just in case
import weka.*;

% Start matlabpool
if matlabpool('size') == 0
    matlabpool local 4
end

%% Loading a dataset 

dataset_path = [env.dataset_dir 'ICPR_features.arff'];

fprintf('Loading dataset: %s \n', dataset_path);

% Full dataset
D = wekaLoadArff(dataset_path); 

fprintf('Dataset: %s  \t %i features, %i instances \n', dataset_path, D.numAttributes, D.numInstances);
fprintf(['Class attribute: ' char(D.classAttribute.toString) '\n']);


%% SUBSET DATASET TO {G3, G5}


E = wekaCopyDataset(D, 0);

classAttribute = D.classAttribute;
classVector = D.attributeToDoubleArray(D.classIndex);

for i = 0:length(classVector)-1
    
    if (classVector(i+1) == 1 || classVector(i+1) == 5)  % Add G3, G5 to E
        E.add(D.instance(i));
    end
    
end

oldValues = E.attributeToDoubleArray(E.classIndex);
oldValues(oldValues ==1) = 0;  % Map old values to new indices
oldValues(oldValues ==5) = 1;

% Create new attribute
newAttribute = wekaCreateAttribute('nlabel', 'nominal', {'G3', 'G5'});

% Insert new attribute 
E.insertAttributeAt(newAttribute, E.classIndex+1);

% Set new attribute to class index
E.setClassIndex(E.classIndex+1);

% Delete old class attribute
E.deleteAttributeAt(E.classIndex-1);

% Add class labels to TRAIN 
for i = 0:length(oldValues)-1
    E.instance(i).setValue(E.classIndex, oldValues(i+1));
end

disp(E.attributeStats(E.classIndex));

% Remove string attributes

% Find index of filename attribute
for i = 0:E.numAttributes
    if strfind(char(E.attribute(i)), 'filename');
        filename_attr_index = i;  break;
    end
end

filename_ATTR = E.attribute(filename_attr_index);
filename_vector = E.attributeToDoubleArray(filename_attr_index);

E.deleteStringAttributes;

%% LOIO cross-validation folds - randomly selected

testSplitSize = 3;
numFolds = 20;

filename_attr = filename_vector;
label_attr = E.attributeToDoubleArray(E.classIndex);
filename_groups = unique(filename_attr);

cmbns = nchoosek(filename_groups, testSplitSize);   % Every possible fold of the image set
cmbns = cmbns(randperm(size(cmbns, 1)), :);         % randomly permute the rows 

% Class distribution
cld = @(x) find(filename_attr == x);
cle = @(c) find(label_attr == c);

c1 = arrayfun(cld, filename_groups, 'UniformOutput', false);
c2 = arrayfun(cle, [0, 1], 'UniformOutput', false);

folds = cmbns(1:numFolds, :);                       % Select the first numFolds 


%% Cherry-picked image folds 
% These were picked to obtain a reasonable balance between G3 and G4 image
% folds in the test set -> computed using R script

% numFolds = 10;
% testSplitSize = 4;
% 
% folds = [10 15 17 20 ; 
%          2 8 13 15;
%          5 7 11 14;
%          2 8 10 18;
%          7 11 16 17;
%          9 12 14 20;
%          4 10 18 20;
%          11 15 18 20;
%          12 14 17 19;
%          4 13 15 20; ]
     
numFolds = 20;
testSplitSize = 4;
folds = [  10   15   17   20;
            2    8   13   15;
            5    7   11   14;
            2    8   10   18;
            7   11   16   17;
            9   12   14   20;
            4   10   18   20;
           11   15   18   20;
           12   14   17   19;
            4   13   15   20;
            1    7   11   17;
            5    7    9   16;
            2    5   11   17;
            7    8   14   17;
            5   15   18   19;
            2    8   12   19;
            2    3    4   12;
            1   10   14   16;
            2    7    9   14;
            2    4    7   19 ];
         
%% Creating fold idx struct
     
clear loi_folds;
loi_folds(numFolds) = struct();

fprintf('Splitting dataset into %i folds with %i images in test set .. \n', numFolds, testSplitSize);

for i = 1:numFolds
    
    fold = folds(i,:);
    fold_idx = [];
    
    for j = 1:testSplitSize
        filename_group_index = fold(j);
        fold_idx = [fold_idx ; find(filename_attr == filename_group_index)];        
    end
    
    nonfold_idx = [1:E.numInstances];
    nonfold_idx(fold_idx) = [];
    
    % Since java indexes from 0 .. 
    fold_idx = fold_idx -1;
    nonfold_idx = nonfold_idx -1;
    
    loi_folds(i).folds = fold;
    loi_folds(i).test_idx = fold_idx';
    loi_folds(i).train_idx = nonfold_idx;
    
end


%% Manage feature (sub)sets .. 

feature_set_names = { 'CICM_v0',
                      'CICM_v1',
                      'CICM_v2',
                      'CICM_v3',
                      'CICM_v4', 
                      'HARALICK_LAB',
                      'HARALICK_RGB',
                      'HISTOGRAM_LAB', 
                      'HISTOGRAM_RGB',
                      'SHAPE',
                      'HARALISTOGRAM_LAB', 
                      'HARALISTOGRAM_RGB', 
                      'HARALICK_LAB_SHAPE', 
                      'HARALICK_LAB_CICMv0', 
                      'ALL'};
                    
feature_set_idxs = { [1:25], ...
                     [26:50], ...
                     [51:75], ...
                     [76:90], ...
                     [91:105], ...
                     [106:465], ...
                     [466:735], ...
                     [736:816], ...
                     [817:897], ...
                     [898:909], ...
                     [106:465 , 736:816], ...
                     [466:735 , 817:897], ...
                     [106:465 , 898:909], ...
                     [106:465 , 1:25], ...
                     [0:D.numAttributes-2] };
                                    
%% Split dataset by each fold and classify

% Assuming 'D' is the primary dataset
import weka.core.Instances;

% classifier_type = 'bayes.NaiveBayes';
% classifier_options = '-O' ;
classifier_type = 'trees.RandomForest';
classifier_options = '-I 50 -K 7 ' ;

fprintf('Leave-one-image-out Cross-Validation: \n');
fprintf('NumFolds: %i \n', numFolds);
fprintf('Test split size: %i \n', testSplitSize);

for f = [1, 10, 11] %length(feature_set_names)
    
    % Copy original dataset 
    F = wekaCopyDataset(E, E.numInstances); 
    F.deleteStringAttributes();
    
    % Name of feature set grouping
    feature_set_name = feature_set_names{f};
    
    fprintf('Feature set: %s \n', feature_set_name);
    
    % Subset selection
    if ~strcmpi(feature_set_name, 'ALL')
        
        % Indices of selected feature set 
        feature_set_idx = [feature_set_idxs{f} F.classIndex+1];       % Don't delete the class index either .. 
        feature_set_str = num2str(feature_set_idx);                 % Convert attribute indices to string
        feature_set_str = regexprep(feature_set_str, '\s*', ',');   % Replace whitespace with single comma
        
        % -R sets indices to remove, -V inverts selection (so only selected
        % indices + class attribute is kept 
        remove_filter_options = ['-R ' feature_set_str ' -V'];  
            
        F = wekaApplyFilter(F, 'weka.filters.unsupervised.attribute.Remove', remove_filter_options);
    end

%     % Print attribute names
%     for i = 0:E.numAttributes-1
%         fprintf('%s\n', char(E.attribute(i)));
%     end
    
    % Cross-fold validation 
    for i = 1:numFolds

%         fprintf('Fold %i \n.', i);
        train = Instances(F, length(loi_folds(i).train_idx));    % Init train as the primary dataset
        test = Instances(F, length(loi_folds(i).test_idx));      % Init test as empty dataset
        
        test_idx = loi_folds(i).test_idx;
        train_idx = loi_folds(i).train_idx;
                
%         fprintf('\tPopulating testing set .. \n');
        for j = 1:length(test_idx)   % For each selected test index in this fold
            test.add(F.instance(test_idx(j)));                          % Add this instance index to test from D
        end

%         fprintf('\tPopulating training set .. \n');
        for j = 1:length(train_idx)   % For each selected test index in this fold
            train.add(F.instance(train_idx(j)));                          % Add this instance index to test from D
        end
      
        % Resampling values 
%         test = wekaApplyFilter(test, 'weka.filters.unsupervised.attribute.Remove', remove_filter_options);
        
%         fprintf('\tTraining classifier .. \n');
        model = wekaTrainModel(train, classifier_type, classifier_options);

%         fprintf('\tTesting classifier .. \n');
% 
        [classPreds classProbs confusionMatrix] = wekaClassify(test, model);

        errorRate = sum(test.attributeToDoubleArray(test.classIndex) ~= classPreds)/test.numInstances;

        fprintf('Fold %i error rate: %0.2f \n', i, errorRate);
%         fprintf('\tError rate: %0.2f \n', errorRate);

        loi_folds(i).classPreds = classPreds;
        loi_folds(i).classProbs = classProbs;
        loi_folds(i).confusionMatrix = confusionMatrix;
        loi_folds(i).errorRate = errorRate;

    end

    % Macro error: average for each test/train split (i.e. imbalanced here)
    
    macroError = 0;
    for i = 1:numFolds
        macroError = macroError + loi_folds(i).errorRate;
    end
    macroError = macroError / numFolds;
    
    % Micro error: weighted average for each test/train split
    
    ac = zeros(size(loi_folds(1).confusionMatrix)); % average confusion matrix 
    for i = 1:numFolds
        ac = ac + loi_folds(i).confusionMatrix;
    end
    
    microAccuracy = (ac(1) + ac(4)) / sum(sum(ac));
    
%     fprintf('Leave-one-image-out Cross-Validation: \n');
%     fprintf('Feature set: %s \n', feature_set_name);
%     fprintf('NumFolds: %i \n', numFolds);
%     fprintf('Test split size: %i \n', testSplitSize);
%     fprintf('Classifier: %s \n', classifier_type);
%     fprintf('Classifier Options: %s \n', classifier_options);
    fprintf('Macro accuracy: %0.2f \n ', (1-macroError)*100);
    fprintf('Micro accuracy: %0.2f \n ', (microAccuracy*100));
    disp('------------------------');
    
end

