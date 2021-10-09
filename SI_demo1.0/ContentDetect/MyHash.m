function ContentDetect = MyHash
ContentDetect.aHash = @aHash;
ContentDetect.readImage = @readImage;
ContentDetect.testFunc = @testFunc;
ContentDetect.frame2video = @frame2video;
ContentDetect.findSharpMeanChange = @findSharpMeanChange;
ContentDetect.findSharpStdUp = @findSharpStdUp;
end

function result =  testFunc(image)

result = {};
if (nargin < 1)
    image = imread('img1.tiff');
    image1 = im2uint8(image);
    ahash = aHash(image1)
    dhash = dHash(image1)
    phash = pHash(image1)
    n = cmpHash(ahash,dhash)
else
    result{1} = mean2(image);      %��ֵ
    result{2} = std2(image);      %��׼��
    result{3} = aHash(image);
    result{4} = dHash(image);
    result{5} = pHash(image);
end
    
end

function Df = Brenner(image)
% Brenner�ݶȺ�����̫����

I = double(image);
[m,n] = size(image);
Df = 0;
for i = 1:n
    for j = 1:(m-2)
%         Df = Df + power(image(j+2,i)-image(j,i),2);
        Df = Df + (I(j+2,i)-I(j,i)) * (I(j+2,i)-I(j,i));
    end
end

end

function FI = Tenengrad(image)
% Tenengrag�ݶȺ���
% image: input image

[M,N] = size(image);

I=double(image);
%����sobel����gx,gy��ͼ�����������ȡͼ��ˮƽ����ʹ�ֱ������ݶ�ֵ
GX = 0;   %ͼ��ˮƽ�����ݶ�ֵ
GY = 0;   %ͼ��ֱ�����ݶ�ֵ
FI = 0;   %��������ʱ�洢ͼ��������ֵ
T  = 0;   %���õ���ֵ
for x=2:M-1 
    for y=2:N-1 
        GX = I(x-1,y+1)+2*I(x,y+1)+I(x+1,y+1)-I(x-1,y-1)-2*I(x,y-1)-I(x+1,y-1); 
        GY = I(x+1,y-1)+2*I(x+1,y)+I(x+1,y+1)-I(x-1,y-1)-2*I(x-1,y)-I(x-1,y+1); 
        SXY= sqrt(GX*GX+GY*GY); %ĳһ����ݶ�ֵ
        %ĳһ���ص��ݶ�ֵ�����趨����ֵ���������ص㿼�ǣ���������Ӱ��
        if SXY>T 
            FI = FI + SXY*SXY;    %Tenengradֵ����
        end 
    end 
end 

end

function FI = myEOG(image)
% energy of gradient

I=double(image);
[M,N] = size(image);
FI = 0;
for x=1:M-1 
    for y=1:N-1 
        % x�����y������������ػҶ�ֵֻ��ĵ�ƽ������Ϊ������ֵ
        FI=FI+(I(x+1,y)-I(x,y))*(I(x+1,y)-I(x,y))+(I(x,y+1)-I(x,y))*(I(x,y+1)-I(x,y));
    end 
end

end

function FI = Roberts(image)
% Roberts����

I=double(image);
[M,N] = size(image);
FI = 0;
%Robert����ԭ���ԽǷ������ڵ�������֮�� 
for x=1:M-1 
    for y=1:N-1 
        FI= FI + (abs(I(x,y)-I(x+1,y+1))+abs(I(x+1,y)-I(x,y+1))); 
    end 
end

end

function FI = myLaplace(image)
% Laplace����

I=double(image);
[M,N] = size(image);
FI = 0;
for x=2:M-1 
    for y=2:N-1 
        IXXIYY = -4*I(x,y)+I(x,y+1)+I(x,y-1)+I(x+1,y)+I(x-1,y); 
        FI=FI+IXXIYY*IXXIYY;        %ȡ�����ص��ݶȵ�ƽ������Ϊ������ֵ    
    end 
end
end

function readImage(strDir,strFileType)
% read image file from strDir
% strDir: file path string
% strFileType: file type string,

if (nargin < 2)
    strFileType = '.tiff';
    if (nargin < 1)
%         strDir = 'D:\softdata\python\video\20210604shunao\01_10umdown\';
%         strDir = 'D:\softdata\python\video\20210610\02zsao\';
        strDir = 'D:\photo\20210630\06\';
    end
end
D = dir([strDir,'*',strFileType]);
% D = dir(strDir)
N = length(D);
means = zeros(1,N);
stds = zeros(1,N);
dstds = zeros(1,N-1);
normalizedstds = zeros(1,N);
brenners = zeros(1,N);
% eogs = zeros(1,N);
% robs = zeros(1,N);
% laps = zeros(1,N);
% tenengrads = zeros(1,N);
% entropys = zeros(1,N);
% N = 2;
for i = 1:N
%     filename = ['ss_single_',num2str(i),strFileType]
    filename = ['image_',num2str(i),strFileType]
    I = imread([strDir,filename]);
%     I1 = im2uint8(I);
    I1 = double(I);
%     figure;imshow(I1);
%{
    result1 =  testFunc(I1);
    if (i > 1)
        ahash(i-1) = cmpHash(result0{3},result1{3});
        dhash(i-1) = cmpHash(result0{4},result1{4});
        phash(i-1) = cmpHash(result0{5},result1{5});
    end
    result0 = result1;
    means(i) = result1{1};
    stds(i) = result1{2};
%}
    means(i) = mean2(I1);
    stds(i) = std2(I1);
    if i>1
        dstds(i) = stds(i) - stds(i-1);
    end
    normalizedstds(i) = stds(i) / means(i);
    brenners(i) = Brenner(I1);
%     eogs(i) = myEOG(I1);
%     robs(i) = Roberts(I1);
%     laps(i) = myLaplace(I1);
%     tenengrads(i) = Tenengrad(I1);
%     entropys(i) = entropy(I1);
end
mean(abs(dstds(1:6)))
mean(abs(dstds(1:20)))
figure,plot(means);title('Mean');
figure,plot(stds);title('Std');
figure,plot(dstds);title('dstd');
figure,plot(normalizedstds);title('Normalized Std');
figure,plot(brenners);title('brenner');
% figure;
% plot(tenengrads);
% figure;
% plot(ahash);
% figure;
% plot(dhash);
% figure;
% plot(phash);
end

function tag = findSharpMeanChange()
% find sharp mean change in a image sequence

tag = 0;
% strDir = 'D:\softdata\python\video\20210610\02zsao\';
strDir = 'D:\softdata\python\video\20210604shunao\01_10umdown\';
strFileType = '.tiff';
D = dir([strDir,'*',strFileType]);
N = length(D);
% get first image
i = 1;
filename = ['ss_single_',num2str(i),strFileType]
I = imread([strDir,filename]);
% I1 = im2uint8(I);
I1 = double(I);
imean1 = mean2(I1);

% get second image
i = 2;
filename = ['ss_single_',num2str(i),strFileType]
I = imread([strDir,filename]);
% I1 = im2uint8(I);
I1 = double(I);
imean2 = mean2(I1);
dmean1 = imean2 - imean1;
imean1 = imean2;

for i = 3:N
    % get new image
    filename = ['ss_single_',num2str(i),strFileType]
    I = imread([strDir,filename]);
%     I1 = im2uint8(I);
    I1 = double(I);
    imean2 = mean2(I1);
    dmean2 = imean2 - imean1;
    % threshold to be test
    if dmean2 > 0 && dmean2 > 20*abs(dmean1)
        tag = i;
        return;
    end
    imean1 = imean2;
    if dmean2 > abs(dmean1)
        dmean1 = dmean2;
    end
end

end

function tag = findSharpStdUp()
% find sharp std up in a image sequence

tag = 0;
threshold1 = 10;
threshold2 = 1.2;
meanStep = 1364;

% strDir = 'D:\softdata\python\video\20210610\01zsao\';
% strDir = 'D:\softdata\python\video\20210604shunao\01_10umdown\';
strDir = 'D:\softdata\python\video\20210630\02\';
strFileType = '.tiff';
D = dir([strDir,'*',strFileType]);
N = length(D);

% initialize
j = 1;
dstd1 = 0;
initialFlag = 0;
% get first image
i = meanStep + 1;
filename = ['ss_single_',num2str(i),strFileType]
I = imread([strDir,filename]);
% I1 = im2uint8(I);
I1 = double(I);
istd1 = std2(I1);

while(j<1000 && initialFlag == 0)
    % get new image
    j = j + 1;
    filename = ['ss_single_',num2str(j+meanStep),strFileType]
    I = imread([strDir,filename]);
    I1 = double(I);
    istd2 = std2(I1);
    temp = istd2 - istd1;
    if (temp < 0)
        if (dstd1 > 0)
            break;
        else
            dstd1 = 0;
        end
    elseif (dstd1 == 0)
        dstd1 = temp;
    elseif (dstd1 > 0 && temp < threshold2*dstd1)
        dstd1 = dstd1 + temp;
    end
    istd1 = istd2;
end



%{
% get second image
i = meanStep + 2;
filename = ['ss_single_',num2str(i),strFileType]
I = imread([strDir,filename]);
% I1 = im2uint8(I);
I1 = double(I);
istd2 = std2(I1);
temp = istd2 - istd1
istd1 = istd2;
%}
dstd1
dstd2 = 0;
% stepFlag = 0;
for i = (meanStep+j+1):N
    % get new image
    filename = ['ss_single_',num2str(i),strFileType]
    I = imread([strDir,filename]);
%     I1 = im2uint8(I);
    I1 = double(I);
    istd2 = std2(I1);
    temp = istd2 - istd1;
    % threshold to be test
    if temp > 0
        dstd2 = dstd2 + temp;
        if (dstd2) > threshold1*abs(dstd1)
            tag = i;
            return;
        end
    else
        if dstd2 > 0
            % threshold to be test
%             if dstd2 < threshold2*abs(dstd1) && dstd2 > dstd1
%                 dstd1 = dstd2
%             end
            dstd2 = 0;
        end
    end
    istd1 = istd2;
end

end

function tag = findTissueEnd()
% find sharp std up in a image sequence

tag = 0;
strDir = 'D:\softdata\python\video\20210610\01zsao\';
% strDir = 'D:\softdata\python\video\20210604shunao\01_10umdown\';
strFileType = '.tiff';
D = dir([strDir,'*',strFileType]);
N = length(D);
meanStep = 1196;
% get first image
i = meanStep + 1;
filename = ['ss_single_',num2str(i),strFileType]
I = imread([strDir,filename]);
I1 = im2uint8(I);
istd1 = std2(I1);

% get second image
i = meanStep + 2;
filename = ['ss_single_',num2str(i),strFileType]
I = imread([strDir,filename]);
I1 = im2uint8(I);
istd2 = std2(I1);
dstd1 = istd2 - istd1;
istd1 = istd2;

for i = (meanStep + 3):N
    % get new image
    filename = ['ss_single_',num2str(i),strFileType]
    I = imread([strDir,filename]);
    I1 = im2uint8(I);
    istd2 = std2(I1);
    dstd2 = istd2 - istd1;
    % threshold to be test
    if dstd2 > 0 && dstd2 > 20*abs(dstd1)
        tag = i;
        return;
    end
    istd1 = istd2;
    if dstd2 > abs(dstd1)
        dstd1 = dstd2;
    end
end

end

function frame2video(strDir,strFileType)
% read image file of strFileType in strDir, to generate avideo file
% strDir: file path string
% strFileType: file type string

if (nargin < 2)
    strFileType = '.tiff';
    if (nargin < 1)
%         strDir = 'D:\softdata\python\video\20210604shunao\01_10umdown';
%         strDir = 'D:\softdata\python\video\20210617\03wpi\';
        strDir = 'D:\photo\20210630\06\';
        strVideoDir = [strDir(1:length(strDir)-1),'.avi'];
    end
end
% strs = split(strDir,'\');
% videoName = [strs{size(strs,1)-1},'.avi'];
videoFullName = strVideoDir;
fps = 16; 
if(exist('videoFullName','file'))  
    delete videoFullName;       %.avi �ж����Ƿ������Ƶ��С�����ϰ��
end  
aviobj=VideoWriter(videoFullName);	%����һ��avi��Ƶ�ļ����󣬿�ʼʱ��Ϊ��  
aviobj.FrameRate=fps;   
open(aviobj);                   %���ļ�д����Ƶ����

D = dir([strDir,'*',strFileType]);
% D = dir(strDir)
N = length(D);
% N = 64;
for i = 1:N
%     filename = ['ss_single_',num2str(i),strFileType]
    filename = ['image_',num2str(i),strFileType]
    I = imread([strDir,filename]);
%     I1 = im2uint8(I);
    I2 = double(I);
    min3 = min(min(I2));
    max3 = max(max(I2));
    I3 = (I2 - min3) / (max3 - min3) * 255;
    I3 = uint8(I3);
    writeVideo(aviobj,I3);
%     writeVideo(aviobj,I1);
end
close(aviobj);

end

function frame16intTo8int(strDir,strFileType)
% uint16 image to uint8
% strDir: file path string
% strFileType: file type string

if (nargin < 2)
    strFileType = '.tiff';
    if (nargin < 1)
%         strDir = 'D:\softdata\python\video\20210604shunao\01_10umdown';
        strDir = 'E:\photo\20210610\04\';
        strResultDir = [strDir(1:length(strDir)-1),'_8\'];
    end
end

if~(exist(strResultDir,'dir'))  
    mkdir(strResultDir);       % �ж����Ƿ�����ļ���
end

D = dir([strDir,'*',strFileType]);
% D = dir(strDir)
N = length(D);
% N = 64;
for i = 1:N
    filename = ['ss_single_',num2str(i),strFileType]
    I = imread([strDir,filename]);
    I1 = im2uint8(I);
    I2 = double(I1);
    min3 = min(min(I2));
    max3 = max(max(I2));
    I3 = (I2 - min3) / (max3 - min3) * 255;
    I3 = uint8(I3);
    imwrite(I3,[strResultDir,filename]);
%     writeVideo(aviobj,I3);
%     writeVideo(aviobj,I1);
end

end


function hash_str = aHash(img)
% average hash
% img: image

%����
img = imresize(img,[8,8]);
%��ֵ
avg = mean(mean(img));
%���ھ�ֵΪ1
hash_str = '';
for i = 1:8
    for j = 1:8
        if img(i,j) > avg
            hash_str = [hash_str,'1'];
        else
            hash_str = [hash_str,'0'];
        end
    end
end
end

function hash_str = dHash(img)
% ��ֵ��֪Hash

%����
img = imresize(img,[8,9]);
%ÿ��ǰһ�����ش��ں�һ������Ϊ1���෴Ϊ0
hash_str = '';
for i = 1:8
    for j = 1:8
        if img(i,j) > img(i,j+1)
            hash_str = [hash_str,'1'];
        else
            hash_str = [hash_str,'0'];
        end
    end
end
end

function hash_str = pHash(img)
% ��֪��ϣ�㷨

%����
img = imresize(img,[32,32]);
dct = dct2(img);
dct_roi = dct(1:8,1:8);
hash_str = '';
avg = mean(dct_roi);
for i = 1:8
    for j = 1:8
        if dct_roi(i,j) > avg
            hash_str = [hash_str,'1'];
        else
            hash_str = [hash_str,'0'];
        end
    end
end
end

function n = cmpHash(hash1,hash2)
% Hashֵ�Ա�,��Ӧλ��ͬ��+1

n = 0;
%���Ȳ�ͬ�򷵻�-1�����γ���
if length(hash1) ~= length(hash2)
    n = -1;
    return;
end
%�����ж�
for i = 1:length(hash1)
    if hash1(i) == hash2(i)
        n = n + 1;
    end
end
end

%ssim()���ڲ���ͼ�������Ľṹ������ (SSIM) ����
%cosin���ƶȣ��������ƶȣ�
