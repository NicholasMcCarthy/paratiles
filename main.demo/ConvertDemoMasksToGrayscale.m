% Convert the colour mask images to grayscale for ease of labeling

[~, masks] = get_image_files(env.image_dir);

result = struct();

for i = 1:19 %length(masks);
    
    mask_filepath = strcat(env.image_dir, masks(i).name);
    disp(mask_filepath);
    
    M = imread(mask_filepath);
    
    if (size(M, 3) == 4) M = M(:,:,1:3);end;
    
    G = convert_image(M);
    
    output_filepath = regexprep(mask_filepath, 'mask-PT.colour.tif', 'mask-PT.gs.tif');
    
    result(i).mask_filepath = mask_filepath;
    result(i).values = unique(G);
    result(i).output_filepath = output_filepath;
    
    imwrite(G, output_filepath, 'TIF');
    
end

disp('Done');