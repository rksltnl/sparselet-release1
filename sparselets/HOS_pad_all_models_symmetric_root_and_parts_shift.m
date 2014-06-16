function HOS_pad_all_models_symmetric_root_and_parts_shift
setup_SPAMS;

original_model_path = '/u/vis/song/voc-release4/VOC2007/original_voc_2007_models/';
model_save_path = '/u/vis/song/voc-release4.01-shiftwindow/VOC2007/shifted_padded_original_models/';

if exist(model_save_path) == 0
  unix(['mkdir -p ' model_save_path]);
end

d = dir([original_model_path '*_final.mat']);

for i=1:length(d)
    this_model_loaded = load([original_model_path d(i).name]);
    this_model = this_model_loaded.model;
    this_model.thresh = -1.1;
    
    model = pad_original_model_shift(this_model);
    
    model = modify_padded_reconstructed_model(model);
    save([model_save_path model.class '_final.mat'], 'model');
end

function model_modified = modify_padded_reconstructed_model(recon_model)

% 1. Modify minsize maxsize
recon_model.maxsize = [0 0];
recon_model.minsize = [100 100];
for i = 1:6
    this_root_filter = recon_model.filters(i).w;
    [height, width, hog] = size(this_root_filter);
    
    if recon_model.maxsize(1) < height, recon_model.maxsize(1) = height; end   
    if recon_model.maxsize(2) < width,  recon_model.maxsize(2) = width;  end  
    if recon_model.minsize(1) > height, recon_model.minsize(1) = height; end  
    if recon_model.minsize(2) > width,  recon_model.minsize(2) = width;  end
end

% 2. Modify filter(i).size
for i = 1:6
    this_root_filter = recon_model.filters(i).w;
    [height, width, hog] = size(this_root_filter);  
    recon_model.filters(i).size = [height width];
end

% 3. Modify blocksizes
[height, width, hog] = size(recon_model.filters(1).w);    
recon_model.blocksizes(1) = height*width*hog;

[height, width, hog] = size(recon_model.filters(3).w);    
recon_model.blocksizes(5) = height*width*hog;

[height, width, hog] = size(recon_model.filters(5).w);    
recon_model.blocksizes(9) = height*width*hog;

% 4. Modify rules{2} 
% HOS: here don't modify the detwindow leave as it is.
% r2 = recon_model.rules{2};
% for i=1:6
%     [height, width, hog] = size(recon_model.filters(i).w);
%     r2(i).detwindow = [height width];
% end
% recon_model.rules{2} = r2;
 
model_modified = recon_model;
    