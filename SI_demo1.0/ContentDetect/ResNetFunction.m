function [ResFunc,temp_folder,net] = ResNetFunction
% ResNet function
    [temp_folder,net] = Initialization();
    ResFunc.Initialization = @Initialization;
    

end

function [temp_folder,net] = Initialization()
% initialization for calling ResNet
    % get temp dir
    temp_folder = [pwd,'\temp\'];
    if ~(exist(temp_folder,'dir'))
        mkdir(temp_folder);
    end
    % load Network
    net1 = load([pwd,'\res_model\regressionNET-21-Aug-2021.mat']);
    net = net1.net;
end

function result = processing(I,net) 

end