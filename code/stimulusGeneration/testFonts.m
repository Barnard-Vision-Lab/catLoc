clear all;

targetDisplay = 'Lenovo';

%trying to prevent text clipping
%global ptb_drawformattedtext_disableClipping
%ptb_drawformattedtext_disableClipping = 1;
%but that doesnt work 

%% open screen
params = catLoc_Params;
t = params.text;


scr = getDisplayParameters(targetDisplay);
scr.white = [255 255 255];
scr.black = [0 0 0];

bgLum = 1;

bgColor = scr.white*bgLum;

rectToOpen = [];
numBuffers = 2;
stereoMode = 0;
multiSample = [];
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
scr.bgColor = bgColor;

%% Put up text 

% clear keyboard buffer
KbEventFlush(-3);

%clear screen to background color
rubber(scr,[]);

Screen('TextSize', scr.main, 20);
Screen('TextStyle', scr.main,0);
c = [0 0 0];
t.targetFonts = cat(2, t.targetFonts, {'Bauhaus 93','Gigi','Arial' })
nFonts = length(t.targetFonts);
for f=1:nFonts
    vertPos = 6-1.5*f;
    Screen('TextFont', scr.main, t.targetFonts{f});
    [posxy] = dva2scrPx(scr, 0, vertPos);

    if f==2
        str = lower(t.targetFonts{f});
    elseif f==3
        str = upper(t.targetFonts{f});
    else
        str = t.targetFonts{f};
    end

    %DRAW TEXT WORKS! But positions are a little messed up 
   Screen('DrawText', scr.main, str, posxy(1), posxy(2), c);
  %DrawFormattedText doesnt work: for some reason, for PseudoSloan, this doenst draw the top half of the
  %letters
   %ptbDrawFormattedText(scr.main,str,posxy,c,true,true,false,false);
end

Screen('Flip',scr.main);

pause(5);
sca;

