
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

coverage = (sum(block_struct.data(:) == label)) / ( size(block_struct.data, 1) * size(block_struct.data, 2) ) ;

coverage = coverage * 255;  % blockproc returns values of same type as input (uint8), so the 0-1 values get rounded up or down..

results = [label double(coverage)];

end

