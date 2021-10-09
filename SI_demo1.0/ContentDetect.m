classdef ContentDetect
    % ContentDetect 
    % Author: Jian Liu
    % Intro: water-plane detect in microscope moving
    
    properties
        tag = 0;    % 0--unfinished;1--found water plane;2--found tissue upside
        
        N = 5;      % width of mean shift window
        Threshold1 = 3;      % to find suspicious point
        Threshold2 = 4;      % to be test, most important parameter
        
        % tag = 1, parameters
        inNum = 0;                  % length of stds
        ecount = 0;                 % count to get suspicious points 
        k = 0;                      % errorData point number
        errorData = [];             % store suspicious points
        stds = [];                  % pre-stds
        epcount = 0;                % number of changed points
        epoints = [];               % index list of changed points
        nextFlag = 0;               % flag for step detect
        nextCount = 0;              % count for step point
        si = 0;                     % index of last suspicious point
        esi = 0;                    % index of last suspicious point for detect step
        lessFlag = 0;               % index of less level suspicious point
        
    end
    
    methods
        function obj = ContentDetect(threshold2,n)
            % ContentDetect
            % constructor function
            if nargin == 1
                obj.Threshold2 = threshold2;
            elseif nargin == 2
                obj.N = n;
                obj.Threshold1 = round(n*0.75) - 1;
                obj.Threshold2 = threshold2;
            end
        end
        
        % 传参失败不可用
        function [imeanStd1,dmeanstd1] = findSharpMeanStdChangeInitialize(I1,I2,meanStdFlag)
            % content detect initialization
            % I1: the first image
            % I2: the second image
            % meanStdFlag: 0--mean;1--std
            
            I1 = double(I1);
            I2 = double(I2);
            if (meanStdFlag == 0)
                imeanStd1 = mean2(I1);
                imean2 = mean2(I2);
                dmeanstd1 = imean2 - imeanStd1;
            else
                imeanStd1 = std2(I1);
                istd2 = std2(I2);
                dmeanstd1 = istd2 - imeanStd1;
            end
            
        end
        
        function [imean1,dmean1,obj] = findSharpMeanChange(obj,imean1,dmean1,I)
            %Desciption:
            % find sharp mean change in a image sequence
            % begin with mean (imean1) of second image, mean change (dmean1) of first and second image, and 
            % ContentDetect class initialized with 1 thresholds
            %Input parameters:
            % obj: object of ContentDetect class
            % imean1: mean of preimage
            % dmean1: mean change of preimage (should not be 0)
            % I: new image
            %Output parameters:
            % imean1,dmean1,obj: updated parameters
            % obj.tag: the finding status
            
            I1 = double(I);
            imean2 = mean2(I1);
            dmean2 = imean2 - imean1;
            % threshold to be test
            if dmean2 > 0 && dmean2 > obj.threshold1*abs(dmean1)
                obj.tag = 1;
                return;
            end
            imean1 = imean2;
%             if dmean2 > abs(dmean1)
%                 dmean1 = dmean2;
%             end
        end
        
        function [flag,istd1,dstd1] = findSharpStdUpInitialize(obj,istd1,dstd1,I)
            %Description:
            % initialzetion of findSharpStdUp() function
            % begin with std (istd1) of second image, std change (dstd1) of first and second image, and
            % ContentDetect class initialized with 2 thresholds
            %Input parameters:
            % obj: object of ContentDetect class
            % istd1: std of preimage, start 
            % dstd1: std change of preimage
            % I: new image
            %Output parameters:
            % flag: the initialized state: 0--unfinished;1--finished
            % istd1,dstd1: updated parameter
            
            flag = 0;
            I1 = double(I);
            istd2 = std2(I1);
            temp = istd2 - istd1;
            if (temp < 0)
                if (dstd1 > 0)
                    flag = 1;
                else
                    dstd1 = 0;
                end
            elseif (dstd1 <= 0)
                dstd1 = temp;
            elseif (dstd1 > 0 && temp < obj.threshold2*dstd1)
                dstd1 = dstd1 + temp;
            end
            istd1 = istd2;
        end
        
        function [istd1,dstd1,dstd2,obj] = findSharpStdUp(obj,istd1,dstd1,dstd2,I)
            %Descriptuion:
            % find sharp std up in a image sequence, after
            % findSharpStdUpInitialize() function
            %Input parameters:
            % obj: object of ContentDetect class
            % istd1: std of preimage
            % dstd1: std change of previous rising edge
            % dstd2: std change of current rising edge
            % I: new image
            %Output parameters:
            % istd1,dstd1,dstd2,obj: updated parameters
            % obj.tag: the finding status
            
            I1 = double(I);
            istd2 = std2(I1);
            temp = istd2 - istd1;
            % threshold to be test
            if temp > 0
                dstd2 = dstd2 + temp;
                if (dstd2) > obj.threshold1*abs(dstd1)
                    obj.tag = 2;
                    return;
                end
            else
                if dstd2 > 0
                    % threshold to be test
%                     if dstd2 < threshold2*abs(dstd1) && dstd2 > dstd1
%                         dstd1 = dstd2
%                     end
                    dstd2 = 0;
                end
            end
            istd1 = istd2;
        end
        
        function obj = ContentDetect1Initialize(obj,seq1D)
            % water plane detect func initialize
            % seq1D:std of first 6 images and final element is 0 -- [std(image1),std(image2)...std(image6),0]
            
            obj.inNum = 6;              % length of stds
            obj.ecount = 0;             % count to get suspicious points 
            obj.k = 0;                  % errorData point number
            obj.errorData = [];         % store suspicious points
            obj.stds = seq1D(1:6);      % pre-stds
            obj.epcount = 0;            % number of changed points
            obj.epoints = [];           % index list of changed points
            obj.nextFlag = 0;           % flag for step detect
            obj.nextCount = 0;          % count for step point
            obj.si = 0;                 % index of last suspicious point
            obj.esi = 0;                    % index of last suspicious point for detect step
            obj.lessFlag = 0;               % index of less level suspicious point
        end
        
        function obj = ContentDetect1(obj,stdNext)
            % water plane detect func initialize
            % stdNext: std of next image
            
            i = obj.inNum;
            n = obj.N;
            threshold1 = obj.Threshold1;
            threshold2 = obj.Threshold2;
            
            obj.stds = [obj.stds,stdNext];
            obj.inNum = obj.inNum + 1;
            while(i < size(obj.stds,2))
                i = i + 1;
                
                % step detect
                if (obj.nextCount == 5 || obj.nextCount == 4  || obj.nextCount == 3) && (i - obj.esi) == 6
                    dmeanLeft = zeros(1,5);
                    dmeanRight = zeros(1,5);
                    for j = 1:5
                        dmeanLeft(j) = abs(obj.stds(obj.esi-5+j) - obj.stds(obj.esi-6+j));
                        dmeanRight(j) = abs(obj.stds(obj.esi+j) - obj.stds(obj.esi-1+j));
                    end

                    % find extend step
                    lp = obj.esi - 1;
                    rp = obj.esi;
                    if obj.stds(obj.esi-1) < obj.stds(obj.esi)
                        tflag = 1;  % up step
                    else
                        tflag = 0;  % down step
                    end
                    
                    if (tflag && obj.stds(lp-1) < obj.stds(lp) || (~tflag && obj.stds(lp-1) > obj.stds(lp)))
                        lp = lp - 1;
                    end
                    if (tflag && obj.stds(rp) < obj.stds(rp + 1) || (~tflag && obj.stds(rp) > obj.stds(rp + 1)))
                        rp = rp + 1;
                    end
                    
                    rightNum = threshold2 * (mean(dmeanLeft(1:max([1,5-obj.esi+lp]))) + mean(dmeanRight(min([5,rp-obj.esi+1]):5))) / 2;
                    leftNum = abs(min(mean(obj.stds(obj.esi-6:obj.esi-1)),obj.stds(lp)) - max(mean(obj.stds(obj.esi:obj.esi+5)),obj.stds(rp)));
                    if leftNum > 600 && leftNum < 1000     % experiment parameter
                        leftNum = leftNum*2;
                    %   leftNum = max(leftNum,1000);
                    end
                    
                    if leftNum > rightNum
                        obj.tag = 1;
                        return;
                    else
                        if obj.esi == 0 || obj.esi == obj.si
                            obj.nextFlag = 0;
                        else
                            i = obj.si + 1;
                            obj.esi = obj.si;
                        end
                        obj.nextCount = 0;
                    end
                elseif obj.nextCount == 5 || (i - obj.esi) > 6
                    if obj.nextFlag == 1
                        if obj.esi == 0 || obj.esi == obj.si
                            obj.nextFlag = 0;
                        else
                            i = obj.si + 1;
                            obj.esi = obj.si;
                        end
                        obj.nextCount = 0;
                    end
                end

                % count to detect suspicious point
                seq1D = obj.stds(i-6:i);
                newShiftMean = mean(seq1D(3:(n+2)));
                count = 0;
                for j = 3:(n+2)
                    if newShiftMean > seq1D(j)
                        count = count + 1;
                    end
                end
                
                % get less suspicious point flag
                if count == 3 && max(seq1D(3:(n+2))) == obj.stds(i)
                    lessI = max(seq1D(3:(n+1)));
                    obj.lessFlag = 1;
                elseif count == 2 && min(seq1D(3:(n+2))) == obj.stds(i)
                    lessI = min(seq1D(3:(n+1)));
                    obj.lessFlag = -1;
                end
                if obj.lessFlag ~= 0
                    for j = 3:(n+1)
                        if seq1D(j) == lessI
                            lessI = j;
                            break;
                        end
                    end
                    tempSeq = seq1D(3:(n+2));
                    tempSeq = (tempSeq - mean(tempSeq)) / std(tempSeq);
                    if abs(tempSeq(lessI-2)) > 0.1
                        obj.lessFlag = 0;
                    end
                end
                
                % get suspicious point
                if count > threshold1 || obj.lessFlag == 1
                    obj.lessFlag = 0;
                    maxnum = max(seq1D(3:(n+2)));
                    for j = 3:(n+2)
                        if seq1D(j) == maxnum
                            ki = j;             % seq1D index
                        end
                    end
                    if obj.si ~= 0 && i - n - 2 + ki < obj.si
                        continue;
                    else
                        obj.si = i - n - 2 + ki;        % stds index
                        obj.nextFlag = 0;
                        obj.nextCount = 0;
                    end
                    if obj.k > 0 && obj.errorData(obj.k,1) == obj.si && obj.errorData(obj.k,3) == 1
                        obj.ecount = obj.ecount + 1;
                        % to be test
                        obj.nextFlag = 0;
                        obj.nextCount = 0;
                    else
                        obj.ecount = 1;
                        if ~obj.nextFlag
                            obj.esi = obj.si;
                        end
                        obj.nextFlag = 1;
                    end
                    if obj.k > 0 && (obj.si-1 == obj.errorData(obj.k,1) &&  obj.ecount == 1)
                        obj.ecount = 2;     % error point next to step point, to be test
                    end
                    obj.k = obj.k + 1;
                    obj.errorData = [obj.errorData;obj.si,seq1D(ki),1];       % save suspicious error data
                    % error point remove
                    if obj.ecount == 5 || (obj.ecount == 4 && (i - obj.si) == 4) || (obj.ecount == 3 && (i - obj.si) == 4)
                        if obj.k > 2
                            lastsi = 1;
                            for ii = 1:obj.k-1
                                if obj.errorData(obj.k-ii,1) < obj.si
                                    lastsi = obj.errorData(obj.k-ii,1);
                                    break;
                                end
                            end
                        end
                        meanR = mean(obj.stds(obj.si+1:obj.si+4));
                        meanL = mean(obj.stds(max([obj.si-4,lastsi,1]):max(obj.si-1,1)));
                        if abs(obj.stds(obj.si) - meanR) > abs(obj.stds(obj.si) - meanL)
                            obj.stds(obj.si) = obj.stds(obj.si-1);
                        else
                            obj.stds(obj.si) = obj.stds(obj.si+1);
                        end
                        i = max(obj.si-5,7);                 % back after change
                        obj.epcount = obj.epcount + 1;
                        obj.epoints = [obj.epoints,obj.si];
                        obj.si = 7;
                        obj.esi = 7;
                    end
                elseif count < (n - threshold1) || obj.lessFlag == -1
                    obj.lessFlag = 0;
                    minnum = min(seq1D(3:(n+2)));
                    for j = 3:(n+2)
                        if seq1D(j) == minnum
                            ki = j;
                        end
                    end
                    if obj.si ~= 0 && i - n - 2 + ki < obj.si
                        continue;
                    else
                        obj.si = i - n - 2 + ki;        % stds index
                        obj.nextFlag = 0;
                        obj.nextCount = 0;
                    end
                    if obj.k > 0 && obj.errorData(obj.k,1) == (obj.si) && obj.errorData(obj.k,3) == 2
                        obj.ecount = obj.ecount + 1;
                        % to be test
                        obj.nextFlag = 0;
                        obj.nextCount = 0;
                    else
                        obj.ecount = 1;
                        if ~obj.nextFlag
                            obj.esi = obj.si;
                        end
                        obj.nextFlag = 1;
                    end
                    if obj.k > 0 && (obj.si-1 == obj.errorData(obj.k,1) &&  obj.ecount == 1)
                        obj.ecount = 2;     % error point next to step point
                    end
                    obj.k = obj.k + 1;
                    obj.errorData = [obj.errorData;obj.si,seq1D(ki),2];
                    % error point remove
                    if obj.ecount == 5 || (obj.ecount == 4 && (i - obj.si) == 4) || (obj.ecount == 3 && (i - obj.si) == 4)
%                         obj.stds(obj.si) = (obj.stds(obj.si - 1) + obj.stds(obj.si + 1)) / 2;
                        if obj.k > 2
                            lastsi = 1;
                            for ii = 1:obj.k-1
                                if obj.errorData(obj.k-ii,1) < obj.si
                                    lastsi = obj.errorData(obj.k-ii,1);
                                    break;
                                end
                            end
                        end
                        meanR = mean(obj.stds(obj.si+1:obj.si+4));
                        meanL = mean(obj.stds(max([obj.si-4,lastsi,1]):max(obj.si-1,1)));
                        if abs(obj.stds(obj.si) - meanR) > abs(obj.stds(obj.si) - meanL)
                            obj.stds(obj.si) = obj.stds(obj.si-1);
                        else
                            obj.stds(obj.si) = obj.stds(obj.si+1);
                        end
                        i = max(obj.si-5,7);                 % back after change
                        obj.epcount = obj.epcount + 1;
                        obj.epoints = [obj.epoints,obj.si];
                        obj.si = 7;
                        obj.esi = 7;
                    end
                else
                    % for step detect
                    if obj.nextFlag == 1
                        obj.nextCount = obj.nextCount + 1;
                    end
                end
            end
        end
        
    end
end

