% This script gives examples of using the GenerateDatasetCSV function.

%% Script inputs and variables 

% The directorys of column csvs to aggregate
feature_dirs = {'datasets/CICM.features', 'datasets/HARALICK.features', 'datasets/HISTOGRAM.features'};
feature_dirs = cellfun(@(x) [env.root_dir '/' x], feature_dirs, 'UniformOutput', false);

% The classes to select from each row
% selected_classes = {'G3', 'G4'};

% The path to the column file showing the class labels of each row
label_path = 'datasets/tile_info/labels.csv';

classlabels = {'G3', 'G34', 'G4', 'G45', 'G5'};

for i = 1:length(classlabels)

    fprintf('Generating dataset for: %s \n', classlabels{i});

    % Where to write the aggregated dataset to
    output_path = ['datasets/' classlabels{i} '_' 'HIST-CICM' 'with-labels.csv'];

    [status cmdout] = GenerateDatasetCSV( env.root_dir, 'Directory', feature_dirs, 'Labels', label_path, 'Classes', classlabels(i), 'Output', output_path, 'LabelsFile', false, 'Headersfile', true);

    disp('Completado!')
     %s %s'
end

%% 

% The directorys of column csvs to aggregate
feature_dirs = {'datasets/CICM.features', 'datasets/HARALICK.features', 'datasets/HISTOGRAM.features'};
feature_dirs = cellfun(@(x) [env.root_dir '/' x], feature_dirs, 'UniformOutput', false);

% The classes to select from each row
classlabels = {'G3', 'G4'};

% The path to the column file showing the class labels of each row
label_path = 'datasets/class.info/labels.csv';

% Where to write the aggregated dataset to
output_path = ['datasets/G3-G4.test.csv'];

% Call to function that calls the python script
[status cmdout] = GenerateDatasetCSV( env.root_dir, 'Directory', feature_dirs, 'Labels', label_path, 'Classes', classlabels, 'Output', output_path, 'LabelsFile', true, 'HeadersFile', false);


