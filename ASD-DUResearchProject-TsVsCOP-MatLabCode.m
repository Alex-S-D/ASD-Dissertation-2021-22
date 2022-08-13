function UsingCosmosData
% This section defines the funtions that should be run, the data that is to be saved and then plotted %
% The plotted data will appear on a single window, with 2 graphs displayed %

% k selects the file being assessed. This value ranges from 3 to 53 %
% All files can be run consecutively by using "k=3:53" %
for k=3;
COPmean(k)=COPmeanFun(k);
end

% This displays the mean COP of the data being run

disp(COPmean)


function COPmean=COPmeanFun(k)

% This sub-function calculates the mean value of COP for the data being run
% by using the Ideal Reversed Carnot Cycle code to find the COP values of
% 100 Linearly spaced temperature points from the relevent data set. 
% This data is then used as a lookup table to claculate the other COP
% values (COPn) for the remaining Ts values in the file.


%Define refigerant
F='R134a';
%Import temperature data
[t,Ts,MyLocation]=ImportTempData(k);
%Determine range of soil temperatures experienced in the data set being run
Tmin=min(Ts);
Tmax=max(Ts);
% "Ti" determines the set of temperatures used for the lookup table by
% linearly spacing 100 points along the Ts curve produced
Ti=linspace(Tmin,Tmax,100);
% "COPi" Determines the corresponding set of COP values for the linearly
% spaced Ti values found above.
for k=1:numel(Ti)
    COPi(k)=SoilTempVsCOP(Ti(k),F);
end
 
% Use interpolation to work out COP for time-series
COPn=interp1(Ti,COPi,Ts);

% Number checking section, needed to assess errors
num2str([Ts(COPn<0) COPn(COPn<0)],4);
num2str([Ti; COPi]',4);

% This section excludes data values for the summer months in the UK, as the
% winter months are the ones under investigation. 
% This is done by using a date vector function to define summer period
% (Start April to End August) and then having the COP values calculated for
% those time periods equal to "NaN" which will not display on the graph.
[yyyy,mm,dd]=datevec(t);
MySummer=mm>=5&mm<=8;
% Make summer COP NaN
COPn(MySummer)=NaN;

% Mean COP is determined 
COPmean=mean(COPn,'omitnan');

figure(1)
clf
subplot(2,1,1)
plot(t,Ts)
datetick('x','mm-yyyy','keeplimits')
title(MyLocation(11:15))
subplot(2,1,2)
plot(t,COPn)
ylim([0 5])
datetick('x','mm-yyyy','keeplimits')
drawnow


%xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx%

function  [t,SoilTemp,MyLocation]=ImportTempData(k)

% This sub-function is the function that looked up data from the relevent Excel CSV file %
% There are 2 "MyDir" locations in this section as the work was done both on my personal Laptop and my Home PC, each had different file loaction routes %

% MYDir=['C:\Me Stuff\Uni\Durham\Research Project\Code\COSMOS-UK_HydroSoil_SH_2013-2019\']; %Laptop
MYDir=['D:\Uni\DURHAM\Research Project\MatLab\Lookup\COSMOS-UK_HydroSoil_SH_2013-2019\']; %PC
MyFileNames=dir(MYDir);

% Detects and displays the loaction name of the file data being read for
% calculation.
MyLocation=MyFileNames(k).name;
opts=detectImportOptions([MYDir MyFileNames(k).name]);
opts.Delimiter = {','};
% This will store all the data in a readable table
alldata=readtable([MYDir MyFileNames(k).name], opts);
% Convert numeric data to an array
numdata=table2array(alldata(:,3:end));
numdata(numdata==-9999)=NaN;

% This section selects the column being read from the CSV file. The number
% and relating look up column is shown at the bottom of this file.
SoilTemp=numdata(:,[45:45]-2);
% SoilTemp has 273.15 added here to convert degree's Celsius to Kelvin as
% the CoolProp toolbox uses Kelvin to perform the thermodynamic cycle.
SoilTemp=SoilTemp+273.15;

% As each file has a unique start time, this has to be change manually at this point, with t0 being the start time %
t0=datenum(2015,3,6,13,30,0);
j=[1:size(numdata,1)]';
t=t0+(j-1)/48;


%xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx%

function COPn=SoilTempVsCOP(Ts,F)

% This sub-function calculated and defines the Ideal Reverse Carnot Cycle %
% A series of pre-defined parameters are used to start the process %

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


%The assumed opperating temperature of the refrigerant at points 1 and 4 is 0C (=273K) %
% The temperature leaving the evaporator (T3) is to be 45C (318K) as determined from data decribed in the report %

% Assumed temperatures (Kelvin)
T1=273;

T3=318;

% Quality of positions 1 and 3 assumed to be 1 and 0, respectively. This is because these points are assumed to lie on the thermodynamic boundary curve (P-h diagram) %
Q1=1;
Q3=0;
% Q4 is to be calculated later

% Ground Heat Exchanger (GHE) calculated length input here %
GHEL=853; % Length of the GHE (m)
GHER=2; % Thermal resistance of the GHE K/W



%Known Parameters
% Building
% The building / volume that is being heated in this scenario has a heating
% load (the amount of power output from the heating system required), Which
% can be calculated using a simple calculation
Af=96; % floor area (m^2)
height=2.5; % height from floor to ceiling (m)
Np=4; % number of people

T4=T1;

% Heating load will be initially calculated in BTU, so a conversion is applied.
% 1 BTU = 0.00029307107kW
% Each additional person in the building subracts another 500 BTU to the
% heating load.

HL=[(Af*height*141)-(Np*500)]*0.00029307107; % Heating Load in kW
Qout=HL;


% Point 1 - Known temperature and quality can calculate other values needed
P1=py.CoolProp.CoolProp.PropsSI('P','T',T1,'Q',Q1,F);
h1=py.CoolProp.CoolProp.PropsSI('H','T',T1,'Q',Q1,F);
s1=py.CoolProp.CoolProp.PropsSI('S','T',T1,'Q',Q1,F);

% Point 3 - Known temperature and quality can calculate other values needed
P3=py.CoolProp.CoolProp.PropsSI('P','T',T3,'Q',Q3,F);
h3=py.CoolProp.CoolProp.PropsSI('H','T',T3,'Q',Q3,F);
s3=py.CoolProp.CoolProp.PropsSI('S','T',T3,'Q',Q3,F);

% Point 4 - Thermodynamic reationships known

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

% For the next cycle to begin, a new value of h1 needs to be calculated using a calculated Qin (kW) value.

Qin=(GHEL*((Ts-T4)/GHER))/1000;

% Then using the equation Qin = Mr*(h1 - h4) and rearranging to make h1 the
% subject, this h1 value is the new value for the start of the next cycle
% h1n (h1 new).
h1n=(Qin/Mr)+h4;

% The Ideal Reversed Carnot Cycle is then repeated using the same method as previously stated but with heat energy being added through the h1n value %
% As it is assumed that the temperature of position 4 and 1 is constant, the enthalpy of the system changes %
% As the soil temperature is greater than that of the working fluid, the working fluid gains energy in the form of increased enthalpy %

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
% COPn is the value of COP calculated for each Ts value input to the system
COPn=Qout/Winn;

%xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx%

%
%
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
