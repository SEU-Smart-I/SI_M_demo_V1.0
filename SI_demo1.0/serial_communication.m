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
global numSwitch prePosition newPosition comList elementAvailable ifreceived scoms angleOffset axisLimits;
global absZero angleXOZ;
numSwitch = 1;     %��¼�����ʾλ�ò�������
prePosition = zeros(9,3);     %�洢�ϴ�ָ��ͺ��λ��
newPosition = zeros(9,3);     %�洢��ǰ���ĺ�δ���͵�λ��
comList = {'COM8'; 'COM22'; 'COM21'; 'COM11'};      %�洢ÿ����Ԫ��Ӧ�Ĵ��ڣ���ʼ������cell
elementAvailable = zeros(9,1);      %�洢ÿ����Ԫ��Ӧ��ť��������
ifreceived = 0;     %��¼�Ƿ���յ�����
scoms = cell(9,1);     %�洢���ڶ���
angleOffset = [0,0,0,19,19,0,0,0,0];     %�洢΢��xoyƽ����ת��
axisLimits = zeros(9,6);     %�洢���ؼ����꼫��
axisLimits(1,:) = [-2429000,0,0,2300000,-2494000,0];     %��΢��λ�Ƽ���
axisLimits(4,:) = [-2020000,0,0,1340000,-1970000,0];     %΢��3λ�Ƽ���
absZero = zeros(9,3);     %�洢�ؼ�����Զ������
angleXOZ = [0,0,0,66,0,0,0,0,0];     %�洢΢��xoz�н�
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
%define the WindowButtonDownFcn
set(gcf, 'WindowButtonDownFcn', {@ButtonDowncallback, handles});
set(gcf, 'WindowButtonMotionFcn', {@callback, handles});
positionInitiate(handles);

guidata(hObject, handles);

function saveABSZeroToConfigFile()
% ������ԭ�����걣�浽�����ļ���
global absZero;
disp('Function: saveABSZeroToConfigFile()');
disp(newline);

file = fopen('si.config','w');
str = 'absZero';
fprintf(file,"%s\n",str);
for i = 1:9
    fprintf(file,"%d %d %d\n",absZero(i,:));
end
fclose(file);

function loadABSZeroFromConfigFile()
% �������ļ��ж�ȡ����ԭ������
global absZero axisLimits;
disp('Function: loadABSZeroFromConfigFile()');
disp(newline);

file = fopen('si.config','r');
temp = fgetl(file);     %��һ��Ϊ������
if strcmp(temp, 'absZero')
    for i = 1:9
        temp = fgetl(file);
        b = sscanf(temp,"%d %d %d");     %�ڶ��п�ʼΪ��������
        absZero(i,:) = b';
        updateAxisLimits(i,absZero(i,:));     %���¸���ؼ�λ��������
    end
    disp(['����ԭ�������ȡ�ɹ���',newline]);
end
absZero
axisLimits
fclose(file);


function updateAxisLimits(index,newZero)
% ���������Ἣ��
% index �ؼ�����
% newZero �����ԭ������
global axisLimits;
newZero
axisLimits(index,1) = axisLimits(index,1) - newZero(1);
axisLimits(index,2) = axisLimits(index,2) - newZero(1);
axisLimits(index,3) = axisLimits(index,3) - newZero(2);
axisLimits(index,4) = axisLimits(index,4) - newZero(2);
axisLimits(index,5) = axisLimits(index,5) - newZero(3);
axisLimits(index,6) = axisLimits(index,6) - newZero(3);


function flag = comPortOn(index, handles)
% �򿪴���
% index ��������
% strCOM ������
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

function sendCommand(index, strCMD, handles)
% ���ض����ڷ�������
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
set(handles.trans, 'string', num2str(numSend));
setappdata(handles.figure1, 'numSend', numSend);
EnterSend_flag = 1;     %DIC��΢��Э����ĩβ�������ӻس��ַ�
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
global ifreceived;
hasData = getappdata(handles.figure1, 'hasData'); %�����Ƿ��յ�����
strRec = getappdata(handles.figure1, 'strRec');   %�������ݵ��ַ�����ʽ����ʱ��ʾ������
numRec = getappdata(handles.figure1, 'numRec');   %���ڽ��յ������ݸ���

    % ������û�н��յ����ݣ��ȳ��Խ��մ�������
    if ~hasData || ifreceived == 0
        bytes(obj, event, handles);
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
        set(handles.rec,'string', numRec);
        % ����hasData��־���������������Ѿ���ʾ
        setappdata(handles.figure1, 'hasData', false);
        % ��������ʾģ�����
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
disp('Function: sendAndGetResponse()');
disp(newline);

response = '';
sendCommand(index, strCMD, handles);    %P ��ȡ��ǰλ��
%�ȴ���������
tic
while (1)

    if (ifreceived == 1)
        response = getappdata(handles.figure1, 'strRec');    %��ȡ������Ϣ
        ifreceived = 0;
        setappdata(handles.figure1, 'strRec', '');
        break;
    elseif (toc > 2)
        % ����2����Ϊ��ȡʧ�ܣ��򷵻ؿ��ַ���
        break;
    end
end
response
length(response)
%��Ϣ���룬�ִ�
%comPortOnOrOff(strCOM, 0, handles);    % �رմ���

function strNums = getCurrentPosition(index, handles)
% ��ȡ�ؼ���ǰλ��
% index �ؼ�����
% handles guiȫ�־��
global elementAvailable;
disp('Function: getCurrentPosition()');
disp(newline);

if (index < 1 || index > 9)
    disp(['������������',newline]);
    return;
end
if (elementAvailable(index) == 1)
    %com = scoms{index};
    msg = sendAndGetResponse(index, 'P', handles);
    msg = removeEndEnterChar(msg);		% �Ƴ��ַ���ĩβ�Ļس�
    if isempty(msg)
        disp(['���ڷ����쳣',newline]);
        return;
    end
    %�ַ����ָ�
    strNums = split(msg,char(9));
    if (length(strNums) ~= 3)
        disp(['�������ݸ�ʽ��ƥ�䣡',newline]);
        strNums
        return;
    end
end

function setNewPosition(index,strNums)
% �����������ݸ�������
global prePosition newPosition;
disp(['Function: setNewPosition()',newline]);
strNums
prePosition(index, 1) = str2num(strNums{1});
prePosition(index, 2) = str2num(strNums{2});
prePosition(index, 3) = str2num(strNums{3});
newPosition(index, 1) = str2num(strNums{1});
newPosition(index, 2) = str2num(strNums{2});
newPosition(index, 3) = str2num(strNums{3});

function commandZEROReaction(handles)
% ����ǰλ����Ϊԭ�㣨0,0,0��
global numSwitch prePosition newPosition absZero;
disp('Function: commandZEROReaction()');

%goto����
%�жϵ�ǰλ���Ƿ�Ϊ��ʾ����λ��
pDisplay = zeros(1,3);
pDisplay(1) = str2num(get(handles.xPosition_edit,'String'))*100;
pDisplay(2) = str2num(get(handles.yPosition_edit,'String'))*100;
pDisplay(3) = str2num(get(handles.zPosition_edit,'String'))*100;
if pDisplay ~= prePosition(numSwitch,:)
    %��ǰ�ؼ��ƶ�
    goTo(numSwitch,pDisplay,handles);
end

absZero(numSwitch,:) = absZero(numSwitch,:) + newPosition(numSwitch,:);     %���¾���ԭ������
saveABSZeroToConfigFile();
updateAxisLimits(numSwitch,newPosition(numSwitch,:));     %�������꼫��
msg = sendAndGetResponse(numSwitch, 'ZERO', handles);
% absZero
% axisLimits axisLimits

%�ж����һ���ַ��Ƿ�Ϊ���з�
if (msg(length(msg))) == char(13)
    msg = msg(1:(length(msg)-1));
end
if isempty(msg)
	disp(['���ڷ����쳣',newline]);
	return;
end
switch(msg)
    case 'E'
        disp(['����ʧ�ܣ�',newline]);
    case 'A'
        disp(['���óɹ���',newline]);
        prePosition(numSwitch,:) = [0,0,0];
        newPosition(numSwitch,:) = [0,0,0];
        refreshGuiPosition(handles);
    otherwise
        disp(['�����쳣��',newline]);
        msg
end

function refreshGuiPosition(handles)
% ˢ�µ�ǰ��ʾ������
global numSwitch newPosition;
set(handles.xPosition_edit, 'string', newPosition(numSwitch,1)/100);
set(handles.yPosition_edit, 'string', newPosition(numSwitch,2)/100);
set(handles.zPosition_edit, 'string', newPosition(numSwitch,3)/100);

function commandMoveReaction(index, cmdType, x, y, z, handles)
% �ƶ������������λ��
% index �ؼ�����
% cmdType �ƶ���ʽ��ABS ���������ƶ���REL ��������ƶ�Ŀ���������룻RELD ��������ƶ����λ��������
% x y z ������������
global prePosition newPosition elementAvailable;

%�ж������Ƿ�Ϸ�
if (index < 1 || index > 9)
    disp(['������������',newline]);
    return;
end
%�ж��ƶ���ʽ�Ƿ�Ϸ�
if strcmp(cmdType,'ABS') && strcmp(cmdType,'REL') && strcmp(cmdType,'RELD')
    disp(['�ƶ���ʽ�������',newline]);
    return;
end
% �������
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
% �����ڿ�������ָ��
if (elementAvailable(index) == 1)
    %com = scoms{index};
    msg = sendAndGetResponse(index, cmd, handles);
    
    %�ж����һ���ַ��Ƿ�Ϊ���з�
    if (msg(length(msg))) == char(13)
        msg = msg(1:(length(msg)-1));
    end
    if isempty(msg)
        disp(['���ڷ����쳣',newline]);
        return;
    end

    switch(msg)
        case 'E'
            disp(['����ʧ�ܣ�',newline]);
            msg
        case 'A'
            disp(['���óɹ���',newline]);
            %��������洢
            prePosition(index,:) = [x,y,z];
            newPosition(index,:) = [x,y,z];
        otherwise
            disp(['�����쳣��',newline]);
            msg
    end
else
    disp(['Ŀ�괮�ڲ����ã�',newline]);
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
% goto��ť����ʵ�֣����ж��Ƿ�����ƶ����ٽ����ƶ���������Χ���ƶ�������λ��
% index �ؼ�����
% newP ���ƶ�λ������ x y z
% global axisLimits;
x = newP(1);
x = xCheckLimit(index,x,handles);
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
y = yCheckLimit(index,y,handles);
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
z = zCheckLimit(index,z,handles);
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
%�ж����һ���ַ��Ƿ�Ϊ���з�
if (str(length(str))) == char(13)
	msg = str(1:(length(str)-1));
else
    msg = str;
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
            disp(['���ڷ����쳣',newline]);
            return;
        end
        if (msg ~= 'A')
            flag(i) = 0;
            disp(['ֹͣʧ�ܣ�',newline])
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
        disp(['���ڷ����쳣',newline]);
        return;
    end

    num = str2num(msg);
    %��֤�����Ƿ���Ч
    if isempty(num) || num < 0 || num > 63
        disp(['�������ݴ���',newline]);
        num
        return;
    end
    %���ֽ���
    xlimit = bitand(binNum,3);
    ylimit = bitshift(xlimitbitand(binNum,12),-2);
    zlimit = bitshift(xlimitbitand(binNum,48),-4);
    %gui��Ӧ
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
% ��⵱ǰ�ؼ��Ƿ��ƶ� �ƶ��򷵻�1��ֹͣ�򷵻�0;�쳣����-1
% handles guiȫ�־��

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
%�°�ָ��
msg = sendAndGetResponse(index, 'S', handles);     %��ȡ�˶�״̬
msg = removeEndEnterChar(msg);		% �Ƴ��ַ���ĩβ�Ļس�
if isempty(msg)
	disp(['���ڷ����쳣',newline]);
	return;
end
switch (msg)
    case '0'
        isMoving = 0;
    case '1'
        isMoving = 1;
    otherwise
        disp(['���������쳣',newline]);
        msg
        isMoving = -1;
end


function obj = getObjective(handles)
% ��ȡ�ﾵ���� 0 ��ȡʧ�ܣ�1 �ͱ�����2 �߱�����������
% handles guiȫ�־��
msg = sendAndGetResponse(1, 'OBJ', handles);
msg = removeEndEnterChar(msg);     %ɾ���ַ���ĩ�Ļ��з�
if isempty(msg)
	disp(['���ڷ����쳣',newline]);
	return;
end
num = str2num(msg);
if num == 1 || num == 2
    obj = num;
else
    obj = 0;
end

function setObjective(objnum,handles)
% �л��ﾵ
% objnum 1 �ͱ�����2 �߱������ݶ���
% handles guiȫ�־��
switch(objnum)
    case 1
        'OBJ 1'
        msg = sendAndGetResponse(1, 'OBJ 1', handles);
    case 2
        'OBJ 2'
        msg = sendAndGetResponse(1, 'OBJ 2', handles);
    otherwise
        disp(['�����������',newline]);
        objnum
        return;
end
msg = removeEndEnterChar(msg);		% �Ƴ��ַ���ĩβ�Ļس�
if isempty(msg)
	disp(['���ڷ����쳣',newline]);
	return;
end
if msg == 'A'
    disp(['�ﾵ�л��ɹ�',newline]);
    if strcmp(get(handles.objswitch_pushbutton,'String'),'��4')
        set(handles.objswitch_pushbutton,'String','��40');
    else
        set(handles.objswitch_pushbutton,'String','��4');
    end
else
    disp(['�ﾵ�л�ʧ��',newline]);
end

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
global loc prePosition;
if (loc(1) == 0 && loc(2) == 0)
    disp(['Get the position first.',newline]);
    return;
end
mPosition = zeros(1,2);
mPosition(1) = prePosition(1,1) + round((loc(1,2)-512)*50/3);
mPosition(2) = prePosition(1,2) - round((loc(1,1)-688)*50/3);

function descStr = getElementDescStr(com,handles)
% get element description from USB comport
% com: comport object
% handles: GUI global handle
descStr = sendAndGetResponse(com, 'DESC', handles);
descStr = removeEndEnterChar(descStr);		% delete the ending enter char 
if isempty(descStr)
	disp(['���ڷ����쳣',newline]);
	return;
end

function positionInitiate(handles)
% �Ӹ��ɿ�Ԫ����ȡ��ʼλ��
global comList elementAvailable;
loadABSZeroFromConfigFile();
comPortOff();
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

%�����д���
for i = 1:9
    if elementAvailable(i) == 1
        flag = comPortOn(i, handles);	% �򿪴���com1
        if flag == 0
            elementAvailable(i) = 0;
        else
            pXYZ = getCurrentPosition(i, handles);     %��ȡ�ؼ�λ��
            setNewPosition(i,pXYZ);     %����ȫ�ֱ���
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
%�ؼ������ַ�����ȡ
if elementAvailable(4) == 1
    msg = sendAndGetResponse(4, 'DESC', handles);
    msg = removeEndEnterChar(msg);		% �Ƴ��ַ���ĩβ�Ļس�
    if isempty(msg)
        disp(['���ڷ����쳣',newline]);
        return;
    end
    msg1 = sendAndGetResponse(4, 'ANGLE', handles);
    msg1 = removeEndEnterChar(msg1);      % �Ƴ��ַ���ĩβ�Ļس�
    if isempty(msg1)
        disp(['���ڷ����쳣',newline]);
        return;
    end
end
%�ﾵ�л����ܳ�ʼ��
if elementAvailable(1) == 1
    % ��΢���ﾵ�л���ť��ʼ��
    disp(['��ʼ����΢���ﾵ��ť',newline]);
    obj = getObjective(handles);
    switch(obj)
        case 0
            disp(['�ﾵ��ʼ��ʧ��',newline]);
            set(handles.objswitch_pushbutton,'Enable', 'off');
        case 1
            set(handles.objswitch_pushbutton,'String', '��40');
        case 2
            set(handles.objswitch_pushbutton,'String', '��4');
    end
else
    set(handles.objswitch_pushbutton,'Enable','off');
end



function setButtonEnableOfElement(a,handles)
% ���ձ�ʶ��������ѡ���ť�Ƿ����
% a ��ʶ����
% 0 off; 1 on
if a(1) == 0
%     set(handles.microscope_pushbutton, 'ForegroundColor', [0.9,0.9,0.9]);
    set(handles.microscope_pushbutton,'Enable', 'off');
else
%     set(handles.microscope_pushbutton, 'ForegroundColor', 'black');
    set(handles.microscope_pushbutton,'Enable', 'on');
end
if a(2) == 0
%     set(handles.injection1_pushbutton, 'ForegroundColor', [0.9,0.9,0.9]);
    set(handles.injection1_pushbutton,'Enable', 'off');
else
%     set(handles.injection1_pushbutton, 'ForegroundColor', [0.6,0.6,0.6]);
    set(handles.injection1_pushbutton,'Enable', 'on');
end
if a(3) == 0
%     set(handles.injection2_pushbutton, 'ForegroundColor', [0.9,0.9,0.9]);
    set(handles.injection2_pushbutton,'Enable', 'off');
else
%     set(handles.injection2_pushbutton, 'ForegroundColor', [0.6,0.6,0.6]);
    set(handles.injection2_pushbutton,'Enable', 'on');
end
if a(4) == 0
%     set(handles.injection3_pushbutton, 'ForegroundColor', [0.9,0.9,0.9]);
    set(handles.injection3_pushbutton,'Enable', 'off');
else
%     set(handles.injection3_pushbutton, 'ForegroundColor', [0.6,0.6,0.6]);
    set(handles.injection3_pushbutton,'Enable', 'on');
end
if a(5) == 0
%     set(handles.injection4_pushbutton, 'ForegroundColor', [0.9,0.9,0.9]);
    set(handles.injection4_pushbutton,'Enable', 'off');
else
%     set(handles.injection4_pushbutton, 'ForegroundColor', [0.6,0.6,0.6]);
    set(handles.injection4_pushbutton, 'Enable', 'on');
end
if a(6) == 0
%     set(handles.injection5_pushbutton, 'ForegroundColor', [0.9,0.9,0.9]);
    set(handles.injection5_pushbutton,'Enable', 'off');
else
%     set(handles.injection5_pushbutton, 'ForegroundColor', [0.6,0.6,0.6]);
    set(handles.injection5_pushbutton,'Enable', 'on');
end
if a(7) == 0
%     set(handles.injection6_pushbutton, 'ForegroundColor', [0.9,0.9,0.9]);
    set(handles.injection6_pushbutton,'Enable', 'off');
else
%     set(handles.injection6_pushbutton, 'ForegroundColor', [0.6,0.6,0.6]);
    set(handles.injection6_pushbutton,'Enable', 'on');
end
if a(8) == 0
%     set(handles.injection7_pushbutton, 'ForegroundColor', [0.9,0.9,0.9]);
    set(handles.injection7_pushbutton,'Enable', 'off');
else
%     set(handles.injection7_pushbutton, 'ForegroundColor', [0.6,0.6,0.6]);
    set(handles.injection7_pushbutton,'Enable', 'on');
end
if a(9) == 0
%     set(handles.injection8_pushbutton, 'ForegroundColor', [0.9,0.9,0.9]);
    set(handles.injection8_pushbutton,'Enable', 'off');
else
%     set(handles.injection8_pushbutton, 'ForegroundColor', [0.6,0.6,0.6]);
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
global obj;
global CameraOpenFlag;
global isCameraStopFlag;
global tb;
CameraOpenFlag = getappdata(handles.figure1, 'isCameraOpened');
if ~CameraOpenFlag
    set(handles.CameraButton, 'string',"�ر�����ͷ",'ForegroundColor',[1 0 0]);
    objects = imaqfind;
    delete(objects);
%     obj = videoinput('winvideo',1,'YUY2_640x480');
    obj = videoinput('pmimaq_2019b', 1, 'PM-Cam 1376x1024'); %��ʼ��ͼ��
    src = getselectedsource(obj);
    set(obj,'FramesPerTrigger',1);
    set(obj,'TriggerRepeat',Inf);
    set(obj,'FrameGrabInterval',1);
    usbVidRes1 = get(obj,'videoResolution');
    nBands1 = get(obj,'NumberOfBands');
    axes(handles.Image_display);
    hImage1 = imshow(zeros(usbVidRes1(2),usbVidRes1(1),nBands1));
    preview(obj,hImage1);
    flushdata(obj);
    start(obj);
%     imwrite(getdata(obj),'C:\Users\xue\Desktop\2.jpg');
    isCameraOpened = true;
    setappdata(handles.figure1,'isCameraOpened',isCameraOpened); 
    isCameraStopFlag = false;
    tb = text;
    set(gcf,'WindowButtonMotionFcn',@callback);
    set(hImage1, 'ButtonDownFcn', {@ButtonDowncallback,handles});
else
    set(hObject, 'String', "��������ͷ",'ForegroundColor',[0 0 1]);  		%���ñ���ť�ı�
    closepreview(obj);
    delete(obj);   
    isCameraOpened = false;
    setappdata(handles.figure1,'isCameraOpened',isCameraOpened); 
    obj = [];
    tb = text;
    set(gcf,'WindowButtonMotionFcn',@callback);
    set(gcf,'WindowButtonDownFcn', {@ButtonDowncallback,handles});
%     delete(gcf);
end

    


% --- Executes during object creation, after setting all properties.
function Image_display_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Image_display (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate Image_display
global tb;
global loc;
tb = text;
set(gcf,'WindowButtonMotionFcn',@callback);
set(gcf, 'WindowButtonDownFcn', @ButtonDowncallback);


function callback(handles,hObject, event)
%     global tb
%     loc = get(gca, 'CurrentPoint');
%     loc = loc([1 3]);
%     set(tb, 'string', num2str(loc), 'position', loc);

function ButtonDowncallback(obj, event, handles)
     global tb;
     global loc;
     global isButtonDown;
     isButtonDown = true;
     loc = get(gca, 'CurrentPoint');
     loc = loc(1,(1:2))
     set(tb, 'string', num2str(loc), 'position', loc); 
%      set(handles.PositionBox,'String',loc);



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
        newPosition(numSwitch,1) = newPosition(numSwitch,1) - 1;
        set(handles.xPosition_edit,'string',newPosition(numSwitch,1)/100);
    else
        newPosition(numSwitch,1) = newPosition(numSwitch,1) - 100;
        set(handles.xPosition_edit,'string',newPosition(numSwitch,1)/100);
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
        newPosition(numSwitch,1) = newPosition(numSwitch,1) + 1;
        set(handles.xPosition_edit,'string',newPosition(numSwitch,1)/100);
    else
        newPosition(numSwitch,1) = newPosition(numSwitch,1) + 100;
        set(handles.xPosition_edit,'string',newPosition(numSwitch,1)/100);
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


% --- Executes on button press in goTo_pushbutton.
function goTo_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to goTo_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global numSwitch prePosition angleOffset;
if get(hObject, 'value')
    %�жϵ�ǰλ���Ƿ�Ϊ��ʾ����λ��
    pDisplay = zeros(1,3);
    pDisplay(1) = str2num(get(handles.xPosition_edit,'String'))*100;
    pDisplay(2) = str2num(get(handles.yPosition_edit,'String'))*100;
    pDisplay(3) = str2num(get(handles.zPosition_edit,'String'))*100;
%     numSwitch
    prePosition(numSwitch,:)
%     pDisplay
    if pDisplay(1) ~= prePosition(numSwitch,1) || pDisplay(2) ~= prePosition(numSwitch,2) || pDisplay(3) ~= prePosition(numSwitch,3)
        % ĿǰЭͬĬ��Ϊ��΢���뵥��΢�ٵ�Эͬ������ЭͬʱnumSwitch = 1
        if numSwitch == 1 && get(handles.comove_checkbox,'value')
            %��΢���ж��Ƿ���ƶ�
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
            angleOffset(4)
            
            
            theta = angleOffset(4)/180*pi;
            dP = zeros(1,3);     %�ȴ�仯��
            dP(1) = detaP(1)*cos(theta) + detaP(2)*sin(theta);
            dP(2) = -detaP(1)*sin(theta) + detaP(2)*cos(theta);
            dP(3) = detaP(3);
            %΢���ж��Ƿ���ƶ�
            tempP(1) = prePosition(4,1)+dP(1) - xCheckLimit(4,prePosition(4,1)+dP(1),handles);
            tempP(2) = prePosition(4,2)+dP(2) - yCheckLimit(4,prePosition(4,2)+dP(2),handles);
            tempP(3) = prePosition(4,3)+dP(3) - zCheckLimit(4,prePosition(4,3)+dP(3),handles);
            if tempP(1) ~= 0 || tempP(2) ~= 0 || tempP(3) ~= 0
                str = ['΢���޷��ƶ�����λ��',newline];
                disp(str);
                return;
            end
            %����Эͬ�ƶ�
            commandMoveReaction(4, 'RELD', dP(1), dP(2), dP(3), handles);     %΢������ƶ�
            
            commandMoveReaction(1, 'RELD', detaP(1), detaP(2), detaP(3), handles);     %��΢������ƶ�
            disp(['Эͬ�ƶ��ɹ�',newline]);
        else
            %��ǰ�ؼ��ƶ�
            goTo(numSwitch,pDisplay,handles);
        end
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
        newPosition(numSwitch,2) = newPosition(numSwitch,2) - 1;
        set(handles.yPosition_edit,'string',newPosition(numSwitch,2)/100);
    else
        newPosition(numSwitch,2) = newPosition(numSwitch,2) - 100;
        set(handles.yPosition_edit,'string',newPosition(numSwitch,2)/100);
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
        newPosition(numSwitch,2) = newPosition(numSwitch,2) + 1;
        set(handles.yPosition_edit,'string',newPosition(numSwitch,2)/100);
    else
        newPosition(numSwitch,2) = newPosition(numSwitch,2) + 100;
        set(handles.yPosition_edit,'string',newPosition(numSwitch,2)/100);
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
        newPosition(numSwitch,3) = newPosition(numSwitch,3) - 1;
        set(handles.zPosition_edit,'string',newPosition(numSwitch,3)/100);
    else
        newPosition(numSwitch,3) = newPosition(numSwitch,3) - 100;
        set(handles.zPosition_edit,'string',newPosition(numSwitch,3)/100);
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
        newPosition(numSwitch,3) = newPosition(numSwitch,3) + 1;
        set(handles.zPosition_edit,'string',newPosition(numSwitch,3)/100);
    else
        newPosition(numSwitch,3) = newPosition(numSwitch,3) + 100;
        set(handles.zPosition_edit,'string',newPosition(numSwitch,3)/100);
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
pos = get(hObject,'Currentpoint');


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
    disp(['��δ��ȡĿ�������',newline]);
    return;
end
% �ж������Ƿ񳬹�����,Эͬ�����
x = prePosition(numSwitch,1) + round((loc(1,2)-512)*50/3)
newX = xCheckLimit(numSwitch,x,handles)
y = prePosition(numSwitch,2) - round((loc(1,1)-688)*50/3)
newY = yCheckLimit(numSwitch,y,handles)
if newX ~= x || newY ~= y
    disp(['Ŀ��λ�ó�����΢��λ�Ƽ���',newline]);
    return;
end
% ��΢���ƶ�
commandMoveReaction(1, 'RELD', round((loc(1,2)-512)*50/3), -round((loc(1,1)-688)*50/3), 0, handles);
%�������
flag = (numSwitch == 1);
ifmoving = 1;
while(ifmoving == 1)
    pause(0.05);
    ifmoving = checkIsMoving(1,handles);	% ��⵱ǰ�ؼ��Ƿ��ƶ�
    %{
    %ֻ����prePosition
    newPosition(1,:) = prePosition(1,:);
    %}
    %���µ�ǰλ��
    pXYZ = getCurrentPosition(1, handles);     %��ȡ�ؼ�λ��
    setNewPosition(1, pXYZ);     %����ȫ�ֱ���
    if (flag)
        refreshGuiPosition(handles)		% ˢ�µ�ǰ��ʾ������
    end
end
loc = zeros(1,2);

%Эͬ�ƶ�
if get(handles.comove_checkbox,'value')
    
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


% --- Executes on button press in comove_checkbox.
function comove_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to comove_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of comove_checkbox


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


% --- Executes on button press in pushbutton31.
function pushbutton31_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton31 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global loc prePosition;
if get(hObject,'value')
    str = get(hObject,'string');
    switch(str)
        case 'Get' 
            if loc(1) == 0 && loc(2) == 0
                disp(['Get the position first.',newline]);
                return;
            end
            set(hObject,'string','Set');
            tempP = transformImagePositionToMicroscopePosition();
            text = [num2str(tempP(1)),' ',num2str(tempP(2)),' ',num2str(prePosition(1,3))];
            set(handles.text23,'string',text);
            set(handles.text23,'value',1);
            if get(handles.text25,'value') == 1
                set(handles.pushbutton33,'Enable','on');
            end
            
        case 'Set'
            set(hObject,'string','Get');
            % ��ʼ��ȡ���������
    end
end
    


% --- Executes on button press in pushbutton32.
function pushbutton32_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton32 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global loc prePosition;
if get(hObject,'value')
    str = get(hObject,'string');
    switch(str)
        case 'Get' 
            if loc(1) == 0 && loc(2) == 0
                disp(['Get the position first.',newline]);
                return;
            end
            set(hObject,'string','Set');
            tempP = transformImagePositionToMicroscopePosition();
            text = [num2str(tempP(1)),' ',num2str(tempP(2)),' ',num2str(prePosition(1,3))];
            set(handles.text25,'string',text);
            set(handles.text25,'value',1);
            if get(handles.text23,'value') == 1
                set(handles.pushbutton33,'Enable','on');
            end
            
        case 'Set'
            set(hObject,'string','Get');
            % ��ʼ��ȡ���������
    end
end


% --- Executes on button press in pushbutton33.
function pushbutton33_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton33 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global loc angleOffset angleXOZ;
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
    % get cell position
    P2 = zeros(1,3);
    tempstr0 = get(handles.text25,'string');
    str0 = split(tempstr0,' ');
    P2(1) = str2num(str0{1});
    P2(2) = str2num(str0{2});
    P2(3) = str2num(str0{3});
    P2
    str1 = get(handles.probeCalibration_pushbutton,'FontWeight');
    if strcmp(str1,'bold')
        % ����΢��3��
        % Calibration
        dx = P2(1) - P1(1)
        dy = P2(2) - P1(2)
        dz = P2(3) - P1(3)
        theta = atan(dy / dx) / pi * 180
        alpha = atan(sqrt(dx * dx + dy * dy) / dz) / pi * 180
        
    else
        % ����΢��3��
        % Initialize
        theta = angleOffset(4) / 180 * pi;
        alpha = angleXOZ(4) / 180 * pi;
        dz = P1(3) - P2(3)     % positive
        Lxoy = dz * tan(alpha)
        dx = Lxoy * cos(theta)
        dy = Lxoy * sin(theta)
        
    end
end

% str2 = get(handles.initializeInjectPoint_pushbutton,'FontWeight')

    


% --- Executes on button press in pushbutton34.
function pushbutton34_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton34 (see GCBO)
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
end


% --- Executes on button press in probeCalibration_pushbutton.
function probeCalibration_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to probeCalibration_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'value')
    set(handles.probeCalibration_uipanel,'title','Probe Calibration');
    set(handles.p1_text,'string','Point1:');
    set(handles.p2_text,'string','Point2:');
    set(handles.probeCalibration_pushbutton,'FontWeight','bold');
    set(handles.initializeInjectPoint_pushbutton,'FontWeight','normal');
    
end


% --- Executes on button press in initializeInjectPoint_pushbutton.
function initializeInjectPoint_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to initializeInjectPoint_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'value')
    set(handles.probeCalibration_uipanel,'title','Probe Inject Initialization');
    set(handles.p1_text,'string','P_probe:');
    set(handles.p2_text,'string','P_cell    :');
    set(handles.probeCalibration_pushbutton,'FontWeight','normal');
    set(handles.initializeInjectPoint_pushbutton,'FontWeight','bold');
    
end


% --- Executes on button press in pushbutton41.
function pushbutton41_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton41 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'value')
    set(handles.config_uipanel,'Visible',1);
    set(handles.probeCalibration_uipanel,'title','Probe Calibration');
    set(handles.p1_text,'string','Point1:');
    set(handles.p2_text,'string','Point2:');
    set(handles.probeCalibration_pushbutton,'FontWeight','bold');
    set(handles.pushbutton33,'Enable','off');
end
