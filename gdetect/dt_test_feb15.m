maxNumCompThreads(1);

addpath('../bin');
load('testdata_dt.mat');

score_double = {};
for i=1:length(score)
  score_double{i} = double(score{i});
end

% Ix_double = {}; Iy_double = {};
% th = tic();
% for p=1:1000
% for i = 1:length(score)
% %for i = 1:1
%   % O(n) distance transform + bounded
%   [score_double{i}, Ix_double{i}, Iy_double{i}] = ...
%         fast_bounded_dt(score_double{i}, def_w(1), def_w(2), ...
%                                        def_w(3), def_w(4),4);                     
% end
% end
% fprintf('Took %.5f secs for dt\n', toc(th));

Ix_single = {}; Iy_single = {};
def_w_single = single(def_w);
range_single = single(4);
large_image_float = repmat(score{1}, 50, 50);

th = tic();
for p=1:1
%for i = 1:length(score)
for i = 1:1
  % O(n) distance transform + bounded
  [score{i}, Ix_single{i}, Iy_single{i}] = ...
        fast_bounded_dt_float_profiler(large_image_float, def_w_single(1), def_w_single(2), ...
                               def_w_single(3), def_w_single(4), range_single);                     
end
end
fprintf('Took %.5f secs for dt float\n', toc(th));