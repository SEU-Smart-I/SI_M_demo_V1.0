function CellDetect = myCellDetect
% my cell detect function package
CellDetect.contentEstimate = @contentEstimate;
CellDetect.getCellPositionFromImage = @getCellPositionFromImage;
end

function contentEstimate()
%
end

function cellP = getCellPositionFromImage()
% cell detect from an image

global obj;

% get image
frame = getsnapshot(obj);
%         frame = ycbcr2rgb(frame);
flushdata(obj);
% cell detect

end

function getImage(obj)

% get image
frame = getsnapshot(obj);
%         frame = ycbcr2rgb(frame);
flushdata(obj);
end