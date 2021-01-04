function varargout = serial_communication(varargin)
%   作者：薛杰，刘迪，刘健
%   功能：指令传输，图像采集
%   版本：2020.11.27  version 1.0
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
%% 改变窗口左上角的图标为icon.jpg
javaFrame = get(hObject, 'JavaFrame');%用来修改窗口logo
javaFrame.setFigureIcon(javax.swing.ImageIcon('LOGO.png'));
%% 初始化参数
hasData = false; 	%表征串口是否接收到数据
isShow = false;  	%表征是否正在进行数据显示，即是否正在执行函数dataDisp
isStopDisp = false;  	%表征是否按下了【停止显示】按钮
isHexDisp = false;   	%表征是否勾选了【十六进制显示】
isHexSend = false;	%表征是否勾选了【十六进制发送】
numRec = 0;    	%接收字符计数
numSend = 0;   	%发送字符计数
strRec = '';   		%已接收的字符串
isCameraOpened= false; %记录是否打开了摄像头 （1126）
global numSwitch prePosition newPosition comList elementAvailable ifreceived scoms angleOffset axisLimits;
global absZero angleXOZ;
numSwitch = 1;     %记录面板显示位置参数对象
prePosition = zeros(9,3);     %存储上次指令发送后的位置
newPosition = zeros(9,3);     %存储当前更改后还未发送的位置
comList = {'COM8'; 'COM22'; 'COM21'; 'COM11'};      %存储每个单元对应的串口，初始化成了cell
elementAvailable = zeros(9,1);      %存储每个单元对应按钮可用属性
ifreceived = 0;     %记录是否接收到数据
scoms = cell(9,1);     %存储串口对象
angleOffset = [0,0,0,19,19,0,0,0,0];     %存储微操xoy平面旋转角
axisLimits = zeros(9,6);     %存储各控件坐标极限
axisLimits(1,:) = [-2429000,0,0,2300000,-2494000,0];     %显微镜位移极限
axisLimits(4,:) = [-2020000,0,0,1340000,-1970000,0];     %微操3位移极限
absZero = zeros(9,3);     %存储控件绝对远点坐标
angleXOZ = [0,0,0,66,0,0,0,0,0];     %存储微操xoz夹角
%读取图片数据，只在第一次运行时读取
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

%% 将上述参数作为应用数据，存入窗口对象内
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
%初始化串口状态指示灯，串口灯默认为关闭状态
% set(handles.lamb, 'cdata', closedData); %通过cdata来改变按钮的图标
set(handles.lamb,'BackgroundColor',closedData);

%Update available comPorts on your computer
set(handles.com, 'String', getAvailableComPort);
%define the WindowButtonDownFcn
set(gcf, 'WindowButtonDownFcn', {@ButtonDowncallback, handles});
set(gcf, 'WindowButtonMotionFcn', {@callback, handles});
positionInitiate(handles);

guidata(hObject, handles);

function saveABSZeroToConfigFile()
% 将绝对原点坐标保存到设置文件中
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
% 从设置文件中读取绝对原点坐标
global absZero axisLimits;
disp('Function: loadABSZeroFromConfigFile()');
disp(newline);

file = fopen('si.config','r');
temp = fgetl(file);     %第一行为数据名
if strcmp(temp, 'absZero')
    for i = 1:9
        temp = fgetl(file);
        b = sscanf(temp,"%d %d %d");     %第二行开始为数据内容
        absZero(i,:) = b';
        updateAxisLimits(i,absZero(i,:));     %更新各轴控件位置上下限
    end
    disp(['绝对原点坐标读取成功！',newline]);
end
absZero
axisLimits
fclose(file);


function updateAxisLimits(index,newZero)
% 更新坐标轴极限
% index 控件索引
% newZero 新相对原点坐标
global axisLimits;
newZero
axisLimits(index,1) = axisLimits(index,1) - newZero(1);
axisLimits(index,2) = axisLimits(index,2) - newZero(1);
axisLimits(index,3) = axisLimits(index,3) - newZero(2);
axisLimits(index,4) = axisLimits(index,4) - newZero(2);
axisLimits(index,5) = axisLimits(index,5) - newZero(3);
axisLimits(index,6) = axisLimits(index,6) - newZero(3);


function flag = comPortOn(index, handles)
% 打开串口
% index 串口索引
% strCOM 串口名
global comList scoms;
disp('Function: comPortOn()');
disp(newline);
baud_rate = 38400;    %波特率 38400
jiaoyan = 'none';     %校验位 无
data_bits = 8;         %数据位 8位
stop_bits = 1;         %终止位 1位
scom0 = serial(comList{index});    %创建串口对象, 'timerfcn', {@dataDisp, handles}
% 配置串口属性，指定其回调函数
set(scom0, 'BaudRate', baud_rate, 'Parity', jiaoyan, 'DataBits',...
    data_bits, 'StopBits', stop_bits, 'BytesAvailableFcnCount', 10,...
    'BytesAvailableFcnMode', 'byte', 'BytesAvailableFcn', {@bytes, handles},...
    'TimerPeriod', 0.05, 'timerfcn', {@getMessageFromComPort, handles});
%BytesAvailableFcnMode 设置中断响应模式（有“byte”和“Terminator”两种模式可选，“byte”是达到一定字节数产生中断，“Terminator”可用作键盘某个按键事件来产生中断）
% 将串口对象的句柄作为用户数据，存入窗口对象
scoms{index} = scom0;
% 尝试打开串口
try
    fopen(scom0);  %打开串口
    flag = 1;
    disp([comList{index},'打开成功!',newline])
catch   % 若串口打开失败，提示“串口不可获得！”
    msgbox('串口不可获得！','Error','error');
    flag = 0;
    %set(hObject, 'value', 0);  %弹起本按钮 
    return;
end

function comPortOff()
% 关闭所有串口
% 停止并删除串口对象
scoms = instrfind; %将所有有效的串行端口对象以 out 数组形式返回
stopasync(scoms); %停止异步读写操作
fclose(scoms);
delete(scoms);

function sendCommand(index, strCMD, handles)
% 向特定串口发送命令
% index 控件串口索引
% strCMD 发送命令内容
disp('Function: sendCommand()');
disp(newline);

vv =10;
dd =13;
global scoms;
com = scoms{index};
%com = get(handles.figure1, 'UserData');      %获取串口对象句柄
numSend = getappdata(handles.figure1, 'numSend');
val = strCMD;
numSend = numSend + length(val);
set(handles.trans, 'string', num2str(numSend));
setappdata(handles.figure1, 'numSend', numSend);
EnterSend_flag = 1;     %DIC显微镜协议中末尾必须增加回车字符
I_flag=0;
if ~isempty(val)
    %% 设置倒计数的初值
    n = 1000;
    while n
        %% 获取串口的传输状态，若串口没有正在写数据，写入数据
        str = get(com, 'TransferStatus');
        if ~(strcmp(str, 'write') || strcmp(str, 'read&write')) 
            if ~I_flag
             fwrite(com, val, 'uint8', 'async'); %数据写入串口
                I_flag=1;
            end
        end
        if EnterSend_flag
            str = get(com, 'TransferStatus');
            if ~(strcmp(str, 'write') || strcmp(str, 'read&write'))
                 fwrite(com, vv); %数据写入串口
                 fwrite(com, dd); %数据写入串口
                 break;
            end
        end 
        n = n - 1; %倒计数
    end
end

function getMessageFromComPort(obj, event, handles)
% 从串口获取数据
% 获取参数
global ifreceived;
hasData = getappdata(handles.figure1, 'hasData'); %串口是否收到数据
strRec = getappdata(handles.figure1, 'strRec');   %串口数据的字符串形式，定时显示该数据
numRec = getappdata(handles.figure1, 'numRec');   %串口接收到的数据个数

    % 若串口没有接收到数据，先尝试接收串口数据
    if ~hasData || ifreceived == 0
        bytes(obj, event, handles);
    end
    % 若串口有数据，返回串口数据
    if hasData && (strRec(length(strRec)) == char(13))
        % 给数据显示模块加互斥锁
        % 在执行显示数据模块时，不接受串口数据，即不执行BytesAvailableFcn回调函数
        setappdata(handles.figure1, 'isShow', true); 
        % 若要显示的字符串长度超过10000，清空显示区
        if length(strRec) > 10000
            strRec = '';
            setappdata(handles.figure1, 'strRec', strRec);
        end
        % 显示数据
        set(handles.xianshi, 'string', strRec);
        % 更新接收计数
        set(handles.rec,'string', numRec);
        % 更新hasData标志，表明串口数据已经显示
        setappdata(handles.figure1, 'hasData', false);
        % 给数据显示模块解锁
        setappdata(handles.figure1, 'isShow', false);
        
        ifreceived = 1;
        %Msg = strRec;    %获取接收到的消息
        %清空接收区
        %strRec = '';
        %setappdata(handles.figure1, 'strRec', strRec);
    end


function response = sendAndGetResponse(index, strCMD, handles)
% 发送一条命令并接受一条返回消息 调用前需先打开相应串口
% index 控件串口索引
% strCMD 操作指令
% handles gui句柄
global ifreceived;
disp('Function: sendAndGetResponse()');
disp(newline);

response = '';
sendCommand(index, strCMD, handles);    %P 获取当前位置
%等待接收数据
tic
while (1)

    if (ifreceived == 1)
        response = getappdata(handles.figure1, 'strRec');    %获取串口消息
        ifreceived = 0;
        setappdata(handles.figure1, 'strRec', '');
        break;
    elseif (toc > 2)
        % 超过2秒认为获取失败，则返回空字符串
        break;
    end
end
response
length(response)
%消息解码，分存
%comPortOnOrOff(strCOM, 0, handles);    % 关闭串口

function strNums = getCurrentPosition(index, handles)
% 获取控件当前位置
% index 控件索引
% handles gui全局句柄
global elementAvailable;
disp('Function: getCurrentPosition()');
disp(newline);

if (index < 1 || index > 9)
    disp(['输入索引错误！',newline]);
    return;
end
if (elementAvailable(index) == 1)
    %com = scoms{index};
    msg = sendAndGetResponse(index, 'P', handles);
    msg = removeEndEnterChar(msg);		% 移除字符串末尾的回车
    if isempty(msg)
        disp(['串口返回异常',newline]);
        return;
    end
    %字符串分割
    strNums = split(msg,char(9));
    if (length(strNums) ~= 3)
        disp(['返回数据格式不匹配！',newline]);
        strNums
        return;
    end
end

function setNewPosition(index,strNums)
% 按照数组数据更新坐标
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
% 将当前位置设为原点（0,0,0）
global numSwitch prePosition newPosition absZero;
disp('Function: commandZEROReaction()');

%goto操作
%判断当前位置是否为显示框中位置
pDisplay = zeros(1,3);
pDisplay(1) = str2num(get(handles.xPosition_edit,'String'))*100;
pDisplay(2) = str2num(get(handles.yPosition_edit,'String'))*100;
pDisplay(3) = str2num(get(handles.zPosition_edit,'String'))*100;
if pDisplay ~= prePosition(numSwitch,:)
    %当前控件移动
    goTo(numSwitch,pDisplay,handles);
end

absZero(numSwitch,:) = absZero(numSwitch,:) + newPosition(numSwitch,:);     %更新绝对原点坐标
saveABSZeroToConfigFile();
updateAxisLimits(numSwitch,newPosition(numSwitch,:));     %更新坐标极限
msg = sendAndGetResponse(numSwitch, 'ZERO', handles);
% absZero
% axisLimits axisLimits

%判断最后一个字符是否为换行符
if (msg(length(msg))) == char(13)
    msg = msg(1:(length(msg)-1));
end
if isempty(msg)
	disp(['串口返回异常',newline]);
	return;
end
switch(msg)
    case 'E'
        disp(['设置失败！',newline]);
    case 'A'
        disp(['设置成功！',newline]);
        prePosition(numSwitch,:) = [0,0,0];
        newPosition(numSwitch,:) = [0,0,0];
        refreshGuiPosition(handles);
    otherwise
        disp(['返回异常！',newline]);
        msg
end

function refreshGuiPosition(handles)
% 刷新当前显示的坐标
global numSwitch newPosition;
set(handles.xPosition_edit, 'string', newPosition(numSwitch,1)/100);
set(handles.yPosition_edit, 'string', newPosition(numSwitch,2)/100);
set(handles.zPosition_edit, 'string', newPosition(numSwitch,3)/100);

function commandMoveReaction(index, cmdType, x, y, z, handles)
% 移动到输入的坐标位置
% index 控件索引
% cmdType 移动方式：ABS 绝对坐标移动；REL 相对坐标移动目标坐标输入；RELD 相对坐标移动相对位移量输入
% x y z 坐标或相对坐标
global prePosition newPosition elementAvailable;

%判断索引是否合法
if (index < 1 || index > 9)
    disp(['输入索引错误！',newline]);
    return;
end
%判断移动方式是否合法
if strcmp(cmdType,'ABS') && strcmp(cmdType,'REL') && strcmp(cmdType,'RELD')
    disp(['移动方式输入错误！',newline]);
    return;
end
% 生成命令串
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
% 若串口可用则发送指令
if (elementAvailable(index) == 1)
    %com = scoms{index};
    msg = sendAndGetResponse(index, cmd, handles);
    
    %判断最后一个字符是否为换行符
    if (msg(length(msg))) == char(13)
        msg = msg(1:(length(msg)-1));
    end
    if isempty(msg)
        disp(['串口返回异常',newline]);
        return;
    end

    switch(msg)
        case 'E'
            disp(['设置失败！',newline]);
            msg
        case 'A'
            disp(['设置成功！',newline]);
            %更新坐标存储
            prePosition(index,:) = [x,y,z];
            newPosition(index,:) = [x,y,z];
        otherwise
            disp(['返回异常！',newline]);
            msg
    end
else
    disp(['目标串口不可用！',newline]);
end

function newNum = xCheckLimit(index,num,handles)
% x坐标极限检测
% index 控件索引
% num 输入坐标
% handles gui全局句柄
global numSwitch axisLimits;
if num < axisLimits(index,1)
    num = axisLimits(index,1);     %限制移动
    if index == numSwitch
        set(handles.xPosition_edit,'string',num/100);     %更新显示坐标
        limitsGuiReaction(1,handles.xMinus_pushbutton,handles.xPlus_pushbutton);     %更新gui控件标识
    end
elseif num > axisLimits(index,2)
    num = axisLimits(index,2);     %限制移动
    if index == numSwitch
        set(handles.xPosition_edit,'string',num/100);     %更新显示坐标
        limitsGuiReaction(2,handles.xMinus_pushbutton,handles.xPlus_pushbutton);     %更新gui控件标识
    end
else
    if index == numSwitch
        limitsGuiReaction(0,handles.xMinus_pushbutton,handles.xPlus_pushbutton);     %更新gui控件标识
    end
end
newNum = num;

function newNum = yCheckLimit(index,num,handles)
% y坐标极限检测
% index 控件索引
% num 输入坐标
% handles gui全局句柄
global numSwitch axisLimits;
if num < axisLimits(index,3)
    num = axisLimits(index,3);     %限制移动
    if index == numSwitch
        set(handles.yPosition_edit,'string',num/100);     %更新显示坐标
        limitsGuiReaction(1,handles.yMinus_pushbutton,handles.yPlus_pushbutton);     %更新gui控件标识
    end
elseif num > axisLimits(index,4)
    num = axisLimits(index,4);     %限制移动
    if index == numSwitch
        set(handles.yPosition_edit,'string',num/100);     %更新显示坐标
        limitsGuiReaction(2,handles.yMinus_pushbutton,handles.yPlus_pushbutton);     %更新gui控件标识
    end
else
    if index == numSwitch
        limitsGuiReaction(0,handles.yMinus_pushbutton,handles.yPlus_pushbutton);     %更新gui控件标识
    end
end
newNum = num;

function newNum = zCheckLimit(index,num,handles)
% z坐标极限检测
% index 控件索引
% num 输入坐标
% handles gui全局句柄
global numSwitch axisLimits;
if num < axisLimits(index,5)
    num = axisLimits(index,5);     %限制移动
    if index == numSwitch
        set(handles.zPosition_edit,'string',num/100);     %更新显示坐标
        limitsGuiReaction(1,handles.zMinus_pushbutton,handles.zPlus_pushbutton);     %更新gui控件标识
    end
elseif num > axisLimits(index,6)
    num = axisLimits(index,6);     %限制移动
    if index == numSwitch
        set(handles.zPosition_edit,'string',num/100);     %更新显示坐标
        limitsGuiReaction(2,handles.zMinus_pushbutton,handles.zPlus_pushbutton);     %更新gui控件标识
    end
else
    if index == numSwitch
        limitsGuiReaction(0,handles.zMinus_pushbutton,handles.zPlus_pushbutton);     %更新gui控件标识
    end
end
newNum = num;

function goTo(index,newP,handles)
% goto按钮功能实现，先判断是否可以移动，再进行移动，若超范围则移动到极限位置
% index 控件索引
% newP 待移动位置坐标 x y z
% global axisLimits;
x = newP(1);
x = xCheckLimit(index,x,handles);
% if x < axisLimits(index,1)
%     x = axisLimits(index,1);     %限制移动
%     set(handles.xPosition_edit,'string',x);     %更新显示坐标
%     limitsGuiReaction(1,handles.xMinus_pushbutton,handles.xPlus_pushbutton);     %更新gui控件标识
% elseif x > axisLimits(index,2)
%     x = axisLimits(index,2);     %限制移动
%     set(handles.xPosition_edit,'string',x);     %更新显示坐标
%     limitsGuiReaction(2,handles.xMinus_pushbutton,handles.xPlus_pushbutton);     %更新gui控件标识
% else
%     limitsGuiReaction(0,handles.xMinus_pushbutton,handles.xPlus_pushbutton);     %更新gui控件标识
% end
y = newP(2);
y = yCheckLimit(index,y,handles);
% if y < axisLimits(index,3)
%     y = axisLimits(index,3);     %限制移动
%     set(handles.yPosition_edit,'string',y);     %更新显示坐标
%     limitsGuiReaction(1,handles.yMinus_pushbutton,handles.yPlus_pushbutton);     %更新gui控件标识
% elseif y > axisLimits(index,4)
%     y = axisLimits(index,4);     %限制移动
%     set(handles.yPosition_edit,'string',y);     %更新显示坐标
%     limitsGuiReaction(2,handles.yMinus_pushbutton,handles.yPlus_pushbutton);     %更新gui控件标识
% else
%     limitsGuiReaction(0,handles.yMinus_pushbutton,handles.yPlus_pushbutton);     %更新gui控件标识
% end
z = newP(3);
z = zCheckLimit(index,z,handles);
% if z < axisLimits(index,5)
%     z = axisLimits(index,5);     %限制移动
%     set(handles.zPosition_edit,'string',z);     %更新显示坐标
%     limitsGuiReaction(1,handles.zMinus_pushbutton,handles.zPlus_pushbutton);     %更新gui控件标识
% elseif z > axisLimits(index,6)
%     z = axisLimits(index,6);     %限制移动
%     set(handles.zPosition_edit,'string',z);     %更新显示坐标
%     limitsGuiReaction(2,handles.zMinus_pushbutton,handles.zPlus_pushbutton);     %更新gui控件标识
% else
%     limitsGuiReaction(0,handles.zMinus_pushbutton,handles.zPlus_pushbutton);     %更新gui控件标识
% end
%commandMoveReaction(index, 'ABS', x, y, z, handles);     %绝对移动
commandMoveReaction(index, 'REL', x, y, z, handles);     %相对移动

function msg = removeEndEnterChar(str)
% 移除字符串末尾的回车
%判断最后一个字符是否为换行符
if (str(length(str))) == char(13)
	msg = str(1:(length(str)-1));
else
    msg = str;
end

function commandSTOPReaction(handles)
% 停止所有控件的任何移动
global numSwitch elementAvailable;
flag = [];
i = numSwitch;
%for i = 1:9
    if elementAvailable(i) == 1
        msg = sendAndGetResponse(i, 'STOP', handles);
        
        %判断最后一个字符是否为换行符
        if (msg(length(msg))) == char(13)
            msg = msg(1:(length(msg)-1));
        end
        if isempty(msg)
            disp(['串口返回异常',newline]);
            return;
        end
        if (msg ~= 'A')
            flag(i) = 0;
            disp(['停止失败！',newline])
        else
            flag(i) = 1;
            pXYZ = getCurrentPosition(i, handles);     %获取新位置
            setNewPosition(i,pXYZ);     %更新全局变量
        end
    end
%end
flag
% 若停止成功更新当前控件位置显示
if (flag(i) == 1)
    refreshGuiPosition(handles);
end

function getLimitsOfAxis(index, handles)
% 获取控件轴向移动是否到达位移极限
% index 控件索引
% handles gui全局句柄
global scoms;
com = scoms{index};
if elementAvailable(index) == 1
	msg = sendAndGetResponse(index, 'LIMITS', handles);
    
    %判断最后一个字符是否为换行符
    if (msg(length(msg))) == char(13)
        msg = msg(1:(length(msg)-1));
    end
    if isempty(msg)
        disp(['串口返回异常',newline]);
        return;
    end

    num = str2num(msg);
    %验证数据是否有效
    if isempty(num) || num < 0 || num > 63
        disp(['返回数据错误！',newline]);
        num
        return;
    end
    %数字解析
    xlimit = bitand(binNum,3);
    ylimit = bitshift(xlimitbitand(binNum,12),-2);
    zlimit = bitshift(xlimitbitand(binNum,48),-4);
    %gui响应
    limitsGuiReaction(xlimit,handles.xMinus_pushbutton,handles.xPlus_pushbutton);
    limitsGuiReaction(ylimit,handles.yMinus_pushbutton,handles.yPlus_pushbutton);
    limitsGuiReaction(zlimit,handles.zMinus_pushbutton,handles.zPlus_pushbutton);
    
    
end

function limitsGuiReaction(limitResponse, hObjectLow, hObjectHeight)
% 对应高低限制显示控件响应
% limitResponse 控件移动极限标识数据 0 无；1 低极限；2 高极限；3 高低都极限
% hObjectLow 低极限显示控件句柄
% hObjectHeight 低极限显示控件句柄
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
        disp(['输入标志位数据错误',newline]);
        return;
end

function isMoving = checkIsMoving(index,handles)
% 检测当前控件是否移动 移动则返回1；停止则返回0;异常返回-1
% handles gui全局句柄

%{
%自己编写的,只会更新prePosition
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
%新版指令
msg = sendAndGetResponse(index, 'S', handles);     %获取运动状态
msg = removeEndEnterChar(msg);		% 移除字符串末尾的回车
if isempty(msg)
	disp(['串口返回异常',newline]);
	return;
end
switch (msg)
    case '0'
        isMoving = 0;
    case '1'
        isMoving = 1;
    otherwise
        disp(['返回数据异常',newline]);
        msg
        isMoving = -1;
end


function obj = getObjective(handles)
% 获取物镜倍率 0 获取失败；1 低倍镜；2 高倍镜（待定）
% handles gui全局句柄
msg = sendAndGetResponse(1, 'OBJ', handles);
msg = removeEndEnterChar(msg);     %删除字符串末的换行符
if isempty(msg)
	disp(['串口返回异常',newline]);
	return;
end
num = str2num(msg);
if num == 1 || num == 2
    obj = num;
else
    obj = 0;
end

function setObjective(objnum,handles)
% 切换物镜
% objnum 1 低倍镜；2 高倍镜（暂定）
% handles gui全局句柄
switch(objnum)
    case 1
        'OBJ 1'
        msg = sendAndGetResponse(1, 'OBJ 1', handles);
    case 2
        'OBJ 2'
        msg = sendAndGetResponse(1, 'OBJ 2', handles);
    otherwise
        disp(['输入参数错误',newline]);
        objnum
        return;
end
msg = removeEndEnterChar(msg);		% 移除字符串末尾的回车
if isempty(msg)
	disp(['串口返回异常',newline]);
	return;
end
if msg == 'A'
    disp(['物镜切换成功',newline]);
    if strcmp(get(handles.objswitch_pushbutton,'String'),'×4')
        set(handles.objswitch_pushbutton,'String','×40');
    else
        set(handles.objswitch_pushbutton,'String','×4');
    end
else
    disp(['物镜切换失败',newline]);
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
	disp(['串口返回异常',newline]);
	return;
end

function positionInitiate(handles)
% 从各可控元件获取初始位置
global comList elementAvailable;
loadABSZeroFromConfigFile();
comPortOff();
availableCom = getAvailableComPort;     %获取有效串口列表
%验证目标串口是否可用
for i = 1:size(comList, 1)
    for j = 1:size(availableCom, 1)
        if strcmp(comList{i},availableCom{j})
            elementAvailable(i) = 1;
        end
    end
end
setButtonEnableOfElement(elementAvailable,handles);     %设置按钮可用

%打开所有串口
for i = 1:9
    if elementAvailable(i) == 1
        flag = comPortOn(i, handles);	% 打开串口com1
        if flag == 0
            elementAvailable(i) = 0;
        else
            pXYZ = getCurrentPosition(i, handles);     %获取控件位置
            setNewPosition(i,pXYZ);     %更新全局变量
        end
    end
end

refreshGuiPosition(handles);     %刷新显示
%{
for i = 1:9
    if elementAvailable(i) == 1
        str1 = comList{i};    %串口名，值为com1
        msg = sendAndGetResponse(str1, 'P', handles);     %获取控件位置
        %更新控件坐标
    end
end
%}
%控件描述字符串获取
if elementAvailable(4) == 1
    msg = sendAndGetResponse(4, 'DESC', handles);
    msg = removeEndEnterChar(msg);		% 移除字符串末尾的回车
    if isempty(msg)
        disp(['串口返回异常',newline]);
        return;
    end
    msg1 = sendAndGetResponse(4, 'ANGLE', handles);
    msg1 = removeEndEnterChar(msg1);      % 移除字符串末尾的回车
    if isempty(msg1)
        disp(['串口返回异常',newline]);
        return;
    end
end
%物镜切换功能初始化
if elementAvailable(1) == 1
    % 显微镜物镜切换按钮初始化
    disp(['初始化显微镜物镜按钮',newline]);
    obj = getObjective(handles);
    switch(obj)
        case 0
            disp(['物镜初始化失败',newline]);
            set(handles.objswitch_pushbutton,'Enable', 'off');
        case 1
            set(handles.objswitch_pushbutton,'String', '×40');
        case 2
            set(handles.objswitch_pushbutton,'String', '×4');
    end
else
    set(handles.objswitch_pushbutton,'Enable','off');
end



function setButtonEnableOfElement(a,handles)
% 按照标识数组设置选项卡按钮是否可用
% a 标识数组
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
% 按照标识数组设置选项卡按钮字体颜色
% a 标识数组
% 0 设置为灰色 [0.6,0.6,0.6]； 1 设置为黑色
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
% 被控元件选择按钮响应
% a 被控元件的编号
%newSwitch = getappdata(handles.figure1, 'numSwitch');
global numSwitch newPosition;
if numSwitch ~= a
    %输入框空异常处理
    if isempty(str2num(get(handles.xPosition_edit,'string'))) || isempty(str2num(get(handles.yPosition_edit,'string'))) || isempty(str2num(get(handles.zPosition_edit,'string')))
        disp(['请输入数字！',newline])
        return;
    end  
    %保存上个控件位置
    newPosition(numSwitch,1) = str2num(get(handles.xPosition_edit,'string'))*100;
    newPosition(numSwitch,2) = str2num(get(handles.yPosition_edit,'string'))*100;
    newPosition(numSwitch,3) = str2num(get(handles.zPosition_edit,'string'))*100;
    %更新按钮字体颜色
    flag = zeros(1,9);
    numSwitch = a;
    flag(numSwitch) = 1;
    setButtonColorOfElements(flag,handles);
    %更新位置数据
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
%   【打开/关闭串口】按钮的回调函数
%    打开串口，并初始化相关参数
%% 若按下【打开串口】按钮，打开串口
%global vv
%global dd
if get(hObject, 'value')
    %% 获取串口的端口名
    com_n = sprintf('com%d', get(handles.com, 'value'));
    %% 获取波特率
    rates = [300 600 1200 2400 4800 9600 19200 38400 43000 56000 57600 115200];
    baud_rate = rates(get(handles.rate, 'value'));
    %% 获取校验位设置
    switch get(handles.jiaoyan, 'value')
        case 1
            jiaoyan = 'none';
        case 2
            jiaoyan = 'odd';
        case 3
            jiaoyan = 'even';
    end
    %% 获取数据位个数
    data_bits = 5 + get(handles.data_bits, 'value');
    %% 获取停止位个数
    stop_bits = get(handles.stop_bits, 'value');
    %% 创建串口对象
    scom = serial(com_n);
    %% 配置串口属性，指定其回调函数
    set(scom, 'BaudRate', baud_rate, 'Parity', jiaoyan, 'DataBits',...
        data_bits, 'StopBits', stop_bits, 'BytesAvailableFcnCount', 10,...
        'BytesAvailableFcnMode', 'byte', 'BytesAvailableFcn', {@bytes, handles},...
        'TimerPeriod', 0.05, 'timerfcn', {@dataDisp, handles});
    %BytesAvailableFcnMode 设置中断响应模式（有“byte”和“Terminator”两种模式可选，“byte”是达到一定字节数产生中断，“Terminator”可用作键盘某个按键事件来产生中断）
    %% 将串口对象的句柄作为用户数据，存入窗口对象
    set(handles.figure1, 'UserData', scom);
    %% 尝试打开串口
    try
        fopen(scom);  %打开串口
    catch   % 若串口打开失败，提示“串口不可获得！”
        msgbox('串口不可获得！','Error','error');
        set(hObject, 'value', 0);  %弹起本按钮 
        return;
    end
    %% 打开串口后，允许串口发送数据，清空接收显示区，点亮串口状态指示灯，
    %% 并更改本按钮文本为“关闭串口”
    set(handles.period_send, 'Enable', 'on');  	%启用【自动发送】按钮
    set(handles.manual_send, 'Enable', 'on');  %启用【手动发送】按钮
    set(handles.EnterSend,'Enable','on');%启用【回车发送】按钮 (1125)
    set(handles.xianshi, 'string', ''); 			%清空接收显示区
    set(handles.lamb, 'BackgroundColor', getappdata(handles.figure1,'openData')); %点亮串口状态指示灯
    set(hObject, 'String', '关闭串口');  		%设置本按钮文本为“关闭串口”
   
else  %若关闭串口
    %% 停止并删除定时器
    t = timerfind;
    if ~isempty(t)
        stop(t);
        delete(t);
    end
    %% 停止并删除串口对象
    scoms = instrfind; %将所有有效的串行端口对象以 out 数组形式返回
    stopasync(scoms); %停止异步读写操作
    fclose(scoms);
    delete(scoms);
    %% 禁用【自动发送】和【手动发送】按钮，熄灭串口状态指示灯
    set(handles.period_send, 'Enable', 'off', 'Value', 0); %禁用【自动发送】按钮
    set(handles.EnterSend, 'Enable', 'off', 'Value', 0); %禁用【回车发送】按钮 (1125)
    set(handles.manual_send, 'Enable', 'off');  %禁用【手动发送】按钮
    set(handles.lamb, 'BackgroundColor', getappdata(handles.figure1,'closedData')); %熄灭串口状态指示灯
    set(hObject, 'String', '打开串口');  		%设置本按钮文本为“打开串口”
end

function dataDisp(obj, event, handles)
%	串口的TimerFcn回调函数
%   串口数据显示
%% 获取参数
hasData = getappdata(handles.figure1, 'hasData'); %串口是否收到数据
strRec = getappdata(handles.figure1, 'strRec');   %串口数据的字符串形式，定时显示该数据
numRec = getappdata(handles.figure1, 'numRec');   %串口接收到的数据个数
%% 若串口没有接收到数据，先尝试接收串口数据
if ~hasData
    bytes(obj, event, handles);
end
%% 若串口有数据，显示串口数据
if hasData
    %% 给数据显示模块加互斥锁
    %% 在执行显示数据模块时，不接受串口数据，即不执行BytesAvailableFcn回调函数
    setappdata(handles.figure1, 'isShow', true); 
    %% 若要显示的字符串长度超过10000，清空显示区
    if length(strRec) > 10000
        strRec = '';
        setappdata(handles.figure1, 'strRec', strRec);
    end
    %% 显示数据
    set(handles.xianshi, 'string', strRec);
    %% 更新接收计数
    set(handles.rec,'string', numRec);
    %% 更新hasData标志，表明串口数据已经显示
    setappdata(handles.figure1, 'hasData', false);
    %% 给数据显示模块解锁
    setappdata(handles.figure1, 'isShow', false);
end
 
function bytes(obj, ~, handles)
%   串口的BytesAvailableFcn回调函数
%   串口接收数据
%% 获取参数
strRec = getappdata(handles.figure1, 'strRec'); %获取串口要显示的数据
numRec = getappdata(handles.figure1, 'numRec'); %获取串口已接收数据的个数
isStopDisp = getappdata(handles.figure1, 'isStopDisp'); %是否按下了【停止显示】按钮
isHexDisp = getappdata(handles.figure1, 'isHexDisp'); %是否十六进制显示
isShow = getappdata(handles.figure1, 'isShow');  %是否正在执行显示数据操作
%% 若正在执行数据显示操作，暂不接收串口数据
if isShow
    return;
end
%% 获取串口可获取的数据个数
n = get(obj, 'BytesAvailable');
%% 若串口有数据，接收所有数据
if n
    %% 更新hasData参数，表明串口有数据需要显示
    setappdata(handles.figure1, 'hasData', true);
    %% 读取串口数据
    a = fread(obj, n, 'uchar');
    %% 若没有停止显示，将接收到的数据解算出来，准备显示
    if ~isStopDisp 
        %% 根据进制显示的状态，解析数据为要显示的字符串
        if ~isHexDisp 
            c = char(a');
        else
            strHex = dec2hex(a')';
            strHex2 = [strHex; blanks(size(a, 1))]; %???为啥要添一个空的同样大小的字符串
            c = strHex2(:)';
        end
        %% 更新已接收的数据个数
        numRec = numRec + size(a, 1);
        %% 更新要显示的字符串
        strRec = [strRec c];
    end
    %% 更新参数
    setappdata(handles.figure1, 'numRec', numRec); %更新已接收的数据个数
    setappdata(handles.figure1, 'strRec', strRec); %更新要显示的字符串
end


function qingkong_Callback(hObject, eventdata, handles)
%% 清空要显示的字符串
setappdata(handles.figure1, 'strRec', '');
%% 清空显示
set(handles.xianshi, 'String', '');

function stop_disp_Callback(hObject, eventdata, handles)
%% 根据【停止显示】按钮的状态，更新isStopDisp参数
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
%% 根据【十六进制显示】复选框的状态，更新isHexDisp参数
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
    %% 设置倒计数的初值
    n = 1000;
    while n
        %% 获取串口的传输状态，若串口没有正在写数据，写入数据
        str = get(scom, 'TransferStatus');
        if ~(strcmp(str, 'write') || strcmp(str, 'read&write')) 
            if ~I_flag
             fwrite(scom, val, 'uint8', 'async'); %数据写入串口
                I_flag=1;
            end
        end
        if EnterSend_flag
            str = get(scom, 'TransferStatus');
            if ~(strcmp(str, 'write') || strcmp(str, 'read&write'))
                 fwrite(scom, vv); %数据写入串口
                 fwrite(scom, dd); %数据写入串口
                 break;
            end
        end 
        n = n - 1; %倒计数
    end
end



function clear_send_Callback(hObject, eventdata, handles)
%% 清空发送区
set(handles.sends, 'string', '')
%% 更新要发送的数据
set(handles.sends, 'UserData', []);

function checkbox2_Callback(hObject, eventdata, handles)


function period_send_Callback(hObject, eventdata, handles)
%   【自动发送】按钮的Callback回调函数
%% 若按下【自动发送】按钮，启动定时器；否则，停止并删除定时器
if get(hObject, 'value')
    t1 = 0.001 * str2double(get(handles.period1, 'string'));%获取定时器周期
    t = timer('ExecutionMode','fixedrate', 'Period', t1, 'TimerFcn',...
        {@manual_send_Callback, handles}); %创建定时器
    set(handles.period1, 'Enable', 'off'); %禁用设置定时器周期的Edit Text对象
    set(handles.sends, 'Enable', 'inactive'); %禁用数据发送编辑区
    start(t);  %启动定时器
else
    set(handles.period1, 'Enable', 'on'); %启用设置定时器周期的Edit Text对象
    set(handles.sends, 'Enable', 'on');   %启用数据发送编辑区
    t = timerfind; %查找定时器
    stop(t); %停止定时器
    delete(t); %删除定时器
end

function period1_Callback(hObject, eventdata, handles)

function period1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function clear_count_Callback(hObject, eventdata, handles)
%% 计数清零，并更新参数numRec和numSend
set([handles.rec, handles.trans], 'string', '0')
setappdata(handles.figure1, 'numRec', 0);
setappdata(handles.figure1, 'numSend', 0);

function copy_data_Callback(hObject, eventdata, handles)
%% 设置是否允许复制接收数据显示区内的数据
if get(hObject,'value')
    set(handles.xianshi, 'enable', 'on');
else
    set(handles.xianshi, 'enable', 'inactive');
end

function figure1_CloseRequestFcn(hObject, eventdata, handles)
%   关闭窗口时，检查定时器和串口是否已关闭
%   若没有关闭，则先关闭
%% 查找定时器
t = timerfind;
%% 若存在定时器对象，停止并关闭
if ~isempty(t)
    stop(t);  %若定时器没有停止，则停止定时器
    delete(t);
end
%% 查找串口对象
scoms = instrfind;
%% 尝试停止、关闭删除串口对象
try
    stopasync(scoms);
    fclose(scoms);
    delete(scoms);
catch
end
%% 关闭窗口
delete(hObject);

function hex_send_Callback(hObject, eventdata, handles)
%% 根据【十六进制发送】复选框的状态，更新isHexSend参数
if get(hObject,'value')
    isHexSend = true;
else
    isHexSend = false;
end
setappdata(handles.figure1, 'isHexSend', isHexSend);
%% 更新要发送的数据
sends_Callback(handles.sends, eventdata, handles);


function sends_Callback(hObject, eventdata, handles)
%   数据发送编辑区的Callback回调函数
%   更新要发送的数据
%% 获取数据发送编辑区的字符串
str = get(hObject, 'string');
%% 获取参数isHexSend的值
isHexSend = getappdata(handles.figure1, 'isHexSend');
if ~isHexSend %若为ASCII值形式发送，直接将字符串转化为对应的数值
    val = double(str);
else  %若为十六进制发送，获取要发送的数据
    n = find(str == ' ');   %查找空格
    n =[0 n length(str)+1]; %空格的索引值
    %% 每两个相邻空格之间的字符串为数值的十六进制形式，将其转化为数值
    for i = 1 : length(n)-1 
        temp = str(n(i)+1 : n(i+1)-1);  %获得每段数据的长度，为数据转换为十进制做准备
        if ~rem(length(temp), 2)
            b{i} = reshape(temp, 2, [])'; %将每段十六进制字符串转化为单元数组
        else
            break;
        end
    end
    val = hex2dec(b)';     %将十六进制字符串转化为十进制数，等待写入串口
end
%% 更新要显示的数据
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
    set(handles.CameraButton, 'string',"关闭摄像头",'ForegroundColor',[1 0 0]);
    objects = imaqfind;
    delete(objects);
%     obj = videoinput('winvideo',1,'YUY2_640x480');
    obj = videoinput('pmimaq_2019b', 1, 'PM-Cam 1376x1024'); %开始读图像
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
    set(hObject, 'String', "开启摄像头",'ForegroundColor',[0 0 1]);  		%设置本按钮文本
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
    helpdlg(strcat('成功保存至',strcat(pname,fname)),'Tips');
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
       set(handles.StopCamera,"string","继续",'ForegroundColor',[0 0 1]);
       stoppreview(obj);
       isCameraStopFlag = true;
    else
       set(handles.StopCamera,"string","暂停",'ForegroundColor',[1 0 0]);
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
    %判断当前位置是否为显示框中位置
    pDisplay = zeros(1,3);
    pDisplay(1) = str2num(get(handles.xPosition_edit,'String'))*100;
    pDisplay(2) = str2num(get(handles.yPosition_edit,'String'))*100;
    pDisplay(3) = str2num(get(handles.zPosition_edit,'String'))*100;
%     numSwitch
    prePosition(numSwitch,:)
%     pDisplay
    if pDisplay(1) ~= prePosition(numSwitch,1) || pDisplay(2) ~= prePosition(numSwitch,2) || pDisplay(3) ~= prePosition(numSwitch,3)
        % 目前协同默认为显微镜与单个微操的协同，所以协同时numSwitch = 1
        if numSwitch == 1 && get(handles.comove_checkbox,'value')
            %显微镜判断是否可移动
            tempP = zeros(1,3);
            tempP(1) = xCheckLimit(1,pDisplay(1),handles);
            tempP(2) = yCheckLimit(1,pDisplay(2),handles);
            tempP(3) = zCheckLimit(1,pDisplay(3),handles);
            if pDisplay(1) ~= tempP(1) || pDisplay(2) ~= tempP(2) || pDisplay(3) ~= tempP(3)
                str = ['显微镜无法移动到该位置',newline];
                disp(str);
                return;
            end
            
            %协同移动控件，测试时为3号微操
            %根据显微镜移动，计算微操坐标
            detaP = pDisplay - prePosition(1,:);     %显微镜位移变化
            angleOffset(4)
            
            
            theta = angleOffset(4)/180*pi;
            dP = zeros(1,3);     %先存变化量
            dP(1) = detaP(1)*cos(theta) + detaP(2)*sin(theta);
            dP(2) = -detaP(1)*sin(theta) + detaP(2)*cos(theta);
            dP(3) = detaP(3);
            %微操判断是否可移动
            tempP(1) = prePosition(4,1)+dP(1) - xCheckLimit(4,prePosition(4,1)+dP(1),handles);
            tempP(2) = prePosition(4,2)+dP(2) - yCheckLimit(4,prePosition(4,2)+dP(2),handles);
            tempP(3) = prePosition(4,3)+dP(3) - zCheckLimit(4,prePosition(4,3)+dP(3),handles);
            if tempP(1) ~= 0 || tempP(2) ~= 0 || tempP(3) ~= 0
                str = ['微操无法移动到该位置',newline];
                disp(str);
                return;
            end
            %进行协同移动
            commandMoveReaction(4, 'RELD', dP(1), dP(2), dP(3), handles);     %微操相对移动
            
            commandMoveReaction(1, 'RELD', detaP(1), detaP(2), detaP(3), handles);     %显微镜相对移动
            disp(['协同移动成功',newline]);
        else
            %当前控件移动
            goTo(numSwitch,pDisplay,handles);
        end
    else
        disp(['已经在该位置',newline]);
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
    disp(['还未获取目标点坐标',newline]);
    return;
end
% 判断坐标是否超过极限,协同需更多
x = prePosition(numSwitch,1) + round((loc(1,2)-512)*50/3)
newX = xCheckLimit(numSwitch,x,handles)
y = prePosition(numSwitch,2) - round((loc(1,1)-688)*50/3)
newY = yCheckLimit(numSwitch,y,handles)
if newX ~= x || newY ~= y
    disp(['目标位置超出显微镜位移极限',newline]);
    return;
end
% 显微镜移动
commandMoveReaction(1, 'RELD', round((loc(1,2)-512)*50/3), -round((loc(1,1)-688)*50/3), 0, handles);
%界面更新
flag = (numSwitch == 1);
ifmoving = 1;
while(ifmoving == 1)
    pause(0.05);
    ifmoving = checkIsMoving(1,handles);	% 检测当前控件是否移动
    %{
    %只更新prePosition
    newPosition(1,:) = prePosition(1,:);
    %}
    %更新当前位置
    pXYZ = getCurrentPosition(1, handles);     %获取控件位置
    setNewPosition(1, pXYZ);     %更新全局变量
    if (flag)
        refreshGuiPosition(handles)		% 刷新当前显示的坐标
    end
end
loc = zeros(1,2);

%协同移动
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
if (strcmp(str,'×4'))
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
            % 开始获取点击的坐标
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
            % 开始获取点击的坐标
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
        % 测试微操3号
        % Calibration
        dx = P2(1) - P1(1)
        dy = P2(2) - P1(2)
        dz = P2(3) - P1(3)
        theta = atan(dy / dx) / pi * 180
        alpha = atan(sqrt(dx * dx + dy * dy) / dz) / pi * 180
        
    else
        % 测试微操3号
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
