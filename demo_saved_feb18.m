% June 12th, 2014 Hyun Oh Song
% Purpose of this script is to demonstrate the correctness and speedup of
% using MKL's float sparse matrix * dense float matrix multiplication versus
% Matlab's *double* sparse matrix * dense double matrix multiplication.

% On my mac, average speedup is about 2.5X (singleCompThread) and the
% norm difference is nil.

load('convolution_data.mat', 'pyra', 'model');
maxNumCompThreads(1);

num_classes = 20;
%num_classes = 1;
num_filt = size(model.sparselets.Alpha,2);

%% original sparselets
trs = 0;
Q0 = {};
for cid = 1:num_classes
  for level = 1:length(pyra.feat)   
    % Compute subfilter responses 
    th = tic;
    Q0{level} = pyra.sparselets.R{level}*model.sparselets.Alpha;
    %Q = fast_sparse_mult(pyra.sparselets.R{level}, model.sparselets.Alpha);
    trs = trs+toc(th);
  end
end
fprintf('matlab double sparse sparselets took %.3f sec\n', trs);


%% original sparselets mkl blas preparsed
R_single = {};
for i = 1:length(pyra.sparselets.R)
  R_single{i} = single(pyra.sparselets.R{i});
end
alpha_single = single(full(model.sparselets.Alpha));

trs_mkl = 0;
[A_nnz, ja, ia] = parse_sparse_matrix_float(model.sparselets.Alpha);
A_dims = size(model.sparselets.Alpha);
Q_sparse = {};
for cid = 1:num_classes
  for level = 1:length(pyra.feat)   
    % Compute subfilter responses 
    th = tic;
    Q_sparse{level} = matrix_sparse_ATB_csc_parsed_float(A_nnz, ja, ia, A_dims, R_single{level});
    %Q_sparse{level}= reshape(macmkl_sparsemm_test(...
    %  A_nnz, ja, ia, A_dims, R_single{level}), size(R_single{level},1), num_filt);
                 
    trs_mkl = trs_mkl + toc(th);
  end
end
fprintf('mkl blas preparsed float transposed sparselets took %.3f sec\n', trs_mkl);
fprintf('\nmkl float sparse speed up over matlab double sparse %.3f\n\n', trs/trs_mkl);

%% Compare the correctness results
for lev = 1 : length(Q0)
  fprintf('[pyra lev %02d] diff: %f\n', lev, norm(Q0{lev} - reshape(Q_sparse{lev},[],num_filt)));
end
