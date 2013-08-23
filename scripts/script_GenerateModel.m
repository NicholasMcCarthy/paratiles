% This script is roughwork for generating a model for specified classes using a feature set.


%% Load dataset(s)

classlabels = {'G3', 'G34' 'G4', 'G45', 'G5', 'TIS'};

output_path = ['datasets/' thisclass{:} '_ALL-FEATURES.arff']


%% Filter dataset

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