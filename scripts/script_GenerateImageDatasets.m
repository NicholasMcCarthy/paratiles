% Performs feature extraction on each image and saves it as a separate .mat
% file so that heatmaps / classification can be performed without it taking
% for-fucking-ever. 

%% Get image set

images_path = getFiles(env.image_dir, 'Suffix', '.tif', 'Wildcard', '.8.');

images = cellfun(@(x) regexprep(x, '8.tif', 'scn'), images_path, 'UniformOutput', false);

%% 

feature_dirs = {'datasets/HARALICK_LAB'}; %, 'datasets/SHAPE.features', ...
                %'datasets/HISTOGRAM_LAB', 'datasets/CICM-r1.features'};
            
label_path = 'datasets/class.info/labels.csv';
filenames_path = 'datasets/class.info/filenames.csv';
env.root_dir = [env.base_dir '/'];

for i = 1:length(images)

    image_path = fliplr(strtok(fliplr(images{i}), '/'));

    [dataset_path status cmdout] = GenerateImageDataset( env.root_dir, 'Directory', feature_dirs, 'Image', image_path, ... 
                            'Labels', label_path, 'Filenames', filenames_path, 'AssignIDs', 0, 'AssignClasses', 1);

end