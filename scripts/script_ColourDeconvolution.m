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


%% Testing different OD matrix default values (on smaller images for ease);

images = getFiles([env.root_dir '/colour.normalisation/color-deconvolution/'], 'Wildcard', 'jpg');


%% Plotting the difference between different OD presets .. 

I = imread('hestain.png');

OD_Preset1 = [0.18 0.20 0.08 ; 0.01 0.13 0.01 ; 0.10 0.21 0.29];
OD_Preset2 = [0.18 0.20 0.08 ; 0.01 0.13 0.01 ; 0 0 0];

IC1 = ColourDeconvolve(I, OD_Preset1);

IC2 = ColourDeconvolve(I, OD_Preset2);

IC3 = imabsdiff(IC1, IC2);

subplot(4,4,1), imshow(I); title('RGB');
subplot(4,4,5), imshow(I(:,:,1)); title('R');
subplot(4,4,9), imshow(I(:,:,2)); title('G');
subplot(4,4,13), imshow(I(:,:,3)); title('B');

subplot(4,4,2), imshow(IC1); title('Ruifrok Preset 1');
subplot(4,4,6), imshow(IC1(:,:,1)); title('Ruifrok Preset 1 C1');
subplot(4,4,10), imshow(IC1(:,:,2)); title('Ruifrok Preset 1 C2');
subplot(4,4,14), imshow(IC1(:,:,3)); title('Ruifrok Preset 1 C3');

subplot(4,4,3), imshow(IC2); title('Ruifrok Preset 2 C1');
subplot(4,4,7), imshow(IC2(:,:,1)); title('Ruifrok Preset 2 C2');
subplot(4,4,11), imshow(IC2(:,:,2)); title('Ruifrok Preset 2 C2');
subplot(4,4,15), imshow(IC2(:,:,3)); title('Ruifrok Preset 2 C2');

subplot(4,4,4), imshow(IC3); title('Correlation Image');
subplot(4,4,8), imshow(IC3(:,:,1)); title('Correlation Image C2');
subplot(4,4,12), imshow(IC3(:,:,2)); title('Correlation Image C2');
subplot(4,4,16), imshow(IC3(:,:,3)); title('Correlation Image C2');

