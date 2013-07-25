% This script is to demonstrate generation of a heatmap for
% cancer-noncancer tiles


%% SETUP 

images = getFiles(env.image_dir, 'Suffix', '.tif', 'Wildcard', '.8.tif');          % Wildcard so it selects the large .SCN layer image

tilesize = 256;

if matlabpool('size') == 0
    matlabpool local 4
end

%% Create heatmap-esque image 

block_func = @(I) entropy(I.data);

for i = 1:length(images)

    G = blockproc(images{i}, [tilesize tilesize], block_func);

    output_path = [env.root_dir '/heatmapper/' fliplr(strtok(fliplr( regexprep(images{i}, '.8.tif', '.8-ent2.tif') ), '/')) ]

    save(output_path, 'G')
end

sendmail('nicholas.mccarthy@gmail.com', 'Heatmap generation completed (for real this time).')

%% Displaying all images

figure;

quanta = 50;
idx = 1

for i = 1:length(images)
    
    % Path to heatmap image
    heatmap_path = [env.root_dir '/heatmapper/' fliplr(strtok(fliplr( regexprep(images{i}, '.8.tif', '.8-mean2.tif') ), '/')) ];

    % Import image
    G = importdata(heatmap_path);

    % Round double values, quantize to 30 and convert to index image
    
    G = im2indexim(quantizeImage(round(G), quanta));
    
    [X Y] = size(G)
    
    if Y > X
        G = rot90(G)
    end
    
    subplot(4, 5, idx), imshow(G, jet(quanta));
    
    idx = idx + 1;
    
end

%% Converting unique values in block image to continuous indices

G = orig;

G = round(G);

fprintf('Converting %d unique values to continuous indices .. \n', length(unique(G)))

G = im2indexim(G);

% figure;
subplot(121), imshow(G, jet(length(unique(G)))), title('Heatmap image');
subplot(122), hist(G), title('Index histogram');

%% Background subtraction

H1 = imfilter(G, fspecial('prewitt'));

subplot(223), imshow(H1);

H2 = imfilter(G, fspecial('prewitt')' );

subplot(224), imshow(H2);

H = xor(H1, H2);

subplot(222), imshow(H, jet(length(unique(G))))



%%

E = grayslice(G, [0.1:0.1:1])

% E = im2indexim(E)

figure, imshow(E, jet(length(unique(E))))


%%
H = G;

bordermean = floor(mean(getBorderValues(H)))

low = min(min(H));
high = max(max(H));

B = H;

B = B - low;

B = B ./ (high - low)

threshold_level = (bordermean - low) / (high - low);

B = im2bw(B, threshold_level)

subplot(122), imshow(B)


%% Save something .. 
