function [CellFun, client] = py2matlab
    [~, client] = InitialPy37Fun(); % initialize the model and make preparation for cell detection  
%     CellFun.CellDetectFun = @CellDetectPy37Fun;
%     CellFun.getCellInfo4Frame = @getCellInfo4Frame; %%---
    CellFun.findCellWholeFrame = @findCellWholeFrame;
    CellFun.getBestCellInfo = @getBestCellInfo;
    CellFun.findCellLocalFrame = @findCellLocalFrame0726;
    CellFun.processing = @processing;
end


%% findCellWholeFrame
function [allCellInfo, candidateCellInfo, bestCellFlag, bestCellRoughIdxInfo, haveCellInFrameFlag] = findCellWholeFrame(snapshot, allCellInfo, candidateCellInfo, haveCellInFrameFlag, frameCount, client)
    [cellNum, stats_frame] = getCellInfo4Frame(snapshot, client); % here need to check if it works
    allCellInfo{end + 1} = struct2cell(stats_frame); % save cell info of each frame
    haveCellInFrameFlag{end + 1} = cellNum;
    if isempty(candidateCellInfo) % first frame
        candidateCellInfo(frameCount,1:cellNum) = num2cell(1:cellNum);
        bestCellFlag = 0; % best cell info
        bestCellRoughIdxInfo = {};
    else
        currCandidateCellInfo = caculateDist(candidateCellInfo, cellNum, allCellInfo);
        candidateCellInfo(frameCount,1:length(currCandidateCellInfo)) = num2cell(currCandidateCellInfo); % to be continued ... 
        % update the candidateCellInfo(remove useless cell info)
        [candidateCellInfo, bestCellFlag, bestCellRoughIdxInfo] = updateCandidateCellInfo(candidateCellInfo, allCellInfo, haveCellInFrameFlag);
    end
end


%% findCellLocalFrame
% if ~isempty(bestCellFineInfo)  call the function
% return a struct of cell's current centroid and score
function bestCellFrame = findCellLocalFrame(bestCellFineInfo, snapshot, client)
    localCentroid =  bestCellFineInfo.localCentroid;
    [localSnapshot, cRefer] = getLocalSnapshot(snapshot, localCentroid);
    bestCellFrame = findLocalBestCellFrame(localSnapshot, client, cRefer);
end

function bestCellFrame = findCellLocalFrame0726(snapshot, client)
    rMin = 385; % snapshot 1024*1376
    rMax = 640;
    cMin = 561;
    cMax = 816;
%     localSnapshot = snapshot(rMin:rMax,cMin:cMax);
    localSnapshot = snapshot(510:765,364:619);
    cRefer = [127,127];
    bestCellFrame = findLocalBestCellFrame(localSnapshot, client, cRefer);
end


%% get the cell info and number
function [cellNum, statsFrame] = getCellInfo4Frame(snapshot, client)
    [img_mask, snap_8] = processing(snapshot, client); % snapshot formart and get prediction
    %% for test
    [B,~] = bwboundaries(img_mask,'noholes');% find the boundaries
%     imshow(snap_8)
%     hold on
%     for k = 1:length(B)
%         boundary = B{k};
%         plot(boundary(:,2), boundary(:,1), 'w', 'LineWidth', 2)
%     end % draw the boundaries%%%%
    
    %%
    statsFrame = regionprops(logical(img_mask),'Centroid','Solidity','Area'); % caculate the props of cell  
	[areanum,~] = size(statsFrame); % count the number of cell detected
    if areanum > 0 
        cellNum = areanum;
    else
        cellNum = 0;
        statsFrame = struct('Area',{NaN},'Centroid',{[NaN,NaN]},'Solidity',{NaN});
    end
end


function [intial_flag, client] = InitialPy37Fun()
%     pe = pyenv('Version','D:\Anaconda3\envs\py37\python.exe');
    pe = pyenv; % check the python enviroment
    if pe.Status == "NotLoaded" && (pe.Version ~= "3.7" || pe.ExecutionMode ~= "InProcess")
%             pyenv('Version', py_dir,"ExecutionMode","OutOfProcess");
            intial_flag = 1;
    elseif pe.Status == "Loaded"  && (pe.Version ~= "3.7" || pe.ExecutionMode ~= "InProcess")
            disp('Need to check your pyenv and restart your MATLAB!!')
            intial_flag = 0;
    else
            intial_flag = 1;
    end
    if intial_flag 
        client = py.importlib.import_module('client');
        disp('client have been loaded successfully!!')
    end
end


 %% function to get the prediction of current frame
function [img_mask, snap_8] = processing(snapshot, client)
%     py.importlib.reload(cell_module);
    [r, c] = size(snapshot);
    % Convert uint16 to uint8
%     snap_8 = im2uint8(mat2gray(snapshot));
    % Convert uint16 to [0,1]
    snap_8 = single(mat2gray(snapshot)); % (image - min(image(:)))/(max(image(:)) - min(image(:))) float32
    % Convert format to nparray
    arr_img = mat2nparray(snap_8);
    out_arr = client.send_array(1, r, c, arr_img);%param1--module flag(0-detect tissue;1-detect cell)
    img_mask = nparray2mat(out_arr);
end


%% caculate the dist of cells between 2 consecutive frames
function currCandidateCellInfo = caculateDist(lastCandidateCellInfo, currCellNum, allCellInfo)
    lastFrameCandiCellIdx = [lastCandidateCellInfo{end,:}];
    lastFrameCellCentroid = reshape([allCellInfo{end-1}{2,lastFrameCandiCellIdx}],2,[])'; % get the last candidate cell centroid info
    currFrameCellCentroid = reshape([allCellInfo{end}{2,:}],2,[])';  % get the curr candidate cell centroid info
    lastRadius = sqrt([allCellInfo{end-1}{1,lastFrameCandiCellIdx}]); % get the last candidate cell radius info
    Dist = pdist2(lastFrameCellCentroid, currFrameCellCentroid); % the differences between two frames
    [mV, idx] = min(Dist,[],2); % find the min value of each centroid pair
    candiCellFlag = [mV(:)<lastRadius(:)]'; % find the candidate cell idx
    tempCandiCellIdx = [idx(:).* candiCellFlag(:)]';  
    % replace the repeat elem with 0
    uniqueIdx = unique(tempCandiCellIdx);
    currCandidateCellInfo = zeros(size(lastFrameCandiCellIdx));
    for i = 1:length(uniqueIdx)
        if uniqueIdx(i) == 0
            continue;
        else
            repeatIdx = find(tempCandiCellIdx == uniqueIdx(i));
            [~,ii] = min(mV(repeatIdx));
            currCandidateCellInfo(repeatIdx(ii)) = uniqueIdx(i);
        end
    end
    wholeCandiCellIdx = [1:currCellNum]; % generate the candidate cell idx for current frame
    otherCandiCellIdx = wholeCandiCellIdx(~ismember([1:currCellNum], uniqueIdx));
    currCandidateCellInfo = cat(2, currCandidateCellInfo, otherCandiCellIdx);
end


%% update the candidate cell array
% remove low score cell info
function [candidateCellInfoUpdated, bestCellFlag, bestCellRoughIdxInfo] = updateCandidateCellInfo(candidateCellInfo, allCellInfo, cellExistFlag)
    [rows, ~] = size(candidateCellInfo);
    finishCellIdx = find([candidateCellInfo{end,:}]==0); % find the idx of 0
    len = length(finishCellIdx);
    idxArr = reshape({candidateCellInfo{:,finishCellIdx}},rows,[]); % idx of single cell info to be scored  ({} is used for keep empty elems)
    scoreArr = zeros(size(idxArr(1:end-1,:))); % array to save cell score in each frame
    singleCellApperTimes = zeros(1, len); % array to save how many times the cell appears
    for i = 1:(rows-1)
        if cellExistFlag{i} % if there is cell in the frame
            tempCellInfoFrame = allCellInfo{i}; % get all cell info of current frame, empty elem -- end of idx
            tempCellInfo = tempCellInfoFrame(:,[idxArr{i,:}]); 
            n = length([idxArr{i,:}]); % [] is used for leave out []-empty elems
            singleCellApperTimes(1:n) = singleCellApperTimes(1:n)+1;% count appear times
            for j = 1:n
                scoreArr(i,j) = getScore4Frame(tempCellInfo(:,j));
            end
        end       
    end
    singleCellScoreArr = sum(scoreArr, 1)./singleCellApperTimes; % mean score
%     singleCellScoreArr = max(scoreArr,[], 1); % max score
    lastingScore = min(singleCellApperTimes/10, 1.1);
    singleCellScoreArr = 0.6*singleCellScoreArr+0.4*lastingScore; %%%
    bestCellFlag = 0; % best cell info
    bestCellRoughIdxInfo = {};
    [val, index] = max(singleCellScoreArr); % find the best cell index and value
    th = 0.85; % can be adjusted
    disp(['The current highest score in the frame is: ' num2str(val)]);
    if val > th
        disp(['The score of the selected cell is: ' num2str(val)]);
        bestCellFlag = 1;
        bestCellRoughIdxInfo = candidateCellInfo(1:end-1, finishCellIdx(index));
        candidateCellInfoUpdated = candidateCellInfo;
    else
        candidateCellInfo(:,finishCellIdx) = [];
        candidateCellInfoUpdated = candidateCellInfo;
    end
end
    
    
%% to get the best cell info
 % bestCellRoughIdxInfo(n*1 cell array) -- cell that save the best cell index info in frames
 % bestCellFineInfo -- a struct to save local centroid
function bestCellFineInfo = getBestCellInfo(bestCellRoughIdxInfo, allCellInfo)
    frameNum = length(bestCellRoughIdxInfo);
    maxArea = 0;
    meanCentroid = [];
    idxZ = 0;
    for i = 1:frameNum
        if ~isempty(bestCellRoughIdxInfo{i})
            curFrameCellInfo = allCellInfo{i};
            tempArea = maxArea;
            maxArea = max(maxArea, curFrameCellInfo{1,bestCellRoughIdxInfo{i}});
            if maxArea ~= tempArea
                idxZ = i;
            end
            meanCentroid(end+1,1:2) = curFrameCellInfo{2,bestCellRoughIdxInfo{i}};%% 可能有问题
        end
    end
    meanCentroid = mean(meanCentroid, 1);
    bestCellFineInfo = struct('localCentroid',{meanCentroid},'zRefer',{idxZ});
end



%% function to get local frames
function [localSnapshot, cRefer] = getLocalSnapshot(snapshot, localCentroid)
    localCentroid = fix(localCentroid);
    rMin = max(1, localCentroid(1) - 127); % snapshot 1024*1376
    rMax = min(1024, localCentroid(1) + 128);
    cMin = max(1, localCentroid(2) - 127);
    cMax = min(1376, localCentroid(2) + 128);
    if rMin == 1
        rMax = 256;
    elseif rMax == 1024
        rMin = 769;
    end
    if cMin == 1
        cMax = 256;
    elseif cMax == 1376
        cMin = 1121;  
    end
    % cell location reference
    cRefer = localCentroid - [rMin, cMin] + 1;
    localSnapshot = snapshot(rMin:rMax,cMin:cMax); % local snapshot
%     localSnapshot = snapshot;
end


%% to get the score for single cell in local frames
% localCentroid =  bestCellFineInfo.localCentroid;
% [localSnapshot, cRefer] = getLocalSnapshot(snapshot, localCentroid)
% bestCellFrame = findLocalBestCellFrame(localSnapshot, CellFun, cRefer)
function bestCellFrameInfo = findLocalBestCellFrame(localSnapshot, client, cRefer)
    [cellNum, statsFrame] = getCellInfo4Frame(localSnapshot, client);
    if cellNum >= 1
        cArr = cat(1,statsFrame.Centroid);
        dist = pdist2(cRefer, cArr);
        [~,idx] = min(dist,[],2);
        frameCellScore = getScore4Frame(struct2cell(statsFrame(idx,:)));
        bestCellFrameInfo = struct('Centroid',{cArr(idx,:)},'score',{frameCellScore});
    elseif cellNum == 0
        bestCellFrameInfo = struct('Centroid',{[]},'score',{0});
    end
end


%% to get the score for single cell in each frame
%  singleCellInfo -- single cell info in a frame (Area, Solidity)
function frameCellScore = getScore4Frame(singleCellInfo)
    areaScore = scoreFun(singleCellInfo{1,1}); % [0,1]
    frameCellScore = 0.5 * areaScore + 0.5 * singleCellInfo{3,1};
end


%% the function for area score
function val = scoreFun(x, mu, sigma)
    if nargin < 2
        mu = 5500;
        sigma = 2400;
    end
    val = normpdf(x, mu, sigma)*sigma*sqrt(2*pi);
end


%% transform the format of image (from matarray to nparray)
function result = mat2nparray( matarray )
    %mat2nparray Convert a Matlab array into an nparray
    %   Convert an n-dimensional Matlab array into an equivalent nparray  
    data_size=size(matarray);
    if length(data_size)==1
        % 1-D vectors are trivial
        result=py.numpy.array(matarray);
    elseif length(data_size)==2
        % A transpose operation is required either in Matlab, or in Python due
        % to the difference between row major and column major ordering
        transpose=matarray';
        % Pass the array to Python as a vector, and then reshape to the correct
        % size
        result=py.numpy.reshape(transpose(:)', int32(data_size));
    else
        % For an n-dimensional array, transpose the first two dimensions to
        % sort the storage ordering issue
        transpose=permute(matarray,[length(data_size):-1:1]);
        % Pass it to python, and then reshape to the python style of matrix
        % sizing
        result=py.numpy.reshape(transpose(:)', int32(fliplr(size(transpose))));
    end
end


%% transform the format of image (from nparray to matarray)
function result = nparray2mat( nparray )
	%nparray2mat Convert an nparray from numpy to a Matlab array
	%   Convert an n-dimensional nparray into an equivalent Matlab array
	data_size = cellfun(@int64,cell(nparray.shape));
	if length(data_size)==1
        % This is a simple operation
        result=double(py.array.array('d', py.numpy.nditer(nparray)));
	elseif length(data_size)==2
        % order='F' is used to get data in column-major order (as in Fortran
        % 'F' and Matlab)
        result=reshape(double(py.array.array('d', ...
            py.numpy.nditer(nparray, pyargs('order', 'F')))), ...
            data_size);
    else
        % For multidimensional arrays more manipulation is required
        % First recover in python order (C contiguous order)
        result=double(py.array.array('d', ...
            py.numpy.nditer(nparray, pyargs('order', 'C'))));
        % Switch the order of the dimensions (as Python views this in the
        % opposite order to Matlab) and reshape to the corresponding C-like
        % array
        result=reshape(result,fliplr(data_size));
        % Now transpose rows and columns of the 2D sub-arrays to arrive at the
        % correct Matlab structuring
        result=permute(result,[length(data_size):-1:1]);
	end
end