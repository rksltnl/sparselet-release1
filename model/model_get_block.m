function w = model_get_block(m, obj)
% Get parameters from a block.
%   w = model_get_block(m, obj)
%
% Return value
%   w       Parameters (shaped)
%
% Arguments
%   m       Object model
%   obj     A struct with a blocklabel field

% Backwards compatibility
%if ~isfield(m, 'blocks')
%  w = obj.w;
%  return;
%end

% AUTORIGHTS
% ---------------------------------------------------------
% Copyright (c) 2014, Hyun Oh Song
% 
% This file is part of the Sparselet code and is available 
% under the terms of the Simplified BSD License provided in 
% LICENSE. Please retain this notice and LICENSE if you use 
% this file (or any portion of it) in your project.
% ---------------------------------------------------------

bl    = obj.blocklabel;
shape = m.blocks(bl).shape;
type  = m.blocks(bl).type;
w     = reshape(m.blocks(bl).w, shape);

% Flip (if needed) according to block type
switch(type)
  case block_types.Filter
    if obj.flip
      w = flipfeat(w);
    end
  case block_types.PCAFilter
    if obj.flip
      w = reshape(m.blocks(bl).w_flipped, shape);
    end
  case block_types.SepQuadDef
    if obj.flip
      w(2) = -w(2);
    end
  %case block_types.Other
end
