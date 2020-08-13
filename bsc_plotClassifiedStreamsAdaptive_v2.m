function bsc_plotClassifiedStreamsAdaptive_v2(wbFG, classification ,t1, figView, saveDir,subSelect,colors,subSample,slices)
%
%   bsc_plotClassifiedStreams(wbFG, classification, t1, view, saveDir,subSelect,colors)
%
%   PURPOSE: This function plots classified fibers using
%   mbaDisplayConnectome.  Will either plot all classified fiber tracts or
%   those that are subselected. Also, if you pass in an fe structure it
%   will only plot the validated fibers.  If you'd like to prune your
%   fibers as well, feel free to use removeOutliersClassification
%
%  -wbFG:  a structure containing the streamlines referenced in the
%    classification structure.  Can be either a fe structure or a whole
%    brain fiber group.  Will load paths.
%
%  -classification: Either the path to structure or the structure itself.
%   The strucure has a field "names" with (N) names of the tracts classified
%   while the field "indexes" has a j long vector (where  j = the nubmer of
%   streamlines in wbFG (i.e. length(wbfibers)).  This j long vector has
%   a 0 for to indicate a streamline has gone unclassified, or a number 1:N
%   indicatate that the streamline has been classified as a member of tract
%   (N).
%
%  -t1: the t1 image for this subject.  Either a path or an object will
%   sufffice
%
%  -view: either 'coronal', 'axial', 'transverse', or 'saggital'.  Case
%   does not matter.  Creates views from both sides (i.e., top and bottom,
%   left and right, front and back).
%
%  -saveDir:  the directory you would like these figures saved to.  If not
%   defined, saves to current directory.
%
%  -subSelect: a vector corresponding to the indexes of the tracts (in the
%   classification.names structure) which you would like to plot.  If this
%   is not defined, then the function will plot all classified fiber
%   tracts.
%
%  -colors: an Nx3 matrix of values between 0 and 1 corresponding to the
%   RGB mapping desired of the corresponding fiber tracts (i.e. N=1
%   corresponds to fiber tract 1 in the classificaiton.names structure).
%   If this is not defined, the function will attempt determine if there is
%   a left/right pattern in the indexing and generate colors accordingly.
%   Barring all this, it will simply select random colors for each fiber
%   tract.
% 
% mba plotting component of function based on code originally written by
% Franco Pestilli
%
% (C) Daniel Bullock, 2017, Indiana University


%% preliminaries
% loads requisite structures from input
%[wbFG, fe] = bsc_LoadAndParseFiberStructure(wbFG);

%loads classificaiton file if a path is passed
if ischar(classification)
    load(classification);
end

% if an fe structure is detected, alters classificaiton index to only
% include positively weighted fibers
% if ~isempty(fe)
%     if length(fe.life.fit.weights)==length(classification.index)
% classification=wma_clearNonvalidClassifications(classification,fe);
%     else
%         warning('mismatch between classification structure and fe weights')
%     end
% end

%loads t1 if a path is passed
if ischar(t1)
    t1= niftiRead(t1);
end

% if user does not pass in a subselection
if notDefined('subSelect')
    subSelect=1:length(classification.names);
end

% save path is set to current directory if not defined
if notDefined('saveDir')
    saveDir=pwd;
end

%% plotting preliminaries

% creates a structure containing an fg object for each fiber tract
% classification
tractStruc = bsc_makeFGsFromClassification(classification, wbFG);
%keyboard;

% starts a parpool
[pool, poolDir]=startUniqueParpool(8);

%if you only have one fg, use it to set the slices
% if length(subSelect)==1
% 
%     for istreams=1:length(tractStruc(subSelect).fg.fibers)
%         meanVec(istreams,:)=mean(tractStruc(subSelect).fg.fibers{istreams},2);
%     end
%     totalMeans=mean(meanVec,1);
%     if isempty(slices)
%         slices      = {[-1 0 0],[0 totalMeans(2) 0] ,[0 0 totalMeans(3)-10]};
%     end
% else
% 
% %this was set differently in the past, why was this?
% %code doesnt like 000
%     if isempty(slices)
%         slices      = {[-1 0 0],[0 -1 0] ,[0 0 -1]};
%     end
% end

% figure setting
fh = figure('name','FiberClassificationPlot','color','k','units','normalized','position',[.5 .5 .5 .5],'visible','off');
axis equal
fhNum = fh.Number;
hold on

% switch lower(figView)
%     case 'sagittal'
%         h  = mbaDisplayBrainSlice(t1, slices{1});
%     case 'coronal'
%         h  = mbaDisplayBrainSlice(t1, slices{2});
%     case {'axial', 'transverse'}
%         h  = mbaDisplayBrainSlice(t1, slices{3});
% end

h = mbaDisplayBrainSlice(t1,slices{1});

%% plotting

%plot each of the fiber tracts iteratively
if length(subSelect) == 1
    tractIndex = subSelect;
    if ~isempty(subSample)
        if length(tractStruc(tractIndex).fg.fibers) > subSample
            [fh, lh] = mbaDisplayConnectome(randsample(tractStruc(tractIndex).fg.fibers,subSample),fhNum, colors{1}, 'single');
        else
            [fh, lh] = mbaDisplayConnectome(tractStruc(tractIndex).fg.fibers,fhNum, colors{1}, 'single');
        end
    else
        [fh, lh] = mbaDisplayConnectome(tractStruc(tractIndex).fg.fibers,fhNum, colors{1}, 'single');
    end
    delete(lh)
    fprintf('\n %s \n',classification.names{subSelect})
else
    for itract = 1:length(subSelect)
        tractIndex=subSelect(itract);
        if exist('lh','var'), delete(lh); end
        if ~isempty(tractStruc(tractIndex).fg.fibers)
            if ~isempty(subSample)
                if length(tractStruc(tractIndex).fg.fibers) > subSample
                    [fh, lh] = mbaDisplayConnectome(randsample(tractStruc(tractIndex).fg.fibers,subSample),fhNum, colors{itract}, 'single');
                else
                    [fh, lh] = mbaDisplayConnectome(tractStruc(tractIndex).fg.fibers,fhNum, colors{itract}, 'single');
                end
            else
                [fh, lh] = mbaDisplayConnectome(tractStruc(tractIndex).fg.fibers,fhNum, colors{itract}, 'single');
            end
            delete(lh)
            fprintf('\n %s \n',classification.names{tractIndex})
        end
    end
end

% set views to the desired azimuth/elevation
switch lower(figView)
    %light handles still need work
    case 'sagittal'
        fig.views =   {[90,0],[-90,0]};
        %best angles for viewing pArc and MdLF
        light.angle = {[45,15],[-45,15]};
        fig.names = {strcat(tractStruc(tractIndex).name,'_ClassifiedTracks_Saggital_',num2str(subSelect))};
        curDim=1;
        sideFlag=[-1 1]; 
    case 'coronal'
        fig.views = {[0,0],[180,0]};
        light.angle = {[25,25],[155,-25]};
        fig.names = {strcat(tractStruc(tractIndex).name,'_ClassifiedTracks_Coronal_',num2str(subSelect))};
        curDim=2;
        sideFlag=[-1 1]; 
    case {'axial', 'transverse'}
        fig.views = {[0,90],[0,-90]};
        light.angle = {[1,89],[1,-89]};
        fig.names = {strcat(tractStruc(tractIndex).name,'_ClassifiedTracks_Axial_',num2str(subSelect))};
        curDim=3;
        sideFlag=[1 -1]; 
end

% iterate through view settings and save a picture for each one.
for iview = 1:length(fig.views)
    fprintf('%s %s',figView,num2str(iview));
    view(fig.views{iview})

    if ischar(light.angle{iview})
        camlight(light.angle{iview})
    else
    lh = camlight(light.angle{iview}(1),light.angle{iview}(2)); 
    end
    
    figureHand=gcf;
    figureHand.Units='inches';
    %figureHand.Position(3:4)=figureHand.Position(3:4)*4;

    fprintf('Saving as %s', strcat(fig.names{1},num2str(iview))) 
    
    saveas ( fh,strrep(strcat(saveDir,'/',fig.names{1},num2str(iview)),'  ', '_'),'jpg')
end

close all

end