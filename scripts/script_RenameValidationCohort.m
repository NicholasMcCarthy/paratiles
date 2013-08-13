% A script for renaming PCRC validation cohort.

% These are a list of .tiff files, but with unique ID strings as names.

% 1. Get list of files in cohort directory

% 2. For each file, use tiffsplit to split image directories

% 3. Open up the smallest image which has a barcode, wait for input

% 4. Take user input string, rename original TIFF file, delete tiffsplitted
%    files


env.cohort_dir = '/media/Data/PCRC_Validation-Cohort/';

files = getFiles(env.cohort_dir, 'Suffix', '.tiff');

figure;

alphabet = 'abcdefghijklmnopqrstuvwxyz';

for i = 1:length(files)
    
    disp('-----------------------------')
    file_path = files{i}
    
    fprintf('Reading image %s \n', file_path);
    
    file_prefix = regexprep(file_path, '.tiff', '_');
    
    cmd0 = sprintf('identify %s', file_path);
    
    [status cmdout] = system(cmd0);
    
    split_str = regexp(cmdout, 'TIFF', 'split');
    
    num_IFDs = size(split_str, 2) - 1;
    
    
    % Tiffsplit file 
    disp('Running tiffsplit cmd ..')
    cmd1 = sprintf('tiffsplit %s %s', file_path, file_prefix)
    
    [status cmdout] = system(cmd1);
    
    tiffcode = sprintf('_aa%s.tif', alphabet(num_IFDs));
    file_barcode = regexprep(file_path, '.tiff', tiffcode);
    
    I = imread(file_barcode);
    I = imrotate(I, 90);
    % Display image
    imshow(I);
    
    str = input('Enter new filename [e.g. PCRC_ID_B_A1L3_HE]: ', 's')
    
    new_file_path = [env.cohort_dir str '.tiff']
    
    disp('Renaming file ..');
    cmd2 = sprintf('mv %s %s', file_path, new_file_path)
    [status cmdout] = system(cmd2);
    
    disp('Deleting leftover files ..');
    leftover_files = regexprep(file_path, '.tiff', '*');
    cmd3 = sprintf('rm %s', leftover_files)
    [status cmdout] = system(cmd3);
end
    

%%

for i = 1:length(files)
   
    cmd1 = sprintf('identify %s', files{i});
    
    [status cmdout] = system(cmd1);
    
    split_str = regexp(cmdout, 'TIFF', 'split');
    
    fprintf('Image %s has %i directories \n', files{i}, size(split_str, 2)-1);
    
    
end