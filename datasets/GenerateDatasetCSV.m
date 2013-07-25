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
check_labels = @(x) ~ exist(x, 'file') ==0;

p.addRequired('Root', @(x) ~ exist(x, 'dir') == 0) ;
p.addParamValue('Directory', check_dir);
p.addParamValue('Labels', check_labels);
p.addParamValue('Classes', @iscellstr);
p.addParamValue('Output', @ischar);
p.addParamValue('LabelsFile', true, @islogical);
p.addParamValue('HeadersFile', true, @islogical);

p.parse(varargin{:});

script_path = [p.Results.Root '/datasets/gen_dataset.py'];

label_path = p.Results.Labels;
feature_dirs = p.Results.Directory;
feature_dirs_str = repmat('%s ', 1, length(feature_dirs) ) ;
sel_classes = p.Results.Classes;
sel_classes_str = repmat('%s ', 1, length(sel_classes ) ) ;
output_path = p.Results.Output;

if p.Results.LabelsFile
    separate_labels = '-labelfile';
else
    separate_labels = '-no-labelfile';
end

if p.Results.HeadersFile
    separate_headers = '-headerfile';
else
    separate_headers = '-no-headerfile';
end

cmd_sprintf_str = ['%s %s %s ' feature_dirs_str ' %s ' sel_classes_str ' %s %s %s %s %s %s']  ; % Construct sprintf string

%% Run python script

cmd = sprintf(cmd_sprintf_str, 'python', script_path, '-dir', feature_dirs{:}, '-class', sel_classes{:}, '-labels', label_path, ...
                                                '-output', output_path, separate_labels, separate_headers);

[status, cmdout] = system(cmd, '-echo'); % For stdout as script runs
% [status, cmdout] = system(cmd);

% if (status)         % as 0 is the success 
%     fprintf('There was an error executing this script:\n');
%     fprintf(cmdout);
% else
%     fprintf('Script executed successfully:\n');
%     fprintf(cmdout);
% end
%     
% 

end

