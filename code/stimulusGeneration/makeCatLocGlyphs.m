function glyphs = makeCatLocGlyphs(targetDisplay, nowDisplay, imgDir)

params = catLoc_Params;
t = params.text;
nFonts = length(t.fontNames);

% Pseudoscloan asci codes, for each letter
lowComplexityASCIIs = 97:122;
hiComplexityASCIIs = 193:218;
mixedComplexASCIIs = zeros(size(lowComplexityASCIIs));
mixedComplexASCIIs(2:2:end) = lowComplexityASCIIs(2:2:end);
mixedComplexASCIIs(1:2:end) = hiComplexityASCIIs(1:2:end);


%ASCI codes for regular alphaget
lowerCaseASCIIs = 97:122;
upperCaseASCIIs = 65:90;


%set asci codes into a big matrix with one row for each font
ascis = NaN(nFonts, 26);
ascis(strcmp(t.fontNames, 'Courier New'), :)   = lowerCaseASCIIs;
ascis(strcmp(t.fontNames, 'BACS2'), :)         = lowerCaseASCIIs;
ascis(strcmp(t.fontNames, 'Sloan'), :)         = upperCaseASCIIs;
%ascis(strcmp(t.fontNames, 'PseudoSloanLo'), :) = lowComplexityASCIIs;
%ascis(strcmp(t.fontNames, 'PseudoSloanHi'), :) = hiComplexityASCIIs;
%starting 2022, we actually want to use just 26 pseudosloan letters, half
%from the low-complexity and half from the high-complexity case. Then all the fonts have the same number of unique characters. 
% This alsoavoids the one odd pseudosloan letter that on the windows laptop is just a
%black outline with white inside. 
ascis(strcmp(t.fontNames, 'PseudoSloan'), :) = mixedComplexASCIIs;

nLetters = size(ascis,2);

lowerAlphabet = char(lowerCaseASCIIs);
xI = find(lowerAlphabet=='x');

%% open screen
%set pixels per degree for the screen to be used
targetScr = getDisplayParameters(targetDisplay); %this is called targetScr because may differ from the screen being used right now
pixPerDeg = targetScr.ppd;

scr = getDisplayParameters(nowDisplay);
scr.white = [255 255 255];
scr.black = [0 0 0];

bgLum = params.bgLum;

bgColor = scr.white*bgLum;

rectToOpen = [];
numBuffers = 2;
stereoMode = 0;
if IsWin
    multiSample = [];
else
    multiSample = 4;
end
colDept = []; %default

if scr.useRetinaDisplay
    PsychImaging('PrepareConfiguration');
    PsychImaging('AddTask', 'General', 'UseRetinaResolution');
    retinaParam = kPsychNeedRetinaResolution;
else
    retinaParam = [];
end

% get rid of PsychtoolBox Welcome screen
Screen('Preference', 'VisualDebugLevel',3);

scr.allScreens = Screen('Screens');
scr.expScreen  = max(scr.allScreens);

%Skip sync tests? Should only do that when necessary
if scr.skipSyncTests
    Screen('Preference', 'SkipSyncTests',1);
end

[scr.main,scr.rect] = Screen('OpenWindow',scr.expScreen,bgColor,rectToOpen,colDept,numBuffers,stereoMode,multiSample,retinaParam);

%HIGH-QUALITY TEXT RENDERED IS NOT WORKING ON THE WINDOWS COMPUTER
if IsWin
    Screen('Preference', 'TextRenderer', 0); %0=fast but no anti-aliasing; 1=high-quality slower, 2=FTGL (whatever that is)
else
    Screen('Preference', 'TextRenderer', 1); %0=fast but no anti-aliasing; 1=high-quality slower, 2=FTGL (whatever that is)
end
Screen('Preference','TextAntiAliasing',t.antiAlias);
Screen('Preference', 'TextAlphaBlending', 1)

[scr.xres, scr.yres]    = Screen('WindowSize', scr.main);
[scr.centerX, scr.centerY] = WindowCenter(scr.main);



%% parameters for createLetterTextures

%2 font sizes
%2 spacings
%o.alphabet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
o.borderLetter = '';
o.readAlphabetFromDisk=0;
o.targetSizeIsHeight = 1;
o.targetHeightOverWidth = 1;
o.targetFontHeightOverNominalPtSize=1;
o.targetFontNumber=[];
o.printSizeAndSpacing = true;
o.showLineOfLetters = true;
o.contrast = 1;

%Y position is baseline?
% on windows, this doesnt work for pseudosloan
if IsWin
    o.yPositionIsBaseline = 0;
else
    o.yPositionIsBaseline = 1;
end

%% loop through fonts and create letter images for each font in each size
nSizes = t.nSizes;
fontSizePoints = NaN(nFonts, nSizes);
letterImgs = cell(nFonts, nSizes);
letterImgSizes = zeros(nFonts, nSizes, nLetters, 2);
letterTightSizes = zeros(nFonts, nSizes, nLetters, 2);
actualXHeightPx  = zeros(nFonts, nSizes);
actualXWidthPx = zeros(nFonts, nSizes);
monospacePixelsToAdd = zeros(nFonts, nSizes);
meanLetterTightWid = zeros(nFonts, nSizes);
whiteSpacePx = zeros(nFonts, nSizes);
usedFontNames = cell(nFonts, 1);
for fi = 1:nFonts
    o.targetFont = t.targetFonts{fi};

    if strcmp(o.targetFont, 'PseudoSloan') && IsWin
        o.yPositionIsBaseline = 0;
    else
        o.yPositionIsBaseline = 1;
    end
    o.alphabet = char(ascis(fi,:));
    baseX = o.alphabet(xI);

    oldFontName = Screen('TextFont',scr.main,o.targetFont);
    %call again to just check the font name the system reports
    usedFontNames{fi} = Screen('TextFont',scr.main,o.targetFont);
    if ~strcmp(usedFontNames{fi}, t.targetFonts{fi})
        error('Couldn''t set font %s correctly', t.fontNames{fi});
    end

    %ttext style: 0=normal,1=bold,2=italic,4=underline,8=outline,32=condense,64=extend.
    Screen('TextStyle',scr.main,0);

    for si=1:nSizes
        %set font size
        % for PseudoSloan, just use the same size as for sloan
        if any(strcmp(t.fontNames{fi}, {'PseudoSloanLo','PseudoSloanHi'}))
            fontSize = fontSizePoints(strcmp(t.fontNames, 'Sloan'), si);
        else
            tooSmall = true;
            fontSize = 10;
            while tooSmall
                fontSize = fontSize+1;
                %old way: use TextBounds. doesnt work for pseudosloan,
                %oddly
                %Screen('TextSize',scr.main,fontSize);
                %bounds = Screen('TextBounds',scr.main,baseX,o.yPositionIsBaseline);
                %heightPix = bounds(4);

                %new way: use createLetterTextures and just get the size
                o.targetPix  = fontSize;
                o.alphabet = char(ascis(fi,xI));
                xStruct = CreateLetterTextures_AW(1,o,scr.main);

                xImg = xStruct(1).image;
                fullHeightPx = size(xImg,1);

                letterBounds = ImageBoundsAW(xImg, 255); % bgColor(1));
                heightPix = letterBounds(4)-letterBounds(2) + 1;

                heightDeg = heightPix/pixPerDeg;
                tooSmall = heightDeg < t.unqXHeightsDeg(si);
            end
        end
        fprintf(1,'\nfor Font %s, size %i, final height is %i pixels\n',o.targetFont, si, heightPix)
        fontSizePoints(fi,si) = fontSize;
        o.targetPix = fontSize;
        o.alphabet = char(ascis(fi,:));

        %create letter images:
        letterStruct = CreateLetterTextures_AW(1,o,scr.main);

        %Pull out the letterimages, and their sizes
        theseLetterImgs = cell(1,nLetters);
        for li=1:nLetters
            theseLetterImgs{li} = letterStruct(li).image;
            letterImgSizes(fi,si,li,:) = [size(letterStruct(li).image,1) size(letterStruct(li).image,2)];

            %Deal with a strange problem with courier & BACS fonts on
            %windows: black pixels in the very first row are missing 
            if IsWin && any(strcmp(o.targetFont, {'Courier New','BACS2serif'}))
                toprow = theseLetterImgs{li}(1,:);
                scndrow = theseLetterImgs{li}(2,:);
                if all(toprow==255) && ~all(scndrow==255)
                    %copy the second row into the first:
                  theseLetterImgs{li}(1,:) = theseLetterImgs{li}(2,:);  
                end
                if li==1, fprintf(1,'\nFIXING MISSING TOP ROW FOR FONT %s\n', o.targetFont); end
            end
            letterBounds = ImageBoundsAW(theseLetterImgs{li}, 255); % bgColor(1));
            letterWidthPx = letterBounds(3)-letterBounds(1) + 1;
            letterHeightPx = letterBounds(4)-letterBounds(2) + 1;
            letterTightSizes(fi,si,li,:) = [letterHeightPx letterWidthPx];
        end
        letterImgs{fi,si} = theseLetterImgs;
        actualXHeightPx(fi,si) = letterTightSizes(fi, si, o.alphabet==baseX,1);
        actualXWidthPx(fi,si) = letterTightSizes(fi, si, o.alphabet==baseX,2);
        letterImgWidth = unique(squeeze(letterImgSizes(fi,si,:,2)));
        %check that all letter images are thes ame width:
        if length(letterImgWidth)~=1
            keyboard
        end

        %determine spacing parameters
        %for monospace
        defaultSpacingPx = floor(actualXWidthPx(fi,si)*1.16);
        monospacePixelsToAdd(fi,si) = defaultSpacingPx - letterImgWidth;

        %for not monospace
        meanLetterTightWid(fi, si) = mean(squeeze(letterTightSizes(fi,si, :, 2)));
        %according to Tony Norcia, one "bar" is one fifth of letter size,
        %and spacing can bet set to some fixed number of bars
        whiteSpacePx(fi, si) = round(meanLetterTightWid(fi, si)*t.whiteSpaceBarWidth/5);

    end
end

%% deal with a strange problem that sometimes the high- and
%low-complexity PseudoSloan fonts don't have exactly the same letter image heights
fi0 = find(strcmp(t.fontNames, 'Sloan'));
fi1 = find(strcmp(t.fontNames, 'PseudoSloan'));

%fi1 = find(strcmp(t.fontNames, 'PseudoSloanLo'));
%fi2 = find(strcmp(t.fontNames, 'PseudoSloanHi'));
for si=1:nSizes
    theseHeights = squeeze(letterImgSizes([fi0 fi1],si,:,1));
    uHeights = unique(theseHeights);
    if length(uHeights)>1
        %add extra pixels to make all these letters be of the same height
        goalHeight = max(uHeights);
        for fontI=[fi0 fi1] % fi2]
            fontHs = squeeze(letterImgSizes(fontI,si,:,1));
            theseLetters =  letterImgs{fontI,si};


            needsPad = find(fontHs<goalHeight)';
            pixToAdd = goalHeight-fontHs;
            %if any(pixToAdd>1), keyboard, end
            if ~isempty(needsPad)
                for leti = needsPad
                    oldLettr = theseLetters{leti};
                    theseLetters{leti} = cat(1, bgColor(1) * ones(pixToAdd(leti), size(oldLettr,2), 3), oldLettr);
                end
            end
            letterImgs{fontI,si} = theseLetters;
        end
    end
end

glyphs.images = letterImgs;
glyphs.imgSizes = letterImgSizes;
glyphs.tightSizes = letterTightSizes;
glyphs.meanLetterTightWid = meanLetterTightWid;
glyphs.actualXHeightPx = actualXHeightPx;
glyphs.actualXWidthPx = actualXWidthPx;
glyphs.usedFontNames = usedFontNames;
glyphs.monospacePixelsToAdd = monospacePixelsToAdd;
glyphs.whiteSpacePx = whiteSpacePx;
glyphs.ascis = ascis;
glyphs.exptParams = params;
glyphs.targetDisplayName = targetDisplay;
glyphs.targetScr = targetScr;
glyphs.usedDisplayName = nowDisplay;
glyphs.usedScr = scr;


resFile = fullfile(imgDir, sprintf('glyphs_%s.mat', targetDisplay));
save(resFile, 'glyphs');

sca;

