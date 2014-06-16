function showboxes_hos_simple(im, boxes, color, draw, linewidth, linestyle)

if nargin <= 3
  draw = true;
end

if nargin <=4
  linewidth = 1;
end

if nargin <= 5
  linestyle = '-';
end

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

  end
end
drawnow;