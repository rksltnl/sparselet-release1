function model = pad_original_model_shift(model)

for i = 1:6
    %% HOS: NO Special case for flip because we always want to
    %%      Right/Bottom pad.
        this_root_filter = model.filters(i).w;
        [height, width, hog] = size(this_root_filter);
        % if mod(~,3) == 2 pad right or bottom. 
        % elseif mod(~,3) == 1 pad both sides.
        % elseif mod(~,3) == 0 happy. no pad.
        
        shift = [0 0];
        % pad height
        if mod(height,3) == 2
            tmp = padarray(this_root_filter, [1, 0, 0], 'post');
        elseif mod(height,3) == 1
            tmp = padarray(this_root_filter, [1, 0, 0], 'both');
            shift(1) = -1;
        else
            tmp = this_root_filter;
        end
        
        % pad width
        if mod(width,3) == 2
            w_root = padarray(tmp, [0, 1, 0], 'post');
            % HOS: shift right if flipped filter
            if model.filters(i).flip, shift(2) = -1; end
        elseif mod(width,3) == 1
            w_root = padarray(tmp, [0, 1, 0], 'both');
            shift(2) = -1;
        else
            w_root = tmp;
        end
        model.rules{model.start}(i).shiftwindow = shift;
        model.filters(i).w = w_root;
end