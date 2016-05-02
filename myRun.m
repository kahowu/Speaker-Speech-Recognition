% Edited by Xerxes Wu & Peter Sun
function myRun(d, hmms)

dir_test = '/h/u1/cs401/speechdata/Testing';
samples_per_mfcc_line = 128;

mfccs = dir([dir_test '/*.mfcc']);
phns = dir([dir_test '/*.phn']);
assert(length(mfccs) == length(phns));

phonemes = fieldnames(hmms);

correct_count = 0;
total_count = 0;
% get frames data for each speaker
tic;
for j = 1:length(mfccs)
    assert(strcmp(strrep(mfccs(j).name, '.mfcc', ''), strrep(phns(j).name, '.phn', '')));
    phn_file = [dir_test '/' phns(j).name];
    phn_lines = textread(phn_file, '%s','delimiter','\n');
    mfcc_file = [dir_test '/' mfccs(j).name];
    mffc_mat = dlmread(mfcc_file);
    for k = 1:length(phn_lines)
        words = strsplit(' ', phn_lines{k});
        start_sample = str2num(char(words(1)));
        end_sample = str2num(char(words(2)));
        start_line = start_sample / samples_per_mfcc_line + 1;
        end_line = max(start_line, end_sample / samples_per_mfcc_line - 1);
        assert(start_line <= end_line);
        actual_phoneme = char(words(3));
        if strcmp(actual_phoneme, 'h#')
            actual_phoneme = 'sil';
        end
        data = mffc_mat(start_line:end_line, 1:d)';

        likelihoods = zeros(length(phonemes), 1);
        for i = 1:length(phonemes)
            likelihoods(i) = loglikHMM(hmms.(char(phonemes(i))), data);
        end
        [max_val, max_index] = max(likelihoods);
        guessed_phoneme = phonemes(max_index);
        if strcmp(actual_phoneme, guessed_phoneme)
            correct_count = correct_count + 1;
        end
        total_count = total_count + 1;
    end
end

accuracy = correct_count / total_count
toc;
