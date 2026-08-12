function reportSearch(query, expected, note)
%REPORTSEARCH  File a ticket when findCalculator shows a wrong/irrelevant tool.
%   REPORTSEARCH(query) runs the LOCAL search on QUERY, shows what it ranked,
%   and appends a ticket (timestamp, question, the top-3 it gave) to
%   searchTickets.csv next to this file. Works fully offline, so a mis-ranking
%   is captured even on a USB / exam-lab machine, ready to be reviewed later.
%
%   REPORTSEARCH(query, expectedTool) also records which calculator you think
%   it SHOULD have picked. REPORTSEARCH(query, expectedTool, note) adds a note.
%
%   Examples:
%     reportSearch("noise dose over an 8 hour shift")
%     reportSearch("noise dose over an 8 hour shift", "Noise dose")
%     reportSearch("...", "Noise dose", "ranked Leq #1, should be Noise dose")
%
%   A maintainer then reviews searchTickets.csv and, for each good ticket,
%   fixes the keywords and adds a row to searchQuestions.csv so checkSearch
%   guards it forever (see checkSearch.m). Students can share their
%   searchTickets.csv (email/USB, or commit it) to pool reports.
    if nargin < 1 || strlength(strtrim(string(query))) == 0
        fprintf('Usage: reportSearch("the question", "Expected tool (optional)", "note (optional)")\n');
        return;
    end
    if nargin < 2, expected = ""; end
    if nargin < 3, note = ""; end
    query    = strtrim(string(query));
    expected = strtrim(string(expected));
    note     = strtrim(string(note));

    % --- run the local search to capture what it currently ranks --------
    s = [];
    try
        evalc('s = findCalculator(query);');     % suppress the pipeline printout
    catch
    end
    top = strings(1,0);
    if ~isempty(s) && ~isempty(s(1).matches)
        top = string({s(1).matches.tool});
    end
    topStr = strjoin(top(1:min(3,numel(top))), " | ");

    % --- append the ticket ----------------------------------------------
    here = fileparts(mfilename('fullpath'));
    file = fullfile(here, 'searchTickets.csv');
    isNew = ~isfile(file);
    fid = fopen(file, 'a');
    if fid < 0
        error('reportSearch:open', 'Could not open %s for writing.', file);
    end
    closer = onCleanup(@() fclose(fid));
    if isNew
        fprintf(fid, 'Timestamp,Query,RankedTop3,ExpectedTool,Note\n');
    end
    ts = char(datetime('now','Format','yyyy-MM-dd HH:mm:ss'));
    fprintf(fid, '%s,%s,%s,%s,%s\n', ...
        csvq(ts), csvq(char(query)), csvq(char(topStr)), csvq(char(expected)), csvq(char(note)));

    % --- confirm to the student -----------------------------------------
    fprintf('Ticket saved to %s\n', file);
    fprintf('   Question   : %s\n', clip(query));
    if ~isempty(top)
        fprintf('   It ranked  : %s\n', topStr);
    end
    if strlength(expected) > 0
        fprintf('   You expect : %s\n', expected);
    end
    fprintf('Thanks - share searchTickets.csv with whoever maintains the toolkit;\n');
    fprintf('each ticket becomes a keyword fix plus a checkSearch regression row.\n');
end

% ======================================================================
function s = csvq(str)
    s = ['"' strrep(str, '"', '""') '"'];   % CSV-quote (double embedded quotes)
end

function s = clip(x)
    s = char(x);
    if numel(s) > 80, s = [s(1:79) char(8230)]; end
end
