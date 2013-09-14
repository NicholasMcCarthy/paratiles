% This script gives examples of using the GenerateDatasetCSV function.

%% Generate individual datasets for multiple files

feature_dirs = {'datasets/HARALICK_LAB', 'datasets/SHAPE.features', ...
                'datasets/HISTOGRAM_LAB', 'datasets/CICM-r1.features'};
%                 'datasets/HISTOGRAM_RGB', 'datasets/HARALICK_RGB'};

label_path = 'datasets/class.info/labels.csv';

classlabels = {'NON', 'TIS', 'G3', 'G34', 'G4', 'G45', 'G5'};
spec_limit = 50000;

output_type = 'arff';

writeHeaders = false;       % Irrelevant for ARFF files
writeLabels = false;

dataset_name = 'all-classes_lab-shape-cicm';

output_path = ['datasets/' dataset_name '.' output_type];
    
[status cmdout] = GenerateDataset( env.root_dir, 'Type', output_type, ...
                        'Directory', feature_dirs, 'Labels', label_path, ...
                        'Classes', classlabels, 'Output', output_path, ...
                        'LabelsFile', writeLabels, 'HeadersFile', writeHeaders, 'Limit', spec_limit, 'AssignZeros', 0);

%% Generate ARFF dataset for NONCANCER TILES

feature_dirs = {'datasets/HISTOGRAM.features'};

label_path = 'datasets/class.info/labels.csv';

classlabels = {'G3', 'G34', 'G4', 'G45', 'G5', 'NON', 'TIS'};

spec_limit = 50000;     % Limit the number of obs (only limits TIS and NON classes)

output_path = 'datasets/all-classes.arff';
output_type = 'arff';

writeHeaders = false;       % Irrelevant for ARFF files
writeLabels = false;

[status cmdout] = GenerateDataset( env.root_dir, 'Type', output_type, 'Directory', feature_dirs, 'Labels', label_path, ...
                                      'Classes', classlabels, 'Output', output_path, ...
                                      'LabelsFile', writeLabels, 'HeadersFile', writeHeaders, 'Limit', spec_limit);

%% Generate ARFF dataset for CANCER TILES {G3, G34, G4, G45, G5}

feature_dirs = {'datasets/HISTOGRAM.features'};

label_path = 'datasets/class.info/labels.csv';

classlabels = {'G3', 'G4', 'G5', 'TIS'};

spec_limit = -1;
output_path = 'datasets/G3-G4-G5-TIS_HISTOGRAM.arff';
output_type = 'arff';

writeHeaders = false;       % Irrelevant for ARFF files
writeLabels = false;

[status cmdout] = GenerateDataset( env.root_dir, 'Type', output_type, 'Directory', feature_dirs, 'Labels', label_path, ...
                                      'Classes', classlabels, 'Output', output_path, ...
                                      'LabelsFile', writeLabels, 'HeadersFile', writeHeaders, 'Limit', spec_limit);

%% Generate individual class datasets using all features

feature_dirs = {'datasets/HISTOGRAM.features', 'datasets/SHAPE.features', ...
                'datasets/HARALICK.features', 'datasets/HARALICK2.features', 'datasets/CICM-r1.features'};

label_path = 'datasets/class.info/labels.csv';

classlabels = {'G3', 'G34' 'G4', 'G45', 'G5', 'TIS'};

obs_limit = 100000;
output_type = 'arff';
writeHeaders = false;       % Irrelevant for ARFF files
writeLabels = false;

for c_idx = 4:length(classlabels)

%     for f_idx = 1:length(feature_dirs)
        
%         thisfeature = feature_dirs(f_idx);
        thisclass = classlabels(c_idx);

        output_path = ['datasets/' thisclass{:} '_ALL-FEATURES.arff']

        [status cmdout] = GenerateDataset( env.root_dir, 'Type', output_type, 'Directory', feature_dirs, 'Labels', label_path, ...
                                          'Classes', thisclass, 'Output', output_path, ...
                                          'LabelsFile', writeLabels, 'HeadersFile', writeHeaders, 'Limit', obs_limit);
                                      
%     end
end