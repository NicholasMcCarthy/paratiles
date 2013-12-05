% This script calculates GLCMs in 4 orthagonal directions and at several
% distances {1,2,4} for each tile that belongs to a class.
% Results are saved to a matlab struct.. 

%% Setup

images = getFiles(env.image_dir, 'Suffix', '.tif', 'Wildcard', '.8.tif'); 
masks = getFiles(env.image_dir, 'Suffix', '.tif', 'Wildcard', 'mask-PT.gs');

D_length = 2079159;         % Preallocating number of rows when blockproc'ing 20 initial PCRC images. 

% glcm_data = struct();

tilesize = 256;

if matlabpool('size') == 0
    matlabpool local 4;
end


%% Create blockproc func .. 

levels = [16 32 64];
distances = [1 2 4];

offsets = [0 d; -d d; -d 0; -d -d];       % Offset vector: 0, 45, 90, 135 degrees

functions = {};
labels = [];
channels = ['L' 'A' 'B'];

c = 1;

for z = 1:3
    for nl = 1:length(levels);
        for d = 1:length(distances);
                        
            offsets = [0 d; -d d; -d 0; -d -d];                 % Offset vector: 0, 45, 90, 135 degrees
            
            tfunc = @(I) im2glcm(I(:,:,z), nl, offsets);
            
            label = ['glcm_' channels(z) '_d' num2str(d) '_q' num2str(nl)];
            
            functions{c} = tfunc;
            labels = [labels ; label];
            
            c = c + 1;
            
        end
    end
end

labels = cellstr(labels);

FE = FeatureExtractor(functions, labels);

func_fe = FE.BlockProcHandle;

%% RUN

% profile on;

for i = 1:length(images)
    
    imagepath = images{i};
    imageinfo = imfinfo(images{i});
 
    fprintf('%d] %s \n', i, imagepath);
    
    % Get number of blocks processed in this image
    numBlocks = ceil( (imageinfo.Width) / tilesize ) * ceil( (imageinfo.Height) / tilesize);
    
    % Pre-allocate 'data' struct
%     data = zeros(numBlocks, length(FE.Features));
    glcm_data(numBlocks) = struct();
    
    % Blockproc
%     FV = blockproc(imagepath, [tilesize tilesize], func_fe);

     parfor z = 1:3
        for nl = 1:length(levels);
            for d = 1:length(distances);

                offsets = [0 d; -d d; -d 0; -d -d];                 % Offset vector: 0, 45, 90, 135 degrees

                tfunc = @(I) im2glcm(I(:,:,z), nl, offsets);

                label = ['glcm_' channels(z) '_d' num2str(d) '_q' num2str(nl)];

                functions{c} = tfunc;
                labels = [labels ; label];

                c = c + 1;

            end
        end
    end

    % Reshape from image to feature vector
    FV = reshape(FV, size(FV, 1) * size(FV, 2), size(FV, 3));   
    
    data = FV;

    % save 'data' struct as .mat file on an image by image basis
    matfile = strcat(temp_dir, 'image-', num2str(i), '_temp_data.mat');
    save(matfile, 'data');
    
    msg = sprintf('%s data written \n', matfile);
    title = sprintf('Feature Extraction: Image %i', i);
    sendmail('nicholas.mccarthy@gmail.com', title, msg);
end

disp('Done!');


%%

%% 
possible a good opportunity to get the mask image upscale to large image
sections for particular tile extraction .. DO IT

image_tilesize = 256; 

i = 1;
image_path = images{1};
mask_path = masks{1};

% 1. Get dimensions of image and mask

image_info = imfinfo(image_path);
mask_info = imfinfo(mask_path);

% 2. Determine scale factor

scaleFactor = image_info.Width / mask_info.Width;

% 3. Scale tilesize to mask ..

mask_tilesize = image_tilesize / scaleFactor; 

% 4. Determine number of tiles in image 

numBlocks = ceil( (image_info.Width) / image_tilesize ) * ceil( (image_info.Height) / image_tilesize);
numBlocksM = ceil( (mask_info.Width) / mask_tilesize ) * ceil( (mask_info.Height) / mask_tilesize);

% 5. Find {x1, y1, x2, y2} coordinates for mask tiles
% NOTE: {x1, y1} is top left, {x2, y2} is bottom right of tile

% The origin points {0,0} added in points allocation
x_coords = mask_tilesize:mask_tilesize:mask_info.Width;
y_coords = mask_tilesize:mask_tilesize:mask_info.Height;

points = zeros(1, 2);

for ij = 1:length(y_coords);        % Y coords first (tiles go horizontally across)
    for ii = 1:length(x_coords)
        points(end+1, :) = [x_coords(ii) y_coords(ij)];
    end
end

6. 