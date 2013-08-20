function filtered_data = wekaApplyFilter( data, filter, option_string )
%WEKAAPPLYFILTER Apply a named Weka filter to an Instances object.
%   data    : A Weka Instances object.
%   filter  : A string for a valid Weka filter. E.g. 'weka.filters.supervised.instance.Resample'
%   options : An option string for the filter. E.g. '-S 1 -Z 100'

if exist('option_string', 'var')
    filterObj = wekaFilter(filter, option_string);
else
    filterObj = wekaFilter(filter);
end
    
filterObj.setInputFormat(data);

filtered_data = filterObj.useFilter(data, filterObj);

end
