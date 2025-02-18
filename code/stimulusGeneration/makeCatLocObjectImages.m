function objectStims = makeCatLocObjectImages(displayName, imgDir)

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


%% load object images
load(fullfile(catLoc_Base,params.objects.imageFile));

nObjects = size(objectImages, 3);
%% assign objects to images
nCat = length(params.objectCategories);
nImg = params.org.totalImgPerCategory + params.org.practiceImgPerCategory; %include some unique images for practice
nPos = sum(params.objects.posToUse);
widsDeg = params.objects.imgWidthDeg(params.objects.posToUse);
eccsDeg = params.stimLocs.eccs(params.objects.posToUse);
objectIs = NaN(nCat, nPos, nImg);
fovealI = find(eccsDeg == 0);
periphIs = find(eccsDeg ~= 0);
nPosPeriph = length(periphIs);

for ci=1:nCat
    switch params.objectCategories{ci}
        case 'objects' %everything in one bin 
            is = 1:nObjects;
        case 'objects1' %odd numbered objects
            is = 1:2:nObjects;
        case 'objects2' %even numbered objects
            is = 2:2:nObjects;
    end
        
    %assign object image indices to foveal position, with as few repeats as possible
    nRepSet = floor(nImg/length(is))-1;
    fovealSet = [is repmat(is, 1, nRepSet)];
    nExtra = nImg - length(fovealSet);
    fovealSet = [fovealSet randsample(is, nExtra, false)];
    fovealSet = fovealSet(randperm(length(fovealSet)));
    fovealSet = fovealSet(1:nImg);
 
    objectIs(ci, fovealI, :) = fovealSet;
    
   
    
    unusedIs = setdiff(is, fovealSet);
    
    %assign images all the other positions, avoiding  repeats at any
    %one position, and as few repeats overall as possible
    for ii=1:nImg
        for pp = 1:nPosPeriph
            posI = periphIs(pp);
             
            thisImgIs = squeeze(objectIs(ci, :, ii));
            thisImgIs = thisImgIs(~isnan(thisImgIs));

            %if there are any, draw from indices not yet used anywhere
            if ~isempty(unusedIs)
                thisI = unusedIs(randsample(1:length(unusedIs), 1));
                
            else
                %otherwise, draw from indices not used at this position yet
                %find indices not yet used at this position
                thisPosNotUsedIs = setdiff(is(:), squeeze(objectIs(ci, posI, :)));
                %and not used in this IMAGE yet 
                thisPosNotUsedIs = setdiff(thisPosNotUsedIs, thisImgIs);
                
                if ~isempty(thisPosNotUsedIs)
                    thisI = thisPosNotUsedIs(randsample(1:length(thisPosNotUsedIs), 1));

                else
                    fprintf(1,'\nWarning: no unused object images to use, image %i of %i\n', ii, nImg);
                    if ii>params.org.totalImgPerCategory
                        fprintf(1,'\nThis for a practice image.  We''ll re-use a random one.\n');
                    else 
                        keyboard
                    end
                    %avoid repeats within the same image 
                    okIs = setdiff(is(:), thisImgIs);
                    thisI = randsample(okIs(:), 1);
                end
            end
                      
            if any(thisI==objectIs(ci, 1:pp, ii))
                keyboard
            end
            
            objectIs(ci, posI, ii) = thisI;
 
            
            unusedIs = setdiff(unusedIs, thisI);
        end
    end
end

valsByIndex.category = params.objectCategories;
valsByIndex.position = 1:nPos;
valsByIndex.stimNum = 1:nImg;

%check there are no repeats at each pos
for ci=1:nCat
    for pp=1:nPos
        nRepeats = nImg - length(unique(squeeze(objectIs(ci, pp, :))));
        if nRepeats>0
            fprintf(1,'\n(%s)WARNING - not enough %s at position %i (ecc=%.1fdeg): %i repeats out of %i\n', mfilename, params.objectCategories{ci}, pp, eccsDeg(pp), nRepeats, nImg);
            pause(0.5);
           % if params.stimLocs.eccs(pp)==0, keyboard; end
        end
    end
end

%% check that there are no repeats in each image 
for ci=1:nCat
    for ii=1:nImg
        nRepeats = nPos - length(unique(squeeze(objectIs(ci, :, ii))));
        if nRepeats>0
            fprintf(1,'\n(%s)WARNING - one object appears twice!\n', mfilename);
            keyboard
        end
    end
end


%% set image center positions in pixels
ctrXs = round(scr.centerX + pixPerDeg*params.stimLocs.x);
ctrYs = round(scr.centerY + pixPerDeg*params.stimLocs.y);

%but only use some locations
ctrXs = ctrXs(params.objects.posToUse);
ctrYs = ctrYs(params.objects.posToUse);

imgSize = [scr.yres scr.xres];


bgColor = scr.white*params.bgLum;

%% assemble images

objectSizePx = NaN(nCat, nImg, nPos, 2);
objectsExtentPx = NaN(nCat, nImg, 2);

for ci = 1:nCat
    for ii = 1:nImg
        %only grayscale
        img = ones(imgSize)*bgColor(1);
        
        for pi=1:nPos
            
            objImage = double(objectImages(:, :, objectIs(ci, pi, ii)));
               
            %set NaNs to background 
            objImage(isnan(objImage)) = bgColor(1); 
            
                        
            %crop to smallest square possible 
            bounds = ImageBoundsAW(round(objImage), bgColor(1)); 
            wid = bounds(3)-bounds(1)+1;
            hei = bounds(4)-bounds(2)+1;
                        
            if wid>hei
                startC = bounds(1); endC = bounds(3); 
                %try to center the object vertically in the cropped square:
                midR = round(mean(bounds([2 4]))); 
                %sometimes that doesnt work if the object wasnt centered to
                %begin with, so we just won't go less than 1 or over the
                %max number of rows already there. in that case the image
                %wont be a perfect square but thats ok: 
                startR = max([1 midR-floor(wid/2)]); 
                endR = min([midR+ceil(wid/2)-1 size(objImage,1)]);
                
            else
                startR = bounds(2); endR = bounds(4); 
                midC = round(mean(bounds([1 3]))); 
                startC = max([1 midC-floor(hei/2)]); 
                endC = min([midC+ceil(hei/2)-1 size(objImage,1)]);
            end
            
            objImage = round(objImage(startR:endR,  startC:endC));
                
    

            %scale
            widthPx = widsDeg(pi)*pixPerDeg;
            
            objImage = round(imresize(objImage, [widthPx widthPx]));
            
              %clip brightness
            objImage(objImage<0) = 0;
            objImage(objImage>255) = 255;
       
            
            wid = size(objImage,2);
            hei = size(objImage,1);
            
            
            startX = ctrXs(pi) - floor(wid/2);
            endX = ctrXs(pi) + ceil(wid/2) - 1;
            
            startY = ctrYs(pi) - floor(hei/2);
            endY = ctrYs(pi) + ceil(hei/2) -1;
            
            img(startY:endY, startX:endX, :) = objImage;
            
            bounds = ImageBoundsAW(objImage, bgColor(1));

            objectSizePx(ci, ii, pi, :) = [bounds(3)-bounds(1) bounds(4)-bounds(2)];

        end
        
        %find the bounds of all the objects in the image
        imBounds = ImageBoundsAW(img, bgColor(1));
        objectsExtentPx(ci, ii, 1) = imBounds(3)-imBounds(1);
        objectsExtentPx(ci, ii, 2) = imBounds(4)-imBounds(2);
       
        
        if showImages
            figure(1); clf;
            imshow(img,[0 255]);
            if ii<=params.org.totalImgPerCategory
                imgFile = fullfile(pngDir, sprintf('%s_%i.png', params.objectCategories{ci}, ii));
            else
                imgFile = fullfile(pngDir, sprintf('%s_%i_PRAC.png', params.objectCategories{ci}, ii-params.org.totalImgPerCategory));
            end
            saveas(gcf,imgFile);
        end
        if ii<=params.org.totalImgPerCategory
            imgFile = fullfile(imgDir, sprintf('%s_%i.mat', params.objectCategories{ci}, ii));
        else
            imgFile = fullfile(imgDir, sprintf('%s_%i_PRAC.mat', params.objectCategories{ci}, ii-params.org.totalImgPerCategory));
        end
        save(imgFile, 'img');
        
    end
end

%separate out the practice images
pracObjIs = objectIs(:,:,(params.org.totalImgPerCategory+1):end);
objectIs = objectIs(:,:,1:params.org.totalImgPerCategory+1);


objectStims.expParams = params;
objectStims.objectLabels = objectLabels;
objectStims.objectIs = objectIs;
objectStims.practiceObjectIs = pracObjIs;
objectStims.valsByIndex = valsByIndex;
objectStims.objectSizePx = objectSizePx;
objectStims.meanObjectSizeDeg = squeeze(mean(objectSizePx,2))/pixPerDeg;
objectStims.minObjectSizeDeg = squeeze(min(objectSizePx,[],2))/pixPerDeg;
objectStims.maxObjectSizeDeg = squeeze(max(objectSizePx,[],2))/pixPerDeg;
objectStims.objectsExtentPx = objectsExtentPx;
objectStims.meanObjectsExtentDeg = squeeze(mean(objectsExtentPx,2))/pixPerDeg;
objectStims.minObjectsExtentDeg = squeeze(min(objectsExtentPx,[],2))/pixPerDeg;
objectStims.maxObjectsExtentDeg = squeeze(max(objectsExtentPx,[],2))/pixPerDeg;
objectStims.imageDir = imgDir;
objectStims.targetScr = scr;

resFile = fullfile(imgDir, sprintf('objectStimParams_%s.mat', displayName));
save(resFile, 'objectStims');

