%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Analyze behavioral data from the catLoc fMRI experiment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Alex White
%%%%%%%% Spring 2022
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 

clear; close all;

%% setup analysis
%List of subject initials to be included
subjs = {'009'};

%whether mat files should be gathered together
doGatherData = true; 

%whether each subject's data needs to be analyzed (false if res files already exist)
analyzeEach = true;


%% set paths
projectDir = fileparts(fileparts(which('AllBehavAnalysis_catLoc')));

anaDir = fullfile(projectDir,'analysis');
datDir = fullfile(projectDir, 'data');
resDir = fullfile(projectDir, 'results');
resDirIndiv = fullfile(resDir,'indiv');
resDirGroup = fullfile(resDir,'mean');
figDir     = fullfile(resDir, 'figs');

if ~isfolder(resDirGroup), mkdir(resDirGroup), end
if ~isfolder(resDirIndiv), mkdir(resDirIndiv), end
if ~isfolder(figDir), mkdir(figDir), end

%% Analyze each subject
%Gather data from all subjects (and plot if necessary)
nSubj = numel(subjs);
resFiles = cell(1,nSubj);

for s=1:numel(subjs)
    sdir    = fullfile(datDir,subjs{s});
    allDatName = fullfile(resDirIndiv,sprintf('%sAllDat.csv',subjs{s}));
    resFiles{s}=fullfile(resDirIndiv, sprintf('%sRes.mat',subjs{s}));
    
    if doGatherData
        allDat = gatherData_catLoc(subjs{s}, sdir, resDirIndiv);
    else
        allDat = readtable(allDatName);
    end
    
    if analyzeEach
        [r, valsByIndex] = AnalyzeSubject_catLoc(allDat);
        save(resFiles{s}, 'r','valsByIndex');
    else
        load(resFiles{s}, 'r','valsByIndex');
    end
    
   
    %for Subject 1, initialize the matrices in allR
    vars = fieldnames(r);
    if s==1
        nD = zeros(1,numel(vars));
        for vi=1:numel(vars)
            eval(sprintf('vsz = size(r.%s);', vars{vi}));
            %exclude singleton dimensions -- why? 
            %vsz = vsz(vsz>1);
            %if isempty(vsz), vsz = 1; end
            matSz = [vsz nSubj];
            nD(vi) = length(vsz);
            eval(sprintf('allR.%s = NaN(matSz);', vars{vi}));
        end
    end
    
    %save these results in a big maxtrix with all subjects
    for vi=1:numel(vars)
        colons = repmat(':,', 1, nD(vi));
        eval(sprintf('allR.%s(%s %i) = r.%s;', vars{vi}, colons, s, vars{vi}));
    end
    
end

%% 
if numel(subjs)>1
    
    %average over subjects
    for vi=1:numel(vars)
        eval(sprintf('rAvg.%s = nanmean(allR.%s, ndims(allR.%s));', vars{vi}, vars{vi}, vars{vi}));
        eval(sprintf('rAvg.SEM.%s = standardError(allR.%s, ndims(allR.%s));', vars{vi}, vars{vi}, vars{vi}));
    end
    
    rAvg.valsByIndex = valsByIndex;
    
    allR.valsByIndex = valsByIndex;
    allR.valsByIndex.subjs = subjs;
    
    resFileName = 'catLoc_AllBehavRes.mat';
    resFile = fullfile(resDirGroup,resFileName);
    save(resFile, 'allR','rAvg');
    
    %% plot scatters
    figure; hold on;
    dataTypes = {'hitRate','falseAlarmRate', 'dprime'};
    axlims = [0.5 1; 0 0.5; 0 4];
    for dti=1:length(dataTypes)
        dataType = dataTypes{dti};
        subplot(1, length(dataTypes), dti);
        hold on;
        eval(sprintf('ds = squeeze(allR.%s(2:3, 1, :));', dataType));
        
        plot(axlims(dti,:), axlims(dti,:), 'k-');
        
        plot(ds(1,:), ds(2,:), 'b.', 'MarkerSize', 11);
        xlabel([valsByIndex.taskName{2} ' task']);
        ylabel([valsByIndex.taskName{3} ' task']);
        xlim(axlims(dti,:));
        ylim(axlims(dti, :)); 
        axis square;
        title(dataType);
    end
    set(gcf,'units','centimeters','color','w', 'pos', [2 2 29 11]);
    fontSize = 12;
    figTitle = fullfile(resDirGroup, 'CatLocPerformanceScatters.eps');
    exportfig(gcf,figTitle,'Format','eps','bounds','loose','color','rgb','LockAxes',0,'FontMode','fixed','FontSize',fontSize)

    %% plot hit rates as a function of category 
    figure; hold on;
    
    catIs = find(~strcmp(valsByIndex.category, 'blank'));
    ms = squeeze(rAvg.hitRate(catIs, 1, :));
    es = squeeze(rAvg.SEM.hitRate(catIs, 1, :));
    taskColors = [1 0 0; 0 0.5 0.5];
    catgs = valsByIndex.category(catIs);
    ncats = length(catgs);
    hs = zeros(1,2);
    for cati=1:ncats
        plot([cati cati], ms(taski, cati)+[-1 1]*es(taski, cati), 'k-', 'Color', taskColors(taski, :));
    end
    
       hs = plot(1:ncats, ms, '.-', 'MarkerSize', 17, 'Color', taskColors(1, :));
       
    xlim([0 ncats+1]);
    ylim([0.5 1]);
    set(gca,'XTick', 1:ncats, 'XTickLabel', catgs, 'XTickLabelRotation',30);
    legend(hs, taskName,'Location','SouthEast');
    text(0.4, 0.55, sprintf('N=%i', length(allR.valsByIndex.subjs)));

    ylabel('Hit rate');
        
    set(gcf,'units','centimeters','color','w', 'pos', [2 2 24 11]);
    figTitle = fullfile(resDirGroup, 'CatLocHitRatesbyCategory.eps');
    exportfig(gcf,figTitle,'Format','eps','bounds','loose','color','rgb','LockAxes',0,'FontMode','fixed','FontSize',fontSize)

end
