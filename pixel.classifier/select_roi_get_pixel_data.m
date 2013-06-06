% This script is used for selecting multiple regions from a list of images
% and saving RGB pixel values by selected class.
%-------
% NOTE:
% This selection process is done with smaller images than are used for 
% normal tiling and processing. These are the images from the 10th layer in
% the .scn images, so 1/16th the size of the full images.


%% SETUP
addpath('/home/nick/workspaces/matlab_workspace/');

HOME_DIR = '/media/Data/PCRC_Dataset/pixel.classification/';
csvfile = '/media/Data/PCRC_Dataset/pixel.classification/pixel_values-intraluminal-content.csv';


cd(HOME_DIR)

% List of large TIFF images
tiff.images = rdir(strcat(HOME_DIR, '../**/*-HE.9.tif'));

%% INIT

classes = {'LUMEN', 'NUCLEI', 'STROMA', 'CYTOPLASM', 'MUCIN', 'FIXATIVE', 'INFLAMMATION', 'INTRALUMINAL'}

% Preallocating data struct
for x = 1:length(classes)
    data(x).class = classes{x};
    
    for y = 1:size(tiff.images, 1)
        data(x).images(y).name = tiff.images(y).name;
        data(x).images(y).pixels = zeros(1,3);
    end;
end;

% Write output csv headers

fid = fopen(csvfile, 'a');
fprintf(fid, 'filename, R, G, B, class\n');
fclose(fid);

%% SELECT ROI FROM EACH IMAGE FOR EACH CLASS

for i = 1:size(tiff.images, 1);
    
    %---------------
    % Read the image
    %---------------
    tiffname = tiff.images(i).name;
    fprintf('-------------------\n');
    fprintf('Image: %s \n', tiffname);
    fprintf('Loading, please wait.. \n ');
    
    I = imread(tiffname);
    
    %---------------
    % Read the image
    %---------------
    
    fprintf('Displaying image. \n');
    
    
    iptsetpref('ImshowBorder','tight'); 
    set(gca,'visible','off');
    imshow(I);
    
    
 %   set(gca, 'units', 'pixels') % Sets the axes units to pixels
 %   x = get(gca, 'position');   % Get the position of the axes
 %   set(gcf, 'units', 'pixels');% Sets the figure units to pixels
 %   y = get(gcf, 'position');   % Gets the figure position
 %   
 %   set(gcf, 'position', [y(1) y(2) x(3) x(4)]) % Set the position of the figure to the length and width of the axes.
 %   set(gca, 'units', 'normalized', 'position', [0 0 1 1]) % Set the axes units to pixels
    
    %---------------------------
    % Select ROIs for each class
    %---------------------------
    
    while(true)
        
        fprintf('######\nREPOSITION/ZOOM IMAGE AS NECESSARY. \n');
        fprintf('######\nSELECT CLASS: [%s %s %s %s %s %s %s %s] \n', classes{:});
        reply = input('OR [N]ext image, [Q]uit: ', 's');
        
        if (strcmp(reply, 'Q'))
            fprintf('Quitting..\n');
            return;
            
        elseif (strcmp(reply, 'N'))
            break;
            
        elseif (ismember(reply, classes))
           
            c = find(ismember(classes, reply)==1);
            fprintf('Selected: %s \n', classes{c});
            
            fprintf('Draw ROI then double click it once positioned to continue. \n');
            
            h = imfreehand; % Freehand select ROI
            
            position = wait(h); % Block input until freehand is doubleclicked
            
            fprintf('Creating ROI mask. \n');
            mask = createMask(h); % Create mask of ROI

            fprintf('Extracting pixel RGB values. \n');
            pixel_values = im_rgblist(I, mask); % Use im_rgblist function to get RGB pixel values
            
            fprintf('Extracted %d pixels. \n', size(pixel_values,1));
            
            data(c).images(i).pixels = [ data(c).images(i).pixels ; pixel_values ] % Append them to existing pixel values for this image
        
            
        end; % if loop
        
    end; % while loop
    
    fprintf('Writing pixel data to: %s\n', csvfile);
    fprintf('Please wait ..');
    
    fid = fopen(csvfile, 'a');
    
    for c = 1:length(classes)
        
        for j = 2:size(data(c).images(i).pixels, 1) % j starts at 2 to ignore the preallocated pixel thingie
            
            line = strcat(tiffname, ',',sprintf('%d,%d,%d',data(c).images(i).pixels(j,:)), ',', classes{c}, '\n');
            fprintf(fid, line);
        end;
    end;
    fclose(fid);
    fprintf(' done!\n') ;
end;

fprintf('Completed ROI selection.\n');

%% Save pixel information to csv



