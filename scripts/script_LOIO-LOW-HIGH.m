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

%% Subset data to classify G3/4 and G4/5 into {G3, G4} and {G4, G5}

disp('Initializing datasets .. ');

G3_4 = wekaCopyDataset(D, 0); % Create new dataset with same attributes
G34 = wekaCopyDataset(D, 0);   

G4_5 = wekaCopyDataset(D, 0);   
G45 = wekaCopyDataset(D, 0);   

classAttribute = D.classAttribute;
classVector = D.attributeToDoubleArray(D.classIndex);

G3_4_Values = [];
G4_5_Values = [];

disp('Subsetting datasets to {G3, G4}, {G3/4}, {G4/5}, {G4,G5}');
for i = 0:length(classVector)-1
  
    if (classVector(i+1) == 1)  % G3 
%         disp('Adding to G3');
        G3_4.add(D.instance(i));
        G3_4_Values = [G3_4_Values classVector(i+1)];
        
    elseif (classVector(i+1) == 2 ) %G3/4
%         disp('Adding to G34');
        
        G34.add(D.instance(i));
        
    elseif (classVector(i+1) == 3 ) %G4 goes to both ..
%         disp('Adding to G4'); 
        
        G3_4.add(D.instance(i));
        G3_4_Values = [G3_4_Values classVector(i+1)];
        
        G4_5.add(D.instance(i));
        G4_5_Values = [G4_5_Values classVector(i+1)];
        
    elseif (classVector(i+1) == 4 ) %G4/5
%         disp('Adding to G45');
        
        G45.add(D.instance(i));
        
    elseif (classVector(i+1) == 5 ) % G5
%         disp('Adding to G5');
        
        G4_5.add(D.instance(i));
        G4_5_Values = [G4_5_Values classVector(i+1)];
    end    
      
    
end

disp('Mapping old class index values to new ones ..');
G3_4_Values(G3_4_Values ==1) = 0;  % Map old values to new indices
G3_4_Values(G3_4_Values ==3) = 1; 

G4_5_Values(G4_5_Values == 3) = 0;
G4_5_Values(G4_5_Values == 5) = 1;

disp('Creating and assigning new attribute');
% Create and insert new attributes
G3_4_Attribute = wekaCreateAttribute('nlabel', 'nominal', {'G3', 'G4'});

G3_4.insertAttributeAt(G3_4_Attribute, G3_4.classIndex+1);
G34.insertAttributeAt(G3_4_Attribute, G34.classIndex+1);

G4_5_Attribute = wekaCreateAttribute('nlabel', 'nominal', {'G4', 'G5'});

G4_5.insertAttributeAt(G4_5_Attribute, G4_5.classIndex+1);
G45.insertAttributeAt(G4_5_Attribute, G45.classIndex+1);

% Set new attribute to class index
G3_4.setClassIndex(G3_4.classIndex+1);
G34.setClassIndex(G34.classIndex+1);
G4_5.setClassIndex(G4_5.classIndex+1);
G45.setClassIndex(G45.classIndex+1);

disp('Deleting old class attribute');
% Delete old class attribute
G3_4.deleteAttributeAt(G3_4.classIndex-1);
G34.deleteAttributeAt(G34.classIndex-1);
G4_5.deleteAttributeAt(G4_5.classIndex-1);
G45.deleteAttributeAt(G45.classIndex-1);

disp('Assigning old class values to newly created class attribute');
% Add class labels to G3_4 and G4_5 
for i = 0:length(G3_4_Values)-1
    G3_4.instance(i).setValue(G3_4.classIndex, G3_4_Values(i+1));
end

for i = 0:length(G4_5_Values)-1
    G4_5.instance(i).setValue(G4_5.classIndex, G4_5_Values(i+1));
end

% Remove string attributes

% Find index of filename attribute
for i = 0:G3_4.numAttributes
    if strfind(char(G3_4.attribute(i)), 'filename');
        filename_attr_index = i;  break;
    end
end

filename_ATTR = G3_4.attribute(filename_attr_index);

filename_G3_G4 = G3_4.attributeToDoubleArray(filename_attr_index);
filename_G34 = G34.attributeToDoubleArray(filename_attr_index);

filename_G4_G5 = G4_5.attributeToDoubleArray(filename_attr_index);
filename_G45 = G45.attributeToDoubleArray(filename_attr_index);


disp(G3_4.attributeStats(G3_4.classIndex));
disp(G34.attributeStats(G34.classIndex));

disp(G4_5.attributeStats(G4_5.classIndex));
disp(G45.attributeStats(G45.classIndex));

G3_4.deleteStringAttributes;
G34.deleteStringAttributes;
G4_5.deleteStringAttributes;
G45.deleteStringAttributes;

%% BUILD CLASSIFIER ON TRAIN SET

classifier_type = 'trees.RandomForest';
classifier_options = '-I 100 -K 7 ';

G3_4_model = wekaTrainModel(G3_4, classifier_type, classifier_options);

G4_5_model = wekaTrainModel(G4_5, classifier_type, classifier_options);

%% CLASSIFY G3/4 and G4/5 datasets

[G3_4_classPreds G3_4_classProbs G3_4_confusionMatrix] = wekaClassify(G34, G3_4_model);

% And assign predicted labels to each instance in TEST SET
for i = 0:G34.numInstances-1
    G34.instance(i).setValue(G34.classIndex, G3_4_classPreds(i+1));
end

[G4_5_classPreds G4_5_classProbs G4_5_confusionMatrix] = wekaClassify(G45, G4_5_model);

% And assign predicted labels to each instance in TEST SET
for i = 0:G45.numInstances-1
    G45.instance(i).setValue(G45.classIndex, G4_5_classPreds(i+1));
end

% And save the G3/4 and G4/5 datasets .. 
wekaSaveArff('datasets/G34_classified.arff', G34);
wekaSaveArff('datasets/G45_classified.arff', G45);

%% CONVERT DATASETS to LOW/HIGH factors 
% G3 -> LOW, G4, G5 -> HIGH

disp('Joining G3/4 to G3_4 dataset');
% Join G3_4 and G34
for i = 0:G34.numInstances-1
    G3_4.add(G34.instance(i));
end

% Remove G4 from G4_5

disp('Deleting G4 from G4_5 dataset');
disp(char(G4_5.attributeStats(G4_5.classIndex)));
for i = fliplr(0:G4_5.numInstances-1)
   
    if (G4_5.instance(i).value(G4_5.classIndex) == 0)
       G4_5.delete(i); 
       filename_G4_G5(i+1) = []; % Deleting entry from filenames vector - no overlap!
    end
    
end

disp(char(G4_5.attributeStats(G4_5.classIndex)));

disp('Joining G4/5 to G5 dataset');
% Join G4_5 and G45
for i = 0:G45.numInstances-1
    G4_5.add(G45.instance(i));
end

disp(char(G45.attributeStats(G4_5.classIndex)));

disp('Mapping G3 -> Low and {G4,G5} -> HIGH');
% Old class values
G3_4_mappedValues = G3_4.attributeToDoubleArray(G3_4.classIndex); % G3-G4 already correctly mapped 
G4_5_mappedValues = ones(G4_5.numInstances, 1);    % And all G4, G5 obs are now HIGH

% New class attribute
disp('Creating new class attribute');
newAttribute = wekaCreateAttribute('label', 'nominal', {'LOW', 'HIGH'});
G3_4.insertAttributeAt(newAttribute, G3_4.classIndex+1);
G4_5.insertAttributeAt(newAttribute, G4_5.classIndex+1);

disp('Assigning new values.');
% Assign oldValues .. 
for i = 0:G3_4.numInstances-1
    G3_4.instance(i).setValue(G3_4.classIndex+1, G3_4_mappedValues(i+1));
end

for i = 0:G4_5.numInstances-1
    G4_5.instance(i).setValue(G4_5.classIndex+1, G4_5_mappedValues(i+1));
end

disp('Setting new class index');
G3_4.setClassIndex(G3_4.classIndex+1);
G4_5.setClassIndex(G4_5.classIndex+1);


disp('Deleting old class index');
G3_4.deleteAttributeAt(G3_4.classIndex-1);
G4_5.deleteAttributeAt(G4_5.classIndex-1);

% Finally, join the two datasets .. 
disp('Joining G3_4 and G4_5 datasets .. ');
for i = 0:G4_5.numInstances-1
    G3_4.add(G4_5.instance(i));
end

disp('Done!');

wekaSaveArff('datasets/LOW-HIGH_consolidated.arff', G3_4);

%% Leave-one-image-out cross-validation folds - randomly selected

% Image folds:
testSplitSize = 2;
numFolds = 10;

% From previously saved filename vectors ..
filename_attr =  [filename_G3_G4 ; filename_G34 ; filename_G4_G5 ; filename_G45];
filename_groups = unique(filename_attr);

label_attr = G3_4.attributeToDoubleArray(G3_4.classIndex);

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
    
    nonfold_idx = [1:G3_4.numInstances];
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
fprintf('%s \n', char(G3_4.classAttribute));
fprintf('NumFolds: %i \n', numFolds);
fprintf('Test split size: %i \n', testSplitSize);

for f = [1,2,4:15] %length(feature_set_names)
    
    % Copy original dataset 
    E = wekaCopyDataset(G3_4, G3_4.numInstances); 
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

%         fprintf('Fold %i \n', i);
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
    disp(ac)
    disp('------------------------');
    
end

