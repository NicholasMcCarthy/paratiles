function fileList = getFiles(varargin)

% Input: directory path, optional suffix and string wildcards for file
% selection
% Output: list of files ..

%% Parse inputs

p = inputParser;

p.addRequired('Directory', @(x) exist(x, 'dir'))
p.addParamValue('Suffix', [], @(x)ischar(x));
p.addParamValue('Wildcard', [], @(x)ischar(x));
p.addParamValue('Exclude', [], @(x)ischar(x));

p.parse(varargin{:});

dirName = p.Results.Directory;
suffix = p.Results.Suffix;
wildcard = p.Results.Wildcard;
exclude = p.Results.Exclude;

%% Search directories


  dirData = dir(dirName);                               %# Get the data for the current directory
  dirIndex = [dirData.isdir];                           %# Find the index for directories
  fileList = {dirData(~dirIndex).name}';                %'# Get a list of the files
  if ~isempty(fileList)
    fileList = cellfun(@(x) fullfile(dirName,x),...     %# Prepend path to files
                       fileList,'UniformOutput',false);
  end
  subDirs = {dirData(dirIndex).name};                   %# Get a list of the subdirectories
  validIndex = ~ismember(subDirs,{'.','..'});           %# Find index of subdirectories
                                                        %#   that are not '.' or '..'
  for iDir = find(validIndex)                           %# Loop over valid subdirectories
    nextDir = fullfile(dirName,subDirs{iDir});          %# Get the subdirectory path
    fileList = [fileList; getFiles(nextDir)];        %# Recursively call getAllFiles
  end

  % Select files with suffix 
  if ~isempty(suffix)
    filesWithSuffixIdx = cellfun(@(x) ~isempty(strfind(x(last_period(x):end), suffix)), fileList);
    fileList = fileList(filesWithSuffixIdx);
  end
 
  % Select files with wildcard
   if ~isempty(wildcard)
    filesWithWildcardIdx = cellfun(@(x) ~isempty(strfind(x, wildcard)), fileList);
    fileList = fileList(filesWithWildcardIdx);
   end
  
   % Remove files that match exclude term
   if ~isempty(exclude)
    filesWithExcludeIdx = cellfun(@(x) isempty(strfind(x, exclude)), fileList);
    fileList = fileList(filesWithExcludeIdx);
  end
  
end

% Too tired to write an inline function for finding the last period (i.e.
% suffix idx) in a filename, so here's this small incurious one
function lpidx = last_period(path)

    periods = strfind(path, '.');

    if ~isempty(periods)
        lpidx = periods(end);
    else 
        lpidx = 0;
    end;
end
