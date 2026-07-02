function results = runAcousticsTests()
%RUNACOUSTICSTESTS  Run the +acoustics validation test suite.
%   RESULTS = RUNACOUSTICSTESTS() runs every test under tests/ and returns
%   the matlab.unittest results array. Run it from the repository root:
%       runAcousticsTests
%
%   Equivalent to  runtests('tests').
    here = fileparts(mfilename('fullpath'));
    results = runtests(fullfile(here, 'tests'));
    disp(table(results));
end
