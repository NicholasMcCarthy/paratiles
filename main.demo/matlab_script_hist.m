%% Extracting image features from images in a directory

HOME_DIR = '/media/Data/PCRC_Dataset/';
OUTPUT_FILE = '/home/nick/matlab_im.csv';

image_data = [];
file = '/home/nick/matlab_im.csv';
starttime = getTimeStr;

%{ EMAIL REPORT VARS }%

subject = 'Matlab processing ';

fprintf('\nSearching directory structure ..\n');

%% SEARCHING TILE AND MASK IMAGE DIRECTORIES
for i = 1:20;
    
    image_dir = strcat('/media/Data/PCRC_Dataset/', int2str(i));
    
    if (exist(image_dir, 'dir'));
        
        dir_search = dir(strcat(image_dir, '/*8.tif'));        
        
        if size(dir_search, 1) ~= 1
            continue; % more than 1 match ..
        else
            image_filename = dir_search(1).name;
            image_size = (dir_search(1).bytes/1024)/1024;
        end;
        
        if (exist(strcat(image_dir, '/', image_filename), 'file')) 
            fprintf('Found image: %s\n', image_filename);
            fprintf('Size: %6.2fMB\n', image_size);
            i_data = struct('image_dir', image_dir, 'image_filename', image_filename);
            image_data = [image_data i_data];
        else 
            fprintf('No image found in dir: %s\n', image_dir);
        end;
               
        
        %{
        % Tiles
        tile_dir = strcat(image_dir, '/tiles');
                
        if (exist(tile_dir) == 7);
            tiles = dir(strcat(tile_dir, '/*.tif'));
            numTiles = size(tiles, 1);
        else
            disp('Error, no tiles directory found.');
        end;
         
        % Masks
        mask_dir = strcat(image_dir, '/mtiles');

        if (exist(mask_dir) == 7);
            masks = dir(strcat(mask_dir, '/*.tif'));
            numMasks = size(masks, 1);
            
        else
            disp('Error, no masks directory found.');
        end;
        
        % Details, error checking
        details = strcat('Tiles:', ' ', int2str(numTiles), '\t Masks:', ' ', int2str(numMasks));
        error = '';
        if numMasks ~= numTiles;
            error = strcat(error, 'Error: Number of masks and tiles should be equal!\t');
        elseif ((numTiles == 0) || (numMasks==0));
            error = strcat(error, 'Error: No masks or tiles!\t');
        end;
                
        fprintf(strcat(image_dir, '\t', details, '\t', error, '\n'));   
        
        if (strcmp(error,'') == 0);
            continue; % Don't save data if error reading mask or tile images.
        else
            i_data = struct('image_dir', image_dir, 'tile_dir', tile_dir, 'mask_dir', mask_dir, ...
                            'tiles', tiles, 'masks', masks);
            
            image_data = [image_data i_data];
        
        end;
        %}
        
        
    else
        disp(strcat('Error:', ' ', image_dir, ' ',  ' is not a directory.'));
    end        
end
    

%{
%% FEATURE EXTRACTION AND CLASS LABELING

fprintf('\nProcessing tiles ..\n');

for i = 1:length(image_data);   
        
    disp(strcat('Feature extraction: ', image_data(i).image_dir)); % Should include number of tiles here 
    
    for j = 1:length(image_data(i).tiles)
        
        % Reading files
        filepath_tile = strcat(image_data(i).tile_dir, '/', image_data(i).tiles(j).name);
        filepath_mask = strcat(image_data(i).mask_dir, '/', image_data(i).masks(j).name);
        im_rgb = imread(filepath_tile);
        im_lab = rgb2cielab(im_rgb);  % Converting RGB image to CIEL*a*b*
        mask = imread(filepath_mask);
        
        % Extracting texture features from RGB image
        
        F_rgb_r_8 = haralick(im2glcm(im_rgb(:,:,1), 8));    % GLCM with 8 gray-levels
        F_rgb_g_8 = haralick(im2glcm(im_rgb(:,:,2), 8));
        F_rgb_b_8 = haralick(im2glcm(im_rgb(:,:,3), 8));
        
        F_rgb_r_16 = haralick(im2glcm(im_rgb(:,:,1), 16));  % GLCM with 16 gray-levels
        F_rgb_g_16 = haralick(im2glcm(im_rgb(:,:,2), 16));
        F_rgb_b_16 = haralick(im2glcm(im_rgb(:,:,3), 16));
        
        F_rgb_r_32 = haralick(im2glcm(im_rgb(:,:,1), 32)); % % GLCM with 32 gray-levels
        F_rgb_g_32 = haralick(im2glcm(im_rgb(:,:,2), 32));
        F_rgb_b_32 = haralick(im2glcm(im_rgb(:,:,3), 32));
        
        % Extracting texture features from CIEL*a*b* image
        
        F_lab_l_8 = haralick(im2glcm(im_lab(:,:,1), 8));
        F_lab_a_8 = haralick(im2glcm(im_lab(:,:,2), 8));
        F_lab_b_8 = haralick(im2glcm(im_lab(:,:,3), 8));
        
        F_lab_l_16 = haralick(im2glcm(im_lab(:,:,1), 16));
        F_lab_a_16 = haralick(im2glcm(im_lab(:,:,2), 16));
        F_lab_b_16 = haralick(im2glcm(im_lab(:,:,3), 16));
        
        F_lab_l_32 = haralick(im2glcm(im_lab(:,:,1), 32));
        F_lab_a_32 = haralick(im2glcm(im_lab(:,:,2), 32));
        F_lab_b_32 = haralick(im2glcm(im_lab(:,:,3), 32));
                
        image_data(i).tiles(j).features = ...
                    horzcat(F_rgb_r_8',  F_rgb_g_8',  F_rgb_b_8', ...
                            F_rgb_r_16', F_rgb_g_16', F_rgb_b_16', ...
                            F_rgb_r_32', F_rgb_g_32', F_rgb_b_32', ...
                            F_lab_l_8',  F_lab_a_8',  F_lab_b_8', ...
                            F_lab_l_16', F_lab_a_16', F_lab_b_16', ...
                            F_lab_l_32', F_lab_a_32', F_lab_b_32' );
        
        % Determining class label from mask
        
        label = get_class_label(mask);
        image_data(i).tiles(j).label = label;
        
    end;
    
    message = strcat('Feature extraction completed from ', image_data(i).image_dir);
    send_mail(subject, message);
    
end

message = 'All feature extraction completed!';
send_mail(subject, message);

%% WRITING OUTPUT TO CSV

fprintf('\nWriting output to: %s\n', file);

fid = fopen(file, 'wt');

% WRITE FILE HEADERS
fprintf(fid, strcat('img_dir,filename,', ...
    'rgb_r_8_f1,rgb_r_8_f2,rgb_r_8_f3,rgb_r_8_f4,rgb_r_8_f5,rgb_r_8_f6,rgb_r_8_f7,rgb_r_8_f8,rgb_r_8_f9,rgb_r_8_f10,rgb_r_8_f11,rgb_r_8_f12,rgb_r_8_f13,', ... 
    'rgb_g_8_f1,rgb_g_8_f2,rgb_g_8_f3,rgb_g_8_f4,rgb_g_8_f5,rgb_g_8_f6,rgb_g_8_f7,rgb_g_8_f8,rgb_g_8_f9,rgb_g_8_f10,rgb_g_8_f11,rgb_g_8_f12,rgb_g_8_f13,', ... 
    'rgb_b_8_f1,rgb_b_8_f2,rgb_b_8_f3,rgb_b_8_f4,rgb_b_8_f5,rgb_b_8_f6,rgb_b_8_f7,rgb_b_8_f8,rgb_b_8_f9,rgb_b_8_f10,rgb_b_8_f11,rgb_b_8_f12,rgb_b_8_f13,', ... 
    'rgb_r_16_f1,rgb_r_16_f2,rgb_r_16_f3,rgb_r_16_f4,rgb_r_16_f5,rgb_r_16_f6,rgb_r_16_f7,rgb_r_16_f8,rgb_r_16_f9,rgb_r_16_f10,rgb_r_16_f11,rgb_r_16_f12,rgb_r_16_f13,', ... 
    'rgb_g_16_f1,rgb_g_16_f2,rgb_g_16_f3,rgb_g_16_f4,rgb_g_16_f5,rgb_g_16_f6,rgb_g_16_f7,rgb_g_16_f8,rgb_g_16_f9,rgb_g_16_f10,rgb_g_16_f11,rgb_g_16_f12,rgb_g_16_f13,', ... 
    'rgb_b_16_f1,rgb_b_16_f2,rgb_b_16_f3,rgb_b_16_f4,rgb_b_16_f5,rgb_b_16_f6,rgb_b_16_f7,rgb_b_16_f8,rgb_b_16_f9,rgb_b_16_f10,rgb_b_16_f11,rgb_b_16_f12,rgb_b_16_f13,', ... 
    'rgb_r_32_f1,rgb_r_32_f2,rgb_r_32_f3,rgb_r_32_f4,rgb_r_32_f5,rgb_r_32_f6,rgb_r_32_f7,rgb_r_32_f8,rgb_r_32_f9,rgb_r_32_f10,rgb_r_32_f11,rgb_r_32_f12,rgb_r_32_f13,', ... 
    'rgb_g_32_f1,rgb_g_32_f2,rgb_g_32_f3,rgb_g_32_f4,rgb_g_32_f5,rgb_g_32_f6,rgb_g_32_f7,rgb_g_32_f8,rgb_g_32_f9,rgb_g_32_f10,rgb_g_32_f11,rgb_g_32_f12,rgb_g_32_f13,', ... 
    'rgb_b_32_f1,rgb_b_32_f2,rgb_b_32_f3,rgb_b_32_f4,rgb_b_32_f5,rgb_b_32_f6,rgb_b_32_f7,rgb_b_32_f8,rgb_b_32_f9,rgb_b_32_f10,rgb_b_32_f11,rgb_b_32_f12,rgb_b_32_f13,', ... 
    'lab_l_8_f1,lab_l_8_f2,lab_l_8_f3,lab_l_8_f4,lab_l_8_f5,lab_l_8_f6,lab_l_8_f7,lab_l_8_f8,lab_l_8_f9,lab_l_8_f10,lab_l_8_f11,lab_l_8_f12,lab_l_8_f13,', ... 
    'lab_a_8_f1,lab_a_8_f2,lab_a_8_f3,lab_a_8_f4,lab_a_8_f5,lab_a_8_f6,lab_a_8_f7,lab_a_8_f8,lab_a_8_f9,lab_a_8_f10,lab_a_8_f11,lab_a_8_f12,lab_a_8_f13,', ... 
    'lab_b_8_f1,lab_b_8_f2,lab_b_8_f3,lab_b_8_f4,lab_b_8_f5,lab_b_8_f6,lab_b_8_f7,lab_b_8_f8,lab_b_8_f9,lab_b_8_f10,lab_b_8_f11,lab_b_8_f12,lab_b_8_f13,', ... 
    'lab_l_16_f1,lab_l_16_f2,lab_l_16_f3,lab_l_16_f4,lab_l_16_f5,lab_l_16_f6,lab_l_16_f7,lab_l_16_f8,lab_l_16_f9,lab_l_16_f10,lab_l_16_f11,lab_l_16_f12,lab_l_16_f13,', ... 
    'lab_a_16_f1,lab_a_16_f2,lab_a_16_f3,lab_a_16_f4,lab_a_16_f5,lab_a_16_f6,lab_a_16_f7,lab_a_16_f8,lab_a_16_f9,lab_a_16_f10,lab_a_16_f11,lab_a_16_f12,lab_a_16_f13,', ... 
    'lab_b_16_f1,lab_b_16_f2,lab_b_16_f3,lab_b_16_f4,lab_b_16_f5,lab_b_16_f6,lab_b_16_f7,lab_b_16_f8,lab_b_16_f9,lab_b_16_f10,lab_b_16_f11,lab_b_16_f12,lab_b_16_f13,', ... 
    'lab_l_32_f1,lab_l_32_f2,lab_l_32_f3,lab_l_32_f4,lab_l_32_f5,lab_l_32_f6,lab_l_32_f7,lab_l_32_f8,lab_l_32_f9,lab_l_32_f10,lab_l_32_f11,lab_l_32_f12,lab_l_32_f13,', ... 
    'lab_a_32_f1,lab_a_32_f2,lab_a_32_f3,lab_a_32_f4,lab_a_32_f5,lab_a_32_f6,lab_a_32_f7,lab_a_32_f8,lab_a_32_f9,lab_a_32_f10,lab_a_32_f11,lab_a_32_f12,lab_a_32_f13,', ... 
    'lab_b_32_f1,lab_b_32_f2,lab_b_32_f3,lab_b_32_f4,lab_b_32_f5,lab_b_32_f6,lab_b_32_f7,lab_b_32_f8,lab_b_32_f9,lab_b_32_f10,lab_b_32_f11,lab_b_32_f12,lab_b_32_f13,', ... 
    'label\n'));

% WRITE DATA
for i = 1:length(image_data);                   % Each image
    
    fprintf('Writing data: %s\n', image_data(i).image_dir);
    
    for j=1:length(image_data(i).tiles)       % Each image tile
        
        line = horzcat(image_data(i).image_dir, ',', image_data(i).tiles(j).name, ',', ...
            num2str(image_data(i).tiles(j).features, '%-6.10f, '), image_data(i).tiles(j).label, '\n');
        
        fprintf(fid, line);

    end;
end;

fclose(fid);

subject = strcat(subject, ' COMPLETE!');
message = 'Matlab script completed running!';
send_mail(subject, message);

disp('Completed!');
%}