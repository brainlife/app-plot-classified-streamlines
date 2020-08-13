function [] = main()

% add paths to repositories
if ~isdeployed
    disp('loading paths for IUHPC')
    addpath(genpath('/N/u/brlife/git/vistasoft'))
    addpath(genpath('/N/u/brlife/git/mba'))
    addpath(genpath('/N/u/brlife/git/jsonlab'))
    addpath(genpath('/N/u/brlife/git/wma_tools'))
end

% set top variables
topDir = pwd;
saveDirectory = fullfile(topDir,'output');

% make output directory
if ~isdir(saveDirectory)
    mkdir(saveDirectory)
end

% load config
config = loadjson('config.json');

% set config variables
slices = config.slices;
slices = {str2num(slices)};
colors = config.colors;
colors = str2num(colors);
    
tract_indices = config.tractIndices;
tract_indices = str2num(tract_indices);
subsample = config.subsample;
fig_view = config.figView;

% set subsample to empty array if config is empty
if isempty(subsample)
    subsample = [];
end

% make colors into a cell array
colors_cell = {};
for ii = 1:(length(colors) / 3)
    colors_cell{ii} = colors((3*ii-3)+1:(3*ii));
end

% load t1, classification structure, and tractogram
wbFG = fgRead(fullfile(config.track));
anat = niftiRead(fullfile(config.anat));
load(fullfile(config.classification));

% plot code
bsc_plotClassifiedStreamsAdaptive_v2(wbFG,classification,anat,fig_view,saveDirectory,tract_indices,colors_cell,subsample,slices);

end