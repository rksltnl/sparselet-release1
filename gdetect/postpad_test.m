maxNumCompThreads(1);

clear;

load('../sparselets/testdata_tile_withroots.mat');
addpath('../bin');

Q_double = double(Q);
model.filtersizes_double    = double(model.filtersizes);
model.num_subfilters_double = double(model.num_subfilters);

%% SSE double tile + postpad double
th0 = tic;
t_pad_double = 0;
for level=1:1000
  r = tile_sparselet_resps_sse_withroots(Q_double, s_dimy, s_dimx, ...
            model.filtersizes_double, model.num_subfilters_double);


  s = [-inf -inf];
  for i = 1:length(r)
    s = max([s; size(r{i})]);
  end
  for i = 1:length(r)
    spady = s(1) - size(r{i},1);
    spadx = s(2) - size(r{i},2);

    th = tic();
    r{i} = post_pad(r{i}, spady, spadx, -inf);
    t_pad_double = t_pad_double + toc(th);
  end
end
fprintf('Took %.5fs for postpad double\n', t_pad_double);
t_sse_double = toc(th0);
fprintf('Took %.5fs for sse double + postpad double\n', t_sse_double);

%% SSE float tile + postpad float
th0 = tic;
t_pad_float = 0;
for level=1:1000
  r_float = tile_sparselet_resps_sse_withroots_float(Q, s_dimy, s_dimx, ...
            model.filtersizes, model.num_subfilters);
  s = [-inf -inf];
  for i = 1:length(r_float)
    s = max([s; size(r_float{i})]);
  end
  for i = 1:length(r_float)
    spady = s(1) - size(r_float{i},1);
    spadx = s(2) - size(r_float{i},2);

    th = tic();
    r_float{i} = post_pad_float(r_float{i}, spady, spadx, -inf);
    t_pad_float = t_pad_float + toc(th);
  end
end
fprintf('Took %.5fs for postpad float\n', t_pad_float);
t_sse_float = toc(th0);
fprintf('Took %.5fs for sse float + postpad float\n', t_sse_float);

%%        
fprintf('The difference in L2 bet. sse float vs sse double is %.3f\n', ...
    norm( [r_float{:}] - [r{:}] ));
