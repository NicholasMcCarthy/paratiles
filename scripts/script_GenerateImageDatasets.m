% Performs feature extraction on each image and saves it as a separate .mat
% file so that heatmaps / classification can be performed without it taking
% for-fucking-ever. 

%% Get image set

images = getFiles(env.training_image_dir, 'Wildcard', '.scn');

if matlabpool('size') == 0
    matlabpool local 4;
end

% Set up feature extractor .. 
numlevels = [16 32 64];
distances = [1 2 4];

histogram_func_lab = @(I) extract_histogram_features(rgb2cielab(I), 'NumLevels', [16 32 64]);
histogram_labels_lab = label_histogram_features('Channels', {'L', 'A', 'B'}, 'NumLevels', [16 32 64], 'Prefix', 'lab', 'UseStrings', true);

haralick_func_lab = @(I) extract_haralick_features(rgb2cielab(I), 'NumLevels', [16 64], 'Distances', [1 2 4]);
haralick_labels_lab = label_haralick_features('Channels', {'L', 'A', 'B'}, 'NumLevels', [16 64], 'Distances', [1 2 4], 'Prefix', 'lab', 'UseStrings', true);

functions = { histogram_func_lab haralick_func_lab };
labels    = [ histogram_labels_lab haralick_labels_lab ] ;

FE = FeatureExtractor(functions, labels);

blockproc_func = FE.BlockProcHandle;

tilesize = 256;

%% 

for i = 1 %:length(images)
    
    image_path = images{i};
    
    fprintf('Reading %s \n', image_path);
    
    % Gets path to 8th IFD (i.e. the largest .. );
    ifd_paths = unpackTiff(image_path, 8, 1);
    
    FV = blockproc(ifd_paths{:}, [tilesize tilesize], blockproc_func);
    
    output_path = regexprep(image_path, '.scn', '.LAB-features.mat')
    
    save(output_path, 'FV');
    
end

%% Alternative idea: Use existing extracted feature sets ..

for i = 1:length(images);

    image_path = images{i};
    
    fprintf('Reading %s \n', image_path);
    
    % Gets path to 8th IFD (i.e. the largest .. );
    ifd_paths = unpackTiff(image_path, 8, 1);
    
    imageinfo = imfinfo(idf_paths{:});
    
    numBlocks = ceil( (imageinfo.Width) / this.Tilesize ) * ceil( (imageinfo.Height) / this.Tilesize);
    
    output_path = regexprep(image_path, '.scn', '.LAB-features.mat')
    
    
    
    save(output_path, 'FV');
    
end

%% Generating filenames.csv from class-labels.mat

loaded = load('datasets/class.info/class_labels.mat');

Df = loaded.D.filename;

Uf = unique(Df);

% Replace names with .scn filenames
repname = @(x) regexprep(x, 'mask-PT.gs.tif', 'scn');

output_file = ['datasets/class.info/filenames.csv'];

fid = fopen(output_file, 'wb');

% No header to print .. 

fprintf('Writing to %s \n', output_file);

for i = 1:length(Df)
    line = repname(Df{i});
    
    lines = stringsplit(line, '/');
    
    fprintf(fid, '%s\n', lines{end});
end

fclose(fid);


