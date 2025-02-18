function [letterStruct,alphabetBounds]=CreateLetterTextures_AW(condition,o,window)
% [letterStruct,alphabetBounds]=CreateLetterTextures(condition,o,window)
% Create textures, one per letter in o.alphabet plus o.borderLetter.
% Returns array "letterStruct" with one struct element per letter, plus
% bounding box "alphabetBounds" that will hold any letter.  The font is o.targetFont.
%
% The font is rendered by Screen DrawText
% to create a texture for each desired letter. The font's TextSize is
% computed to yield the desired o.targetPix size in the direction specified
% by o.targetSizeIsHeight. However, if
% o.targetFontHeightOverNominalPtSize==nan then the TextSize is set equal
% to o.targetPix.
%
%
% The argument "condition" is used only for diagnostic printout.
%
% HISTORY
% Feb 22, 2017 - Alex White (ALW) cloned this from Pelli's github
% Feb 22, 2017 - ALW added functionality to also return image of each word,
% as a matrix of pixel values. That's now in letterStruct(i).image. Also
% returns final pixel size of font, in letterStruct(i).sizePix;
% Aug 15 2020 - ALW removed the readAlphabetFromDisk functionality, because
% that was quite speficic to Dennis's code.

tryFixUpperCutoff = IsWin;

if ~isfinite(o.targetHeightOverWidth)
    o.targetHeightOverWidth=1;
end
letters=[o.alphabet o.borderLetter];
for i=1:length(letters)
    letterStruct(i).letter=letters(i);
end
% if o.targetSizeIsHeight
%    canvasRect=[0 0 o.targetPix o.targetPix];
% else
canvasRect=[0 0 o.targetPix o.targetPix]*o.targetHeightOverWidth;
% end


%set colors
black = 0;
white = 255;

if o.contrast==1
    textColr = black;
else
    textColr = uint8(white+(double(black)-white)*o.contrast);
end

% open a scratch window to draw all the letters in to get size 
scratchWindow=Screen('OpenOffscreenWindow',window,[],canvasRect*4,8,0);

%set font 
if ~isempty(o.targetFontNumber)
    Screen('TextFont',scratchWindow,o.targetFontNumber);
    [~,number]=Screen('TextFont',scratchWindow);
    assert(number==o.targetFontNumber);
else
    Screen('TextFont',scratchWindow,o.targetFont);
    font=Screen('TextFont',scratchWindow);
    assert(streq(font,o.targetFont));
end

%set size
if o.targetSizeIsHeight
    sizePix=round(o.targetPix/o.targetFontHeightOverNominalPtSize);
else
    sizePix=round(o.targetPix*o.targetHeightOverWidth/o.targetFontHeightOverNominalPtSize);
end

if ~isfinite(sizePix)
    sizePix=o.targetPix;
end

Screen('TextSize',scratchWindow,sizePix);

%loop through all letters to find smallest bounds that encompass all of
%them 
for i=1:length(letters)
    lettersInCells{i}=letters(i);
    bounds=TextBoundsNew(scratchWindow, letters(i), o.yPositionIsBaseline);

    %TRY TO FIX MISSING PIXEL AT TOP
    if tryFixUpperCutoff
        bounds = GrowRect(bounds, 0, 1);
        %bounds(RectBottom) = bounds(RectBottom)+1;
    end
    
    if o.showLineOfLetters
        b=Screen('TextBounds',scratchWindow, letters(i));
        fprintf('%d: %s "%c" textSize %d, TextBounds [%d %d %d %d] width x height %d x %d, Screen TextBounds %.0f x %.0f\n', ...
            condition,o.targetFont,letters(i),sizePix,round(bounds),RectWidth(bounds),RectHeight(bounds),RectWidth(b),RectHeight(b));
    end
    letterStruct(i).bounds=bounds;
    if i==1
        alphabetBounds=bounds;
    else
        alphabetBounds=UnionRect(alphabetBounds,bounds);
    end
end
bounds = alphabetBounds;

if o.printSizeAndSpacing
    fprintf('%d: sizePix %d, first letter "%c", height %d, width %d.\n',condition,sizePix,letters(1),RectHeight(letterStruct(1).bounds),RectWidth(letterStruct(1).bounds));
end
assert(RectHeight(bounds)>0);

%find center position for each letter: 
for i=1:length(letters)
    letterStruct(i).width=RectWidth(letterStruct(i).bounds);
    desiredBounds=CenterRect(letterStruct(i).bounds,bounds);
    letterStruct(i).dx=desiredBounds(1)-letterStruct(i).bounds(1);
end
Screen('Close',scratchWindow);

%set size of "canvas" into which we'll draw this: 
canvasRect=bounds;
canvasRect=OffsetRect(canvasRect,-canvasRect(1),-canvasRect(2));

%TRY TO FIX MISSING PIXEL AT TOP
if tryFixUpperCutoff
%canvasRect = GrowRect(canvasRect, 0, 1);
end

if o.printSizeAndSpacing
    fprintf('%d: textSize %.0f, "%s" height %.0f, width %.0f\n',condition,sizePix,letters,RectHeight(bounds),RectWidth(bounds));
end
% Create texture for each letter
for i=1:length(letters)
    %create offscreen window into which to draw this letter 
    [letterStruct(i).texture, letterStruct(i).rect] = Screen('OpenOffscreenWindow', window, [], canvasRect); %,8,0);
  
    %set font
    if ~isempty(o.targetFontNumber)
        Screen('TextFont',letterStruct(i).texture,o.targetFontNumber);
        [font,number]=Screen('TextFont',letterStruct(i).texture);
        assert(number==o.targetFontNumber);
    else
        Screen('TextFont',letterStruct(i).texture,o.targetFont);
        font=Screen('TextFont',letterStruct(i).texture);
        assert(streq(font,o.targetFont));
    end

    %set size 
    Screen('TextSize',letterStruct(i).texture,sizePix);

    %make white background 
    Screen('FillRect',letterStruct(i).texture,white);

    %draw letter
    xpos = -bounds(1)+letterStruct(i).dx;
    ypos = -bounds(2);
    %TRY TO FIX MISSING PIXEL AT TOP
    if tryFixUpperCutoff
        ypos = ypos+1;
    end
    Screen('DrawText',letterStruct(i).texture, letters(i), xpos, ypos, textColr, white, o.yPositionIsBaseline);


    %CAPTURE IMAGE!
    letterStruct(i).image = double(Screen('GetImage',letterStruct(i).texture,[],[],0,3));

    if tryFixUpperCutoff
        %remove the extra pixel at top
        letterStruct(i).image = letterStruct(i).image(2:end, :, :);
    end
    letterStruct(i).sizePix = sizePix;

end


