%% function allDat = gatherData_catLoc(SID, subjDir,resDir)
% This function loads in all the .mat files saved by Psychtoolbox for each
% run of the experiment, for just one subject (SID). 
% It searches for all .mat files for this experiment in the subject's data directory ("subjDir") and loads them all in. 
% It creates a table called allDat with 1 row for each subject,
% concatinating across runs. allDat gets saved both as a .mat file and a
% .csv file in the results directory (resDir). 
% It also creates a BIDS-compatible events tsv file for each run by calling
% catLoc_MakeEventsTSV. 
% 
% NOT DONE YET: 
% - processing the eyelink data files to summarize fixation stability 
% - including only runs that are also included in the fMRI analysis. 
% 
% Inputs: 
% - SID: character string, subject ID  (e.g., '001')
% - subjDataDir: full directory of subjects data folder, e.g.,
%   '.../catLoc/data/001/' 
% - resDir: full directory of folder in which to save the resulting allDat
%   file, e.g., '.../catLoc/results/indiv/'
%
% Outputs: 
% - allDat: table with 1 row for each trial, summarizing what happened. 

function allDat = gatherData_catLoc(SID, subjDataDir, resDir)

exptCodeName = 'catLoc_Run.m'; %name of code file that generated data files

%load in eye analysis parameters:
ip = struct;


[st,i] = dbstack;
thisMFilename = st(min(i,length(st))).file;


%find names of all .mat data files
[matFs, dirs, dirIs] = getFilesByType(subjDataDir,'mat');
edfFiles = getFilesByType(subjDataDir, 'edf');

%but-only take the ones that are included in MRI analysis
%[sessionDates, scans, stims] = FOVMRI_GetSessionInfo(SID);
%%find good sessions that have FOV data
%goodSessNums = [];
%for sci=1:length(sessionDates)
%    if ~isempty(scans.catLoc{sci})
%        goodSessNums = [goodSessNums sci];
%    end
%end
%goodSessDates = sessionDates(goodSessNums);

blockEDFs = {};
hasEDFFile = [];


%check which ones are actual data files produced by each block of
%experiment, and excluding practice
nf = numel(matFs); goodf = 0;
blockFs = {}; dateNums = []; blockDirs = {}; accuracies = [];
for fi=1:nf
    clear task scr stairRes stair
    
    %check if this is a scan included in MRI analysis... not set up yet 
%     thisDir = dirs{dirIs(fi)};
%     slashIs = find(thisDir==filesep);
%     thisFolder = thisDir((slashIs(end)+1):end);
%     if length(thisFolder)>(length(SID)+2)
%         folderDate = thisFolder((length(SID)+2):end);
%         includeScans = any(strcmp(folderDate, goodSessDates));
%         thisSessNum = find(strcmp(folderDate, sessionDates));
%     else
%         includeScans = false;
%     end
    
    %for now, just include all
    includeScans = true;
    
    
    if includeScans
        load(matFs{fi});
        if exist('task','var')
            
            
            if ~task.practice  && strcmp(task.codeFilename, exptCodeName) % && any(task.runNumber==stims.catLoc{thisSessNum}) %only include runs in included in MRI analysis
                goodf = goodf+1;
                blockFs{goodf} = matFs{fi};
                dateNums(goodf) = round(datenum(task.startTime(1:3))); %only count year, month, day
                blockDirs{goodf} = dirs{dirIs(fi)};
             
                taskSubj = task.subj;
                
                
                %find EDF files
                fnm = matFs{fi}(1:(end-4));
                matchEDF = [fnm '.edf'];
                ei = find(strcmp(edfFiles,matchEDF));
                
                if length(ei)==1
                    blockEDFs{goodf} = edfFiles{ei};
                    hasEDFFile(goodf) = true;
                elseif length(ei)>1
                    error('\n(%s) More than 1 edf file matches mat file %s.edf\n', thisMFilename, fnm);
                elseif isempty(ei)
                    if task.EYE==0
                        fprintf(1,'\n(%s) WARNING: no eyetracking during recording of mat file \n%s.mat\n\t\n', thisMFilename, fnm);
                        
                        hasEDFFile(goodf) = false;
                    else
                        fprintf(1,'\n(%s) WARNING: missing edf file for mat file \n%s\n\tType dbcont to continue\n', thisMFilename, fnm);
                        keyboard
                        hasEDFFile(goodf) = false;
                    end
                end
                
                
            end
        end
    end
end



%load in blocks sorted by date
[~,~,dateIs] = unique(dateNums);
[~,blockLoadOrder]=sort(dateIs);

allDat = table;
for fni=1:length(blockLoadOrder)
    fi=blockLoadOrder(fni);
    
    %% Gather behavioral data from mat files
    fprintf(1,'\n(%s) processing file: ...%s\n',thisMFilename, blockFs{fi}((end-26):end));
    
    [blockBehavDat, scrStruct, status] = loadPerceptData_catLoc(blockFs{fi},exptCodeName);
    
    blockBehavDat.dateNum = ones(size(blockBehavDat.chosenRes))*dateIs(fi); %add index of this testing day
    
    
    if status==0, fprintf(1,'\n\n(%s): Warning! Problem with  data file %s.mat\n\n',thisMFilename,blockFs{fi}); keyboard, end
    
    if fni==1
        ipS = catstruct(scrStruct,ip);
    else
        if scrStruct.subjDist~=ipS.subjDist || scrStruct.scrXRes~=ipS.scrXRes || scrStruct.scrWidth~=ipS.scrWidth
            fprintf(1,'\n\n(%s) Warning! Screen setup changed across blocks.\n\n',thisMFilename);
        end
        if ~strcmp(scrStruct.subjInit, ipS.subjInit)
            fprintf(1,'\n\n(%s) Warning! Subject changed across blocks!!\n\n',thisMFilename);
        end
    end
    
%     %% Process eye data! Not set up yet 
%     if ~hasEDFFile(fi)
%         fprintf(1,'\n(gatherData) MISSING EDF FILE FOR %s. Pretending no fixation breaks\n',blockFs{fi}((end-26):end));
%         blockEyeDat = computeCatLoc_EyeData(blockBehavDat,[],ipS);
%     else
%         fprintf(1,'\n(gatherData) processing *edf* file: %s\n',blockEDFs{fi}((end-26):end));
%         blockEyeDat = computeCatLoc_EyeData(blockBehavDat,blockEDFs{fi},ipS);
%     end
%     
%     %blockBehavDat = catstruct(blockBehavDat,blockEyeDat);
%     blockBehavDat = [blockBehavDat blockEyeDat];
%     
    %% Concatenate data across blocks
    try
        allDat = [allDat; blockBehavDat];
    catch
        keyboard
    end
    
    %% make events TSV files 
    
    tsvName = sprintf('sub-%s_ses-%i_task-%s_run-%i_events', SID, dateIs(fi), 'catLoc', blockBehavDat.runNumber(1));
    tsvName = fullfile(resDir, tsvName);
    [taskName] = makeEventsTSV_catLoc(blockFs{fi}, tsvName);
    
    
end

%save as a mat file
matFileName = sprintf('%s/%sAllDat.mat',resDir,ipS.subjInit);
save(matFileName, 'allDat');


%% print out all data to big text file
txtFileName = sprintf('%s/%sAllDat.csv',resDir,ipS.subjInit);
writetable(allDat,txtFileName); %,'Delimiter','\t');
