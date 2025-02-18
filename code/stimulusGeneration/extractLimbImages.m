% Test adpat Alex's script for Limb images
clear; close all;

global img iter

%% extract object pictures from the KNK images

%whether to start from scratch, or load in work you already started
startFromScratch = true;

%stimDir = '/Users/alexlw/Dropbox/PROJECTS/stimulusImages/stimsFromBaoTsao2020';
stimDir = '/Volumes/GoogleDrive/My Drive/Projects/Intervention/Localizer/Limb_KNK_BG127';

finalDir = fullfile(catLoc_Base, 'stimulusGeneration');

%figDir = fullfile(finalDir, 'objectImageGrids');
figDir = fullfile(finalDir, 'limbImageGrids');

imgFile = fullfile(finalDir, 'limbImages.mat');

if startFromScratch
    myList = readtable(fullfile(stimDir, 'limbImageList.xlsx'));
    fileNames = myList.fileName;
  
    numImages = size(myList,1);
    categories = unique(myList.category);
    nCats = numel(categories);
    nPerCat = zeros(1,nCats);
    
    
    opts.oldBG = 128;%255
    opts.newBG = NaN;
    opts.doFeather = true;
    opts.featherTargetVal = 161;
    
    opts.rescaleIntensities = true;
    
else
%     load(imgFile, 'objectImages','objectLabels', 'nPerCat','opts','origImages');
%     numImages = size(objectLabels,1);
%     categories = unique(objectLabels.category);
%     nCats = numel(categories);
end



%% set background to NaN
     
for id = 1:numel(fileNames)
    %try to save time by automatically starting from the 4 corners
    curFileName = fullfile(stimDir,[fileNames{id} '.jpg']);
    curImage = imread(curFileName);
    %img = replaceImageBackground(objectImages(:,:,id), opts.oldBG, opts.newBG, opts.doFeather, opts.featherTargetVal);
    img = replaceImageBackground(curImage, opts.oldBG, opts.newBG, opts.doFeather, opts.featherTargetVal);
    
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
    %img = imresize(img, [600, 600]);
    objectImages(:,:,oi) = img;
end
    
%% hand edit 
figpos = [2061         134        1752        1308];

needsEdit = [950];
for ei=1:length(needsEdit)
    figure(6); clf; 
    id = find(objectLabels.originalIndex==needsEdit(ei));    
    objImg = objectImages(:,:,id); 
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
    
    objectImages(:,:,id) = newImg;
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

