function faceStims = makeCatLocFaceImages_Unilateral(displayName, imgDir)

params = catLoc_Params;
showImages = false;
if showImages
    pngDir = fullfile(imgDir, 'pngs');
    if ~isfolder(pngDir), mkdir(pngDir); end
end
%% screen info:
scr = getDisplayParameters(displayName);
scr.xres = scr.goalResolution(1);
scr.yres = scr.goalResolution(2);
scr.centerX = round(scr.xres/2);
scr.centerY = round(scr.yres/2);
scr.white = [255 255 255];
scr.black = [0 0 0];
pixPerDeg = scr.ppd;


%% load face images
load(fullfile(catLoc_Base,params.faces.imageFile));

nPeople = size(faceImages, 4);
nAngles = size(faceImages, 3);

faceImageIs = 1:(nAngles*nPeople);
faceImageIs = reshape(faceImageIs, nAngles, nPeople);


%test
%faceImageIs(3,35) == sub2ind([nAngles nPeople], 3, 35)
%% assign faces to images
nCat = length(params.faceCategories);
nImg = params.org.totalImgPerCategory + params.org.practiceImgPerCategory; %include some unique images for practice
nPos = sum(params.faces.posToUse);
widsDeg = params.faces.imgWidthDeg(params.faces.posToUse);
eccsDeg = params.stimLocs.eccs(params.faces.posToUse);
faceIDs = NaN(nCat, nImg); %which person is in each picture
faceAngleIs = NaN(nCat, nImg); %which angle is in each picture
faceIs = NaN(nCat, nImg);

for ci=1:nCat
    switch params.faceCategories{ci}
        case 'faces' %all faces not divided
            IDs = 1:nPeople;
            angleIs = 1:nAngles;
            inGenders = 1:2;
        case 'femaleFaces'
            IDs = find(gender==2);
            angleIs = 1:nAngles;
            inGenders = 2;
        case 'maleFaces'
            IDs = find(gender==1);
            angleIs = 1:nAngles;
            inGenders=1;
        case 'forwardFaces'
            IDs = 1:nPeople;
            angleIs = find(angles==0);
            inGenders = 1:2;
        case 'sideFaces'
            IDs = 1:nPeople;
            angleIs = find(angles~=0);
            inGenders = 1:2;
    end
    
    is = faceImageIs(angleIs, IDs);
    
    %first set the images at the fovea: 
    
    %assign persion IDs, with as few repeats as possible
    nRepSet = floor(nImg/length(IDs))-1;
    IDSet = [IDs repmat(IDs, 1, nRepSet)];
    nExtra = nImg - length(IDSet);
    IDSet = [IDSet randsample(IDs, nExtra, false)];
    IDSet = IDSet(randperm(length(IDSet)));
    IDSet = IDSet(1:nImg);
    
    faceIDs(ci, :) = IDSet;
        
    %pick which viewing angle for each person. Try to avoid repeats. 
    angleSet = NaN(size(IDSet));
    for person = IDs
        theseImgs = find(IDSet==person);
        if nAngles>=length(theseImgs)
            angleSet(theseImgs) = randsample(1:nAngles, length(theseImgs), 'false');
        else
            fprintf(1,'(%s) Warning not enough faces to avoid exact image repeats at fovea!\n', mfilename); 
            angleSet(theseImgs) = randsample(1:nAngles, length(theseImgs), 'true');
        end
    end
    faceAngleIs(ci, :) = angleSet;
  
    %store the unique index for each image, for this category and foveal location: 
    faceIs(ci, :) = sub2ind([nAngles, nPeople], angleSet, IDSet);
    
end

valsByIndex.category = params.faceCategories;
valsByIndex.stimNum = 1:nImg;


%% set image center positions in pixels
ctrXs = round(scr.centerX + pixPerDeg*params.stimLocs.x);
ctrYs = round(scr.centerY + pixPerDeg*params.stimLocs.y);

%but only use some locations
ctrXs = ctrXs(params.faces.posToUse);
ctrYs = ctrYs(params.faces.posToUse);

imgSize = [scr.yres scr.xres];


bgColor = scr.white*params.bgLum;

%% assemble images

faceSizePx = NaN(nCat, nImg, nPos, 2);
facesExtentPx = NaN(nCat, nImg, 2);

for ci = 1:nCat
    for ii = 1:nImg
        faceImage = double(faceImages(:, :, faceAngleIs(ci, ii), faceIDs(ci, ii)));

        %set NaNs to background
        faceImage(isnan(faceImage)) = bgColor(1);
        for pi=1:nPos

        %only grayscale
        img = ones([imgSize])*bgColor(1);
        
            
      
               %scale
            widthPx = widsDeg(pi)*pixPerDeg;
            
            faceImage = round(imresize(faceImage, [widthPx widthPx]));
                 
            %clip
            faceImage(faceImage<0) = 0;
            faceImage(faceImage>255) = 255;

            wid = size(faceImage,2);
            hei = size(faceImage,1);
            
            startX = ctrXs(pi) - floor(wid/2);
            endX = ctrXs(pi) + ceil(wid/2) - 1;
            
            startY = ctrYs(pi) - floor(hei/2);
            endY = ctrYs(pi) + ceil(hei/2) -1;
            
            img(startY:endY, startX:endX, :) = faceImage;
            
            faceSizePx(ci, ii, pi, :) = [wid hei];
        

            %find the bounds of all the faces in the image
            imBounds = ImageBoundsAW(img, bgColor(1));
            facesExtentPx(ci, ii, 1) = imBounds(3)-imBounds(1);
            facesExtentPx(ci, ii, 2) = imBounds(4)-imBounds(2);
                
        if showImages
            figure(1); clf;
            imshow(img,[0 255]);
            if ii<=params.org.totalImgPerCategory
                imgFile = fullfile(pngDir, sprintf('%s_%i_side%i.png', params.faceCategories{ci}, ii, pi));
            else
                imgFile = fullfile(pngDir, sprintf('%s_%i_side%i_PRAC.png', params.faceCategories{ci}, ii-params.org.totalImgPerCategory, pi));
            end
            saveas(gcf,imgFile);
        end
        if ii<=params.org.totalImgPerCategory
            imgFile = fullfile(imgDir, sprintf('%s_%i_side%i.mat', params.faceCategories{ci}, ii, pi));
        else
            imgFile = fullfile(imgDir, sprintf('%s_%i_side%i_PRAC.mat', params.faceCategories{ci}, ii-params.org.totalImgPerCategory, pi));
        end
        save(imgFile, 'img');
        end
    end
end

%separate out the practice images
pracFaceIs = faceIs(:,(params.org.totalImgPerCategory+1):end);
faceIs = faceIs(:,1:params.org.totalImgPerCategory+1);

faceStims.expParams = params;
faceStims.faceIs = faceIs;
faceStims.practiceFaceIs = pracFaceIs;
faceStims.faceAngleIs = faceAngleIs;
faceStims.faceIDs = faceIDs;
faceStims.faceGenders = gender(faceIDs);
faceStims.angles = angles;
faceStims.valsByIndex = valsByIndex;
faceStims.faceSizePx = faceSizePx;
faceStims.minFaceSizeDeg = squeeze(min(faceSizePx,[],2))/pixPerDeg;
faceStims.maxFaceSizeDeg = squeeze(max(faceSizePx,[],2))/pixPerDeg;
faceStims.meanFaceSizeDeg = squeeze(mean(faceSizePx,2))/pixPerDeg;
faceStims.facesExtentPx = facesExtentPx;
faceStims.minFacesExtentDeg = squeeze(min(facesExtentPx,[],2))/pixPerDeg;
faceStims.maxFacesExtentDeg = squeeze(max(facesExtentPx,[],2))/pixPerDeg;
faceStims.meanFacesExtentDeg = squeeze(mean(facesExtentPx,2))/pixPerDeg;
faceStims.imageDir = imgDir;
faceStims.targetScr = scr;

resFile = fullfile(imgDir, sprintf('faceStimParams_%s.mat', displayName));
save(resFile, 'faceStims');

