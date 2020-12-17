function varargout = serial_communication(varargin)
%   ���ߣ�Ѧ�ܣ����ϣ�����
%   ���ܣ�ָ��䣬ͼ��ɼ�
%   �汾��2020.11.27  version 1.0
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
global numSwitch prePosition newPosition comList elementAvailable ifreceived scoms;
numSwitch = 1;     %��¼�����ʾλ�ò�������
prePosition = zeros(9,3);     %�洢�ϴ�ָ��ͺ��λ��
newPosition = zeros(9,3);     %�洢��ǰ���ĺ�δ���͵�λ��
comList = {'COM16'; 'COM13'; 'COM12'; 'COM20'};      %�洢ÿ����Ԫ��Ӧ�Ĵ��ڣ���ʼ������cell
elementAvailable = zeros(9,1);      %�洢ÿ����Ԫ��Ӧ��ť��������
ifreceived = 0;     %��¼�Ƿ���յ�����
scoms = cell(9,1);     %�洢���ڶ���
%��ȡͼƬ���ݣ�ֻ�ڵ�һ������ʱ��ȡ
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
set(handles.lamb,'BackgroundColor',closedData);

%Update available comPorts on your computer
set(handles.com, 'String', getAvailableComPort);

positionInitiate(handles);

guidata(hObject, handles);

function flag = comPortOn(index, handles)
% �򿪴���
% index ��������
% strCOM ������
global comList scoms;
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
% ���Դ򿪴���
try
    fopen(scom0);  %�򿪴���
    flag = 1;
    disp([comList{index},'�򿪳ɹ�!',newline])
catch   % �����ڴ�ʧ�ܣ���ʾ�����ڲ��ɻ�ã���
    msgbox('���ڲ��ɻ�ã�','Error','error');
    flag = 0;
    %set(hObject, 'value', 0);  %���𱾰�ť 
    return;
end

function comPortOff()
% �ر����д���
% ֹͣ��ɾ�����ڶ���
scoms = instrfind; %��������Ч�Ĵ��ж˿ڶ����� out ������ʽ����
stopasync(scoms); %ֹͣ�첽��д����
fclose(scoms);
delete(scoms);

%{
function comPortOnOrOff(strCOM, flag, handles)
% �򿪻�رմ���
% strCOM ������
% flag 0 �رգ�1 ��
if flag == 1
    baud_rate = 38400;    %������ 38400
    jiaoyan = 'none';     %У��λ ��
    data_bits = 8;         %����λ 8λ
    stop_bits = 1;         %��ֹλ 1λ
    scom0 = serial(strCOM);    %�������ڶ���, 'timerfcn', {@dataDisp, handles}
    % ���ô������ԣ�ָ����ص�����
    set(scom0, 'BaudRate', baud_rate, 'Parity', jiaoyan, 'DataBits',...
        data_bits, 'StopBits', stop_bits, 'BytesAvailableFcnCount', 10,...
        'BytesAvailableFcnMode', 'byte', 'BytesAvailableFcn', {@bytes, handles},...
        'TimerPeriod', 0.05, 'timerfcn', {@getMessageFromComPort, handles});
    %BytesAvailableFcnMode �����ж���Ӧģʽ���С�byte���͡�Terminator������ģʽ��ѡ����byte���Ǵﵽһ���ֽ��������жϣ���Terminator������������ĳ�������¼��������жϣ�
    % �����ڶ���ľ����Ϊ�û����ݣ����봰�ڶ���
    set(handles.figure1, 'UserData', scom0);
    % ���Դ򿪴���
    try
        fopen(scom0);  %�򿪴���
    catch   % �����ڴ�ʧ�ܣ���ʾ�����ڲ��ɻ�ã���
        msgbox('���ڲ��ɻ�ã�','Error','error');
        %set(hObject, 'value', 0);  %���𱾰�ť 
        return;
    end
    
else %�رմ���
    % ֹͣ��ɾ�����ڶ���
    scoms = instrfind; %��������Ч�Ĵ��ж˿ڶ����� out ������ʽ����
    stopasync(scoms); %ֹͣ�첽��д����
    fclose(scoms);
    delete(scoms);
end
%}

function sendCommand(index, strCMD, handles)
% ���ض����ڷ�������
% index �ؼ���������
% strCMD ������������
vv =10;
dd =13;
global scoms;
com = scoms{index};
%com = get(handles.figure1, 'UserData');      %��ȡ���ڶ�����
numSend = getappdata(handles.figure1, 'numSend');
val = strCMD;
numSend = numSend + length(val);
set(handles.trans, 'string', num2str(numSend));
setappdata(handles.figure1, 'numSend', numSend);
EnterSend_flag = 1;
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
%% ��ȡ����
global ifreceived;
hasData = getappdata(handles.figure1, 'hasData'); %�����Ƿ��յ�����
strRec = getappdata(handles.figure1, 'strRec');   %�������ݵ��ַ�����ʽ����ʱ��ʾ������
numRec = getappdata(handles.figure1, 'numRec');   %���ڽ��յ������ݸ���
%% ������û�н��յ����ݣ��ȳ��Խ��մ�������
if ~hasData
    bytes(obj, event, handles);
end
%% �����������ݣ����ش�������
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
    ifreceived = 1;
    %Msg = strRec;    %��ȡ���յ�����Ϣ
    %��ս�����
    %strRec = '';
    %setappdata(handles.figure1, 'strRec', strRec);
end

function response = sendAndGetResponse(index, strCMD, handles)
% ����һ���������һ��������Ϣ ����ǰ���ȴ���Ӧ����
% index �ؼ���������
% strCMD ����ָ��
% handles gui���
global ifreceived;
response = '';
%comPortOnOrOff(strCOM, 1, handles);    % �򿪴���
sendCommand(index, strCMD, handles);    %P ��ȡ��ǰλ��
%�ȴ���������
while (1)
    if (ifreceived == 1)
        response = getappdata(handles.figure1, 'strRec');    %��ȡ������Ϣ
        ifreceived = 0;
        setappdata(handles.figure1, 'strRec', '');
        break;
    end
end
length(response)
%��Ϣ���룬�ִ�
%comPortOnOrOff(strCOM, 0, handles);    % �رմ���

%{
function commandPDecodeByIndex(index, strPosition)
% �������������ض���ʽ���µ������ص�Ԫ��λ�ã���ʽΪ��x y z
% index ����Ԫ�����
% strPosition λ���ַ���
% strPositionFormate λ�������ʽ
global prePosition newPosition;
%�ж����һ���ַ��Ƿ�Ϊ���з�
if (strPosition(length(strPosition))) == newline
    strPosition = strPosition(1:(length(strPosition)-1));
end
%�ַ����ָ�
strNums = split(strPosition,' ');
if (length(strNums) ~= 3)
    disp(['�������ݸ�ʽ��ƥ�䣡',newline]);
    return;
end
prePosition(index, 1) = str2num(strNums{1});
prePosition(index, 2) = str2num(strNums{2});
prePosition(index, 3) = str2num(strNums{3});
newPosition(index, 1) = str2num(strNums{1});
newPosition(index, 2) = str2num(strNums{2});
newPosition(index, 3) = str2num(strNums{3});
%}

function getCurrentPosition(index, handles)
% ��ȡ�ؼ���ǰλ��
% index �ؼ�����
% handles guiȫ�־��
global prePosition newPosition elementAvailable;
if (index < 1 || index > 9)
    disp(['������������',newline]);
    return;
end
if (elementAvailable(index) == 1)
    %com = scoms{index};
    msg = sendAndGetResponse(index, 'P', handles);
    
    %�ж����һ���ַ��Ƿ�Ϊ���з�
    if (msg(length(msg))) == char(13)
        msg = msg(1:(length(msg)-2));
    end
    %�ַ����ָ�
    strNums = split(msg,char(9));
    if (length(strNums) ~= 3)
        disp(['�������ݸ�ʽ��ƥ�䣡',newline]);
        
        return;
    end
    prePosition(index, 1) = str2num(strNums{1});
    prePosition(index, 2) = str2num(strNums{2});
    prePosition(index, 3) = str2num(strNums{3});
    newPosition(index, 1) = str2num(strNums{1});
    newPosition(index, 2) = str2num(strNums{2});
    newPosition(index, 3) = str2num(strNums{3});
end

function commandZEROReaction(handles)
% ����ǰλ����Ϊԭ�㣨0,0,0��
global numSwitch prePosition newPosition;
%com = scoms{numSwitch};
msg = sendAndGetResponse(numSwitch, 'ZERO', handles);

%�ж����һ���ַ��Ƿ�Ϊ���з�
if (msg(length(msg))) == char(13)
    msg = msg(1:(length(msg)-1));
end

switch(msg)
    case 'E'
        disp(['����ʧ�ܣ�',newline]);
    case 'A'
        disp(['���óɹ���',newline]);
        prePosition(numSwith,:) = [0,0,0];
        newPosition(numSwith,:) = [0,0,0];
        refreshGuiPosition(handles);
    otherwise
        disp(['�����쳣��',newline]);
        msg
end

function refreshGuiPosition(handles)
% ˢ�µ�ǰ��ʾ������
global numSwitch newPosition;
set(handles.xPosition_edit, 'string', newPosition(numSwitch,1));
set(handles.yPosition_edit, 'string', newPosition(numSwitch,2));
set(handles.zPosition_edit, 'string', newPosition(numSwitch,3));

function commandMoveReaction(index, cmdType, x, y, z, handles)
% �ƶ������������λ��
% index �ؼ�����
% cmdType �ƶ���ʽ��ABS ���������ƶ���REL ��������ƶ�
% x y z ����
global prePosition newPosition elementAvailable;

if strcmp(cmdType,'ABS') && strcmp(cmdType,'REL')
    disp(['�ƶ���ʽ�������',newline]);
    return;
end
% �������
if strcmp(cmdType,'ABS')
    cmd = ['ABS ',num2str(x),' ',num2str(y),' ',num2str(z)];
else
    cmd = ['REL ',num2str(x - newPosition(index,1)),' ',num2str(y - newPosition(index,2)),' ',num2str(z - newPosition(index,3))];
end

%�ж������Ƿ�Ϸ�
if (index < 1 || index > 9)
    disp(['������������',newline]);
    return;
end
if (elementAvailable(index) == 1)
    %com = scoms{index};
    msg = sendAndGetResponse(index, cmd, handles);
    
    %�ж����һ���ַ��Ƿ�Ϊ���з�
    if (msg(length(msg))) == char(13)
        msg = msg(1:(length(msg)-1));
    end
    

    switch(msg)
        case 'E'
            disp(['����ʧ�ܣ�',newline]);
        case 'A'
            disp(['���óɹ���',newline]);
            prePosition(index,:) = [x,y,z];
            newPosition(index,:) = [x,y,z];
        otherwise
            disp(['�����쳣��',newline]);
            msg
    end
end

function goTo(index,handles)
% goto��ť����ʵ��
% index �ؼ�����
x = str2num(get(handles.xPosition_edit, 'string'));
y = str2num(get(handles.yPosition_edit, 'string'));
z = str2num(get(handles.zPosition_edit, 'string'));
%commandMoveReaction(index, 'ABS', x, y, z, handles);     %�����ƶ�
commandMoveReaction(index, 'REL', x, y, z, handles);     %����ƶ�

%{
function commandABSReaction(index, x, y, z)
% ���������ƶ����ƶ������������λ��
% index �ؼ�����
% x y z ����
global prePosition newPosition elementAvailable scoms;
% �������
cmd = ['ABS ',num2str(x),' ',num2str(y),' ',num2str(z)];
%�ж������Ƿ�Ϸ�
if (index < 1 || index > 9)
    disp('������������/n');
    return;
end
if (elementAvailable(index) == 1)
    com = scoms{index};
    msg = sendAndGetResponse(com, cmd, handles);
    
    %�ж����һ���ַ��Ƿ�Ϊ���з�
    if (msg(length(msg))) == newline
        msg = msg(1:(length(msg)-1));
    end
    
    switch(msg)
        case 'E'
            disp('����ʧ�ܣ�/n');
        case 'A'
            disp('���óɹ���/n');
            prePosition(numSwith,:) = [x,y,z];
            newPosition(numSwith,:) = [x,y,z];
            refreshGuiPosition(handles);
        otherwise
            disp('�����쳣/n');
            msg
    end
end

function commandRELReaction(index, x, y, z)
% ��������ƶ����ƶ������������λ��
% index �ؼ�����
% x y z ����
global prePosition newPosition elementAvailable scoms;
% �������
cmd = ['REL ',num2str(x - newPosition(index,1)),' ',num2str(y - newPosition(index,2)),' ',num2str(z - newPosition(index,3))];
%�ж������Ƿ�Ϸ�
if (index < 1 || index > 9)
    disp('������������/n');
    return;
end
if (elementAvailable(index) == 1)
    com = scoms{index};
    msg = sendAndGetResponse(com, cmd, handles);
    
    %�ж����һ���ַ��Ƿ�Ϊ���з�
    if (msg(length(msg))) == newline
        msg = msg(1:(length(msg)-1));
    end
    
    switch(msg)
        case 'E'
            disp('����ʧ�ܣ�/n');
        case 'A'
            disp('���óɹ���/n');
            prePosition(numSwith,:) = [x,y,z];
            newPosition(numSwith,:) = [x,y,z];
            refreshGuiPosition(handles);
        otherwise
            disp('�����쳣/n');
            msg
    end
end
%}

function msg = removeEndEnterChar(str)
% �Ƴ��ַ���ĩβ�Ļس�
%�ж����һ���ַ��Ƿ�Ϊ���з�
if (str(length(str))) == char(13)
	msg = str(1:(length(str)-1));
end

function commandSTOPReaction(handles)
% ֹͣ���пؼ����κ��ƶ�
global numSwitch elementAvailable;
flag = [];
i = numSwitch;
%for i = 1:9
    if elementAvailable(i) == 1
        %com = scoms{i};
        msg = sendAndGetResponse(i, 'STOP', handles);
        
        %�ж����һ���ַ��Ƿ�Ϊ���з�
        if (msg(length(msg))) == char(13)
            msg = msg(1:(length(msg)-1));
        end
        
        if (msg ~= 'A')
            flag(i) = 0;
            disp(['ֹͣʧ�ܣ�',newline])
        else
            flag(i) = 1;
            getCurrentPosition(i, handles);     %��ȡ��λ��
        end
    end
%end
flag
% ��ֹͣ�ɹ����µ�ǰ�ؼ�λ����ʾ
if (flag(i) == 1)
    refreshGuiPosition(handles);
end


function positionInitiate(handles)
% �Ӹ��ɿ�Ԫ����ȡ��ʼλ��
global comList elementAvailable;
availableCom = getAvailableComPort;     %��ȡ��Ч�����б�
%��֤Ŀ�괮���Ƿ����
for i = 1:size(comList, 1)
    for j = 1:size(availableCom, 1)
        if strcmp(comList{i},availableCom{j})
            elementAvailable(i) = 1;
        end
    end
end
setButtonEnableOfElement(elementAvailable,handles);     %���ð�ť����


%msg = sendAndGetResponse(1, 'P', handles);     %��ȡ�ؼ�λ��
%comPortOff();
%�����д���
for i = 1:9
    if elementAvailable(i) == 1
        flag = comPortOn(i, handles);	% �򿪴���com1
        if flag == 0
            elementAvailable(i) = 0;
        else
            getCurrentPosition(i, handles);     %��ȡ�ؼ�λ��
        end
    end
end



refreshGuiPosition(handles);     %ˢ����ʾ
%{
for i = 1:9
    if elementAvailable(i) == 1
        str1 = comList{i};    %��������ֵΪcom1
        msg = sendAndGetResponse(str1, 'P', handles);     %��ȡ�ؼ�λ��
        %���¿ؼ�����
    end
end
%}



function setButtonEnableOfElement(a,handles)
% ���ձ�ʶ��������ѡ���ť�Ƿ����
% a ��ʶ����
% 0 off; 1 on
if a(1) == 0
    set(handles.microscope_pushbutton, 'ForegroundColor', [0.9,0.9,0.9]);
    set(handles.microscope_pushbutton,'Enable', 'off');
else
    set(handles.microscope_pushbutton, 'ForegroundColor', 'black');
    set(handles.microscope_pushbutton,'Enable', 'on');
end
if a(2) == 0
    set(handles.injection1_pushbutton, 'ForegroundColor', [0.9,0.9,0.9]);
    set(handles.injection1_pushbutton,'Enable', 'off');
else
    set(handles.injection1_pushbutton, 'ForegroundColor', [0.6,0.6,0.6]);
    set(handles.injection1_pushbutton,'Enable', 'on');
end
if a(3) == 0
    set(handles.injection2_pushbutton, 'ForegroundColor', [0.9,0.9,0.9]);
    set(handles.injection2_pushbutton,'Enable', 'off');
else
    set(handles.injection2_pushbutton, 'ForegroundColor', [0.6,0.6,0.6]);
    set(handles.injection2_pushbutton,'Enable', 'on');
end
if a(4) == 0
    set(handles.injection3_pushbutton, 'ForegroundColor', [0.9,0.9,0.9]);
    set(handles.injection3_pushbutton,'Enable', 'off');
else
    set(handles.injection3_pushbutton, 'ForegroundColor', [0.6,0.6,0.6]);
    set(handles.injection3_pushbutton,'Enable', 'on');
end
if a(5) == 0
    set(handles.injection4_pushbutton, 'ForegroundColor', [0.9,0.9,0.9]);
    set(handles.injection4_pushbutton,'Enable', 'off');
else
    set(handles.injection4_pushbutton, 'ForegroundColor', [0.6,0.6,0.6]);
    set(handles.injection4_pushbutton, 'Enable', 'on');
end
if a(6) == 0
    set(handles.injection5_pushbutton, 'ForegroundColor', [0.9,0.9,0.9]);
    set(handles.injection5_pushbutton,'Enable', 'off');
else
    set(handles.injection5_pushbutton, 'ForegroundColor', [0.6,0.6,0.6]);
    set(handles.injection5_pushbutton,'Enable', 'on');
end
if a(7) == 0
    set(handles.injection6_pushbutton, 'ForegroundColor', [0.9,0.9,0.9]);
    set(handles.injection6_pushbutton,'Enable', 'off');
else
    set(handles.injection6_pushbutton, 'ForegroundColor', [0.6,0.6,0.6]);
    set(handles.injection6_pushbutton,'Enable', 'on');
end
if a(8) == 0
    set(handles.injection7_pushbutton, 'ForegroundColor', [0.9,0.9,0.9]);
    set(handles.injection7_pushbutton,'Enable', 'off');
else
    set(handles.injection7_pushbutton, 'ForegroundColor', [0.6,0.6,0.6]);
    set(handles.injection7_pushbutton,'Enable', 'on');
end
if a(9) == 0
    set(handles.injection8_pushbutton, 'ForegroundColor', [0.9,0.9,0.9]);
    set(handles.injection8_pushbutton,'Enable', 'off');
else
    set(handles.injection8_pushbutton, 'ForegroundColor', [0.6,0.6,0.6]);
    set(handles.injection8_pushbutton,'Enable', 'on');
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
    %positionInitiate();
    %str2num(get(handles.xPosition_edit,'string'))
    if isempty(str2num(get(handles.xPosition_edit,'string'))) || isempty(str2num(get(handles.yPosition_edit,'string'))) || isempty(str2num(get(handles.zPosition_edit,'string')))
        disp(['���������֣�',newline])
        return;
    end  
    %�����ϸ��ؼ�λ��
    newPosition(numSwitch,1) = str2num(get(handles.xPosition_edit,'string'));
    newPosition(numSwitch,2) = str2num(get(handles.yPosition_edit,'string'));
    newPosition(numSwitch,3) = str2num(get(handles.zPosition_edit,'string'));
    %���°�ť������ɫ
    flag = zeros(1,9);
    numSwitch = a;
    flag(numSwitch) = 1;
    setButtonColorOfElements(flag,handles);
    %����λ������
    set(handles.xPosition_edit,'string',newPosition(numSwitch,1));
    set(handles.yPosition_edit,'string',newPosition(numSwitch,2));
    set(handles.zPosition_edit,'string',newPosition(numSwitch,3));
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
%   �رմ���ʱ����鶨ʱ���ʹ����Ƿ��ѹر�
%   ��û�йرգ����ȹر�
%% ���Ҷ�ʱ��
t = timerfind;
%% �����ڶ�ʱ������ֹͣ���ر�
if ~isempty(t)
    stop(t);  %����ʱ��û��ֹͣ����ֹͣ��ʱ��
    delete(t);
end
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
global obj
global CameraOpenFlag;
global isCameraStopFlag;
CameraOpenFlag = getappdata(handles.figure1, 'isCameraOpened');
if ~CameraOpenFlag
    set(handles.CameraButton, 'string',"�ر�����ͷ",'ForegroundColor',[1 0 0]);
    objects = imaqfind;
    delete(objects);
    obj = videoinput('winvideo',1,'YUY2_640x480');
%     obj = videoinput('pmimaq_2019b', 1, 'PM-Cam 1376x1024'); %��ʼ��ͼ��
%     src = getselectedsource(vid);
    set(obj,'FramesPerTrigger',1);
    set(obj,'TriggerRepeat',Inf);
    usbVidRes1 = get(obj,'videoResolution');
    nBands1 = get(obj,'NumberOfBands');
    axes(handles.Image_display);
    hImage1 = imshow(zeros(usbVidRes1(2),usbVidRes1(1),nBands1));
    preview(obj,hImage1);
    start(obj);
%     imwrite(getdata(obj),'C:\Users\xue\Desktop\2.jpg');
    isCameraOpened = true;
    setappdata(handles.figure1,'isCameraOpened',isCameraOpened); 
    isCameraStopFlag = false;
else
    set(hObject, 'String', "��������ͷ",'ForegroundColor',[0 0 1]);  		%���ñ���ť�ı�
    closepreview(obj);
    delete(obj);   
    isCameraOpened = false;
    setappdata(handles.figure1,'isCameraOpened',isCameraOpened); 
    obj = [];
%     delete(gcf);
end

    


% --- Executes during object creation, after setting all properties.
function Image_display_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Image_display (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate Image_display




% --- Executes on button press in Snapshot_save.
function Snapshot_save_Callback(hObject, eventdata, handles)
% hObject    handle to Snapshot_save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global obj;
[fname,pname]=uiputfile({'*.jpg';'*.tiff';'*.png';'*.*'});
CameraOpenFlag = getappdata(handles.figure1, 'isCameraOpened');
if CameraOpenFlag
    frame = getsnapshot(obj);
    imwrite(ycbcr2rgb(frame),strcat(pname,fname));
    helpdlg(strcat('�ɹ�������',strcat(pname,fname)),'Tips');
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
       set(handles.StopCamera,"string","����",'ForegroundColor',[0 0 1]);
       stoppreview(obj);
       isCameraStopFlag = true;
    else
       set(handles.StopCamera,"string","��ͣ",'ForegroundColor',[1 0 0]);
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
        newPosition(numSwitch,1) = newPosition(numSwitch,1) - 0.01;
        set(handles.xPosition_edit,'string',newPosition(numSwitch,1));
    else
        newPosition(numSwitch,1) = newPosition(numSwitch,1) - 1;
        set(handles.xPosition_edit,'string',newPosition(numSwitch,1));
    end
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
        newPosition(numSwitch,1) = newPosition(numSwitch,1) + 0.01;
        set(handles.xPosition_edit,'string',newPosition(numSwitch,1));
    else
        newPosition(numSwitch,1) = newPosition(numSwitch,1) + 1;
        set(handles.xPosition_edit,'string',newPosition(numSwitch,1));
    end
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


% --- Executes on button press in sendCommond_pushbutton.
function sendCommond_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to sendCommond_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global numSwitch;
if get(hObject, 'value')
    %positionInitiate(handles);
    goTo(numSwitch,handles);
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
        newPosition(numSwitch,2) = newPosition(numSwitch,2) - 0.01;
        set(handles.yPosition_edit,'string',newPosition(numSwitch,2));
    else
        newPosition(numSwitch,2) = newPosition(numSwitch,2) - 1;
        set(handles.yPosition_edit,'string',newPosition(numSwitch,2));
    end
end


% --- Executes on button press in yPlus_pushbutton.
function yPlus_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to yPlus_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global numSwitch newPosition;
if get(hObject,'value')
    if get(handles.fine_checkbox,'value')
        newPosition(numSwitch,2) = newPosition(numSwitch,2) + 0.01;
        set(handles.yPosition_edit,'string',newPosition(numSwitch,2));
    else
        newPosition(numSwitch,2) = newPosition(numSwitch,2) + 1;
        set(handles.yPosition_edit,'string',newPosition(numSwitch,2));
    end
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
        newPosition(numSwitch,3) = newPosition(numSwitch,3) - 0.01;
        set(handles.zPosition_edit,'string',newPosition(numSwitch,3));
    else
        newPosition(numSwitch,3) = newPosition(numSwitch,3) - 1;
        set(handles.zPosition_edit,'string',newPosition(numSwitch,3));
    end
end


% --- Executes on button press in zPlus_pushbutton.
function zPlus_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to zPlus_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global numSwitch newPosition;
if get(hObject,'value')
    if get(handles.fine_checkbox,'value')
        newPosition(numSwitch,3) = newPosition(numSwitch,3) + 0.01;
        set(handles.zPosition_edit,'string',newPosition(numSwitch,3));
    else
        newPosition(numSwitch,3) = newPosition(numSwitch,3) + 1;
        set(handles.zPosition_edit,'string',newPosition(numSwitch,3));
    end
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
