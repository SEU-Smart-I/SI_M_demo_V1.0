clear all;
close all;
clc;
%{
i1 = imread('G:\photo\20210628\02x40\002\matlab\image_0.tiff');
figure,imshow(i1);
% i2 = uint8(i1);
i2 = double(i1);
% i2=medfilt2(i1);
i2 = floor(i2 / 65535 * 16383);
% figure,imshow(i2);
i3 = uint16(i2);
figure,imshow(i3);
imin = min(min(i2));
imax = max(max(i2));
i22 = round((i2 - imin) / (imax - imin) * 255);
i22 = uint8(i22);
figure,imshow(i22)

i4 = imread('G:\photo\20210628\02x40\002\pv\ss_single_1.tiff');
figure,imshow(i4,[]);
%}
% min3 = min(min(i2));
% max3 = max(max(i2));
% i4 = (i2 - min3) / (max3 - min3) * 255;
% i4 = uint8(i4);
% figure,imshow(i4);
% imwrite(i4,'img2.tiff');
% i5 = adapthisteq(im2uint8(i1), 'NumTiles', [25 25], 'ClipLimit', 0.05);
% i4 = uint8(i4);
% figure,imshow(i4);
% figure,imshow(i5);

CD = MyHash;
CD.readImage();
% CD.frame2video();
% tag = CD.findSharpMeanChange();
% tag = CD.findSharpStdUp();