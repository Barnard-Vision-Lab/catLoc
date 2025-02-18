params = catLoc_Params;
t = params.text;
nFonts = length(t.fontNames);

% Pseudoscloan asci codes, for each letter
lowComplexityASCIIs = 97:122;
hiComplexityASCIIs = 193:218;

%ASCI codes for regular alphaget
lowerCaseASCIIs = 97:122;
upperCaseASCIIs = 65:90;

%set asci codes into a big matrix with one row for each font
ascis = NaN(nFonts, 26);
ascis(strcmp(t.fontNames, 'Courier New'), :)   = lowerCaseASCIIs;
ascis(strcmp(t.fontNames, 'BACS2'), :)         = lowerCaseASCIIs;
ascis(strcmp(t.fontNames, 'Sloan'), :)         = upperCaseASCIIs;
ascis(strcmp(t.fontNames, 'PseudoSloanLo'), :) = lowComplexityASCIIs;
ascis(strcmp(t.fontNames, 'PseudoSloanHi'), :) = hiComplexityASCIIs;

Screen('Preference', 'SkipSyncTests', 1)
try
    % Choosing the display with the highest dislay number is
    % a best guess about where you want the stimulus displayed.
    screens=Screen('Screens');
    screenNumber = max(screens);
    w=Screen('OpenWindow', screenNumber);
    [xres, yres]    = Screen('WindowSize', w);
    [centerX, centerY] = WindowCenter(w);

    Screen('FillRect', w);

    for f = 1:nFonts


        Screen('TextFont',w, t.targetFonts{f});
        Screen('TextSize',w, 24);
        Screen('TextStyle', w, 0);
        Screen('DrawText', w, char(ascis(f,:)), centerX-500, centerY, [0, 0, 0]);
        fprintf('Requested font: %s, got: %s\n',  t.targetFonts{f}, Screen('TextFont', w));


        Screen('DrawText', w, 'Hit any key to continue.', centerX, centerY+200, [255, 0, 0, 255]);
        Screen('Flip',w);
        pause(1);

        KbWait;
    end
    sca;
catch
    % This "catch" section executes in case of an error in the "try" section
    % above.  Importantly, it closes the onscreen window if it's open.
    sca;
    psychrethrow(psychlasterror);
end

%% Issues right now: 
% - Pseudosloan font likes to be bigger than all the rest, at a given point
% size 
% - CreateLetterTextures is putting a weird white line at the top of each
% letter
% - %PseudoSloan Hi 22nd letter is just a black outline! Huh? 

