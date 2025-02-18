clear; close all;

global img iter

%% extract object pictures from the Bao & Tsao set

%whether to start from scratch, or load in work you already started
startFromScratch = false;

stimDir = '/Users/alexlw/Dropbox/PROJECTS/stimulusImages/stimsFromBaoTsao2020';

finalDir = fullfile(catLoc_Base, 'stimulusGeneration');
figDir = fullfile(finalDir, 'objectImageGrids');

imgFile = fullfile(finalDir, 'objectImages.mat'); 

if startFromScratch
    L = readtable(fullfile(stimDir, 'BaoTsaoImageLabels.xlsx'));
    load(fullfile(stimDir, 'ims.mat'));
    
    %exclude some categories
    catsToExclude = {'places'};
    
    %only include a subset
    objectLabels = L(L.include==1 & ~ismember(L.category,catsToExclude),:);
    
    numImages = size(objectLabels,1);
    categories = unique(objectLabels.category);
    nCats = numel(categories);
    nPerCat = zeros(1,nCats);
    
    % % save subset of images
    objectLabels.originalIndex = objectLabels.number;
    objectLabels.number = (1:numImages)';
    
    objectImages = double(ims(:,:,objectLabels.originalIndex));
    origImages = objectImages;
    
    clear ims;
    
    
    opts.oldBG = 255;
    opts.newBG = NaN;
    opts.doFeather = true;
    opts.featherTargetVal = 161;
    
    opts.rescaleIntensities = true;
    
else
    load(imgFile, 'objectImages','objectLabels', 'nPerCat','opts','origImages');
    numImages = size(objectLabels,1);
    categories = unique(objectLabels.category);
    nCats = numel(categories);
 
end


%set figPos
%figpos = [2030 300 1250 1100];

figure(1); imshow(objectImages(:,:,1), [0 255]);
fprintf(1,'\nMove and scale the image to where you want all the images to appear. Make sure its big enought to see small details\n');
fprintf(1,'\nPress the space bar when you''re done\n'); 

pause 

figpos = get(gcf,'pos'); 



%% set background to NaN

ois = 1:size(objectImages,3);
for oi = ois
    %try to save time by automatically starting from the 4 corners
    img = replaceImageBackground(objectImages(:,:,oi), opts.oldBG, opts.newBG, opts.doFeather, opts.featherTargetVal);
    
    %KLUGE for one weird repeated backpack
    if objectLabels.originalIndex(oi)==219
        img = fliplr(img);
    end
    
    fh = figure(1); clf;
    imshow(img, [0 255]);
    set(fh, 'pos', figpos);
    
    %% click on points that need to be filled in with bg
    done = false;
    while ~done
        continueStr = 'x';
        while ~any(continueStr=='yn')
            figure(fh);
            commandwindow;
            continueStr = input('\nDoes this image need any background filled? y/n\n', 's');
        end
        done = continueStr=='n';
        if ~done
            fprintf(1,'\nClick on a point in the image that contains a background patch\n');
            %get point from mouse click:
            h=drawpoint;
            pis = sub2ind(size(img), round(h.Position(2)), round(h.Position(1)));
            
            %replace that patch:
            iter = 0;
            replaceContiguousImagePatch(pis, opts.oldBG, NaN, opts.doFeather, opts.featherTargetVal);
            
            %re-draw image:
            figure(fh); clf;
            imshow(img, [0 255]);
            set(fh, 'pos', figpos);
            
        end
    end
    
    %% RESCALE INTENSITY TO FILL [0 255] range
    if opts.rescaleIntensities
        img = scaleIntensitiesToRange(img, [0 255]);
    end
        

    objectImages(:,:,oi) = img;
end

%% filter out a few bad ones that have too much shadow under them 
excludeNums = unique([359 370 1049]);

for ei=1:length(excludeNums) 
    oi = find(objectLabels.originalIndex==excludeNums(ei));
    figure; imshow(objectImages(:,:,oi), [0 255]);
    title(sprintf('Excluding img %i', excludeNums(ei)));
    objectImages = objectImages(:,:,objectLabels.originalIndex~=excludeNums(ei));
    objectLabels = objectLabels(objectLabels.originalIndex~=excludeNums(ei), :);
end

%reset number:
objectLabels.number = (1:size(objectImages,3))';

   
%% rotate
rotateNums = unique([328:330 343 358 950 1015:1017 1032 1036 1061 1381 1394 1479]);
negDirNums = [950 1016 1381 1479]; 
[~,iis] = ismember(negDirNums, rotateNums); 
rotateK = ones(size(rotateNums)); 
rotateK(iis) = -1; 

for ri=1:length(rotateNums)
    oi = find(objectLabels.originalIndex==rotateNums(ri));
    objImg = objectImages(:,:,oi); 
    rotImg = rot90(objImg,rotateK(ri)); 
    figure(5); clf; 
    subplot(1,2,1); imshow(objImg, [0 255]); 
    title(sprintf('img %i', rotateNums(ri)));
    subplot(1,2,2); imshow(rotImg, [0 255]); 
    title(sprintf('rotated %i deg', 90*rotateK(ri)));

    pause
    
    objectImages(:,:,oi) = rotImg;
end
    
%% hand edit 
figpos = [2061         134        1752        1308];

needsEdit = [950];
for ei=1:length(needsEdit)
    figure(6); clf; 
    oi = find(objectLabels.originalIndex==needsEdit(ei));    
    objImg = objectImages(:,:,oi); 
    subplot(1,2,1); imshow(objImg, [0 255]); 
    set(gcf,'pos', figpos);
    
    newImg = objImg;

    switch needsEdit(ei)
        case 679
            bgRectCols = 43:62; 
            bgRectRows = 165:173;
            newImg(bgRectRows, bgRectCols) = NaN;
        case 684
            img = newImg;
            fh = figure(1); clf;
            imshow(img, [0 255]);
            set(fh, 'pos', figpos);
            %% click on points that need to be filled in with bg
            done = false;
            while ~done
                continueStr = 'x';
                while ~any(continueStr=='yn')
                    figure(fh);
                    commandwindow;
                    continueStr = input('\nDoes this image need any background filled? y/n\n', 's');
                end
                done = continueStr=='n';
                if ~done
                    fprintf(1,'\nClick on a point in the image that contains a background patch\n');
                    %get point from mouse click:
                    h=drawpoint;
                    pis = sub2ind(size(img), round(h.Position(2)), round(h.Position(1)));
                    
                    %replace that patch:
                    iter = 0;
                    replaceContiguousImagePatch(pis, NaN, NaN, opts.doFeather, opts.featherTargetVal);
                    
                    %re-draw image:
                    figure(fh); clf;
                    imshow(img, [0 255]);
                    set(fh, 'pos', figpos);
                    
                end

            end
            newImg = img;
            
            bgRectCols = 88:152;
            bgRectRows = 172:175;
            newImg(bgRectRows, bgRectCols) = NaN;
        case 950 
            bgRectRows = [159 166; 155 164; 155 161]; 
            bgRectCols = [13 30;   31 36;   37 44];
            for rcti=1:size(bgRectRows,1)
                newImg(bgRectRows(rcti,1):bgRectRows(rcti,2), bgRectCols(rcti,1):bgRectCols(rcti,2)) = 254;

            end
    end
    subplot(1,2,2); imshow(newImg, [0 255]); 
    pause
    
    objectImages(:,:,oi) = newImg;
end

    

%% save 
save(imgFile, 'objectImages','objectLabels', 'nPerCat','opts','origImages');


%% show image grids
nrow = 5;
ncol = 5;
nPerFig = nrow*ncol;

subplotPositions = makeVariableSubplots(nrow, ncol, [0.04 0.01 0.01 0.01], 0.02, 0.01, 1, 1);

for catI=1:nCats
    subL = objectLabels(strcmp(objectLabels.category, categories{catI}), :);
    ni = size(subL,1);
    
    nPerCat(catI) = ni;
    
    nfig = ceil(ni/nPerFig);
    
    for figI=1:nfig
        figure;
        
        theseIs = ((figI-1)*nPerFig+1):(figI*nPerFig);
        theseIs = theseIs(theseIs<=ni);
        figIs = subL.number(theseIs);
        origNs = subL.originalIndex(theseIs);
        for ii=1:length(theseIs)
            [ri,ci] = ind2sub([nrow ncol], ii);
            subplot('position', squeeze(subplotPositions(ri, ci, :)));
            %subplot(nrow,ncol,ii);
            imshow(objectImages(:,:,figIs(ii)),[0 255]);
            title(sprintf('%s %i: %s (%i)', categories{catI},  theseIs(ii), subL.label{theseIs(ii)}, origNs(ii)));
        end
        set(gcf,'units','centimeters','pos',[5 5 60 40]);
        saveas(gcf,fullfile(figDir, sprintf('%sIms%i.png', categories{catI},figI)));
    end
end

save(imgFile, 'objectImages','objectLabels', 'nPerCat','opts','origImages');

