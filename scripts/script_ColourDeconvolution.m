% A script for performing colour deconvolution on selected images..


images_set1 = getFiles(env.training_image_dir, 'Wildcard', '.scn');
images_set2 = getFiles(env.validation_image_dir, 'Wildcard', '.tiff');

% selected_images = [ images_set1([5 8 18]) ; images_set2([6 21 32]) ]

selected_images = [ images_set1 ; images_set2 ];

if matlabpool('size') == 0
    matlabpool local 4;
end

%% Main

colourDeconvolve = @(block) ColourDeconvolve(block.data);

for i = 1:length(selected_images);
   
    image_path = selected_images{i};
    
    disp(image_path);

    % Determine filetype (.scn or .tiff)
    file_type = fliplr(strtok(fliplr(image_path), '.'));

    % Use different IFD depending on filetype
    if strcmp(file_type,'scn')
        use_IFD = 8;
    elseif strcmp(file_type, 'tiff')
        use_IFD = 1;
    end
    
    % Unpack base image, get path to selected IFD
    unpacked_images = unpackTiff(image_path, use_IFD, true)
    
    big_image = unpacked_images{1};
    
    output_image = regexprep(image_path, [ '.' file_type], '-cd.tif');
    
    blockproc(big_image, [512 512], colourDeconvolve, 'Destination', output_image);
    
    repackTiff(image_path);
    
    sendmail('nicholas.mccarthy@gmail.com', 'Colour deconvolution script', ['Beep boop: ' image_path]);
    
end