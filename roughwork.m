
philips = getFiles('/media/Data/philips.test/region', 'Suffix', '.tif')

Tif = Tiff(philips{2});
info = imfinfo(philips{2});
numImages = numel(info);


%%  

scn9 = {};

for i = 1:20
    loc = ['/media/Data/PCRC_Dataset/' sprintf('%02.2g', i) '/'];
    scn = getFiles(loc, 'Suffix', '.tif', 'Wildcard', '.9.');
    
    scn9 = horzcat
    
end    
 scn = getFiles('/media/Data/PCRC_Dataset/', 'Suffix', '.tif', 'Wildcard', '.9.');


 %% 

 
 newloc = '/media/Data/dataset.PCRC/';
 
images = {}

for i = 1:20
    
    loc = ['/media/Data/PCRC_Dataset/' sprintf('%02.2g', i) '/'];
    
    image = getFiles(loc , 'Suffix', '.tif', 'Wildcard', '.9.tif'  );
    
    cmd1 = ['mv ' image{1} ' ' newloc] 
    
    % Call command to tiffsplit
    status1 = system(cmd1)
    
end
