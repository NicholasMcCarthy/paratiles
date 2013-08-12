function [ output_args ] = repackTiff( file_path )
%REPACKTIFF Given an input file, cleans up any of the unpack'd Tiff files
%from the paired 'unpackTiff' function.



unpacked_tiff = regexprep(file_path, '.tif', '_x*');


ls_cmd = sprintf('ls %s', unpacked_tiff);

[status cmdout] = system(ls_cmd);

deleted_files = cmdout;

rm_cmd = sprintf('rm %s', unpacked_tiff);

[status cmdout] = system(rm_cmd);

end

