% This script is for finding and removing tiles from the background of an
% image. 

%% SETUP 

images = getFiles(env.image_dir, 'Suffix', '.tif', 'Wildcard', '.8.tif');          % Wildcard so it selects the large .SCN layer image

tilesize = 256;

if matlabpool('size') == 0
    matlabpool local 4
end

%% Create block-image 

i = 1;

block_func = @(I) mean2(I.data);

G = blockproc(images{i}, [tilesize tilesize], block_func);

orig = G

%% imfill regions 

G = im2bw(G)