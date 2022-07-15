function UsingCosmosData

[t,SoilTemp]=PlotData;

Ts=290;

Ts=SoilTemp;

wait = waitbar(0,'Please wait...');

N=84550;
for k=1:N
    COPn(k)=SoilTempVsCOP(Ts(k));
    waitbar(k/N,wait)
    save('MyData.mat','COPn','Ts','t')
end
close(wait)

load('MyData.mat')

N=numel(COPn);
figure(1)
clf
subplot(2,1,1)
plot(t(1:N),Ts(1:N))
datetick('x','dd-mmm')
subplot(2,1,2)
plot(t(1:N),COPn(1:N))
datetick('x','dd-mmm')

figure(2)
clf
plot(Ts(1:N),COPn(1:N),'.')


%xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx


function  [t,SoilTemp]=PlotData

MYDir=['C:\Me Stuff\Uni\Durham\Research Project\Code\COSMOS-UK_HydroSoil_SH_2013-2019\']; %Laptop
% MYDir=['D:\Uni\DURHAM\Research Project\MatLab\Lookup\COSMOS-UK_HydroSoil_SH_2013-2019\']; %PC
MyFileNames=dir(MYDir);


k=3; %file number goes from 3 to 53
opts=detectImportOptions([MYDir MyFileNames(k).name]);
opts.Delimiter = {','};
%This will store all the data in a readable table
alldata=readtable([MYDir MyFileNames(k).name], opts);
%Convert numeric data to an array
numdata=table2array(alldata(:,3:end));
numdata(numdata==-9999)=NaN;

SoilTemp=numdata(:,[45:45]-2);
SoilTemp=SoilTemp+273.15;

%Define start time
t0=datenum(2015,3,6,13,30,0);
j=[1:size(numdata,1)]';
t=t0+(j-1)/58;

%
figure(1)
clf
plot(t,SoilTemp)
% xlim(datenum(2016,[5 6],1))
datetick('x','mmm-dd','keeplimits')
ylabel('Temperature (K)')

%xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

function COPn=SoilTempVsCOP(Ts)

% Parameters
% T = Temperature K
% P = Pressure Pa
% h = enthalpy J/kg
% s = entropy J/kgK
% Qin = Work in at evaporator kW
% Win = Work in at compressor kW
% Qout = Work out at condenser kW - Qout = Heating Load
% COP = Coefficient of Performance
% HL = Heating Load (W / kW)
%
%
% 

%The opperating temperature of the refrigerant at points 1 and 4 is -6C (=267K).
% The temperature leaving the evaporator (T3) is to be 45C (318K)
%
% Working Fluid
F='R134a';

% Temperatures (K)
T1=273;

T3=318;

%Quality
Q1=1;
Q3=0;
% Q4 is to be calculated later

% Ground Heat Exchanger (GHE)
GHEL=853; % Length of the GHE (m)
GHER=2; % Thermal resistance of the GHE (mK/W)



%Known Parameters
% Building
% The building / volume that is being heated in this scenario has a heating
% load (the amount of power output from the heating system required), Which
% can be calculated using a simple calculation
Af=96; % floor area (m^2)
height=2.5; % height from floor to ceiling (m)
Np=4; % number of people

% % SoilTemp in the excel is in Degree's C, CoolProp runs in Kelvin, so 273.15 needs to
% % be added to the value obtained from the excel

T4=T1;

% Heating load will be initially calculated in BTU, so a conversion is applied.
% 1 BTU = 0.00029307107kW
% Each additional person in the building subracts another 500 BTU to the
% heating load.

HL=[(Af*height*141)-(Np*500)]*0.00029307107; % Heating Load in kW
Qout=HL;


% Point 1 - Known temperature and quality
P1=py.CoolProp.CoolProp.PropsSI('P','T',T1,'Q',Q1,F);
h1=py.CoolProp.CoolProp.PropsSI('H','T',T1,'Q',Q1,F);
s1=py.CoolProp.CoolProp.PropsSI('S','T',T1,'Q',Q1,F);

% Point 3 - Known temperature and quality
P3=py.CoolProp.CoolProp.PropsSI('P','T',T3,'Q',Q3,F);
h3=py.CoolProp.CoolProp.PropsSI('H','T',T3,'Q',Q3,F);
s3=py.CoolProp.CoolProp.PropsSI('S','T',T3,'Q',Q3,F);

% Point 4 - Temperature known
% P1 = P4
% h4 = h3
P4=P1;
h4=h3;
% To find Q4, you need the enthalpy values for point 4 at quality 1 and 0,
% and then use the calculated h4 to find the quality.
h4g=py.CoolProp.CoolProp.PropsSI('H','T',T4,'Q',1,F);
h4f=py.CoolProp.CoolProp.PropsSI('H','T',T4,'Q',0,F);
Q4=(h4-h4f)/(h4g-h4f);
% entrpoy can now be calculated
s4=py.CoolProp.CoolProp.PropsSI('S','T',T4,'Q',Q4,F);

% Point 2 - Values can be calculated using other known data
P2=P3;
s2=s1;
T2=py.CoolProp.CoolProp.PropsSI('T','S',s2,'P',P2,F);
h2=py.CoolProp.CoolProp.PropsSI('H','P',P2,'S',s2,F);


% Using Qout = Mr x (h2 - h3) , you can rearrange to make Mr the subject.
% Mr = mass flow rate refrigerant (kg/s)
%
Mr=Qout/(h2-h3);

% Win (kW) is the work input by the compressor to compress the fluid from state
% 1 to state 2
Win=Mr*(h2-h1);

% COP (unitless) is the ratio of the useful heat energy being delivered to
% the target volume to the amount of power being input by the compressor
COP=Qout/Win;

% For the next cycle to begin, a new value of h1 needs to be calculated
% using a calculated Qin (kW) value.
% Need to revisiti how to lookup the soil temperature data from the
% CVS spreadsheet, still a little bit confused.
% Ts = Temperatures of the soil at 50cm depth
% Ts needs to be looked up from the cvs files for each run. Little stuck
% on that, need to go through again.



Qin=(GHEL*((Ts-T4)/GHER))/1000;

% Then using the equation Qin = Mr*(h1 - h4) and rearranging to make h1 the
% subject, this h1 value is the new value for the start of the next cycle
% h1n (h1 new).
h1n=(Qin/Mr)+h4;



P1=py.CoolProp.CoolProp.PropsSI('P','T',T1,'Q',Q1,F);

s1=py.CoolProp.CoolProp.PropsSI('S','T',T1,'Q',Q1,F);

% Point 3 - Known temperature and quality
P3=py.CoolProp.CoolProp.PropsSI('P','T',T3,'Q',Q3,F);
h3=py.CoolProp.CoolProp.PropsSI('H','T',T3,'Q',Q3,F);
s3=py.CoolProp.CoolProp.PropsSI('S','T',T3,'Q',Q3,F);

% Point 4 - Temperature known
% P1 = P4
% h4 = h3
P4=P1;
h4=h3;
% To find Q4, you need the enthalpy values for point 4 at quality 1 and 0,
% and then use the calculated h4 to find the quality.
h4g=py.CoolProp.CoolProp.PropsSI('H','T',T4,'Q',1,F);
h4f=py.CoolProp.CoolProp.PropsSI('H','T',T4,'Q',0,F);
Q4=(h4-h4f)/(h4g-h4f);
% entrpoy can now be calculated
s4=py.CoolProp.CoolProp.PropsSI('S','T',T4,'Q',Q4,F);

% Point 2 - Values can be calculated using other known data
P2=P3;
s2=s1;
T2=py.CoolProp.CoolProp.PropsSI('T','S',s2,'P',P2,F);
h2=py.CoolProp.CoolProp.PropsSI('H','P',P2,'S',s2,F);

Winn=Mr*(h2-h1n);

% COP (unitless) is the ratio of the useful heat energy being delivered to
% the target volume to the amount of power being input by the compressor
COPn=Qout/Winn;


%xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
% 1	DATE_TIME
% 2	SITE_ID
% 3	LWIN
% 4	LWOUT
% 5	SWIN
% 6	SWOUT
% 7	RN
% 8	PRECIP
% 9	PA
% 10	TA
% 11	WS
% 12	WD
% 13	Q
% 14	RH
% 15	SNOWD_DISTANCE_COR
% 16	UX
% 17	UY
% 18	UZ
% 19	G1
% 20	G2
% 21	TDT1_TSOIL
% 22	TDT1_VWC
% 23	TDT2_TSOIL
% 24	TDT2_VWC
% 25	TDT3_TSOIL
% 26	TDT3_VWC
% 27	TDT4_TSOIL
% 28	TDT4_VWC
% 29	TDT5_TSOIL
% 30	TDT5_VWC
% 31	TDT6_TSOIL
% 32	TDT6_VWC
% 33	TDT7_TSOIL
% 34	TDT7_VWC
% 35	TDT8_TSOIL
% 36	TDT8_VWC
% 37	TDT9_TSOIL
% 38	TDT9_VWC
% 39	TDT10_TSOIL
% 40	TDT10_VWC
% 41	STP_TSOIL2
% 42	STP_TSOIL5
% 43	STP_TSOIL10
% 44	STP_TSOIL20
% 45	STP_TSOIL50
