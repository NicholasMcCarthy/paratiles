function filterObj = wekaFilter( varargin )
%WEKAFILTER Summary of this function goes here
%   Detailed explanation goes here

%% Parse inputs

if nargin == 0
    error('MATLAB:wekaFilter', 'Missing input arguments.');
elseif nargin > 2
    error('MATLAB:wekaFilter', 'Too many input arguments.');
end

filter_type = varargin{1};
options_set = false;

if nargin == 2
    options_string = varargin{2};
    options_set = true;
end

% Check that model is a weka classifier object. Otherwise throw an error.
if isempty(regexp(filter_type, 'weka.filters', 'once'))
    error('MATLAB:saveWekaModel', 'Must supply a valid weka.filters object: %s \n', filter_type);
end

%% Main 

% Create filter object
filterObj = javaObject(filter_type);

if options_set
    
    options_cell = stringsplit(options_string, ' ');
    options = javaArray('java.lang.String', length(options_cell));

    for i=1:length(options_cell)
        options(i) = java.lang.String(options_cell{i}); 
    end;
        
    filterObj.setOptions(options);
    
end

end

