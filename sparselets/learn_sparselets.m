function sparselets = learn_sparselets(dict_size, l0, s)
% Learns a dictionary of sparselets
%
% dict_size    dictionary size
% l0           L_0 norm of sparse encoding <= l0
% s            sparselet size

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
    if ~all(mod(model.filters(j).size, s) == 0)
      continue;
    end

    w = model_get_block(model, model.filters(j));
    for r = 1:s:model.filters(j).size(1)-1
      for c = 1:s:model.filters(j).size(2)-1
        w1 = w(r:r+s-1, c:c+s-1, :);
        k = k+1;
        X(:,end+1) = w1(:) ./ norm(w1(:));
      end
    end
  end
end
fprintf('%d training samples\n', size(X,2));

param.K = dict_size;
param.mode = 3;
param.lambda = l0;
param.numThreads = -1;
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

alpha = mexOMP(X, D, param);
if sum(abs(alpha) > 0) > l0
  error('not using <= l0 elements');
end
R = mean(0.5*sum((X-D*alpha).^2));
fprintf('objective function: %f\n',R);
