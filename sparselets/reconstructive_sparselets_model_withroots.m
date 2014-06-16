function [model, err, nused] = reconstructive_sparselets_model_withroots(...
    model, sparselets)

% F is the stacked feature map matrix (each row is a convolution window)
% D is the sparselet bank (each column is a sparselet)
% R = F*D is the shared sparselet response
%
% A is a sparse matrix of activation vectors 
%   starting from filter index 7 each group of 4 columns reconstructs the 4
%   tiles in a part filter
%
% Q = R*A are the reconstructed subfilter scores for all filters
%
% Now for each filter, we extract the corresponding 4 columns of Q
% reshape the responses into score maps, shift them and add them

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

% D is a vocabulary of shared parts, each part is a col in C.
D  = sparselets.dict;
s  = sparselets.size;
l0 = sparselets.l0;
Alpha  = zeros([size(D,2) 0]);
err = 0;
nused = 0;

% loop over all filters
% if root, pad zeros, set `shiftwindow', end
% get alpha for each sub-filters
for i=1:length(model.filters)
    w = model_get_block(model, model.filters(i));
    
    % filter id 1~6 are roots
    if i <= 6
        [height, width,~] = size(w);
        shift = [ 0 0 ];
        
        %pad height
        if mod(height,3)==2
            w = padarray(w, [1,0,0], 'post');        
        elseif mod(height,3)==1
            w = padarray(w, [1,0,0], 'both');
            shift(1) = -1;
        end

        %pad width
        if mod(width,3)==2
            w = padarray(w, [0,1,0], 'post');
            % HOS: shift right if flipped filter
            if model.filters(i).flip, shift(2) = -1; end
        elseif mod(width,3)==1
            w = padarray(w, [0,1,0], 'both');
            shift(2) = -1;
        end
        model.rules{model.start}(i).shiftwindow = shift;  
        [height, width,~] = size(w);        
        model.filters(i).size = [height, width];
    end
    
    w_rec = zeros(size(w));
    for r=1:s:size(w_rec,1)-1
        for c=1:s:size(w_rec,2)-1
            w1 = w(r:r+s-1, c:c+s-1, :);
            [p, alpha, e1, c1] = reconstruct_tile(D, w1, l0, s);
            w_rec(r:r+s-1, c:c+s-1, :) = p;
            err = err + e1;
            nused = nused + c1;            
            Alpha(:,end+1) = alpha;
        end
    end
    
    %
    if model.filters(i).flip
        [model, bl] = model_add_block(model, ...
                                  'type', block_types.Filter, ...
                                  'w', w_rec);
        model.filters(i).flip = 0;
        model.filters(i).blocklabel = bl;
    else
        bl = model.filters(i).blocklabel;
        model.blocks(bl).w = w_rec(:);
        if i <= 6
            model.blocks(bl).shape = size(w_rec);
            dim = prod(size(w_rec));
            model.blocks(bl).dim   = dim;
            model.blocks(bl).lb    = -inf*ones(dim,1);
        end
    end
end

sparselets.Alpha  = sparse(Alpha);
% HOS: Feb 13 store float A_nnz, ja, ia 1D arrays
[A_nnz, ja, ia]   = parse_sparse_matrix_float(sparse(Alpha));
sparselets.A_nnz  = A_nnz;
sparselets.ja     = ja;
sparselets.ia     = ia;
sparselets.A_dims = size(Alpha);

model.sparselets  = sparselets;

% fprintf('%14s: reconstruction error = %f   L = %f\n', ...
%         model.class, err, nused);

toggle_spams(false);

% modify minsize maxsize
model.maxsize = [0 0];
model.minsize = [100 100];
for i=[1,3,6]
    height = model.filters(i).size(1);
    width  = model.filters(i).size(2);
    if model.maxsize(1) < height, model.maxsize(1) = height; end
    if model.maxsize(2) < width , model.maxsize(2) = width;  end
    if model.minsize(1) > height, model.minsize(1) = height; end
    if model.minsize(2) > width , model.minsize(2) = width;  end
end

% precompute filter sizes into a 2 by 54 matrix
model.filtersizes = zeros(2, model.numfilters);
for i=1:model.numfilters
    model.filtersizes(:, i) = model.filters(i).size;
end

% precompute number of subfilters y and x into a 2 by 54 matrix
model.num_subfilters = zeros(2, model.numfilters);
for i=1:model.numfilters
    num_subfilters = model.filters(i).size ./ [s s];
    model.num_subfilters(:, i) = num_subfilters;
end

% HOS: Feb 13 convert to single
model.filtersizes = single(model.filtersizes);
model.num_subfilters = single(model.num_subfilters);

    
function [p, alpha, err, nused] = reconstruct_tile(D, w, l0, s)

param.L = l0;
param.eps = 0.001;

D = double(D);
worig = w;

wnorm = norm(w(:));
w = w(:) / wnorm;
alpha = mexOMP(w, D, param);
nused = full(sum(abs(alpha) > 0));
if nused > l0
  error('not using <= l0 elements');
end
p = D*alpha;
pnorm = norm(p);
nf = size(D,1)/(s*s);
p = reshape(wnorm*p/pnorm, [s s nf]);
alpha = wnorm*alpha/pnorm;
assert(sum(abs(p(:) - D*alpha)) < 1e-8);

d = worig - p;
err = 0.5*sum(d(:).^2);    
    