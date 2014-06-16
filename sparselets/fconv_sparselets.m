function R = fconv_sparselets(feat, sparselets)

% AUTORIGHTS
% ---------------------------------------------------------
% Copyright (c) 2014, Hyun Oh Song
% 
% This file is part of the Sparselet code and is available 
% under the terms of the Simplified BSD License provided in 
% LICENSE. Please retain this notice and LICENSE if you use 
% this file (or any portion of it) in your project.
% ---------------------------------------------------------

D = sparselets.Dmat;
s = sparselets.size;

filt_dimy = s;
filt_dimx = s;
filt_dimz = size(D,1)/(s*s);
num_filt = size(D,2);
filt_dim = filt_dimy*filt_dimx*filt_dimz;

[feat_dimy, feat_dimx, feat_dimz] = size(feat);

out_dimy = feat_dimy - filt_dimy + 1;
out_dimx = feat_dimx - filt_dimx + 1;

%tic;
Mfeat = zeros(out_dimy*out_dimx, filt_dim, 'single');
for x = 0:filt_dimx-1
  for y = 0:filt_dimy-1
    Mfeat(:, (x*filt_dimy+y)*filt_dimz+(1:filt_dimz)) = ...
      reshape(feat(y+(1:out_dimy), x+(1:out_dimx),:), [out_dimy*out_dimx filt_dimz]);
  end
end
%toc;

%tic;
%R = double(Mfeat*D);
% HOS: Feb 13, 2014 everything is single(float) now.
R = Mfeat*D;
%toc;
