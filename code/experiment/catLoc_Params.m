%% function p = catLoc_Params(TR)
% This function creates a structure "p", (later called "params" or "task"), 
% which has many fields. Each field specifies something about the stimuli
% and task in the catLoc experiment. Some fields are themselves structures. 
% This structure (p) is passed from function to function, sometimes with data fields added to it. 
% 
function p = catLoc_Params(TR)

if nargin<1
    TR = 1.5;
end

%% Two possible versions that differ in how many stimuli are presented simultaneously 
p.stimLaterality = 'tri'; %uni for unilateral; tri for tri-lateral (three simultaneous) 

%% categories of stimuli
%text categories are defined by word type and font  
p.textCategoryWordTypes = {'lowFreqWords','lowFreqWords','pseudowords','pseudowords'};
p.textCategoryFonts     = {'Sloan',      'Courier',   'Sloan',    'Courier'};
for sci = 1:length(p.textCategoryWordTypes)
    p.textCategories{sci} = [p.textCategoryWordTypes{sci} p.textCategoryFonts{sci}];
end
p.pseudofontCategories = {'PseudoSloan','PseudoCourier'};
p.faceCategories = {'maleFaces','femaleFaces'};
p.limbCategories = {'limbs1','limbs2'};
p.objectCategories = {'objects1','objects2'};

% Now assemble all of those into one list of categories 
%NOTE - NOT INCLUDING OBJECTS! 
p.categories =  cat(2, p.textCategories, p.pseudofontCategories, p.faceCategories, p.limbCategories);

%add a "blank" trial category
p.categories = cat(2, p.categories, {'blank'});

p.nCategories = length(p.categories); 


%% background luminance 
p.bgLum = 161/255;  

%% stimulus locations
if strcmp(p.stimLaterality, 'uni') %one stimulus at a time, at one of 3 positions. *COULD BE EDITED TO ALWAYS PRESENT ONLY AT THE FOVEA (x-position 0). 
    %x and y in degrees
    p.stimLocs.x = [-2.75 0 2.75];  
    p.stimLocs.y = [ 0  0    0  ];
    
    [p.stimLocs.ang, p.stimLocs.eccs] = cart2pol(p.stimLocs.x ,p.stimLocs.y);
    p.stimLocs.n = length(p.stimLocs.eccs);

    p.stimLocs.propTrialsBySide = [0.39 0.21 0.39];


    %% font sizes for each position
    
    p.text.xHeightsDeg    = 0.6 * ones(p.stimLocs.n, 1); %desired height of x in degrees visual angle, at each position
    p.text.unqXHeightsDeg = unique(p.text.xHeightsDeg);
    p.text.nSizes         = length(p.text.unqXHeightsDeg);

else %3 stimuli at a time (as in White et al, 2023):
    %% stimulus locations
    %x and y in degrees
    p.stimLocs.x = [-5.5 0 5.5];
    p.stimLocs.y = [ 0  0   0  ];
    
    [p.stimLocs.ang, p.stimLocs.eccs] = cart2pol(p.stimLocs.x ,p.stimLocs.y);
    p.stimLocs.n = length(p.stimLocs.eccs);
    
    %% font sizes for each position
    %how should size vary with eccentricity?
    %Chung, Mansfield & Lette, 1998N
    %   S = S0*(1 + E/E2)
    % where S critical print size: min size of "x" to achieve max reading speed
    % E is eccentricity
    % S0 is critical print size at fovea
    % E2 is eccentricity where S=2*S0.
    % They find E2=1.39, and S0=0.16 deg.
    
    S0 = 0.3; %foveal x-height
    E2 = 1.7;
    p.text.xHeightsDeg    = S0*(1 + p.stimLocs.eccs/E2);
    p.text.unqXHeightsDeg = unique(p.text.xHeightsDeg);
    p.text.nSizes         = length(p.text.unqXHeightsDeg);
    
    %what would Chung et al say critical print size is at our locations?
    p.text.criticalPrintSize = 0.17*(1+p.stimLocs.eccs/1.39); %rounding up S0 from 0.16 to 0.17

    
end

%% text fonts 
%string fonts: names to refer to fonts used for words 
p.text.fontNames = {'Courier New','Sloan'};
if any(strcmp(p.pseudofontCategories, 'PseudoSloan'))
    p.text.fontNames = cat(2, p.text.fontNames, 'PseudoSloan');
end
if any(strcmp(p.pseudofontCategories, 'PseudoCourier'))
    p.text.fontNames = cat(2, p.text.fontNames, 'BACS2');
end

%target fonts: which to actually set font to
p.text.targetFonts = p.text.fontNames;
p.text.targetFonts(strcmp(p.text.targetFonts, 'Sloan')) = {'PseudoSloan'}; 

if IsWin
    p.text.targetFonts(strcmp(p.text.targetFonts, 'BACS2')) = {'BACS2serif'}; %windows names it with this full name
end

%for not monospace fonts, number of fifths of letter size to add as white space between letters
p.text.whiteSpaceBarWidth = 1.6;

%monospace: whether each font should be monospaced. if so, letters are just
%concatenated; if not, blank space between each pair of letters is set to a contant number of pixels
%all are monospaced except pseudosloan
p.text.monospace = ones(size(p.text.targetFonts));
p.text.monospace(strcmp(p.text.targetFonts, 'PseudoSloan')) = 0; 

%% length of character strings 
p.text.lengths = 5;

%% frequency bins to use 
p.text.realWordFreqBinsToUse = {'low','high'}; %only applies to real words 
p.text.freqBins = [5 10; 75 4000];

p.text.nRealWordFreqBins = length(p.text.realWordFreqBinsToUse);

%% which type of pseudowords? Constrained trigrams or bigrams
p.text.pseudowordType = 'bigram';

%text stimulus set
p.text.listFile = 'stimulusGeneration/CatLocTextSet.csv';

%% face images 
p.faces.imageFile = 'stimulusGeneration/faceImages.mat';

%where to put the faces? 
%only where the words were along the horizontal meridian
p.faces.posToUse = p.stimLocs.y==0; %
%what should the face width image be, at each eccentricity? 
%roughly match it to the words, which are set by the height (roughly=width)
%of individual letters. 
%so we just multiply the letter size + spacing by the mean number of letters. 
%then I'm scaling further because on average the faces occupy only
%the centeral 71% of the image. 
p.faces.imgWidthDeg = (p.text.xHeightsDeg*mean(p.text.lengths))/0.71; 

p.faces.unqWidthDeg = unique(p.faces.imgWidthDeg);
p.faces.nSizes       = length(p.faces.unqWidthDeg);

%% object images
%inherit most params from faces
p.objects = p.faces;
%don't scale quite as much as the faces, b/c many objects do take up the
%whole horizontal extent of the image
p.objects.imgWidthDeg = (p.text.xHeightsDeg*mean(p.text.lengths))/0.78; 
p.objects.unqWidthDeg = unique(p.objects.imgWidthDeg);

p.objects.imageFile = 'stimulusGeneration/objectImages.mat';

%% limb images
%inherit most params from objects
p.limbs = p.objects;
%don't scale quite as much as the faces, b/c many objects do take up the
%whole horizontal extent of the image
p.limbs.imgWidthDeg = (p.text.xHeightsDeg*mean(p.text.lengths))/0.78; 
p.limbs.unqWidthDeg = unique(p.limbs.imgWidthDeg);

p.limbs.imageFile = 'stimulusGeneration/limbImages.mat';
%% text color & appearance
p.text.contrast = -1;
if p.bgLum>0
    p.text.lum            = p.bgLum + p.text.contrast*p.bgLum;
else
    p.text.lum            = 1*p.text.contrast;
end
p.text.color               = ones(1,3)*round(p.text.lum*255);

p.text.antiAlias          = 1; %0; %Previously I said: "Don't. It looks bad." But as of 4/10/24, the text shows up as all boxes with antiAlias turned off

%% task events 
%doFixationColorChanges: whether to do random fixation dot color changes. 
%NOTE: if you set this to false, the fixation dot will always be black, EXCEPT on runs when you select the fixation task. 
%If you set it to true, then it will always do color changes, even during the one-back task

p.doFixationColorChanges    = false; 
p.probFixColorChange        = 0.33; %mean proportion of trials with 1 color change. The rest have none. 

%doStimRepeats: whether to have some stimuli repeat in the trial (target
%events for one-back task. 
%NOTE: if you set this to false, there will be no successive repeats,
%except on runs when you select the one-back task.
%If you seit it to true, there will always be some repeats, even during the
%fixation task. 
p.doStimRepeats          = true; 
p.probStimRepeat         = 0.33; %mean proportion of trials with 1 stimulus repeat. The rest have none. 
%% fixation mark 

%Dot
p.fixation.dotDiameter      = 0.11;  %0.08
p.fixation.dotType          = 2; % 0 (default) squares, 1 circles (with anti-aliasing), 2 circles (with high-quality anti-aliasing, if supported by your hardware). If you use dot_type = 1 you'll also need to set a proper blending mode with the Screen('BlendFunction') command!

if p.doFixationColorChanges
%     nColrs = 5; %saturations: ranges from gray (0) to full color (1)
%     %hues: can range from red (0) and back to red (1)
%     hues = 0:(1/nColrs):(1-1/nColrs);
%     sats = ones(1,nColrs); 
%     %values, aka luminance, ranges from 0 (black) to 1 (max)
%     vals = ones(1,nColrs)*0.6; 
%     vals(1:2:end) = 0.5; %subtle changes in brightness too
%     %set colors in hsv space: 

    %hand coded
    % We decided not to change colors based on 
    % https://projects.susielu.com/viz-palette
    
    hues = [0 0.2 0.5 0.7 0 0];
    sats = [1  1   1    1 0 0];
    vals = [0.5 0.8 0.6 1 1 0];   
  
    p.fixation.dotColors = round(255*hsv2rgb([hues' sats' vals']));    
    p.fixation.nColrs = length(hues);
else
    p.fixation.dotColors    = [100 0 0];
    p.fixation.nColrs  = 1;
end
    
%start the color out at index 1. On target events it is incremented by some
%random amount.
p.fixation.dotColorI = 1;

%% ORGANIZATION OF SCANS & TRIALS 
p.org.stimPerTrial           = 4; 
p.org.trialsPerCatPerRun     = 7; %total trials per category per run 
p.org.trialsPerRun           = p.nCategories*p.org.trialsPerCatPerRun; 

p.org.goalNRuns = 4; %how many runs to prepare unique stimuli for: 
%how many images we need per category (each image can contian multiple individual stimuli) 
p.org.totalImgPerCategory = p.org.trialsPerCatPerRun*p.org.goalNRuns*p.org.stimPerTrial;  
%how many individual stimuli we need 
p.org.totalStimsPerCategory = p.org.totalImgPerCategory*p.stimLocs.n; 

p.org.practiceTrialsPerCatPerRun = 2; %total trials per category per run
p.org.practiceTrialsPerRun       = p.nCategories*p.org.practiceTrialsPerCatPerRun;
p.org.practiceImgPerCategory   = p.org.practiceTrialsPerCatPerRun*1*p.org.stimPerTrial; 

%% Timing parameters
p.TR = TR;

p.time.stimulus                = 0.700; 
p.time.ISI                     = 0.300; 
p.time.trial                   = p.org.stimPerTrial*(p.time.stimulus+p.time.ISI);

%because the trials all come back to back, there is some danger of falling
%behind schedule. So, given that the last ISI of each trial is just a blankadditionalInitialBlankTRs
%period, we can but that ISI short by a "buffer" period that can then be
%taken by all the inter-trial computations, and start the next trial on
%time. 
p.time.interTrialBufferTime     = 0.100; 

%blank before trial 1
p.scannerWarmupTRs = 0; 
p.additionalInitialBlankTRs = 4;

p.time.initialBlank   = p.scannerWarmupTRs*p.TR + p.additionalInitialBlankTRs*p.TR;
p.time.finalBlank     = 4*p.TR;

p.time.practiceInitialBlank = 4;
p.time.practiceFinalBlank = 2;

p.time.startRecordingTime = 0.200;
%total scan duration 
p.goalRunDuration = p.time.initialBlank + p.org.trialsPerRun*p.time.trial + p.time.finalBlank;
p.goalRunDuration_TRs = p.goalRunDuration/p.TR;

%NOW ADD 1 MS TO EACH DURATION TO AVOID ROUND DOWN ERROR WHEN SETTING TO
%MULTIPLES OF FRAME DURATION
p.timeFudgeFactor = 0.001;
times = fieldnames(p.time); 
for tsi = 1:numel(times)
    eval(sprintf('p.time.%s = p.time.%s + p.timeFudgeFactor;', times{tsi}, times{tsi}));
end

%Tolerance in rounding off durations to be in multiples of monitor frame
%duration. If rounding up would make an error less than this tolerance,
%then round up. Otherwise, round down. 
p.durationRoundTolerance = 0.0026; 

%To precisely control timing, determine when frame flips are asked for 
p.flipperTriggerFrames = 1.25;  %How many video frames before desired stimulus time should the screen Flip command be executed 
p.flipLeadFrames = 0.5;        %Within the screen Flip command, how many video frames before desired time should flip be asked for 

%maximum response time to count as a hit 
p.maxResponseTime = 2.0; 
%and mininum response time. Anything less than that is probably a false
%alarm 
p.minResponseTime = 0.200;

%% Eyetracking 
% initlFixCheckRad: 
% if just 1 number, it's the radius of circle in which gaze position must land to start trial. 
% if its a 1x2 vector, then it defines a rectangular region of acceptable
% gaze potiion. 
% Then new fixation position is defined as mean gaze position in small time window at trial start 

p.fivePointCalib           = true; %whether to just do 5 point caliberation in stead of 9
p.initlFixCheckRad         = [1 3];  
p.fixCheckRad              = [1 2]; % radius of circle (or dims of rectangle) in which gaze position must remain to avoid fixation breaks. [deg]
p.horizOnlyFixCheck        = false; %whether to abort only if horizontal position of eye exceeds fixCheckRad(1)
p.maxFixCheckTime          = 0.500; % maximum fixation check time before recalibration attempted 
p.minFixTime               = 0.200; % minimum correct fixation time
p.nMeanEyeSamples          = 10;    %number of eyelink samples over which to average gaze position to determine new fixation point 
p.calibShrink              = [0.5 0.6];   %shrinkage of calibration area in vertical dimension (horizontal is adjusted further by aspect ratio to make square, if squareCalib)
p.squareCalib              = false;  %whether calibration area should be square 

%% text for instructions 
p.instruct.fontName = 'Courier New';
p.instruct.fontStyle = 1; %bold
p.instruct.fontSize = 40; 
p.instruct.fontColor = [0 0 0];

p.textAntialias = 1;
p.fontName = 'Courier New';
p.textSize = 32;


%% key to press to abort experiment 
p.quitKey  = 'q';

%% sounds - not used in this experiment but these things are still necessary 
p.soundsOutFreq             = 48000; %output sampling frequency 
p.soundsBlankDur            = 0;  %amount of blank time before sound signal starts 



