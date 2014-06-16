function sparselets = learn_sparselets_with_roots(dict_size, l0, s)

% Learns a dictionary of sparselets with roots
%
% dict_size    dictionary size
% l0           L_0 norm of sparse encoding <= l0
% s            sparselet size

% AUTORIGHTS
% ---------------------------------------------------------
% Copyright (c) 2014, Hyun Oh Song
% 
% This file is part of the Sparselet code and is available 
% under the terms of the Simplified BSD License provided in 
% LICENSE. Please retain this notice and LICENSE if you use 
% this file (or any portion of it) in your project.
% ---------------------------------------------------------

toggle_spams(true);

conf = voc_config();
classes = conf.pascal.VOCopts.classes;

ncls = length(classes);
X = zeros(s*s*conf.features.dim, 0);

k = 0;
for i = 1:ncls
    cls = classes{i};
    load(['VOC2007/' cls '_final']);
    for j = 1:model.numfilters
        
        % Only take unflipped filters
        %if model.filters(j).flip == 0        
        w = model_get_block(model, model.filters(j));

        % if any dim is not divisible by 3
        if ~all(mod(model.filters(j).size, s) == 0)
            [height, width,~] = size(w);

            %pad height
            if mod(height,3)==2
                w = padarray(w, [1,0,0], 'post');
            elseif mod(height,3)==1
                w = padarray(w, [1,0,0], 'both');
            end

            %pad width
            if mod(width,3)==2
                w = padarray(w, [0,1,0], 'post');
            elseif mod(width,3)==1
                w = padarray(w, [0,1,0], 'both');
            end
        end    

        [height, width, ~] = size(w);
        for r = 1:s:height-1
            for c = 1:s:width-1
                w1 = w(r:r+s-1, c:c+s-1, :);
                k = k+1;
                X(:,end+1) = w1(:) ./ norm(w1(:));
            end
        end        
        %end
    end
end
fprintf('%d training samples\n', size(X,2));

param.K = dict_size;
param.mode = 3;
param.lambda = l0;
param.numThreads = 5;
param.iter = 100;

[D, m] = mexTrainDL(X, param);
Dmat = D;
for i = 1:size(D,2)
  D(:,i) = D(:,i) ./ norm(D(:,i));

  d = D(:,i);
  d = reshape(d, [s s conf.features.dim]);
  d = shiftdim(d, 2);
  Dmat(:,i) = d(:);
end

show_error(X, D, l0);

sparselets.dict = single(D);
sparselets.Dmat = single(Dmat);
sparselets.size = s;
sparselets.l0   = l0;

toggle_spams(false);


% ------------------------------------------------------------------------
function show_error(X, D, l0)
% ------------------------------------------------------------------------
% test reconstruction of training data

param.L = l0;
param.eps = 0.001;
param.numThreads = 5;


alpha = mexOMP(X, D, param);
if sum(abs(alpha) > 0) > l0
  error('not using <= l0 elements');
end
R = mean(0.5*sum((X-D*alpha).^2));
fprintf('objective function: %f\n',R);