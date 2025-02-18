function textStims = makeCatLocTextImages_Unilateral(displayName, imgDir)

params = catLoc_Params;
nPos = params.stimLocs.n;

showImages = false;
if showImages
    pngDir = fullfile(imgDir, 'pngs');
    if ~isfolder(pngDir), mkdir(pngDir); end
end
%% load glyphs and params

resFile = fullfile(imgDir, sprintf('glyphs_%s.mat', displayName));
load(resFile, 'glyphs');

scr = getDisplayParameters(displayName);
scr.xres = scr.goalResolution(1);
scr.yres = scr.goalResolution(2);
scr.centerX = round(scr.xres/2);
scr.centerY = round(scr.yres/2);
scr.white = [255 255 255];
scr.black = [0 0 0];

if scr.ppd ~= glyphs.targetScr.ppd
    error('Mismatch in this requested display''s pixels per degree and that recorded in the pre-made glyphs');
end
pixPerDeg = scr.ppd;

t1 = glyphs.exptParams.text;

t = params.text;

%check if params have changed since glyphs were made
[fs1, fs2] = comp_struct(t1, t);
if ~isempty(fs1) || ~isempty(fs2)
    error('Text params have changed. Re-create glyphs');
end

nFonts = length(t.fontNames);

%% load lexicon
L = readtable(t.listFile);

%% assign letter strings to images
allCats = params.textCategories;
catFonts = params.textCategoryFonts;
nCat = length(allCats);
nImg = params.org.totalImgPerCategory + params.org.practiceImgPerCategory; %include some unique images for practice
stringIs = NaN(nCat, nImg);

for ci=1:nCat
    %organized by "word types", the category name that excludes the font.
    %the font is appended to the word type in params.textCategories
    switch params.textCategoryWordTypes{ci}
        %assign word indices just for the foveal stimulus:
        case {'highFreqWords'}
            %choose high-freq real words
            is = find(strcmp(L.category,'real') & strcmp(L.frequencyBin, 'high'));
            %take the N highest freq words
            [~,sortIs] = sort(L.FREQ(is),'descend');

            %if there are multiple fonts of this type:
            are2Cats = ~isempty(intersect(params.textCategories, {'highFreqWordsSloan', 'highFreqWordsCourier'}));
            if are2Cats
                if strcmp(params.textCategories{ci}, 'highFreqWordsSloan')
                    theseIs = sortIs(1:2:(nImg*2));
                else
                    theseIs = sortIs(2:2:(nImg*2));
                end
            else
                theseIs = sortIs(1:nImg);
            end

        case {'lowFreqWords'}
            %choose
            is = find(strcmp(L.category,'real') & strcmp(L.frequencyBin, 'low'));
            %take the N LOWEST freq words
            [~,sortIs] = sort(L.FREQ(is),'ascend');

            %now we have two categories with low freq words (either one
            %with fovea only, one with 2 postns, or one in sloan and one in
            %courier).
            %so lets' take the even numbered words for one category, and
            %the odd for the other
            are2Cats = ~isempty(intersect(params.textCategories, {'lowFreqWordsSloan', 'lowFreqWordsCourier', 'lowFreqWordsFoveaSloan'} ));
            if are2Cats
                if strcmp(params.textCategories{ci}, 'lowFreqWords') || strcmp(params.textCategories{ci}, 'lowFreqWordsSloan')
                    theseIs = sortIs(1:2:(nImg*2));
                else
                    theseIs = sortIs(2:2:(nImg*2));
                end
            else
                theseIs = sortIs(1:nImg);
            end
        case {'pseudowords'}
            is = find(strcmp(L.category,'pseudo'));
            %now we have two categories with pseudowords, one in courier
            %and one in sloan.
            %so lets' take the even numbered words for one category, and
            %the odd for the other
            if strcmp(params.textCategories{ci}, 'pseudowordsSloan')
                is = is(1:2:end);
            elseif strcmp(params.textCategories{ci}, 'pseudowordsCourier')
                is = is(2:2:end);
            end
            sortIs = randperm(length(is));
            theseIs = sortIs(1:nImg);

        case 'consonants'
            is = find(strcmp(L.category,'consonants'));
            sortIs = randperm(length(is));
            are2Cats = ~isempty(intersect(params.textCategories, {'consonantsSloan', 'consonantsCourier'} ));
            if are2Cats
                if strcmp(params.textCategories{ci}, 'consonantsSloan')
                    theseIs = sortIs(1:2:(nImg*2));
                else
                    theseIs = sortIs(2:2:(nImg*2));
                end
            else
                theseIs = sortIs(1:nImg);
            end
    end

    stringIs(ci, :) = is(theseIs);

end


%% add indices for pseudofont images
%they should be matched to real text images in the corresponding real fonts
for pcf = 1:length(params.pseudofontCategories)
    switch params.pseudofontCategories{pcf}
        case 'PseudoCourier'
            matchCatIs = find(strcmp(params.textCategoryFonts, 'Courier'));
            thisFont ='BACS2';
        case 'PseudoSloan'
            matchCatIs = find(strcmp(params.textCategoryFonts, 'Sloan'));
            thisFont = 'PseudoSloan';

    end
    for mci=matchCatIs
        pseudofontStringIs = stringIs(mci, :);
        %add these stringIs:
        stringIs = cat(1, stringIs, pseudofontStringIs);
        %add this category:
        allCats = cat(2, allCats, {[params.pseudofontCategories{pcf} '_' params.textCategoryWordTypes{mci}]});
        catFonts = cat(2, catFonts, thisFont);
    end
end

nCat =  length(allCats);
valsByIndex.category = allCats;
valsByIndex.stimNum = 1:nImg;

%% set word center positions in pixels
ctrXs = round(scr.centerX + pixPerDeg*params.stimLocs.x);
ctrYs = round(scr.centerY + pixPerDeg*params.stimLocs.y);

imgSize = [scr.yres scr.xres];

bgColor = round(scr.white*params.bgLum);

%% assemble images
lowerCaseASCIIs = 97:122;
lowerAlphabet = char(lowerCaseASCIIs);

wordSizePx     = NaN(nCat, nImg, nPos, 2);
wordsExtentPx = NaN(nCat,  nImg, 2);

for ci = 1:nCat
    thisFont = catFonts{ci};
    if strcmp(thisFont, 'Courier')
        thisFont = 'Courier New'; %thats what we actually mean
    end
    fontsToDo = find(strcmp(t.fontNames, thisFont));

    for ii = 1:nImg
        for fi = fontsToDo
            for pi = 1:nPos

                %only grayscale
                img = ones([imgSize 3])*bgColor(1);

                stringIndex = stringIs(ci,ii);

                thisXHeight = t.xHeightsDeg(pi);
                sizeI = find(t.unqXHeightsDeg==thisXHeight);


                fi1 = find(strcmp(t.fontNames, t.fontNames{fi}));
                alphabet = char(glyphs.ascis(fi1,:));
                if isempty(alphabet), keyboard; end
                theseLetters = glyphs.images{fi,sizeI};

                %Set spacing
                if t.monospace(fi1)
                    %if need to add some pixels on the right side of each letter to
                    %get standard spacing
                    if glyphs.monospacePixelsToAdd(fi1, sizeI)>=0
                        trimParams.tightWidth = false; %whether to do do any trimming
                        trimParams.minBlankOnLeftForCut = inf; %min number of blank pixels on left side to trigger a cut
                        trimParams.blankOnLeftToCut = 0; %      number of blank pixels on left to cut (if any)
                        trimParams.minBlankOnRightForCut = inf; %don't cut
                        trimParams.blankOnRightToCut = 0;

                        padParams.right = glyphs.monospacePixelsToAdd(fi1, sizeI);
                        padParams.left  = 0;
                    else %if need to cut some pixels on the right to get standard spacing
                        trimParams.tightWidth = true; %whether to do do any trimming
                        trimParams.minBlankOnLeftForCut = inf; %min number of blank pixels on left side to trigger a cut
                        trimParams.blankOnLeftToCut = 0; %      number of blank pixels on left to cut (if any)
                        trimParams.minBlankOnRightForCut = abs(glyphs.monospacePixelsToAdd(fi1, sizeI)); %don't cut
                        trimParams.blankOnRightToCut = abs(glyphs.monospacePixelsToAdd(fi1, sizeI));

                        padParams.right = 0;
                        padParams.left  = 0;
                    end
                else

                    trimParams.tightWidth = true; %whether to do do any trimming
                    trimParams.minBlankOnLeftForCut = 0; %min number of blank pixels on left side to trigger a cut
                    trimParams.blankOnLeftToCut = inf; %      number of blank pixels on left to cut (if any)
                    trimParams.minBlankOnRightForCut = 0; %don't cut
                    trimParams.blankOnRightToCut = inf;

                    padParams.right = glyphs.whiteSpacePx(fi1,sizeI);
                    padParams.left  = 0;

                end

                %find indices of letters in the lower case alphabet
                [~,wordLetterIs] = ismember(L.STRING{stringIndex}, lowerAlphabet);

                theWord = alphabet(wordLetterIs);
                letterColrs = repmat(t.color,[length(theWord) 1]);

                %assemble
                try
                    wordImage = assembleWordImage(theWord, alphabet, theseLetters, letterColrs, bgColor(1), trimParams, padParams);
                catch
                    keyboard
                end
                %Crop the word image as tightly as possible... but only HORIZONTALLY. Leave space on the top and bottom, so the
                %baseline stays in the same vertical position for all words
                wordBounds = ImageBoundsAW(wordImage, bgColor(1));
                wordImage = wordImage(:, wordBounds(RectLeft):wordBounds(RectRight), :);

                wid = size(wordImage,2);
                hei = size(wordImage,1);


                startX = ctrXs(pi) - floor(wid/2);
                endX = ctrXs(pi) + ceil(wid/2) - 1;

                startY = ctrYs(pi) - floor(hei/2);
                endY = ctrYs(pi) + ceil(hei/2) - 1;

                img(startY:endY, startX:endX, :) = wordImage;

                %save this as the actual part of image occupied by words,
                %even vertically:
                wordSizePx(ci, ii, pi, :) = [wordBounds(RectRight)-wordBounds(RectLeft) wordBounds(RectBottom)-wordBounds(RectTop)];


                %find the bounds of all the text in the image
                imBounds = ImageBoundsAW(img, bgColor(1));
                wordsExtentPx(ci, ii, 1) = imBounds(3)-imBounds(1);
                wordsExtentPx(ci, ii, 2) = imBounds(4)-imBounds(2);

                if showImages
                    figure(1); clf;
                    imshow(img(:,:,1),[0 255]);

                    if ii<=params.org.totalImgPerCategory
                        if length(fontsToDo)>1
                            %imgFile = fullfile(pngDir, sprintf('%s_%s_%i.png', params.textCategories{ci}, t.fontNames{fi}, ii));
                        else
                            %Change in 2022: the category name icludes the font
                            %name, so that doesnt need to be added in again
                            imgFile = fullfile(pngDir, sprintf('%s_%i_side%i.png', allCats{ci},   ii, pi));
                        end
                    else
                        imgFile = fullfile(pngDir, sprintf('%s_%i_side_%i_PRAC.png', allCats{ci}, ii-params.org.totalImgPerCategory, pi));
                    end
                    saveas(gcf,imgFile);

                end

                if ii<=params.org.totalImgPerCategory
                  
                    imgFile = fullfile(imgDir, sprintf('%s_%i_side%i.mat', allCats{ci}, ii, pi));

                else %save the images over totalImgPerCategory as practice images
                    imgFile = fullfile(imgDir, sprintf('%s_%i_side%i_PRAC.mat', allCats{ci}, ii-params.org.totalImgPerCategory, pi));
                end

                save(imgFile, 'img');
            end
        end
    end
end

%separate out the practice images
pracStringIs = stringIs(:,(params.org.totalImgPerCategory+1):end);
stringIs = stringIs(:,1:params.org.totalImgPerCategory+1);

textStims.imageDir = imgDir;
textStims.targetScr = glyphs.targetScr;
textStims.expParams = params;
textStims.lexicon = L;
textStims.stringIs = stringIs;
textStims.practiceStringIs = pracStringIs;
textStims.valsByIndex = valsByIndex;
textStims.fonts = t.fontNames;
textStims.wordSizePx = wordSizePx;
textStims.minWordSizeDeg = squeeze(min(wordSizePx,[],2))/pixPerDeg;
textStims.maxWordSizeDeg = squeeze(max(wordSizePx,[],2))/pixPerDeg;
textStims.meanWordSizeDeg = squeeze(mean(wordSizePx,2))/pixPerDeg;
textStims.wordsExtentPx = wordsExtentPx;
textStims.meanWordsExtentDeg = squeeze(mean(wordsExtentPx,3))/pixPerDeg;
textStims.minWordsExtentDeg = squeeze(min(wordsExtentPx,[],3))/pixPerDeg;
textStims.maxWordsExtentDeg = squeeze(max(wordsExtentPx,[],3))/pixPerDeg;

resFile = fullfile(imgDir, sprintf('textStimParams_%s.mat', displayName));
save(resFile, 'textStims');

