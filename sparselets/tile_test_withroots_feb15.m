maxNumCompThreads(1);

clear;

load('sparselets/testdata_tile_withroots.mat');
addpath('../bin');

Q_double = double(Q);
model.filtersizes_double    = double(model.filtersizes);
model.num_subfilters_double = double(model.num_subfilters);

th = tic;
for i=1:1000
r_sse_double = tile_sparselet_resps_sse_withroots(Q_double, s_dimy, s_dimx, ...
          model.filtersizes_double, model.num_subfilters_double);
end
t_sse_double = toc(th);
fprintf('Took %.5fs for sse double\n', t_sse_double);

th = tic;
for i=1:1000
r_sse_float = tile_sparselet_resps_sse_withroots_float(Q, s_dimy, s_dimx, ...
          model.filtersizes, model.num_subfilters);
end
t_sse_float = toc(th);
fprintf('Took %.5fs for sse float\n', t_sse_float);

th = tic;
for i=1:1000
r_blas_float = tile_sparselet_resps_blas_withroots_float_singleTH(Q, s_dimy, s_dimx, ...
          model.filtersizes, model.num_subfilters);  
end
t_blas_float = toc(th);
fprintf('Took %.5fs for blas float\n', t_blas_float);

        
fprintf('The difference in L2 bet. sse float vs sse double is %.3f\n', ...
    norm( [r_sse_float{:}] - [r_sse_double{:}] ));
  
fprintf('The difference in L2 bet. blas float vs sse double is %.3f\n', ...
    norm( [r_blas_float{:}] - [r_sse_double{:}] ));  