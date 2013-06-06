% roughwork 

clear PC;

PC = PixelClassifier();

I = imread(cell2mat(test_images(6)));

CI = PC.GetClassifiedImage(I);

PI = PC.GetProcessedClassIndexImage(I);

PI = uint8(PI * (255/5));

figure;
subplot(311), imshow(I);
subplot(312), imshow(CI);
subplot(313), imshow(PI);