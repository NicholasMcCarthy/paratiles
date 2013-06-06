% Tile-pixel classifier


% Author: Nicholas McCarthy
% Created: 10-05-2013
% Updated: 10-05-2013

%% SETUP
% Working directory
cd('/media/Data/PCRC_Dataset/pixel.classification/');

% Paths to extra scripts
addpath('/home/nick/workspaces/matlab_workspace/');
addpath('~/Dropbox/workspace/matlab_workspace/')

% Path to test image directory
tiledir = '/media/Data/PCRC_Dataset/pixel.classification/test.images/';
outputdir = '/media/Data/PCRC_Dataset/pixel.classification/output.images/';

%% GET TEST IMAGES, COLOURMAPS
% Get tif filenames from test images directory
tileset = rdir(strcat(tiledir, '*.tif'));

% Class -> colour mapping scheme
colourmap = struct('CYTOPLASM', [255 255 0], ...  % YELLOW
                   'FIXATIVE', [0 0 0], ...       % BLACK
                   'INFLAMMATION', [0 0 255], ... % BLUE
                   'INTRALUMINAL', [255 0 0 ], ...% RED
                   'LUMEN', [255 255 255 ], ...   % WHITE
                   'NUCLEI', [0 255 255 ], ...    % CYAN
                   'STROMA', [255 0 255 ] );      % MAGENTA

classnames = unique(D.class);

% Load NBModel for LAB colourspace
load('NB-PixelClassifier-LAB.mat');

%% TEST OUTPUT OF MODELS ON SAMPLE IMAGES (smaller, doesn't batch process)

for i = 1:size(tileset, 1);

    %%%%%%%%%%%%%%%%%
    % READING IMAGE %
    %%%%%%%%%%%%%%%%%
    
    fprintf('Reading test image: %s\n', tileset(i).name);
    
    base_image = imread(tileset(i).name); % Reference tile
        
    [X Y Z] = size(base_image); % Get image dimensions
    
    % Drop the alpha channel from sRGB 
    if Z == 4 
        Z = 3; 
        base_image = base_image(:,:,1:3);
    end;
    
    fprintf('Image Size: %dx%d \n', X, Y); % And some image info
    fprintf('Num Pixels: %d \n', X*Y);
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % PIXEL CLASSIFICATION (LAB COLOURSPACE) %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    lab_image = rgb2cielab(base_image); 
    
    FV = TileToFeatureVector(lab_image);
    
    % Predict all rows of the feature vector
    [lpost, lcpred, llogp] = posterior(models.NBL, double(FV));
    
    % Classified Tile - Reshape tile to feature vector, drop A channel
    lctile = TileToFeatureVector(uint8(zeros(X, Y, Z)));
        
    % For each pixel in feature vector
    for p = 1:size(lctile,1)
        
       % The predicted class
       pred = lcpred(p);
       
       % Assign the mapped colour
       if (strcmp(pred, '"CYTOPLASM"'))
           lctile(p,:) = colourmap.CYTOPLASM;
       elseif (strcmp(pred, '"FIXATIVE"'))          % Not included in model!
           lctile(p,:) = colourmap.FIXATIVE;
       elseif (strcmp(pred, '"INFLAMMATION"'))
           lctile(p,:) = colourmap.INFLAMMATION;
       elseif (strcmp(pred, '"INTRALUMINAL"'))      % Not included in model!
           lctile(p,:) = colourmap.INTRALUMINAL;
       elseif (strcmp(pred, '"LUMEN"'))
           lctile(p,:) = colourmap.LUMEN;
       elseif (strcmp(pred, '"NUCLEI"'))
           lctile(p,:) = colourmap.NUCLEI;
       elseif (strcmp(pred, '"STROMA"'))
           lctile(p,:) = colourmap.STROMA;
       end;    
    end;
    
    % Reshape feature vector to image
    lctile = FeatureVectorToTile(lctile, X, Y);
    
    % Post-processing on binary class masks
    
    % get binary mask for each class 
    
    % lumen: erosion to remove anything too small
    
    % nuclei: erosion to remove small tiles, opening to regain
    
    % cytoplasm: dilation
    
    % stroma: ????
    
    
    
    % Writing disk to image
    image_name = regexp(tileset(i).name, '/', 'split');
    image_name = image_name(end);
    
    outfile = strcat(outputdir, char(regexprep(image_name, '.tif', '.LAB.NB-classified.tif')));
    fprintf('Writing LAB classified image to: %s \n', outfile);
    imwrite(lctile, outfile, 'Compression', 'packbits');
    
end;





