%% script to make all stimuli for catLoc experiment
% To do:

clear; close all; 

%the display you want to actually run the experiment with: 
targetDisplay = 'JuneProjector'; 
% the dispaly you're going to use now to generate the stimuli 
nowDisplay = 'Lenovo';

projDir = fileparts(catLoc_Base);
imgDir = fullfile(projDir, 'stimuli_unilateral', targetDisplay);
if ~isfolder(imgDir), mkdir(imgDir); end


try
    glyphs = makeCatLocGlyphs(targetDisplay, nowDisplay, imgDir);  
catch me
    sca;
    keyboard
end


% % draw them: 
params = catLoc_Params;
t = params.text;
s= 1; %size 
for f=1:length(t.targetFonts)
    figure; nRows = 2; nCols = 13;
    for l = 1:26
        subplot(nRows, nCols, l);
        imshow(glyphs.images{f,s}{l}/255);
        if l==1, title(sprintf('%s (%s)', t.fontNames{f}, glyphs.usedFontNames{f})); end
    end
end

%%
ts = makeCatLocTextImages_Unilateral(targetDisplay, imgDir);

fs = makeCatLocFaceImages_Unilateral(targetDisplay, imgDir);

ls = makeCatLocLimbImages_Unilateral(targetDisplay, imgDir);

os = makeCatLocObjectImages_Unilateral(targetDisplay, imgDir);

%% print out some stats --doesn't quite work yet for unilateral version
f = fopen(fullfile(imgDir, 'StimulusSizeSummary.txt'), 'w');
% os does not have a field for position
% nPos = length(os.valsByIndex.position);
% fprintf(f,'\nPosition:');
% for pi=1:nPos
%     fprintf(f,'\t\t%i', pi);
% end

allMeanStimSz = [];
allMinStimSz = [];
allMaxStimSz = [];

allMeanStimExtent = [];
allMinStimExtent = [];
allMaxStimExtent = [];

allCatgrs = {};

for stimType = [1 2 4]
    switch stimType
        case 1
            meanStimSz = squeeze(nanmean(ts.meanWordSizeDeg, 1)); %average over categories
            minStimSz = squeeze(nanmean(ts.minWordSizeDeg, 1));
            maxStimSz = squeeze(nanmean(ts.maxWordSizeDeg, 1));
            
            meanStimExtent = squeeze(nanmean(ts.meanWordsExtentDeg,1));
            minStimExtent = squeeze(nanmean(ts.minWordsExtentDeg,1));
            maxStimExtent = squeeze(nanmean(ts.maxWordsExtentDeg,1));
            
            catgrs = ts.fonts;
            %catgrs = cat(2,ts.fonts, ts.valsByIndex.category(end)); %add in the last category which should be lowFreqWordsFoveaSloan
            
        case 2
            meanStimSz = fs.meanFaceSizeDeg;
            minStimSz = fs.minFaceSizeDeg;
            maxStimSz = fs.maxFaceSizeDeg;
            
            meanStimExtent = fs.meanFacesExtentDeg;
            minStimExtent = fs.minFacesExtentDeg;
            maxStimExtent = fs.maxFacesExtentDeg;
            
            catgrs = fs.valsByIndex.category;
            
            
        case 3
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
            
        case 4
            keyboard
                        
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
        fprintf(f,'\t\t%.2f [%.2f %.2f]', allMeanStimSz(ci, widHei), allMinStimSz(ci, widHei), allMaxStimSz(ci, widHei));

%         for pi=1:nPos
%             fprintf(f,'\t\t%.2f [%.2f %.2f]', allMeanStimSz(ci, pi, widHei), allMinStimSz(ci, pi, widHei), allMaxStimSz(ci, pi, widHei));
%         end
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



