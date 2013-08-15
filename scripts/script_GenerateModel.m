% This script is roughwork for generating a model for specified classes
% using a feature set.

% Script makes a call to python script gen_dataset.py that builds the csv file 

% Inputs:
%       - dir : A directory of column csvs, i.e. feature sets
%       - class : One or more classes specified in labels csv
%       - labels : Path to a column csv of labels for each row in directory
%                       feature sets
%        - output : The name of the outputted csv file

% Output: output filename written to dataset directory

script_path = [env.dataset_dir 'gen_dataset.py'];
feature_dir = [env.dataset_dir 'final/'];
sel_classes = {'G3', 'G34'};
label_path = [env.dataset_dir 'tile_info/' 'labels.csv'];
output_path = [env.dataset_dir 'test.csv'];

sel_classes_str = repmat('%s ', 1, length(sel_classes));

sprintf_str = ['%s %s %s %s %s ' sel_classes_str ' %s %s %s %s']

cmd = sprintf(sprintf_str, 'python', script_path, '-dir', feature_dir, '-class', sel_classes{:}, '-label', label_path, '-output', output_path);

[status, cmdout] = system(cmd);

if (~status)
    fprintf('Script executed successfully:\n');
    fprintf(cmdout);
else
    fprintf('There was an error executing this script:\n');
    fprintf(cmdout);
end
