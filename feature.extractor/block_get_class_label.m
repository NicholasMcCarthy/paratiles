
function results = block_get_class_label( block_struct )
%  GET_CLASS_LABEL Determines class label of an input block_struct.dataage.
%  IN: block_struct.data in RGB or RGBA format. <widthxheight uint8> 
%  OUT: uint8 value of assigned class 
%
%  Nicholas McCarthy 2012
%  <nicholas.mccarthy@gmail.com>


%% CLASS-LABELS AND RGB PIXEL VALUES
if (size(block_struct, 3) ~= 1)
    error('block_get_class_label:: Expecting grayscale image.');
else
    
% Returns label as the mask class value
% A = sort(block_struct.data(:), 'ascend');  % Changed this to ascend as 255 is the 'NON' class and should be evaluated last ..
u = unique(block_struct.data);

max = 0;
for i = 1:length(u);
    if sum(block_struct.data(:) == u(i)) > max
        label = u(i);
        max = sum(block_struct.data(:) == u(i));
    end
end

% Converting uint8 values to string labels
interval = (255/8);

idx_labelsr = num2str(idx_labels);
idx_labelsr = cellstr(idx_labelsr);

idx_labelsr = regexprep(idx_labelsr, '28', 'G34');
idx_labelsr = regexprep(idx_labelsr, '56', 'G4');
idx_labelsr = regexprep(idx_labelsr, '85', 'G45');
idx_labelsr = regexprep(idx_labelsr, '113', 'G5');
idx_labelsr = regexprep(idx_labelsr, '141', 'INF')
idx_labelsr = regexprep(idx_labelsr, '170', 'ART');
idx_labelsr = regexprep(idx_labelsr, '198', 'TIS');
idx_labelsr = regexprep(idx_labelsr, '255', 'NON');
idx_labelsr = regexprep(idx_labelsr, '0', 'G3');

results = [label double(coverage)];

end

