% This script will iterate through a set of images, tile them and determine
% whether they are within 

% Author: Nicholas McCarthy
% Date created: 03/07/2013

%% SETUP

images = getFiles(env.image_dir, 'Suffix', '.tif', 'Wildcard', '.8.tif');          % Wildcard so it selects the large .SCN layer image
masks = getFiles(env.image_dir, 'Suffix', '.tif', 'Wildcard', 'mask-PT.gs');

output_dir = [env.image_dir 'class-datasets/']

tilesize = 256;     % Tilesize for 40x image  
maskts = 16;      % Equivelant tilesize for mask image


% Ensure your local setup allows this ..
matlabpool local 4;

%% Create multi-level tiffs per class

tiffclasses = {'G3', 'G34' ,'G4', 'G45', 'G5'};

for tc = tiffclasses
        
    newtifffilename = [output_dir tc{:} '.tif'];
    
    t = Tiff(newtifffilename, 'a');
    
    t.close();

    
end


%% Create Tiff tagstruct 

tagstruct.ImageLength = tilesize;
tagstruct.ImageWidth = tilesize;
tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
tagstruct.SampleFormat = Tiff.SampleFormat.IEEEFP;
tagstruct.Compression = Tiff.Compression.JPEG;
tagstruct.BitsPerSample = 32;
tagstruct.RowsPerStrip = 16
tagstruct.SamplesPerPixel = 1;
tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
tagstruct.Software = 'MATLAB';

%% Parfor instead of blockproc .. 

% profile on;
   
for i = 1:length(images)
    
    imagepath = images{i};
    imageinfo = imfinfo(imagepath);
    
    maskpath = masks{i};
    maskinfo = imfinfo(maskpath);
    
    % Get number of blocks processed in this image
    numBlocks = ceil( (imageinfo.Width) / tilesize ) * ceil( (imageinfo.Height) / tilesize);
    
    %% Determine tile coords 
    trow_coords = 1:tilesize:(imageinfo.Width-mod(imageinfo.Width, tilesize)); % .. for image
    tcol_coords = 1:tilesize:(imageinfo.Height-mod(imageinfo.Height, tilesize));
    
    mrow_coords = 1:maskts:(maskinfo.Width-mod(maskinfo.Width, maskts)); % .. for mask
    mcol_coords = 1:maskts:(maskinfo.Height-mod(maskinfo.Height, maskts));
    
    [Tx Ty] = meshgrid(trow_coords, tcol_coords);               % Welp now I understand how meshgrid works 
    [Mx My] = meshgrid(mrow_coords, mcol_coords);   
    
    tvalues = cat(3, Tx, Ty, Mx, My);                                      
    tvalues = reshape(tvalues, size(tvalues, 1) * size(tvalues, 2), 4);  % This should work for a single parfor loop now .. 
    
    parfor i = 1:length(tvalues);
        
        trows = [tvalues(i, 1) tvalues(i, 1)+tilesize];
        tcols = [tvalues(i, 2) tvalues(i, 2)+tilesize];
        
        mrows = [tvalues(i, 3) tvalues(i, 3)+maskts];
        mcols = [tvalues(i, 4) tvalues(i, 4)+maskts];
        
        mask = imread(maskpath, 'PixelRegion', {mrows mcols});
        
        tileclass = block_get_class_label(mask); % Change this so it doesn't assume a block_struct.data input
        
        % if tileclass is in myclasses
            % read tile
            tile = imread(imagepath, 'PixelRegion', {trows tcols});
            
            % and  append it to the appropriate tiff 
            
            
        % end
            
    end
    
    % Concat output_dir with regex replaced filename (8.tif -> PC8.tif) 
    outputpath = [output_dir regexprep(fliplr(strtok(fliplr(images{1}), '/')), '.8.tif', '.PC8.tif')]   % .. don't ask 
    fprintf('Current Image: %s \n', imagepath);
    
    % Blockproc
    tic
    blockproc(imagepath, [tilesize tilesize], cls_image, 'Destination', outputpath);
    toc
    
end

% profile off;
% profile report;

%% CLEANUP

sendmail('nicholas.mccarthy@gmail.com', 'Processing complete', 'Adios');

%%