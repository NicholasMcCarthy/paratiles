
% 1. Starting with a GLCM for a given area at 40x magnification

% 2. If we have the 4 orthagonal distance 1 matrices (0,90,180,270 degrees)
%  then we can reduce the matrix to the equivelent 20x resolution GLCM by
%  pairing pixel adjacencies and popping them off the GLCM 'stack', and
%  calculate the derived interpolation value (starting with bicubic interpolation since it's probably 
%  the easiest to do ..

% The test image .. 
I = imread('hestain.png');
% Make it a tile for simples, and make it small so I can wrap my head
% around it .. 
I = I(1:10,1:10,:);

% Offsets vector: distance 1 unsymmetric orthagonal directions adjacency matrices
GLCM_offsets= [ 0 1; 1 0 ; 0 -1 ; -1 0] ;
[GLCM SI] = graycomatrix(I(:,:,1), 'offset', GLCM_offsets, 'Symmetric', false);
    
% Output GLCMs for lower res image
G = zeros(size(GLCM));

figure;
subplot(121), imshow(I);
subplot(122), imshow(SI, jet(max(max(SI)) ));

%% Getting number of adjacencies in an image .. 

% Anonymous function 
get_num_adjacencies = @(H, W, O) H * W * O - ((W*2) + ((H-2)*2) + O) ; 

% Vars
W = size(I, 1);             % image width
H = size(I, 2);             % image height
O = length(GLCM_offsets);   % number of adacencies per inner pixel

num_adjacencies_gt = sum(GLCM(:));

num_adjacencies = get_num_adjacencies(H, W, O);

% Vars for lower resolution image (assuming a linear size rescaling)
Wb = W / 2;     % Image resolution twice as low (40x->20x)
Hb = H / 2;     %  Image resolution twice as low (40x->20x)
Ob = O;         % Same number of adjacencies though 

num_adjacencies_b = get_num_adjacencies(Hb, Wb, Ob); % in interpolated GLCM

%% Re-potting GLCM values 

% Values on 

% Intermediate matrix for popped values
T = zeros(size(GLCM));

it_idx = 1;

% while sum(GLCM(:)) > 10    
    
while it_idx < 5
    
    % Maximum value currently in GLCM
    M = max(GLCM(:));
    % Indices / intensity values of max value
    M_idx = find(GLCM == M);
    [i,j,k] = ind2sub(size(GLCM),find(GLCM == max(GLCM(:)))); % Gets i, j, k values for largest GLCM values 
    
    % Popping values off the stack .. 
    GLCM(i, j, k) = GLCM(i, j, k)-1;    % 
    
    % Push values onto temp matrix
    T(i, j, k) = T(i, j, k) + 1;
    
    % Match values for interpolation in temp matrix
%     match_function(T);
    
    it_idx = it_idx +1;
end

%% Match function 

% Anonymous interpolation match function for the moment
match_function = @(x) disp('Uhhh');

% Given the temporary popped values matrix from above

%--------------------------------
% Finding a 2x2 neighbourhood:

% 1. Find max value in T(1) matrices

% 2. Get indices/intensity values of max value (could be multiple pairings
% .. ?) -> (i,j)

% 3. There must be entries in (i,j) columns in the other matrices 


%---------------------------------
% 2x2 neighbourhood 

% Four entry pairs:
% e.g. (3,4) N
%      (4,2) E
%      (2,3)  

% 3x3 neighbourhood

% Nearest-neighbour interpolation - chooses largest value in neighbourhood
% Bi-linear interpolation - chooses rounded average value in neighbourhood
