function varargout = comp_explore(varargin)
% COMP_EXPLORE - GUI used for exploring and classifying
%                Independent Components
%      COMP_EXPLORE(EEG) lets you classify components in a given EEG
%      signal. It is assumed that you have an ICAw variable in your
%      workspace - this variable should be the ICAw database that
%      you interface with using comp_explore.
%      EEG should be a given EEG recovered using recoverEEG
%      with option 'ICAnorem' - that is without removing components
%
%
%      COMP_EXPLORE, by itself, creates a new COMP_EXPLORE or raises the existing
%      singleton*.
%
%      H = COMP_EXPLORE returns the handle to a new COMP_EXPLORE or the handle to
%      the existing singleton*.
%
%      COMP_EXPLORE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in COMP_EXPLORE.M with the given input arguments.
%
%      COMP_EXPLORE('Property','Value',...) creates a new COMP_EXPLORE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before comp_explore_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to comp_explore_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help comp_explore

% Last Modified by GUIDE v2.5 04-Dec-2013 17:56:42

% TODOs:
% [ ] - editable component descriptions
% [ ] - update ICAw by (inputname?) global variable
% [ ] - compare spectopo and SpectPwelch - why are they different in
%       plotting component spectra?
% [ ] - add button options for erpimage (smoothing, something else/)
% [ ] - change scatter to go back to variance if patch deleted
% [ ] - add some (floating?) text-box with info on freq when marking
%       spectrum for scatter display
% [ ] - change display of scatter
% [ ] - add options gui for spectrum
% [ ] - add/repair click-zoom property for topo, tri etc.

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @comp_explore_OpeningFcn, ...
    'gui_OutputFcn',  @comp_explore_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before comp_explore is made visible.
function comp_explore_OpeningFcn(hObject, eventdata, h, varargin) %#ok<INUSL>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to comp_explore (see VARARGIN)

% CHANGE:
% arguments can be passed as:
%         - if no ICAw given we assume it is in the base workspace
%           we perform checks:
%           -- if no EEG given then we search base workspace
%              for ICAw structures, get name(s) of these structures,
%              if multiple exist - pop up gui, if none - return error
% EEG       -- if EEG is present we check whether the EEG has
%              a copy of ICAw in EEG.etc
%              look for ICAw just as in previous point
%              (but if EEG.etc.ICAw copy exists then look for ICAw(r) that
%              matches the EEG.etc.ICAw copy
%              display warning if no ICAw is present
%
% ICAw    - then r is assumed to be 1 (not if EEG present)
% ICAw, r - then EEG is recovered
% if before first optional key occurs there is
% a string we assume it is

% Choose default command line output for comp_explore
h.output = hObject;

h.EEG = varargin{1};
h.spect = cell(1, size(h.EEG.icaweights, 1));
h.varia = h.spect;

% check num of comps
h.ncomp = size(h.EEG.icaweights, 1);

% additional arguments:
if evalin('base', 'exist(''ICAw'', ''var'');');
    % take care of additional arguments
    evalin('base', 'global ICAw;');
    global ICAw %#ok<TLEV>
else
    % dupa blada
    error('Damn, you should have a ICAw variable in your workspace');
end

% additional arguments:
if nargin > 5
    % take care of additional arguments
    h.r = varargin{3};
else
    % dupa blada
    error('Damn, you should have given me record number!');
end

% additional arguments:
if nargin > 6
    % take care of additional arguments
    h.comp = varargin{4};
else
    h.comp = 1;
end


% ============================================
% checking ICAw - if no ICA_desc field, create
f = ICAw_checkfields(ICAw, h.r, {'ICA_desc'});

if ~f.fnonempt(1)
    for cc = 1:h.ncomp
        ICAw(h.r).ICA_desc(cc).reject = false;
        ICAw(h.r).ICA_desc(cc).ifreject = false;
        ICAw(h.r).ICA_desc(cc).type = '?';
        ICAw(h.r).ICA_desc(cc).subtype = 'what am I ?';
        ICAw(h.r).ICA_desc(cc).rank = [];
        ICAw(h.r).ICA_desc(cc).notes = [];
    end
end

%% default opt ICA:
h.opt.ICA.types = {'artifact';'brain';'?'};
h.opt.ICA.subtypes{1} = {'blink'; 'horiz eye movement';...
    'heart'; 'muscle'; 'neck'};
h.opt.ICA.subtypes{2} = {'brrrain'};
h.opt.ICA.subtypes{3} = {'what am I ?'};
h.opt.ICA.ranks = {'NoRank';'5';'4';'3';'2';'1'};
h.opt.ICA.rejcol = [0.2 0.85 0.15; 0.92 0.28 0.15; 0.78 0.78 0.21];
h.opt.ICA.rejs = {'spare';'reject';'maybe'};

% ADD:
% [ ] scan across ICAw to add subtypes etc.

% [ ] CHANGE? - should it be a cell for different
% individual selections?
h.spct.startpoint = [];
h.spct.endpoint = [];
h.spct.patch = [];
h.spct.line = [];
h.spct.freqsel = [];
h.spct.patchcolor = [0.8, 0.5, 0.2];

h.triaxhndls = [];

%% initial options:
h.opt.topo.numcont = 4;

h.opt.tri.smooth = 1;
h.opt.tri.filt = true;

h.opt.spect.freqlim = [1 60];
h.opt.plot.winl = 3; % this is the nb of windows(epochs) to plot


% ==============
% dipfit options
if femp(ICAw(h.r), 'dipfit')
    h.opt.dipf.plot = true;
else
    h.opt.dipf.plot = false;
end
h.dipfig = [];

% ADD, CHANGE, CHECK:
% 'mri' can be taken from
% EEG.dipfit.mrifile
% but what about variable paths??

% ADD these options to h.opt.dipfit:
% 'cornermri','on','axistight','on','projimg','on',...
% 'projlines','on','normlen','on'


% how it is plotted in eegh:
% pop_dipplot( EEG,[1:63] ,'mri',...
% 'D:\\MATLAB stuff\\eeglab12_0_2_5b\\plugins\\dipfit2.2\\standard_BEM\\standard_mri.mat',...
% 'cornermri','on','axistight','on','projimg','on',...
% 'projlines','on','normlen','on');

%% if no icaact - create:
if isempty(h.EEG.icaact)
    h.EEG.icaact = eeg_getdatact(h.EEG, ...
        'component', 1:size(h.EEG.icaweights, 1));
end

% [ ] ADD - use inputname() and declare corresponding
%     ICAw as global variable

% maybe use narginchk(minargs, maxargs) ?

% set spectrum axis callback
set(h.freq, 'ButtonDownFcn',@start_getrange);

% display filename
set(h.uipanel1, 'Title', ICAw(h.r).filename);

%  =============
%% DipFit figure
%  =============
if h.opt.dipf.plot
    % CHECK 'gui'' 'off' option
    
    pop_dipplot( h.EEG, 1:h.ncomp ,'mri',...
        h.EEG.dipfit.mrifile,...
        'cornermri','on','axistight','on','projimg','on',...
        'projlines','on','normlen','on', 'view', [0.5 -0.5 0.5]);
    h.dipfig = gcf;
    
    % set size and position of both figure1
    % (main comp_explore GUI and dipplot figure)
    uni = get(0, 'units');
    set(0, 'units', 'pixels');
    screen = get(0, 'ScreenSize');
    set(0, 'units', uni);
    
    % width of compexp:
    set(h.figure1, 'units', 'pixels');
    pos = get(h.figure1, 'Position');
    
    screen_left = screen(3) - pos(3);
    left_onright = screen_left - pos(1);
    
    % size of dipplot figure:
    uni = get(h.dipfig, 'units');
    set(h.dipfig, 'units', 'pixels');
    posdip = get(h.dipfig, 'Position');
    
    if left_onright >= posdip(3) + 10
        posdip(1) = pos(1) + pos(3) + 5;
        posdip(2) = pos(2) + (pos(4) - posdip(4) - 10);
        set(h.dipfig, 'Position', posdip);
        clear posdip pos
    else
        % either enough place on screen:
        if screen_left >= posdip(3) + 10
            need_screen_onright = posdip(3) - left_onright;
            
            pos(1) = pos(1) - need_screen_onright - 10;
            posdip(1) = pos(1) + pos(3) + 5;
            posdip(2) = pos(2) + (pos(4) - posdip(4) - 10);
            set(h.dipfig, 'Position', posdip);
            set(h.figure1, 'Position', pos);
            clear need_screen_onright pos posdip
        else
            % or not enough space, rescale dipplot fig:
            pos(1) = 5;
            newposdip = screen_left - 10;
            rescaleby = newposdip / posdip(3);
            posdip(1) = pos(3) + 10;
            posdip(3) = newposdip;
            posdip(4) = round(posdip(4) * rescaleby);
            posdip(2) = pos(2) + (pos(4) - posdip(4) - 10);
            
            set(h.dipfig, 'Position', posdip);
            set(h.figure1, 'Position', pos);
            clear newposdip pos posdip rescaleby
        end
    end
    
    % return units to dipplot fig
    set(h.dipfig, 'units', uni);
    
    % look for main axis of dipplot
    chldrn = get(h.dipfig, 'Children');
    tps = get(chldrn, 'Type');
    h.dipaxis = chldrn(strcmp('axes', tps));
    clear tps chldrn
    
    % hide all dipoles
    for tmpi = 1:length(h.EEG.dipfit.model)
        dips = findobj('parent', h.dipaxis, ...
            'tag', ['dipole' int2str(tmpi)]);
        %         for d = 1:length(dips)
        %         set(dips(d), 'visible', 'off');
        %         end
        %         clear d dips
        set(dips, 'visible', 'off');
    end;
    clear tmpi
end

% Update handles structure
guidata(hObject, h);

% refresh gui
refresh_comp_explore(h);



% UIWAIT makes comp_explore wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = comp_explore_OutputFcn(hObject, eventdata, handles)  %#ok<INUSL>
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


%
function refresh_comp_explore(h, varargin)

% default - refresh all
refr = {'topo'; 'spect'; 'scatter'; 'tri'; 'compinfo'; 'rank'; 'dip'};

% check for specific refresh commands
if nargin > 1
    refr = varargin;
end

% global variable ICAw:
global ICAw

%% === component info ===
if sum(strcmp('compinfo', refr)) > 0
    
    % type of comp:
    compt = ICAw(h.r).ICA_desc(h.comp).type;
    alltps = h.opt.ICA.types;
    compi = find(strcmp(compt, alltps));
    
    if isempty(compi)
        ICAw(h.r).ICA_desc(h.comp).type = '?';
        compi = 3;
    end
    
    ht = [h.artif; h.brain; h.dontknow];
    set(ht(compi), 'Value', 1);
    
    % component subtype:
    compt = ICAw(h.r).ICA_desc(h.comp).subtype;
    alltps = h.opt.ICA.subtypes{compi};
    
    compiyou = find(strcmp(compt, alltps));
    if isempty(compiyou)
        alltps = [alltps(:); compt]; %why so?
        h.opt.ICA.subtypes{compi} = alltps;
        compiyou = length(alltps);
    end
    
    %set(h.compsubtype, 'String', alltps,'Value', compiyou);
    set(h.compsubtype, 'String',alltps);
    set(h.compsubtype,'Value', compiyou);
    
    % reject button
    if ICAw(h.r).ICA_desc(h.comp).reject
        ICAw(h.r).ICA_desc(h.comp).ifreject = false;
        set(h.rejbut, 'BackGroundColor', h.opt.ICA.rejcol(2,:), ...
            'String', h.opt.ICA.rejs{2});
    elseif ICAw(h.r).ICA_desc(h.comp).ifreject
        set(h.rejbut, 'BackGroundColor', h.opt.ICA.rejcol(3,:), ...
            'String', h.opt.ICA.rejs{3});
    else
        set(h.rejbut, 'BackGroundColor', h.opt.ICA.rejcol(1,:), ...
            'String', h.opt.ICA.rejs{1});
    end
    
    
    % notes
    set(h.componotes, 'String', ICAw(h.r).ICA_desc(h.comp).notes);
    
    % comp number
    set(h.ICnb, 'String', ['IC ', num2str(h.comp)]);
    
    %sum of rejected components
    if ~isempty(sum([ICAw(h.r).ICA_desc.reject]))
        set(h.sumrej, 'String', num2str(sum([ICAw(h.r).ICA_desc.reject])));
    else
        set(h.sumrej, 'String','None');
    end
    
    % =======================================
    % allow for interruption by using drawnow
    drawnow
end

% ============
% refresh rank

if sum(strcmp('rank', refr)) > 0
    
    rnk = ICAw(h.r).ICA_desc(h.comp).rank;
    valr = find(strcmp(rnk, h.opt.ICA.ranks));
    if ~isempty(valr) && valr > 0
        set(h.RatingDropDown, 'Value', valr);
    else
        set(h.RatingDropDown, 'Value', 1);
    end
end

%% === topo map plot ===
if sum(strcmp('topo', refr)) > 0
    axes(h.topo);
    % ADD - using options for topo (!)
    % clear axes here?
    topoplot( h.EEG.icawinv(:,h.comp), h.EEG.chanlocs, 'chaninfo', h.EEG.chaninfo, ...
        'shading', 'interp', 'numcontour', h.opt.topo.numcont);
    axis square;
    
    % =======================================
    % allow for interruption by using drawnow
    drawnow
end

%% ===check variance===
if sum(strcmp('scatter', refr)) > 0
    if isempty(h.varia{h.comp})
        h.varia{h.comp} = var(squeeze(h.EEG.icaact(h.comp,:,:)), 1)';
    end
    
    varscatter(h.scatter, h.varia{h.comp}, 'sd', 3.5)
    
    % =======================================
    % allow for interruption by using drawnow
    drawnow
end

%% ===spectrum checks===:
if sum(strcmp('spect', refr)) > 0
    % compute spectra
    % now very simply
    if isempty(h.spect{h.comp})
        % [ ] ADD option changes
        opt.compo = true;
        opt.elec = h.comp;
        opt.verbose = false;
        opt.overlap = 0;
        opt.padto = 2^nextpow2(h.EEG.pnts);
        
        % =======================================
        % allow for interruption by using drawnow
        drawnow
        
        % compute spectrum
        h.spect{h.comp} = SpectPwelch(h.EEG, opt);
        
        % scale spectrum (RMS - root mean square)
        h.spect{h.comp}.powspctrm = sqrt(mean(...
            h.EEG.icawinv(:,h.comp).^4)) * h.spect{h.comp}.powspctrm;
        
        % turn power to 10*log10(power)
        h.spect{h.comp}.powspctrm = 10*log10(h.spect{h.comp}.powspctrm);
        
        % update GUI data:
        guidata(h.freq, h);
        
        % =======================================
        % allow for interruption by using drawnow
        drawnow
    end
    
    %% plot spectrum
    % [ ] ADD - check for replot
    hold off
    h.spct.specline = plot(h.freq, h.spect{h.comp}.freq, squeeze(mean(h.spect{h.comp}.powspctrm...
        (:, 1, :), 1)), 'LineWidth', 2.5, 'Color', [0.32, 0.78, 0.22],...
        'LineSmoothing', 'on');
    if ~isempty(h.opt.spect.freqlim)
        set(h.freq, 'XLim', h.opt.spect.freqlim);
    end
    
    h.spct.XLim = get(h.freq, 'XLim');
    h.spct.YLim = get(h.freq, 'YLim');
    
    xlabel('Frequency (Hz)');
    % [ ] ADD - options to plot power or log power etc.
    ylabel('Log-power');
    set(h.freq, 'ButtonDownFcn',@start_getrange);
    
    % =======================================
    % allow for interruption by using drawnow
    drawnow
end

%% plot erpimage
if sum(strcmp('tri', refr)) > 0
    
    % clear tri
    cla(h.tri);
    
    if ~isempty(h.triaxhndls)
        % delete tri co-occuring axes
        delh = h.triaxhndls(2:end);
        delh = delh(~isnan(delh));
        delh = delh(ishandle(delh));
        delete(delh);
    end
    
    axes(h.tri);
    if isempty(h.EEG.times)
        h.EEG.times = linspace(h.EEG.xmin,...
            h.EEG.xmax, h.EEG.pnts);
    end
    
    ei_smooth = h.opt.tri.smooth;
    
    % =======================================
    % allow for interruption by using drawnow
    drawnow
    
    offset = nan_mean(h.EEG.icaact(h.comp,:));
    era = nan_mean(squeeze(h.EEG.icaact(h.comp,:,:))')-offset;
    era_limits=get_era_limits(era);
    % erpimage deletes current axis :( - we must use its altered version
    % remember about 'filt'  = [low_boundary high_boundary] option
    if ~h.opt.tri.filt || length(h.spct.freqsel) < 2
        [~,~,~,~,h.triaxhndls] = erpimage2( h.EEG.icaact(h.comp,:,:) ...
            - offset, ones(1,h.EEG.trials)*10000,...
            h.EEG.times*1000, '', ei_smooth, 1, 'caxis', 2/3, 'cbar', 'erp',...
            'yerplabel', '','erp_vltg_ticks', era_limits);
    elseif length(h.spct.freqsel) == 2
        [~,~,~,~,h.triaxhndls] = erpimage2( h.EEG.icaact(h.comp,:,:) ...
            - offset, ones(1,h.EEG.trials)*10000,...
            h.EEG.times*1000, '', ei_smooth, 1, 'caxis', 2/3, 'cbar', 'erp',...
            'yerplabel', '','erp_vltg_ticks', era_limits, 'filt', ...
            h.spct.freqsel, 'srate', h.EEG.srate);
    end
    
    % =======================================
    % allow for interruption by using drawnow
    drawnow
end

%% ===dipfit===
if sum(strcmp('dip', refr)) > 0 && h.opt.dipf.plot
    if ishandle(h.dipfig)
    % =======================================
    % allow for interruption by using drawnow
    drawnow
    
    % make dipaxis globaly current (eh...)
    axes(h.dipaxis); %#ok<MAXES>
    
    editobj = findobj('parent', h.dipfig, 'userdata', 'editor');
    set(editobj, 'string', num2str(h.comp));
    dipplot(h.dipfig);
    figure(h.figure1);
    end
end

%%

% update GUI data:
guidata(h.freq, h);

function start_getrange(hObject, ev) %#ok<INUSD>
h = guidata(hObject);

if isempty(h.spct.startpoint)
    % if patchobj present - destroy
    if ~isempty(h.spct.patch) && ishandle(h.spct.patch)
        del_ptch(h.spct.patch, []);
        h.spct.endpoint = [];
    end
    
    % get cursor position
    h.spct.startpoint = get(h.freq, 'CurrentPoint');
    h.spct.startpoint = h.spct.startpoint(1, 1);
    
    % plot line there
    Xpos = h.spct.startpoint;
    hold on
    h.spct.line = plot([Xpos, Xpos], h.spct.YLim, 'LineWidth', 2, ...
        'Color', [0.68, 0.42, 0.12]);
    hold off
    
    % retaining axis limits (should be updateICAw in
    % a different way)
    set(h.freq, 'XLim', h.spct.XLim);
    set(h.freq, 'YLim', h.spct.YLim);
    
    guidata(hObject, h);
else
    h.spct.endpoint = get(h.freq, 'CurrentPoint');
    h.spct.endpoint = h.spct.endpoint(1, 1);
    
    % delete line
    if ~isempty(h.spct.line)
        delete(h.spct.line);
        h.spct.line = [];
    end
    
    % find the points
    lowX = min([h.spct.endpoint(1,1), h.spct.startpoint(1,1)]);
    hiX = max([h.spct.endpoint(1,1), h.spct.startpoint(1,1)]);
    h.spct.freqsel = [lowX, hiX];
    
    % plot the patch
    h.spct.patch = patch('Vertices', [lowX, h.spct.YLim(1); hiX, h.spct.YLim(1);...
        hiX, h.spct.YLim(2); lowX, h.spct.YLim(2)], 'Faces', 1:4, 'HitTest', ...
        'on', 'FaceAlpha', 0.3, 'ButtonDownFcn', @del_ptch, ...
        'EdgeColor', 'none', 'FaceColor', h.spct.patchcolor);
    
    % set it below the line?
    % children = get(h.ax, 'Children');
    
    % retaining axis limits (should be updateICAw in
    % a different way)
    set(h.freq, 'XLim', h.spct.XLim);
    set(h.freq, 'YLim', h.spct.YLim);
    
    
    % update the other window
    figscatt(h);
    
    h.spct.startpoint = [];
    h.spct.endpoint = [];
    
    % update erpimage if necessary
    if h.opt.tri.filt
        refresh_comp_explore(h, 'tri');
    end
    
end

% disp(h.startpoint);
guidata(hObject, h);

% update scatter data
function figscatt(h)

if ~isempty(h.spct.freqsel)
    % get freqs:
    for fr = 1:2
        [~, freqadr(fr)] = min((abs(h.spect{h.comp}.freq - h.spct.freqsel(fr)))); %#ok<AGROW>
        % frq(fr) = h.spect.freq(freqadr);
    end
    
    % take average power in freq range across epochs
    h.scattdat = squeeze(mean(h.spect{h.comp}.powspctrm(:,1, ...
        freqadr(1):freqadr(2)), 3));
    
    % CHANGE
    % This should change so that varscatter is updated only through
    % refresh_comp_explore
    varscatter(h.scatter, h.scattdat, 'sd', 3.5, 'label', 'Power');
    
    % update gui data
    guidata(h.scatter, h);
    
end



% deletes patch object
function del_ptch(hObj, e) %#ok<INUSD>

h = guidata(hObj);
if ~isempty(h.spct.patch)
    delete(h.spct.patch)
    h.spct.patch = [];
    h.spct.freqsel = [];
    refr = {'scatter'};
    % update erpimage if necessary
    if h.opt.tri.filt
        refr{2} = 'tri';
    end
    refresh_comp_explore(h, refr{:});
end
guidata(h.scatter, h);

% --- Executes on button press in prev.
function prev_Callback(hObject, eventdata, handles) %#ok<DEFNU,INUSD>
% hObject    handle to prev (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

h = guidata(hObject);

if h.comp > 1
    cla(h.topo);
    
    if ishandle(h.spct.patch)
        delete(h.spct.patch);
        h.spct.patch = [];
    end
    
    h.comp = h.comp - 1;
    guidata(hObject, h);
    refresh_comp_explore(h);
end

% ADD callback for this button:
% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles) %#ok<DEFNU,INUSD>
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global ICAw
h = guidata(hObject);
prevcomp = h.comp;
rejected=[ICAw(h.r).ICA_desc.reject];
pop_selectcomps2(h.EEG, 1:length(h.EEG.icawinv), 'main', h, 'rejects', rejected);

h = guidata(hObject);
nowcomp = h.comp;

if ~isequal(prevcomp, nowcomp)
    guidata(hObject, h)
    
    % clear topoplot - should be later performed
    % just before drawing in refresh_comp_explore
    cla(h.topo);
    refresh_comp_explore(h);
end




% --- Executes on button press in next.
function next_Callback(hObject, eventdata, handles) %#ok<DEFNU,INUSD>

h = guidata(hObject);

if h.comp < size(h.EEG.icaweights,1)
    cla(h.topo);
    
    % delete patch object?
    % [ ] - other option - save info
    %       to recover when back to this
    %       componenet
    if ishandle(h.spct.patch)
        delete(h.spct.patch);
        h.spct.patch = [];
    end
    
    h.comp = h.comp + 1;
    guidata(hObject, h);
    refresh_comp_explore(h);
end


% --- Executes on button press in erpimopt.
function erpimopt_Callback(hObject, eventdata, handles) %#ok<DEFNU,INUSD>

% ADD
% [ ] - option to choose trials
% [ ] - frequency range from freqplot
h = guidata(hObject);
hs = gui_multiedit('ERPimage options', {'smoothing', 'filter frequency range'},...
    {num2str(h.opt.tri.smooth), ''});

% change second option to checkbox
% filtpos = get(hs.edit(2), 'Position');
% delete(hs.edit(2));
% hs.edit(2) = uicontrol('Style', 'checkbox',...
%         'Units', 'pixels', 'Position', ...
%         filtpos, 'String', '',...
%         'FontSize', 12);
set(hs.edit(2), 'Style', 'checkbox',...
    'Value', h.opt.tri.filt);

set(hs.ok, 'Callback', {@tricall, hObject, hs});
set(hs.cancel, 'Callback', 'close(hs.hf)');

% callback function for ERPimage options
function tricall(h, e, hobj, hwin) %#ok<INUSL>
% callback function for erpimopt
hgui = guidata(hobj);
optval = get(hwin.edit(1), 'String');
filt = get(hwin.edit(2), 'Value');
newfilt = ~isequal(filt, hgui.opt.tri.filt);
newsmooth = false;

if newfilt
    hgui.opt.tri.filt = filt;
end

if ~isempty(optval)
    smoothval = str2num(optval); %#ok<ST2NM>
    if isnumeric(smoothval)
        hgui.opt.tri.smooth = smoothval;
        newsmooth = true;
    end
end

if newsmooth || newfilt
    refresh_comp_explore(hgui, 'tri');
end

delete(hwin.hf);

% ADD options for frequency plot (etc.)
% --- Executes on button press in freqdisplayopt.
function freqdisplayopt_Callback(hObject, eventdata, handles) %#ok<INUSD>
% hObject    handle to freqdisplayopt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% for selecting component subtype (type within class)
function compsubtype_Callback(hObject, eventdata, handles) %#ok<DEFNU,INUSD>
% hObject    handle to compsubtype (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
h = guidata(hObject);
global ICAw
strval = get(hObject,'String');
ICAw(h.r).ICA_desc(h.comp).subtype = strval{get(hObject,'Value')};


% --- Executes during object creation, after setting all properties.
function compsubtype_CreateFcn(hObject, eventdata, handles) %#ok<DEFNU,INUSD>
% hObject    handle to compsubtype (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function componotes_Callback(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to componotes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global ICAw
h = guidata(hObject);
ICAw(h.r).ICA_desc(h.comp).notes =  get(hObject,'String');
%        str2double(get(hObject,'String')) returns contents of componotes as a double


% --- Executes during object creation, after setting all properties.
function componotes_CreateFcn(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to componotes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% ADD option to add tags
% ADD option to add a subtype of a component
function addtype_Callback(hObject, eventdata, handles)
% hObject    handle to addtype (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% classifying quality/probability for a given component
% for example:
% class: brain
% subtype: frontomidline theta
% rank: 2
% (means that it seems to be fm theta but we are not sure)
function RatingDropDown_Callback(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to RatingDropDown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns RatingDropDown contents as cell array
%        contents{get(hObject,'Value')} returns selected item from RatingDropDown

global ICAw

h = guidata(hObject);
val = get(hObject, 'Value');
stropt = get(hObject, 'String');
curropt = stropt{val};
ICAw(h.r).ICA_desc(h.comp).rank = curropt;
% now refresh GUI:
refresh_comp_explore(h, 'rank');




% --- Executes during object creation, after setting all properties.
function RatingDropDown_CreateFcn(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to RatingDropDown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Allows to set components as rejected, spared
% considered for rejection
function rejbut_Callback(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to rejbut (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

h = guidata(hObject);

butopt = h.opt.ICA.rejs;
currstr = get(hObject, 'String');

stri = find(strcmp(currstr, butopt));
if stri == 3
    stri = 0;
end

stri = stri + 1;
set(hObject, 'String', h.opt.ICA.rejs{stri});
set(hObject, 'BackGroundColor', h.opt.ICA.rejcol(stri, :));

global ICAw

% introduce changes to ICAw
if stri == 1
    ICAw(h.r).ICA_desc(h.comp).reject = false;
    ICAw(h.r).ICA_desc(h.comp).ifreject = false;
elseif stri == 2
    ICAw(h.r).ICA_desc(h.comp).reject = true;
    ICAw(h.r).ICA_desc(h.comp).ifreject = false;
else
    ICAw(h.r).ICA_desc(h.comp).reject = false;
    ICAw(h.r).ICA_desc(h.comp).ifreject = true;
end
set(h.sumrej, 'String', num2str(sum([ICAw(h.r).ICA_desc.reject])))


% CHANGE below to a more modern version?
%        cooleegplot with reject option here
%        (as Marta suggested), more options?
% --- Executes on button press in comp_signal.
function comp_signal_Callback(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to comp_signal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
h = guidata(hObject);

if isfield(h.opt.plot, 'sigall') && h.opt.plot.sigall;
    eegplot(h.EEG.icaact(:,:,:), 'srate', h.EEG.srate, ...
        'winlength', h.opt.plot.winl ,'limits', [h.EEG.times(1), h.EEG.times(end)],...
        'events', h.EEG.event, 'title', 'Component Timecourse');
else
    eegplot(h.EEG.icaact(h.comp,:,:), 'srate', h.EEG.srate, ...
        'winlength', h.opt.plot.winl ,'limits', [h.EEG.times(1), h.EEG.times(end)],...
        'events', h.EEG.event, 'title', 'Component Timecourse');
end


% Shows changes in EEG data after rejecting
% ADD options to plot only N most affected channels etc.
function eeg_changes_Callback(hObject, eventdata, handles) %#ok<INUSD,DEFNU>
% hObject    handle to eeg_changes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
h = guidata(hObject);
global ICAw
allelecs = 1:size(h.EEG.data,1);
goodelecs = allelecs;
corrs=badchan_ind(ICAw, h.r ,h.EEG.chanlocs);
goodelecs(corrs) = [];

if isfield(h.opt.plot, 'remall') && h.opt.plot.remall;
    rejects = find([ICAw(h.r).ICA_desc.reject]);
else
    rejects = h.comp;
end

% looking for N most affected (in EEG.icawinv)
% compow = EEG.icawinv(:,opts.ind(h.comp));
% [~, sortind] = sort(compow, 'descend');
% Nmost = sortind(1:N);
% then check which channels these are (EEG.icachansind)
% and plot only those channels

% CONSIDER:
% should this be computed or set as persistent
% or smth? Too much memory or too much computation time?
h.EEG2 = pop_subcomp(h.EEG, rejects, 0);


% open window:
eegplot(h.EEG.data(goodelecs,:,:), 'srate', h.EEG.srate, ...
    'winlength', h.opt.plot.winl, 'eloc_file', h.EEG.chanlocs(goodelecs), ...
    'limits', [h.EEG.times(1), h.EEG.times(end)], 'data2',...
    h.EEG2.data(goodelecs,:,:), 'events', h.EEG.event, ...
    'title', ['Signal change after removing IC ', ...
    num2str(rejects)], 'tag', 'befaft');


% === the subfunctions below are copied from EEGlab pop_prop:
function era_limits=get_era_limits(era)
%function era_limits=get_era_limits(era)
%
% function stolen from EEGlab:
% Returns the minimum and maximum value of an event-related
% activation/potential waveform (after rounding according to the order of
% magnitude of the ERA/ERP)
%
% Inputs:
% era - [vector] Event related activation or potential
%
% Output:
% era_limits - [min max] minimum and maximum value of an event-related
% activation/potential waveform (after rounding according to the order of
% magnitude of the ERA/ERP)

mn=min(era);
mx=max(era);
mn=orderofmag(mn)*round(mn/orderofmag(mn));
mx=orderofmag(mx)*round(mx/orderofmag(mx));
era_limits=[mn mx];


function ord=orderofmag(val)
%function ord=orderofmag(val)
%
% function stolen from EEGlab:
% Returns the order of magnitude of the value of 'val' in multiples of 10
% (e.g., 10^-1, 10^0, 10^1, 10^2, etc ...)
% used for computing erpimage trial axis tick labels as an alternative for
% plotting sorting variable

val=abs(val);
if val>=1
    ord=1;
    val=floor(val/10);
    while val>=1,
        ord=ord*10;
        val=floor(val/10);
    end
    return;
else
    ord=1/10;
    val=val*10;
    while val<1,
        ord=ord/10;
        val=val*10;
    end
    return;
end


% --------------------------------------------------------------------
function compotype_panel_ButtonDownFcn(hObject, eventdata, handles)

% dont know if this iss the best way to manage radiobutton groups

h = guidata(hObject);
global ICAw

% get selected
vals = find(get([h.artif, h.brain, h.dontknow], 'Value'));
ICAw(h.r).ICA_desc(h.comp).type = h.opt.ICA.types{vals};
refresh_comp_explore(h, 'compinfo');



% --- Executes on button press in updateICAw.
function updateICAw_Callback(hObject, eventdata, handles)
% hObject    handle to updateICAw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Update handles structure

h = guidata(hObject);
global ICAw
assignin('base', 'ICAw', ICAw);
time=gettime();
set(h.lastUpdate, 'String', ['Last update:' time]);


% --- Executes on button press in plot_opt.
function plot_opt_Callback(hObject, eventdata, handles)
% hObject    handle to plot_opt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
h = guidata(hObject);

plotopts(h);
guidata(hObject, h);


% --- Executes when selected object is changed in compotype_panel.
function compotype_panel_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in compotype_panel
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
h = guidata(hObject);
global ICAw

% get selected
vals = find(cell2mat(get([h.artif, h.brain, h.dontknow], 'Value')));
ICAw(h.r).ICA_desc(h.comp).type = h.opt.ICA.types{vals};
refresh_comp_explore(h, 'compinfo');


% --- Executes during object creation, after setting all properties.
function compotype_panel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to compotype_panel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

%jak kasuje to jest czerwono.


% --- Executes on button press in preview.
function preview_Callback(hObject, eventdata, handles)
% hObject    handle to preview (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
h = guidata(hObject);
global ICAw
allelecs = 1:size(h.EEG.data,1);
goodelecs = allelecs;
corrs=badchan_ind(ICAw, h.r ,h.EEG.chanlocs);
goodelecs(corrs) = [];

if ~isempty(find([ICAw(h.r).ICA_desc.reject]));
    rejects = find([ICAw(h.r).ICA_desc.reject]);
else
    rejects = h.comp;
end

h.EEG2 = pop_subcomp(h.EEG, rejects, 0);

% cooleegplot here?
% MMAgnuski: mysle ze tak
% electrode colors
cpal = color_palette(); nowait = false;
elec_color = mat2cell(cpal, ones(size(cpal,1), 1), 3);

if isfield(h.opt.plot, 'eegplot2on') && h.opt.plot.eegplot2on
    eegplot2(h.EEG2.data(goodelecs,:,:), 'srate', h.EEG.srate, 'color', ...
        elec_color, 'eloc_file', h.EEG.chanlocs(goodelecs),'events',...
        h.EEG.event, 'winlength', h.opt.plot.winl,'limits', ...
        [h.EEG.times(1), h.EEG.times(end)],'title', ...
        'Signal after removing artefacts');
else
    eegplot(h.EEG2.data(goodelecs,:,:), 'srate', h.EEG.srate,'eloc_file',...
        h.EEG.chanlocs(goodelecs),'events',h.EEG.event, 'winlength', ...
        h.opt.plot.winl,'limits',[h.EEG.times(1), h.EEG.times(end)],'title', ...
        'Signal after removing artefacts');
end

