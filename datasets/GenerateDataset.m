function [status cmdout] = GenerateDatasetCSV( varargin )
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

p = inputParser;

check_dir = @(x)  ~ any(cellfun( @(y) exist(y, 'dir'), x )==0);
check_file_exists = @(x) ~ exist(x, 'file') == 0;

p.addRequired('Root', @(x) ~ exist(x, 'dir') == 0) ;
p.addParamValue('Type', 'csv', @(x) strcmpi(x, 'csv') || strcmpi(x, 'arff'))
p.addParamValue('Directory', check_dir);
p.addParamValue('Labels', check_file_exists);
p.addParamValue('Filenames', check_file_exists);
p.addParamValue('Classes', @iscellstr);
p.addParamValue('Output', @ischar);
p.addParamValue('LabelsFile', false, @islogical);
p.addParamValue('HeadersFile', false, @islogical);
p.addParamValue('Limit', -1, @isnumeric);
p.addParamValue('AssignZeros', -1, @(x) x==true || x == false);

p.parse(varargin{:});

feature_dirs = p.Results.Directory;
label_path   = p.Results.Labels;
filename_path= p.Results.Filenames;
sel_classes  = p.Results.Classes;
output_path  = p.Results.Output;
output_type  = p.Results.Type;
assign_zeros = tercond(p.Results.AssignZeros == -1, '-assign-zeros', '-no-assign-zeros');

%% Run script

script_name = tercond(strcmpi(output_type, 'csv'), 'gen_dataset_csv.py', 'gen_dataset_arff.py');
script_path  = [p.Results.Root '/datasets/' script_name ];

feature_dirs_str = repmat('%s ', 1, length(feature_dirs) ) ;
sel_classes_str = repmat('%s ', 1, length(sel_classes ) ) ;

if strcmpi(output_type, 'csv')
    
    separate_labels = tercond(p.Results.LabelsFile, '-labelfile', '-no-labelfile');
    separate_headers = tercond(p.Results.HeadersFile, '-headerfile', '-no-headerfile');
    
    cmd_sprintf_str = ['%s %s %s ' feature_dirs_str ' %s ' sel_classes_str ' %s %s %s %s %s %s']  ; % Construct sprintf string

    cmd = sprintf(cmd_sprintf_str, 'python', script_path, '-dir', feature_dirs{:}, '-class', sel_classes{:}, '-labels', label_path, ...
                                                    '-output', output_path, separate_labels, separate_headers);

    if p.Results.Limit ~= -1
        cmd = [cmd sprintf(' %s %s', '-limit-obs', num2str(p.Results.Limit))];
    end

    [status, cmdout] = system(cmd, '-echo'); % For stdout as script runs

elseif strcmpi(output_type, 'arff')
      
    cmd_sprintf_str = ['%s %s %s ' feature_dirs_str ' %s ' sel_classes_str ' %s %s %s %s %s %s %s']  ; % Construct sprintf string

    
    
    cmd = sprintf(cmd_sprintf_str, 'python', script_path, '-dir', feature_dirs{:}, '-class', sel_classes{:}, '-labels', label_path, ...
                  '-filenames', filename_path, '-output', output_path, assign_zeros);

    if p.Results.Limit ~= -1
        cmd = [cmd sprintf(' %s %s', '-limit-obs', num2str(p.Results.Limit))];
    end
    
    disp(cmd);
    
    [status, cmdout] = system(cmd, '-echo'); % For stdout as script runs
    
else
    disp('Invalid inputs to GenerateDataset'); % Should not reach this point because inputs are parsed but w/e
end


end