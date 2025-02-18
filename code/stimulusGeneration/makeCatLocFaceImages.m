function faceStims = makeCatLocFaceImages(displayName, imgDir)

params = catLoc_Params;
nPos = params.stimLocs.n;

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
faceIDs = NaN(nCat, nPos, nImg); %which person is in each picture
faceAngleIs = NaN(nCat, nPos, nImg); %which angle is in each picture
faceIs = NaN(nCat, nPos, nImg);
fovealI = find(eccsDeg == 0);
periphIs = find(eccsDeg ~= 0);
nPosPeriph = length(periphIs);

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
    
    %assign persion IDs to foveal position, with as few repeats as possible
    nRepSet = floor(nImg/length(IDs))-1;
    fovealIDSet = [IDs repmat(IDs, 1, nRepSet)];
    nExtra = nImg - length(fovealIDSet);
    fovealIDSet = [fovealIDSet randsample(IDs, nExtra, false)];
    fovealIDSet = fovealIDSet(randperm(length(fovealIDSet)));
    fovealIDSet = fovealIDSet(1:nImg);
    
    faceIDs(ci, fovealI, :) = fovealIDSet;
        
    %pick which viewing angle for each person. Try to avoid repeats. 
    fovealAngleSet = NaN(size(fovealIDSet));
    for person = IDs
        theseImgs = find(fovealIDSet==person);
        if nAngles>=length(theseImgs)
            fovealAngleSet(theseImgs) = randsample(1:nAngles, length(theseImgs), 'false');
        else
            fprintf(1,'(%s) Warning not enough faces to avoid exact image repeats at fovea!\n', mfilename); 
            fovealAngleSet(theseImgs) = randsample(1:nAngles, length(theseImgs), 'true');
        end
    end
    faceAngleIs(ci, fovealI, :) = fovealAngleSet;
  
    %store the unique index for each image, for this category and foveal location: 
    faceIs(ci, fovealI, :) = sub2ind([nAngles, nPeople], fovealAngleSet, fovealIDSet);
    
        
    %now assign images all the other positions, avoiding  repeats at any
    %one position, and as few repeats overall as possible
    unusedIs = setdiff(is(:), faceIs(ci, fovealI, :));

    for ii=1:nImg
        for pp = 1:nPosPeriph
            posI = periphIs(pp);
            
            thisImgIs = squeeze(faceIs(ci, :, ii));

            %find IDs of people in images not used at all yet
            [~,unusedIDs] = ind2sub([nAngles nPeople], unusedIs);
            
            %person IDs already used in this image
            imageUsedIDs = faceIDs(ci, :, ii);
            imageUsedIDs = imageUsedIDs(~isnan(imageUsedIDs));
            
            %avoid having the same person appear in this image
            goodIDIs = ~ismember(unusedIDs, imageUsedIDs);
            goodUnusedIs = unusedIs(goodIDIs);
            
            
            %if there are any, draw from indices not yet used anywhere
            if ~isempty(goodUnusedIs)
                thisI = goodUnusedIs(randsample(1:length(goodUnusedIs), 1));
                
            else
                %otherwise, draw from indices not used at this position yet
                %find indices not yet used at this position
                thisPosNotUsedIs = setdiff(is(:), faceIs(ci, posI, :));
                %and get the person IDs associated with those unused image indices
                [~,thisPosNotUsedIDs] = ind2sub([nAngles nPeople], thisPosNotUsedIs);
                
                %don't use any of those same people already used in this image 
                isUsed = ismember(thisPosNotUsedIDs, imageUsedIDs);
                thisPosNotUsedIs = thisPosNotUsedIs(~isUsed);
                %and not used in this IMAGE yet 
                if pp>1
                    thisPosNotUsedIs = setdiff(thisPosNotUsedIs, thisImgIs);
                end
                
                if ~isempty(thisPosNotUsedIs)
                    thisI = thisPosNotUsedIs(randsample(1:length(thisPosNotUsedIs), 1));

                else
                    fprintf(1,'\nWarning: no unused face images to use, image %i of %i\n', ii, nImg);
                    if ii >params.org.totalImgPerCategory
                      fprintf(1,'\nThis for a practice image.  We''ll re-use a random one.\n');
                    else
                        keyboard
                    end
                    okIs = setdiff(is(:), thisImgIs);
                    thisI = randsample(okIs(:), 1);

                end
            end
            
            faceIs(ci, posI, ii) = thisI;
            [faceAngleIs(ci, posI, ii), faceIDs(ci, posI, ii)] = ind2sub([nAngles nPeople], thisI);
            unusedIs = setdiff(unusedIs, thisI);
            
            %check that gender worked 
            thisGender = gender(faceIDs(ci, posI, ii));
            if ~any(thisGender==inGenders), keyboard; end
        end
    end
end

valsByIndex.category = params.faceCategories;
valsByIndex.position = 1:nPos;
valsByIndex.stimNum = 1:nImg;

%check there are no repeats at each pos
for ci=1:nCat
    for pp=1:nPos
        nRepeats = nImg - length(unique(squeeze(faceIs(ci, pp, :))));
        if nRepeats>0
            fprintf(1,'\n(%s)WARNING - not enough %s at position %i (ecc=%.1fdeg): %i repeats out of %i\n', mfilename, params.faceCategories{ci}, pp, eccsDeg(pp), nRepeats, nImg);
            pause(0.5);
            % if params.stimLocs.eccs(pp)==0, keyboard; end
        end
    end
end


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
        %only grayscale
        img = ones([imgSize])*bgColor(1);
        
        for pi=1:nPos
            
            faceImage = double(faceImages(:, :, faceAngleIs(ci, pi, ii), faceIDs(ci, pi, ii)));
            
            %set NaNs to background
            faceImage(isnan(faceImage)) = bgColor(1); 
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
        end
        
        %find the bounds of all the faces in the image 
        imBounds = ImageBoundsAW(img, bgColor(1));
        facesExtentPx(ci, ii, 1) = imBounds(3)-imBounds(1);
        facesExtentPx(ci, ii, 2) = imBounds(4)-imBounds(2);
                
        if showImages
            figure(1); clf;
            imshow(img,[0 255]);
            if ii<=params.org.totalImgPerCategory
                imgFile = fullfile(pngDir, sprintf('%s_%i.png', params.faceCategories{ci}, ii));
            else
                imgFile = fullfile(pngDir, sprintf('%s_%i_PRAC.png', params.faceCategories{ci}, ii-params.org.totalImgPerCategory));
            end
            saveas(gcf,imgFile);
        end
        if ii<=params.org.totalImgPerCategory
            imgFile = fullfile(imgDir, sprintf('%s_%i.mat', params.faceCategories{ci}, ii));
        else
            imgFile = fullfile(imgDir, sprintf('%s_%i_PRAC.mat', params.faceCategories{ci}, ii-params.org.totalImgPerCategory));
        end
        save(imgFile, 'img');
        
    end
end

%separate out the practice images
pracFaceIs = faceIs(:,:,(params.org.totalImgPerCategory+1):end);
faceIs = faceIs(:,:,1:params.org.totalImgPerCategory+1);

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

