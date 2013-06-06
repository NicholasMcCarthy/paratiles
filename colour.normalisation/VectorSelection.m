% Function to select staining solution vectors for colour deconvolution. 


function [ output_args ] = VectorSelection( varargin )
%% SELECT ROI FROM EACH IMAGE FOR EACH CLASS

p = inputParser;

p.addRequired('Images', @(x) iscellstr(x) & checkFilesExist(x));
p.addRequired('Classes', @(x) iscellstr(x));

p.parse(varargin{:});

images = p.Results.Images;
classes = p.Results.Classes;


% Forgot this bit, handle it better ..
csvfile = 'vector_selection_results.csv';
% Write output csv headers

fid = fopen(csvfile, 'a');
fprintf(fid, 'filename, R, G, B, class\n');
fclose(fid);


for i = 1:size(images, 1);
    
    % Read the image
    fprintf('Image: %s \nLoading, please wait.. \n ', images{i});
    
    I = imread(images{i});
    
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
    
    % Select ROIs for each class
    
    % Pre-allocate struct for data (well, the size of the struct, not the
%     % pixel_values array)
%     for c_ = 1:length(classes)
%         for i_ = 1:length(images)
%             data(c_).images(i_).pixels = [];
    data(length(classes)).images(length(images)).pixels = [];
    
    while(true) % iterate over images selecting regions of each class in each 
        
        fprintf('######\nREPOSITION/ZOOM IMAGE AS NECESSARY. \n');
        fprintf(strcat('######\nSELECT CLASS: [', repmat('%s , ', 1, length(classes)), ']\n'), classes{:});
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
            %%%
            %%  missing im_rgblist function, need to find it
            %% 
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

end

function ret = im_rgblist(image, mask)
    
    ret = reshape(image, size(image, 1)*size(image, 2), size(image, 3));
    ret = ret(mask(:)==1,:)
end

function ret = checkFilesExist(files) 

    % make the cellfun function boolean ..
    % cellfun(@(x) any(exist(x, 'file')==0), images)
    ret = true;
    for i = 1:length(files)
        
        if ~exist(char(files(i)), 'file');
            ret = false;
            break;
        end
    end
end
