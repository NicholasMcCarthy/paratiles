% This is a demo script showing how a dataset CSV or ARFF file can be
% generated from the column csvs produced  by FeatureExtractor

% Calls a python script 'gen_dataset_csv.py' with the specified options.
% The class column and header row can be written to separate files if
% specified. 

% Multiple directories of column CSV files can be specified
feature_dirs = {'datasets/HISTOGRAM.features' 'datasets/HARALICK.features', ...
                'datasets/SHAPE.features', 'datasets/CICM-r1.features'};
% feature_dirs = cellfun(@(x) [env.root_dir '/' x], feature_dirs, 'UniformOutput', false);

% Give a path to a columnar label file specifying the class values of
% each row in the specified feature dirs
label_path = 'datasets/class.info/labels.csv';

% The classes to select from the labels file 
classlabels = {'G3', 'G4'};

% Specify where to write the completed dataset to.
output_path = 'datasets/G3-G4.arff';
output_type = 'arff';

% Limit the outputted dataset to a certain number of observations.
spec_limit = -1;

% ----------------
% CSV ONLY OPTIONS (will be ignored if arff type is specified

% Write the headers to a separate file? If the output file given is (for
% example) 'G3-G4.csv', headers will be written to 'G3-G4.headers.csv' as a
% comma-separated _ROW_
writeHeaders = false;

% Write labels to a separate file? G3-G4.csv -> G3-G4.labels.csv as a
% _COLUMN_ file (so indices match)
writeLabels = false;

% Call to function that calls the python script
[status cmdout] = GenerateDataset( env.root_dir, 'Type', output_type, 'Directory', feature_dirs, 'Labels', label_path, ...
                                      'Classes', classlabels, 'Output', output_path, ...
                                      'LabelsFile', writeLabels, 'HeadersFile', writeHeaders, 'Limit', spec_limit);


                                  
%% 

