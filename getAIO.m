% getAIO  Fetch the latest MECH9325 acoustics toolkit from GitHub and launch it.
%
%   Keep a copy of this file on your USB (or in Documents/MATLAB). On any
%   computer with internet, just type:
%
%       getAIO
%
%   and it downloads the newest version of the toolkit to a temporary folder,
%   switches into it, and opens the app. Because the URL lives in this file you
%   never have to paste it (which is what corrupts the quotes).
%
%   No internet (e.g. the exam PCs)? Don't use this - run the app from your USB
%   copy of the whole folder instead:  cd into it, then  AcousticsApp
aio_url  = 'https://github.com/AirTrafficController/MECH9325-MATLAB-AIO/archive/refs/heads/claude/matlab-aio-sync.zip';
aio_dest = tempname;
fprintf('Downloading acoustics toolkit...\n');
unzip(websave([aio_dest '.zip'], aio_url), aio_dest);
cd(fullfile(aio_dest, 'MECH9325-MATLAB-AIO-claude-matlab-aio-sync'));
fprintf('Loaded from: %s\n', pwd);
clear classes %#ok<CLCLS>
AcousticsApp
