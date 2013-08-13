
% 1. Starting with a GLCM for a given area at 40x magnification

% 2. If we have the 4 orthagonal distance 1 matrices (0,90,180,270 degrees)
%  then we can reduce the matrix to the equivelent 20x resolution GLCM by
%  pairing pixel adjacencies and popping them off the GLCM 'stack', and
%  calculate the derived interpolation value (starting with bicubic interpolation since it's probably 
%  the easiest to do ..

% The test image .. 
I = imread('hestain.png');
% Make it a tile for simples
I = I(1:200,1:200,:);

% Offsets vector: distance 1 unsymmetric orthagonal directions adjacency matrices
GLCM_offsets= [ 0 1; 1 0 ; 0 -1 ; -1 0] ;
GLCM = graycomatrix(I(:,:,1), 'offset', GLCM_offsets, 'Symmetric', false);

% Output GLCMs for lower res image
G = zeros(size(GLCM));

%% Getting number of adjacencies in an image .. 

% Anonymous function 
get_num_adjacencies = @(H, W, O) H * W * O - ((W*2) + ((H-2)*2) + O)

% Vars
W = size(I, 1);             % image width
H = size(I, 2);             % image height
O = length(GLCM_offsets);   % number of adacencies per inner pixel

num_adjacencies_gt = sum(GLCM(:))

num_adjacencies = get_num_adjacencies(H, W, O)

% Vars for lower resolution image (assuming a linear size rescaling)
Wb = W / 2;     % Image resolution twice as low (40x->20x)
Hb = H / 2;     %  Image resolution twice as low (40x->20x)
Ob = O;         % Same number of adjacencies though 

num_adjacencies_b = get_num_adjacencies(Hb, Wb, Ob); % in interpolated GLCM



%% Re-potting GLCM values 

while sum(GLCM(:)) > 10    
    M = max(GLCM(:));
    M_idx = find(GLCM == M);
    
    [i,j,k] = ind2sub(size(GLCM),find(GLCM == max(GLCM(:)))); % Gets i, j, k values for largest GLCM values 
    
%     disp(M)
    

pause(30)


% --- This for loop 
%     for v = 1:length(i)
%         
%         Iv = i(v);
%         Jv = j(v);
%         Kv = k(v);
        
%         GLCM(Iv,Jv,Kv) = GLCM(Iv,Jv,Kv) - 1;
        
%     end

% --- OR 

    GLCM(i, j, k) = GLCM(i, j, k)-1;    % 
    
end

% toc
