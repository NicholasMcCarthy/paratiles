% Script for obtaining results of CANCER versus NONCANCER tissue for ICPR
% 2013 Submission

%% SETUP 

import weka.*;

if (matlabpool('size') == 0)  matlabpool local 4; end;

%% LOAD DATASET

dataset_path = [env.dataset_dir 'ICPR_features.arff'];
fprintf('Loading dataset: %s \n', dataset_path);

% Full dataset
D = wekaLoadArff(dataset_path); 

fprintf('Dataset: %s  \t %i features, %i instances \n', dataset_path, D.numAttributes, D.numInstances);
fprintf(['Class attribute: ' char(D.classAttribute.toString) '\n']);

%% CONVERT CLASS ATTRIBUTES
% Convert {G3, G34, G4, G45, G5} to {CAN} 

newAttribute = wekaCreateAttribute('nlabel', 'nominal', {'TIS', 'CAN'});
D.insertAttributeAt(newAttribute, D.numAttributes)      % Insert attribute at end of dataset 

% Indices of old and new class values
oldClassIndex = D.classIndex;
newClassIndex = D.classIndex+1;

oldValues = D.attributeToDoubleArray(oldClassIndex);    % Get old class values (as factor indices)
oldValues(oldValues>=1) = 1;                            % Map renamed values to new factor index 

for i = 0:D.numInstances-1
    D.instance(i).setValue(newClassIndex, oldValues(i+1));
end

D.setClass(D.attribute(newClassIndex)); % Swap class index values
D.deleteAttributeAt(oldClassIndex);     % And delete old class attribute!

fprintf(['Converted Class attribute: ' char(D.classAttribute.toString) '\n']);

D.numInstances
disp('Removing samples ..');
D = wekaApplyFilter(D, 'weka.filters.unsupervised.instance.Resample', '-S 1998 -Z 50');
D.numInstances

%% Leave-one-image-out cross-validation folds - randomly selected

% Image folds:
testSplitSize = 2;
numFolds = 10;

% Get datasets by filename 'string' attribute
filename_attr_index = 0;

% Find index of filename attribute
for i = 0:D.numAttributes
    if strfind(char(D.attribute(i)), 'filename');
        filename_attr_index = i;
        break;
    end
end

filename_attr = D.attributeToDoubleArray(filename_attr_index);
label_attr = D.attributeToDoubleArray(D.classIndex);
filename_groups = unique(filename_attr);

cmbns = nchoosek(filename_groups, testSplitSize);   % Every possible fold of the image set
cmbns = cmbns(randperm(size(cmbns, 1)), :);         % randomly permute the rows 

% Class distribution
cld = @(x) find(filename_attr == x);
cle = @(c) find(label_attr == c);

c1 = arrayfun(cld, filename_groups, 'UniformOutput', false);
c2 = arrayfun(cle, [0, 1], 'UniformOutput', false);

folds = cmbns(1:numFolds, :);                       % Select the first numFolds 
    
clear loi_folds; loi_folds(numFolds) = struct();

fprintf('Splitting dataset into %i folds with %i images in test set .. \n', numFolds, testSplitSize);

for i = 1:numFolds
    
    fold = folds(i,:);
    fold_idx = [];
    
    for j = 1:testSplitSize
        filename_group_index = fold(j);
        fold_idx = [fold_idx ; find(filename_attr == filename_group_index)];        
    end
    
    nonfold_idx = [1:D.numInstances];
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
classifier_options = '-I 100 -K 9 ' ;

fprintf('Leave-one-image-out Cross-Validation: \n');
fprintf('NumFolds: %i \n', numFolds);
fprintf('Test split size: %i \n', testSplitSize);

for f = 10 % [1,2,4:9,15] %length(feature_set_names)
    
    % Copy original dataset 
    E = wekaCopyDataset(D, D.numInstances); 
    E.deleteStringAttributes();
    
    % Name of feature set grouping
    feature_set_name = feature_set_names{f};
    
    fprintf('Feature set: %s \n', feature_set_name);
    
    % Subset selection
    if ~strcmpi(feature_set_name, 'ALL')
        
        % Indices of selected feature set 
        feature_set_idx = [feature_set_idxs{f} E.classIndex+1];       % Don't delete the class index either .. 
        feature_set_str = num2str(feature_set_idx);                 % Convert attribute indices to string
        feature_set_str = regexprep(feature_set_str, '\s*', ',');   % Replace whitespace with single comma
        
        % -R sets indices to remove, -V inverts selection (so only selected
        % indices + class attribute is kept 
        remove_filter_options = ['-R ' feature_set_str ' -V'];  
            
        E = wekaApplyFilter(E, 'weka.filters.unsupervised.attribute.Remove', remove_filter_options);
    end

%     % Print attribute names
%     for i = 0:E.numAttributes-1
%         fprintf('%s\n', char(E.attribute(i)));
%     end
    
    % Cross-fold validation 
    for i = 1:numFolds

%         fprintf('Fold %i \n.', i);
        train = Instances(E, length(loi_folds(i).train_idx));    % Init train as the primary dataset
        test = Instances(E, length(loi_folds(i).test_idx));      % Init test as empty dataset
        
        test_idx = loi_folds(i).test_idx;
        train_idx = loi_folds(i).train_idx;
                
%         fprintf('\tPopulating testing set .. \n');
        for j = 1:length(test_idx)   % For each selected test index in this fold
            test.add(E.instance(test_idx(j)));                          % Add this instance index to test from D
        end

%         fprintf('\tPopulating training set .. \n');
        for j = 1:length(train_idx)   % For each selected test index in this fold
            train.add(E.instance(train_idx(j)));                          % Add this instance index to test from D
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
    
    sensitivity = (ac(1)) / ( ac(1) + ac(2));
    specificity = (ac(4)) / ( ac(4) + ac(3));

%     fprintf('Leave-one-image-out Cross-Validation: \n');
%     fprintf('Feature set: %s \n', feature_set_name);
%     fprintf('NumFolds: %i \n', numFolds);
%     fprintf('Test split size: %i \n', testSplitSize);
%     fprintf('Classifier: %s \n', classifier_type);
%     fprintf('Classifier Options: %s \n', classifier_options);
    fprintf('Macro accuracy: %0.2f \n', (1-macroError)*100);
    fprintf('Micro accuracy: %0.2f \n ', (microAccuracy*100));
    fprintf('Sensitivity: %0.5f \n ', sensitivity);
    fprintf('Specificity: %0.5f \n ', specificity);
    disp('------------------------');
    
end

