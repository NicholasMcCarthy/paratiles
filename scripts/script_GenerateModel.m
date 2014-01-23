% This script is roughwork for generating a model for specified classes using a feature set.


%% Load dataset(s)

dataset_path = ['datasets/ICPR_features.arff'];

D = wekaLoadArff(dataset_path);

fprintf('Dataset: %s  \t %i features, %i instances \n', dataset_path, D.numAttributes, D.numInstances);
fprintf(['Class attribute: ' char(D.classAttribute.toString) '\n']);


%% Convert class attribute (and sample if necessary)

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

%% Filter dataset

D.numInstances
disp('Removing samples ..');
D = wekaApplyFilter(D, 'weka.filters.unsupervised.instance.Resample', '-S 1998 -Z 50');

%% Subset dataset

selected_idx = [106:465];



%%

classcombns = combnk(classlabels, 2);

% For each binary combination of classes
for i = 1:length(classcombns)
    
    [C1 C2] = deal(classcombns{i,:});
    
    % Load datasets
    C1_path = ['datasets/' C1 '_ALL-FEATURES.arff'];
    C2_path = ['datasets/' C2 '_ALL-FEATURES.arff'];

    fprintf('Loading dataset: %s \n', C1_path);
    D1 = wekaLoadArff(C1_path);

    fprintf('Loading dataset: %s \n', C2_path);
    D2 = wekaLoadArff(C2_path);
    
    % Join datasets
    
    mydata = weka.core.Instances.mergeInstances(D1, D2);
    
    % Resample both datasets to equal values
    num_samples = min(D1.numInstances, D2.numInstances);
    
    
    E = wekaApplyFilter(D, , '-S 1998 -Z 10');
    filter_name = 'weka.filters.unsupervised.instance.Resample';
    filter_options = 
    
    D1 = wekaApplyFilter
    
    
end



%% Train Classifier



%% Evaluate Classifier