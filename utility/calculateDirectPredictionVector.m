function FV = calculateDirectPredictionVector( varargin )
%CALCULATEDIRECTPREDICTIONVECTOR
% Calculate a vector for direct prediction of Gleason classified images. 
% This takes the form of a normalized vector with the relative areas of
% non-cancerous tissue and each Gleason grade {G3, G34, G4, G45, G5}.

%% %%%%%%%%%%%
% Parse Inputs %
%%%%%%%%%%%%%%%%

check_image = @(x) isnumeric(x) && length(unique(x)) < 10;

p = inputParser;
p.addRequired('Image', check_image);
p.parse(varargin{:});

M = p.Results.Image;

%% %%%%%%%%%%%%%
% Some variables %
%%%%%%%%%%%%%%%%%%

grades = {'G3', 'G34', 'G4', 'G45', 'G5'};
grade_score = {3, 3.5, 4, 4.5, 5};
grade_idx = struct('TIS', 1, 'G3', 2, 'G34', 3, 'G4', 4, 'G45',5, 'G5',6);

%% %%%%%%%%%%%%%%%%%%
% Calculate Vector  %
%%%%%%%%%%%%%%%%%%%%%

% Total area of image (used for ratio calculation)
stats.image_area =  size(M, 1) * size(M, 2);

% Tissue area (everything that is not light-microscope background)
stats.tissue_area = sum(sum(M>0));

% Areas of each gleason grade .. 
TIS_area    = sum(sum(M==grade_idx.TIS));
G3_area     = sum(sum(M==grade_idx.G3));
G34_area    = sum(sum(M==grade_idx.G34));
G4_area     = sum(sum(M==grade_idx.G4));
G45_area    = sum(sum(M==grade_idx.G45));
G5_area     = sum(sum(M==grade_idx.G5));
grade_areas = [TIS_area G3_area, G34_area, G4_area, G45_area, G5_area];

total = sum(grade_areas);

FV = grade_areas / total;

end

