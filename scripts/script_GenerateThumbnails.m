% A script to generate thumbnail images (will only be used until I can find
% a way to speed up / display the images in openslide with deepzoom)


images = getFiles(env.image_dir, 'Suffix', '.tif', 'Wildcard', '.9.tif');   

%%

matlabpool local 4


 %%

for i = 3:length(images)
    
    image_path = images{i};
    
    G = im2thumb(image_path, 128);
    
    output_path = regexprep(image_path, '.9.tif', '.thumbnail.tif')
    
    imwrite(G, output_path);            
    
end
    