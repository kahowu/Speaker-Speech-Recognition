% Edited by Xerxes Wu & Peter Sun
function gmms = gmmTrain (dir_train, max_iter, epsilon, M)
% gmmTrain
%
%  inputs:  dir_train  : a string pointing to the high-level
%                        directory containing each speaker directory
%           max_iter   : maximum number of training iterations (integer)
%           epsilon    : minimum improvement for iteration (float)
%           M          : number of Gaussians/mixture (integer)
%
%  output:  gmms       : a 1xN cell array. The i^th element is a structure
%                        with this structure:
%                            gmm.name    : string - the name of the speaker
%                            gmm.weights : 1xM vector of GMM weights
%                            gmm.means   : DxM matrix of means (each column
%                                          is a vector
%                            gmm.cov     : DxDxM matrix of covariances.
%                                          (:,:,i) is for i^th mixture

% Default dimension of input speech sequence
D = 14;
[N, speakers, mfccs] = read_mfcc (dir_train);
gmms = cell (1, N);
gmms = initialize (M, D, N, speakers, mfccs);
gmms = em_step (max_iter, epsilon, gmms, mfccs, M, N, D);
save('../output/gmm-model.mat', 'gmms', '-mat'); 

end

% Get number of speakers, their names and speech. 
function [numSpeakers, speakers, speakerFrames] = read_mfcc (dir_train)
dirs = dir(dir_train);
speakers = {};
% get all speaker names (folder names)
for i = 1:length(dirs)
    % get subdirs excluding '.' and '..'
    if ~strcmp(dirs(i).name, '.') && ~strcmp(dirs(i).name, '..')
        speakers{end+1} = dirs(i).name;
    end
end

numSpeakers = length(speakers);
speakerFrames = cell(numSpeakers, 1);
% get frames data for each speaker
for i = 1:numSpeakers
    speakerDir = [dir_train '/' speakers{i}];
    mfccs = dir([speakerDir '/*.mfcc']);
    frames = [];
    % concatenate vertically all frames data for this speaker
    for j = 1:length(mfccs)
        frames = vertcat(frames, dlmread([speakerDir '/' mfccs(j).name]));
    end
    speakerFrames{i} = frames;
end
end

% Initializes the weight for training 
function gmms = initialize (M, D, N, names, mfccs)
    for l = 1:N
        gmms{l} = struct ();
        s_gmm = gmms {l};
        s_mfcc = mfccs {l};
        s_gmm.name = names {l};
        s_gmm.weights  = zeros (1, M);
        s_gmm.means = zeros (D, M);
        s_gmm.cov = zeros (D, D, M);

        % Use kmeans to initialize the Gaussian means (see 2.3 report for more detail)
        % NOTE: we included "kmeans.m" function because it does not 
        % seem to exist on CDF
        % [idx, C] = kmeans (s_mfcc, M);
        % s_gmm.means = transpose (C);
        
        mfcc_dim = size (s_mfcc);
        for m = 1:M
            s_gmm.weights(m) = 1 / M;
            % Random means initialization 
            s_gmm.means (:, m) = s_mfcc(randi(mfcc_dim(1)), :)';
            s_gmm.cov (:,:, m) = eye(14);
        end
        gmms {l} = s_gmm;
    end
end

% EM step for GMM modles
function gmms = em_step (max_iter, epsilon, gmms, mfccs, M, N, D)
    for l = 1:N
        gmm = gmms{l};
        s_mfcc = mfccs {l};
        prev_L = -Inf;
        improvement = Inf;
        i = 0;
        mfcc_dim = size (s_mfcc); 
        numRows = mfcc_dim (1);
        while i < max_iter && improvement >= epsilon
            prob_m = zeros (numRows, M);
            % Calculate Bm 
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
            weights = repmat(gmm.weights,numRows, 1);
            wx = weights .* prob_m;
            weighted_sum = sum (wx, 2);
            g_priors = wx ./ repmat(weighted_sum, 1, M);
           
            % Calculate likelihood 
            current_L = sum(log(weighted_sum), 1);
                    
            % Weight updates
            priors_sum = sum (g_priors,1);
            gmm.weights = priors_sum / numRows;
            gmm.means = transpose(g_priors' * s_mfcc) ./ repmat (priors_sum, 14, 1);
            temp = (g_priors' * s_mfcc.^2)' ./ repmat (priors_sum, 14, 1);
            covs = temp - gmm.means.^2;           
            for m = 1:M
               gmm.cov (:,:,m) = diag(covs (:, m));
            end
            
            % Updates improvement and set new likelihood
            improvement = current_L - prev_L;
            prev_L = current_L;
                     
            i = i + 1;
        end
        gmms{l} = gmm;
    end
end