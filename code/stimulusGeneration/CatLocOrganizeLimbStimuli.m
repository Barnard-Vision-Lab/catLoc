
% Create images mat file for Alex's code that creates triplets
%stimDir = '/Volumes/GoogleDrive/My Drive/Projects/Intervention/Localizer/Limbs';
stimDir = '/Volumes/GoogleDrive/My Drive/Projects/Intervention/Localizer/Gray_BG_scale0';

%finalDir = fullfile(catLoc_Base, 'stimulusGeneration');
finalDir = stimDir;

figDir = fullfile(finalDir, 'limbImageGrids');
imgFile = fullfile(finalDir, 'limbImages.mat');

allImages = dir(fullfile(stimDir,'*.png'));
fileNames = {allImages.name}';
limbImages = [];
 
 % We read all images and save them into a single mat file 
 for id = 1:numel(fileNames)
     curFileName = fullfile(stimDir,fileNames{id});
     curImage = imread(curFileName);
     % Alex has rescaled all images to the range [0 255]
     % If I do it on the images with the 161 bg it looks really bad
     % rescaledImage = scaleIntensitiesToRange(curImage, [0 255]);
     % figure;imshow(curImage);title('orig');
     % figure;imshow(rescaledImage);title('rescaled');
     
     % I checked and the images are not rescaled, some have max 217, 246,
     % 255
     
     limbImages(:,:,id) = curImage;
 end
 
 save(imgFile, 'limbImages');
 