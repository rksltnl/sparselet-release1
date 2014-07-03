function [model, conv_time] = gdetect_dp(pyra, model)
% Compute dynamic programming tables used for finding detections.
%   model = gdetect_dp(pyra, model)
%
%   This function implements the dynamic programming algorithm for
%   computing high-scoring derivations using an Object Detection Grammar.
%   It is assumed that the detection grammar is an Isolated Deformation
%   Grammar and therefore contains only structural schemas and deformation
%   schemas.
%
% Return value
%   model   Object model augmented to store the dynamic programming tables
%
% Arguments
%   pyra    Feature pyramid returned by featpyramid.m
%   model   Object model

% AUTORIGHTS
% ---------------------------------------------------------
% Copyright (c) 2014, Hyun Oh Song
% 
% This file is part of the Sparselet code and is available 
% under the terms of the Simplified BSD License provided in 
% LICENSE. Please retain this notice and LICENSE if you use 
% this file (or any portion of it) in your project.
% ---------------------------------------------------------

% cache filter response
%th = tic();
if isfield(model, 'sparselets')
  %model = sparselet_filter_responses(model, pyra);
  [model, conv_time] = sparselet_filter_responses_withroots(model, pyra);
else
  [model, conv_time] = filter_responses(model, pyra);
end
%ts = toc(th);
%fprintf('Filter responses took %.3fs\n', ts);

% compute detection scores
%th = tic();
L = model_sort(model);
%dst_time = 0;
for s = L
  for r = model.rules{s}
    [model, dst] = apply_rule(model, r, pyra.pady, pyra.padx);
    %dst_time = dst_time + dst;
  end
  model = symbol_score(model, s, pyra);
end
% fprintf('Rules took %.3fs\n', toc(th));
% fprintf('DST took %.3fs\n', dst_time);
% done
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute score pyramid for symbol s
function model = symbol_score(model, s, pyra)
% model  object model
% s      grammar symbol

% take pointwise max over scores for each rule with s as the lhs
rules = model.rules{s};
score = rules(1).score;

for r = rules(2:end)
  for i = 1:length(r.score)
    score{i} = max(score{i}, r.score{i});
  end
end
model.symbols(s).score = score;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute score pyramid for rule r
function [model, dst_time] = apply_rule(model, r, pady, padx)
% model  object model
% r      structural|deformation rule
% pady   number of rows of feature map padding
% padx   number of cols of feature map padding

if r.type == 'S'
  model = apply_structural_rule(model, r, pady, padx);
  dst_time = 0;
else
  tt = tic();
  model = apply_deformation_rule(model, r);
  dst_time = toc(tt);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute score pyramid for structural rule r
function model = apply_structural_rule(model, r, pady, padx)
% model  object model
% r      structural rule
% pady   number of rows of feature map padding
% padx   number of cols of feature map padding

% structural rule -> shift and sum scores from rhs symbols
% prepare score for this rule
score      = model.scoretpt;
bias       = model_get_block(model, r.offset) * model.features.bias;
loc_w      = model_get_block(model, r.loc);
loc_f      = loc_feat(model, length(score));
loc_scores = loc_w * loc_f;
for i = 1:length(score)
  score{i}(:) = bias + loc_scores(i);
end

% sum scores from rhs (with appropriate shift and down sample)
for j = 1:length(r.rhs)
  ax = r.anchor{j}(1);
  ay = r.anchor{j}(2);
  ds = r.anchor{j}(3);
  % step size for down sampling
  step = 2^ds;
  % amount of (virtual) padding to halucinate
  virtpady = (step-1)*pady;
  virtpadx = (step-1)*padx;
  % starting points (simulates additional padding at finer scales)
  starty = 1+ay-virtpady;
  startx = 1+ax-virtpadx;
  % score table to shift and down sample
  s = model.symbols(r.rhs(j)).score;
  for i = 1:length(s)
    level = i - model.interval*ds;
    if level >= 1
      % ending points
      endy = min(size(s{level},1), starty+step*(size(score{i},1)-1));
      endx = min(size(s{level},2), startx+step*(size(score{i},2)-1));
      % y sample points
      iy = starty:step:endy;
      oy = sum(iy < 1);
      iy = iy(iy >= 1);
      % x sample points
      ix = startx:step:endx;
      ox = sum(ix < 1);
      ix = ix(ix >= 1);
      % sample scores
      sp = s{level}(iy, ix);
      sz = size(sp);
      % sum with correct offset
      stmp = -inf(size(score{i}));
      stmp(oy+1:oy+sz(1), ox+1:ox+sz(2)) = sp;
      score{i} = score{i} + stmp;
    else
      score{i}(:) = -inf;
    end
  end
end
model.rules{r.lhs}(r.i).score = score;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute score pyramid for deformation rule r
function model = apply_deformation_rule(model, r)
% model  object model
% r      deformation rule

% deformation rule -> apply distance transform
def_w      = model_get_block(model, r.def);
score      = model.symbols(r.rhs(1)).score;
bias       = model_get_block(model, r.offset) * model.features.bias;
loc_w      = model_get_block(model, r.loc);
loc_f      = loc_feat(model, length(score));
loc_scores = loc_w * loc_f;

for i = 1:length(score)  
  
  score{i} = score{i} + bias + loc_scores(i);
  
  % O(n) distance transform + bounded
    [score{i}, Ix{i}, Iy{i}] = fast_bounded_dt(score{i}, def_w(1), def_w(2), ...
                                       def_w(3), def_w(4),4);
end
model.rules{r.lhs}(r.i).score = score;
model.rules{r.lhs}(r.i).Ix    = Ix;
model.rules{r.lhs}(r.i).Iy    = Iy;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute all filter responses (filter score pyramids)
function [model, trs] = filter_responses(model, pyra)
% model    object model
% pyra     feature pyramid

% gather filters for computing match quality responses
filters = cell(model.numfilters, 1);
for i = 1:model.numfilters
  filters{i} = single(model_get_block(model, model.filters(i)));
end

trs = 0;

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
    % Match the sparselets setup: sse version for the variable size roots
    % fconvMM for the parts
    
    %% HOS
%     rr = fconv(pyra.feat{level}, filters, 1, 6);
%     th = tic;
%     rp = fconvMM(pyra.feat{level}, filters(7:end));
%     trs = trs+toc(th);
%     r = cat(2, rr, rp);

      th = tic;
      r = fconv(pyra.feat{level}, filters, 1, length(filters));
      trs = trs+toc(th);
  else
    % More general convolution code to handle non-32-dim features
    % e.g., the HOG-PCA features used by the star-cascade
    r = fconv_var_dim(pyra.feat{level}, filters, 1, length(filters));
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
    %r{i} = padarray(r{i}, [spady spadx], -inf, 'post');
    r{i} = post_pad(r{i}, spady, spadx, -inf);
    fsym = model.filters(i).symbol;
    model.symbols(fsym).score{level} = r{i};
  end
  model.scoretpt{level} = zeros(s);
end
%fprintf('%s total part filter convolution time: %.3fs\n', model.class, trs);
