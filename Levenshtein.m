% Edited by Xerxes Wu & Peter Sun
function [overall_SE overall_IE overall_DE overall_WER] = Levenshtein(hypothesis_file,annotation_dir)
% Input:
%	hypothesis: The path to file containing the the recognition hypotheses
%	annotation_dir: The path to directory containing the annotations
%			(Ex. the Testing dir containing all the *.txt files)
% Outputs:
%	SE: proportion of substitution errors over all the hypotheses
%	IE: proportion of insertion errors over all the hypotheses
%	DE: proportion of deletion errors over all the hypotheses
%	WER: proportion of overall error in all hypotheses



% gather hypotehses
lines = textread(hypothesis_file, '%s','delimiter','\n');
hypotheses = cell(length(lines), 1);
for i = 1 : length(lines)
    line = strtrim(char(lines{i}));
    line = regexprep(line, '[.,?!]', '');
    words = strsplit(' ', line);
    % hypotheses{i} = words(3 : end);
    hypotheses{i} = words(:);
    % strjoin(hypotheses{i})
end

% gather actual spoken textread
text_files = dir([annotation_dir '/unkn_*.txt']);
references = cell(length(text_files), 1);
for i = 1 : length(text_files)
    filename = ['unkn_' num2str(i) '.txt'];
    line = strtrim(fileread([annotation_dir '/' filename]));
    line = regexprep(line, '[.,?!]', '');
    words = strsplit(' ', line);
    references{i} = words(3 : end);
    % strjoin(references{i})
end

assert(length(hypotheses) == length(references));




overall_S = 0;
overall_I = 0;
overall_D = 0;
overall_n = 0;
for k = 1:length(hypotheses)
    hyp = hypotheses{k};
    ref = references{k};
    % hyp = strsplit(' ', 'how to wreck a nice beach');
    % ref = strsplit(' ', 'how to recognize speech');
    % hyp = strsplit(' ', 'k i t t e n');
    % ref = strsplit(' ', 's i t t i n g');
    % hyp = strsplit(' ', 'S a t u r d a y');
    % ref = strsplit(' ', 'S u n d a y');
    n = length(ref);
    m = length(hyp);

    % Levenshtein distance calculation
    R = zeros(n + 1, m + 1);
    R(1, 2 : end) = Inf;
    R(2 : end, 1) = Inf;
    for i = 2 : n + 1
        for j = 2 : m + 1
            if strcmpi(ref(i - 1), hyp(j - 1))
                substitutionCost = 0;
            else
                substitutionCost = 1;
            end
            R(i, j) = min([R(i - 1, j) + 1 R(i, j - 1) + 1 R(i - 1, j - 1) + substitutionCost]);
        end
    end
    % R

    % backtrack on Levenshtein distance matrix to get SE IE DE WER
    S = 0;
    I = 0;
    D = 0;
    i = n + 1;
    j = m + 1;
    while (i >= 2 && j >= 2)
        if R(i, j - 1) == R(i, j) - 1
            I = I + 1;
            j = j - 1;
        elseif R(i - 1, j) == R(i, j) - 1
            D = D + 1;
            i = i - 1;
        else
            if R(i - 1, j - 1) ~= R(i, j)
                S = S + 1;
            end
            i = i - 1;
            j = j - 1;
        end
    end
    SE = S / n;
    IE = I / n;
    DE = D / n;
    WER = SE + IE + DE;
    disp(['utterance ' num2str(k) ':']);
    disp([SE IE DE WER]);

    % update overall stats
    overall_S = overall_S + S;
    overall_I = overall_I + I;
    overall_D = overall_D + D;
    overall_n = overall_n + n;
end




overall_SE = overall_S / overall_n;
overall_IE = overall_I / overall_n;
overall_DE = overall_D / overall_n;
overall_WER = overall_SE + overall_IE + overall_DE;

disp('overall:');
disp([overall_SE overall_IE overall_DE overall_WER]);


end


