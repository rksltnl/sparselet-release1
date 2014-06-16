maxNumCompThreads(1);


clear;

Q = randn(1,1);
load('sparselets/testdata.mat');
load('sparselets/model.mat');
s = 3;

th = tic;
rssefloat = tile_sparselet_resps_sse_float(Q, s_dimy, s_dimx, out_dimy, out_dimx,...
     num_sub_filters_roots);
t_mex_ssefloat = toc(th);
fprintf('Took %.5fs for mex sse float tiling\n', t_mex_ssefloat);

th = tic;
rsse = tile_sparselet_resps_sse(Q, s_dimy, s_dimx, out_dimy, out_dimx,...
     num_sub_filters_roots);
t_mex_sse = toc(th);
fprintf('Took %.5fs for mex sse tiling\n', t_mex_sse);

th = tic;
rblas = tile_sparselet_resps_blas_singleTH(Q, s_dimy, s_dimx, out_dimy, out_dimx,...
     num_sub_filters_roots);
t_mex_blas = toc(th);
fprintf('Took %.5fs for mex blas tiling\n', t_mex_blas);

Q_float = single(Q);
th = tic;
rblasfloat = tile_sparselet_resps_blas_infloat_outdouble_singleTH(Q_float, s_dimy, s_dimx, out_dimy, out_dimx,...
     num_sub_filters_roots);
t_mex_blas = toc(th);
fprintf('Took %.5fs for mex float in float out blas tiling\n', t_mex_blas);

th = tic;
r = tile_sparselet_resps(Q, s_dimy, s_dimx, out_dimy, out_dimx,...
     num_sub_filters_roots);
t_mex = toc(th);
fprintf('Took %.5fs for mex tiling\n', t_mex);

th = tic;
fi = 7; rs = cell(48,1);
for i = num_sub_filters_roots+1:4:size(Q,2)

    P0 = reshape(Q(:,i), [s_dimy s_dimx]);
    P0 = P0(1:out_dimy, 1:out_dimx);

    P1 = reshape(Q(:,i+1), [s_dimy s_dimx]);
    P0 = P0 + P1(1:out_dimy, s+(1:out_dimx));

    P1 = reshape(Q(:,i+2), [s_dimy s_dimx]);
    P0 = P0 + P1(s+(1:out_dimy), 1:out_dimx);

    P1 = reshape(Q(:,i+3), [s_dimy s_dimx]);
    P0 = P0 + P1(s+(1:out_dimy), s+(1:out_dimx));

    rs{fi-7+1} = P0;
    fi = fi+1;
end

t_matlab = toc(th);
fprintf('Took %.5fs for matlab tiling\n', t_matlab);

fprintf('The difference in L2 bet. mex float vs matlab is %.3f\n', ...
    norm( [rssefloat{:}] - [rs{:}] ));

fprintf('The difference in L2 bet. mex vs matlab is %.3f\n', ...
    norm( [r{:}] - [rs{:}] ));

fprintf('The difference in L2 bet. sse vs matlab is %.3f\n', ...
    norm( [rsse{:}] - [rs{:}] ));
  
fprintf('The difference in L2 bet. blas vs matlab is %.3f\n', ...
    norm( [rblas{:}] - [rs{:}] )); 
  
fprintf('The difference in L2 bet. blas vs matlab is %.3f\n', ...
    norm( [rblasfloat{:}] - [rs{:}] )); 