function visualize_sparselets(sparselets)

D = sparselets.dict;
s = sparselets.size;
f = size(D,1)/(s*s);

im = mkim(reshape(D(:,1), [s s f]));
imsz = size(im);
Dsz = size(D,2);
n = ceil(sqrt(Dsz));
I = zeros(imsz(1)*n, imsz(1)*n, 'uint8');

k = 1;
for i = 1:n
  for j = 1:n
    im = mkim(reshape(D(:,k), [s s f]));
    I(1+(i-1)*imsz(1):1+(i-1)*imsz(1)+imsz(1)-1, ...
      1+(j-1)*imsz(2):1+(j-1)*imsz(2)+imsz(2)-1) = im;
    k = k + 1;
    if k > Dsz
      break;
    end
  end
  if k > Dsz
    break;
  end
end

clf;
imagesc(I); 
colormap gray;
axis equal;
axis off;



function im = mkim(w)
% make picture of root filter
pad = 2;
bs = 20;
w = foldHOG(w);
scale = max(w(:));
im = HOGpicture(w, bs);
%im = imresize(im, 2);
im = uint8(im * (255/scale));
im = padarray(im, [pad pad], 128);
