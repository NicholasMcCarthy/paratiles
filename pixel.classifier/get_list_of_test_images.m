% Quick&dirty to get list of tiles in test.images folder

function [ output_args ] = get_list_of_test_images( file_path )


dir = 'test.images';

tileset = rdir(strcat(dir, 'x*.tif')); % x000001.tif, x000002.tif, etc 


end

