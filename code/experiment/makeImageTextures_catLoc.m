function task = makeImageTextures_catLoc(task,scr)

ntrials = size(task.runTrials,1);

task.textures  = NaN(ntrials, task.org.stimPerTrial);
task.textRect = []; %FULL SCREEN

for ti = 1:ntrials %trial number within run (including all blocks)
    
    td = task.runTrials(ti,:);
    
    if ~strcmp(td.category, 'blank')
        for si=1:task.org.stimPerTrial
            clear img;
            
            eval(sprintf('fname = td.stim%iFile;', si));
            
            try
                load(fullfile(task.imagePath, fname{1}), 'img');
            catch
                sca
                ShowCursor;
                error('cannot find image %s to load', fname{1});
            end
            task.textures(td.trialNum, si) = Screen('MakeTexture', scr.main, img);
        end
    end
end



