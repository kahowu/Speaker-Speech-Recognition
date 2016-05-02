% Edited by Xerxes Wu & Peter Sun

function hmms = myTrain(training_size_shrink_factor, M, Q, d_dim, output_name)
    dir_train = '/h/u1/cs401/speechdata/Training';
    samples_per_mfcc_line = 128;
    dirs = dir(dir_train);
    speakers = {};
    % get all speaker names (folder names)
    for i = 1:length(dirs)
        % get subdirs excluding '.' and '..'
        if ~strcmp(dirs(i).name, '.') && ~strcmp(dirs(i).name, '..')
            speakers{end+1} = dirs(i).name;
        end
    end

    data = struct();
    % get frames data for each speaker
    for i = 1:length(speakers)
        speakerDir = [dir_train '/' speakers{i}];
        mfccs = dir([speakerDir '/*.mfcc']);
        phns = dir([speakerDir '/*.phn']);
        assert(length(mfccs) == length(phns));

        for j = 1:length(mfccs)
            assert(strcmp(strrep(mfccs(j).name, '.mfcc', ''), strrep(phns(j).name, '.phn', '')));
            phn_file = [speakerDir '/' phns(j).name];
            phn_lines = textread(phn_file, '%s','delimiter','\n');
            mfcc_file = [speakerDir '/' mfccs(j).name];
            mffc_mat = dlmread(mfcc_file);
            for k = 1:length(phn_lines)
                words = strsplit(' ', phn_lines{k});
                start_sample = str2num(char(words(1)));
                end_sample = str2num(char(words(2)));
                start_line = start_sample / samples_per_mfcc_line + 1;
                end_line = max(start_line, end_sample / samples_per_mfcc_line - 1);
                assert(start_line <= end_line);
                phoneme = char(words(3));
                if strcmp(phoneme, 'h#')
                    phoneme = 'sil';
                end
                if ~isfield(data, phoneme)
                    data.(phoneme) = {};
                end
                data.(phoneme){end+1} = mffc_mat(start_line:end_line, 1:d_dim)';
            end
        end
    end

    phonemes = fieldnames (data);
    hmms = struct ();
    for i = 1:length (phonemes)
        p = phonemes {i};
        hmms.(p) = struct ();
        p_data = data.(p);
        p_data = p_data (1:min(max(M, int64(training_size_shrink_factor * length(p_data))), length(p_data)));
        HMM = initHMM(p_data, M, Q);
        HMM = trainHMM(HMM, p_data, 15);
        hmms.(p) = HMM; 
    end

    save(['../output/' output_name '.mat'], 'hmms', '-mat'); 

return
