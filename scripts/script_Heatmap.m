% This script is to demonstrate generation of a heatmap for
% cancer-noncancer tiles


%% SETUP 

images = getFiles(env.image_dir, 'Suffix', '.tif', 'Wildcard', '.8.tif');          % Wildcard so it selects the large .SCN layer image

tilesize = 256;

if matlabpool('size') == 0
    matlabpool local 4
end

%% Create heatmap-esque image 

i = 3;

block_func = @(I) mean2(I.data);

G = blockproc(images{i}, [tilesize tilesize], block_func);

orig = G;


%% Converting unique values in block image to continuous indices

G = orig;

G = round(G);

fprintf('Converting %d unique values to continuous indices .. \n', length(U))

G = im2indexim(G);

% figure;
subplot(221), imshow(G, jet(length(unique(G)))), title('Heatmap image');
% subplot(122), hist(G), title('Index histogram');

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

output_path = [env.root_dir '/heatmapper/' fliplr(strtok(fliplr(regexprep(images{i}, '.8.tif', '.8-mean2.tif')), '/'))]

save output_path 'G'