function C = constants()
%CONSTANTS  Course physical constants for MECH9325 acoustics.
%   C = ACOUSTICS.CONSTANTS() returns a struct of the reference quantities
%   used throughout the toolkit:
%       PREF  reference sound pressure       2e-5 Pa
%       WREF  reference sound power          1e-12 W
%       IREF  reference sound intensity      1e-12 W/m^2
%       RHOC  characteristic impedance of air 415 rayls
%       CAIR  speed of sound in air at 20 C  343 m/s
%
%   Example:
%       C = acoustics.constants;   C.RHOC   % -> 415
    C = struct( ...
        'PREF', 2e-5, ...
        'WREF', 1e-12, ...
        'IREF', 1e-12, ...
        'RHOC', 415, ...
        'CAIR', 343);
end
