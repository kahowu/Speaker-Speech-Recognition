% Edited by Xerxes Wu & Peter Sun
% Classify and compute likelihood over the whole testing set
function gmmClassify ()
    % Modify D and M here if different numbers are used
    D = 14;
    M = 8; 
    
    % Directory path of the testing folder
    dir_test = '/h/u1/cs401/speechdata/Testing';
    load ('../output/gmm-model.mat');
    [numSpeakers, speakers, speakerFrames] = read_mfcc (dir_test);
    topNames = classifyTestingSet (gmms, numSpeakers, speakers, speakerFrames, M, D); 

end

% Read mfccs into memory
function [numSpeakers, speakers, speakerFrames] = read_mfcc (dir_test)
    mfccs = dir([dir_test '/*.mfcc']);
    numSpeakers = length(mfccs);

    speakers = cell(numSpeakers, 1);
    speakerFrames = cell(numSpeakers, 1);
    for i = 1:numSpeakers
        speakers{i} = regexprep(mfccs(i).name, '.mfcc$', '');
        speakerFrames{i} = dlmread([dir_test '/' mfccs(i).name]);
    end

end



% Return the top 5 names with the highest likelihood and calculate accuracy
% over 
function topNames = classifyTestingSet (gmms, numSpeakers, speakers, speakerFrames, M, D)
    actualNames = textread('../Testing/testing_IDs', '%s','delimiter','\n');
    topNames = cell (numSpeakers, 1);
    for u = 1:numSpeakers;
        s_unknown = speakers {u};
        s_mfcc = speakerFrames {u};
        [likelihood, names] = classify (gmms, s_mfcc, M, D);
        [sortedValues,sortIndex] = sort(cell2mat (likelihood),'descend');  
        maxIndex = sortIndex(1:5);
        maxValues = sortedValues(1:5);
        maxNames = cell (1, 5);
        for i = 1:length(maxIndex)
            index = maxIndex (i);
            maxNames {i} = names {index};
        end
        index = str2num(regexprep(s_unknown, 'unkn_', ''));
        topNames{index} = maxNames{1};
        
        f = fopen(['../output/' s_unknown '.lik'], 'w');
        for v = 1:length(maxNames)
            fprintf(f, '%s\n', [maxNames{v} ': ' num2str(maxValues(v))]);
        end
        fclose(f);
    end
    
    f = fopen('../output/GuessedIDs.txt', 'w');
    for i = 1:length(topNames)
        fprintf(f, '%s\n', topNames{i});
    end

    topNames = topNames(1:length(actualNames));
    accuracy = sum(cellfun(@strcmp, actualNames, topNames)) / length(actualNames);
    fprintf('The accuracy is %f\n', accuracy); 
end 


% Classify a single speaker's speech sequence
function [likelihood, names] = classify (gmms, s_mfcc, M, D)
    N = length (gmms);
    likelihood = cell (1, N);
    names = cell (1, N);
    for l = 1:N
        gmm = gmms{l};
        mfcc_dim = size (s_mfcc); 
        numRows = mfcc_dim (1);
        % Calculate bm
        for m = 1:M
            diff_sq = zeros (mfcc_dim);
            m_mean = transpose(gmm.means (:, m));
            m_cov = gmm.cov (:, :, m);
            m_cov = transpose(diag (m_cov));
            m_cov_r = repmat(m_cov,numRows, 1);
            m_mean_r = repmat(m_mean,numRows, 1);
            diff = s_mfcc - m_mean_r;     
            diff_sq = diff.^2;
            numerator = exp((-1/2) * sum ((diff_sq ./ m_cov_r), 2));
            dominator = ((2 * pi)^(D/2)) * sqrt(prod (m_cov, 2));
            bm = numerator / dominator;
            prob_m (:, m) = bm;
        end

        % Calculate gaussian priors
        weights = repmat(gmm.weights, numRows, 1);
        wx = weights .* prob_m;
        weighted_sum = sum (wx, 2);
        g_priors = wx ./ repmat(weighted_sum, 1, M);

        % Calculate likelihood 
        current_L = sum(log(weighted_sum), 1);
        likelihood {l} = current_L;
        names {l} = gmm.name;
    end
end


