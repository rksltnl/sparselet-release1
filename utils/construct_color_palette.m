function color_palette_heat = construct_color_palette(num_grid)
% ------------------------------------------------------------------------
% return num_grid hot to cold color palette in [r,g,b]
% return in 0 ~ 1 double

% AUTORIGHTS
% ---------------------------------------------------------
% Copyright (c) 2014, Hyun Oh Song
% 
% This file is part of the Sparselet code and is available 
% under the terms of the Simplified BSD License provided in 
% LICENSE. Please retain this notice and LICENSE if you use 
% this file (or any portion of it) in your project.
% ---------------------------------------------------------


color_palette_heat = [];

% swap min and max if cold to hot is desired
minimum = 0;
maximum = 255;

for value = floor(linspace(maximum, minimum, num_grid))

  halfmax = (minimum + maximum)/2;
  b = floor(max(0, 255*(1 - value/halfmax)));
  r = floor(max(0, 255*(value/halfmax - 1)));
  g = 255 - b - r;
  color_palette_heat = [color_palette_heat; r, g, b];
end
color_palette_heat = color_palette_heat ./ 255;