% EEGDB
%
% adds necessary paths to folders
%
% see also: addpath


pth = fileparts(which('eegDb'));
fld = {'database operations', 'dependencies', 'eeglabsubst', 'gui', ...
    'manage marks', 'manage versions', 'path and file utils', ...
    'should be in a branch'};

% add folders to path
for f = fld
    addpath(fullfile(pth, f{1}));
end