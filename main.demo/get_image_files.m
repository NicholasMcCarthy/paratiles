function [ images masks ] = get_image_files( data_dir )

images = dir(strcat(data_dir, '*8.tif'));
masks = dir(strcat(data_dir, '*mask-PT.gs.tif'));

% Masks and images struct should be the same length .. 
if (~length(masks) == length(images))
    error('Something wrong with images and masks? I dunno.')
end

% And should be paired 
for i = 1:length(masks)
    
    image = images(i).name;
    mask = masks(i).name;
    
    if (~strcmp(regexprep(image, '.8.tif', ''), regexprep(mask, '.mask-PT.gs.tif', '')))
        error('Mismatched image and mask.');
    end
end

end

