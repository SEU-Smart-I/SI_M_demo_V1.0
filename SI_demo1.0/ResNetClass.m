classdef ResNetClass
    % ResNetClass 
    % Author: Jian Liu
    % Intro: ResNet parameters and predict function
    
    properties
        temp_folder;        % temp folder dir
        net;                % ResNet network
    end
    
    methods
        function obj = ResNetClass(netFileName)
            %ResNetClass creatFunc
            % get temp dir
            % netFileName: mat file of network
            obj.temp_folder = [pwd,'\temp\'];
            if ~(exist(obj.temp_folder,'dir'))
                mkdir(obj.temp_folder);
            end
            % load Network
            net1 = load([pwd,'\res_model\',netFileName]);
            obj.net = net1.net;
        end
        
        function guess = processing(I,obj)
            % do pridiction using ResNet
            % I: image input
            tic 
            new_dimension = 224; % new dimension of image output (should be a square)
            img_size = [new_dimension new_dimension]; 
            
            % resizing paramters 
%             [ysize,xsize] = size(I);
%             min_dimension = min([xsize ysize]);
            
            % preprocess image
            pipetteImg = customPreprocess(I,img_size);
            
            % save temporary image 
            temp_path = strcat(obj.temp_folder,num2str(cputime),'.png');
            imwrite(pipetteImg, temp_path);
            
            % save information to struct for imds
            imgstruct(1).file = string(temp_path);
            imgstruct(1).x = NaN;
            imgstruct(1).y = NaN;
            imgstruct(1).z = NaN;
            imgstruct(1).hT = NaN;
            imgdata = struct2table(imgstruct);
            
            % create augmented imds for predict function
            auimds = augmentedImageDatastore(img_size,imgdata,...
                'OutputSizeMode','centercrop',...
                'ColorPreprocessing','gray2rgb');
            
            % do predict using neural net
            guess = predict(obj.net,auimds);
            
            % delete temporary image
            delete(temp_path);
            toc
        end
    end
end

