function task = catLoc_SetRunAndTrialOrder(task)

%% Find stimulus images
if task.stimLocs.n~=1
    task.imagePath =  fullfile(task.projPath, 'stimuli', task.displayName);
else
    %special case for just 1 stimulus in each image
    task.imagePath =  fullfile(task.projPath, 'stimuli', [task.displayName '_1Loc']);
end

if ~isempty(task.textCategories) || ~isempty(task.pseudofontCategories)
    textParamFile = fullfile(task.imagePath,sprintf('textStimParams_%s.mat',task.displayName));
    if ~exist(textParamFile,'file')
        error('(%s) No text images made for this display (%s)!',mfilename, textParamFile);
    end
    %load word image params
    load(textParamFile,'textStims');
    task.textImageParams = textStims;
end
if ~isempty(task.faceCategories)
    faceParamFile = fullfile(task.imagePath,sprintf('faceStimParams_%s.mat',task.displayName));
    if ~exist(faceParamFile,'file')
        error('(%s) No face images made for this display (%s)!',mfilename, faceParamFile);
    end
    %load face image params
    load(faceParamFile,'faceStims');
    task.faceImageParams = faceStims;
end

if ~isempty(task.objectCategories)
    if any(ismember(task.objectCategories, task.categories))
        ojbectParamFile = fullfile(task.imagePath,sprintf('objectStimParams_%s.mat',task.displayName));
        if ~exist(objectParamFile,'file')
            error('(%s) No object images made for this display (%s)!',mfilename, objectParamFile);
        end
        %load face image params
        load(objectParamFile,'objectStims');
        task.objectImageParams = objectStims;
    end
end

if ~isempty(task.limbCategories)
    limbParamFile = fullfile(task.imagePath,sprintf('limbStimParams_%s.mat',task.displayName));
    if ~exist(limbParamFile,'file')
        error('(%s) No limb images made for this display (%s)!',mfilename, limbParamFile);
    end
    %load face image params
    load(limbParamFile,'limbStims');
    task.limbImageParams = limbStims;
end


%% RESET RANDOM NUMBER GENERATOR
task.initialSeed = ClockRandSeed;
task.startTime=clock;


%% set data folder
theDate=date;
folderDate=[task.subj '_' theDate(1:2) theDate(4:6) theDate((end-1):end)];
task.subjFolder = fullfile(task.dataPath,task.subj);
task.subjDataFolder = fullfile(task.subjFolder,folderDate);
if ~isfolder(task.subjDataFolder)
    mkdir(task.subjDataFolder);
end
task.pracDataFolder = fullfile(task.subjDataFolder,'practice');
if ~isfolder(task.pracDataFolder)
    mkdir(task.pracDataFolder);
end



%% set up the run, taking into account previous runs for this subject
taskLabels = {'one-back','fixation'};

% First, determine whether a prior run exists
runFile = fullfile(task.subjFolder, sprintf('%s_catLocRunInfo.mat', task.subj));

if exist(runFile,'file') && ~task.practice
    load(runFile, 'runNumber','allRunTrials');

    fprintf(1,'\n(%s) Looks like there have been %i runs already for this subject.\n', mfilename, runNumber);

    %copy this previous run file before we overwrite anything
    oldRunFile = fullfile(task.subjFolder, sprintf('%s_CatLocOriginalRun%iInfo.mat', folderDate, runNumber));
    copyfile(runFile, oldRunFile);

    %If not all planned runs have been completed
    if runNumber < task.numRuns
        fprintf(1,'\n(%s) Do you want to continue to the next run that was originally planned for this subject?', mfilename);
        fprintf(1,'\n(%s) It will be run number %i, %s task\n', mfilename, runNumber+1, taskLabels{task.whichTasks(runNumber+1)});

        keepAskingContinue = true;
        while keepAskingContinue
            continueOldRun = input('Enter y or n\n', 's');
            keepAskingContinue = ~strcmp(continueOldRun,'y') && ~strcmp(continueOldRun,'n');
        end
        if strcmp(continueOldRun,'y')
            %take the same "runTrials" structure, starting after the
            %last completed block from the prior run
            task.allRunTrials  = allRunTrials;
            priorRunStatus = 1; %taking into account prior run
            runNumber = runNumber+1;
            %make sure the allRunTrials has trials for this run
            thisRunTrials = allRunTrials(allRunTrials.runNum == runNumber, :);
            if size(thisRunTrials,1)<task.org.trialsPerRun
                fprintf(1,'(%s) ERROR: not enough trials for this run set in previous allRunTrials!', mfilename);
                keyboard
            end


        else
            fprintf(1,'\nOk, we will start a new set of runs fresh\n');
            priorRunStatus = 2; %ignoring prior run
            runNumber = 1;

            %but give the user a chance to escape
            keepAskingContinue = true;
            while keepAskingContinue
                allGood = input('Are you sure? Enter y or n\n', 's');
                keepAskingContinue = ~strcmp(allGood,'y') && ~strcmp(allGood,'n');
            end
            if strcmp(allGood, 'n')
                error('Start over');
            end

        end
        %If the prior run was finished
    else
        fprintf(1,'\n(%s) It looks like the previous session was completed, so we''ll start a new one now', mfilename);
        runNumber = 1;
        priorRunStatus = 1; %taking into account prior run
    end

    %if there was no prior run
else
    if ~task.practice
        fprintf(1,'\n(%s) We can''t find any prior run information for this subject. So we''ll start from scratch.\n', mfilename);

        %but give the user a chance to escape
        keepAskingContinue = true;
        while keepAskingContinue
            allGood = input('Does that seem right? Enter y or n\n', 's');
            keepAskingContinue = ~strcmp(allGood,'y') && ~strcmp(allGood,'n');
        end
        if strcmp(allGood, 'n')
            error('Start over');
        end
    end
    runNumber = 1;
    priorRunStatus = 0; %nothing
end
task.runNumber = runNumber;



%% Set trial order for ALL runs in this sesion, if not done yet
%if we haven't loaded the "allRunTrials" structure in from a previous run
if ~isfield(task, 'allRunTrials')
    T = table;
    nT = task.org.trialsPerRun;
    %% set trial order
    cis = repmat(1:task.nCategories, task.numRuns, task.org.trialsPerCatPerRun);
    for ri=1:task.numRuns
        rt = table;
        rt.runNum   = ones(nT, 1)*ri;
        rt.trialNum = (1:nT)';
        rt.task     = ones(nT, 1)*task.whichTasks(ri);

        %set category for each trial, in a random order
        rt.categoryI = cis(ri, randperm(nT))';

        T = [T; rt];
    end

    %% choose the 4 stimuli for each trial, checking if we have enough to avoid repeats

    T.category = task.categories(T.categoryI)';
    T.fixColorChange = false(size(T.runNum));
    T.fixColorChangeStimNum = zeros(size(T.runNum));
    T.fixColorChangeIncrement = zeros(size(T.runNum));
    T.stimRepeat = false(size(T.runNum));
    T.repeatStimNum = zeros(size(T.runNum));

    for sii=1:task.org.stimPerTrial
        eval(sprintf('T.stim%iFile = cell(size(T.runNum));', sii));
        eval(sprintf('T.stim%iIndex = zeros(size(T.runNum));', sii));
    end

    %target events - stimulus repetitions
    if (task.doStimRepeats || task.whichTasks(runNumber)==1)
        nRepeatTrialsPerCat = round(task.org.trialsPerCatPerRun*task.numRuns*task.probStimRepeat);
    else
        nRepeatTrialsPerCat = 0;
    end

    %target events - fixation dot color changes
    if (task.doFixationColorChanges || task.whichTasks(runNumber)==2)
        nColorChangesPerCat = round(task.org.trialsPerCatPerRun*task.numRuns*task.probFixColorChange);
    else
        nColorChangesPerCat = 0;
    end

    nStimPerCat = task.org.trialsPerCatPerRun*task.numRuns*task.org.stimPerTrial;
    allFontIs = zeros(size(T,1),1);
    allImgNums = zeros(size(T,1), task.org.stimPerTrial);

    %Set stimuli for all trials that aren't in the "blank" cateogry:
    nonBlankCategories = find(~strcmp(task.categories, 'blank'));
    for ci = nonBlankCategories
        theseTs = find(T.categoryI==ci);
        N = length(theseTs);

        %% set when an image repeats (for one-back task)
        %on which trials there is a repeat
        repeatTs = randsample(1:N, nRepeatTrialsPerCat, false);
        T.stimRepeat(theseTs(repeatTs)) = true;

        %within each trial with a repeat, which stimulus in the
        %sequence is the repeat (2-4)
        repeatStim = randsample(2:task.org.stimPerTrial, nRepeatTrialsPerCat, true);
        T.repeatStimNum(theseTs(repeatTs)) = repeatStim;

        %% randomly select images for this category, with no repetitions
        nUniqueStims = nStimPerCat - nRepeatTrialsPerCat;

        imgNumLin = randsample(1:task.org.totalImgPerCategory, nUniqueStims, false);
        imgNums = zeros(N, task.org.stimPerTrial);
        repIs = sub2ind([N task.org.stimPerTrial], repeatTs, repeatStim);
        nonRepIs = setdiff(1:nStimPerCat, repIs);
        imgNums(nonRepIs) = imgNumLin;

        %set repeats in imgNums
        for tii=1:length(repeatTs)
            imgNums(repeatTs(tii), repeatStim(tii)) =  imgNums(repeatTs(tii), repeatStim(tii)-1);
        end
        %so now imgNums is a Ntrials x imgPerTrial matrix of image indices

        %% set fonts
        if ci<=length(task.textCategories)
            thisFont = task.textCategoryFonts{ci};
            if strcmp(thisFont, 'Courier')
                thisFont = 'Courier New';
            end
            baseFontI = find(strcmp(task.text.fontNames, thisFont));
            fontIs = ones(N,1)*baseFontI;

            stimFileCategories = task.categories(ones(N,1)*ci);
            %take out the stimulus indices for the foveal stimulus in
            %all images we have for this condition
            allCentralStimIs = squeeze(textStims.stringIs(strcmp(task.categories{ci}, textStims.valsByIndex.category), task.stimLocs.eccs==0, :));

            doCheckCentralRepeat = true;
        else

            switch task.categories{ci}

                case {'PseudoSloan', 'PseudoCourier'}
                    if strcmp(task.categories{ci}, 'PseudoSloan')
                        matchFont = 'Sloan';
                        baseFontI = find(strcmp(task.text.fontNames, 'PseudoSloan'));
                    elseif strcmp(task.categories{ci}, 'PseudoCourier')
                        matchFont = 'Courier New';
                        baseFontI = find(strcmp(task.text.fontNames, 'BACS2'));
                    end
                    %find previous trials with this base font
                    matchFontTrls = allFontIs == find(strcmp(task.text.fontNames, matchFont));
                    %and what category they belonged to
                    matchFontCats = T.categoryI(matchFontTrls);
                    uMatchFontCats = unique(matchFontCats);
                    nMatchFontCats = length(uMatchFontCats);

                    %match each of these false font trials to a string
                    %presented earlier
                    nTrlsPerMatchCat = round(N/nMatchFontCats);

                    trlsToMatch = [];
                    for mci = 1:nMatchFontCats
                        matchCat = uMatchFontCats(mci);
                        matchTrls = find(matchFontTrls & T.categoryI==matchCat);
                        trlsToMatch = [trlsToMatch; matchTrls(randsample(1:length(matchTrls), nTrlsPerMatchCat, false))];
                    end
                    %shuffle order
                    trlsToMatch = trlsToMatch(randperm(length(trlsToMatch)));
                    if length(trlsToMatch)>N
                        trlsToMatch = trlsToMatch(1:N);
                    elseif length(trlsToMatch)<N
                        unusedMatchTrials = setdiff(find(matchFontTrls), trlsToMatch);
                        trlsToMatch = [trlsToMatch; unusedMatchTrials(randsample(1:length(unusedMatchTrials), N-length(trlsToMatch), false))];
                    end

                    %pull stim nums from those matching trials:
                    imgNums = allImgNums(trlsToMatch, :);

                    %and also set stim repeats from those matched trials
                    T.stimRepeat(theseTs) = T.stimRepeat(trlsToMatch);
                    T.repeatStimNum(theseTs) = T.repeatStimNum(trlsToMatch);

                    %set font index
                    fontIs = ones(N,1)*baseFontI;

                    %set the category the pseudostring was drawn from
                    stimFileCategories = task.textCategoryWordTypes(T.categoryI(trlsToMatch));

                    %but then add the compound name
                    for mti = 1:length(stimFileCategories)
                        stimFileCategories{mti} = [task.categories{ci} '_' stimFileCategories{mti}];
                    end

                    %these inherit imgNums from previously made words so there
                    %shouldnt be any unecessary repeats
                    doCheckCentralRepeat = false;

                case 'PseudoSloanFovea' %low-freq words at fovea only, translated into pseudosloan
                    matchFont = 'Sloan';
                    baseFontI = find(strcmp(task.text.stringFonts, 'PseudoSloan'));
                    %match the words from lowFreqWordsFoveaSloan cateogory
                    matchCatgI = find(strcmp(task.categories, 'lowFreqWordsFoveaSloan'));
                    trlsToMatch = find(T.categoryI==matchCatgI);
                    %pull stim nums from those matching trials:
                    imgNums = allImgNums(trlsToMatch, :);

                    %and also set stim repeats from those matched trials
                    T.stimRepeat(theseTs) = T.stimRepeat(trlsToMatch);
                    T.repeatStimNum(theseTs) = T.repeatStimNum(trlsToMatch);

                    %set font index
                    fontIs = ones(N,1)*baseFontI;

                    %set the category the pseudostring was drawn from
                    stimFileCategories = task.categories(T.categoryI(trlsToMatch));

                    %these inherit imgNums from previously made words so there
                    %shouldnt be any unecessary repeats
                    doCheckCentralRepeat = false;
                case {'faces','maleFaces','femaleFaces'}

                    fontIs = zeros(N,1);
                    stimFileCategories = task.categories(ones(N,1)*ci);

                    %take out the stimulus indices for the foveal stimulus in
                    %all images we have for this condition
                    allCentralStimIs = squeeze(faceStims.faceIs(strcmp(task.categories{ci}, faceStims.valsByIndex.category), task.stimLocs.eccs==0, :));
                    doCheckCentralRepeat = true;
                case {'objects', 'objects1','objects2'}
                    fontIs = zeros(N,1);
                    stimFileCategories = task.categories(ones(N,1)*ci);
                    %take out the stimulus indices for the foveal stimulus in
                    %all images we have for this condition
                    allCentralStimIs = squeeze(objectStims.objectIs(strcmp(task.categories{ci}, objectStims.valsByIndex.category), task.stimLocs.eccs==0, :));
                    doCheckCentralRepeat = true;
                case {'limbs', 'limbs1','limbs2'}
                    fontIs = zeros(N,1);
                    stimFileCategories = task.categories(ones(N,1)*ci);
                    %take out the stimulus indices for the foveal stimulus in
                    %all images we have for this condition
                    allCentralStimIs = squeeze(limbStims.limbIs(strcmp(task.categories{ci}, limbStims.valsByIndex.category), task.stimLocs.eccs==0, :));
                    doCheckCentralRepeat = true;


                otherwise
                    fontIs = zeros(N,1);
                    keyboard
            end
        end


        if doCheckCentralRepeat && ~task.practice
            try
                centralStim = allCentralStimIs(imgNums);
            catch
                keyboard
            end
            centralStim = reshape(centralStim, size(imgNums));
            centralStim(repIs) = 9999; %dont include stimulu that actually ought to repeat
            cdiffs = diff(centralStim, 1, 2);
            badIs = find(cdiffs==0);
            if ~isempty(badIs)
                for bii=1:length(badIs)
                    [badT, badS] = ind2sub(size(cdiffs), badIs(bii));
                    badS = badS+1;
                    prevCentralStim = centralStim(badT, badS-1);
                    if badS<task.org.stimPerTrial
                        nextCentralStim = centralStim(badT, badS+1);
                    else
                        nextCentralStim = -inf;
                    end
                    goodIs = find(allCentralStimIs~=prevCentralStim & allCentralStimIs~=nextCentralStim);
                    %replace this one stimulus with a fresh one
                    imgNums(badT, badS) = goodIs(randi(length(goodIs),1));
                end
            end
        end


        allImgNums(theseTs,:) = imgNums;
        allFontIs(theseTs) = fontIs;


        %set image index for each trial
        for sii=1:task.org.stimPerTrial
            eval(sprintf('T.stim%iIndex(theseTs) = imgNums(:, sii);', sii));
        end

        %set actual image file for each stimulus on each trial
        for trli = 1:N
            trlN = theseTs(trli);
            for sii=1:task.org.stimPerTrial
                %format for text and pseudotext images:
                %if fontIs(trli)>0
                %    thisFileName = sprintf('%s_%s_%i', stimFileCategories{trli}, task.text.stringFonts{fontIs(trli)}, imgNums(trli, sii));
                %format for all others
                %else
                thisFileName = sprintf('%s_%i', stimFileCategories{trli}, imgNums(trli, sii));
                %end

                if task.practice
                    thisFileName = [thisFileName '_PRAC'];
                end
                thisFileName = [thisFileName '.mat'];

                if ~exist(fullfile(task.imagePath,thisFileName))
                    fprintf(1,'\n(%s) image file %s does not exist!\n', mfilename, thisFileName);
                    keyboard
                else
                    eval(sprintf('T.stim%iFile{trlN} = thisFileName;', sii));
                end

            end
        end

        %% set color changes
        %on which trials
        changeTs = randsample(1:N, nColorChangesPerCat, false);
        T.fixColorChange(theseTs(changeTs)) = true;

        % when in the trial... with same temporal distribution as the
        % one-back events
        colrChangeStim = randsample(2:task.org.stimPerTrial, nColorChangesPerCat, true);
        T.fixColorChangeStimNum(theseTs(changeTs)) = colrChangeStim;

        %and what should the color be? set the change in index on each time
        T.fixColorChangeIncrement(theseTs(changeTs)) = randsample(1:task.fixation.nColrs, nColorChangesPerCat, true);


    end

    T.fontI = allFontIs;
    T.font(allFontIs>0) = task.text.fontNames(allFontIs(allFontIs>0));

    task.allRunTrials = T;

end

