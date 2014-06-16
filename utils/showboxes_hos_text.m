function showboxes_hos_text(im, boxes, color, string, draw, linewidth, linestyle)

if nargin <= 4
  draw = true;
end

if nargin <=5
  linewidth = 1;
end

if nargin <= 6
  linestyle = '-';
end

% AUTORIGHTS
% ---------------------------------------------------------
% Copyright (c) 2014, Hyun Oh Song
% 
% This file is part of the Sparselet code and is available 
% under the terms of the Simplified BSD License provided in 
% LICENSE. Please retain this notice and LICENSE if you use 
% this file (or any portion of it) in your project.
% ---------------------------------------------------------

% doing this initializes the image. set to false in consequent runs.
% if this function is to be called multiple times on the same image.
if draw
  image(im);
  axis image;
  axis off;
end

if ~isempty(boxes)
  for j = 1:size(boxes,1)

    x1 = boxes(j,1);
    y1 = boxes(j,2);
    x2 = boxes(j,3);
    y2 = boxes(j,4);

    line([x1 x1 x2 x2 x1 x1]', [y1 y2 y2 y1 y1 y2]', 'color', color, ...
                         'linewidth', linewidth, 'linestyle', linestyle);

    text(round(x1+5), round(y1+16), string, ...
        'backgroundcolor', color, 'fontsize', 15, ...
        'fontweight', 'bold');                   
  end
end
drawnow;