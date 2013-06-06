% Function to select staining solution vectors for colour deconvolution. 


function [ output_args ] = VectorSelection( varargin )
%% SELECT ROI FROM EACH IMAGE FOR EACH CLASS


p = inputParser;
% checks images is a cellstr, are files that exist and are images
p.addRequired('Images', @(x) iscellstr(x) & all(cellfun(@(y) exist(y, 'file'), x)) & verifyImages(x));
% Classes can be specified by any thing ..
p.addRequired('Classes', @(x) iscellstr(x));
% 
p.addOptional('CSVFile', 'vectorselection_output.csv', @(x) ischar(x)); % Just check its a string here 

p.parse(varargin{:});

images = p.Results.Images;
classes = p.Results.Classes;


disp('#-#-#-#-#-#-#-#-#-#-#-#-#-');
disp('---- Vector Selection ----');
disp('#-#-#-#-#-#-#-#-#-#-#-#-#-');

disp('Setting up output file ..');

% Set up output CSV filepath, writemode & headers
csvfile = p.Results.CSVFile;

wrmode = 'wt';
if (~exist(csvfile))
    wrmode = 'wt';
else
    ret = input('Output CSV file already exists. Overwrite ? [Y/N]  ', 's');
    if (strcmp(ret, 'N'))   % Default to append ..
        wrmode = 'a';
        fprintf('Will append new data to: %s \n', csvfile);
    else
        fprintf('Overwriting data in: %s \n', csvfile);
        wrmode = 'wt';
    end
end;

if (strcmp(wrmode, 'wt'))
    fid = fopen(csvfile, 'wt');
    fprintf(fid, '%c %c %c %s', 'R', 'G', 'B', 'class');
    fclose(fid);
end

disp('Preallocating results data struct ..');
% Preallocate data struct - could be neater but they get appended each selection
data(length(classes)).images(length(images)).pixels = [];
for l = 1:length(classes)
    for ip = 1:length(images)
        data(l).images(ip).pixels = [];
    end
end

for i = 1:length(images)
    
    % Read the image
    fprintf('Loading image: %s \n', images{i});
    
    I = imread(images{i});
    
%     fprintf('Displaying image. \n');
    
    iptsetpref('ImshowBorder','tight'); 
    set(gca,'visible','off');
    set(gca, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
    imshow(I);
        
 %   set(gca, 'units', 'pixels') % Sets the axes units to pixels
 %   x = get(gca, 'position');   % Get the position of the axes
 %   set(gcf, 'units', 'pixels');% Sets the figure units to pixels
 %   y = get(gcf, 'position');   % Gets the figure position
 %   
 %   set(gcf, 'position', [y(1) y(2) x(3) x(4)]) % Set the position of the figure to the length and width of the axes.
 %   set(gca, 'units', 'normalized', 'position', [0 0 1 1]) % Set the axes units to pixels
    
    % Select ROIs for each class
    
    % Pre-allocate struct for data (well, the size of the struct, not the
%     % pixel_values array)
%     for c_ = 1:length(classes)
%         for i_ = 1:length(images)
%             data(c_).images(i_).pixels = [];

    while(true) % iterate over images selecting regions of each class in each 
        
        fprintf('---------------------------\nReposition or zoom on the image as necessary.\n---------------------------\n');
        fprintf(strcat('Select class: \t', repmat(' [%s] ', 1, length(classes)), '\n[N]ext image \t [Q]uit :\t'), classes{:});
        reply = input('', 's');
        
        if (strcmp(reply, 'Q'))             % Quits the program
            fprintf('Quitting..\n');
            return;                     
            
        elseif (strcmp(reply, 'N'))         % Breaks out of while loop, goes to next iteration of for loop
            break;
            
        elseif (ismember(reply, classes))   % Otherwise, select another region on this image, etc
           
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
            
            data(c).images(i).pixels = [ data(c).images(i).pixels ; pixel_values ]; % Append them to existing pixel values for this image
         
        end; % if loop
        
    end; % while loop
    
    
    % Write data to CSV file - 

    fprintf('Writing data to output: %s\n', csvfile);

    fid = fopen(csvfile, 'a');

    for c = 1:length(classes)

        for j = 1:size(data(c).images(i).pixels, 1) % j starts at 2 to ignore the preallocated pixel thingie

            line = strcat(images{i}, ',',sprintf('%d,%d,%d',data(c).images(i).pixels(j,:)), ',', classes{c}, '\n');
            fprintf(fid, line);
        end;
    end;
    fclose(fid);
    
end;

fprintf('Completed ROI selection.\n');




end

function ret = im_rgblist(image, mask)

% Input: An n-channel image, a binary mask.
% Output: Matrix of pixel values of area in the mask. Each row is a pixel,
% each column is a channel value.

    ret = reshape(image, size(image, 1)*size(image, 2), size(image, 3));
    ret = ret(mask(:)==1,:);
    
end

function ret = verifyImages(files) 
% Input: A cellstr of paths to image files
% Output: True if all files listed exist and are images, false otherwise.

    ret = true;
    for i = 1:length(files)
        
        try 
            imfinfo(files{i});
        catch err
            ret = false; 
            break;
        end; 
    end
end

%% roughwork area


% for i = 1:20
%     
%     disp(i);
%     x = 1;
%     
%     while(x > 0)
%       
%         x = input('Press 1 or 0: ');
%         
%         if(x == 2) 
%             disp('X is 2!');
%             break;
%         end
%     end
%     
% end;
