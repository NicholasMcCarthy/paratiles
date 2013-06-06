% Demo script for showing the colour normalisation procedure.



%% Vector selection 
% This can be set up to select -any- specified classes but works for this
% purpose too.

images = {'../pixel.classifier/test.images/x0000000424.tif'   ...  % using test images from pixel.classifier
          '../pixel.classifier/test.images/x0000000425.tif'   ...
          '../pixel.classifier/test.images/x0000000431.tif'}
      
classes = {'nuclei', 'stroma', 'cytoplasm', 'lumen'};
% classes = {'A', 'B', 'C'};
% classes = {'H', 'E'};

% Specifying a file here, but will default to vector_selection_results.csv
csvfile = 'test_vector_selection.csv';

VectorSelection(images, classes, csvfile);

%% Normalising colour images ..


