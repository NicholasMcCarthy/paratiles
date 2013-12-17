% Script for obtaining results of CANCER versus NONCANCER tissue for ICPR
% 2013 Submission

%% SETUP 

import weka.*;

if (matlabpool('size') == 0)  matlabpool local 4; end;

%% LOAD DATASET(S)

dataset_path = [env.dataset_dir 'ICPR_features.arff'];
fprintf('Loading dataset: %s \n', dataset_path);

% Full dataset
D = wekaLoadArff(dataset_path); 

fprintf('Dataset: %s  \t %i features, %i instances \n', dataset_path, D.numAttributes, D.numInstances);
fprintf(['Class attribute: ' char(D.classAttribute.toString) '\n']);

%% Subset data to classify G3, G4, G5

disp('Initializing datasets .. ');

E = wekaCopyDataset(D, 0); % Create new dataset with same attributes

classAttribute = D.classAttribute;
classVector = D.attributeToDoubleArray(D.classIndex);


disp('Subsetting datasets to {G3, G4, G5}');

for i = 0:length(classVector)-1
    
    if any(classVector(i+1) == [1 3 5])
       E.add(D.instance(i)); 
    end
    
end

disp('Mapping old class index values to new ones ..');

newValues = E.attributeToDoubleArray(E.classIndex);
newValues(newValues ==1)= 0;    % All 1s -> 0
newValues(newValues ~=0)= 1;    % All ~0s -> 1

disp('Creating and assigning new class attribute');

% Create and insert new attributes
newAttribute = wekaCreateAttribute('nlabel', 'nominal', {'LOW', 'HIGH'});
E.insertAttributeAt(newAttribute, E.classIndex+1);

% Set new attribute to class index, E.classIndex+1);
E.setClassIndex(E.classIndex+1);

% Delete old class attribute
E.deleteAttributeAt(E.classIndex-1);

disp('Assigning old class values to newly created class attribute');
% Add class labels to G3_4 and G4_5 
for i = 0:length(newValues)-1
    E.instance(i).setValue(E.classIndex, newValues(i+1));
end

% Reduce dataset size by 0.5
E = wekaApplyFilter(E, 'weka.filters.unsupervised.instance.Resample', '-S 1988 -Z 50');


% Remove string attributes

% Find index of filename attribute
for i = 0:E.numAttributes
    if strfind(char(E.attribute(i)), 'filename');
        filename_attr_index = i;  break;
    end
end

filename_ATTR = E.attribute(filename_attr_index);

filenameVector = E.attributeToDoubleArray(filename_attr_index);

disp(E.attributeStats(E.classIndex));

E.deleteStringAttributes;

wekaSaveArff('datasets/LOW-HIGH_unconsolidated.arff', E);

%% BUILD CLASSIFIER ON TRAIN SET

classifier_type = 'trees.RandomForest';
classifier_options = '-I 100 -K 7 ';

fprintf('Training model: \nType: %s\nOptions: %s\n', classifier_type, classifier_options);

model = wekaTrainModel(E, classifier_type, classifier_options);

%% Leave-one-image-out cross-validation folds - randomly selected

% Image folds:
testSplitSize = 3;
numFolds = 20;

% From previously saved filename vectors ..
filename_attr =  filenameVector; % To be clear . .
filename_groups = unique(filename_attr);

label_attr = E.attributeToDoubleArray(E.classIndex);

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
classifier_options = '-I 100 -K 9 ' ;

fprintf('Leave-one-image-out Cross-Validation: \n');
fprintf('%s \n', char(E.classAttribute));
fprintf('NumFolds: %i \n', numFolds);
fprintf('Test split size: %i \n', testSplitSize);

for f = [1, 10, 11] %length(feature_set_names)
    
    % Copy original dataset 
    F = wekaCopyDataset(E, E.numInstances); 
    F.deleteStringAttributes();
    
    % Name of feature set grouping
    feature_set_name = feature_set_names{f};
    
    fprintf('Feature set: %s \n', feature_set_name);
    
    % Subsetting attributes
    if ~strcmpi(feature_set_name, 'ALL')
        
        % Indices of selected feature set 
        feature_set_idx = [feature_set_idxs{f} E.classIndex+1];       % Don't delete the class index either .. 
        feature_set_str = num2str(feature_set_idx);                 % Convert attribute indices to string
        feature_set_str = regexprep(feature_set_str, '\s*', ',');   % Replace whitespace with single comma
        
        remove_filter_options = ['-R ' feature_set_str ' -V'];  
            
        F = wekaApplyFilter(E, 'weka.filters.unsupervised.attribute.Remove', remove_filter_options);
    end
    
    % Cross-fold validation 
    for i = 1:numFolds

        train = Instances(F, length(loi_folds(i).train_idx));    % Init train as the primary dataset
        test = Instances(F, length(loi_folds(i).test_idx));      % Init test as empty dataset
        
        test_idx = loi_folds(i).test_idx;
        train_idx = loi_folds(i).train_idx;
                
        for j = 1:length(test_idx)   % For each selected test index in this fold
            test.add(F.instance(test_idx(j)));                          % Add this instance index to test from D
        end

        for j = 1:length(train_idx)   % For each selected test index in this fold
            train.add(F.instance(train_idx(j)));                          % Add this instance index to test from D
        end
       
        model = wekaTrainModel(train, classifier_type, classifier_options);

        [classPreds classProbs confusionMatrix] = wekaClassify(test, model);

        errorRate = sum(test.attributeToDoubleArray(test.classIndex) ~= classPreds)/test.numInstances;

        fprintf('Fold %i error rate: %0.2f \n', i, errorRate);

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
    disp(ac)
    disp('------------------------');
    
end

