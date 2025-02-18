%% Process lexical decision stimulus set, making exclusions, and putting it all together into one table/spreadsheet
clear; close all;


%% find files and paramters
codePath = catLoc_Base();
stimPath = fullfile(codePath, 'stimulusGeneration');


%read in words from a 'raw' set
listFile = fullfile(stimPath, 'LexicalDecision_RawStimulusSet1.xlsx');

elpStatsFile = fullfile(stimPath, 'ELP_Stats.xlsx');

lexiconFileName = fullfile(stimPath, 'CatLocTextSet');

params = catLoc_Params;

wordLengths = params.text.lengths;
nLeng = length(wordLengths);

categories = {'real','pseudo','consonants'};
nCatg = numel(categories);

freqLabels = params.text.realWordFreqBinsToUse;
freqBinBorders = params.text.freqBins;

nFreqBins = length(freqLabels);

%% Assemble the lexicon
lexicon = table;

nStims = NaN(nLeng, nCatg, nFreqBins);

lowerCaseASCIIs = 97:122;
alphabet = char(lowerCaseASCIIs);
vowels = 'aeiouy';
consonants = setdiff(alphabet, vowels);

for li=1:nLeng
    for ci=1:nCatg
        if strcmp(categories{ci},'pseudo')
            T = readtable(listFile, 'sheet', sprintf('%s %s %i', categories{ci}, params.text.pseudowordType,  wordLengths(li)));
            %exclude pseudohomophones
            T = T(T.Pseudohomophone~=1,:);
            %exclude strings marked as "bad"
            T = T(T.bad~=1,:);
            
            %add frequency bin
            T.frequencyBin = repmat({'0'},size(T,1),1);
            
            %set frequency itself to 0
            if all(strcmp(T.FREQ,'NA'))
                T.FREQ = zeros(size(T.LEN));
            else
                keyboard
            end
            
            %% exclude psueodowords with no vowels
            hasVowel = NaN(size(T.bad));
            for wi=1:size(T,1)
                hasVowel(wi) = any(ismember(vowels, T.STRING{wi}));
            end
            T = T(hasVowel==1,:);
            
            nStims(li, ci, 1) = size(T,1);
            
        elseif strcmp(categories{ci},'real')
            T = table;
            %two frequencies?
            for fi=1:nFreqBins
                fT = readtable(listFile, 'sheet', sprintf('%s %i %s', categories{ci}, wordLengths(li), freqLabels{fi}));
                fT.frequencyBin = repmat(freqLabels(fi),size(fT,1),1);
                
                %exclude strings marked as "bad"
                fT = fT(fT.bad~=1,:);
                
                %filter by max and min frequency 
                fT = fT(fT.FREQ>=freqBinBorders(fi,1) & fT.FREQ<=freqBinBorders(fi,2), :);
                
                nStims(li, ci, fi) = size(fT,1);
                                
                T = [T; fT];
            end
            
            %exclude strings marked as "bad"
            T = T(T.bad~=1,:);
            
            %add pseudohomophone variable
            T.Pseudohomophone = false(size(T.bad));
        elseif strcmp(categories{ci}, 'consonants')
            nStr = nStims(li, 1, 1)*1.5; %make same number of consonant strings as we had for pseudowords 
            is = randi(length(consonants), nStr, wordLengths(li));
            is = unique(is, 'rows');
            is = is(1:nStims(li, 1, 1), :);
            
            T = table;
            T.STRING = cell(size(is,1),1);
            for stri=1:size(is,1)
                T.STRING{stri} = consonants(is(stri,:));
            end
            T.LEN = ones(size(T.STRING))*wordLengths(li);
            T.FREQ = zeros(size(T.LEN));
            T.Pseudohomophone = zeros(size(T.LEN));
            T.bad = zeros(size(T.LEN));
            T.frequencyBin = repmat({'0'},size(T,1),1);
            
            %add other things that might be missing 
            otherVars = setdiff(lexicon.Properties.VariableNames, T.Properties.VariableNames);
            for ovi=1:length(otherVars)
                eval(sprintf('T.%s = NaN(size(T.LEN));', otherVars{ovi}));
            end
            
        end
        T.category = repmat(categories(ci),size(T,1),1);
        
        lexicon = [lexicon; T];
        
    end
end



%% Add information from English Lexicon Project  about real word frequency and lexical decision RTs
% https://elexicon.wustl.edu/
% only found info about real words. No matching data about

E = readtable(elpStatsFile, 'sheet','real');
varsToAdd =  {'Freq_HAL','Ortho_N',  'Phono_N',      'Freq_N',      'Concreteness_Rating','Emotional_Valence','   Emotional_Arousal','   BG_Mean',          'NPhon',            'NSyll',               'POS',   'I_Mean_RT','I_Mean_Accuracy'};
newVarName = {'ELP_FreqHAL','ELP_OrthN','ELP_PhonoN','ELP_MeanOrthNFreq','ELP_Concreteness','ELP_EmotionalValence','ELP_EmotionalArousal','ELP_MeanBigramCount','ELP_NPhonemes','ELP_NSyllables','ELP_PartOfSpeech','ELP_MeanRT','ELP_MeanAcc'};
for vi=1:numel(varsToAdd)
    if strcmp(varsToAdd{vi},'POS')
        eval(sprintf('lexicon.%s = cell(size(lexicon.LEN));', newVarName{vi}));
    else
        eval(sprintf('lexicon.%s = NaN(size(lexicon.LEN));', newVarName{vi}));
    end
end
realWordIs = find(strcmp(lexicon.category,'real'))';
for wi=realWordIs
    ri = find(strcmp(E.Word, lexicon.STRING{wi}));
    if ~isempty(ri)
        for vi=1:numel(varsToAdd)
            eval(sprintf('dats = E.%s;', varsToAdd{vi}));
            if iscell(dats)
                dat = dats{ri};
                
                if dat~='#'
                    %all but part of speech are numbers coded as strings
                    %that need to be converted
                    if ~strcmp(varsToAdd{vi}, 'POS')
                        %remove commas and convert to number
                        dat = str2double(dat(dat~=','));
                        eval(sprintf('lexicon.%s(wi) = dat;', newVarName{vi}));
                        
                    else
                        eval(sprintf('lexicon.%s{wi} = dat;', newVarName{vi}));
                    end
                end
            else
                eval(sprintf('lexicon.%s(wi) = E.%s(ri);', newVarName{vi},  varsToAdd{vi}));
            end
        end
    else
        %fprintf(1,'\n%s',lexicon.STRING{wi});
        fprintf(1,'\nword %s not found in ELP', lexicon.STRING{wi});
    end
end

% % DO THE SAME FOR PSEUDOWORDS
E = readtable(elpStatsFile, 'sheet','pseudo');

varsToAdd = {'Ortho_N','BG_Mean', 'NWI_Mean_RT','NWI_Mean_Accuracy'};
newVarName = {'ELP_OrthN','ELP_MeanOrthNFreq','ELP_MeanRT','ELPMeanAcc'};
for vi=1:numel(varsToAdd)
    if ~any(strcmp(lexicon.Properties.VariableNames,newVarName{vi}))
        eval(sprintf('lexicon.%s = NaN(size(lexicon.LEN));', newVarName{vi}));
    end
end
psedoWordIs = find(strcmp(lexicon.category,'pseudo'))';
for wi=psedoWordIs
    ri = find(strcmp(E.Word, lexicon.STRING{wi}));
    if ~isempty(ri)
        for vi=1:numel(varsToAdd)
            eval(sprintf('dats = E.%s;', varsToAdd{vi}));
            if iscell(dats)
                dat = dats{ri};
                
                if dat~='#'
                    %remove commas and convert to number
                    dat = str2double(dat(dat~=','));
                    eval(sprintf('lexicon.%s(wi) = dat;', newVarName{vi}));
                end
            else
                eval(sprintf('lexicon.%s(wi) = E.%s(ri);', newVarName{vi},  varsToAdd{vi}));
            end
        end
    else
        %fprintf(1,'\n%s',lexicon.STRING{wi});
        fprintf(1,'\n%s not found in ELP', lexicon.STRING{wi});
    end
end






%% load in description
[~,descrip,~]=xlsread(listFile,'description');
[~,definitions,~] = xlsread(elpStatsFile,'definitions');

%% save
writetable(lexicon,[lexiconFileName '.csv']);

%write the description
fn = fopen([lexiconFileName '_Description.txt'],'w');
for kk=1:length(descrip)
    fprintf(fn,'\n%s', descrip{kk});
end
%add definitions from ELP file
fprintf(fn,'\n\nELP Definitions:\n');
for kk=1:length(definitions)
    fprintf(fn,'\n%s', definitions{kk});
end

%% count what we have 
fprintf(fn, '\n\nNumber of strings of each type:\n');
nStims = NaN(nLeng, nCatg, nFreqBins);

for li=1:nLeng
    lens = lexicon.LEN==wordLengths(li);
    
    for ci=1:nCatg
        cats = strcmp(lexicon.category,categories{ci});
        if strcmp(categories{ci},'real')
            for fi=1:nFreqBins
                theseStims =lens & cats & strcmp(lexicon.frequencyBin,freqLabels{fi});
                nStims(li, ci, fi) = sum(theseStims);
               
                fprintf(fn, '%s freq (%i-%i per mill) real words of length %i: %i\n', freqLabels{fi}, freqBinBorders(fi,1), freqBinBorders(fi,2), wordLengths(li), nStims(li, ci, fi));
            end
        else
            theseStims = lens & cats;
            nStims(li, ci, 1) = sum(theseStims);
            fprintf(fn, '%s of length %i: %i\n', categories{ci}, wordLengths(li),nStims(li, ci, 1));

        end
    end
end