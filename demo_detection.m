function demo_detection

% Run sparselet multiclass detection demo.
%
% This demo is single threaded for a fair comparison between the DPM code.
%  Both the DPM code and Sparselet code uses float, SSE enabled convolutions.
%
% Sparselet code uses mkl_scscmm_() Intel MKL Blas level 3 function for 
%  floating point sparse matrix multiplication. This Blas function is about
%  2.5X faster than MATLAB's sparse matrix multiplication in single
%  threaded mode.

% AUTORIGHTS
% ---------------------------------------------------------
% Copyright (c) 2014, Hyun Oh Song
% 
% This file is part of the Sparselet code and is available 
% under the terms of the Simplified BSD License provided in 
% LICENSE. Please retain this notice and LICENSE if you use 
% this file (or any portion of it) in your project.
% ---------------------------------------------------------

maxNumCompThreads(1);

conf = voc_config();

% ------------------------------------------------------------------------
% Learn the sparselets
dict_size      = 128;
lambda_0       = 16;
sparselet_size = 3;

save_file = sprintf('sparselets/data/sparselets_withroots_%d_%d_%d', ...
                    dict_size, lambda_0, sparselet_size);
try
  load(save_file);
  fprintf('Loaded sparselets, |D|: %d, L0: %d\n', dict_size, lambda_0);
catch
  fprintf('Learning sparselets\n');
  sparselets = learn_sparselets_with_roots(dict_size, lambda_0, sparselet_size);
  save(save_file, 'sparselets');
end
% ------------------------------------------------------------------------


% ------------------------------------------------------------------------
% Convert the models to sparselet models
classes = conf.pascal.VOCopts.classes;
    
sparselet_models = cell(length(classes), 1);
orig_models = cell(length(classes), 1);
for i = 1:length(classes)
  cls = classes{i};
  load(['VOC2007/' cls '_final']);
  orig_models{i} = model;
  sparselet_models{i} = reconstructive_sparselets_model_withroots(model, sparselets);
end

% ------------------------------------------------------------------------
% Run detections on example images

image_filename = '004637.jpg';
test(image_filename, sparselet_models, orig_models, conf);
fprintf('\nPress any key to continue with demo'); pause; fprintf('...ok\n\n');

image_filename = '001998.jpg';
test(image_filename, sparselet_models, orig_models, conf);
fprintf('\nPress any key to continue with demo'); pause; fprintf('...ok\n\n');

image_filename = '000358.jpg';
test(image_filename, sparselet_models, orig_models, conf);
fprintf('\nPress any key to continue with demo'); pause; fprintf('...ok\n\n');

image_filename = '000313.jpg';
test(image_filename, sparselet_models, orig_models, conf);



% ------------------------------------------------------------------------
% Detection engine
function test(image_filename, sparselet_models, orig_models, conf) 
% ------------------------------------------------------------------------

im = imread(image_filename);

% Detection parameters
max_dets_per_image  = 100;
detection_threshold = -0.01;

% Precompute sparselet filter responses
[pyra, t_precom] = gdetect_sparselets_prepare(im, sparselet_models{1});

t_sparselet_det  = t_precom;
t_sparselet_conv = 0; 
for i = 1:length(sparselet_models)
  th = tic();
  [ds{i}, bs{i}, conv_time] = gdetect(...
              pyra, sparselet_models{i}, detection_threshold, max_dets_per_image);
  det_time = toc(th);          
  keep = nms(ds{i}, 0.2);
            
  ds{i} = ds{i}(keep, :);
  bs{i} = bs{i}(keep, :);
  
  t_sparselet_det  = t_sparselet_det  + det_time;
  t_sparselet_conv = t_sparselet_conv + conv_time; 
end

% Plot detection results
color_palette_heat = construct_color_palette(length(sparselet_models));

fig1 = figure(1);
screen_size = get(0, 'screensize');
set(fig1, 'outerposition', [1, screen_size(4)/2, screen_size(3)*0.75, screen_size(4)/2]);

clf; subplot(1,2,1); image(im); title('Sparselet detections');
for i = 1:length(sparselet_models)
  if ~isempty(bs{i})
    this_class = conf.pascal.VOCopts.classes{i};
    subplot(1,2,1);
    showboxes_hos_text(im, reduceboxes(sparselet_models{i}, bs{i}), ...
      color_palette_heat(i,:), this_class, false, 2);
  end
end

clear ds;
clear bs;

% DPM detection
detection_threshold = -0.3;
t_dpm_det  = 0;
t_dpm_conv = 0;
for i = 1:length(orig_models)
  th = tic();
  [ds{i}, bs{i}, conv_time] = gdetect(...
            pyra, orig_models{i}, detection_threshold, max_dets_per_image);
  det_time = toc(th); 
  keep = nms(ds{i}, 0.2);
            
  ds{i} = ds{i}(keep, :);
  bs{i} = bs{i}(keep, :);
  
  t_dpm_det  = t_dpm_det  + det_time;
  t_dpm_conv = t_dpm_conv + conv_time;  
end

% Plot detection results
subplot(1,2,2); image(im); title('DPM detections');
for i = 1:length(orig_models)
  if ~isempty(bs{i})
    this_class = conf.pascal.VOCopts.classes{i};
    subplot(1,2,2);
    showboxes_hos_text(im, reduceboxes(orig_models{i}, bs{i}), ...
      color_palette_heat(i,:), this_class, false, 2);
  end
end


fprintf('done\n');
fprintf('  --> DPM detection took %.2f seconds\n', t_dpm_det);
fprintf('  --> Sparselet detection took %.2f seconds\n', t_sparselet_det);
fprintf('  --> Detection speedup   = %.2fX\n', t_dpm_det/t_sparselet_det);
fprintf('  --> Convolution speedup = %.2fX\n', t_dpm_conv/t_sparselet_conv);

