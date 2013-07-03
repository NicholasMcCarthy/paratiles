% Local tree pattern  histogram


% parameterized local pattern histogram


% given n classes, 

% Binary pattern search
% Tile image I with tiles of size TxT
% G <- For each pixel p(x,y) in tile T, compare pixel to 8-neighbours (anti) clockwise
    % Vb <- if p(x,y) > p(x',y') write 1 else 0 % e.g. 10010111 
    % Vd <- convert Vb binary number to decimal 
%

% H <- compute histogram of G values (i.e. Vd)
% Quantize H to n levels % (say, 32)

% N-ARY: 
% Compute histogram of pairwise values in H 
% There will be n(n+1)/2 histograms (triangular numbers, eh)
% so FV length = Q * n(n+1)/2
% Example:
% Gleason grades: {G3, G34, G4, G45, G5}
% 5 classes
% Q = 32
% FV length = 
C = 5;
Q = 32;
FV = rand(1, Q*(Q*(Q+1))/2)

blockidx = 1;
while (blockidx < length(FV))
   
    
    FV(blockidx:blockidx+(Q-1)) = FV(blockidx:blockidx+(Q-1))/Q; % normalize each histogram separately
    
%     sum(FV(blockidx:blockidx+(Q-1)))
    blockidx = blockidx + Q;
end
disp('Done');

% 
% (Optionally normalize H)
% FV <- Concatenate H for each T in I (heeeeyyy)

% Parameterized n-ary tree pattern search

% Given n classes
% will give 8 digit number in base n 
% Convert to decimal (will have very large range, possibly unstable) 
% take 5 classes ..
% 

%% Comparing decimal values + histogram length for n-ary local patterns

n = 5; % Number of classes

q = (n*(n+1)) /2


