function stats = calculateGleason( varargin )
%CALCULATEGLEASON Calculate Gleason grades, score + other statistics
% from an input indexed image. The index image must have the following
% class values:
%
% 0 : NON 
% 1 : TIS (i.e. NONCANCER TISSUE)
% 2 : G3
% 3 : G34
% 4 : G4
% 5 : G45
% 6 : G5
%

%% %%%%%%%%%%%
% Parse Inputs %
%%%%%%%%%%%%%%%%

check_image = @(x) isnumeric(x) && length(unique(x)) < 10;

p = inputParser;
p.addRequired('Image', check_image);
p.parse(varargin{:});

M = p.Results.Image;

% Median filter image for better estimation of tissue area coverage
% M = medfilt2(M, [3 3]);

%% %%%%%%%%%%%%%
% Some variables %
%%%%%%%%%%%%%%%%%%

grades = {'G3', 'G34', 'G4', 'G45', 'G5'};
grade_score = {3, 3.5, 4, 4.5, 5};
grade_idx = struct('G3', 2, 'G34', 3, 'G4', 4, 'G45',5, 'G5',6);

%% %%%%%%%%%%%%%%%%%%
% Calculate Statistics %
%%%%%%%%%%%%%%%%%%%%%%%

% Total area of image (used for ratio calculation)
stats.image_area =  size(M, 1) * size(M, 2);

% Tissue area (everything that is not light-microscope background)
stats.tissue_area = sum(sum(M>0));

% Areas of each gleason grade .. 
G3_area     = sum(sum(M==grade_idx.G3));
G34_area    = sum(sum(M==grade_idx.G34));
G4_area     = sum(sum(M==grade_idx.G4));
G45_area    = sum(sum(M==grade_idx.G45));
G5_area     = sum(sum(M==grade_idx.G5));
grade_areas = [G3_area, G34_area, G4_area, G45_area, G5_area];


% Area of cancer-noncancer tissue
stats.cancer_area = sum(grade_areas);

if stats.cancer_area == 0

stats.cancer_tissue_ratio = stats.cancer_area / stats.tissue_area;

% Primary tumour grade
stats.PRIMARY_grade = grades{grade_areas == max(grade_areas)};
stats.PRIMARY_score = grade_score{grade_areas == max(grade_areas)};

uv = unique(grade_areas);
second = uv(end-1);

% Secondary tumour grade & Gleason Score
if second ~= 0
    stats.SECONDARY_grade = grades{grade_areas == second};
    stats.SECONDARY_score = grade_score{grade_areas == second};
    
    % If there is a secondary grade, sum primary and secondary to get Gleason score
    stats.GLEASON_score = stats.PRIMARY_score + stats.SECONDARY_score;
else
    stats.SECONDARY_grade = 0;
    stats.SECONDARY_score = 0;
    
    % If there is no secondary grade, double primary to get Gleason score
    stats.GLEASON_score = stats.PRIMARY_score + stats.PRIMARY_score;
end

% Number of distinct tumour regions
TIS_area = M==1;
O = M;
O(TIS_area) = 0;

O(O>0) = 1;
O = logical(O);

CC = bwconncomp(O, 8);

stats.num_tumour_regions = CC.NumObjects

end

