% This script generates a set of multipage Tiffs for each class. 
% It does this by iterating through the the set of images we have, reading
% the equivelent mask region and determining the class label. If it is one
% of the classes it appends it to the CLASSNAME.tif file as a tile. 

% Author: Nicholas McCarthy
% Date created: 03/07/2013
% Date updated: 08/07/2013

%% SETUP

images = getFiles(env.image_dir, 'Suffix', '.tif', 'Wildcard', '.8.tif');          % Wildcard so it selects the large .SCN layer image
masks = getFiles(env.image_dir, 'Suffix', '.tif', 'Wildcard', 'mask-PT.gs');

output_dir = [env.image_dir 'class-datasets/'];

tilesize = 256;     % Tilesize for 40x image % NOTE: for the 20x images (9.tif) just change this to 128 for same region
tilesize_mask = 16;      % Equivelant tilesize for mask image

% Ensure your local setup has matlabpool validated, etc
if matlabpool('size') == 0
    matlabpool local 4;
end

%% Create Tiff tags 
% Assign this to finalize written Tiff images with proper Tiff tags. 

tags.Photometric = Tiff.Photometric.RGB;
tags.ImageLength = tilesize;
tags.ImageWidth = tilesize;
tags.Compression = Tiff.Compression.JPEG;
tags.BitsPerSample = 8;
tags.RowsPerStrip = 16;
tags.SamplesPerPixel = 3;
tags.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
tags.Software = 'MATLAB';

% tags.SampleFormat = Tiff.SampleFormat.IEEEFP;


%% Create multi-level tiffs per class

% Classes to extract
tiffclasses = {'G3', 'G34' ,'G4', 'G45', 'G5'};

entropy_check = @(I) entropy(I) > 3.8;

%% Parfor instead of blockproc .. 

% profile on;

disp('Starting parfor loop!');

for i = 1:length(images)
    
    imagepath = images{i};
    imageinfo = imfinfo(imagepath);
    
    disp(imagepath);
    
    maskpath = masks{i};
    maskinfo = imfinfo(maskpath);
    
    mask = imread(maskpath);
    
    % Determine tiling coords 
    tile_width = imageinfo.Width;
    tile_height = imageinfo.Height;
    
    mask_width = size(mask, 2);
    mask_height = size(mask, 1);
    
    tile_x_coords = 1:tilesize:(tile_width-mod(tile_width, tilesize)); % .. for image
    tile_y_coords = 1:tilesize:(tile_height-mod(tile_height, tilesize));
    
    mask_x_coords = 1:tilesize_mask:(mask_width-mod(mask_width, tilesize_mask)); % .. for mask
    mask_y_coords = 1:tilesize_mask:(mask_height-mod(mask_height, tilesize_mask));
    
    [Tx Ty] = meshgrid(tile_y_coords, tile_x_coords);               % Welp now I understand how meshgrid works 
    [Mx My] = meshgrid(mask_y_coords,mask_x_coords);   
    
    tiling_matrix = cat(3, Tx, Ty, Mx, My);                                      
    tiling_matrix = reshape(tiling_matrix, size(tiling_matrix, 1) * size(tiling_matrix, 2), 4);  % This should work for a single parfor loop now .. 
    tiling_matrix = tiling_matrix(1:end-1, :);                          % Dropping the last coords so image coordinates are not out of bounds ..
    
    % Parallellize searching regions of each image
    % Iterative over each mask-image paired coordinates
    parfor b = 1:length(tiling_matrix);
        
        % Mask coordinates
        mask_ys = [tiling_matrix(b, 3) tiling_matrix(b, 3)+tilesize_mask-1];
        mask_xs = [tiling_matrix(b, 4) tiling_matrix(b, 4)+tilesize_mask-1];
        
        maskregion = mask(mask_ys(1):mask_ys(2), mask_xs(1):mask_xs(2));     % Read mask region from previously read mask image
%         maskregion = imread(maskpath, 'PixelRegion', {mask_ys, mask_xs});    % Read mask region from disk (slower!)
        
        % Get region label
        tileclass = get_class_label(maskregion, 'string');    
        
        % If label is one we want
        if any(ismember(tileclass, tiffclasses))
                        
            % Get tile regions
            tile_xs = [tiling_matrix(b, 1) tiling_matrix(b, 1)+(tilesize-1)];
            tile_ys = [tiling_matrix(b, 2) tiling_matrix(b, 2)+(tilesize-1)];
            
            % Read image region
            tile = imread(imagepath, 'PixelRegion', {tile_xs tile_ys});
            
            % Perform entropy check on tile to remove blank / lumen areas
            % covered by annotation region
            if entropy_check(tile)
                
                tile_filepath = [output_dir tileclass '/' sprintf('%0.15f', now) '.tif']
                
                t= Tiff(tile_filepath, 'a');
                t.setTag(tags);
                t.write(tile);
                t.close();
                
                % Since apparently Matlab is infuckingcapable of actually
                % writing multipage tiffs correctly, 
%                 tifffile = [output_dir tileclass '.tif']; % Better than indexing into tiffimages .. 
%          
%                 t = Tiff(tifffile, 'a'); % Open tiff for appending
%                 t.setTag(tags);
%                 t.write(tile); % Write tile 
%                 t.close(); % Close tiffobj
                
            end
            
        end
        
    end
end

disp('Ended parfor loop!');
% profile off;
% profile report;

%% Creating the multipage tiffs from individual tiles

for i = 1:length(tiffclasses)
    
    tiffclass = tiffclasses{i};
    
    tile_class = [output_dir tileclass '.tif'];
    tile_dir = [output_dir tileclass '/'];
    
    tileset = getFiles(tile_dir, 'Suffix', '.tif');
    
    t = Tiff(tile_class, 'a');
    
    t.writeDirectory(); % ????? 
    
    for t = 1:length(tileset)
        
        
        % try read the tile
        % if theres an error, ignore it
        % otherwise append it to tileclass.tif
        
        
        tile = imread(tileset{t});
        
        t.setTag(tags);
        t.write(tile);
        t.writeDirectory();
        
    end
    
    t.close();
     
end

%% CLEANUP

sendmail('nicholas.mccarthy@gmail.com', 'Completed constructing class dataset. ', 'Adios');

