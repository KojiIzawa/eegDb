function ICAw = CUTTING_DIPfitize_KG(ICAw, varargin)

% =================
% info for hackers:
% this version can be run without problems
% in S106, ICACS, Warsaw, Poland - on the first 
% computer counting from left wall (while facing 
% window)

% TODOs:
% [ ] universalize :) 

%% options
% above this residiual variance 
% dipoles are rejected
rv_thrsh = 100;
% path to save temporary ICAw's to
% (the last one being final)
save_path = ['E:\Dropbox\MATLAB scripts & projects\',...
    'EEGlab common (1)\magic\14112013\'];

% other options may come soon



%% ==welcome to the code==

% prepath:
% prepath = '\\Swps-01222w\c';
% addpath(['D:\Dropbox\Dropbox\MATLAB scripts & ',...
%     'projects\EEGlab common (1)']);

% transform vector
transf = [0.092784, -13.3654, -1.9004, 0.10575, 0.003062,...
    -1.5708, 10.0078, 10.0077, 10.1331];
hdmf = ['D:\\MATLAB stuff\\eeglab12_0_2_5b\\plugins\\dipfit2.2\\',...
    'standard_BEM\\standard_vol.mat'];
mrif = ['D:\\MATLAB stuff\\eeglab12_0_2_5b\\plugins\\dipfit2.2\\',...
    'standard_BEM\\standard_mri.mat'];
chanf = ['D:\\MATLAB stuff\\eeglab12_0_2_5b\\plugins\\dipfit2.2\\',...
    'standard_BEM\\elec\\standard_1005.elc'];
remel = {'E62', 'E63'};

for r = 1:length(ICAw)
    %% preliminary checks
    % check if ICA weights present
    ICApres = ~isempty(ICAw(r).icaweights);
    
    % if no ICA weights then check next file
    if ~ICApres
        continue
    end
    clear ICApres
    
%     % add prepath if not present
%     if ~strcmp(prepath, ICAw(r).filepath(1:length(prepath)))
%         sepind = strfind(ICAw(r).filepath, '\');
%         ICAw(r).filepath = [prepath, ICAw(r).filepath(sepind(1):end)];
%     end
    
    %% recover and check
    % recover EEG
    EEG = recoverEEG(ICAw, r, 'local');
    
    % check channels
    allchn = 1:length(EEG.chanlocs);
    
    % remove E62 and E63
    remind = zeros(1, length(remel));
    elstep = 0;
    for el = 1:length(remel)
        elind = strcmp(remel{el}, {EEG.chanlocs.labels});
        
        if sum(elind) == 1
            elstep = elstep + 1;
            remind(elstep) = find(elind);
        end
    end
    
    % trim if some were not found:
    remind = remind(1:elstep);
    clear elstep el elind
    
    % remove these channels and badchannels:
    allchn(union(ICAw(r).badchan, remind)) = [];
    goodchan = allchn;
    clear allchn remind
    
    %% DIPfit
    % dipfit options
    EEG = pop_dipfit_settings( EEG, 'hdmfile', hdmf, 'coordformat', 'MNI',...
        'mrifile', mrif, 'chanfile', chanf, 'coord_transform', transf,...
        'chansel', goodchan);
    clear goodchan
    
    % locate components:
    EEG = pop_multifit(EEG, 1 : size(EEG.icaweights, 1),...
        'threshold', rv_thrsh, 'rmout', 'on', 'plotopt', ...
        {'normlen' 'on'});
    
    % we are interested only in EEG.dipfit
    ICAw(r).dipfit = EEG.dipfit;
    clear EEG
    
    % save temporary file:
    save([save_path, 'ICAw_dipfit.mat'], 'ICAw');
end