% Demo script for showing the colour normalisation procedure.



%% Vector selection 
% This can be set up to select -any- specified classes but works for this
% purpose too.

images = {'test.images/x0000000424.tif'   ...  % using test images from pixel.classifier
          'test.images/x0000000425.tif'   ...
          'test.images/x0000000431.tif'}
      
classes = {'nuclei', 'stroma', 'cytoplasm', 'lumen'};
% classes = {'A', 'B', 'C'};
% classes = {'H', 'E'};

% Specifying a file here, but will default to vector_selection_results.csv
csvfile = 'test_vector_selection.csv';

%VectorSelection(images, classes, csvfile);

%% Normalising colour images ..

% Sample of stain specific optical-density values. Can be determined y
% measuring relative absoprtion for RGB channels on slides mixed with a
% single stain. 


% A sample OD vector for H&E
% Each row is a stain, each column is a channel (i.e. RGB)
H = [0.18 0.20 0.08 ; 0.01 0.13 0.01 ; 0.10 0.21 0.29];

% Normalize the OD matrix 
for r = 1:3
	H(r,:) = H(r,:) ./sqrt(sum(H(r,:).^2));
end

% I = imread('hestain.png');

for i = 1:length(images)
    
    I = imread(images{i});
    G = I;
    [X Y Z] = size(I);

    G = double(reshape(G, X*Y, Z)); % Convert image to double and vector form

    G = G'; % Flip so each pixel is a column

    for r = 1:size(G, 2)
        G(:,r) = H * G(:,r);
    end

    G = uint8(G);
    G = G';
    G = reshape(G, X, Y, Z);

    figure;
    subplot(211), imshow(I), title('Original image');
    subplot(212), imshow(G), title('Deconvolved image');
    
end


