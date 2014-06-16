function learn_sparselets_study_initialization(dict_size, l0, s)
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
param.numThreads = 20;
param.iter = 50;

%% try manual initialization of dictionary
% random matrix
%param.D = randn(size(X,1), dict_size);
% random subset of the data

total_epochs = 10;
mean_error = zeros(total_epochs,1);
std_error  = zeros(total_epochs,1);

total_initializations = 50;
param.verbose = false;
param.batch = true; % use batch learning

iterations = [1, 10:10:500];

for epoch = 1: length(iterations)
    fprintf('epoch %i\n', epoch);
    % monitor every 10th iteration
    param.iter = iterations(epoch);
    
    % try 100 different initilizations
    error_list = zeros(total_initializations, 1);
    for run = 1:total_initializations
        param.D = X(:, randperm(size(X,2), dict_size));

        [D, m] = mexTrainDL(X, param);
        Dmat = D;
        for i = 1:size(D,2)
          D(:,i) = D(:,i) ./ norm(D(:,i));

          d = D(:,i);
          d = reshape(d, [s s conf.features.dim]);
          d = shiftdim(d, 2);
          Dmat(:,i) = d(:);
        end
        error_list(run) = show_error(X, D, l0);
    end
    mean_error(epoch) = mean(error_list);
    std_error(epoch)  = std(error_list);
end

% close all;
% figure(1); hold on;
% errorbar([1, 10:10:500], mean_error, std_error, '.', 'markersize', 10);
% plot([1, 10:10:500], mean_error, 'k--');
% set(gca, 'Xtick', [1, 10:10:500]);
% xlim([0 505]);
% grid on;
% xlabel('Iterations'); ylabel('Objective function');
% hold off; set(gcf, 'color', 'w');
% addpath(genpath('~/Desktop/export_fig/'));
% export_fig('500batchIterations.pdf', '-painters');
iters = [1, 10:10:500];
save([num2str(dict_size),'_', num2str(l0),'_500batchInits.mat'],...
    'iters', 'mean_error', 'std_error');

toggle_spams(false);

% ------------------------------------------------------------------------
function R= show_error(X, D, l0)
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
