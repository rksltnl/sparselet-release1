function [model, err, nused] = reconstructive_sparselets_model(model, sparselets)

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

toggle_spams(true);

% D is a vocabulary of shared parts, each part is a col in C.
D  = sparselets.dict;
s  = sparselets.size;
l0 = sparselets.l0;
Alpha  = zeros([size(D,2) 0]);

err = 0;
nused = 0;
for i = 7:length(model.filters)
  w = model_get_block(model, model.filters(i));
  w_rec = zeros(size(w));
  for r = 1:s:5
    for c = 1:s:5
      w1 = w(r:r+s-1, c:c+s-1, :);
      [p, alpha, e1, c1] = reconstruct_tile(D, w1, l0, s);
      w_rec(r:r+s-1, c:c+s-1, :) = p;
      err = err + e1;
      nused = nused + c1;
      Alpha(:,end+1) = alpha;
    end
  end

  % HOS: creates new block with `.flip=0' for flipped filters
  %      overwrites unflipped filters with reconstructed filters
  if model.filters(i).flip
    [model, bl] = model_add_block(model, ...
                                  'type', block_types.Filter, ...
                                  'w', w_rec);
    model.filters(i).flip = 0;
    model.filters(i).blocklabel = bl;
  else
    bl = model.filters(i).blocklabel;
    model.blocks(bl).w = w_rec(:);
  end
end
sparselets.Alpha = sparse(Alpha);
model.sparselets = sparselets;

fprintf('%14s: reconstruction error = %f   L = %f\n', ...
        model.class, err, nused);

toggle_spams(false);

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
