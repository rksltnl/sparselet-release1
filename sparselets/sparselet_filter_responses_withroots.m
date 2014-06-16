%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute all filter responses (filter score pyramids)
function [model, trs] = sparselet_filter_responses_withroots(model, pyra)
% model    object model
% pyra     feature pyramid

%disp('Using sparselets');
trs = 0;
%hos
t_tile = 0;
t_pad  = 0;
%t_root_tile = 0; t_part_tile = 0;

%pyra.valid_levels(:) = false;
%pyra.valid_levels([15 15-model.interval]) = true;

% gather filters for computing match quality responses
% filters = cell(model.numfilters, 1);
% for i = 1:model.numfilters
%   filters{i} = single(model_get_block(model, model.filters(i)));
% end

for level = 1:length(pyra.feat)
  if ~pyra.valid_levels(level)
    % not processing this level, so set default values
    model.scoretpt{level} = 0;
    for i = 1:model.numfilters
      model.symbols(model.filters(i).symbol).score{level} = -inf;
    end
    continue;
  end

  % compute filter response for all filters at this level
  if size(pyra.feat{level},3) == 32
    % root responses
%    tth = tic;
%    rr = fconv(pyra.feat{level}, filters, 1, 6);
%    troot = troot + toc(tth);
%    % baseline convolution
%    th = tic;
%    rb = fconv(pyra.feat{level}, filters, 7, length(filters));
%    tb = toc(th);
%
%    th = tic;
%    rp = fconvMM(pyra.feat{level}, filters(7:end));
%    tp = toc(th);
%    fprintf('fconvsee %.3fs  fconvMM %.3fs %.3fx\n', tb, tp, tb/tp);

%    % Compute sparselet responses (this would be done once for all classes)
%    th = tic;
%    R = fconv_sparselets(pyra.feat{level}, model.sparselets);
%    ts = toc(th);

    %R = pyra.sparselets.R{level};

    % Compute subfilter responses 
    th = tic;
    %Q = R*model.sparselets.Alpha;
    Q = reshape(matrix_sparse_ATB_csc_parsed_float(...
         model.sparselets.A_nnz, model.sparselets.ja, model.sparselets.ia,...
         model.sparselets.A_dims, pyra.sparselets.R{level}), ...
         size(pyra.sparselets.R{level},1), model.sparselets.A_dims(2));
       
    trs = trs+toc(th);

    % Collect subfilter responses into filter responses
    %th = tic;
    [feat_dimy, feat_dimx, ~] = size(pyra.feat{level});
    % sparselet/subfilter response size
    s = model.sparselets.size;
    s_dimy = feat_dimy - s + 1;
    s_dimx = feat_dimx - s + 1;

    %%
%     r = tile_sparselet_resps_sse_withroots(Q, s_dimy, s_dimx, ...
%             model.filtersizes, model.num_subfilters);
    
    % HOS: Feb15 expects model.filtersizes and model.num_subfilters
    %         to be single
    r = tile_sparselet_resps_sse_withroots_float(Q, s_dimy, s_dimx, ...
            model.filtersizes, model.num_subfilters);

    %t_tile = t_tile + toc(th);  
        
%     %%
%     th = tic();
%     % reconstruct root responses
%     num_sub_filters_roots = size(Q,2)- 4*6*8;
%     k = 1;
%     rr = cell(6,1);
%     for i = 1:6
%       filt_dim = model.filters(i).size; %[height, width]
%       out_dimy = feat_dimy - filt_dim(1) + 1;
%       out_dimx = feat_dimx - filt_dim(2) + 1;
%       
%       % 0   | ... | k
%       % --------------
%       % k+1 | ... | n
%       
%       num_sub_filters = prod(model.filters(i).size ./ [s s]);
%       num_sub_filters_per_row = filt_dim(2)/s;
%       P0 = zeros(out_dimy, out_dimx);
%       for j = 1:num_sub_filters
%           P = reshape(Q(:, k), [s_dimy s_dimx]);
%           dx = mod(j-1, num_sub_filters_per_row) * s;
%           dy = floor((j-1)/num_sub_filters_per_row) * s;
%           P0 = P0 + P(dy+(1:out_dimy), dx+(1:out_dimx));
%           k = k+1;
%       end
%       rr{i} = P0;
%     end
%     t_root_tile = t_root_tile + toc(th);
%     
%     %%
%     out_dimy = feat_dimy - 5;
%     out_dimx = feat_dimx - 5;
%     % reconstruct part responses
% 
%     th = tic;
%     rs = tile_sparselet_resps_sse(Q, s_dimy, s_dimx, out_dimy, out_dimx, ...
%         num_sub_filters_roots);
% 
% %     fi = 7; rs = cell(48,1);
% %     for i = num_sub_filters_roots+1:4:size(Q,2)
% %       filt_dim = model.filters(fi).size;
% %       out_dimy = feat_dimy - filt_dim(1) + 1;
% %       out_dimx = feat_dimx - filt_dim(2) + 1;
% % 
% %       % 0 | 1
% %       % --+--
% %       % 2 | 3
% % 
% %       P0 = reshape(Q(:,i), [s_dimy s_dimx]);
% %       P0 = P0(1:out_dimy, 1:out_dimx);
% % 
% %       P1 = reshape(Q(:,i+1), [s_dimy s_dimx]);
% %       P0 = P0 + P1(1:out_dimy, s+(1:out_dimx));
% % 
% %       P1 = reshape(Q(:,i+2), [s_dimy s_dimx]);
% %       P0 = P0 + P1(s+(1:out_dimy), 1:out_dimx);
% % 
% %       P1 = reshape(Q(:,i+3), [s_dimy s_dimx]);
% %       P0 = P0 + P1(s+(1:out_dimy), s+(1:out_dimx));
% % 
% %       rs{fi-7+1} = P0;
% %       fi = fi+1;
% %     end
%     
%     t_part_tile = t_part_tile + toc(th);
% %    fprintf('%.3fx total: %.3fs  ammort: %.3fs  dict: %.3fs  subfilt recon: %.3fs  tiling: %.3fs\n', ...
% %            tp/(trs+tr), ts+trs+tr, trs+tr, ts, trs, tr);
%     r = cat(1, rr, rs);
   
  else
    error('unsupported');
  end
  %th = tic();
  % find max response array size for this level
  s = [-inf -inf];
  for i = 1:length(r)
    s = max([s; size(r{i})]);
  end
  % set filter response as the score for each filter terminal
  %th = tic();
  for i = 1:length(r)
    % normalize response array size so all responses at this 
    % level have the same dimension
    spady = s(1) - size(r{i},1);
    spadx = s(2) - size(r{i},2);
    % HOS: really bug prone but sticking in 
    %      float array to double array conversion in this pad function.
    r{i} = post_pad_floatin_doubleout(r{i}, spady, spadx, -inf);     
    %r{i} = post_pad_float(r{i}, spady, spadx, -inf); 
    
    fsym = model.filters(i).symbol;
    model.symbols(fsym).score{level} = r{i};
  end
  model.scoretpt{level} = zeros(s);
  %t_pad = t_pad + toc(th);
end

% fprintf(['%s total conv time: %.3fs (%.3fs sparse mult + %.3fs tile)\n'...
%     ' maxsize/padding time: %.3fs\n'], ...
%     model.class, trs+t_tile, trs, t_tile, t_pad);