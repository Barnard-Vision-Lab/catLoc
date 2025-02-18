%% This is the script to make all stimuli for catLoc experiment. 
% Before running this script you should:
% 
% - set various parameters about the stimuli in the catLoc_Params
% function (which is invoked by each of the functions below). This
% determines what categories of stimuli you want, and which screen
% positions, how big etc. 
%
% - Decide what particular words, pseudowords, and consonant strings you want in the
% "text" cateogries. Those are all in CatLocTextSet.csv. 
% 
% - Make sure your display parameters are set in the getDisplayParameters
% function. You need to specify a name for the display your subjects see,
% its size, resolution, distance, etc. That is crucial for getting stimulus
% sizes correct. You can also run this script on another display, but then
% you also have to have an entry for that in getDisplayParameters. 
% 
% - add the whole catLoc/code/ directory to your path. 
% 
% Other notes:
% - the faces, object, and limbs are loaded as images stored in .mat file:
%  faceImages.mat, objectImages.mat, and limbImages.mat. **These were
%  kindly provided by Kalanit Grill-Spector.** 
%
% - The images are saved in catLoc/stimuli/displayName/ as .mat files.
%   These .mat files are then loaded in when you run the experiment, creating
%   "textures" that are put on the screen at the right moment. 
% 
% - this code also prints out 'StimulusSizeSummary.txt', to the image
% directory. This is useful for reporting stimulus sizes in a manuscript. 
%
% - You can also save PNG files of each image frame. If you want do to
%  that, within each of the 4 main functions used below (to make text,
%  face, limb and object image), turn on the "showImages" variable to true. 
% 
% - Currently, the code assumes that in each stimulus display there are
%  three items all of the same category, one small in the fovea, one larger
%  one to the left, and one larger one to the right. But you can also have
%  just 1 foveal stimulus, or one stimulus at a time at any of the 3
%  positions. THAT WOULD TAKE SOME ADDITIONAL CODING: 
%  first by changing a paramter in the Params function: params.stimLocs.n
%  could be 1 instead of 3. Then below in this script, to make the images of each of 
%  the object categories, you'd need to call the Unilateral version of the function, e.g., 
%  makeCatLocTextImages_Unilateral, instead of makeCatLocTextImages. 
% 
% Written by: Alex White, Barnard College 

clear; close all; 

%% Set the screen: 

%the display you want to actually run the experiment with: 
targetDisplay = 'JuneProjector'; 
% the display you're going to use now to generate the stimuli (doesn't have
% to be the same).
nowDisplay = 'Lenovo';

%% Set paths: 
projDir = fileparts(catLoc_Base);
params = catLoc_Params;
nPos = params.stimLocs.n;
if nPos==1
    imgDir = fullfile(projDir, 'stimuli', [targetDisplay '_1Loc']); 
else
    imgDir = fullfile(projDir, 'stimuli', targetDisplay);
end
if ~isfolder(imgDir), mkdir(imgDir); end

%% Make individual letters (aka glyphs) for the text stimuli: 
try
    glyphs = makeCatLocGlyphs(targetDisplay, nowDisplay, imgDir);  
catch me
    sca;
    keyboard
end

% % draw them: 
t = params.text;
s= 2; %size 
for f=1:length(t.targetFonts)
    figure; nRows = 2; nCols = 13;
    for l = 1:26
        subplot(nRows, nCols, l);
        imshow(glyphs.images{f,s}{l}/255);
        if l==1, title(sprintf('%s (%s)', t.fontNames{f}, glyphs.usedFontNames{f})); end
    end
end

%% Make images of text categories: 
ts = makeCatLocTextImages(targetDisplay, imgDir);

%% Make images of face cateogries: 
fs = makeCatLocFaceImages(targetDisplay, imgDir);

%% Make images of limb categories: 
ls = makeCatLocLimbImages(targetDisplay, imgDir);

%% Make images of object categories 
%for now, no objects in the experiment (see the Params function)

%os  = makeCatLocObjectImages(targetDisplay, imgDir);


%% print out some stats

f = fopen(fullfile(imgDir, 'StimulusSizeSummary.txt'), 'w');

nPos = length(ls.valsByIndex.position);
fprintf(f,'\nPosition:');
for pi=1:nPos
    fprintf(f,'\t\t%i', pi);
end

allMeanStimSz = [];
allMinStimSz = [];
allMaxStimSz = [];

allMeanStimExtent = [];
allMinStimExtent = [];
allMaxStimExtent = [];

allCatgrs = {};

for stimType = [1 2 4] %OBJECTS LEFT OUT HERE (3)
    switch stimType
        case 1 %text

            meanStimSz = ts.meanWordSizeDeg;
            minStimSz = ts.minWordSizeDeg;
            maxStimSz = ts.maxWordSizeDeg;
            
            meanStimExtent =ts.meanWordsExtentDeg;
            minStimExtent = ts.minWordsExtentDeg;
            maxStimExtent = ts.maxWordsExtentDeg;
            catgrs = ts.valsByIndex.category;
        case 2 %faces
                       
            meanStimSz = fs.meanFaceSizeDeg;
            minStimSz = fs.minFaceSizeDeg;
            maxStimSz = fs.maxFaceSizeDeg;
            
            meanStimExtent =fs.meanFacesExtentDeg;
            minStimExtent = fs.minFacesExtentDeg;
            maxStimExtent = fs.maxFacesExtentDeg;

            catgrs = fs.valsByIndex.category;
        case 3 %objects
            meanStimSz = os.meanObjectSizeDeg;
            minStimSz = os.minObjectSizeDeg;
            maxStimSz = os.maxObjectSizeDeg;
            
            
            meanStimExtent = os.meanObjectsExtentDeg;
            minStimExtent = os.minObjectsExtentDeg;
            maxStimExtent = os.maxObjectsExtentDeg;
            
            catgrs = os.valsByIndex.category;
            
            if length(catgrs)==1
                %reshape these things so they have a 1st dim for category
                meanStimSz = reshape(meanStimSz, [1 size(meanStimSz)]);
                minStimSz = reshape(minStimSz, [1 size(minStimSz)]);
                maxStimSz = reshape(maxStimSz, [1 size(maxStimSz)]);
                meanStimExtent = reshape(meanStimExtent, [1 size(meanStimExtent)]);
                minStimExtent = reshape(minStimExtent, [1 size(minStimExtent)]);
                maxStimExtent = reshape(maxStimExtent, [1 size(maxStimExtent)]);
            end
            
        case 4 %limbs
            
            meanStimSz = ls.meanLimbSizeDeg;
            minStimSz = ls.minLimbSizeDeg;
            maxStimSz = ls.maxLimbSizeDeg;
            
            
            meanStimExtent = ls.meanLimbsExtentDeg;
            minStimExtent =ls.minLimbsExtentDeg;
            maxStimExtent = ls.maxLimbsExtentDeg;

            catgrs = ls.valsByIndex.category;
                        
    end
    
    allMeanStimSz = cat(1, allMeanStimSz, meanStimSz);
    allMinStimSz = cat(1, allMinStimSz, minStimSz);
    allMaxStimSz = cat(1, allMaxStimSz, maxStimSz);
    allMeanStimExtent = cat(1, allMeanStimExtent, meanStimExtent);
    allMinStimExtent = cat(1, allMinStimExtent, minStimExtent);
    allMaxStimExtent = cat(1, allMaxStimExtent, maxStimExtent);
    
    allCatgrs = cat(2,allCatgrs,catgrs);
end

%print stats on individual stimuli
for widHei = 1:2
    if widHei==1
        fprintf(f,'\n\nIndividual stimulus WIDTHS, for each position\n');
    else
        fprintf(f,'\n\nIndividual stimulus HEIGHTS, for each position\n');
    end
    
    fprintf(f,'\n');
    for ci=1:length(allCatgrs)
        fprintf(f,'\n%s', allCatgrs{ci});
        for pi=1:nPos
            fprintf(f,'\t\t%.2f [%.2f %.2f]', allMeanStimSz(ci, pi, widHei), allMinStimSz(ci, pi, widHei), allMaxStimSz(ci, pi, widHei));
        end
    end
end

%print stats on the extent on all the stimuli in each whole-screen images
for widHei = 1:2
    if widHei==1
        fprintf(f,'\n\nEntire image WIDTHS\n');
    else
        fprintf(f,'\n\nEntire image HEIGHTS\n');
    end
    
    fprintf(f,'\n');
    for ci=1:length(allCatgrs)
        fprintf(f,'\n%s', allCatgrs{ci});
        fprintf(f,'\t\t%.2f [%.2f %.2f]', allMeanStimExtent(ci, widHei), allMinStimExtent(ci, widHei), allMaxStimExtent(ci, widHei));
    end
end



