function r = fconvMM(feat, filters)

[filt_dimy, filt_dimx, filt_dimz] = size(filters{1});
num_filt = length(filters);
filt_dim = filt_dimy*filt_dimx*filt_dimz;

Mfilt = zeros(filt_dim, num_filt);
for i = 1:num_filt
  f = shiftdim(filters{i}, 2);
  Mfilt(:,i) = reshape(f, [filt_dim 1]);
end

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
R = Mfeat*Mfilt;
%toc;

for i = 1:num_filt
  r{i} = double(reshape(R(:,i), [out_dimy out_dimx]));
end
