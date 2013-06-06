% Matlab script to process tile sets

%% SETUP

HOME_DIR = '/media/Data/PCRC_Dataset/pixel.classification/';
DATA_DIR = '/media/Data/PCRC_Dataset/set.images/';

cd(HOME_DIR);
addpath('/home/nick/workspaces/matlab_workspace/');

TILE_RESOLUTION = 512;

% TIF image (THIS DOESNT EXIST, JUST USE TIFF_DIR)
TIFF_FILE = strcat(DATA_DIR, num2str(TILE_RESOLUTION), '.set.tif');
TIFF_DIR = strcat(DATA_DIR, num2str(TILE_RESOLUTION), '.set.tiles/');
CSV_FILE = strcat(DATA_DIR, num2str(TILE_RESOLUTION), '.set.csv');
OUTPUT_FILE = strcat(HOME_DIR,  num2str(TILE_RESOLUTION), '.art-data.csv');

%%  INIT

%--------------------
%% READING DATASET
%--------------------

fprintf('Reading dataset %s \n', CSV_FILE);

D = dataset('File', CSV_FILE, 'Delimiter', ',');

% Clean attribute header names
D.Properties.VarNames = regexprep(D.Properties.VarNames(:), '(x*)0x22', '');

% Tile information
data.filename = regexprep(D.filename, '\"', '');
data.label = regexprep(D.label, '\"', '');
data.IFD = D.IFD;

[numRows numCols] = size(D);
fprintf('%d rows, %d cols \n', numRows, numCols);


%--------------------
%% CREATING DATA STRUCT
%--------------------
fprintf('Preallocating resources .. \n');

% Pre-allocate data struct (enough for each tile)
info(numRows) = struct('set_id', -1, 'filename', 'a filename', 'IFD', -1, 'features', zeros(1,15) );

%--------------------
%% INDEXING TIFF DIRECTORY
%--------------------

tileset = rdir(strcat(TIFF_DIR, 'x*.tif')); % x000001.tif, x000002.tif, etc 

%--------------------
%% PROGRESS VARIABLES (for my own edification)
%--------------------
qq = floor(numRows/4);
qp = num2cell([qq, qq*2, qq*3, numRows]);
[q1 q2 q3 q4] = qp{:};

%-----------------------
%% LOAD MODELS 
%-----------------------
% datasets = importdata('5class.datasets.mat');
models = importdata('5class.models.mat');

%-----------------------
%% 5 class colourmap scheme
%-----------------------

graymap  = struct('CYTOPLASM', 192, ...  % BLUE
                   'INFLAMMATION', 0, ... % BLACK
                   'LUMEN', 255, ... % WHITE
                   'NUCLEI', 128, ...    % GREEN
                   'STROMA', 64 );      % RED


colourmap = struct('CYTOPLASM', [0 0 255], ...  % BLUE
                   'INFLAMMATION', [0 0 0], ... % BLACK
                   'LUMEN', [255 255 255 ], ... % WHITE
                   'NUCLEI', [0 255 0 ], ...    % GREEN
                   'STROMA', [255 0 0 ] );      % RED


%-----------------------
%% OPEN MATLAB WORKS FOR PARALLEL PROCESSING
%-----------------------
matlabpool open local 3
               
%% RUN 

tic; % Progress timing

fprintf('Processing %d tiles .. \n', numRows)

c = clock;
fprintf('%0d:%0d:%0d\n', fix(c(4:6)))

% for i = 1:numRows;  % UNPARALLELIZED PROCESSING
parfor i = 1:numRows; % PARALLELIZED PROCESSING

    filename = tileset(i).name;
    im_rgb = imread(filename);
   
    [X Y Z] = size(im_rgb);
    
    % Convert RGB image to CIELab
    im_lab = rgb2cielab(im_rgb);
    
    % Tile pixels as a feature vector
    fv = TileToFeatureVector(im_lab);
    
    % Classify using models.NBL (mean-shifted lab-colourspace model)
    [post, cpred, logp] = posterior(models.NBL, double(fv));
    
    % Empty Classified Tile - Reshape tile to feature vector, drop A channel
    ctile = TileToFeatureVector(uint8(zeros(X, Y, 1)));
    
     % For each pixel in ctile feature vector
    for p = 1:size(ctile,1)
       
       % The predicted class
       pred = cpred(p);

       % Assign the mapped colour
       if (strcmp(pred, '"CYTOPLASM"'))
           ctile(p,:) = 192; % graymap.CYTOPLASM;
       elseif (strcmp(pred, '"INFLAMMATION"'))
           ctile(p,:) = 0;   % graymap.INFLAMMATION;   % THIS BIT COULD BE FASTER BY RESHAPING PRED AND REASSIGNING ITS VALUES
       elseif (strcmp(pred, '"LUMEN"'))
           ctile(p,:) = 255; % graymap.LUMEN;
       elseif (strcmp(pred, '"NUCLEI"'))
           ctile(p,:) = 128; % graymap.NUCLEI;
       elseif (strcmp(pred, '"STROMA"'))
           ctile(p,:) = 64 ; % graymap.STROMA;
       end; 
       
    end;
    
    % Reshape feature vector to image
    ctile = FeatureVectorToTile(ctile, X, Y);
    
    % Convolve probabilities with 7x7 gaussian/median filter to remove
    % improbable 'Inflammation' pixels
  
    %------------
    % PROCESSING 
    %------------
    
    % Extract haralick features at 5 gray-levels
    
    GLCM = im2glcm(ctile, 5);
    
    F  =  haralick( GLCM );
    Fc = get_cluster_features( GLCM );
    

    % Save data to struct
    info(i).set_id = i;
    info(i).filename = data.filename(i);
    info(i).IFD = data.IFD(i);
    info(i).label = data.label(i);
    
    info(i).features = horzcat(F', Fc');
      
    %{
    % Progress information
    if (i == q1);
        fprintf('25%% completed ..\n');
        toc; tic;
        c = clock;
        fprintf('%d:%d:%0d\n', fix(c(4:6)))
    elseif (i == q2);
        fprintf('50%% completed ..\n');
        toc; tic;
        c = clock;
        fprintf('%d:%d:%0d\n', fix(c(4:6)))
    elseif (i == q3);
        fprintf('75%% completed ..\n');
        toc; tic;
        c = clock;
        fprintf('%d:%d:%0d\n', fix(c(4:6)))
    elseif (i == q4);
        fprintf('100%% completed ..\n');
        toc; 
        c = clock;
        fprintf('%d:%d:%0d\n', fix(c(4:6)))
    end;
    %}
    
end;

toc

%% OUTPUT HEADERS

fprintf('\nWriting output headers to: %s\n', OUTPUT_FILE);

fid = fopen(OUTPUT_FILE, 'w+');

% WRITE FILE HEADERS
fprintf(fid, strcat('set_id, filename, IFD, ',...
    'art_5_f1,art_5_f2,art_5_f3,art_5_f4,art_5_f5,art_5_f6,art_5_f7,art_5_f8,art_5_f9,art_5_f10,art_5_f11,art_5_f12,art_5_f13,art_5_cprom,art_5_cshad,', ... 
    'label\n'));

fclose(fid);


%% WRITING OUTPUT DATA

fprintf('Writing tile data to: %s \n', OUTPUT_FILE);

csvFun = @(str)sprintf('%s',str);

fid = fopen(OUTPUT_FILE, 'a'); % Open output file to append
    
for i = 1:numRows        % Iterate through tile data and output it.

    % Write data to CSV
    line = strcat(num2str(info(i).set_id), ',', info(i).filename, ',',  num2str(info(i).IFD), ',', ...
                num2str(info(i).features, '%-0.10f, '), info(i).label, {'\n'});
    
    %line = cellfun(csvFun, line, 'UniformOutput', false);
    
    line = strcat(line{:});
    
    fprintf(fid, line);
    
end;

fclose(fid);

fprintf('Finished outputting tile data!\n');