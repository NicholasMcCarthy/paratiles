function [status] = repackTiff( file_path )
%REPACKTIFF Given an input file, cleans up any of the unpack'd Tiff files
%from the paired 'unpackTiff' function.

fprintf('repackTiff(%s)', file_path);

file_prefix = [ '.' fliplr(strtok(fliplr(file_path), '.'))];

tiffsplit_wildcard = regexprep(file_path, file_prefix, '_aa*'); % Replace .tif with file identifier

%deleted_files = ls(tiffsplit_wildcard);

rm_cmd = sprintf('rm %s', tiffsplit_wildcard);

status = system(rm_cmd);

end