function [dataset_name status cmdout] = GenerateDatasetCSV( varargin )
% Runs gen_dataset.py
% Used to generate a CSV file from a set of column csv files (i.e. the
% output of FeatureExtractor

% Inputs:
%  - dir          : Path(s) to directories containing column csvs 
%  - labels     : Path to column csv with labels for each row of column csvs
%  - classes   : Class(es) to extract 
%  - output    : The name of the outputted dataset
%  -labelfile / -nolabelfile : Write the labels for each row as a separate
%                       column csv or as the final column in the aggregated dataset csv

% Outputs: status (returned from exec of python script) cmdout (print
% messages from python script)


%% Parse inputs

check_dir = @(x)  ~ any(cellfun( @(y) exist(y, 'dir'), x )==0);
check_file = @(x) ~ exist(x, 'file') == 0;
check_boolean = @(x) x == 1 | x == 0;


p = inputParser;
p.addRequired('Root', @(x) ~ exist(x, 'dir') == 0) ;
p.addParamValue('Directory', check_dir);
p.addParamValue('Image', check_file);
p.addParamValue('Labels', check_file);
p.addParamValue('Filenames', check_file);
p.addParamValue('AssignIDs', 0, check_boolean);
p.addParamValue('AssignClasses', 0, check_boolean);

p.parse(varargin{:});

feature_dirs = p.Results.Directory;
image_path = p.Results.Image;
label_path   = p.Results.Labels;
filenames_path = p.Results.Filenames;
assign_ids = p.Results.AssignIDs;

if p.Results.AssignClasses == 1
    assign_classes = '-assign-classes';
else
    assign_classes = '-no-assign-classes';
end

script_path  = [p.Results.Root '/datasets/' 'gen_imagedataset.py' ];

%% 

feature_dirs_str = repmat('%s ', 1, length(feature_dirs) ) ;

cmd_sprintf_str = ['%s %s %s ' feature_dirs_str ' %s %s %s %s %s %s %s']  ; % Construct sprintf string

cmd = sprintf(cmd_sprintf_str, 'python', script_path, '-dir', feature_dirs{:}, '-image', image_path, ...
                            '-labels', label_path, '-filenames', filenames_path, assign_classes);

disp(cmd);
                                            
[status, cmdout] = system(cmd, '-echo'); % For stdout as script runs

dataset_name = regexprep(image_path, 'scn', 'arff');

end