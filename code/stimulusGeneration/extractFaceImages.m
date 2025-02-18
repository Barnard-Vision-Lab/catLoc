%% pull out face images from the set provided by Kalanit Grill-Spector and Kendrick Kay
%% also, crop and scale them
%On 8.18.2020, Kalanit said:
%     hi Alex
%     Yes, you have my permission to use our face stimuli. All I would like you to do if you use them and they end in a publication is that tiy mention in the methods that these are 101 faces from the VPNL lab
%     Thanks
%     kalanit
%this is in a file called 'allviewpointfacesC11.mat'
% from Kendrick's "notes"
% this is similar to allrangefacesC5 in that we removed the same crappy subjects.
close all;
clear;

%% choices
%whether to set backgroung pixels outside the circular mask to NaN
nanBackground = true;

%whether to crop images to the smallest rectangle around the circular mask
cropToMask = true;

%whether to adjust each image's brightness levels to it spans the full
%range [0 255]. This is done by subtracting the mean, scaling the pixels
%below the mean by a fixed factor, and scaling the pixels above the mean by
%a fixed factor.
scaleIntensities = true;
%if scaleIntensities, what should the "middle level" be, against which
%dark and light are scaled? The middle level is the only one that is not
%changed. (see function scaleIntensitiesToRange). 
%If you want to just use the mean intensity of each image, set this to
%empty brackets []. 
midLevel = 161; 

%% load images 
%SET THIS DIRECTORY TO WHERE YOU SAVED THE FACE IMAGE MAT FILE 
stimDir = '/Users/alexlw/Dropbox/PROJECTS/stimulusImages/faceAndHandImages_From_Grill-Spector_Kay';

%this director is where the processed images are saved 
finalDir = fullfile(catLoc_Base, 'stimulusGeneration');

%and where pictures are saved 
figDir = fullfile(finalDir, 'faceImageGrids');


%pull from the C11 file: one of KNKs more recent processed versions 
load(fullfile(stimDir, 'allviewpointfacesC11.mat'));
%this contains a file called images which is 536 x 536 x 950
% there are pictures taken from 10 angles
angles = [30,60,90,120,-30,-60,-90,-120,0,180];
nAngles = length(angles);
% of 95 individuals
nPeople = 95;

% reshape so that dim3 is angle, dim4 is individual person
rsimages = reshape(images,size(images,1),size(images,2),nAngles,nPeople);

%% pull out a subset of images
%angles we want to use
anglesToInclude = [-60 0 60];
[~,angleIs]=  ismember(anglesToInclude, angles);
angles = angles(angleIs);


% % assign genders
genders = 'mf';
%1=male; 2=female
gender = zeros(1,nPeople);
gender(1:18) = [1 2 1 2 1 2 2 2 2 1 1 1 1 1 1 2 2 2];
gender(19:36) = [1 1 1 2 1 1 2 1 1 2 2 2 1 1 1 1 1 2];
gender(37:54) = [2 1 1 2 2 1 1 2 2 1 2 2 2 2 2 2 2 2];
gender(55:72) = [2 1 2 1 1 2 1 2 2 2 2 1 2 2 2 2 2 1];
gender(73:90) = [2 2 2 1 2 2 2 2 2 2 2 1 1 1 1 2 2 1];
gender(91:95) = [1 2 2 2 2];

nM = sum(gender==1)
nF = sum(gender==2)

% %show all identities
% nRows = 6;
% nCols = 3;
% nPerFig = nRows*nCols;
%
% figN = ceil((1:nPeople)/(nPerFig));
% subN = mod(1:nPeople, nPerFig);
% subN(subN==0) = nPerFig;
%
% for si=1:nPeople
%     figure(figN(si)); subplot(nRows, nCols, subN(si));
%     imshow(rsimages(:,:,6, si), [0 255]);
%     title(sprintf('%i %s', si, genders(gender(si))));
% end


%decide which to include or exclude
include = ones(1,nPeople);
%need to get rid of 17 females
include(16) = 0; %this is Kalanit. Excluding her b/c some subjects may know her
include(18) = 0;
if scaleIntensities
    include(24) = 0; %for some reason, when rescaling intensities for this guy, there are bright spots in the background
end
include(30) = 0;
include(40) = 0;
influde(50) = 0;
include(51) = 0;
include(53) = 0;
include(54) = 0;
include(55) = 0;
include(62) = 0;
include(68) = 0;
include(69) = 0;
include(70) = 0;
include(75) = 0;
include(77) = 0;
include(83) = 0;
include(88) = 0;
include(93) = 0;

%% make a new set for my experiment
close all;

faceImages = double(rsimages(:,:,angleIs, include==1));
gender = gender(include==1);
nID = size(faceImages,4);

nM = sum(gender==1)
nF = sum(gender==2)

%% crop and set background to NaN
%save unmodified version
origFaceImages = faceImages;

%these face images are already in a circular mask, which some border around
%the mask. Let's crop the images to the edge of the mask
%find the mask by averaging over faces
meanImg = squeeze(mean(mean(faceImages, 4), 3));
figure; imshow(meanImg, [0 255]);
title('Mean image');

%bgVal, which lies outside the max, should be equal to top left pixel of
%the mean image
bgVal = meanImg(1,1);
allIsBg = round(meanImg)==bgVal;
faceBounds = ImageBoundsAW(allIsBg, 1);

%set background to NaN, code should later replace NaN with whatever the
%screen bg aught to be
%allIsBg = repmat(allIsBg, [1 1 size(faceImages,3) size(faceImages,4)]);
%faceImages(allIsBg) = NaN;

% the circular mask seem to be off by 1 pixel at the bottom in some cases
% so let's apply a slightly smaller mask
radius = 0.5*min([faceBounds(3)-faceBounds(1) faceBounds(4)-faceBounds(2)]) - 1;
xs = 1:size(meanImg,2);
xs = round(xs-size(meanImg,2)/2);
ys = 1:size(meanImg,1);
ys = round(ys-size(meanImg,1)/2);
[X,Y] = meshgrid(xs,ys);
[~,rs]= cart2pol(X,Y);

mask = rs>radius;
if nanBackground
    maskRep = repmat(mask, [1 1 size(faceImages,3) size(faceImages,4)]);
    faceImages(maskRep) = NaN;
end


%crop
if cropToMask
    faceBounds = ImageBoundsAW(mask,1);
    faceImages = faceImages(faceBounds(1):faceBounds(3), faceBounds(2):faceBounds(4), :, :);
end

%% scale pixel intensities to span ful rnage

if scaleIntensities
    %save the ones not scaled
    for gi=1:size(faceImages,3)
        for ii=1:size(faceImages,4)
            faceImages(:,:,gi,ii) = scaleIntensitiesToRange(faceImages(:,:,gi,ii), [0 255], midLevel);
            if min(min(faceImages(:,:,gi,ii)))>0 || max(max(faceImages(:,:,gi,ii)))<255
                keyboard
            end
        end
    end
end


%% save 

save(fullfile(finalDir,'faceImages.mat'),'faceImages','origFaceImages','gender','angles');

%note: 
%on average, the face occupies space between pixels 65-375
%so the face occupies about (375-65+1)/size(meanImg,2) = 71% of the image,
%horizontally
%% show all people at 1 angle 
angleI = 2;

nRows = 4;
nCols = 4;
nPerFig = nRows*nCols;

subplotPositions = makeVariableSubplots(nRows, nCols, [0.04 0.01 0.01 0.01], 0.02, 0.01, 1, 1);


nFigs = ceil(nID/nPerFig);

figN = ceil((1:nID)/(nPerFig));
subN = mod(1:nID, nPerFig);
subN(subN==0) = nPerFig;

for si=1:nID
    figure(figN(si));  
    [ri,ci] = ind2sub([nRows nCols], subN(si));
    subplot('position', squeeze(subplotPositions(ri, ci, :)));

    imshow(faceImages(:,:,angleI, si), [0 255]);
    title(sprintf('%i %s', si, genders(gender(si))));
    
    if subN(si)==nPerFig || si==nID
        set(gcf,'units','centimeters','pos',[5 5 35 37]);
        saveas(gcf,fullfile(figDir, sprintf('FaceIms%i.png',figN(si))));
    end

end

meanImg = squeeze(mean(mean(faceImages, 4), 3));
figure; imshow(meanImg, [0 255]);

