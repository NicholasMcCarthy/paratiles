% This script will do some Feature Extraction on a set of images

% Author: Nicholas McCarthy
% Date created: 11/06/2013
% Date run: x/x/x

%% SETUP

images = getFiles(env.image_dir, 'Suffix', '.tif', 'Wildcard', '.8.tif');          % Wildcard so it selects the large .SCN layer image
% masks = getFiles(env.image_dir, 'Suffix', '.tif', 'Wildcard', 'mask-PT.gs');

temp_dir = [env.root_dir '/temp_GABOR/'];

tilesize = 256;
    
D_length = 2079159;         % Preallocating number of rows when blockproc'ing 20 initial PCRC images. 

% Ensure your local setup allows this ..
if matlabpool('size') == 0
    matlabpool local 4
end

    
%% DEFINE FEATURE SETS TO BE EXTRACTED

filterBank = FilterBank();
filterBank.CreateFilterBank();

functions = { glcm_func }; 
labels = [  glcm_labels ]; %haralick_labels_lab ];

FE = FeatureExtractor(functions, labels);

func_fe = FE.BlockProcHandle;

%% A small test

test_images = getFiles([env.root_dir '/test.image.tiles/'], 'Suffix', 'tif');

for i = 1:length(test_images)
   
    I = imread(test_images{i});
    
    Ir = double(I(:,:,1));
    
    [filtersParams, responses] = filterBank.Convolve(Ir); 
    
    for j = 1:37
       
        
    end
    
end

%% RUN

% profile on;

for i = 2:length(images)
    
    imagepath = images{i};
    imageinfo = imfinfo(images{i});
 
    fprintf('%d] %s \n', i, imagepath);
    
    % Get number of blocks processed in this image
    numBlocks = ceil( (imageinfo.Width) / tilesize ) * ceil( (imageinfo.Height) / tilesize);
    
    % Pre-allocate 'data' struct
    data = zeros(numBlocks, length(FE.Features));
    
    % Blockproc
    tic
    
    FV = blockproc(imagepath, [tilesize tilesize], func_fe);
    
    mytime = toc;
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

% profile off;
% profile report;

%% OUTPUT 

output_dir = [env.root_dir '/datasets/GLCMVector_LAB_D1_NL64/']

% Generate single column csvs with column names as filenames
for h = 1:length(FE.Features)
    filename = strcat(output_dir, FE.Features{h}, '.csv');
    fid = fopen(filename, 'w+');
    fclose(fid);
end

linesWritten = 0;
columnsWritten = 0;
totalLines = 0;

for i = 1:length(images)                        % for each image
    
    fprintf('image %d \n', i);
    
    matfile = strcat(temp_dir, 'image-', num2str(i), '_temp_data.mat');
    load(matfile);                                                      % loads 'data' struct
    
    size(data)
    columnsWritten = 0;
    totalLines = totalLines + size(data, 1);

    for c = 1:size(data, 2)                                             % Append each column
        
        filename = strcat(output_dir, FE.Features{c}, '.csv');          % Column filename 
        fid = fopen(filename, 'a');                                     % Open to append
        
        for r = 1:size(data, 1)                                         %  For each row in 'data'
            
            fprintf(fid,   '%0.9f\n', data(r, c));                      % append it to file
            
            linesWritten = linesWritten + 1;
        end
        
        fclose(fid);
        
    end
    fprintf('%i lines written \n', linesWritten);
end

fprintf('Each csv file should have %i lines \n', totalLines);

% Verify number of lines per csv file

for h = 1:length(FE.Features)
    filename = strcat(output_dir, FE.Features{h}, '.csv');
    
    cmd = sprintf('grep -c ^$ %s', filename);
    
    [status result] = system(cmd);
    
    result = str2double(result);
    
    if result ~= 0
        fprintf('%s has %i empty lines .. \n', filename, result);
    end
end

disp('Finishing writing column csv files .. ')

% sendmail('nicholas.mccarthy@gmail.com', 'Finished writing CSV files ..', 'Adios');

% This function works for a single data matrix, not appending to multiple
% ones :( 
% writeMatrixToCSV(data, FE.Features, output_dir);

%% CLEANUP

sendmail('nicholas.mccarthy@gmail.com', 'Processing complete', 'Adios');

%%