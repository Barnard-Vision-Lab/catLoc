%function [m, status] = getDisplayParameters(displayName)
%
% Returns a structure m with parameters for display monitor for a
% particular computer (with name displayName). For use with the function
% prepScreen that opens a Psychtoolbox window.
%
% fields of m:
% - width: width of active pixels [cm]
% - height: height of active pixels [cm]
% - subDist: distance of subject's eyes from monitor [cm]
% - goalResolution: desired screen resolution, horizontal and vertical [pixels].
%   PTB will try to set this resolution, unless it is left empty.
% - goalFPS: desired screen refresh rate, in frames per second [Hz].
%   PTB will try to set this referesh rate, unless it is left empty.
% - skipSyncTests: whether PTB should skip synchronization tests [boolean]
% - calibFile: the name of a mat file that contains the luminance calibration information,
%   as a table to load into  Screen('LoadNormalizedGammaTable' [character string].
%   Can be left empty.
% - monName: name of this monitor [character string]
%
% Also returns status, which is 1 if input displayName matches one of the
% setups stored in this function, 0 if there was no match and monitor
% parameters resorted to the default.

function [m, status] = getDisplayParameters(displayName)

status = 1;

m.useRetinaDisplay = false;
m.monName = displayName;

switch displayName
    case 'JuneProjector'
        m.width = 50.5;
        m.height = 20.25;
        m.subDist = 142;
        m.goalResolution = [1920 1080];
        m.goalFPS = 60; 
        m.normlzdGammaTable = [];
        m.useRetinaDisplay = false;
        m.skipSyncTests = true;

    case 'ASUS'
        m.width = 40.5;
        m.height = 25.5;
        m.subDist = 60;
        m.goalResolution = [1680 1050];
        m.goalFPS = 60; 
        m.normlzdGammaTable = [];
        m.useRetinaDisplay = false;
        m.skipSyncTests = IsOSX;
        
    case 'CMRR' %MISSING INFO
        m.width = NaN;
        m.height = 39.29; 
        m.subDist = 1080;
        m.goalResolution = [NaN 1080]; 

        m.ppd = 85; 
       
   
    case 'ViewPixxEEG'
        m.width = 53;
        m.height = 29.8;
        m.goalResolution = [1920 1080];
        m.goalFPS = 120;
        m.subDist = 70;
        
        m.skipSyncTests = 0;
        
        %to use calibration fit to each gun separately 
        m.calibFile = 'ViewPixxEEG_RGBW_15-Oct-2019.mat';
        
        load(m.calibFile); 
        m.calib = calib;
        m.normlzdGammaTable = calib.normlzdGammaTable;
        
    case 'MacbookPro'
        m.width = 28.5;
        m.height = 18;
        m.subDist = 50;
        m.goalResolution = [1440 900];
        m.skipSyncTests = 1;
        m.normlzdGammaTable = [];
        m.useRetinaDisplay = true;
    
    case 'MacbookProMaya'
        m.width = 28.5;  % Apple website 30.31
        m.height = 18; % Apple website 21.24
        m.subDist = 50;
        m.goalResolution = [2560 1600];
        m.skipSyncTests = 1;
        m.normlzdGammaTable = [];
        m.useRetinaDisplay = true; 

    case {'CERASOffice','LG_Home'}
        m.width = 59.6;
        m.height = 33.5;
        m.subDist = 57;
        m.goalResolution = [3840 2160];
        m.goalFPS = 60;
        m.skipSyncTests = 1;
        m.normlzdGammaTable = [];
        m.useRetinaDisplay = true;        
        
    case 'CNI_LCD'
        m.width = 103.8;
        m.height = 58.6;
        m.subDist = 280;
        m.goalResolution = [1920 1080];
        m.goalFPS = 60; 
        m.normlzdGammaTable = [];
        m.useRetinaDisplay = false;
        m.skipSyncTests = IsOSX;

    case 'Lenovo'
        m.width = 31;
        m.height = 17.7;
        m.subDist = 50;
        m.goalResolution = [1920 1080];
        m.goalFPS = 60;
        m.skipSyncTests = 1;
        m.normlzdGammaTable = [];
        m.useRetinaDisplay = false;
    
    otherwise
        m.width = 36;
        m.height = 29;
        m.subDist = 60;
        m.ppd = 100;
        %m.goalResolution = [];
        m.goalFPS = 60;
        m.skipSyncTests = 1;
        m.calibFile = '';
        m.monName = 'default';
        status = 0;
end

m.displayName = displayName;

%% compute pixels per degree
if ~isfield(m, 'ppd')
    m.ppd =  pixelsPerDegree(m.subDist, m.width, m.goalResolution(1));
end
%compute size of screen in degrees, using ppd
m.dimsDeg = m.goalResolution/m.ppd;
%again, based on centimeters:
m.dimsDeg2 = 2*atand(0.5*[m.width m.height]/m.subDist);
