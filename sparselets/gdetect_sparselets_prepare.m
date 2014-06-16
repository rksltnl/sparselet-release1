function [pyra, ts] = gdetect_sparselets_prepare(im, model)

% Compute sparselet responses (shared between all classes)

% AUTORIGHTS
% ---------------------------------------------------------
% Copyright (c) 2014, Hyun Oh Song
% 
% This file is part of the Sparselet code and is available 
% under the terms of the Simplified BSD License provided in 
% LICENSE. Please retain this notice and LICENSE if you use 
% this file (or any portion of it) in your project.
% ---------------------------------------------------------

im = color(im);
pyra = featpyramid(im, model);
th = tic;
for level = 1:pyra.num_levels
  pyra.sparselets.R{level} = ...
    fconv_sparselets(pyra.feat{level}, model.sparselets);
end
ts = toc(th);
