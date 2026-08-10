% getAIO  Fetch the latest MECH9325 acoustics toolkit from GitHub and launch it.
%
%   Keep a copy of this file on your USB (or in Documents/MATLAB). On any
%   computer with internet, just type:
%
%       getAIO
%
%   and it downloads the newest version of the toolkit to a temporary folder,
%   switches into it, clears MATLAB's cached copy of the old code, and opens
%   the app. Because the URL lives in this file you never have to paste it
%   (which is what corrupts the quotes), and you never touch git.
%
%   No internet (e.g. the exam PCs)? Don't use this - run the app from your USB
%   copy of the whole folder instead:  cd into it, then  AcousticsApp
aio_branch = 'claude/matlab-aio-sync';    % the branch getAIO tracks (edit to switch)
aio_url    = ['https://github.com/AirTrafficController/MECH9325-MATLAB-AIO/' ...
              'archive/refs/heads/' aio_branch '.zip'];
aio_dest   = tempname;

fprintf('Downloading latest acoustics toolkit (%s)...\n', aio_branch);
try
    zipfile = websave([aio_dest '.zip'], aio_url);
catch err
    error('getAIO:download', ['Could not download the toolkit - are you online?\n' ...
        'On an offline PC, run the app from your USB copy instead: cd into the\n' ...
        'MECH9325-MATLAB-AIO folder, then type  AcousticsApp\n\n(details: %s)'], ...
        err.message);
end
unzip(zipfile, aio_dest);

% GitHub names the extracted folder "<repo>-<branch with / -> ->".
folder = fullfile(aio_dest, ['MECH9325-MATLAB-AIO-' strrep(aio_branch, '/', '-')]);
cd(folder);

% Close any app window still open from a previous run FIRST. While an
% AcousticsApp object exists, MATLAB refuses to reload its class ("Objects of
% 'AcousticsApp' class exist. Cannot clear this class"), then launches a
% half-old/half-new definition that errors (e.g. "Unrecognized method
% 'buildConvert'"). Deleting the figures removes those objects so the reload
% can happen.
try, delete(findall(groot, 'Type', 'figure')); catch, end

% Drop MATLAB's in-memory copy of the PREVIOUS version so the freshly
% downloaded files are actually used - otherwise a cached findCalculator (and
% its persistent search index) or a cached AcousticsApp class can shadow the
% update, which is exactly what makes it "look like it didn't update".
clear functions %#ok<CLFUNC>
clear classes   %#ok<CLCLS>
rehash

fprintf('Loaded latest version from: %s\n', pwd);
AcousticsApp
