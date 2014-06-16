%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute all filter responses (filter score pyramids)
function model = sparselet_filter_responses(model, pyra)
% model    object model
% pyra     feature pyramid

%disp('Using sparselets');
trs = 0;
tr = 0;
%hos
troot = 0;
%pyra.valid_levels(:) = false;
%pyra.valid_levels([15 15-model.interval]) = true;

% gather filters for computing match quality responses
filters = cell(model.numfilters, 1);
for i = 1:model.numfilters
  filters{i} = single(model_get_block(model, model.filters(i)));
end

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
    tth = tic;
    rr = fconv(pyra.feat{level}, filters, 1, 6);
    troot = troot + toc(tth);
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

    R = pyra.sparselets.R{level};

    % Compute subfilter responses 
    th = tic;
    Q = R*model.sparselets.Alpha;
    trs = trs+toc(th);

    % Collect subfilter responses into filter responses
    th = tic;
    [feat_dimy, feat_dimx, feat_dimz] = size(pyra.feat{level});
    % sparselet/subfilter response size
    s = model.sparselets.size;
    s_dimy = feat_dimy - s + 1;
    s_dimx = feat_dimx - s + 1;

    fi = 7;
    for i = 1:4:size(Q,2)
      filt_dim = model.filters(fi).size;
      out_dimy = feat_dimy - filt_dim(1) + 1;
      out_dimx = feat_dimx - filt_dim(2) + 1;

      % 0 | 1
      % --+--
      % 2 | 3

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
    tr = tr+toc(th);
%    fprintf('%.3fx total: %.3fs  ammort: %.3fs  dict: %.3fs  subfilt recon: %.3fs  tiling: %.3fs\n', ...
%            tp/(trs+tr), ts+trs+tr, trs+tr, ts, trs, tr);

    r = cat(2, rr, rs);
  else
    error('unsupported');
  end
  % find max response array size for this level
  s = [-inf -inf];
  for i = 1:length(r)
    s = max([s; size(r{i})]);
  end
  % set filter response as the score for each filter terminal
  for i = 1:length(r)
    % normalize response array size so all responses at this 
    % level have the same dimension
    spady = s(1) - size(r{i},1);
    spadx = s(2) - size(r{i},2);
    r{i} = padarray(r{i}, [spady spadx], -inf, 'post');
    fsym = model.filters(i).symbol;
    model.symbols(fsym).score{level} = r{i};
  end
  model.scoretpt{level} = zeros(s);
end
%fprintf(['%s total part filter convolution time: %.3fs\n' ...
%         '  (%.3fs sparse mult + %.3fs tiling)\n'], model.class, trs+tr, trs, tr);
fprintf(['%s total root time: %.3fs\n' ...
         ' part time: %.3fs\n' ...
         '  (%.3fs sparse mult + %.3fs tiling)\n'], model.class, troot, trs+tr, trs, tr);