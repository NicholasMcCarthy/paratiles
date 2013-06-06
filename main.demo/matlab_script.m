%% Extracting image features from images in a directory

image_data = [];
file = '/home/nick/matlab_im.csv';
starttime = getTimeStr;

%{ EMAIL REPORT VARS }%

subject = 'Matlab processing ';

fprintf('\nSearching directory structure ..\n');

valid_Dirs = [1,2,4,5,6,8,9,10,14,16,17,18,19,20];

%% SEARCHING TILE AND MASK IMAGE DIRECTORIES
for i = valid_Dirs;
    
    image_dir = strcat('/media/Data/PCRC_Dataset/', int2str(i));
    
    if (exist(image_dir) == 7);
        
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
    else
        disp(strcat('Error:', ' ', image_dir, ' ',  ' is not a directory.'));
    end             
end


%% FEATURE EXTRACTION AND CLASS LABELING

fprintf('\nProcessing tiles ..\n');

for i = 1:size(image_data, 2);   
    
    fprintf('Processing: %s\n', image_data(i).image_dir);

    fprintf('\t Num tiles: %d \n ', size(image_data(i).tiles, 1));
    fprintf('\t Num masks: %d \n ', size(image_data(i).masks, 1));
    
    % Extract features from each tiff tile image.
    for j = 1 : size(image_data(i).tiles, 1)
        
        % Reading files
        filepath_tile = strcat(image_data(i).tile_dir, '/', image_data(i).tiles(j).name);
        im_rgb = imread(filepath_tile);
        
        % Extracting RGB histogram and texture features
        
        H_rgb_r_stats = get_histogram_features(im_rgb(:,:,1), 'NumLevels', 256);
        H_rgb_g_stats = get_histogram_features(im_rgb(:,:,2), 'NumLevels', 256);
        H_rgb_b_stats = get_histogram_features(im_rgb(:,:,3), 'NumLevels', 256);
        
        %{
        F_rgb_r_8 = haralick(im2glcm(im_rgb(:,:,1), 8));    % GLCM with 8 gray-levels
        F_rgb_g_8 = haralick(im2glcm(im_rgb(:,:,2), 8));
        F_rgb_b_8 = haralick(im2glcm(im_rgb(:,:,3), 8));
        
        F_rgb_r_16 = haralick(im2glcm(im_rgb(:,:,1), 16));  % GLCM with 16 gray-levels
        F_rgb_g_16 = haralick(im2glcm(im_rgb(:,:,2), 16));
        F_rgb_b_16 = haralick(im2glcm(im_rgb(:,:,3), 16));
        
        F_rgb_r_32 = haralick(im2glcm(im_rgb(:,:,1), 32)); % % GLCM with 32 gray-levels
        F_rgb_g_32 = haralick(im2glcm(im_rgb(:,:,2), 32));
        F_rgb_b_32 = haralick(im2glcm(im_rgb(:,:,3), 32));
        %}
        
        % Convert RGB image to CIELab
        im_lab = rgb2cielab(im_rgb);
        
        % Extract CIELab histogram and texture features.
        
        H_lab_l_stats = get_histogram_features(im_lab(:,:,1), 'NumLevels', 256);
        H_lab_a_stats = get_histogram_features(im_lab(:,:,2), 'NumLevels', 256);
        H_lab_b_stats = get_histogram_features(im_lab(:,:,3), 'NumLevels', 256);
        
        %{
        F_lab_l_16 = haralick(im2glcm(im_lab(:,:,1), 16));
        F_lab_a_16 = haralick(im2glcm(im_lab(:,:,2), 16));
        F_lab_b_16 = haralick(im2glcm(im_lab(:,:,3), 16));
        
        F_lab_l_32 = haralick(im2glcm(im_lab(:,:,1), 32));
        F_lab_a_32 = haralick(im2glcm(im_lab(:,:,2), 32));
        F_lab_b_32 = haralick(im2glcm(im_lab(:,:,3), 32));
        %}
        
        % Read associated mask and determine class label
        filepath_mask = strcat(image_data(i).mask_dir, '/', image_data(i).masks(j).name);
        mask = imread(filepath_mask);
        label = get_class_label(mask);
        
        % Get width and length from Tiff image.
        [length, width, dim] = size(im_rgb);
        
        
        % Save data to struct
        image_data(i).tiles(j).width = width;
        image_data(i).tiles(j).length = length;
        image_data(i).tiles(j).label = label;
        
        image_data(i).tiles(j).histogram = ...
                    horzcat(H_rgb_r_stats, H_rgb_g_stats, H_rgb_b_stats, ...
                            H_lab_l_stats, H_lab_a_stats, H_lab_b_stats );
        %{
        image_data(i).tiles(j).features = ...
                    horzcat(F_rgb_r_8',  F_rgb_g_8',  F_rgb_b_8', ...
                            F_rgb_r_16', F_rgb_g_16', F_rgb_b_16', ...
                            F_rgb_r_32', F_rgb_g_32', F_rgb_b_32', ...
                            F_lab_l_8',  F_lab_a_8',  F_lab_b_8', ...
                            F_lab_l_16', F_lab_a_16', F_lab_b_16', ...
                            F_lab_l_32', F_lab_a_32', F_lab_b_32' );
        %}              
                
    end;
    
    %message = strcat('Processing complete on ', image_data(i).image_dir);
    %subject = '[MATLAB] Histogram and Feature extraction';
    %send_mail(subject, message);
    
    fprintf('Finished processing: %s\n', image_data(i).image_dir);
end

%% WRITING OUTPUT TO CSV

fprintf('\nWriting output to: %s\n', file);

fid = fopen(file, 'wt');

% WRITE FILE HEADERS
fprintf(fid, strcat('filename,tile_id,width,length,',...
    'rgb_r_min,rgb_r_mean,rgb_r_max,rgb_r_stddev,rgb_r_variance,rgb_r_skewness,rgb_r_kurtosis,rgb_r_energy,rgb_r_entropy,',...
    'rgb_g_min,rgb_g_mean,rgb_g_max,rgb_g_stddev,rgb_g_variance,rgb_g_skewness,rgb_g_kurtosis,rgb_g_energy,rgb_g_entropy,',...
    'rgb_b_min,rgb_b_mean,rgb_b_max,rgb_b_stddev,rgb_b_variance,rgb_b_skewness,rgb_b_kurtosis,rgb_b_energy,rgb_b_entropy,',...
    'lab_l_min,lab_l_mean,lab_l_max,lab_l_stddev,lab_l_variance,lab_l_skewness,lab_l_kurtosis,lab_l_energy,lab_l_entropy,',...
    'lab_a_min,lab_a_mean,lab_a_max,lab_a_stddev,lab_a_variance,lab_a_skewness,lab_a_kurtosis,lab_a_energy,lab_a_entropy,',...
    'lab_b_min,lab_b_mean,lab_b_max,lab_b_stddev,lab_b_variance,lab_b_skewness,lab_b_kurtosis,lab_b_energy,lab_b_entropy,',...
    'label\n'));

%{'rgb_r_8_f1,rgb_r_8_f2,rgb_r_8_f3,rgb_r_8_f4,rgb_r_8_f5,rgb_r_8_f6,rgb_r_8_f7,rgb_r_8_f8,rgb_r_8_f9,rgb_r_8_f10,rgb_r_8_f11,rgb_r_8_f12,rgb_r_8_f13,', ... 
 %   'rgb_g_8_f1,rgb_g_8_f2,rgb_g_8_f3,rgb_g_8_f4,rgb_g_8_f5,rgb_g_8_f6,rgb_g_8_f7,rgb_g_8_f8,rgb_g_8_f9,rgb_g_8_f10,rgb_g_8_f11,rgb_g_8_f12,rgb_g_8_f13,', ... 
 %   'rgb_b_8_f1,rgb_b_8_f2,rgb_b_8_f3,rgb_b_8_f4,rgb_b_8_f5,rgb_b_8_f6,rgb_b_8_f7,rgb_b_8_f8,rgb_b_8_f9,rgb_b_8_f10,rgb_b_8_f11,rgb_b_8_f12,rgb_b_8_f13,', ... 
 %   'rgb_r_16_f1,rgb_r_16_f2,rgb_r_16_f3,rgb_r_16_f4,rgb_r_16_f5,rgb_r_16_f6,rgb_r_16_f7,rgb_r_16_f8,rgb_r_16_f9,rgb_r_16_f10,rgb_r_16_f11,rgb_r_16_f12,rgb_r_16_f13,', ... 
 %   'rgb_g_16_f1,rgb_g_16_f2,rgb_g_16_f3,rgb_g_16_f4,rgb_g_16_f5,rgb_g_16_f6,rgb_g_16_f7,rgb_g_16_f8,rgb_g_16_f9,rgb_g_16_f10,rgb_g_16_f11,rgb_g_16_f12,rgb_g_16_f13,', ... 
 %   'rgb_b_16_f1,rgb_b_16_f2,rgb_b_16_f3,rgb_b_16_f4,rgb_b_16_f5,rgb_b_16_f6,rgb_b_16_f7,rgb_b_16_f8,rgb_b_16_f9,rgb_b_16_f10,rgb_b_16_f11,rgb_b_16_f12,rgb_b_16_f13,', ... 
 %   'rgb_r_32_f1,rgb_r_32_f2,rgb_r_32_f3,rgb_r_32_f4,rgb_r_32_f5,rgb_r_32_f6,rgb_r_32_f7,rgb_r_32_f8,rgb_r_32_f9,rgb_r_32_f10,rgb_r_32_f11,rgb_r_32_f12,rgb_r_32_f13,', ... 
 %   'rgb_g_32_f1,rgb_g_32_f2,rgb_g_32_f3,rgb_g_32_f4,rgb_g_32_f5,rgb_g_32_f6,rgb_g_32_f7,rgb_g_32_f8,rgb_g_32_f9,rgb_g_32_f10,rgb_g_32_f11,rgb_g_32_f12,rgb_g_32_f13,', ... 
 %   'rgb_b_32_f1,rgb_b_32_f2,rgb_b_32_f3,rgb_b_32_f4,rgb_b_32_f5,rgb_b_32_f6,rgb_b_32_f7,rgb_b_32_f8,rgb_b_32_f9,rgb_b_32_f10,rgb_b_32_f11,rgb_b_32_f12,rgb_b_32_f13,', ... 
 %   'lab_l_8_f1,lab_l_8_f2,lab_l_8_f3,lab_l_8_f4,lab_l_8_f5,lab_l_8_f6,lab_l_8_f7,lab_l_8_f8,lab_l_8_f9,lab_l_8_f10,lab_l_8_f11,lab_l_8_f12,lab_l_8_f13,', ... 
 %   'lab_a_8_f1,lab_a_8_f2,lab_a_8_f3,lab_a_8_f4,lab_a_8_f5,lab_a_8_f6,lab_a_8_f7,lab_a_8_f8,lab_a_8_f9,lab_a_8_f10,lab_a_8_f11,lab_a_8_f12,lab_a_8_f13,', ... 
 %   'lab_b_8_f1,lab_b_8_f2,lab_b_8_f3,lab_b_8_f4,lab_b_8_f5,lab_b_8_f6,lab_b_8_f7,lab_b_8_f8,lab_b_8_f9,lab_b_8_f10,lab_b_8_f11,lab_b_8_f12,lab_b_8_f13,', ... 
 %   'lab_l_16_f1,lab_l_16_f2,lab_l_16_f3,lab_l_16_f4,lab_l_16_f5,lab_l_16_f6,lab_l_16_f7,lab_l_16_f8,lab_l_16_f9,lab_l_16_f10,lab_l_16_f11,lab_l_16_f12,lab_l_16_f13,', ... 
 %   'lab_a_16_f1,lab_a_16_f2,lab_a_16_f3,lab_a_16_f4,lab_a_16_f5,lab_a_16_f6,lab_a_16_f7,lab_a_16_f8,lab_a_16_f9,lab_a_16_f10,lab_a_16_f11,lab_a_16_f12,lab_a_16_f13,', ... 
 %   'lab_b_16_f1,lab_b_16_f2,lab_b_16_f3,lab_b_16_f4,lab_b_16_f5,lab_b_16_f6,lab_b_16_f7,lab_b_16_f8,lab_b_16_f9,lab_b_16_f10,lab_b_16_f11,lab_b_16_f12,lab_b_16_f13,', ... 
 %   'lab_l_32_f1,lab_l_32_f2,lab_l_32_f3,lab_l_32_f4,lab_l_32_f5,lab_l_32_f6,lab_l_32_f7,lab_l_32_f8,lab_l_32_f9,lab_l_32_f10,lab_l_32_f11,lab_l_32_f12,lab_l_32_f13,', ... 
 %  'lab_a_32_f1,lab_a_32_f2,lab_a_32_f3,lab_a_32_f4,lab_a_32_f5,lab_a_32_f6,lab_a_32_f7,lab_a_32_f8,lab_a_32_f9,lab_a_32_f10,lab_a_32_f11,lab_a_32_f12,lab_a_32_f13,', ... 
 %}   'lab_b_32_f1,lab_b_32_f2,lab_b_32_f3,lab_b_32_f4,lab_b_32_f5,lab_b_32_f6,lab_b_32_f7,lab_b_32_f8,lab_b_32_f9,lab_b_32_f10,lab_b_32_f11,lab_b_32_f12,lab_b_32_f13,', ... 
  
% WRITE DATA
for i = 1:size(image_data, 2); 
    
    fprintf('Writing data: %s\n', image_data(i).image_dir);
    
    for j= 1:size(image_data(i).tiles, 1)
        
        line = horzcat(image_data(i).image_dir, ',', image_data(i).tiles(j).name, ',', num2str(image_data(i).tiles(j).width), ',' , num2str(image_data(i).tiles(j).length),  ',', ...
            num2str(image_data(i).tiles(j).histogram, '%-6.10f, '), image_data(i).tiles(j).label, '\n');
        
        fprintf(fid, line);

    end;
end;

fclose(fid);

fprintf('Done!\n');

