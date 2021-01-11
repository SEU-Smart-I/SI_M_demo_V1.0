%% This file contains various functions related to image processing
function DetectFun = MultiFunctions
    DetectFun.threshold_local = @threshold_local;
    DetectFun.PipDetectFun = @PipDetectFun;
    DetectFun.CellDetectFun = @CellDetectFun;
    DetectFun.ConvertToPseudocolor = @ConvertToPseudocolor;
end

%% Function for Pseudocolor
function outimg = ConvertToPseudocolor(frame_image)
    img_origin = im2uint8(frame_image);
    % tic
    img_enhance = adapthisteq(img_origin,'NumTiles',[4,4],'clipLimit',0.5,'Distribution','rayleigh');
    % img_enhance = mapminmax(double(img_enhance),0,1);
%     figure(2)
    % title('img_enhance')
%     imshow(img_enhance);

    % imhist(img_enhance)
%     figure(3)
    st = uint8(stdfilt(img_enhance,true(15)));
%     st = mapminmax(st,0,255);
%     imshow(st)

    outimg(:,:,1) = img_origin;
    outimg(:,:,2) = st;

    img_enhance = histeq(img_enhance); 
    % imshow(img_enhance)

    [Gmag, Gdir] = imgradient(img_enhance);
    % figure(4)
    thresh = mean(Gmag,'all');
    Gmag = Gmag>thresh;
    h = fspecial('disk',5);
    Gmag = imfilter(Gmag, h, 'replicate');
    % imshow(Gmag)
    se1 = strel('line', 13, 0);
    se2 = strel('line', 13, 90);
    processed_image = imdilate(Gmag, [se1 se2]);
    processed_image = imerode(processed_image, strel('disk',5));
    processed_image = imclearborder(~processed_image);
    processed_image = bwareaopen(processed_image,1500);
%     figure(5)
%     title('imclose')
%     imshow(processed_image);
%     figure(6)
    outimg(:,:,3) = uint8(processed_image*255);
%     imshow(uint8(outimg))
    % figure(4)
    % imshow(rgb2gray(outimg))
    % toc


end

%% Function for Cell Detection
function [cell_location, flag] = CellDetectFun(frame_img)
    img_origin = im2uint8(frame_img);
    img_enhance = adapthisteq(img_origin,'NumTiles',[4,4],'clipLimit',0.5,'Distribution','rayleigh');
    img_enhance = histeq(img_enhance); 
    [Gmag, ~] = imgradient(img_enhance);
    thresh = mean(Gmag,'all');
    Gmag = Gmag>thresh;
    h = fspecial('disk',5);
    Gmag = imfilter(Gmag, h, 'replicate');
    se1 = strel('line', 13, 0);
    se2 = strel('line', 13, 90);
    label_image = imdilate(Gmag, [se1 se2]);
    label_image = imerode(label_image, strel('disk',5));
    label_image = imclearborder(~label_image);
    label_image = bwareaopen(label_image,1500);
    
    % ========================
    DetectFun = MultiFunctions;
    [~,img_enhance1] = DetectFun.threshold_local(img_enhance, 81, 'gaussian');
    bkg_thresh = mean(img_enhance1(:));
    fro_img = img_enhance1 - bkg_thresh;
    SE_1 = strel('line',2,45);
    SE_2 = strel('line',2,0);
    processed_image = imerode(fro_img, [SE_1 SE_2]);
    processed_image = imdilate(processed_image, [SE_1 SE_2]);
    processed_image = medfilt2(processed_image,[5 5]);
    level = graythresh(processed_image);
    processed_image = imbinarize(processed_image, level);
    processed_image = imopen(processed_image, strel('disk',5));
    edges2 = uint8(processed_image);
    SE_2 = strel('diamond',5);
    aftopen = imclose(edges2,SE_2);
    edges3 = edge(aftopen,'Sobel');
    edges3 = imdilate(edges3,strel('diamond',2));

    edges3 = imclearborder(edges3);
    edges3 = bwlabeln(edges3);
    im_filled = imfill(edges3,'holes');

    im_filled = bwareaopen(im_filled,2500);

    stats = regionprops(im_filled,img_enhance,'WeightedCentroid','Solidity','BoundingBox');
    weighted = regionprops(im_filled,label_image,'MeanIntensity');
    [areanum,~] = size(stats);
    if areanum > 0
        flag = true;
        count = 1;
        for i = 1:areanum
            if (stats(i).Solidity > 0.78) && (weighted(i).MeanIntensity >0.2)
                cell_location(count) = stats(i);
                count = count + 1;
            end
        end
    else
        flag = false;
    end
end




%% Function for threshold_local
function [thresh_image, processed_image] = threshold_local(image, block_size, method)
    if nargin < 2 && isempty(image)
        error('The number of input parameters is illegal !!');
    end
    if mod(block_size, 2) == 0
        error('The number of input parameters is illegal !!');
    end
    processed_image = zeros(size(image));
    if strcmp(method, 'gaussian')
        sigma = (block_size-1)/4;
        thresh_image =imgaussfilt(image, sigma);
        processed_image = image>thresh_image;
    elseif strcmp(method, 'median')
        thresh_image = medfilt2(image,[block_size,block_size]);
        processed_image = image>thresh_image;
    elseif strcmp(method, 'mean')
        h = fspecial('average', block_size);
        thresh_image = imfilter(image, h, 'replicate');
        processed_image = image>thresh_image;
    elseif strcmp(method, 'disk')
        h = fspecial('disk', block_size/2);
        thresh_image = imfilter(image, h, 'replicate');
        processed_image = image>thresh_image;
    end
end


%% Function for Pip Detection
function [out_img, points] = PipDetectFun(ori_img)
    img_origin = im2uint8(ori_img);
    img_enhance = adapthisteq(img_origin,'NumTiles',[4,4],'clipLimit',0.5,'Distribution','rayleigh');
    h = ones(8,8)/25;
    processed_image = imfilter(img_enhance,h);
    points = detectHarrisFeatures(processed_image);
    points = points.selectStrongest(1);
    out_img = img_enhance;
end
