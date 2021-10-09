function varargout = serial_communication(varargin)
%   Author: Jian Liu, Di Liu, Jie Xue
%   Function: command communication,image acquisition
%   Version: 2020.11.27  version 1.0
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @serial_communication_OpeningFcn, ...
                   'gui_OutputFcn',  @serial_communication_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end

function serial_communication_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
warning off all;
%% �ı䴰�����Ͻǵ�ͼ��Ϊicon.jpg
javaFrame = get(hObject, 'JavaFrame');%�����޸Ĵ���logo
javaFrame.setFigureIcon(javax.swing.ImageIcon('LOGO.png'));
%% ��ʼ������
hasData = false; 	%���������Ƿ���յ�����
isShow = false;  	%�����Ƿ����ڽ���������ʾ�����Ƿ�����ִ�к���dataDisp
isStopDisp = false;  	%�����Ƿ����ˡ�ֹͣ��ʾ����ť
isHexDisp = false;   	%�����Ƿ�ѡ�ˡ�ʮ��������ʾ��
isHexSend = false;	%�����Ƿ�ѡ�ˡ�ʮ�����Ʒ��͡�
numRec = 0;    	%�����ַ�����
numSend = 0;   	%�����ַ�����
strRec = '';   		%�ѽ��յ��ַ���
isCameraOpened= false; %��¼�Ƿ��������ͷ ��1126��
global numSwitch prePosition newPosition comList elementAvailable ifreceived scoms angleOffset axisLimits;
global absZero angleZ calibrateFlag xOffset yOffset zOffset coMoveFlag timeCount configValue haveInitialized;
global injectionP CameraOpenFlag loc currentInjectionP currentCellP StepA StepZ isAutoSaving myResNet;
loc = zeros(1,2);
CameraOpenFlag = false;     %camera status flag
numSwitch = 1;     % current element index
prePosition = zeros(9,3);     %�洢�ϴ�ָ��ͺ��λ��
newPosition = zeros(9,3);     %�洢��ǰ���ĺ�δ���͵�λ��
comList = {'COM16';'COM26';'COM27';'COM13';'COM12';'COM14';'COM15';'COM8'};      %�洢ÿ����Ԫ��Ӧ�Ĵ��ڣ���ʼ������cell
%'COM16';'COM17';'COM13';'COM12';'COM9';'COM11';'COM8';'COM10'
elementAvailable = zeros(9,1);      %�洢ÿ����Ԫ��Ӧ��ť��������
ifreceived = 0;     %��¼�Ƿ���յ�����
scoms = cell(9,1);     %�洢���ڶ���
angleOffset = [0,0,0,19,19,0,0,0,0];     %�洢΢��xoyƽ����ת��
axisLimits = zeros(9,6);     %�洢���ؼ����꼫��
axisLimits(1,:) = [0,2429000,0,2300000,-2494000,0];     %��΢��λ�Ƽ���
axisLimits(4,:) = [-2020000,0,0,1340000,-1970000,0];     %΢��3λ�Ƽ���
axisLimits(5,:) = [-1950000,0,0,1300000,-1950000,0];     %΢��4λ�Ƽ���
absZero = zeros(9,3);     %�洢�ؼ�����ԭ������
angleZ = [0,0,0,70,0,0,0,0];     %�洢΢��xoz�н�
calibrateFlag = [0,0,0,0,0,0,0,0,0];
xOffset = zeros(9,2);     %x co-move offset
yOffset = zeros(9,2);     %y co-move offset
zOffset = zeros(9,2);     %z co-move offset
coMoveFlag = zeros(9,1);     %Эͬ�ƶ���ʶ
timeCount = 0;      %λ��ˢ�¼�ʱ��
configValue = 0;      %config plane function flag
haveInitialized = 0;      % initialize flag
injectionP = zeros(8,3);      % injection position
currentInjectionP = zeros(1,3);       % current injection position
currentCellP = zeros(1,3);       % current cell position
StepA = -500;      % cell moving check step
StepZ = -1000;      % z scan step
isAutoSaving = 0;      % auto save flag
myResNet = ResNetClass('regressionNET-21-Aug-2021.mat');    % ResNet parameters
%%��ȡͼƬ���ݣ�ֻ�ڵ�һ������ʱ��ȡ
% pathstr = fileparts(which(mfilename));
% if exist([pathstr '\lamb.mat'], 'file') == 2
%     load([pathstr '\lamb.mat']);
% else
%     openData = imread('green.jpg');
%     closedData = imread('red.jpg');
%     save lamb.mat openData closedData;
% end
openData = [0 1 0];
closedData = [1 0 0];

%% ������������ΪӦ�����ݣ����봰�ڶ�����
setappdata(hObject, 'hasData', hasData);
setappdata(hObject, 'strRec', strRec);
setappdata(hObject, 'numRec', numRec);
setappdata(hObject, 'numSend', numSend);
setappdata(hObject, 'isShow', isShow);
setappdata(hObject, 'isStopDisp', isStopDisp);
setappdata(hObject, 'isHexDisp', isHexDisp);
setappdata(hObject, 'isHexSend', isHexSend);
setappdata(hObject, 'openData', openData);
setappdata(hObject, 'closedData', closedData);
setappdata(hObject,'isCameraOpened',isCameraOpened); %(1126)
%setappdata(hObject, 'numSwitch', numSwitch);
%setappdata(hObject, 'prePosition', prePosition);
%setappdata(hObject, 'newPosition', newPosition);
%��ʼ������״ָ̬ʾ�ƣ����ڵ�Ĭ��Ϊ�ر�״̬
% set(handles.lamb, 'cdata', closedData); %ͨ��cdata���ı䰴ť��ͼ��
% set(handles.lamb,'BackgroundColor',closedData);

%Update available comPorts on your computer
% set(handles.com, 'String', getAvailableComPort);
%define the WindowButtonDownFcn
set(handles.Image_display,'ButtonDownFcn', {@ButtonDowncallback});
% set(gcf, 'WindowButtonDownFcn', {@ButtonDowncallback, handles});
% set(gcf, 'WindowButtonMotionFcn', {@callback, handles});
positionInitiate(handles);

guidata(hObject, handles);

function saveCurrentPosition()
% store preposition for position loss by power off

global prePosition;
disp('Function: saveCurrentPosition()');
disp(newline);

file = fopen('pbackup.txt','w');
str = 'absZero';
fprintf(file,"%s\n",str);
for i = 1:3
    fprintf(file,"%d %d %d %d %d %d %d %d %d\n",round(prePosition(:,i)));
end
fclose(file);

function loadCurrentPosition()
% load position from backup file

global prePosition;
disp('Function: loadCurrentPosition()');
disp(newline);

file = fopen('pbackup.txt','r');
temp = fgetl(file)
if strcmp(temp, 'prePosition')
    for i = 1:3
        temp = fgetl(file);
        b = sscanf(temp,"%d %d %d %d %d %d %d %d %d");     %�ڶ��п�ʼΪ��������
        prePosition(:,i) = b;
%         updateAxisLimits(i,absZero(i,:));     %���¸���ؼ�λ��������
    end
    disp(['Read absZero successfully',newline]);
end
fclose(file);


function saveParameterToConfigFile()
% save config setting to local file
global absZero calibrateFlag xOffset yOffset zOffset angleOffset;
disp('Function: saveParameterToConfigFile()');
disp(newline);

file = fopen('si.config','w');

str = 'absZero';
fprintf(file,"%s\n",str);
for i = 1:3
    fprintf(file,"%d %d %d %d %d %d %d %d %d\n",round(absZero(:,i)));
end

str = 'calibrateFlag';
fprintf(file,"%s\n",str);
fprintf(file,"%d %d %d %d %d %d %d %d %d\n",round(calibrateFlag));

str = 'xOffset';
fprintf(file,"%s\n",str);
for i = 1:2
    fprintf(file,"%d %d %d %d %d %d %d %d %d\n",xOffset(:,i)*100);
end

str = 'yOffset';
fprintf(file,"%s\n",str);
for i = 1:2
    fprintf(file,"%d %d %d %d %d %d %d %d %d\n",yOffset(:,i)*100);
end

str = 'zOffset';
fprintf(file,"%s\n",str);
for i = 1:2
    fprintf(file,"%d %d %d %d %d %d %d %d %d\n",zOffset(:,i)*100);
end

str = 'angleOffset';
fprintf(file,"%s\n",str);
fprintf(file,"%d %d %d %d %d %d %d %d %d\n",round(angleOffset*100));

fclose(file);

function loadParameterFromConfigFile()
% load config setting from local file
global absZero axisLimits calibrateFlag xOffset yOffset zOffset angleOffset;
disp('Function: loadParameterFromConfigFile()');
disp(newline);

file = fopen('si.config','r');
temp = '0';
while(temp ~= -1)
    temp = fgetl(file);      % first line is parameter name
    switch(temp)
        case 'absZero'
            for i = 1:3
                temp = fgetl(file);
                b = sscanf(temp,"%d %d %d %d %d %d %d %d %d");     % from second line are context
                absZero(:,i) = b;
                
            end
            % update the available limits
            for i = 1:9
                updateAxisLimits(i,absZero(i,:));
            end
            disp(['Read absZero successfully',newline]);
            
        case 'calibrateFlag'
            temp = fgetl(file);
            b = sscanf(temp,"%d %d %d %d %d %d %d %d %d");     % from second line are context
            calibrateFlag = b';
            disp(['Read calibrateFlag successfully',newline]);
            
        case 'xOffset'
            for i = 1:2
                temp = fgetl(file);
                b = sscanf(temp,"%d %d %d %d %d %d %d %d %d");     % from second line are context
                xOffset(:,i) = b/100;
            end
            disp(['Read xOffset successfully',newline]);
            
        case 'yOffset'
            for i = 1:2
                temp = fgetl(file);
                b = sscanf(temp,"%d %d %d %d %d %d %d %d %d");     % from second line are context
                yOffset(:,i) = b/100;
            end
            disp(['Read yOffset successfully',newline]);
            
        case 'zOffset'
            for i = 1:2
                temp = fgetl(file);
                b = sscanf(temp,"%d %d %d %d %d %d %d %d %d");     % from second line are context
                zOffset(:,i) = b/100;
            end
            disp(['Read zOffset successfully',newline]);
            
        case 'angleOffset'
            temp = fgetl(file);
            b = sscanf(temp,"%d %d %d %d %d %d %d %d %d");     % from second line are context
            angleOffset = b'/100;
            disp(['Read angleOffset successfully',newline]);
            
    end
end
%{
temp = fgetl(file);     % first line is parameter name
if strcmp(temp, 'absZero')
    for i = 1:3
        temp = fgetl(file);
        b = sscanf(temp,"%d %d %d %d %d %d %d %d %d");     % from second line are context
        absZero(:,i) = b;
        updateAxisLimits(i,absZero(i,:));     % update the available limits
    end
    disp(['Read absZero successfully',newline]);
end
%}
absZero
axisLimits
fclose(file);

function logAdd(str)
% add log msg for test
% str: the log msg

disp('Function: logAdd()');
disp(newline);

file = fopen('log.txt','a');
fprintf(file,"%s\n",str);
fclose(file);


function updateAxisLimits(index,newZero)
%  update the available limits 
% index: element index
% newZero: new REL zero position
global axisLimits;
disp('Function:  updateAxisLimits(index,newZero)');
%newZero
axisLimits(index,1) = axisLimits(index,1) - newZero(1);
axisLimits(index,2) = axisLimits(index,2) - newZero(1);
axisLimits(index,3) = axisLimits(index,3) - newZero(2);
axisLimits(index,4) = axisLimits(index,4) - newZero(2);
axisLimits(index,5) = axisLimits(index,5) - newZero(3);
axisLimits(index,6) = axisLimits(index,6) - newZero(3);


function flag = comPortOn(index, handles)
% open the comport
% index: element index
% strCOM: comport name
global comList scoms;
disp('Function: comPortOn()');
disp(newline);
baud_rate = 38400;    %������ 38400
jiaoyan = 'none';     %У��λ ��
data_bits = 8;         %����λ 8λ
stop_bits = 1;         %��ֹλ 1λ
scom0 = serial(comList{index});    %�������ڶ���, 'timerfcn', {@dataDisp, handles}
% ���ô������ԣ�ָ����ص�����
set(scom0, 'BaudRate', baud_rate, 'Parity', jiaoyan, 'DataBits',...
    data_bits, 'StopBits', stop_bits, 'BytesAvailableFcnCount', 10,...
    'BytesAvailableFcnMode', 'byte', 'BytesAvailableFcn', {@bytes, handles},...
    'TimerPeriod', 0.05, 'timerfcn', {@getMessageFromComPort, handles});
%BytesAvailableFcnMode �����ж���Ӧģʽ���С�byte���͡�Terminator������ģʽ��ѡ����byte���Ǵﵽһ���ֽ��������жϣ���Terminator������������ĳ�������¼��������жϣ�
% �����ڶ���ľ����Ϊ�û����ݣ����봰�ڶ���
scoms{index} = scom0;

% try to open the comport
try
    fopen(scom0);  % open the comport
    
    % test the comport is available
    pXYZ = getCurrentPosition(index, handles);     % get current position
    if length(pXYZ) == 3
        setNewPosition(index,pXYZ);     %store new position
        flag = 1;
        disp([comList{index},' open successfully!',newline])
    else
        scoms{index} = [];
        flag = 0;
        % �쳣����
        %{
        switch(pXYZ)
            case 0
                % no reply
                elementAvailable(index) = 0;
            case 1
                % index error
            case 2
                % return format error
        end
        %}
    end
    
catch   % comport open failed
    msgbox('Comport open failed','Error','error');
    flag = 0;
    %set(hObject, 'value', 0);  %���𱾰�ť 
    return;
end

function timeoutReaction(index, handles)
% ��ʼ����ɺ���г�ʱ��Ӧ
% index: element number
%handles: gui global handle

global haveInitialized timeCount elementAvailable prePosition;
%20210317
haveInitialized = 0;
timeCount = timeCount + 1;
if timeCount == 2
    timeCount = 0;     % ��־λ��λ
    % ��ʱ��Ӧ�����µ�ǰλ��
    disp('Timeout position check.');
    if elementAvailable(index) == 1
        pXYZ = getCurrentPosition(index, handles);     % ��ȡ�ؼ�λ��
        if pXYZ(1) ~= prePosition(index,1) || pXYZ(2) ~= prePosition(index,2) || pXYZ(3) ~= prePosition(index,3)
            setNewPosition(index, pXYZ);     % ����ȫ�ֱ���
            refreshGuiPosition(handles)		% ˢ�µ�ǰ��ʾ������
        end
    end
end
haveInitialized = 1;


function comPortOff()
% close all comport
% stop and delete comport
disp('Function: comPortOff()');
scoms = instrfind; %��������Ч�Ĵ��ж˿ڶ����� out ������ʽ����
if size(scoms,1) == 0
    return;
else
    stopasync(scoms); %ֹͣ�첽��д����
    fclose(scoms);
    delete(scoms);
end

function sendCommand(index, strCMD, handles)
% ���ض����ڷ����������ض����ڷ�������
% index �ؼ���������
% strCMD ������������
disp('Function: sendCommand()');
disp(newline);

vv =10;
dd =13;
global scoms;
com = scoms{index};
%com = get(handles.figure1, 'UserData');      %��ȡ���ڶ�����
numSend = getappdata(handles.figure1, 'numSend');
val = strCMD;
numSend = numSend + length(val);
% set(handles.trans, 'string', num2str(numSend));
setappdata(handles.figure1, 'numSend', numSend);
EnterSend_flag = 1;     %DIC��΢��Э����ĩβ�������ӻس��ַ���������΢���ɸ���
I_flag=0;
if ~isempty(val)
    %% ���õ������ĳ�ֵ
    n = 1000;
    while n
        %% ��ȡ���ڵĴ���״̬��������û������д���ݣ�д������
        str = get(com, 'TransferStatus');
        if ~(strcmp(str, 'write') || strcmp(str, 'read&write')) 
            if ~I_flag
             fwrite(com, val, 'uint8', 'async'); %����д�봮��
                I_flag=1;
            end
        end
        if EnterSend_flag
            str = get(com, 'TransferStatus');
            if ~(strcmp(str, 'write') || strcmp(str, 'read&write'))
                 fwrite(com, vv); %����д�봮��
                 fwrite(com, dd); %����д�봮��
                 break;
            end
        end 
        n = n - 1; %������
    end
end

function getMessageFromComPort(obj, event, handles)
% �Ӵ��ڻ�ȡ����
% ��ȡ����
global ifreceived timeCount numSwitch prePosition elementAvailable haveInitialized;
% disp('Function: getMessageFromComPort()');
hasData = getappdata(handles.figure1, 'hasData'); %�����Ƿ��յ�����
strRec = getappdata(handles.figure1, 'strRec');   %�������ݵ��ַ�����ʽ����ʱ��ʾ������
numRec = getappdata(handles.figure1, 'numRec');   %���ڽ��յ������ݸ���

    % ������û�н��յ����ݣ��ȳ��Խ��մ�������
    if ~hasData || ifreceived == 0
        bytes(obj, event, handles);
        % ��ʼ����ɺ���г�ʱ��Ӧ
        %{
        %20210317
        if haveInitialized == 1
            haveInitialized = 0;
            timeCount = timeCount + 1;
            if timeCount == 3
                timeCount = 0;     %��־λ��λ
                % ��ʱ��Ӧ�����µ�ǰλ��
                disp('Timeout position check.');
                if elementAvailable(numSwitch) == 1
                    pXYZ = getCurrentPosition(numSwitch, handles);     %��ȡ�ؼ�λ��
                    if length(pXYZ) == 3
                        length(pXYZ)
                        if str2num(pXYZ{1}) ~= prePosition(numSwitch,1) || str2num(pXYZ{2}) ~= prePosition(numSwitch,2) || str2num(pXYZ{3}) ~= prePosition(numSwitch,3)
                            setNewPosition(numSwitch, pXYZ);     %����ȫ�ֱ���
                            refreshGuiPosition(handles)		% ˢ�µ�ǰ��ʾ������
                        end
                        disp(['Update successfully!',newline])
                    else
                        disp(['Update failed!',newline])
                    end
                    
                end
            end
            haveInitialized = 1;
        end
        %}
        % ��ʱ��������仯��������
        %{
        if timeCount == 0
            timeCount = 1;
        else
            %����50msˢ��һ�λ�����
            %���������ʱ����ʱ100ms����һ�οؼ�����
            %���µ�ǰλ��
            timeCount = 0;
            disp('Timeout position check.');
            if elementAvailable(numSwitch) == 1
                pXYZ = getCurrentPosition(numSwitch, handles);     %��ȡ�ؼ�λ��
                if pXYZ(1) ~= prePosition(numSwitch,1) || pXYZ(2) ~= prePosition(numSwitch,2) || pXYZ(3) ~= prePosition(numSwitch,3)
                    setNewPosition(numSwitch, pXYZ);     %����ȫ�ֱ���
                    refreshGuiPosition(handles)		% ˢ�µ�ǰ��ʾ������
                end
            end
        end
        %}
    end
    % �����������ݣ����ش�������
    if hasData && (strRec(length(strRec)) == char(13))
         % ��������ʾģ��ӻ�����
        % ��ִ����ʾ����ģ��ʱ�������ܴ������ݣ�����ִ��BytesAvailableFcn�ص�����
        setappdata(handles.figure1, 'isShow', true); 
        % ��Ҫ��ʾ���ַ������ȳ���10000�������ʾ��
        if length(strRec) > 10000
            strRec = '';
            setappdata(handles.figure1, 'strRec', strRec);
        end
        % ��ʾ����
        set(handles.xianshi, 'string', strRec);
        % ���½��ռ���
        %set(handles.rec,'string', numRec);
        % ����hasData��־���������������Ѿ���ʾ
        setappdata(handles.figure1, 'hasData', false);
        % ��������ʾģ�����
        setappdata(handles.figure1, 'isShow', false);
        
        ifreceived = 1;
        timeCount = 0;     %��־λ��λ
        %Msg = strRec;    %��ȡ���յ�����Ϣ
        %��ս�����
        %strRec = '';
        %setappdata(handles.figure1, 'strRec', strRec);
    end


function response = sendAndGetResponse(index, strCMD, handles)
% send a command and get a response, need open the comport first
% index: element index
% strCMD: command string
% handles: gui global handle
global ifreceived haveInitialized;
disp('Function: sendAndGetResponse()');
disp(newline);

response = '';
sendCommand(index, strCMD, handles);
%waiting for response
haveInitialized = 0;
tic
%old
while (1)
    pause(0.15);
    if (ifreceived == 1)
        response = getappdata(handles.figure1, 'strRec');    % get comport information
        ifreceived = 0;
        setappdata(handles.figure1, 'strRec', '');
        break;
    elseif (toc > 2)
        % over 2 second then return empty array
        break;
    end
end
%new


haveInitialized = 1;
response
% length(response)
%��Ϣ���룬�ִ�
%comPortOnOrOff(strCOM, 0, handles);    % �رմ���

function homeInSet(index,x,y,z,handles)
% set homeIn position
% index: element index
% x,y,z: position to be set
% handles: gui global handle

sendAndGetResponse(index, ['INSET ',num2str(x),' ',num2str(y),' ',num2str(z)], handles)

function strNums = getCurrentPosition(index, handles)
% get element current position
% index: element index
% handles: gui global handle
global elementAvailable;
disp('Function: getCurrentPosition()');
disp(newline);

if (index < 1 || index > 9)
    disp(['Index error!',newline]);
    strNums = 1;
    return;
end
if (elementAvailable(index) == 1)
    %com = scoms{index};
    msg = sendAndGetResponse(index, 'P', handles);
    msg = removeEndEnterChar(msg);		% remove '/n'
    if isempty(msg)
        disp(['No reply.',newline]);
        strNums = 0;
        return;
    end
    % string split
    strs = split(msg,char(9));
    if (length(strs) ~= 3)
        disp(['Return format error!',newline]);
        strs
        strNums = 2;
        return;
    else
        strNums = strs;
    end
end

function setNewPosition(index,strNums)
% store new position
global prePosition newPosition;
disp(['Function: setNewPosition()',newline]);
strNums
prePosition(index, 1) = str2num(strNums{1});
prePosition(index, 2) = str2num(strNums{2});
prePosition(index, 3) = str2num(strNums{3});
newPosition(index, 1) = str2num(strNums{1});
newPosition(index, 2) = str2num(strNums{2});
newPosition(index, 3) = str2num(strNums{3});

function refreshGuiPosition(handles)
% refresh the displayed position
global numSwitch newPosition;
set(handles.xPosition_edit, 'string', newPosition(numSwitch,1)/100);
set(handles.yPosition_edit, 'string', newPosition(numSwitch,2)/100);
set(handles.zPosition_edit, 'string', newPosition(numSwitch,3)/100);

function commandZEROReaction(handles)
% set current position to (0,0,0)
global numSwitch prePosition newPosition absZero;
disp('Function: commandZEROReaction()');

%goto function
% check the same of current position and displayed position
pDisplay = zeros(1,3);
pDisplay(1) = str2num(get(handles.xPosition_edit,'String'))*100;
pDisplay(2) = str2num(get(handles.yPosition_edit,'String'))*100;
pDisplay(3) = str2num(get(handles.zPosition_edit,'String'))*100;
if (pDisplay(1) ~= prePosition(numSwitch,1)) || (pDisplay(2) ~= prePosition(numSwitch,2)) || (pDisplay(3) ~= prePosition(numSwitch,3))
    % current element move to displayed position
    goTo(numSwitch,pDisplay,handles);
end

absZero(numSwitch,:) = absZero(numSwitch,:) + newPosition(numSwitch,:);     % update the adsZero
saveParameterToConfigFile();
updateAxisLimits(numSwitch,newPosition(numSwitch,:));     % update the available limits
msg = sendAndGetResponse(numSwitch, 'ZERO', handles);
% absZero
% axisLimits axisLimits

% check end with '/n'
if (msg(length(msg))) == char(13)
    msg = msg(1:(length(msg)-1));
end
if isempty(msg)
	disp(['No reply.',newline]);
	return;
end
switch(msg)
    case 'E'
        disp(['Setting failed.',newline]);
    case 'A'
        disp(['Setting successfully.',newline]);
        prePosition(numSwitch,:) = [0,0,0];
        newPosition(numSwitch,:) = [0,0,0];
        refreshGuiPosition(handles);
    otherwise
        disp(['Return format error.',newline]);
        msg
end

function commandMoveReaction(index, cmdType, x, y, z, handles)
% �ƶ������������λ��
% index �ؼ�����
% cmdType �ƶ���ʽ��ABS ���������ƶ���REL ��������ƶ�Ŀ���������룻RELD ��������ƶ����λ��������
% x y z ������������

global prePosition newPosition elementAvailable;

%�ж������Ƿ�Ϸ�
if (index < 1 || index > 9)
    disp(['Index error.',newline]);
    return;
end
% check cmdType
if strcmp(cmdType,'ABS') && strcmp(cmdType,'REL') && strcmp(cmdType,'RELD')
    disp(['Move cmd error.',newline]);
    return;
end
% generate cmd string
switch(cmdType)
    case 'ABS'
        cmd = ['ABS ',num2str(x),' ',num2str(y),' ',num2str(z)];
    case 'REL'
        cmd = ['REL ',num2str(x - prePosition(index,1)),' ',num2str(y - prePosition(index,2)),' ',num2str(z - prePosition(index,3))];
    case 'RELD'
        cmd = ['REL ',num2str(x),' ',num2str(y),' ',num2str(z)];
        x = x + prePosition(index,1);
        y = y + prePosition(index,2);
        z = z + prePosition(index,3);
end
% send cmd
if (elementAvailable(index) == 1)
    %com = scoms{index};
    msg = sendAndGetResponse(index, cmd, handles);
    
    % check newline char
    if (msg(length(msg))) == char(13)
        msg = msg(1:(length(msg)-1));
    end
    if isempty(msg)
        disp(['No reply.',newline]);
        return;
    end

    switch(msg)
        case 'E'
            disp(['Setting failed.',newline]);
            msg
        case 'A'
            disp(['Setting successfully.',newline]);
            % update position
            prePosition(index,:) = [x,y,z];
            newPosition(index,:) = [x,y,z];
        otherwise
            disp(['Return format error!',newline]);
            msg
    end
else
    disp(['Comport unavailable.',newline]);
end

function newNum = xCheckLimit(index,num,handles)
% x���꼫�޼��
% index �ؼ�����
% num ��������
% handles guiȫ�־��
global numSwitch axisLimits;
if num < axisLimits(index,1)
    num = axisLimits(index,1);     %�����ƶ�
    if index == numSwitch
        set(handles.xPosition_edit,'string',num/100);     %������ʾ����
        limitsGuiReaction(1,handles.xMinus_pushbutton,handles.xPlus_pushbutton);     %����gui�ؼ���ʶ
    end
elseif num > axisLimits(index,2)
    num = axisLimits(index,2);     %�����ƶ�
    if index == numSwitch
        set(handles.xPosition_edit,'string',num/100);     %������ʾ����
        limitsGuiReaction(2,handles.xMinus_pushbutton,handles.xPlus_pushbutton);     %����gui�ؼ���ʶ
    end
else
    if index == numSwitch
        limitsGuiReaction(0,handles.xMinus_pushbutton,handles.xPlus_pushbutton);     %����gui�ؼ���ʶ
    end
end
newNum = num;

function newNum = yCheckLimit(index,num,handles)
% y���꼫�޼��
% index �ؼ�����
% num ��������
% handles guiȫ�־��
global numSwitch axisLimits;
if num < axisLimits(index,3)
    num = axisLimits(index,3);     %�����ƶ�
    if index == numSwitch
        set(handles.yPosition_edit,'string',num/100);     %������ʾ����
        limitsGuiReaction(1,handles.yMinus_pushbutton,handles.yPlus_pushbutton);     %����gui�ؼ���ʶ
    end
elseif num > axisLimits(index,4)
    num = axisLimits(index,4);     %�����ƶ�
    if index == numSwitch
        set(handles.yPosition_edit,'string',num/100);     %������ʾ����
        limitsGuiReaction(2,handles.yMinus_pushbutton,handles.yPlus_pushbutton);     %����gui�ؼ���ʶ
    end
else
    if index == numSwitch
        limitsGuiReaction(0,handles.yMinus_pushbutton,handles.yPlus_pushbutton);     %����gui�ؼ���ʶ
    end
end
newNum = num;

function newNum = zCheckLimit(index,num,handles)
% z���꼫�޼��
% index �ؼ�����
% num ��������
% handles guiȫ�־��
global numSwitch axisLimits;
if num < axisLimits(index,5)
    num = axisLimits(index,5);     %�����ƶ�
    if index == numSwitch
        set(handles.zPosition_edit,'string',num/100);     %������ʾ����
        limitsGuiReaction(1,handles.zMinus_pushbutton,handles.zPlus_pushbutton);     %����gui�ؼ���ʶ
    end
elseif num > axisLimits(index,6)
    num = axisLimits(index,6);     %�����ƶ�
    if index == numSwitch
        set(handles.zPosition_edit,'string',num/100);     %������ʾ����
        limitsGuiReaction(2,handles.zMinus_pushbutton,handles.zPlus_pushbutton);     %����gui�ؼ���ʶ
    end
else
    if index == numSwitch
        limitsGuiReaction(0,handles.zMinus_pushbutton,handles.zPlus_pushbutton);     %����gui�ؼ���ʶ
    end
end
newNum = num;

function goTo(index,newP,handles)
% goto button, check movable first
% index: element index
% newP: target position, (x y z)
% global axisLimits;
x = newP(1);
% x = xCheckLimit(index,x,handles);
% if x < axisLimits(index,1)
%     x = axisLimits(index,1);     %�����ƶ�
%     set(handles.xPosition_edit,'string',x);     %������ʾ����
%     limitsGuiReaction(1,handles.xMinus_pushbutton,handles.xPlus_pushbutton);     %����gui�ؼ���ʶ
% elseif x > axisLimits(index,2)
%     x = axisLimits(index,2);     %�����ƶ�
%     set(handles.xPosition_edit,'string',x);     %������ʾ����
%     limitsGuiReaction(2,handles.xMinus_pushbutton,handles.xPlus_pushbutton);     %����gui�ؼ���ʶ
% else
%     limitsGuiReaction(0,handles.xMinus_pushbutton,handles.xPlus_pushbutton);     %����gui�ؼ���ʶ
% end
y = newP(2);
% y = yCheckLimit(index,y,handles);
% if y < axisLimits(index,3)
%     y = axisLimits(index,3);     %�����ƶ�
%     set(handles.yPosition_edit,'string',y);     %������ʾ����
%     limitsGuiReaction(1,handles.yMinus_pushbutton,handles.yPlus_pushbutton);     %����gui�ؼ���ʶ
% elseif y > axisLimits(index,4)
%     y = axisLimits(index,4);     %�����ƶ�
%     set(handles.yPosition_edit,'string',y);     %������ʾ����
%     limitsGuiReaction(2,handles.yMinus_pushbutton,handles.yPlus_pushbutton);     %����gui�ؼ���ʶ
% else
%     limitsGuiReaction(0,handles.yMinus_pushbutton,handles.yPlus_pushbutton);     %����gui�ؼ���ʶ
% end
z = newP(3);
% z = zCheckLimit(index,z,handles);
% if z < axisLimits(index,5)
%     z = axisLimits(index,5);     %�����ƶ�
%     set(handles.zPosition_edit,'string',z);     %������ʾ����
%     limitsGuiReaction(1,handles.zMinus_pushbutton,handles.zPlus_pushbutton);     %����gui�ؼ���ʶ
% elseif z > axisLimits(index,6)
%     z = axisLimits(index,6);     %�����ƶ�
%     set(handles.zPosition_edit,'string',z);     %������ʾ����
%     limitsGuiReaction(2,handles.zMinus_pushbutton,handles.zPlus_pushbutton);     %����gui�ؼ���ʶ
% else
%     limitsGuiReaction(0,handles.zMinus_pushbutton,handles.zPlus_pushbutton);     %����gui�ؼ���ʶ
% end
%commandMoveReaction(index, 'ABS', x, y, z, handles);     %�����ƶ�
commandMoveReaction(index, 'REL', x, y, z, handles);     %����ƶ�

function msg = removeEndEnterChar(str)
% �Ƴ��ַ���ĩβ�Ļس�
% �ж����һ���ַ��Ƿ�Ϊ���з�

if isempty(str) || (str(length(str))) ~= char(13)
	msg = str;
else
    msg = str(1:(length(str)-1));
end

function commandSTOPReaction(handles)
% ֹͣ���пؼ����κ��ƶ�
global numSwitch elementAvailable;
flag = [];
i = numSwitch;
%for i = 1:9
    if elementAvailable(i) == 1
        msg = sendAndGetResponse(i, 'STOP', handles);
        
        %�ж����һ���ַ��Ƿ�Ϊ���з�
        if (msg(length(msg))) == char(13)
            msg = msg(1:(length(msg)-1));
        end
        if isempty(msg)
            disp(['No reply.',newline]);
            return;
        end
        if (msg ~= 'A')
            flag(i) = 0;
            disp(['Stop failed!',newline])
        else
            flag(i) = 1;
            pXYZ = getCurrentPosition(i, handles);     %��ȡ��λ��
            setNewPosition(i,pXYZ);     %����ȫ�ֱ���
        end
    end
%end
flag
% ��ֹͣ�ɹ����µ�ǰ�ؼ�λ����ʾ
if (flag(i) == 1)
    refreshGuiPosition(handles);
end

function getLimitsOfAxis(index, handles)
% ��ȡ�ؼ������ƶ��Ƿ񵽴�λ�Ƽ���
% index �ؼ�����
% handles guiȫ�־��
global scoms;
com = scoms{index};
if elementAvailable(index) == 1
	msg = sendAndGetResponse(index, 'LIMITS', handles);
    
    %�ж����һ���ַ��Ƿ�Ϊ���з�
    if (msg(length(msg))) == char(13)
        msg = msg(1:(length(msg)-1));
    end
    if isempty(msg)
        disp(['No reply.',newline]);
        return;
    end

    num = str2num(msg);
    %%��֤�����Ƿ���Ч
    if isempty(num) || num < 0 || num > 63
        disp(['Return error!',newline]);
        num
        return;
    end
    %���ֽ���
    xlimit = bitand(binNum,3);
    ylimit = bitshift(xlimitbitand(binNum,12),-2);
    zlimit = bitshift(xlimitbitand(binNum,48),-4);
    %gui reaction
    limitsGuiReaction(xlimit,handles.xMinus_pushbutton,handles.xPlus_pushbutton);
    limitsGuiReaction(ylimit,handles.yMinus_pushbutton,handles.yPlus_pushbutton);
    limitsGuiReaction(zlimit,handles.zMinus_pushbutton,handles.zPlus_pushbutton);
    
    
end

function limitsGuiReaction(limitResponse, hObjectLow, hObjectHeight)
% ��Ӧ�ߵ�������ʾ�ؼ���Ӧ
% limitResponse �ؼ��ƶ����ޱ�ʶ���� 0 �ޣ�1 �ͼ��ޣ�2 �߼��ޣ�3 �ߵͶ�����
% hObjectLow �ͼ�����ʾ�ؼ����
% hObjectHeight �ͼ�����ʾ�ؼ����
switch (limitResponse)
    case 0
        if get(hObjectLow,'Value') == 1
            set(hObjectLow,'Value',0);
            set(hObjectLow,'BackgroundColor',[0.9,0.9,0.9]);
        end
        if get(hObjectHeight,'Value') == 1
            set(hObjectHeight,'Value',0);
            set(hObjectHeight,'BackgroundColor',[0.9,0.9,0.9]);
        end
    case 1
        if get(hObjectLow,'Value') == 0
            set(hObjectLow,'Value',1);
            set(hObjectLow,'BackgroundColor',[1,0,0]);
        end
        if get(hObjectHeight,'Value') == 1
            set(hObjectHeight,'Value',0);
            set(hObjectHeight,'BackgroundColor',[0.9,0.9,0.9]);
        end
    case 2
        if get(hObjectLow,'Value') == 1
            set(hObjectLow,'Value',0);
            set(hObjectLow,'BackgroundColor',[0.9,0.9,0.9]);
        end
        if get(hObjectHeight,'Value') == 0
            set(hObjectHeight,'Value',1);
            set(hObjectHeight,'BackgroundColor',[1,0,0]);
        end
    case 3
        if get(hObjectLow,'Value') == 0
            set(hObjectLow,'Value',1);
            set(hObjectLow,'BackgroundColor',[1,0,0]);
        end
        if get(hObjectHeight,'Value') == 0
            set(hObjectHeight,'Value',1);
            set(hObjectHeight,'BackgroundColor',[1,0,0]);
        end
    otherwise
        disp(['�����־λ���ݴ���',newline]);
        return;
end

function isMoving = checkIsMoving(index,handles)
% check the element's moving status, 0--unmoving; otherwise--moving
% handles: gui global handle

%{
%�Լ���д��,ֻ�����prePosition
global prePosition;
currentPosition = getCurrentPosition(index,handles);
if (prePosition(index,1) ~= currentPosition(1) || prePosition(index,2) ~= currentPosition(2) || prePosition(index,3) ~= currentPosition(3))
    prePosition(index,1) = currentPosition(1);
    prePosition(index,1) = currentPosition(1);
    prePosition(index,1) = currentPosition(1);
    isMoving = 1;
else
    isMoving = 0;
end
%}
% old cmd string
msg = sendAndGetResponse(index, 'S', handles);     % get moving status
msg = removeEndEnterChar(msg);		% remove '/n' end
if isempty(msg)
	disp(['No reply.',newline]);
	return;
end
if (strcmp(msg,'0')) 
    isMoving = 0;
else
    isMoving = 1;
end
switch (msg)
    case '0'
        isMoving = 0;
    case '1'
        isMoving = 1;
    otherwise
        disp(['Return format error!',newline]);
        msg
        isMoving = -1;
end

%ָ������
function obj = getObjective(handles)
% ��ȡ�ﾵ���� 0 ��ȡʧ�ܣ�1 �ͱ�����2 �߱�����������
% handles guiȫ�־��
msg = sendAndGetResponse(1, 'OBJ', handles);
msg = removeEndEnterChar(msg);     %ɾ���ַ���ĩ�Ļ��з�
if isempty(msg)
	disp(['No reply.',newline]);
	return;
end
num = str2num(msg);
if num == 1 || num == 2
    obj = num;
else
    obj = 0;
end

%ָ������
function setObjective(objnum,handles)
% �л��ﾵ
% objnum 1 �ͱ�����2 �߱������ݶ���
% handles guiȫ�־��
switch(objnum)
    case 1
%         'OBJ 1'
        msg = sendAndGetResponse(1, 'OBJ 1', handles);
    case 2
%         'OBJ 2'
        msg = sendAndGetResponse(1, 'OBJ 2', handles);
    otherwise
        disp(['Input error.',newline]);
%         objnum
        return;
end
msg = removeEndEnterChar(msg);		% remove '/n' end
if isempty(msg)
	disp(['No reply.',newline]);
	return;
end
if msg == 'A'
    disp(['Object switch successfully.',newline]);
    if strcmp(get(handles.objswitch_pushbutton,'String'),'��4')
        set(handles.objswitch_pushbutton,'String','��40');
    else
        set(handles.objswitch_pushbutton,'String','��4');
    end
else
    disp(['Object switch failed.',newline]);
end

% old version
function comoveOfInjectionBaseOnScope(index,pDisplay,offsetFlag,handles)
% Microscope and injection comove
% base on microscope to move injection
% index: element index
% pDisplay: position of destination
% offsetFlag: 1, with offset; 0, without offset
% handles: gui global handle

global angleOffset prePosition;
%�ж���΢���Ƿ���ƶ�
tempP = zeros(1,3);
tempP(1) = xCheckLimit(1,pDisplay(1),handles);
tempP(2) = yCheckLimit(1,pDisplay(2),handles);
tempP(3) = zCheckLimit(1,pDisplay(3),handles);
if pDisplay(1) ~= tempP(1) || pDisplay(2) ~= tempP(2) || pDisplay(3) ~= tempP(3)
    str = ['��΢���޷��ƶ�����λ��',newline];
    disp(str);
    return;
end

%Эͬ�ƶ��ؼ�������ʱΪ3��΢��
%������΢���ƶ�������΢������
detaP = pDisplay - prePosition(1,:);     %��΢��λ�Ʊ仯
angleOffset(index)


theta = angleOffset(index)/180*pi;
dP = zeros(1,3);     %�ȴ�仯��
dP(1) = detaP(1)*cos(theta) + detaP(2)*sin(theta);
dP(2) = -detaP(1)*sin(theta) + detaP(2)*cos(theta);
dP(3) = detaP(3);
%����
if offsetFlag == 1
    dP(1) = dP(1) + dP(1) * xOffset(index,1) + dP(2) * yOffset(index,1) + dP(3) * zOffset(index,1)
    dP(2) = dP(2) + dP(1) * xOffset(index,2) + dP(2) * yOffset(index,2) + dP(3) * zOffset(index,2)
end
%΢���ж��Ƿ���ƶ�
tempP(1) = prePosition(index,1)+dP(1) - xCheckLimit(4,prePosition(index,1)+dP(1),handles);
tempP(2) = prePosition(index,2)+dP(2) - yCheckLimit(4,prePosition(index,2)+dP(2),handles);
tempP(3) = prePosition(index,3)+dP(3) - zCheckLimit(4,prePosition(index,3)+dP(3),handles);
if tempP(1) ~= 0 || tempP(2) ~= 0 || tempP(3) ~= 0
    str = ['΢���޷��ƶ�����λ��',newline];
    disp(str);
    return;
end
%����Эͬ�ƶ�
commandMoveReaction(index, 'RELD', dP(1), dP(2), dP(3), handles);     %΢������ƶ�

commandMoveReaction(1, 'RELD', detaP(1), detaP(2), detaP(3), handles);     %��΢������ƶ�
disp(['Эͬ�ƶ��ɹ�',newline]);


function dP = comoveOfInjection(index,detaP)
% Using Microscope movement to compute injection movement
% index: injection index
% detaP: microscope position change
disp(['Function: comoveOfInjection',newline]);

theta = angleOffset(index)/180*pi;
dP = zeros(1,3);     %store position change
dP(1) = detaP(1)*cos(theta) + detaP(2)*sin(theta);
dP(2) = -detaP(1)*sin(theta) + detaP(2)*cos(theta);
dP(3) = detaP(3);
%to check whether the injection could go to this position
tempP(1) = prePosition(index,1)+dP(1) - xCheckLimit(index,prePosition(index,1)+dP(1),handles);
tempP(2) = prePosition(index,2)+dP(2) - yCheckLimit(index,prePosition(index,2)+dP(2),handles);
tempP(3) = prePosition(index,3)+dP(3) - zCheckLimit(index,prePosition(index,3)+dP(3),handles);
if tempP(1) ~= 0 || tempP(2) ~= 0 || tempP(3) ~= 0
	str = ['The injection can not go to this position.',newline];
	disp(str);
	return;
end
            
%do co-move
commandMoveReaction(index, 'RELD', dP(1), dP(2), dP(3), handles);     %injection move

function mPosition = transformImagePositionToMicroscopePosition()
% transform the image position stored in global parameter (loc) to microscope position
% To be checkout
global loc prePosition;
if (loc(1) == 0 && loc(2) == 0)
    disp(['Get the position first.',newline]);
    return;
end
mPosition = zeros(1,2);
mPosition(1) = prePosition(1,1) + round((loc(1,2)-512)*50/3);
mPosition(2) = prePosition(1,2) - round((loc(1,1)-688)*50/3);

function comoveInjectionWithInjection(indexMaster, indexSlave, dM, offsetFlag, handles)
% slave injection comove depending on master injection
% indexMaster: master element index
% indexSlave: slave element index
% dM: position change of destination of master element
% offsetFlag: 1, with offset; 0, without offset
% handles: GUI global handle

global angleOffset prePosition xOffset yOffset zOffset ;

% compute slave element based on master element
% dM = pDisplay - prePosition(indexMaster,:);     % position change

% theta = (angleOffset(indexSlave) - angleOffset(indexMaster)) / 180 * pi
% dS(1) = dM(1) * cos(theta) + dM(2) * sin(theta);
% dS(2) = -dM(1) * sin(theta) + dM(2) * cos(theta);
% dS(3) = dM(3);
dS = coordinateTransformation(dM,indexMaster,indexSlave);

%error compensation (to be tested)
if offsetFlag == 1
    dM(1) * (xOffset(indexMaster,1) - xOffset(indexSlave,1))
    dM(2) * (yOffset(indexMaster,1) - yOffset(indexSlave,1))
    dM(3) * (zOffset(indexMaster,1) - zOffset(indexSlave,1))
    dM(1) * (xOffset(indexMaster,2) - xOffset(indexSlave,2))
    dM(2) * (yOffset(indexMaster,2) - yOffset(indexSlave,2))
    dM(3) * (zOffset(indexMaster,2) - zOffset(indexSlave,2))
    dS(1) = dS(1) - dM(1) * (xOffset(indexMaster,1) - xOffset(indexSlave,1)) - dM(2) * (yOffset(indexMaster,1) - yOffset(indexSlave,1)) - dM(3) * (zOffset(indexMaster,1) - zOffset(indexSlave,1))
    dS(2) = dS(2) - dM(1) * (xOffset(indexMaster,2) - xOffset(indexSlave,2)) - dM(2) * (yOffset(indexMaster,2) - yOffset(indexSlave,2)) - dM(3) * (zOffset(indexMaster,2) - zOffset(indexSlave,2))
end

dS(1) = round(dS(1))
dS(2) = round(dS(2))

%check moveable
% tempP = prePosition(indexSlave,:) + dS;
% tempP = checkGoToDestination(indexSlave, tempP, handles) - tempP
% % 
% if tempP(1) ~= 0 || tempP(2) ~= 0 || tempP(3) ~= 0
%     str = ['Can not go to that position.',newline];
%     disp(str);
%     return;
% end

% do comove
commandMoveReaction(indexSlave, 'RELD', dS(1), dS(2), dS(3), handles);     % slave element move
disp(['Comove successflly.',newline]);

function dPTo = coordinateTransformation(dPFrom,indexFrom,indexTo)
% transform the coordinate in element indexFrom to indexTo
% dPFrom: point / position change in coordinate_from
% indexFrom: index of the element_from
% indexTo: index of the element_to

global angleOffset;
theta = (angleOffset(indexTo) - angleOffset(indexFrom)) / 180 * pi
dPTo(1) = dPFrom(1) * cos(theta) + dPFrom(2) * sin(theta);
dPTo(2) = -dPFrom(1) * sin(theta) + dPFrom(2) * cos(theta);
dPTo(3) = dPFrom(3);

function tempP = checkGoToDestination(index, pDisplay, handles)
% check whether element can go to destination
% index: element index
% pDisplay: the displayed Position of destination
% handles: GUI global handles

%global prePosition;
tempP = zeros(1,3);
tempP(1) = xCheckLimit(index,pDisplay(1),handles);
tempP(2) = yCheckLimit(index,pDisplay(2),handles);
tempP(3) = zCheckLimit(index,pDisplay(3),handles);
if pDisplay(1) ~= tempP(1) || pDisplay(2) ~= tempP(2) || pDisplay(3) ~= tempP(3)
    if index == 1
        str = ['Microscope can not move to destination.',newline];
    else
        str = ['Injection ', num2str(index-1),' can not move to destination.',newline];
    end
    disp(str);
    return;
end

function doComove(pDisplay,handles)
% do comove based on the checkbox list
% pDisplay: destination of master element
% handles: gui global handles

global coMoveFlag numSwitch prePosition;
for i = 1:9
    if coMoveFlag(i) == 1
        if i ~= numSwitch
            comoveInjectionWithInjection(numSwitch,i,pDisplay-prePosition(numSwitch,:),0,handles);
        end
    end
end

function descStr = getElementDescStr(com,handles)
% get element description from USB comport
% com: comport object
% handles: GUI global handle
descStr = sendAndGetResponse(com, 'DESC', handles);
descStr = removeEndEnterChar(descStr);		% delete the ending enter char 
if isempty(descStr)
	disp(['No reply.',newline]);
	return;
end

function getZAngle(handles)
% get angleZ from sensor
% handles: gui global handles

global angleZ elementAvailable;
disp('Function: getZAngle()');
for i = 1:8
    if elementAvailable(i+1) == 1
        msg = sendAndGetResponse(i+1, 'ANGLE', handles);
        msg = removeEndEnterChar(msg);     % remove '/n' end
        if isempty(msg)
            disp(['No reply.',newline]);
            return;
        end
        angleZ(i) = str2num(msg);
    end
end

function xzComoveOfInjection(index,dx,handles)
% Injection x and z comove, x guides z
% index: element index
% dx: x position change
% handles: gui global handle

global elementAvailable prePosition ;
if elementAvailable(index) == 1
    % open the comove mod
    msg = sendAndGetResponse(index, 'APPROACH 1', handles);      %
    msg = removeEndEnterChar(msg);		% remove '/n' end
    if isempty(msg)
        disp(['No reply.',newline]);
        return;
    elseif strcmp(msg,'A')
        disp(['Setting ON successfully.',newline]);
    end
    try
        % do comove
        % x -50um
%         pDisplay = prePosition(index,:) + [-5000,0,0]
        pDisplay = prePosition(index,:) + [dx,0,0]
        goTo(index,pDisplay,handles);
    end
    
    % close the comove mod
    msg = sendAndGetResponse(index, 'APPROACH 0', handles);
    msg = removeEndEnterChar(msg);		% remove '/n' end
    if isempty(msg)
        disp(['No reply.',newline]);
        return;
        elseif strcmp(msg,'A')
        disp(['Setting OFF successfully.',newline]);
    end
end

function microscopeP = imageP2MicroscopeP(imageP)
% convert image coordinate to microscope coordinate
% imageP: pixel position in a image (1376*1024)

global prePosition;
microscopeP(1) = prePosition(1,1) + round((imageP(2)-512)*50/3); % 512 = 1024/2; 50/3: 6pixels = 1um
microscopeP(2) = prePosition(1,2) - round((imageP(1)-688)*50/3); % 688 = 1376/2
microscopeP(3) = prePosition(1,3);

function [tag,z] = contentEstimate(orgtag,injectionFlag,zStart,zEnd,handles)
% estimate the content in the view
% 1-in air;2-in water and see nothing;3-in water and see sample;4-have detected cell
% orgtag: origin tag
% injectionFlag: 0--no injection;1--move with injection
% zStart: start of z scan
% zEnd: end of z scan
% handles: gui global handle

global obj StepZ prePosition myResNet scoms;

tag = 0;
index = 1;
z = zStart;

switch(orgtag)
    case 1
        % initialize
        seq1D = zeros(1,6);     % local stds
        CDobj = ContentDetect(4);
        n = CDobj.N;
        for i = 1:(n+1)
            % get image
            frame = getsnapshot(obj);
            flushdata(obj);
            I1 = double(frame);
            seq1D(i) = std2(I1);
        end
        CDobj = ContentDetect1Initialize(CDobj,seq1D);
        
        % in air, stop if objective touch the water
        while(CDobj.tag == 0 && (z + StepZ) > zEnd)
            % get new image
            frame = getsnapshot(obj);
            flushdata(obj);
            I1 = double(frame);
            stdNext = std2(I1);
            CDobj = ContentDetect1(CDobj,stdNext);
            
            % z move ****************************
            z = z + StepZ;
            goTo(index,[prePosition(index,1),prePosition(index,2),z],handles);
            refreshGuiPosition(handles)		% refresh position diaplayed
            waitForPositionUpdate(index,handles);
            
        end
        % just into the water ***********************
        if (injectionFlag == 1)
            % for test
            kk = 0;
            while (kk > 20)
                pause(1);
                kk = kk + 1;
            end
            % focal plane correction
            % z+80000(z+800um)
            % tip detection
        end
        
    case 2
        flag = 0; % tissue detect flag
        threshold = 0.75; % tissue detect threshold
        % in water and see nothing, stop if detected tissue
        while(flag == 0 && (z + StepZ) > zEnd)
            % get new image
            frame = getsnapshot(obj);
            flushdata(obj);
            % surface detection
            guess = processing(frame,myResNet);
            if (guess(4) >= threshold)
                flag = 1;
            end
            
            % z move ************************
            z = z + StepZ;
            goTo(index,[prePosition(index,1),prePosition(index,2),z],handles);
            refreshGuiPosition(handles)		% refresh position diaplayed
            waitForPositionUpdate(index,handles);
            
        end
        % change move step
        StepZ = -100;      %?????
    case 3
        % in water and see sample
        % global cell detection
        %*********************** new 0702 ***********************
        % best cell select
        % return ============== bestCellFineInfo
        % a 1*1 struct that contain localCentroid[x,y]
        % and zRefer(z = z0 + zStep*zRefer)
        
        % initialize
        [CellFun, client] = py2matlab;
        py.importlib.reload(client);
        
        bestCellFlag = 0;
        allCellInfo = {}; % cell to save all cell info in each frame
        candidateCellInfo = {};  % cell to save the info of candidate cells
        haveCellInFrameFlag = {};
        % bestCellRoughIdxInfo = {};
        frameCount = 1;
        while(~bestCellFlag && (z + StepZ) > zEnd) % stop if find best cell
            % get new image
            tic
            
            snapshot = getsnapshot(obj);
            flushdata(obj); 
            %-- evaluate whole frame
            [allCellInfo, candidateCellInfo, bestCellFlag, bestCellRoughIdxInfo, haveCellInFrameFlag] = CellFun.findCellWholeFrame(snapshot, allCellInfo, candidateCellInfo, haveCellInFrameFlag, frameCount, client);
            %-- if find a good cell
            if bestCellFlag
                bestCellFineInfo = CellFun.getBestCellInfo(bestCellRoughIdxInfo, allCellInfo); % return bestCell centroid(mean), score
                disp(bestCellFineInfo)
                break;
            end
            frameCount = frameCount + 1;
            %pause(0.00001);
            %}
            % z move ************************
            z = z + StepZ;
            goTo(index,[prePosition(index,1),prePosition(index,2),z],handles);
            refreshGuiPosition(handles)		% refresh position diaplayed
            waitForPositionUpdate(index,handles);
            
            toc            
        end
        
end







function cellP = getCellPositionFromImage()
% cell detect from an image

global obj;

% get image
snapshot = getsnapshot(obj);
%         frame = ycbcr2rgb(frame);
flushdata(obj);
% cell detect
%%%%%%%%%%%
% get cell position in microscope
cellP = imageP2MicroscopeP(imageP);

function autoCellInject(index,cellP,injectionP,handles)
% the injection from it's currentP to cellP to do the auto move
% injection better to have same x and y with cell 
% index: injection index
% cellP: cell position
% injectionP: injection position
% handles: gui global handle

global prePosition currentInjectionP;

% check whether the selected injection can go to cellP
%check moveable
dM = cellP - injectionP;
dS = coordinateTransformation(dM,1,index);
tempP = prePosition(index,:) + dS;
tempP = checkGoToDestination(index, tempP, handles) - tempP;
% 
if tempP(1) ~= 0 || tempP(2) ~= 0 || tempP(3) ~= 0
    str = ['Can not go to that position.',newline];
    disp(str);
    return;
end

% compute start point
startP = computeRoutinePoint(index,cellP,-dM(3));
% injection go to start point
comoveInjectionWithInjection(1,index,[startP(1)-injectionP(1),startP(2)-injectionP(2),startP(3)-injectionP(3)],0,handles); % from injectionP to startP
currentInjectionP = pStart(1:3);
% approach to inject****************
cellTracingApproach(index,startP(4),[2,2,1],handles)

function cellTracingApproach(index,dA,cellP,shakingLimit,handles)
% step approach with cell tracing
% index: injection index
% dA: distance along injection centrol line between injection tip and cell
% cellP: cell position
% shakingLimit: cell detect shaking error acceptance
% handles: gui global handle

global StepA angleZ prePosition;

ddA = 0;
dPCell = zeros(1,3);
n = floor(StepA * sin(angleZ(index - 1) / 180 * pi) / 100);
StepZ = n * 100;    % StepA < 0; StepZ < 0
startP = prePosition(1,:) + [0,0,StepZ];
cells = zeros(2*n+1,4);
% shakingLimit = [2,2,1];
while (ddA ~= dA)
    % injection step move with offset
    if abs(dPCell(1)) > shakingLimit(1) && abs(dPCell(2)) > shakingLimit(2) && abs(dPCell(3)) > shakingLimit(3)
        approachWithOffset(index,StepA,dPCell,handles);
    else
        goToApproach(index,StepA,zeros(1,3),0,handles);
    end
    ddA = ddA + StepA;
    % cell tracing
    for i = 0:2*n
        destP = startP + i * 100;
        goTo(1,destP,handles);
        imageP = '**************[x,y,z,mark]';  % local single cell detect
        newCellP = imageP2MicroscopeP(imageP(1:3));
        cells(i,1:3) = newCellP;
        cells(i,4) = imageP(4);
    end
    % best result detect
    % *******************
    dPCell = newCellP - cellP;
    
    cellP = newCellP;
end


function P = computeRoutinePoint(index,baseP,dz)
% compute the point basing on injection orientation
% index: index of the injection
% baseP: based point
% dz: the plane dz higher above the cell
% handles: gui global handles
% P: return formate -- [px, py, pz, Lxoy]

global angleOffset angleZ;

theta = angleOffset(index) / 180 * pi;
alpha = angleZ(index - 1) / 180 * pi;
Lxoy = dz / tan(alpha)
dx = round(Lxoy * cos(theta))
dy = round(Lxoy * sin(theta))
P = [baseP(1) + dx, baseP(2) + dy, baseP(3) + dz, round(Lxoy)]


function positionInitiate(handles)
% get element position
global comList elementAvailable angleZ haveInitialized; 
% load config parameter
loadParameterFromConfigFile();
% close all port
comPortOff();
% initiate available port
availableCom = getAvailableComPort;     %get available comport list
%check comport available
count = 0;
for i = 1:size(comList, 1)
    for j = 1:size(availableCom, 1)
        if strcmp(comList{i},availableCom{j})
            elementAvailable(i) = 1;
            count = count + 1;
        end
    end
end

%open comport
for i = 1:9
    if elementAvailable(i) == 1
        flag = comPortOn(i, handles);	% open comport:com1
        if flag == 0
            elementAvailable(i) = 0;
            count = count - 1;
        %{
        else
            pXYZ = getCurrentPosition(i, handles);     % get position
            if length(pXYZ) == 3
                setNewPosition(i,pXYZ);     % update position
            else
                %error processing
                switch(pXYZ)
                    case 0
                        %No reply.
                        elementAvailable(i) = 0;
                    case 1
                        %Index error!
                    case 2
                        %Return format error!
                end
            end
            %}
        end
    end
end

refreshGuiPosition(handles);     % refresh gui

setButtonEnableOfElement(elementAvailable,handles);     % enable the buttons
%{
for i = 1:9
    if elementAvailable(i) == 1
        str1 = comList{i};    % comport name: com1
        msg = sendAndGetResponse(str1, 'P', handles);     % get position
        % update position
    end
end
%}

% get element description string
%{
k = 7;
if elementAvailable(k) == 1
%     str1 = 'APPROACH'
%     str1 = 'RELA 120000'
%     str1 = 'S'
    msg = sendAndGetResponse(k, str1, handles);
    msg = removeEndEnterChar(msg);		% remove '/n' end
    if isempty(msg)
        disp(['No reply.',newline]);
        return;
    end
%     msg1 = sendAndGetResponse(k, 'RELA 120000', handles);
%     msg1 = removeEndEnterChar(msg1);      % remove '/n' end
%     if isempty(msg1)
%         disp(['No reply.',newline]);
%         return;
%     end
end
%}
% initialize the angleZ
getZAngle(handles);
angleZ

%{
%initialze the object switch function
if elementAvailable(1) == 1
    % button initialize
    disp(['Initialized the objective switch button.',newline]);
    obj = getObjective(handles);
    switch(obj)
        case 0
            disp(['Objective initialization failed.',newline]);
            set(handles.objswitch_pushbutton,'Enable', 'off');
        case 1
            set(handles.objswitch_pushbutton,'String', '��40');
        case 2
            set(handles.objswitch_pushbutton,'String', '��4');
    end
else
    set(handles.objswitch_pushbutton,'Enable','off');
end
%}



% set initialization flag
if count == 0
    haveInitialized = 0;      %initialize failed
else
    haveInitialized = 1;      %initialize finished
end

function goToApproach(index,dA,desPosition,scopeFollowFlag,handles)
% XZ comove of injection
% index: element index
% dA: position change along injection centrol line
% desPosition: the destination position of injection tip in microscope
% scopeFollowFlag: 0--off,desPosition unused;1--on
% handles: gui global handle ,angleZ prePosition angleOffset

global elementAvailable;
disp(['Function: goToApproach()',newline]);
% check index
if (index < 2 || index > 9)
    disp(['Index error.',newline]);
    return;
end

% send cmd
if (elementAvailable(index) == 1)
%     switchApproach(index,1,handles);
    msg = sendAndGetResponse(index, ['RELA ', num2str(dA)], handles);
%     switchApproach(index,0,handles);
    msg = removeEndEnterChar(msg);      % remove '/n' end
    if isempty(msg)
        disp(['No reply.',newline]);
        return;
    end

    switch(msg)
        case 'E'
            disp(['Setting failed.',newline]);
            msg
        case 'A'
            disp(['Setting successfully.',newline]);
            % update injection position, when is not moving 
            waitForPositionUpdate(index,handles);
            % microscope go to cunrrent tip position
%             alpha = angleZ(index-1)/180*pi;
%             theta = angleOffset(index)/180*pi;
%             [dA*cos(alpha)*cos(theta),dA*cos(alpha)*sin(theta),dA*sin(alpha)]
%             pDestination = prePosition(1,:)+[dA*cos(alpha)*cos(theta),dA*cos(alpha)*sin(theta),dA*sin(alpha)];
            if scopeFollowFlag == 1
                goTo(1,desPosition,handles);
            end
            refreshGuiPosition(handles);     % refresh gui
        otherwise
            disp(['Return format error!',newline]);
            msg
    end
else
    disp(['Comport unavailable.',newline]);
end

function switchApproach(index,status,handles)
% switch the Approach status
% index: element index
% status: 0-OFF;1-ON

if status == 0
    msg = sendAndGetResponse(index, 'APPROACH 0', handles);
else
    msg = sendAndGetResponse(index, 'APPROACH 1', handles);
end
msg = removeEndEnterChar(msg);		% remove '/n' end
if isempty(msg)
    disp(['No reply.',newline]);
    return;
end

function waitForPositionUpdate(index,handles)
% check element movement status, if not update the position parameter
% index: element index
% handles: gui global handle

global elementAvailable;
disp(['Function: waitForPositionUpdate', newline])
flag = 1;
while(flag == 1)
    pause(0.05);
    % get new moving flag
    flag = checkIsMoving(index,handles)     % to be tested
    if (flag == 0)
        if (elementAvailable(index) == 1)
            % get current injection position
            pXYZ = getCurrentPosition(index, handles)
            setNewPosition(index,pXYZ);
        else
            disp(['Comport is unavailable.',newline]);
        end
    end
end

function approachWithOffset(index,dA,dPCell,handles)
% compansate the cell movement
% index: injection index,2-9
% dA: position change along injection central line
% dPCell: cell position change
% handles: gui global handle

global angleZ angleOffset prePosition currentInjectionP ;
disp(['Function: approachWithOffset()',newline]);
dPA = [dA*cos(angleZ(index-1)/180*pi),0,dA*sin(angleZ(index-1)/180*pi)];     % position change cause by dA
dPCell = coordinateTransformation(dPCell,1,index)      % position change cause by cell movement
dP = round(dPA + dPCell);
destP = dP + prePosition(index,:);
currentInjectionP = destP;
goTo(index,destP,handles);


function setButtonEnableOfElement(a,handles)
% ���ձ�ʶ��������ѡ���ť�Ƿ����
% a ��ʶ����
% 0 off; 1 on
if a(1) == 0
%     set(handles.microscope_pushbutton, 'ForegroundColor', [0.9,0.9,0.9]);
    set(handles.microscope_pushbutton,'Enable', 'off');
    set(handles.comove_microscope,'Enable', 'off');
else
%     set(handles.microscope_pushbutton, 'ForegroundColor', 'black');
    set(handles.microscope_pushbutton,'Enable', 'on');
    set(handles.comove_microscope,'Enable', 'on');
end
if a(2) == 0
%     set(handles.injection1_pushbutton, 'ForegroundColor', [0.9,0.9,0.9]);
    set(handles.injection1_pushbutton,'Enable', 'off');
    set(handles.comove_injection1,'Enable', 'off');
else
%     set(handles.injection1_pushbutton, 'ForegroundColor', [0.6,0.6,0.6]);
    set(handles.injection1_pushbutton,'Enable', 'on');
    set(handles.comove_injection1,'Enable', 'on');
end
if a(3) == 0
%     set(handles.injection2_pushbutton, 'ForegroundColor', [0.9,0.9,0.9]);
    set(handles.injection2_pushbutton,'Enable', 'off');
    set(handles.comove_injection2,'Enable', 'off');
else
%     set(handles.injection2_pushbutton, 'ForegroundColor', [0.6,0.6,0.6]);
    set(handles.injection2_pushbutton,'Enable', 'on');
    set(handles.comove_injection2,'Enable', 'on');
end
if a(4) == 0
%     set(handles.injection3_pushbutton, 'ForegroundColor', [0.9,0.9,0.9]);
    set(handles.injection3_pushbutton,'Enable', 'off');
    set(handles.comove_injection3,'Enable', 'off');
else
%     set(handles.injection3_pushbutton, 'ForegroundColor', [0.6,0.6,0.6]);
    set(handles.injection3_pushbutton,'Enable', 'on');
    set(handles.comove_injection3,'Enable', 'on');
end
if a(5) == 0
%     set(handles.injection4_pushbutton, 'ForegroundColor', [0.9,0.9,0.9]);
    set(handles.injection4_pushbutton,'Enable', 'off');
    set(handles.comove_injection4,'Enable', 'off');
else
%     set(handles.injection4_pushbutton, 'ForegroundColor', [0.6,0.6,0.6]);
    set(handles.injection4_pushbutton, 'Enable', 'on');
    set(handles.comove_injection4,'Enable', 'on');
end
if a(6) == 0
%     set(handles.injection5_pushbutton, 'ForegroundColor', [0.9,0.9,0.9]);
    set(handles.injection5_pushbutton,'Enable', 'off');
    set(handles.comove_injection5,'Enable', 'off');
else
%     set(handles.injection5_pushbutton, 'ForegroundColor', [0.6,0.6,0.6]);
    set(handles.injection5_pushbutton,'Enable', 'on');
    set(handles.comove_injection5,'Enable', 'on');
end
if a(7) == 0
%     set(handles.injection6_pushbutton, 'ForegroundColor', [0.9,0.9,0.9]);
    set(handles.injection6_pushbutton,'Enable', 'off');
    set(handles.comove_injection6,'Enable', 'off');
else
%     set(handles.injection6_pushbutton, 'ForegroundColor', [0.6,0.6,0.6]);
    set(handles.injection6_pushbutton,'Enable', 'on');
    set(handles.comove_injection6,'Enable', 'on');
end
if a(8) == 0
%     set(handles.injection7_pushbutton, 'ForegroundColor', [0.9,0.9,0.9]);
    set(handles.injection7_pushbutton,'Enable', 'off');
    set(handles.comove_injection7,'Enable', 'off');
else
%     set(handles.injection7_pushbutton, 'ForegroundColor', [0.6,0.6,0.6]);
    set(handles.injection7_pushbutton,'Enable', 'on');
    set(handles.comove_injection7,'Enable', 'on');
end
if a(9) == 0
%     set(handles.injection8_pushbutton, 'ForegroundColor', [0.9,0.9,0.9]);
    set(handles.injection8_pushbutton,'Enable', 'off');
    set(handles.comove_injection8,'Enable', 'off');
else
%     set(handles.injection8_pushbutton, 'ForegroundColor', [0.6,0.6,0.6]);
    set(handles.injection8_pushbutton,'Enable', 'on');
    set(handles.comove_injection8,'Enable', 'on');
end

function setButtonColorOfElements(a,handles)
% ���ձ�ʶ��������ѡ���ť������ɫ
% a ��ʶ����
% 0 ����Ϊ��ɫ [0.6,0.6,0.6]�� 1 ����Ϊ��ɫ
if a(1) == 0
    set(handles.microscope_pushbutton, 'FontWeight', 'normal');
else
    set(handles.microscope_pushbutton, 'FontWeight', 'bold');
end
if a(2) == 0
    set(handles.injection1_pushbutton, 'FontWeight', 'normal');
else
    set(handles.injection1_pushbutton, 'FontWeight', 'bold');
end
if a(3) == 0
    set(handles.injection2_pushbutton, 'FontWeight', 'normal');
else
    set(handles.injection2_pushbutton, 'FontWeight', 'bold');
end
if a(4) == 0
    set(handles.injection3_pushbutton, 'FontWeight', 'normal');
else
    set(handles.injection3_pushbutton, 'FontWeight', 'bold');
end
if a(5) == 0
    set(handles.injection4_pushbutton, 'FontWeight', 'normal');
else
    set(handles.injection4_pushbutton, 'FontWeight', 'bold');
end
if a(6) == 0
    set(handles.injection5_pushbutton, 'FontWeight', 'normal');
else
    set(handles.injection5_pushbutton, 'FontWeight', 'bold');
end
if a(7) == 0
    set(handles.injection6_pushbutton, 'FontWeight', 'normal');
else
    set(handles.injection6_pushbutton, 'FontWeight', 'bold');
end
if a(8) == 0
    set(handles.injection7_pushbutton, 'FontWeight', 'normal');
else
    set(handles.injection7_pushbutton, 'FontWeight', 'bold');
end
if a(9) == 0
    set(handles.injection8_pushbutton, 'FontWeight', 'normal');
else
    set(handles.injection8_pushbutton, 'FontWeight', 'bold');
end

function buttonElementAction(a,handles)
% ����Ԫ��ѡ��ť��Ӧ
% a ����Ԫ���ı��
%newSwitch = getappdata(handles.figure1, 'numSwitch');
global numSwitch newPosition;
if numSwitch ~= a
    %�������쳣����
    if isempty(str2num(get(handles.xPosition_edit,'string'))) || isempty(str2num(get(handles.yPosition_edit,'string'))) || isempty(str2num(get(handles.zPosition_edit,'string')))
        disp(['���������֣�',newline])
        return;
    end  
    %�����ϸ��ؼ�λ��
    newPosition(numSwitch,1) = str2num(get(handles.xPosition_edit,'string'))*100;
    newPosition(numSwitch,2) = str2num(get(handles.yPosition_edit,'string'))*100;
    newPosition(numSwitch,3) = str2num(get(handles.zPosition_edit,'string'))*100;
    %���°�ť������ɫ
    flag = zeros(1,9);
    numSwitch = a;
    flag(numSwitch) = 1;
    setButtonColorOfElements(flag,handles);
    %����λ������
    set(handles.xPosition_edit,'string',newPosition(numSwitch,1)/100);
    set(handles.yPosition_edit,'string',newPosition(numSwitch,2)/100);
    set(handles.zPosition_edit,'string',newPosition(numSwitch,3)/100);
    if (numSwitch == 1)
        set(handles.objswitch_pushbutton,'Visible',1);
    else
        set(handles.objswitch_pushbutton,'Visible',0);
    end
end

function varargout = serial_communication_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

function com_Callback(hObject, ~, handles)
 
function com_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function rate_Callback(hObject, eventdata, handles)

function rate_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function jiaoyan_Callback(hObject, eventdata, handles)

function jiaoyan_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function data_bits_Callback(hObject, eventdata, handles)

function data_bits_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function stop_bits_Callback(hObject, eventdata, handles)

function stop_bits_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function start_serial_Callback(hObject, eventdata, handles)
%   ����/�رմ��ڡ���ť�Ļص�����
%    �򿪴��ڣ�����ʼ����ز���
%% �����¡��򿪴��ڡ���ť���򿪴���
%global vv
%global dd
if get(hObject, 'value')
    %% ��ȡ���ڵĶ˿���
    com_n = sprintf('com%d', get(handles.com, 'value'));
    %% ��ȡ������
    rates = [300 600 1200 2400 4800 9600 19200 38400 43000 56000 57600 115200];
    baud_rate = rates(get(handles.rate, 'value'));
    %% ��ȡУ��λ����
    switch get(handles.jiaoyan, 'value')
        case 1
            jiaoyan = 'none';
        case 2
            jiaoyan = 'odd';
        case 3
            jiaoyan = 'even';
    end
    %% ��ȡ����λ����
    data_bits = 5 + get(handles.data_bits, 'value');
    %% ��ȡֹͣλ����
    stop_bits = get(handles.stop_bits, 'value');
    %% �������ڶ���
    scom = serial(com_n);
    %% ���ô������ԣ�ָ����ص�����
    set(scom, 'BaudRate', baud_rate, 'Parity', jiaoyan, 'DataBits',...
        data_bits, 'StopBits', stop_bits, 'BytesAvailableFcnCount', 10,...
        'BytesAvailableFcnMode', 'byte', 'BytesAvailableFcn', {@bytes, handles},...
        'TimerPeriod', 0.05, 'timerfcn', {@dataDisp, handles});
    %BytesAvailableFcnMode �����ж���Ӧģʽ���С�byte���͡�Terminator������ģʽ��ѡ����byte���Ǵﵽһ���ֽ��������жϣ���Terminator������������ĳ�������¼��������жϣ�
    %% �����ڶ���ľ����Ϊ�û����ݣ����봰�ڶ���
    set(handles.figure1, 'UserData', scom);
    %% ���Դ򿪴���
    try
        fopen(scom);  %�򿪴���
    catch   % �����ڴ�ʧ�ܣ���ʾ�����ڲ��ɻ�ã���
        msgbox('���ڲ��ɻ�ã�','Error','error');
        set(hObject, 'value', 0);  %���𱾰�ť
        return;
    end
    %% �򿪴��ں������ڷ������ݣ���ս�����ʾ������������״ָ̬ʾ�ƣ�
    %% �����ı���ť�ı�Ϊ���رմ��ڡ�
    set(handles.period_send, 'Enable', 'on');  	%���á��Զ����͡���ť
    set(handles.manual_send, 'Enable', 'on');  %���á��ֶ����͡���ť
    set(handles.EnterSend,'Enable','on');%���á��س����͡���ť (1125)
    set(handles.xianshi, 'string', ''); 			%��ս�����ʾ��
    set(handles.lamb, 'BackgroundColor', getappdata(handles.figure1,'openData')); %��������״ָ̬ʾ��
    set(hObject, 'String', '�رմ���');  		%���ñ���ť�ı�Ϊ���رմ��ڡ�
   
else  %���رմ���
    %% ֹͣ��ɾ����ʱ��
    t = timerfind;
    if ~isempty(t)
        stop(t);
        delete(t);
    end
    %% ֹͣ��ɾ�����ڶ���
    scoms = instrfind; %��������Ч�Ĵ��ж˿ڶ����� out ������ʽ����
    stopasync(scoms); %ֹͣ�첽��д����
    fclose(scoms);
    delete(scoms);
    %% ���á��Զ����͡��͡��ֶ����͡���ť��Ϩ�𴮿�״ָ̬ʾ��
    set(handles.period_send, 'Enable', 'off', 'Value', 0); %���á��Զ����͡���ť
    set(handles.EnterSend, 'Enable', 'off', 'Value', 0); %���á��س����͡���ť (1125)
    set(handles.manual_send, 'Enable', 'off');  %���á��ֶ����͡���ť
    set(handles.lamb, 'BackgroundColor', getappdata(handles.figure1,'closedData')); %Ϩ�𴮿�״ָ̬ʾ��
    set(hObject, 'String', '�򿪴���');  		%���ñ���ť�ı�Ϊ���򿪴��ڡ�
end

function dataDisp(obj, event, handles)
%	���ڵ�TimerFcn�ص�����
%   ����������ʾ
%% ��ȡ����
hasData = getappdata(handles.figure1, 'hasData'); %�����Ƿ��յ�����
strRec = getappdata(handles.figure1, 'strRec');   %�������ݵ��ַ�����ʽ����ʱ��ʾ������
numRec = getappdata(handles.figure1, 'numRec');   %���ڽ��յ������ݸ���
%% ������û�н��յ����ݣ��ȳ��Խ��մ�������
if ~hasData
    bytes(obj, event, handles);
end
%% �����������ݣ���ʾ��������
if hasData
    %% ��������ʾģ��ӻ�����
    %% ��ִ����ʾ����ģ��ʱ�������ܴ������ݣ�����ִ��BytesAvailableFcn�ص�����
    setappdata(handles.figure1, 'isShow', true); 
    %% ��Ҫ��ʾ���ַ������ȳ���10000�������ʾ��
    if length(strRec) > 10000
        strRec = '';
        setappdata(handles.figure1, 'strRec', strRec);
    end
    %% ��ʾ����
    set(handles.xianshi, 'string', strRec);
    %% ���½��ռ���
    set(handles.rec,'string', numRec);
    %% ����hasData��־���������������Ѿ���ʾ
    setappdata(handles.figure1, 'hasData', false);
    %% ��������ʾģ�����
    setappdata(handles.figure1, 'isShow', false);
end
 
function bytes(obj, ~, handles)
%   ���ڵ�BytesAvailableFcn�ص�����
%   ���ڽ�������
%% ��ȡ����
strRec = getappdata(handles.figure1, 'strRec'); %��ȡ����Ҫ��ʾ������
numRec = getappdata(handles.figure1, 'numRec'); %��ȡ�����ѽ������ݵĸ���
isStopDisp = getappdata(handles.figure1, 'isStopDisp'); %�Ƿ����ˡ�ֹͣ��ʾ����ť
isHexDisp = getappdata(handles.figure1, 'isHexDisp'); %�Ƿ�ʮ��������ʾ
isShow = getappdata(handles.figure1, 'isShow');  %�Ƿ�����ִ����ʾ���ݲ���
%% ������ִ��������ʾ�������ݲ����մ�������
if isShow
    return;
end
%% ��ȡ���ڿɻ�ȡ�����ݸ���
n = get(obj, 'BytesAvailable');
%% �����������ݣ�������������
if n
    %% ����hasData����������������������Ҫ��ʾ
    setappdata(handles.figure1, 'hasData', true);
    %% ��ȡ��������
    a = fread(obj, n, 'uchar');
    %% ��û��ֹͣ��ʾ�������յ������ݽ��������׼����ʾ
    if ~isStopDisp 
        %% ���ݽ�����ʾ��״̬����������ΪҪ��ʾ���ַ���
        if ~isHexDisp 
            c = char(a');
        else
            strHex = dec2hex(a')';
            strHex2 = [strHex; blanks(size(a, 1))]; %???ΪɶҪ��һ���յ�ͬ����С���ַ���
            c = strHex2(:)';
        end
        %% �����ѽ��յ����ݸ���
        numRec = numRec + size(a, 1);
        %% ����Ҫ��ʾ���ַ���
        strRec = [strRec c];
    end
    %% ���²���
    setappdata(handles.figure1, 'numRec', numRec); %�����ѽ��յ����ݸ���
    setappdata(handles.figure1, 'strRec', strRec); %����Ҫ��ʾ���ַ���
end


function qingkong_Callback(hObject, eventdata, handles)
%% ���Ҫ��ʾ���ַ���
setappdata(handles.figure1, 'strRec', '');
%% �����ʾ
set(handles.xianshi, 'String', '');

function stop_disp_Callback(hObject, eventdata, handles)
%% ���ݡ�ֹͣ��ʾ����ť��״̬������isStopDisp����
if get(hObject, 'value')
    isStopDisp = true;
else
    isStopDisp = false;
end
setappdata(handles.figure1, 'isStopDisp', isStopDisp);

function radiobutton1_Callback(hObject, eventdata, handles)

function radiobutton2_Callback(hObject, eventdata, handles)

function togglebutton4_Callback(hObject, eventdata, handles)

function hex_disp_Callback(hObject, eventdata, handles)
%% ���ݡ�ʮ��������ʾ����ѡ���״̬������isHexDisp����
if get(hObject, 'value')
    isHexDisp = true;
else
    isHexDisp = false;
end
setappdata(handles.figure1, 'isHexDisp', isHexDisp);

function manual_send_Callback(hObject, eventdata, handles)
vv =10;
dd =13;
scom = get(handles.figure1, 'UserData');
numSend = getappdata(handles.figure1, 'numSend');
val = get(handles.sends, 'UserData');
numSend = numSend + length(val);
set(handles.trans, 'string', num2str(numSend));
setappdata(handles.figure1, 'numSend', numSend);
EnterSend_flag = get(handles.EnterSend,'Value');
I_flag=0;
if ~isempty(val)
    %% ���õ������ĳ�ֵ
    n = 1000;
    while n
        %% ��ȡ���ڵĴ���״̬��������û������д���ݣ�д������
        str = get(scom, 'TransferStatus');
        if ~(strcmp(str, 'write') || strcmp(str, 'read&write')) 
            if ~I_flag
             fwrite(scom, val, 'uint8', 'async'); %����д�봮��
                I_flag=1;
            end
        end
        if EnterSend_flag
            str = get(scom, 'TransferStatus');
            if ~(strcmp(str, 'write') || strcmp(str, 'read&write'))
                 fwrite(scom, vv); %����д�봮��
                 fwrite(scom, dd); %����д�봮��
                 break;
            end
        end 
        n = n - 1; %������
    end
end



function clear_send_Callback(hObject, eventdata, handles)
%% ��շ�����
set(handles.sends, 'string', '')
%% ����Ҫ���͵�����
set(handles.sends, 'UserData', []);

function checkbox2_Callback(hObject, eventdata, handles)


function period_send_Callback(hObject, eventdata, handles)
%   ���Զ����͡���ť��Callback�ص�����
%% �����¡��Զ����͡���ť��������ʱ��������ֹͣ��ɾ����ʱ��
if get(hObject, 'value')
    t1 = 0.001 * str2double(get(handles.period1, 'string'));%��ȡ��ʱ������
    t = timer('ExecutionMode','fixedrate', 'Period', t1, 'TimerFcn',...
        {@manual_send_Callback, handles}); %������ʱ��
    set(handles.period1, 'Enable', 'off'); %�������ö�ʱ�����ڵ�Edit Text����
    set(handles.sends, 'Enable', 'inactive'); %�������ݷ��ͱ༭��
    start(t);  %������ʱ��
else
    set(handles.period1, 'Enable', 'on'); %�������ö�ʱ�����ڵ�Edit Text����
    set(handles.sends, 'Enable', 'on');   %�������ݷ��ͱ༭��
    t = timerfind; %���Ҷ�ʱ��
    stop(t); %ֹͣ��ʱ��
    delete(t); %ɾ����ʱ��
end

function period1_Callback(hObject, eventdata, handles)

function period1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function clear_count_Callback(hObject, eventdata, handles)
%% �������㣬�����²���numRec��numSend
set([handles.rec, handles.trans], 'string', '0')
setappdata(handles.figure1, 'numRec', 0);
setappdata(handles.figure1, 'numSend', 0);

function copy_data_Callback(hObject, eventdata, handles)
%% �����Ƿ������ƽ���������ʾ���ڵ�����
if get(hObject,'value')
    set(handles.xianshi, 'enable', 'on');
else
    set(handles.xianshi, 'enable', 'inactive');
end

function figure1_CloseRequestFcn(hObject, eventdata, handles)

global CameraOpenFlag;
%   �رմ���ʱ����鶨ʱ���ʹ����Ƿ��ѹر�
%   ��û�йرգ����ȹر�
%% ���Ҷ�ʱ��
t = timerfind;
%% �����ڶ�ʱ������ֹͣ���ر�
if ~isempty(t)
    stop(t);  %����ʱ��û��ֹͣ����ֹͣ��ʱ��
    delete(t);
end
%% check camera
CameraOpenFlag = false;
%% ���Ҵ��ڶ���
scoms = instrfind;
%% ����ֹͣ���ر�ɾ�����ڶ���
try
    stopasync(scoms);
    fclose(scoms);
    delete(scoms);
catch
end
%% �رմ���
delete(hObject);

function hex_send_Callback(hObject, eventdata, handles)
%% ���ݡ�ʮ�����Ʒ��͡���ѡ���״̬������isHexSend����
if get(hObject,'value')
    isHexSend = true;
else
    isHexSend = false;
end
setappdata(handles.figure1, 'isHexSend', isHexSend);
%% ����Ҫ���͵�����
sends_Callback(handles.sends, eventdata, handles);


function sends_Callback(hObject, eventdata, handles)
%   ���ݷ��ͱ༭����Callback�ص�����
%   ����Ҫ���͵�����
%% ��ȡ���ݷ��ͱ༭�����ַ���
str = get(hObject, 'string');
%% ��ȡ����isHexSend��ֵ
isHexSend = getappdata(handles.figure1, 'isHexSend');
if ~isHexSend %��ΪASCIIֵ��ʽ���ͣ�ֱ�ӽ��ַ���ת��Ϊ��Ӧ����ֵ
    val = double(str);
else  %��Ϊʮ�����Ʒ��ͣ���ȡҪ���͵�����
    n = find(str == ' ');   %���ҿո�
    n =[0 n length(str)+1]; %�ո������ֵ
    %% ÿ�������ڿո�֮����ַ���Ϊ��ֵ��ʮ��������ʽ������ת��Ϊ��ֵ
    for i = 1 : length(n)-1 
        temp = str(n(i)+1 : n(i+1)-1);  %���ÿ�����ݵĳ��ȣ�Ϊ����ת��Ϊʮ������׼��
        if ~rem(length(temp), 2)
            b{i} = reshape(temp, 2, [])'; %��ÿ��ʮ�������ַ���ת��Ϊ��Ԫ����
        else
            break;
        end
    end
    val = hex2dec(b)';     %��ʮ�������ַ���ת��Ϊʮ���������ȴ�д�봮��
end
%% ����Ҫ��ʾ������
set(hObject, 'UserData', val); 


function lamb_Callback(hObject, eventdata, handles)


% --- Executes on button press in EnterSend.
function EnterSend_Callback(hObject, eventdata, handles)
% hObject    handle to EnterSend (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of EnterSend



% --- Executes on button press in CameraButton.
function CameraButton_Callback(hObject, eventdata, handles)
% hObject    handle to CameraButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global obj;
global CameraOpenFlag;
global isCameraStopFlag;
<<<<<<< HEAD
% global tb;{
global h;
global loc usbVidRes1 nBands1;
%
CameraOpenFlag = getappdata(handles.figure1, 'isCameraOpened'); % get flag
if ~CameraOpenFlag 
    set(handles.CameraButton, 'string',"Camera Off",'ForegroundColor',[1 0 0]);
    objects = imaqfind;
    delete(objects);
%     obj = videoinput('winvideo',1,'YUY2_640x480');
    obj = videoinput('pmimaq_2019b', 1, 'PM-Cam 1376x1024'); % start get images
%     set(obj,'FramesPerTrigger',1);
%     set(obj,'TriggerRepeat',Inf);
%     set(obj,'FrameGrabInterval',1);
    usbVidRes1 = get(obj,'videoResolution');
    nBands1 = get(obj,'NumberOfBands');
    start(obj);
    CameraOpenFlag = true;
    axes(handles.Image_display);
    axis off;
    
    himage=image(zeros(usbVidRes1(2),usbVidRes1(1),nBands1),'parent', handles.Image_display);
    h = preview(obj,himage);
    hold on;  %draw central point
    plot(usbVidRes1(1)/2,usbVidRes1(2)/2,'ro',usbVidRes1(1)/2,usbVidRes1(2)/2,'r.'); 
    hold off
=======
global tb;
global h;
CameraOpenFlag = getappdata(handles.figure1, 'isCameraOpened');
if ~CameraOpenFlag 
    set(handles.CameraButton, 'string',"�ر�����ͷ",'ForegroundColor',[1 0 0]);
    objects = imaqfind;
    delete(objects);
%     obj = videoinput('winvideo',1,'YUY2_640x480');
    obj = videoinput('pmimaq_2019b', 1, 'PM-Cam 1376x1024'); %��ʼ��ͼ��
    usbVidRes1 = get(obj,'videoResolution');
    nBands1 = get(obj,'NumberOfBands');
    start(obj);
    axes(handles.Image_display);
    axis off;
    himage=image(zeros(usbVidRes1(2),usbVidRes1(1),nBands1),'parent', handles.Image_display);
    h = preview(obj,himage);
    hold on;  %�����ĵ�
    plot(usbVidRes1(1)/2,usbVidRes1(2)/2,'ro',usbVidRes1(1)/2,usbVidRes1(2)/2,'r.'); 
    
>>>>>>> c1dad3ae10e94eb80012507d1a59a09632233939
    %% =================1229=================
    isCameraOpened = true;
    setappdata(handles.figure1,'isCameraOpened',isCameraOpened); 
    isCameraStopFlag = false;
<<<<<<< HEAD
%     plot([usbVidRes1(1)-80,usbVidRes1(1)-20],[usbVidRes1(2)-25,usbVidRes1(2)-25],'b','linewidth',2); 
%     text(usbVidRes1(1)-70, usbVidRes1(2)-35,'10 {\mu}m','Color','white','FontSize',7)
=======
    plot([usbVidRes1(1)-80,usbVidRes1(1)-20],[usbVidRes1(2)-25,usbVidRes1(2)-25],'b','linewidth',2); 
    text(usbVidRes1(1)-70, usbVidRes1(2)-35,'10 {\mu}m','Color','white','FontSize',7)
>>>>>>> c1dad3ae10e94eb80012507d1a59a09632233939
    flushdata(obj)
    tb = text;
    set(gcf,'WindowButtonMotionFcn',@callback);
    set(himage, 'ButtonDownFcn', {@ButtonDowncallback,handles});   
else
    set(hObject, 'String', "Camera On",'ForegroundColor',[0 0 1]);                  % setting button text
    closepreview(obj);
    delete(obj);   
    isCameraOpened = false;
    CameraOpenFlag = false;
    setappdata(handles.figure1,'isCameraOpened',isCameraOpened); 
    obj = false;
    tb = text;
    set(gcf,'WindowButtonMotionFcn',@callback);
    set(gcf,'WindowButtonDownFcn', {@ButtonDowncallback,handles});
%     delete(gcf);
end
%}

%{
%liujian 20210415

if ~CameraOpenFlag
    objects = imaqfind;
    delete(objects);
%     obj = videoinput('winvideo',1,'YUY2_640x480');
    obj = videoinput('pmimaq_2019b', 1, 'PM-Cam 1376x1024'); % start get images
    triggerconfig(obj,'manual');
    usbVidRes1 = get(obj,'videoResolution');
    nBands1 = get(obj,'NumberOfBands');
    start(obj);
    CameraOpenFlag = true;
    isCameraStopFlag = false;
    set(handles.CameraButton,'Enable','off');
    axes(handles.Image_display);
    c=0;
    
%      tic 
    while(CameraOpenFlag)
        c=c+1;
        
        frame = getsnapshot(obj);
%         frame = ycbcr2rgb(frame);
        flushdata(obj);
%         cla(handles.Image_display)
%         hold on
%         ishghandle(h)
        h = imshow(frame);
%         h = image(frame,'parent',handles.Image_display);
        axis off;
        set(h,'HitTest','off');
        hold on;  %draw central point
        plot(usbVidRes1(1)/2,usbVidRes1(2)/2,'ro',usbVidRes1(1)/2,usbVidRes1(2)/2,'r.'); 
        
        plot([usbVidRes1(1)-80,usbVidRes1(1)-20],[usbVidRes1(2)-25,usbVidRes1(2)-25],'b','linewidth',2); 
        text(usbVidRes1(1)-70, usbVidRes1(2)-35,'10 {\mu}m','Color','white','FontSize',7)
%         set(handles.Image_display,'ButtonDownFcn', {@ButtonDowncallback,handles});
%         tb = text;
        if loc(1,1) ~= 0 && loc(1,2) ~= 0
            plot(loc(1,1),loc(1,2),'r.');
        end
        
%         set(gcf,'WindowButtonMotionFcn',@callback);
%         set(gcf,'WindowButtonDownFcn', {@ButtonDowncallback,handles});
        pause(0.05)
        if mod(c,30)==0
            hold off
        end
    end
    
%     elapsedTime = toc;
%     timePerFrame = elapsedTime/1000;
%     effectiveFrameRate = 1/timePerFrame;
    
    isCameraStopFlag = false;
    
    stop(obj);
    delete(obj);
end
%}




% --- Executes during object creation, after setting all properties.
function Image_display_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Image_display (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate Image_display
<<<<<<< HEAD
=======
global tb;
% global loc;
tb = text;
set(gcf,'WindowButtonMotionFcn',@callback);
set(gcf, 'WindowButtonDownFcn', @ButtonDowncallback);
>>>>>>> c1dad3ae10e94eb80012507d1a59a09632233939



function callback(handles,hObject, ~)
%     global tb
%     loc = get(gca, 'CurrentPoint');
%     loc = loc([1 3]);
%     set(tb, 'string', num2str(loc), 'position', loc);

function ButtonDowncallback(hObject, eventdata, handles)
%      global tb;
     global loc;
     global isButtonDown;
%      global h usbVidRes1;
     isButtonDown = true;
<<<<<<< HEAD
%      ishandle(h)
%      if ~ishandle(h)
%      else
    loc = get(gca, 'currentpoint');
%      end
    loc = loc(1,(1:2))
    hold off;
%     hold on
% %     plot([usbVidRes1(1)-80,usbVidRes1(1)-20],[usbVidRes1(2)-25,usbVidRes1(2)-25],'b','linewidth',2); 
% %     text(usbVidRes1(1)-70, usbVidRes1(2)-35,'10 {\mu}m','Color','white','FontSize',7)
%     plot(loc(1,1),loc(1,2),'r.');
%     hold off
% %      set(tb, 'string', num2str(loc), 'position', loc); 
% %      set(handles.PositionBox,'String',loc);
=======
     loc = get(gca, 'CurrentPoint');
     loc = loc(1,(1:2));
     set(tb, 'string', num2str(loc), 'position', loc); 
%      set(handles.PositionBox,'String',loc);
>>>>>>> c1dad3ae10e94eb80012507d1a59a09632233939



% --- Executes on button press in Snapshot_save.
function Snapshot_save_Callback(hObject, eventdata, handles)
% hObject    handle to Snapshot_save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global obj;
%open the saving window
[fname,pname]=uiputfile({'*.jpg';'*.tiff';'*.png';'*.*'});
CameraOpenFlag = getappdata(handles.figure1, 'isCameraOpened');
if CameraOpenFlag
    frame = getsnapshot(obj);
    %check the availability of fname and pname
    if isequal(fname,0) || isequal(pname,0)
        return;
    end
%     imwrite(ycbcr2rgb(frame),strcat(pname,fname));
    imwrite(frame,strcat(pname,fname));
    helpdlg(strcat('Saved successfully to:',strcat(pname,fname)),'Tips');
end
    


% --- Executes on button press in StopCamera.
function StopCamera_Callback(hObject, eventdata, handles)
% hObject    handle to StopCamera (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global obj;
global isCameraStopFlag;

CameraOpenFlag = getappdata(handles.figure1, 'isCameraOpened');
if CameraOpenFlag
    if ~isCameraStopFlag
       set(handles.StopCamera,"string","Continue",'ForegroundColor',[0 0 1]);
       stoppreview(obj);
       isCameraStopFlag = true;
    else
       set(handles.StopCamera,"string","Pause",'ForegroundColor',[1 0 0]);
       preview(obj);
       isCameraStopFlag = false;
    end
end



function xPosition_edit_Callback(hObject, eventdata, handles)
% hObject    handle to xPosition_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of xPosition_edit as text
%        str2double(get(hObject,'String')) returns contents of xPosition_edit as a double


% --- Executes during object creation, after setting all properties.
function xPosition_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to xPosition_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in radiobutton6.
function radiobutton6_Callback(hObject, ~, handles)
% hObject    handle to radiobutton6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton6


% --- Executes on button press in xMinus_pushbutton.
function xMinus_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to xMinus_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global numSwitch newPosition;
if get(hObject,'value')
    if get(handles.fine_checkbox,'value')
        step = 100;
    elseif get(handles.rough_checkbox,'value')
        step = 10000;
    else
        step = 1000;
    end
    newPosition(numSwitch,1) = newPosition(numSwitch,1) - step;
    set(handles.xPosition_edit,'string',newPosition(numSwitch,1)/100);
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over xMinus_pushbutton.
function xMinus_pushbutton_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to xMinus_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in xPlus_pushbutton.
function xPlus_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to xPlus_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global numSwitch newPosition;
if get(hObject,'value')
    if get(handles.fine_checkbox,'value')
        step = 100;
    elseif get(handles.rough_checkbox,'value')
        step = 10000;
    else
        step = 1000;
    end
    newPosition(numSwitch,1) = newPosition(numSwitch,1) + step;
    set(handles.xPosition_edit,'string',newPosition(numSwitch,1)/100);
end
%{
if isempty(str2num(get(handles.xPosition_edit,'string')))
    set(hObject, Enable, 'off');
else
    set(hObject, Enable, 'on');
end
%}


% --- Executes on button press in fine_checkbox.
function fine_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to fine_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of fine_checkbox
 set(handles.rough_checkbox,'Value',0);

% --- Executes on button press in goTo_pushbutton.
function goTo_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to goTo_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global numSwitch prePosition angleOffset;
if get(hObject, 'value')
    %get target position
    pDisplay = zeros(1,3);
    pDisplay(1) = str2num(get(handles.xPosition_edit,'String'))*100;
    pDisplay(2) = str2num(get(handles.yPosition_edit,'String'))*100;
    pDisplay(3) = str2num(get(handles.zPosition_edit,'String'))*100;
%     numSwitch
    prePosition(numSwitch,:)
%     pDisplay
    %�жϵ�ǰλ���Ƿ�Ϊ��ʾ����λ��
    if pDisplay(1) ~= prePosition(numSwitch,1) || pDisplay(2) ~= prePosition(numSwitch,2) || pDisplay(3) ~= prePosition(numSwitch,3)
        %ĿǰЭͬĬ��Ϊ��΢���뵥��΢�ٵ�Эͬ������ЭͬʱnumSwitch = 1
        %  && get(handles.comove_injection3,'value')
        if numSwitch == 1
            doComove(pDisplay,handles);
            % comove element reaction
%             comoveInjectionWithInjection(1,4,pDisplay,0,handles);
%{            
%             %��΢���ж��Ƿ���ƶ�
%             tempP = zeros(1,3);
%             tempP(1) = xCheckLimit(1,pDisplay(1),handles);
%             tempP(2) = yCheckLimit(1,pDisplay(2),handles);
%             tempP(3) = zCheckLimit(1,pDisplay(3),handles);
%             if pDisplay(1) ~= tempP(1) || pDisplay(2) ~= tempP(2) || pDisplay(3) ~= tempP(3)
%                 str = ['��΢���޷��ƶ�����λ��',newline];
%                 disp(str);
%                 return;
%             end
%             
%             %Эͬ�ƶ��ؼ�������ʱΪ3��΢��
%             %������΢���ƶ�������΢������
%             detaP = pDisplay - prePosition(1,:);     %��΢��λ�Ʊ仯
%             angleOffset(4)
%             
%             
%             theta = angleOffset(4)/180*pi;
%             dP = zeros(1,3);     %�ȴ�仯��
%             dP(1) = detaP(1)*cos(theta) + detaP(2)*sin(theta);
%             dP(2) = -detaP(1)*sin(theta) + detaP(2)*cos(theta);
%             dP(3) = detaP(3);
%             %΢���ж��Ƿ���ƶ�
%             tempP(1) = prePosition(4,1)+dP(1) - xCheckLimit(4,prePosition(4,1)+dP(1),handles);
%             tempP(2) = prePosition(4,2)+dP(2) - yCheckLimit(4,prePosition(4,2)+dP(2),handles);
%             tempP(3) = prePosition(4,3)+dP(3) - zCheckLimit(4,prePosition(4,3)+dP(3),handles);
%             if tempP(1) ~= 0 || tempP(2) ~= 0 || tempP(3) ~= 0
%                 str = ['΢���޷��ƶ�����λ��',newline];
%                 disp(str);
%                 return;
%             end
%             %����Эͬ�ƶ�
%             commandMoveReaction(4, 'RELD', dP(1), dP(2), dP(3), handles);     %΢������ƶ�
%             
%             commandMoveReaction(1, 'RELD', detaP(1), detaP(2), detaP(3), handles);     %��΢������ƶ�
%             disp(['Эͬ�ƶ��ɹ�',newline]);
%}            
        end
        % Master element move
        goTo(numSwitch,pDisplay,handles);
    else
        disp(['�Ѿ��ڸ�λ��',newline]);
    end
    
end

function yPosition_edit_Callback(hObject, eventdata, handles)
% hObject    handle to yPosition_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of yPosition_edit as text
%        str2double(get(hObject,'String')) returns contents of yPosition_edit as a double


% --- Executes during object creation, after setting all properties.
function yPosition_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to yPosition_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in yMinus_pushbutton.
function yMinus_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to yMinus_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global numSwitch newPosition;
if get(hObject,'value')
    if get(handles.fine_checkbox,'value')
        step = 100;
    elseif get(handles.rough_checkbox,'value')
        step = 10000;
    else
        step = 1000;
    end
    newPosition(numSwitch,2) = newPosition(numSwitch,2) - step;
    set(handles.yPosition_edit,'string',newPosition(numSwitch,2)/100);
end


% --- Executes on button press in yPlus_pushbutton.
function yPlus_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to yPlus_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global numSwitch newPosition;
if get(hObject,'value')
    if get(handles.fine_checkbox,'value')
        step = 100;
    elseif get(handles.rough_checkbox,'value')
        step = 10000;
    else
        step = 1000;
    end
    newPosition(numSwitch,2) = newPosition(numSwitch,2) + step;
    set(handles.yPosition_edit,'string',newPosition(numSwitch,2)/100);
end


function zPosition_edit_Callback(hObject, eventdata, handles)
% hObject    handle to zPosition_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of zPosition_edit as text
%        str2double(get(hObject,'String')) returns contents of zPosition_edit as a double


% --- Executes during object creation, after setting all properties.
function zPosition_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to zPosition_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in zMinus_pushbutton.
function zMinus_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to zMinus_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global numSwitch newPosition;
if get(hObject,'value')
    if get(handles.fine_checkbox,'value')
        step = 100;
    elseif get(handles.rough_checkbox,'value')
        step = 10000;
    else
        step = 1000;
    end
    newPosition(numSwitch,3) = newPosition(numSwitch,3) - step;
    set(handles.zPosition_edit,'string',newPosition(numSwitch,3)/100);
end


% --- Executes on button press in zPlus_pushbutton.
function zPlus_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to zPlus_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global numSwitch newPosition;
if get(hObject,'value')
    if get(handles.fine_checkbox,'value')
        step = 100;
    elseif get(handles.rough_checkbox,'value')
        step = 10000;
    else
        step = 1000;
    end
    newPosition(numSwitch,3) = newPosition(numSwitch,3) + step;
    set(handles.zPosition_edit,'string',newPosition(numSwitch,3)/100);
end


% --- Executes on button press in microscope_pushbutton.
function microscope_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to microscope_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject, 'value')
    buttonElementAction(1,handles);
end



% --- Executes on button press in injection3_pushbutton.
function injection3_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to injection3_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject, 'value')
    buttonElementAction(4,handles);
end


% --- Executes on button press in injection2_pushbutton.
function injection2_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to injection2_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject, 'value')
    buttonElementAction(3,handles);
end


% --- Executes on button press in injection1_pushbutton.
function injection1_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to injection1_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject, 'value')
    buttonElementAction(2,handles);
end


% --- Executes on button press in injection5_pushbutton.
function injection5_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to injection5_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject, 'value')
    buttonElementAction(6,handles);
end


% --- Executes on button press in injection4_pushbutton.
function injection4_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to injection4_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject, 'value')
    buttonElementAction(5,handles);
end


% --- Executes on button press in injection6_pushbutton.
function injection6_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to injection6_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject, 'value')
    buttonElementAction(7,handles);
end


% --- Executes on button press in injection7_pushbutton.
function injection7_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to injection7_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject, 'value')
    buttonElementAction(8,handles);
end


% --- Executes on button press in injection8_pushbutton.
function injection8_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to injection8_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject, 'value')
    buttonElementAction(9,handles);
end


% --- Executes during object creation, after setting all properties.
function uipanel7_CreateFcn(hObject, eventdata, handles)
% hObject    handle to uipanel7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function microscope_pushbutton_CreateFcn(hObject, eventdata, handles)
% hObject    handle to microscope_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function injection1_pushbutton_CreateFcn(hObject, eventdata, handles)
% hObject    handle to injection1_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function injection2_pushbutton_CreateFcn(hObject, eventdata, handles)
% hObject    handle to injection2_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function injection3_pushbutton_CreateFcn(hObject, eventdata, handles)
% hObject    handle to injection3_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function injection4_pushbutton_CreateFcn(hObject, eventdata, handles)
% hObject    handle to injection4_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function injection5_pushbutton_CreateFcn(hObject, eventdata, handles)
% hObject    handle to injection5_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function injection6_pushbutton_CreateFcn(hObject, eventdata, handles)
% hObject    handle to injection6_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function injection7_pushbutton_CreateFcn(hObject, eventdata, handles)
% hObject    handle to injection7_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function injection8_pushbutton_CreateFcn(hObject, eventdata, handles)
% hObject    handle to injection8_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over xPlus_pushbutton.
function xPlus_pushbutton_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to xPlus_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)




function xianshi_Callback(hObject, eventdata, handles)
% hObject    handle to xianshi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of xianshi as text
%        str2double(get(hObject,'String')) returns contents of xianshi as a double


% --- Executes during object creation, after setting all properties.
function xianshi_CreateFcn(hObject, eventdata, handles)
% hObject    handle to xianshi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton24.
function pushbutton24_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton24 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'value')
    commandSTOPReaction(handles);
end


% --- Executes on button press in zero_pushbutton.
function zero_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to zero_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'value')
    commandZEROReaction(handles);
end


% --- Executes during object creation, after setting all properties.
function PositionBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PositionBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on mouse press over axes background.
function Image_display_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to Image_display (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% global loc;
% loc = get(hObject,'Currentpoint');
% plot(loc(1,1),loc(1,2),'r.');


% --- Executes on button press in pushbutton27.
function pushbutton27_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton27 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in clickto_pushbutton.
function clickto_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to clickto_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global numSwitch loc prePosition newPosition;
if (loc(1) == 0 && loc(2) == 0)
    disp(['Please get the target position first.',newline]);
    return;
end
% ��
x = prePosition(numSwitch,1) + round((loc(1,2)-512)*50/3)
newX = xCheckLimit(numSwitch,x,handles)
y = prePosition(numSwitch,2) - round((loc(1,1)-688)*50/3)
newY = yCheckLimit(numSwitch,y,handles)
if newX ~= x || newY ~= y
    disp(['Destination is out of the available limits.',newline]);
    return;
end
% microscope move
commandMoveReaction(1, 'RELD', round((loc(1,2)-512)*50/3), -round((loc(1,1)-688)*50/3), 0, handles);

%{
%gui refresh
flag = (numSwitch == 1);
ifmoving = 1;
while(ifmoving == 1)
    pause(0.05);
    ifmoving = checkIsMoving(1,handles);	% ��⵱ǰ�ؼ��Ƿ��ƶ�
    %{
    %update prePosition
    newPosition(1,:) = prePosition(1,:);
    %}
    %update current position
    pXYZ = getCurrentPosition(1, handles);     %get position
    setNewPosition(1, pXYZ);     %update position parameter
    if (flag)
        refreshGuiPosition(handles)		% refresh gui
    end
end
%}
loc = zeros(1,2);

%do comove
if get(handles.comove_injection3,'value')
    
end


% --- Executes during object deletion, before destroying properties.
function PositionBox_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to PositionBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over PositionBox.
function PositionBox_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to PositionBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in comove_injection3.
function comove_injection3_Callback(hObject, eventdata, handles)
% hObject    handle to comove_injection3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of comove_injection3

global coMoveFlag;
if get(hObject,'Value')
    coMoveFlag(4) = 1;
else
    coMoveFlag(4) = 0;
end

% --- Executes on button press in objswitch_pushbutton.
function objswitch_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to objswitch_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
get(hObject,'value')
str = get(hObject,'String');
if (strcmp(str,'��4'))
    obj = 1;
else
    obj = 2;
end
setObjective(obj,handles);


% --- Executes on button press in set1.
function set1_Callback(hObject, eventdata, handles)
% hObject    handle to set1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global numSwitch loc prePosition elementAvailable configValue;
if get(hObject,'value')
    

    % pDisplay1 = zeros
    switch(configValue)
        case 1
            
            % get current position
            if (elementAvailable(1) == 1)
                pXYZ = getCurrentPosition(1, handles);
                setNewPosition(1,pXYZ);
            else
                disp(['Comport is unavailable.',newline]);
            end
%             tempP = transformImagePositionToMicroscopePosition();
%             text = [num2str(tempP(1)),' ',num2str(tempP(2)),' ',num2str(prePosition(1,3))];
            text = [num2str(prePosition(1,1)),' ',num2str(prePosition(1,2)),' ',num2str(prePosition(1,3))];
            set(handles.text23,'string',text);
            set(handles.text23,'value',1);
            if get(handles.text25,'value') == 1
                set(handles.ok_pushbutton,'Enable','on');
            end
            loc(1) = 0;
            loc(2) = 0;
            
            %{
            if numSwitch ~= 1
            % theta compute mod
            % injection move (-50,0,0)um
            pDisplay = prePosition(numSwitch,:) + [-5000,0,0]
            goTo(numSwitch,pDisplay,handles);

            % theta and alpha compute mod
%             xzComoveOfInjection(4,handles);
            % manual adjustment
            end
            %}
        case 2
            % get current Z
            if (elementAvailable(1) == 1)
                pXYZ = getCurrentPosition(1, handles);
                setNewPosition(1,pXYZ);
            else
                disp(['Comport is unavailable.',newline]);
            end
%             tempP = transformImagePositionToMicroscopePosition();
%             text = [num2str(tempP(1)),' ',num2str(tempP(2)),' ',num2str(prePosition(1,3))];
            text = [num2str(prePosition(1,1)),' ',num2str(prePosition(1,2)),' ',num2str(prePosition(1,3))];
            set(handles.text23,'string',text);
            set(handles.text23,'value',1);
            if get(handles.text25,'value') == 1
                set(handles.ok_pushbutton,'Enable','on');
            end
            loc(1) = 0;
            loc(2) = 0;
            
        case 3
            
            % close the cilck get point function
            
            % x comove 50um
%             pDisplay1 = prePosition(1,:) - [10000,0,0]
            comoveInjectionWithInjection(1,numSwitch,[-10000,0,0],0,handles);
            goTo(1,pDisplay1,handles);
            prePosition(numSwitch,1)
            
            % get current slave element position
            if (elementAvailable(numSwitch) == 1)
                pXYZ = getCurrentPosition(numSwitch, handles);
                setNewPosition(numSwitch,pXYZ);
            else
                disp(['Comport is unavailable.',newline]);
            end
            prePosition(numSwitch,1)
            
            % set slave element position
            text = [num2str(prePosition(numSwitch,1)),' ',num2str(prePosition(numSwitch,2)),' ',num2str(prePosition(numSwitch,3))];
            set(handles.text23,'string',text);
            set(handles.text23,'value',1);
            if get(handles.text25,'value') == 1
                set(handles.ok_pushbutton,'Enable','on');
            end
            
        case 4
            % y comove 50um
%             pDisplay1 = prePosition(1,:) + [0,-10000,0]
%             pDisplay(2) = pDisplay(2)
            comoveInjectionWithInjection(1,numSwitch,[0,-10000,0],0,handles);
            goTo(1,pDisplay1,handles);
            
            prePosition(numSwitch,1)
            
            % get current slave element position
            if (elementAvailable(numSwitch) == 1)
                pXYZ = getCurrentPosition(numSwitch, handles);
                setNewPosition(numSwitch,pXYZ);
            else
                disp(['Comport is unavailable.',newline]);
            end
            prePosition(numSwitch,1)
            
            % set slave element position
            text = [num2str(prePosition(numSwitch,1)),' ',num2str(prePosition(numSwitch,2)),' ',num2str(prePosition(numSwitch,3))];
            set(handles.text23,'string',text);
            set(handles.text23,'value',1);
            if get(handles.text25,'value') == 1
                set(handles.ok_pushbutton,'Enable','on');
            end
            
        case 5
            % z comove -50um
%             pDisplay1 = prePosition(1,:) + [0,0,-10000]
%             pDisplay(3) = pDisplay(3)
            comoveInjectionWithInjection(1,numSwitch,[0,0,-10000],0,handles);
            goTo(1,pDisplay1,handles);
            
            prePosition(numSwitch,1)
            
            % get current slave element position
            if (elementAvailable(numSwitch) == 1)
                pXYZ = getCurrentPosition(numSwitch, handles);
                setNewPosition(numSwitch,pXYZ);
            else
                disp(['Comport is unavailable.',newline]);
            end
            prePosition(numSwitch,1)
            
            % set slave element position
            text = [num2str(prePosition(numSwitch,1)),' ',num2str(prePosition(numSwitch,2)),' ',num2str(prePosition(numSwitch,3))];
            set(handles.text23,'string',text);
            set(handles.text23,'value',1);
            if get(handles.text25,'value') == 1
                set(handles.ok_pushbutton,'Enable','on');
            end
            
        otherwise
            disp(['Error in config button value.',newline]);
            return;
    end
            
        
%{    
%     str = get(hObject,'string');
%     switch(str)
%         case 'Get' 
%             if loc(1) == 0 && loc(2) == 0
%                 disp(['Get the position first.',newline]);
%                 return;
%             end
%             set(hObject,'string','Set');
%             tempP = transformImagePositionToMicroscopePosition();
%             % get current Z
%             if (elementAvailable(1) == 1)
%                 pXYZ = getCurrentPosition(1, handles);
%                 setNewPosition(1,pXYZ);
%             else
%                 disp(['Comport is unavailable.',newline]);
%             end
%             text = [num2str(tempP(1)),' ',num2str(tempP(2)),' ',num2str(prePosition(1,3))];
%             set(handles.text23,'string',text);
%             set(handles.text23,'value',1);
%             if get(handles.text25,'value') == 1
%                 set(handles.ok_pushbutton,'Enable','on');
%             end
%             
%         case 'Set'
%             set(hObject,'string','Get');
%             % start to get point
%     end
%}
end
    


% --- Executes on button press in set2.
function set2_Callback(hObject, eventdata, handles)
% hObject    handle to set2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global loc prePosition elementAvailable numSwitch configValue;
if get(hObject,'value')
    %{
    if loc(1) == 0 && loc(2) == 0
        disp(['Get the position first.',newline]);
        return;
    end
    %}
    
    if configValue == 1 || configValue == 2
        
        % get current Z, update current position
        if (elementAvailable(1) == 1)
            pXYZ = getCurrentPosition(1, handles);
            setNewPosition(1,pXYZ);
        else
            disp(['Comport is unavailable.',newline]);
        end
%         tempP = transformImagePositionToMicroscopePosition();
%         text = [num2str(tempP(1)),' ',num2str(tempP(2)),' ',num2str(prePosition(1,3))];
        text = [num2str(prePosition(1,1)),' ',num2str(prePosition(1,2)),' ',num2str(prePosition(1,3))];
    else
        % get current slave element position
        if (elementAvailable(numSwitch) == 1)
            pXYZ = getCurrentPosition(numSwitch, handles);
            setNewPosition(numSwitch,pXYZ);
        else
            disp(['Comport is unavailable.',newline]);
        end
        % set slave element position
        text = [num2str(prePosition(numSwitch,1)),' ',num2str(prePosition(numSwitch,2)),' ',num2str(prePosition(numSwitch,3))];
    end
        
    set(handles.text25,'string',text);
    set(handles.text25,'value',1);
    if get(handles.text23,'value') == 1
        set(handles.ok_pushbutton,'Enable','on');
    %{
    else
        % injection move (100,100,100)um
        pDisplay = prePosition(4,:) + [10000,10000,10000]
        goTo(4,pDisplay,handles);
        % microscope move (0,0,100)um
        pDisplay = prePosition(1,:) + [0,0,10000]
        goTo(1,pDisplay,handles);
        % manual adjustment
    %}
    end
    loc(1) = 0;
    loc(2) = 0;
    
    %{
    str = get(hObject,'string');
    switch(str)
        case 'Get' 
            if loc(1) == 0 && loc(2) == 0
                disp(['Get the position first.',newline]);
                return;
            end
            set(hObject,'string','Set');
            tempP = transformImagePositionToMicroscopePosition();
            % get current Z, update current position
            if (elementAvailable(1) == 1)
                pXYZ = getCurrentPosition(1, handles);
                setNewPosition(1,pXYZ);
            else
                disp(['Comport is unavailable.',newline]);
            end
            text = [num2str(tempP(1)),' ',num2str(tempP(2)),' ',num2str(prePosition(1,3))];
            set(handles.text25,'string',text);
            set(handles.text25,'value',1);
            if get(handles.text23,'value') == 1
                set(handles.ok_pushbutton,'Enable','on');
            end
            
        case 'Set'
            set(hObject,'string','Get');
            % strat to get point
    end
    %}
end


% --- Executes on button press in ok_pushbutton.
function ok_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to ok_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global numSwitch loc angleOffset angleZ calibrateFlag xOffset yOffset zOffset configValue prePosition initialL;
% tempP = transformImagePositionToMicroscopePosition();

if get(hObject,'value')
    % get probe position
    P1 = zeros(1,3);
    tempstr0 = get(handles.text23,'string');
    str0 = split(tempstr0,' ');
    P1(1) = str2num(str0{1});
    P1(2) = str2num(str0{2});
    P1(3) = str2num(str0{3});
    P1
    logAdd(['P1 = (',num2str(P1(1)),',',num2str(P1(2)),',',num2str(P1(3)),')']);
    % get cell position
    P2 = zeros(1,3);
    tempstr0 = get(handles.text25,'string');
    str0 = split(tempstr0,' ');
    P2(1) = str2num(str0{1});
    P2(2) = str2num(str0{2});
    P2(3) = str2num(str0{3});
    P2
    logAdd(['P2 = (',num2str(P2(1)),',',num2str(P2(2)),',',num2str(P2(3)),')']);
    %str1 = get(handles.probeCalibration_pushbutton,'FontWeight');
    
    switch (configValue)
        case 1
            % test by injection 3
            % Calibration
            dx = P2(1) - P1(1)
            dy = P2(2) - P1(2)
%             dz = P2(3) - P1(3)
            angleOffset(numSwitch)
            sqrt(dx * dx + dy * dy)
            temp = roundn(atan(dy / dx) / pi * 180,-2)    %0.01
            if temp < 0
                angleOffset(numSwitch) = temp + 180
            end
            % update parameter file
            
        case 2
            % test by injection 3
            %{
            % get current slave element position
            if (elementAvailable(numSwitch) == 1)
                pXYZ = getCurrentPosition(numSwitch, handles);
                setNewPosition(numSwitch,pXYZ);
            else
                disp(['Comport is unavailable.',newline]);
            end
            %}
            % Initialize target points
            dz11 = 15000; % 150um, farther from the cell
            P11 = computeRoutinePoint(4,P2,dz11,handles)
            dz22 = 5000; % 50um, closer to the cell 
            P22 = computeRoutinePoint(4,P2,dz22,handles)
            
            logAdd(['P11 = (',num2str(P11(1)),',',num2str(P11(2)),',',num2str(P11(3)),',',num2str(P11(4)),')']);
            logAdd(['P22 = (',num2str(P22(1)),',',num2str(P22(2)),',',num2str(P22(3)),',',num2str(P22(4)),')']);
            % goto reaction
            [P11(1)-P1(1),P11(2)-P1(2),P11(3)-P1(3)]
            comoveInjectionWithInjection(1,4,[P11(1)-P1(1),P11(2)-P1(2),P11(3)-P1(3)],0,handles); % from P1 to P11
            goTo(1,P11(1:3),handles);
            
            set(handles.ok_pushbutton,'Enable','off');
            set(handles.next_pushbutton,'Enable','on');
            set(handles.next_pushbutton,'visible','on');
           initialL{1} = [1,P11(4)-P22(4),P22(4)]
           initialL{2} = P22(1:3)
           initialL{3} = P2
            
%             set(handles.ok_pushbutton,'value',[P11(4)-P22(4),P22(4)]);
            % x&z comove from P11 to P22
%             xzComoveOfInjection(4,P22(4)-P11(4),handles);
            % x&z comove from P22 to P2
%             xzComoveOfInjection(4,-P22(4),handles);
        case 3
            % x offset
            P2(1) - P1(1)
%             (P2(1) - P1(1)) / 10000
            P2(2) - P1(2)
%             (P2(2) - P1(2)) / 10000
            xOffset(numSwitch,1) = roundn((P2(1) - P1(1)) / 10000,-2)
            xOffset(numSwitch,2) = roundn((P2(2) - P1(2)) / 10000,-2)
        case 4
            % y offset
            P2(1) - P1(1)
%             (P2(1) - P1(1)) / 10000
            P2(2) - P1(2)
            yOffset(numSwitch,1) = roundn((P2(1) - P1(1)) / 10000,-2)
            yOffset(numSwitch,2) = roundn((P2(2) - P1(2)) / 10000,-2)
        case 5
            % z offset
            P2(1) - P1(1)
%             (P2(1) - P1(1)) / 10000
            P2(2) - P1(2)
            zOffset(numSwitch,1) = roundn(-(P2(1) - P1(1)) / 10000,-2)
            zOffset(numSwitch,2) = roundn(-(P2(2) - P1(2)) / 10000,-2)
        otherwise
            disp(['Error in config button value.',newline]);
            return;
    end
end
% str2 = get(handles.initializeInjectPoint_pushbutton,'FontWeight')
set(handles.xoffset_pushbutton,'Enable','on');
set(handles.yoffset_pushbutton,'Enable','on');
set(handles.zoffset_pushbutton,'Enable','on');
calibrateFlag(numSwitch) = 1;
saveParameterToConfigFile();


% --- Executes on button press in cancel_pushbutton.
function cancel_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to cancel_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global loc;
if get(hObject,'value')
    loc = zeros(1,2);
    set(handles.text23,'string','');
    set(handles.text23,'value',0);
    set(handles.text25,'string','');
    set(handles.text25,'value',0);
    set(handles.config_uipanel,'Visible',0);
    set(handles.next_pushbutton,'Visible',0)
end


% --- Executes on button press in probeCalibration_pushbutton.
function probeCalibration_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to probeCalibration_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global loc configValue;
if get(hObject,'value')
    configValue = 1;
    set(handles.probeCalibration_uipanel,'title','Probe Calibration');
    set(handles.p1_text,'string','Point1:');
    set(handles.p2_text,'string','Point2:');
    set(handles.probeCalibration_pushbutton,'FontWeight','bold');
    set(handles.initializeInjectPoint_pushbutton,'FontWeight','normal');
    set(handles.xoffset_pushbutton,'FontWeight','normal');
    set(handles.yoffset_pushbutton,'FontWeight','normal');
    set(handles.zoffset_pushbutton,'FontWeight','normal');
    set(handles.text23,'string','');
    set(handles.text25,'string','');
    set(handles.text23,'value',0);
    set(handles.text25,'value',0);
    loc(1) = 0;
    loc(2) = 0;
end


% --- Executes on button press in initializeInjectPoint_pushbutton.
function initializeInjectPoint_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to initializeInjectPoint_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global loc configValue;
if get(hObject,'value')
    configValue = 2;
    set(handles.probeCalibration_uipanel,'title','Probe Inject Initialization');
    set(handles.p1_text,'string','P_probe:');
    set(handles.p2_text,'string','P_cell    :');
    set(handles.probeCalibration_pushbutton,'FontWeight','normal');
    set(handles.initializeInjectPoint_pushbutton,'FontWeight','bold');
    set(handles.xoffset_pushbutton,'FontWeight','normal');
    set(handles.yoffset_pushbutton,'FontWeight','normal');
    set(handles.zoffset_pushbutton,'FontWeight','normal');
    set(handles.text23,'string','');
    set(handles.text25,'string','');
    set(handles.text23,'value',0);
    set(handles.text25,'value',0);
    loc(1) = 0;
    loc(2) = 0;
end


% --- Executes on button press in config_pushbutton.
function config_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to config_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global loc numSwitch calibrateFlag configValue;
if get(hObject,'value')
    configValue = 1;
    set(handles.config_uipanel,'Visible',1);
    set(handles.probeCalibration_uipanel,'title','Probe Calibration');
    set(handles.p1_text,'string','Point1:');
    set(handles.p2_text,'string','Point2:');
<<<<<<< HEAD
    %{
    if numSwitch == 1
        set(handles.probeCalibration_pushbutton,'Enable','off');
        set(handles.initializeInjectPoint_pushbutton,'FontWeight','bold');
        set(handles.xoffset_pushbutton,'Enable','off');
        set(handles.yoffset_pushbutton,'Enable','off');
        set(handles.zoffset_pushbutton,'Enable','off');
    else
        set(handles.probeCalibration_pushbutton,'FontWeight','bold');
        set(handles.initializeInjectPoint_pushbutton,'FontWeight','normal');
        set(handles.xoffset_pushbutton,'FontWeight','normal');
        set(handles.yoffset_pushbutton,'FontWeight','normal');
        set(handles.zoffset_pushbutton,'FontWeight','normal');
    end
    %}
    set(handles.probeCalibration_pushbutton,'FontWeight','bold');
    set(handles.initializeInjectPoint_pushbutton,'FontWeight','normal');
    set(handles.xoffset_pushbutton,'FontWeight','normal');
    set(handles.yoffset_pushbutton,'FontWeight','normal');
    set(handles.zoffset_pushbutton,'FontWeight','normal');
    set(handles.text23,'string','');
    set(handles.text25,'string','');
    set(handles.text23,'value',0);
    set(handles.text25,'value',0);
    loc(1) = 0;
    loc(2) = 0;
    set(handles.ok_pushbutton,'Enable','off');
    if calibrateFlag(numSwitch) == 1
        set(handles.xoffset_pushbutton,'Enable','on');
        set(handles.yoffset_pushbutton,'Enable','on');
        set(handles.zoffset_pushbutton,'Enable','on');
    else
        set(handles.xoffset_pushbutton,'Enable','off');
        set(handles.yoffset_pushbutton,'Enable','off');
        set(handles.zoffset_pushbutton,'Enable','off');
    end
end


% --- Executes on button press in xoffset_pushbutton.
function xoffset_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to xoffset_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global loc configValue;
if get(hObject,'value')
    configValue = 3;
    set(handles.probeCalibration_uipanel,'Title','X_Offset');
    set(handles.p1_text,'string','P_Start');
    set(handles.p2_text,'string','P_End');
    set(handles.probeCalibration_pushbutton,'FontWeight','normal');
    set(handles.initializeInjectPoint_pushbutton,'FontWeight','normal');
    set(handles.xoffset_pushbutton,'FontWeight','bold');
    set(handles.yoffset_pushbutton,'FontWeight','normal');
    set(handles.zoffset_pushbutton,'FontWeight','normal');
    set(handles.text23,'string','');
    set(handles.text25,'string','');
    set(handles.text23,'value',0);
    set(handles.text25,'value',0);
    loc(1) = 0;
    loc(2) = 0;
end


% --- Executes on button press in yoffset_pushbutton.
function yoffset_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to yoffset_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global loc configValue;
if get(hObject,'value')
    configValue = 4;
    set(handles.probeCalibration_uipanel,'Title','Y_Offset');
    set(handles.p1_text,'string','P_Start');
    set(handles.p2_text,'string','P_End');
    set(handles.probeCalibration_pushbutton,'FontWeight','normal');
    set(handles.initializeInjectPoint_pushbutton,'FontWeight','normal');
    set(handles.xoffset_pushbutton,'FontWeight','normal');
    set(handles.yoffset_pushbutton,'FontWeight','bold');
    set(handles.zoffset_pushbutton,'FontWeight','normal');
    set(handles.text23,'string','');
    set(handles.text25,'string','');
    set(handles.text23,'value',0);
    set(handles.text25,'value',0);
    loc(1) = 0;
    loc(2) = 0;
end

% --- Executes on button press in zoffset_pushbutton.
function zoffset_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to zoffset_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global loc configValue;
if get(hObject,'value')
    configValue = 5;
    set(handles.probeCalibration_uipanel,'Title','Z_Offset');
    set(handles.p1_text,'string','P_Start');
    set(handles.p2_text,'string','P_End');
    set(handles.probeCalibration_pushbutton,'FontWeight','normal');
    set(handles.initializeInjectPoint_pushbutton,'FontWeight','normal');
    set(handles.xoffset_pushbutton,'FontWeight','normal');
    set(handles.yoffset_pushbutton,'FontWeight','normal');
    set(handles.zoffset_pushbutton,'FontWeight','bold');
    set(handles.text23,'string','');
    set(handles.text25,'string','');
    set(handles.text23,'value',0);
    set(handles.text25,'value',0);
    loc(1) = 0;
    loc(2) = 0;
end

function configButtonsBoldToNormal(index)
% 


% --- Executes on button press in comove_microscope.
function comove_microscope_Callback(hObject, eventdata, handles)
% hObject    handle to comove_microscope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of comove_microscope

global coMoveFlag;
if get(hObject,'Value')
    coMoveFlag(1) = 1;
else
    coMoveFlag(1) = 0;
end


% --- Executes on button press in comove_injection1.
function comove_injection1_Callback(hObject, eventdata, handles)
% hObject    handle to comove_injection1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of comove_injection1

global coMoveFlag;
if get(hObject,'Value')
    coMoveFlag(2) = 1;
else
    coMoveFlag(2) = 0;
end

% --- Executes on button press in comove_injection2.
function comove_injection2_Callback(hObject, eventdata, handles)
% hObject    handle to comove_injection2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of comove_injection2

global coMoveFlag;
if get(hObject,'Value')
    coMoveFlag(3) = 1;
else
    coMoveFlag(3) = 0;
end

% --- Executes on button press in comove_injection4.
function comove_injection4_Callback(hObject, eventdata, handles)
% hObject    handle to comove_injection4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of comove_injection4

global coMoveFlag;
if get(hObject,'Value')
    coMoveFlag(5) = 1;
else
    coMoveFlag(5) = 0;
end

% --- Executes on button press in comove_injection5.
function comove_injection5_Callback(hObject, eventdata, handles)
% hObject    handle to comove_injection5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of comove_injection5

global coMoveFlag;
if get(hObject,'Value')
    coMoveFlag(6) = 1;
else
    coMoveFlag(6) = 0;
end

% --- Executes on button press in comove_injection6.
function comove_injection6_Callback(hObject, eventdata, handles)
% hObject    handle to comove_injection6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of comove_injection6

global coMoveFlag;
if get(hObject,'Value')
    coMoveFlag(7) = 1;
else
    coMoveFlag(7) = 0;
end

% --- Executes on button press in comove_injection7.
function comove_injection7_Callback(hObject, eventdata, handles)
% hObject    handle to comove_injection7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of comove_injection7

global coMoveFlag;
if get(hObject,'Value')
    coMoveFlag(8) = 1;
else
    coMoveFlag(8) = 0;
end

% --- Executes on button press in comove_injection8.
function comove_injection8_Callback(hObject, eventdata, handles)
% hObject    handle to comove_injection8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of comove_injection8

global coMoveFlag;
if get(hObject,'Value')
    coMoveFlag(9) = 1;
else
    coMoveFlag(9) = 0;
end


% --- Executes during object creation, after setting all properties.
function goTo_pushbutton_CreateFcn(hObject, eventdata, handles)
% hObject    handle to goTo_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in cameraOff_pushbutton.
function cameraOff_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to cameraOff_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global CameraOpenFlag;
CameraOpenFlag = false;
set(handles.CameraButton,'Enable','on');


% --- Executes on button press in next_pushbutton.
function next_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to next_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% k = get(handles.next_pushbutton,'value')
% Lxoy = get(handles.ok_pushbutton,'value')
global initialL;
switch(initialL{1}(1))
    case 1
        % k=1: x&z comove from P11 to P22
%         xzComoveOfInjection(4,-initialL(2),handles);
        goToApproach(4,-initialL{1}(2),initialL{2},1,handles);
        initialL{1}(1) = 2;
        
    case 2
        % change to low speed
        
        % k=2: x&z comove from P22 to P2
%         xzComoveOfInjection(4,-initialL(3),handles);
        goToApproach(4,-initialL{1}(3),initialL{3},1,handles)
%         set(handles.next_pushbutton,'Enable',0);
end


% --- Executes on button press in test_pushbutton.
function test_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to test_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

testApproachFunc(7,-10000,handles);

function testApproachFunc(index,dx,handles)
% XZ-comove test function
% index: element index
% dx: injection position change in x direction

global angleZ angleOffset prePosition elementAvailable;

offsetAngleAlpha = str2double(get(handles.AlphaOffset_edit,'String'));
offsetAngleTheta = str2double(get(handles.ThetaOffset_edit,'String'));
% get current position
if (elementAvailable(index) == 1)
    pXYZ = getCurrentPosition(index, handles);
    setNewPosition(index,pXYZ);
else
    disp(['Comport is unavailable.',newline]);
end
dA = dx / cos((angleZ(index-1) + offsetAngleAlpha) / 180 * pi)
rdA = round(dA)
dz = dx*tan((angleZ(index-1) + offsetAngleAlpha) / 180 * pi)
rdz = round(dz)
rdx = round(dx * cos((angleOffset(index) + offsetAngleTheta) / 180 * pi))
rdy = round(dx * sin((angleOffset(index) + offsetAngleTheta) / 180 * pi))
destP = prePosition(1,:) + [rdx, rdy, rdz]
goToApproach(index,rdA,destP,1,handles);
% dA r(dA) dz r(dz)
logAdd(['(',num2str(dA),',',num2str(rdA),',',num2str(dz),',',num2str(rdz),')']);
% destP
logAdd(['destP = (',num2str(destP(1)),',',num2str(destP(2)),',',num2str(destP(3)),')']);


% --- Executes on button press in refreshPosition_pushbutton.
function refreshPosition_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to refreshPosition_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

testRefreshPosition(1,handles)
testRefreshPosition(7,handles)

function testRefreshPosition(i,handles)
% i: element index
% handles: gui global handle

global elementAvailable prePosition;
% get current position
if (elementAvailable(i) == 1)
    pXYZ = getCurrentPosition(i, handles);
    setNewPosition(i,pXYZ);
else
    disp(['Comport is unavailable.',newline]);
end
% newP
logAdd(['P',num2str(i),' = (',num2str(prePosition(i,1)),',',num2str(prePosition(i,2)),',',num2str(prePosition(i,3)),')']);

function testForHysteresisError()
% hysteresis error automatic measurement
% 



function ThetaOffset_edit_Callback(hObject, eventdata, handles)
% hObject    handle to ThetaOffset_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ThetaOffset_edit as text
%        str2double(get(hObject,'String')) returns contents of ThetaOffset_edit as a double


% --- Executes during object creation, after setting all properties.
function ThetaOffset_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ThetaOffset_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function AlphaOffset_edit_Callback(hObject, eventdata, handles)
% hObject    handle to AlphaOffset_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AlphaOffset_edit as text
%        str2double(get(hObject,'String')) returns contents of AlphaOffset_edit as a double


% --- Executes during object creation, after setting all properties.
function AlphaOffset_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AlphaOffset_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in tipSave_pushbutton.
function tipSave_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to tipSave_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global elementAvailable prePosition currentInjectionP ;
% get current position
i = 1;
if (elementAvailable(i) == 1)
    pXYZ = getCurrentPosition(i, handles);
    setNewPosition(i,pXYZ);
else
    disp(['Comport is unavailable.',newline]);
end
currentInjectionP = prePosition(1,:)
set(handles.tip_text,'String',[num2str(currentInjectionP(1)),' ',num2str(currentInjectionP(2)),' ',num2str(currentInjectionP(3))]);


% --- Executes on button press in cellSave_pushbutton.
function cellSave_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to cellSave_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global elementAvailable prePosition currentCellP ;
% get current position
i = 1;
if (elementAvailable(i) == 1)
    pXYZ = getCurrentPosition(i, handles);
    setNewPosition(i,pXYZ);
else
    disp(['Comport is unavailable.',newline]);
end
currentCellP = prePosition(1,:)
set(handles.cell_text,'String',[num2str(currentCellP(1)),' ',num2str(currentCellP(2)),' ',num2str(currentCellP(3))]);


% --- Executes on button press in rough_checkbox.
function rough_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to rough_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rough_checkbox
set(handles.fine_checkbox,'Value',0);


% --- Executes on button press in touchTest_pushbutton.
function touchTest_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to touchTest_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global elementAvailable prePosition currentInjectionP ;
% get current position
i = 7;
if (elementAvailable(i) == 1)
    pXYZ = getCurrentPosition(i, handles);
    setNewPosition(i,pXYZ);
else
    disp(['Comport is unavailable.',newline]);
end
destP = prePosition(i,:) + [0,1500,0];
goTo(i,destP,handles);
pause(0.5);
destP = prePosition(i,:) + [0,-3000,0];
goTo(i,destP,handles);
pause(0.5);
destP = prePosition(i,:) + [0,1500,0];
goTo(i,destP,handles);


% --- Executes on button press in refreshPosition2_pushbutton.
function refreshPosition2_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to refreshPosition2_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

testRefreshPosition(1,handles)
testRefreshPosition(7,handles)
logAdd('');


% --- Executes on button press in getFrameTest_pushbutton.
function getFrameTest_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to getFrameTest_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global obj;
frame = getsnapshot(obj);
frame = ycbcr2rgb(frame);
flushdata(obj);
figure
imshow(frame);


% --- Executes on button press in cellDetect_checkbox.
function cellDetect_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to cellDetect_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cellDetect_checkbox


% --- Executes on button press in testfunc_pushbutton.
function testfunc_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to testfunc_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in approach_pushbutton.
function approach_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to approach_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global StepA angleZ angleOffset currentInjectionP ;
index = 7;
dz = StepA*sin(angleZ(index-1)/180*pi)
lxoy = StepA*cos(angleZ(index-1)/180*pi)
dx = lxoy*cos(angleOffset(index)/180*pi)
dy = lxoy*sin(angleOffset(index)/180*pi)
P = round([dx,dy,dz]) + currentInjectionP
goToApproach(index,StepA,zeros(1,3),0,handles);

% --- Executes on button press in offsetApproach_pushbutton.
function offsetApproach_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to offsetApproach_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global currentCellP prePosition StepA angleZ angleOffset currentInjectionP elementAvailable;

% get new cell position
i = 1;
if (elementAvailable(i) == 1)
    pXYZ = getCurrentPosition(i, handles);
    setNewPosition(i,pXYZ);
else
    disp(['Comport is unavailable.',newline]);
end

dPCell = prePosition(1,:)-currentCellP
currentCellP = prePosition(1,:);
set(handles.cell_text,'String',[num2str(currentCellP(1)),' ',num2str(currentCellP(2)),' ',num2str(currentCellP(3))]);

% add offset to approach
approachWithOffset(7,StepA,dPCell,handles)
% get current position
index = 7;
dz = StepA*sin(angleZ(index-1)/180*pi)
lxoy = StepA*cos(angleZ(index-1)/180*pi)
dx = lxoy*cos(angleOffset(index)/180*pi)
dy = lxoy*sin(angleOffset(index)/180*pi)
P = round([dx,dy,dz]) + dPCell + currentInjectionP


% --- Executes on button press in preStart_pushbutton.
function preStart_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to preStart_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% P1: injection position
% Pcell: cell position

global prePosition currentInjectionP;

 % get probe position
P1 = zeros(1,3);
tempstr0 = get(handles.tip_text,'string');
str0 = split(tempstr0,' ');
P1(1) = str2num(str0{1});
P1(2) = str2num(str0{2});
P1(3) = str2num(str0{3});
P1
logAdd(['P1 = (',num2str(P1(1)),',',num2str(P1(2)),',',num2str(P1(3)),')']);
 % get cell position
P2 = zeros(1,3);
tempstr0 = get(handles.cell_text,'string');
str0 = split(tempstr0,' ');
P2(1) = str2num(str0{1});
P2(2) = str2num(str0{2});
P2(3) = str2num(str0{3});
P2
logAdd(['P2 = (',num2str(P2(1)),',',num2str(P2(2)),',',num2str(P2(3)),')']);

%{
% get current position
if (elementAvailable(index) == 1)
    pXYZ = getCurrentPosition(index, handles);
    setNewPosition(index,pXYZ);
else
    disp(['Comport is unavailable.',newline]);
end
P1 = prePosition(1,:);
%}
index = 7;
dz = P1(3) - P2(3)    %z of injection above cell
pStart = computeRoutinePoint(index,P2,dz);   
% goto reaction
[pStart(1)-P1(1),pStart(2)-P1(2),pStart(3)-P1(3)]
comoveInjectionWithInjection(1,index,[pStart(1)-P1(1),pStart(2)-P1(2),pStart(3)-P1(3)],0,handles); % from P1 to P11
currentInjectionP = pStart(1:3);
%goTo(1,P11(1:3),handles);
% Deviation correction


% --- Executes on button press in zStart_pushbutton.
function zStart_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to zStart_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global prePosition elementAvailable;
index = 1;
% get current position
if (elementAvailable(index) == 1)
    pXYZ = getCurrentPosition(index, handles);
    setNewPosition(index,pXYZ);
    refreshGuiPosition(handles)		% refresh position diaplayed
else
    disp(['Comport is unavailable.',newline]);
end
set(handles.zStart_text,'string',num2str(prePosition(1,3)));

% --- Executes on button press in zEnd_pushbutton.
function zEnd_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to zEnd_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global prePosition elementAvailable;
index = 1;
% get current position
if (elementAvailable(index) == 1)
    pXYZ = getCurrentPosition(index, handles);
    setNewPosition(index,pXYZ);
    refreshGuiPosition(handles)		% refresh position diaplayed
else
    disp(['Comport is unavailable.',newline]);
end
set(handles.zEnd_text,'string',num2str(prePosition(1,3)));

% --- Executes on button press in zStepMove_pushbutton.
function zStepMove_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to zStepMove_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global prePosition elementAvailable obj CameraOpenFlag isAutoSaving;
zStep = str2num(get(handles.zStep_edit,'String'));
zStart = str2num(get(handles.zStart_text,'String'));
zEnd = str2num(get(handles.zEnd_text,'String'));

index = 1;
% get current position
if (elementAvailable(index) == 1)
    pXYZ = getCurrentPosition(index, handles);
    setNewPosition(index,pXYZ);
    refreshGuiPosition(handles)		% refresh position diaplayed
else
    disp(['Comport is unavailable.',newline]);
end
%
% step move
if (prePosition(index,3) ~= zStart)
    goTo(index,[prePosition(index,1),prePosition(index,2),zStart],handles);
    waitForPositionUpdate(index,handles);
    refreshGuiPosition(handles)		% refresh position diaplayed
end
z = zStart;

maxNum = 50000;
path = get(handles.path_edit,'string');
if (~isAutoSaving)
    isAutoSaving = 1;
    counter = 0;
    n = 3;
else
    isAutoSaving = 0;
end

%
while ((z + zStep) > zEnd && counter < maxNum && isAutoSaving)
    z = z + zStep;
    goTo(index,[prePosition(index,1),prePosition(index,2),z],handles);
    refreshGuiPosition(handles)		% refresh position diaplayed
    waitForPositionUpdate(index,handles);
    if (isAutoSaving)
%         tic;
        counter = counter + 1;
        filename = [path,'\image_',num2str(counter),'.tiff'];
        
        for i = 1:n
            if (i == 1)
                frame1 = getsnapshot(obj);
                flushdata(obj);
                frame = double(frame1);
            else
                frame1 = getsnapshot(obj);
                flushdata(obj);
                frame = frame + double(frame1);
            end
        end
        frame = frame / n;
        frame = uint16(frame);
        imwrite(frame,filename);
%         imwrite(ycbcr2rgb(frame),filename);
%         time = toc;
%         fps = round(10/time)/10;
    end
end
isAutoSaving = 0;
%}

% -----------------------------meanStepTest-------------------------------
% get first image
%{
frame = getsnapshot(obj);
flushdata(obj);
frame = double(frame);
imean1 = mean2(frame);
istd1 = std2(frame);
logAdd([num2str(imean1),' ',num2str(0),' ',num2str(istd1),' ',num2str(0)]);
% get second image
frame = getsnapshot(obj);
flushdata(obj);
frame = double(frame);
imean2 = mean2(frame);
dmean1 = imean2 - imean1;
imean1 = imean2;
istd2 = std2(frame);
dstd1 = istd2 - istd1;
istd1 = istd2;
logAdd([num2str(imean1),' ',num2str(dmean1),' ',num2str(istd1),' ',num2str(dstd1)]);
% initialization
CDobj = ContentDetect(20);
% [imean1,dmean1] = CDobj.findSharpMeanStdChangeInitialize(I1,I2,0);



% in air
initialFlag = 0
while(CDobj.tag == 0 && (z + zStep) > zEnd)
    % get new image
    frame = getsnapshot(obj);
    flushdata(obj);
    imean2 = mean2(frame);
    dmean1 = imean2 - imean1;
    imean1 = imean2;
    istd2 = std2(frame);
    dstd1 = istd2 - istd1;
    istd1 = istd2;
    logAdd([num2str(imean1),' ',num2str(dmean1),' ',num2str(istd1),' ',num2str(dstd1)]);
    while (initialFlag < 6)
        imwrite(frame,['E:\photo\20210628\01x04\002\matlab\image_',num2str(initialFlag),'.tiff']);
        initialFlag = initialFlag + 1;
    end
%     [imean1,dmean1,CDobj] = findSharpMeanChange(CDobj,imean1,dmean1,frame);
    % z move ****************************
%     z = z + zStep;
%     goTo(index,[prePosition(index,1),prePosition(index,2),z],handles);
%     refreshGuiPosition(handles)		% refresh position diaplayed
%     waitForPositionUpdate(index,handles);
    
end
CDobj.tag
%}

% -----------------------------stdStepTest--------------------------------
%{
if (CDobj.tag == 1)
    CDobj.tag = 0;
    
    % get first image
    I1 = getsnapshot(obj);
    flushdata(obj);
    % get second image
    I2 = getsnapshot(obj);
    flushdata(obj);
    % initialization
    CDobj = ContentDetect(10,2);
    [istd1,dstd1] = CDobj.findSharpMeanStdChangeInitialize(I1,I2,1);
    flag = 0;
    
    % in water and see nothing
    while(CDobj.tag == 0 && (z + zStep) > zEnd)
        
        % get new image
        frame = getsnapshot(obj);
        flushdata(obj);

        if (flag == 0)
            % constant z 
            [flag,istd1,dstd1] = findSharpStdUpInitialize(CDobj,istd1,dstd1,frame);
        else
            [istd1,dstd1,dstd2,CDobj] = findSharpStdUp(CDobj,istd1,dstd1,dstd2,frame);
            % z move ************************
            z = z + zStep;
            goTo(index,[prePosition(index,1),prePosition(index,2),z],handles);
            refreshGuiPosition(handles)		% refresh position diaplayed
            waitForPositionUpdate(index,handles);
        end
        
    end
end
CDobj.tag
%}
% low speed move
% 'VJ' cmd

function zStep_edit_Callback(hObject, eventdata, handles)
% hObject    handle to zStep_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of zStep_edit as text
%        str2double(get(hObject,'String')) returns contents of zStep_edit as a double


% --- Executes during object creation, after setting all properties.
function zStep_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to zStep_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function approach_pushbutton_CreateFcn(hObject, eventdata, handles)
% hObject    handle to approach_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in startautosave_pushbutton.
function startautosave_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to startautosave_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global obj CameraOpenFlag isAutoSaving;

if (CameraOpenFlag)
    maxNum = 50000;
    path = get(handles.path_edit,'string');
    str = get(hObject,'string');
    if (strcmp(str,'Start'))
        isAutoSaving = 1;
        set(hObject,'string','Stop');
    %     set(hObject,'value',flag);
        counter = 0;
    else
        isAutoSaving = 0;
        set(hObject,'string','Start');
    %     set(hObject,'value',flag);
    end
    while (isAutoSaving && counter < maxNum)
%         tic;
        counter = counter + 1;
        filename = [path,'\image_',num2str(counter),'.tiff'];
        frame = getsnapshot(obj);
        flushdata(obj);
%         imwrite(ycbcr2rgb(frame),filename);
        imwrite(frame,filename);
%         time = toc;
%         fps = round(10/time)/10;
    end
end



function path_edit_Callback(hObject, eventdata, handles)
% hObject    handle to path_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of path_edit as text
%        str2double(get(hObject,'String')) returns contents of path_edit as a double


% --- Executes during object creation, after setting all properties.
function path_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to path_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

path = [pwd,'\image'];
if ~(exist(path,'dir'))
    mkdir(path);
end
set(hObject,'string',path);


% --- Executes on button press in path_pushbutton.
function path_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to path_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

path = get(handles.path_edit,'string');
filepath = uigetdir(path,'��ѡ���ļ���');%fliepathΪ�ļ���·��
if (filepath ~= 0)
    set(handles.path_edit,'string',filepath);
end


% --- Executes during object creation, after setting all properties.
function startautosave_pushbutton_CreateFcn(hObject, eventdata, handles)
% hObject    handle to startautosave_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in autocelldetect_pushbutton.
function autocelldetect_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to autocelldetect_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global StepZ elementAvailable prePosition;
StepZ = str2num(get(handles.zStep_edit,'String'));
zStart = str2num(get(handles.zStart_text,'String'));
zEnd = str2num(get(handles.zEnd_text,'String'));

index = 1;
% get current position
if (elementAvailable(index) == 1)
    pXYZ = getCurrentPosition(index, handles);
    setNewPosition(index,pXYZ);
    refreshGuiPosition(handles)		% refresh position diaplayed
else
    disp(['Comport is unavailable.',newline]);
end
%
% step move
if (prePosition(index,3) ~= zStart)
    goTo(index,[prePosition(index,1),prePosition(index,2),zStart],handles);
    waitForPositionUpdate(index,handles);
    refreshGuiPosition(handles)		% refresh position diaplayed
end

[tag,z] = contentEstimate(3,0,zStart,zEnd,handles);
tag
z
=======
    set(handles.probeCalibration_pushbutton,'FontWeight','bold');
    set(handles.pushbutton33,'Enable','off');
end


% --- Executes on button press in PseudocolorButton.
function PseudocolorButton_Callback(hObject, eventdata, handles)
% hObject    handle to PseudocolorButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of PseudocolorButton

global h obj;
global CameraOpenFlag;

CameraOpenFlag = getappdata(handles.figure1, 'isCameraOpened');
PseudocolorFlag = get(hObject,'Value');
% axes(handles.PseudocolorImage);
% axis off;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
while ishandle(h)
    tmp = get(hObject,'Value');
    if PseudocolorFlag == 0 && tmp == 0
        break;
    end
    if tmp && CameraOpenFlag
         %%%%%%%%%%%%%%��˼��%%%%%%%%%%%%%%%%%
%     figure(1);
%     while ishandle(h)%��֡����1229
% %         axes(handles.Image_display);
%         frame = getsnapshot(obj);
%         
%         flushdata(obj);
% %         imshow(rgb2gray(ycbcr2rgb(frame)));
%         [out_img, points] = PipDetectFun(rgb2gray(ycbcr2rgb(frame)));
%         imshow(out_img);
%         hold on
%         plot(points.Location(1),points.Location(2),'r*','LineWidth',3);
%         hold off
%         drawnow;
%     end
     %%%%%%%%%%%%%%%%ϸ�����%%%%%%%%%%%%%%%%
%      DetectFun = MultiFunctions;
%      figure(1)
%      while ishandle(h)
% %          disp("Here")
%          frame = ycbcr2rgb(getsnapshot(obj));
%          flushdata(obj);
%          tic
%          [cell_location,flag] = DetectFun.CellDetectFun(rgb2gray(frame));
%          toc
%          if flag
%              centroids = cat(1,cell_location.WeightedCentroid);
% %              [areanum,~] = size(cell_location);
%              imshow(frame);
%              hold on
%              plot(centroids(:,1),centroids(:,2),'r*')
%     %          for i = 1:areanum
%     %             plot(centroids(i,1),centroids(i,2),'r*')
%     %             rectangle('Position',cell_location(i).BoundingBox,'EdgeColor','r','LineWidth',3);
%     %          end
%              hold off
%          end
%      end
    %%%%%%%%%%%%%%%%α��ͼ%%%%%%%%%%%%%%%%
    
   
            DetectFun = MultiFunctions;
            figure(1);%1
%             frame = ycbcr2rgb(getsnapshot(obj));
            frame = getsnapshot(obj);
%          flushdata(obj);
            outimg = DetectFun.ConvertToPseudocolor(frame);
            imshow(outimg)%1
    else
            close(figure(1))
%             p = ishandle(f1)

            break;
    end
end
    
     
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
>>>>>>> c1dad3ae10e94eb80012507d1a59a09632233939
