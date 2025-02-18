%[data, scrStruct, status] = loadPerceptData_catLoc(filename,exptCodeName)
%
% Alex White, 2014
%
% loads in data from the task.data structure stored in the experimental
% data file with  name filename. Makes sure that it was the correct
% experiment, and not practice or staircase.
% Also stores information about screen and subject in separate field
%
% inputs:
% - filename: a string containing the address of the mat file to be loaded
% - exptCodeName: string containing name of experiment's main function
%
% outputs:
% - data: a table containing one column for each of stored
%   variables
% - scrStruct: a structure with variables about the screen (subject
% distance, horizontal dimensions, etc).
% - status: 1 if all was good, 0 if the loaded file was not of the right
%  type


function [data, scrStruct, status] = loadPerceptData_catLoc(filename, exptCodeName)

status = 0;

load(filename);


if exist('task','var')
    codename = task.codeFilename;
    
    if strcmp(codename, exptCodeName)
        if ~task.practice
            
            %load in all data variables
            data = task.runTrials;
            
            %Exclude trials that were planned but not reached because user quit
            if any(data.userQuit)
                lastTrial = find(data.userQuit)-1;
                data = data(1:lastTrial, :);
            end
                
            
            %add the year, month and day
            data.year  = ones(size(data.trialNum))*task.startTime(1);
            data.month = ones(size(data.trialNum))*task.startTime(2);
            data.day   = ones(size(data.trialNum))*task.startTime(3);
            
            %add the run number
            data.runNumber   = ones(size(data.trialNum))*task.runNumber;
            
         
            %Get out details of the screen (and subject)
            scrStruct.subjDist = scr.subDist;
            scrStruct.scrXRes  = scr.xres;
            scrStruct.scrWidth = scr.width;
            scrStruct.scrCen   = [scr.centerX scr.centerY];
            scrStruct.DPP = pix2deg(scrStruct.scrXRes,scrStruct.scrWidth,scrStruct.subjDist,1); % degrees per pixel
            scrStruct.PPD = deg2pix(scrStruct.scrXRes,scrStruct.scrWidth,scrStruct.subjDist,1); % pixels per degree
            
            scrStruct.subjInit = task.subj;
            scrStruct.fixCheckRad = task.fixCheckRad;            
            scrStruct.buttons = task.buttons;
            
            status = 1;
        end
    end
else
    data = []; scrStruct = [];
end
