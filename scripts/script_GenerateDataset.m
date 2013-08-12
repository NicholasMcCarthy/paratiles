% This script gives examples of using the GenerateDatasetCSV function.

%% Generate individual datasets for multiple files

feature_dirs = {'datasets/HISTOGRAM.features' 'datasets/HARALICK.features', ...
                'datasets/SHAPE.features', 'datasets/CICM-r1.features'};
            
label_path = 'datasets/class.info/labels.csv';

classlabels = {'G3', 'G34', 'G4', 'G45', 'G5'};
classlimits = {-1, -1, -1, -1, -1}  % i.e., don't limit any classes .. 

output_type = 'arff';

writeHeaders = false;       % Irrelevant for ARFF files
writeLabels = false;

dataset_name = 'rev1';

for i = 1:length(classlabels)

    output_path = ['datasets/' classlabels{i} '_' dataset_name '.' output_type];
    
    [status cmdout] = GenerateDataset( env.root_dir, 'Type', output_type, ...
                        'Directory', feature_dirs, 'Labels', label_path, ...
                        'Classes', classlabels, 'Output', output_path, ...
                        'LabelsFile', writeLabels, 'HeadersFile', writeHeaders, 'Limit', spec_limit);
end

%% Generate ARFF dataset for NONCANCER TILES

feature_dirs = {'datasets/HISTOGRAM.features'};

label_path = 'datasets/class.info/labels.csv';

classlabels = {'TIS'};

spec_limit = 70000;     % Limit the number of obs since there are a LOT of TIS tiles

output_path = 'datasets/TIS_HISTOGRAM.arff';
output_type = 'arff';

writeHeaders = false;       % Irrelevant for ARFF files
writeLabels = false;

[status cmdout] = GenerateDataset( env.root_dir, 'Type', output_type, 'Directory', feature_dirs, 'Labels', label_path, ...
                                      'Classes', classlabels, 'Output', output_path, ...
                                      'LabelsFile', writeLabels, 'HeadersFile', writeHeaders, 'Limit', spec_limit);

%% Generate ARFF dataset for CANCER TILES {G3, G34, G4, G45, G5}

feature_dirs = {'datasets/HISTOGRAM.features'};

label_path = 'datasets/class.info/labels.csv';

classlabels = {'G3', 'G34', 'G4', 'G45', 'G5'};

spec_limit = -1;
output_path = 'datasets/G3-G34-G4-G45-G6_HISTOGRAM.arff';
output_type = 'arff';

writeHeaders = false;       % Irrelevant for ARFF files
writeLabels = false;

[status cmdout] = GenerateDataset( env.root_dir, 'Type', output_type, 'Directory', feature_dirs, 'Labels', label_path, ...
                                      'Classes', classlabels, 'Output', output_path, ...
                                      'LabelsFile', writeLabels, 'HeadersFile', writeHeaders, 'Limit', spec_limit);
