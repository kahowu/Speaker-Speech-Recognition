% Edited by Xerxes Wu & Peter Sun
% 4.1
%
dir_test = '/h/u1/cs401/speechdata/Testing';
username = '64a7dd24-cf9d-4092-ab52-8ca18136c6e0';
password = 'kejNL72NPKn0';
file_transcript = '../output/ibm_transcript4.1.txt';

mfccs = dir([dir_test '/*.flac']);
transcripts = cell(length(mfccs), 1);
for i = 1:length(mfccs)
    index = regexp(mfccs(i).name, '^unkn_(\d+)\.flac$', 'tokens');
    index = str2num(char(index{1}));
    flac_file = [dir_test '/' mfccs(i).name];
    cmd = ['/bin/bash --login -c ''env LD_LIBRARY_PATH="" DYLD_LIBRARY_PATH="" curl -u ' username ':' password ' -X POST --header "Content-Type: audio/flac" --header "Transfer-ncoding: chunked" --data-binary @' flac_file  '  "https://stream.watsonplatform.net/speech-to-text/api/v1/recognize?continuous=true"'''];
    [status, result] = unix(cmd);
    result = regexp(result, '"transcript": "(.*?)"', 'tokens');
    result = char(result{1});
    transcripts{index} = result;
end

f = fopen(file_transcript, 'w');
for i = 1:length(transcripts)
    fprintf(f, '%s\n', transcripts{i});    
end
fclose(f);
%}


% 4.2
%
% text to speech
dir_test = '/h/u1/cs401/speechdata/Testing';
file_IDs = '../output/GuessedIDs.txt';
username = 'fd9bbc0c-421b-4198-8fc2-faaf2e785147';
password = 'EEamIkkVUfSW';
output_dir = '../output';

% f = fopen('../output/references.txt', 'w');
ids = textread(file_IDs, '%s','delimiter','\n');
for i = 1:length(ids)
    name = ['unkn_' num2str(i)];
    words = strsplit(' ', strtrim(fileread([dir_test '/' name '.txt'])));
    text = strjoin(words(3:end));
    % fprintf(f, '%s\n', text);
    voice = 'en-US_MichaelVoice';
    if ids{i}(1) ~= 'M'
        voice = 'en-US_LisaVoice';
    end
    output_file = [output_dir '/ibm_' name '.flac'];
    cmd = ['/bin/bash --login -c ''env LD_LIBRARY_PATH="" DYLD_LIBRARY_PATH="" curl -u ' username ':' password ' -X POST -H "content-type: application/json" -d "{\"text\":\"' text '\"}" "https://stream.watsonplatform.net/text-to-speech/api/v1/synthesize?accept=audio%2Fflac&voice=' voice '" > ' output_file '''']
    unix(cmd);
end
%}

%
% speech to text
dir_test = '../output';
username = '64a7dd24-cf9d-4092-ab52-8ca18136c6e0';
password = 'kejNL72NPKn0';
file_transcript = '../output/ibm_transcript4.2.txt';

mfccs = dir([dir_test '/*.flac']);
transcripts = cell(length(mfccs), 1);
for i = 1:length(mfccs)
    i
    index = regexp(mfccs(i).name, '^ibm_unkn_(\d+)\.flac$', 'tokens');
    index = str2num(char(index{1}));
    flac_file = [dir_test '/' mfccs(i).name];
    cmd = ['/bin/bash --login -c ''env LD_LIBRARY_PATH="" DYLD_LIBRARY_PATH="" curl -u ' username ':' password ' -X POST --header "Content-Type: audio/flac" --header "Transfer-ncoding: chunked" --data-binary @' flac_file  '  "https://stream.watsonplatform.net/speech-to-text/api/v1/recognize?continuous=true"'''];
    [status, result] = unix(cmd);
    result = regexp(result, '"transcript": "(.*?)"', 'tokens');
    result = char(result{1});
    transcripts{index} = result;
end

f = fopen(file_transcript, 'w');
for i = 1:length(transcripts)
    fprintf(f, '%s\n', transcripts{i});    
end
fclose(f);
%}
