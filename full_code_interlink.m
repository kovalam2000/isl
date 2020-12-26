
% STUDY OF THE INTERLINK BETWEEN SMALL SATELLITES IN A CONSTELLATION 
% Author: David Puig Puig? david.puig.puig@estudiant.upc.edu 
% Director: Miquel Sureda Anfres 
% ESEIAAT? UPC 

% Visual contact for two satellites analysis 

% Reminder: All times are in UTC 

%% Menu module 

% Introduction and information 

input tle list = f'Author: David Puig', 'Director: Miquel Sureda'; 'ESEIAAT? UPC'g;

[indx,tf] = listdlg('ListString',input tle list,'Name';'InterLink';'PromptString';'This tool is used to analyse visibility windows in satellite constellations';... 
'SelectionMode';'single';'ListSize';[500;300],'OKString';'Next';'CancelString';'Quit'); 

if tf == 0 
disp('User selected Quit'); 

return 
end 

%% Input Parameters module 

% Input Celestial Object System 

input tle list = f'Earth', 'Other'g; 
[indx,tf] = listdlg('ListString',input tle 

list,'Name';'Celestial Object System';'PromptString';'Select your analysis system:';... 
'SelectionMode';'single';'ListSize';[500,300],'OKString';'Next';'CancelString';'Quit'); 

if tf == 0 
disp('User selected Quit'); 

return 
end 

% Common System Parameters 

global mu; 
k = 2*pi; % Factor from [rev/s] to [rad/s] 

if indx == 1 

% Earth System parameters 
body radius = 6.378e6; % Radius of the primary body [m] 
extra radius = 20000; % Extra radius for the primary body [m] 
S = body radius + extra radius; % Magnitude of the rise?set vector [m] 
mu = 3.986004418e14; % Standard gravitational parameter [mˆ3/sˆ2] 

else 

% Other system parameters 

prompt = f'Primary body radius [m]:', 'Extra radius (atmosphere and other effects) [m]:', 'Mu parameter [mˆ3/sˆ2]:'g; 
dlgtitle = 'Celestial Object System'; 
dims = [1 70; 1 70; 170]; 
system answer = inputdlg(prompt,dlgtitle,dims); 
body radius = str2double(system answerf1g); % Radius of the primary body [m] 
extra radius = str2double(system answerf2g); % Extra radius for the primary body [m] 
S = body radius + extra radius; % Magnitude of the rise?set vector [m] 
mu = str2double(system answerf1g); % Standard gravitational parameter [mˆ3/sˆ2] 

end 

% TLE input menu 

input tle list = f'Examples', 'From .txt file (without blank lines between set)', 'Paste'g; 
[indx,tf] = listdlg('ListString',input tle list,'Name','Two Line Element (TLE)','PromptString','Select a TLE input mode:',... 
'SelectionMode','single','ListSize',[500,300],'OKString','Next','CancelString','Quit'); 

if tf == 0 
disp('User selected Quit'); 

return 
end 

if indx == 1 
input examples list = f'EGYPTSAT 1', 'TRMM', 'GOES 3', 'NOAA 3', 'NAVSTAR 46'g; 
[indx,tf] = listdlg('ListString',input examples list,'Name','Two Line Element (TLE)','PromptString','Select two or more TLE to analyse:',... 

'SelectionMode','multiple','ListSize',[500,300],'OKString','Run','CancelString','Quit'); 

% Hard?Coded TLE as input examples 

possible example answers = ff'EGYPTSAT 1 '; 
'1 31117U 07012A 08142.74302347 .00000033 00000?0 13654?4 0 2585 '; 
'2 31117 098.0526 218.7638 0007144 061.2019 298.9894 14.69887657 58828'g; 
f'TRMM '; 
'1 25063U 97074A 08141.84184490 .00002948 00000?0 41919?4 0 7792 '; 
'2 25063 034.9668 053.5865 0001034 271.1427 088.9226 15.55875272598945'g; 
f'GOES 3 '; 
'1 10953U 78062A 08140.64132336?.00000110 00000?0 10000?3 0 1137 '; 
'2 10953 014.2164 003.1968 0001795 336.4858 023.4617 01.00280027 62724'g; 
f'NOAA 3 '; 
'1 06920U 73086A 08141.92603915?.00000030 00000?0 +10000?3 0 00067 '; 
'2 06920 101.7584 171.9430 0006223 187.3360 172.7614 12.40289355563642'g; 
f'NAVSTAR 46 '; 
'1 25933U 99055A 08142.14123352 .00000019 00000?0 10000?3 0 00126 '; 
'2 25933 051.0650 222.9439 0079044 032.8625 327.6958 02.00568102 63184'g; 
f'EGYPTSAT 1 '; 
'1 31117U 07012A 08142.74302347 .00000033 00000?0 13654?4 0 2585 '; 
'2 31117 098.0526 218.7638 0007144 061.2019 298.9894 14.69887657 58828'gg; 

if tf == 0 
disp('User selected Quit'); 

return 
end 

if size(indx) == 1 
CreateStruct.Interpreter = 'tex'; 
CreateStruct.WindowStyle = 'modal'; 
msgbox('A minimum of two TLE set are needed to compute visibility','Error',CreateStruct); 

return 
else 

% TLE variables extraction 

selected example answers = cell(1,1); 
count=1; 
for i=1:size(indx,2) 

for j=1:3 
selected example answersf1gfcount,1} 
= possible example 

answersfindx(i),1gfjg; 
count=count+1; 

end 
end 

1 



CHAPTER 
1. 
MATLAB 
CODE 


% Find the total number of satellites in the file 

num satellites = size(indx,2); 

% Initialize array 

sat id line = zeros(1,num 

satellites); 
line count = 1; 
for i=1:num 

satellites 

% Take every 3rd line 

sat id line(i) = line count; 
txt data = textscan(selected example answersf1gfline count,1g,'%s %s %s %s %s %s %s %s %s'); 

OrbitData.ID(i) = txt dataf1g; 
if isempty(txt 

dataf2g) 
OrbitData.designation(i) = f''g; 

else 

OrbitData.designation(i) = txt dataf2g; 

end 

if isempty(txt 

dataf3g) 
OrbitData.PRN(i) = f''g; 

else 

OrbitData.PRN(i) = txt dataf3g; 

end 

% Jump to the next Satellite Name line 

line count = line count + 3; 

end 

% Find the two lines corresponding to the spacecraft in question 

for j=1:length(sat 

id 

line) 

% Find the first line of the first satellite 

index = sat id 

line(j); 
txt data second = textscan(selected example 

answersf1gfindex+2,1g,'%s %s %s %s %s %s %s %s %s'); 

% Translate two line element data into obital elements 
OrbitData.i(j) = str2double(txt data secondf1,3g)*(pi/180); % Inclination [deg] to [rad] 
OrbitData.RAAN(j) = str2double(txt data secondf1,4g)*(pi/180); % Right ascention of the ascending node[deg] to [rad] 
OrbitData.omega(j) = str2double(txt data secondf1,6g)*(pi/180); % Argument of the periapsis [deg] to [rad] 
OrbitData.M(j) = str2double(txt data secondf1,7g)*(pi/180); % Mean anomaly [deg] to [rad] 
n = str2double(txt data secondf1,8g); % Unperturbed mean motion [rev/day] 
OrbitData.n(j) = n*2*pi/24/60/60; % Unperturbed mean motion [rad/s] 
OrbitData.a(j) = ( mu / OrbitData.n(j)ˆ2 )ˆ(1/3); % Semi?major axis [m] 
OrbitData.e(j) = str2double(txt data secondf1,5g)*1e?7; % Eccentricity [unitless] 

% Compute the UTC date / time 

txt data first = textscan(selected 

example 

answersf1gfindex+1,1g,'%s %s %s %s %s %s %s %s %s'); 
temp2 = txt data 

firstf1,4g; 
yy = str2double(temp2f1g(1:2)); 
yyyy = 2000 + yy; 
start = datenum([yyyy 0 0 0 0 0]); 
secs = str2double(temp2f1g(3:length(temp2f1g)))*24*3600; 
date1 = datevec(addtodate(start,floor(secs),'second')); 
remainder = [0 0 0 0 0 mod(secs,1)]; 
OrbitData.datefj} 
= datestr(date1+remainder,'dd?mmm?yyyy HH:MM:SS.FFF'); 

% Compute ballistic coefficient in SI units 

temp3 = txt data 

firstf1,7g; 

if length(temp3f1g)== 7 
base = str2double(temp3f1g(1:5)); 
expo = str2double(temp3f1g(6:7)); 

elseif length(temp3f1g)== 8 
base = str2double(temp3f1g(2:6)); 
expo = str2double(temp3f1g(7:8)); 

else 

fprintf('Error in ballistic coefficient calculationnn') 
CreateStruct.Interpreter = 'tex'; 
CreateStruct.WindowStyle = 'modal'; 
msgbox('Error in ballistic coefficient calculationnn','Error',CreateStruct); 
error('End program') 

end 

OrbitData.Bstar(j) = base*1e?5*10ˆexpo; 
OrbitData.BC(j) = 1/12.741621/OrbitData.Bstar(j); 

end 
end 

elseif indx == 2 

[file,path] = uigetfile('*.txt'); 

if isequal(file,0) 
disp('User selected Cancel'); 

return 

else 

disp(['User selected ', fullfile(path,file)]); 

% TLE file name and variables extraction 

fid input = fopen(fullfile(path,file)); 
txt data = textscan(fid 

input,'%s %s %s %s %s %s %s %s %s'); 

% Find the total number of satellites in the file 

num satellites = length(txt dataf1g)/3; 

% Initialize array 

sat id line = zeros(1,num 

satellites); 
line count = 1; 
for i=1:num 

satellites 

% Take every 3rd line 

sat id line(i) = line count; 

OrbitData.ID(i) = txt dataf1g(line count); 
if isempty(txt 

dataf2g(line 

count)) 
OrbitData.designation(i) = f''g; 

else 

OrbitData.designation(i) = txt dataf2g(line count); 

end 

if isempty(txt 

dataf3g(line 

count)) 
OrbitData.PRN(i) = f''g; 

else 

OrbitData.PRN(i) = txt dataf3g(line 

count); 

end 

% Jump to the next Satellite Name line 

line count = line count + 3; 

end 

% Find the two lines corresponding to the spacecraft in question 

for j=1:length(sat 

id 

line) 

% Find the first line of the first satellite 

index = sat id 

line(j); 

% Translate two line element data into obital elements 
OrbitData.i(j) = str2double(txt dataf1,3gfindex+2g)*(pi/180); % Inclination [deg] to [rad] 
OrbitData.RAAN(j) = str2double(txt dataf1,4gfindex+2g)*(pi/180); % Right ascention of the ascending node[deg] to [rad] 
OrbitData.omega(j) = str2double(txt dataf1,6gfindex+2g)*(pi/180); % Argument of the periapsis [deg] to [rad] 
OrbitData.M(j) = str2double(txt dataf1,7gfindex+2g)*(pi/180); % Mean anomaly [deg] to [rad] 
n = str2double(txt dataf1,8gfindex+2g); % Unperturbed mean motion [rev/day] 
OrbitData.n(j) = n*2*pi/24/60/60; % Unperturbed mean motion [rad/s] 

2 



CHAPTER 
1. 
MATLAB 
CODE 


OrbitData.a(j) = ( mu / OrbitData.n(j)ˆ2 )ˆ(1/3); % Semi?major axis [m] 
OrbitData.e(j) = str2double(txt dataf1,5gfindex+2g)*1e?7; % Eccentricity [unitless] 

% Compute the UTC date / time 

temp2 = txt dataf1,4gfindex+1g; 
yy = str2double(temp2(1:2)); 
yyyy = 2000 + yy; 
start = datenum([yyyy 0 0 0 0 0]); 
secs = str2double(temp2(3:length(temp2)))*24*3600; 
date1 = datevec(addtodate(start,floor(secs),'second')); 
remainder = [0 0 0 0 0 mod(secs,1)]; 
OrbitData.datefj} 
= datestr(date1+remainder,'dd?mmm?yyyy HH:MM:SS.FFF'); 

% Compute ballistic coefficient in SI units 

temp3 = txt dataf1,7gfindex+1g; 

if length(temp3) == 7 
base = str2double(temp3(1:5)); 
expo = str2double(temp3(6:7)); 

elseif length(temp3) == 8 
base = str2double(temp3(2:6)); 
expo = str2double(temp3(7:8)); 

else 

fprintf('Error in ballistic coefficient calculationnn') 
CreateStruct.Interpreter = 'tex'; 
CreateStruct.WindowStyle = 'modal'; 
msgbox('Error in ballistic coefficient calculationnn','Error',CreateStruct); 
error('end program') 

return 
end 

OrbitData.Bstar(j) = base*1e?5*10ˆexpo; 
OrbitData.BC(j) = 1/12.741621/OrbitData.Bstar(j); 

end 
end 

elseif indx == 3 

prompt = 'How many TLE do you want to analyse?'; 
dlgtitle = 'Paste TLE'; 
dims = [1 69]; 
tle num answer = inputdlg(prompt,dlgtitle,dims); 

if isempty(tle 

num 

answer) 
disp('User selected Cancel'); 

return 
end 

number of tle = str2double(tle 

num 

answer); 

if number 

of 

tle< 
2 
CreateStruct.Interpreter = 'tex'; 
CreateStruct.WindowStyle = 'modal'; 
msgbox('A minimum of two TLE set are needed to compute visibility','Error',CreateStruct); 

return 
end 

prompt = sprintf('Enter %d sets of TLE without blank lines between set:', number of tle); 
dlgtitle = 'Paste TLE'; 
dims = [3*number of tle 69]; 
tle pasted answer = inputdlg(prompt,dlgtitle,dims); 

if isempty(tle pasted 

answer) 
disp('User selected Cancel'); 

return 
end 

% TLE variables extraction 

% Find the total number of satellites in the file 

num satellites = str2double(tle num 

answer); 

% Initialize array 

sat id line = zeros(1,num 

satellites); 
line count = 1; 
for i=1:num 

satellites 

% Take every 3rd line 

sat id line(i) = line 

count; 
txt data = textscan(tle pasted 

answerf1g(line count,1:69),'%s %s %s %s %s %s %s %s %s'); 

OrbitData.ID(i) = txt dataf1g; 
if isempty(txt 

dataf2g) 
OrbitData.designation(i) = f''g; 

else 

OrbitData.designation(i) = txt dataf2g; 

end 

if isempty(txt 

dataf3g) 
OrbitData.PRN(i) = f''g; 

else 

OrbitData.PRN(i) = txt dataf3g; 

end 

% Jump to the next Satellite Name line 

line count = line count + 3; 

end 

% Find the two lines corresponding to the spacecraft in question 

for j=1:length(sat 

id 

line) 

% Find the first line of the first satellite 

index = sat id 

line(j); 
txt data second = textscan(tle 

pasted 

answerf1g(index+2,1:69),'%s %s %s %s %s %s %s %s %s'); 

% Translate two line element data into obital elements 
OrbitData.i(j) = str2double(txt data secondf1,3g)*(pi/180); % Inclination [deg] to [rad] 
OrbitData.RAAN(j) = str2double(txt data secondf1,4g)*(pi/180); % Right ascention of the ascending node[deg] to [rad] 
OrbitData.omega(j) = str2double(txt data secondf1,6g)*(pi/180); % Argument of the periapsis [deg] to [rad] 
OrbitData.M(j) = str2double(txt data secondf1,7g)*(pi/180); % Mean anomaly [deg] to [rad] 
n = str2double(txt data secondf1,8g); % Unperturbed mean motion [rev/day] 
OrbitData.n(j) = n*2*pi/24/60/60; % Unperturbed mean motion [rad/s] 
OrbitData.a(j) = ( mu / OrbitData.n(j)ˆ2 )ˆ(1/3); % Semi?major axis [m] 
OrbitData.e(j) = str2double(txt data secondf1,5g)*1e?7; % Eccentricity [unitless] 

% Compute the UTC date / time 

txt data first = textscan(tle 

pasted 

answerf1g(index+1,1:69),'%s %s %s %s %s %s %s %s %s'); 
temp2 = txt data 

firstf1,4g; 
yy = str2double(temp2f1g(1:2)); 
yyyy = 2000 + yy; 
start = datenum([yyyy 0 0 0 0 0]); 
secs = str2double(temp2f1g(3:length(temp2f1g)))*24*3600; 
date1 = datevec(addtodate(start,floor(secs),'second')); 
remainder = [0 0 0 0 0 mod(secs,1)]; 
OrbitData.datefj} 
= datestr(date1+remainder,'dd?mmm?yyyy HH:MM:SS.FFF'); 

% Compute ballistic coefficient in SI units 

temp3 = txt data 

firstf1,7g; 

if length(temp3f1g)== 7 
base = str2double(temp3f1g(1:5)); 
expo = str2double(temp3f1g(6:7)); 

elseif length(temp3f1g)== 8 
base = str2double(temp3f1g(2:6)); 

3 



CHAPTER 
1. 
MATLAB 
CODE 


384 
expo = str2double(temp3f1g(7:8)); 

else 

386 
fprintf('Error in ballistic coefficient calculationnn') 
387 
CreateStruct.Interpreter = 'tex'; 
388 
CreateStruct.WindowStyle = 'modal'; 
389 
msgbox('Error in ballistic coefficient calculationnn','Error',CreateStruct); 

error('End program') 
391 
end 
392 
393 
OrbitData.Bstar(j) = base*1e?5*10ˆexpo; 
394 
OrbitData.BC(j) = 1/12.741621/OrbitData.Bstar(j); 

396 
end 
397 
398 
end 
399 


% Simulation Parameters menu 

401 
402 
input 

simulation list = f'From Now to Tomorrow (24h simulation) and 500 time divisions', 'Other'g; 
403 
[indx,tf] = listdlg('ListString',input simulation list,'Name','Simulation Time','PromptString','Select a UTC time for your analysis:',... 
404 
'SelectionMode','single','ListSize',[500,300],'OKString','Next','CancelString','Quit'); 

406 
if tf == 0 
407 
disp('User selected Quit'); 
408 
return 
409 
end 

411 
disp('Starting InterLink...') 
412 
413 
if indx == 1 
414 
% Simulation Parameters 

start time = '22?May?2008 12:00:00'; 
416 
%start time = datetime('now', 'TimeZone', 'UTC'); 
417 
418 
start time unix = posixtime(datetime(start 

time)); 
419 
fprintf('Conversion of the simulation start time: %s is %d in Unix timenn', start 

time, start 

time 

unix); % Command window print 
start time to log = sprintf('Conversion of the simulation start time: %s is %d in Unix time', start time, start time unix); 
421 
t = start time unix; % Start simulation time in Unix ... 
time [s] 

422 
423 
end time = '23?May?2008 00:00:00'; 
424 
%end 

time = datetime('now', 'TimeZone', 'UTC') + days(1); 

426 
end time unix = posixtime(datetime(end 

time)); 
427 
fprintf('Conversion of the simulation end time: %s is %d in Unix timenn', end 

time, end 

time 

unix); % Command window print 
428 
end time to log = sprintf('Conversion of the simulation end time: %s is %d in Unix time', end time, end time 

unix); 
429 
t end = end time unix; % End of simulation time in Unix ... 
time [s] 

431 
time divisions = 1000; %4320 is every 10 seconds for a 12h simulation 
432 
433 
else 
434 
prompt = f'Simulation start:', 'Simulation end:', 'Time divisons (steps):'g; 

dlgtitle = 'Simulation Time. Example: 22?Jan?2019 13:22:22'; 
436 
dims = [1 70; 1 70; 1,70]; 
437 
simulation answer = inputdlg(prompt,dlgtitle,dims); 
438 
start 

time = simulation answerf1g; 
439 
end 

time = simulation answerf2g; 
time divisions = round(str2double(simulation answerf3g)); 

441 
442 
start time unix = posixtime(datetime(start 

time)); 
443 
fprintf('Conversion of the simulation start time: %s is %d in Unix timenn', start 

time, start 

time 

unix); % Command window print 
444 
start time to log = sprintf('Conversion of the simulation start time: %s is %d in Unix time', start time, start time 

unix); 
t = start time unix; % Start simulation time in Unix ... 
time [s] 

446 
end time unix = posixtime(datetime(end 

time)); 
447 
fprintf('Conversion of the simulation end time: %s is %d in Unix timenn', end 

time, end 

time 

unix); % Command window print 
448 
end time to log = sprintf('Conversion of the simulation end time: %s is %d in Unix time', end time, end time 

unix); 
449 
t end = end time unix; % End of simulation time in Unix ... 
time [s] 

451 
end 
452 
453 
increment = (end time unix?start time unix)/time divisions; % Time increment [s] 
454 
num 

steps = time divisions+1; % Number of time steps 

456 
% Satellite orbit parameters 
457 
458 
for i=1:num satellites 
459 
OrbitData.epoch(i) = posixtime(datetime(char(OrbitData.date(i)))); 

OrbitData.T(i) = OrbitData.epoch(i)?OrbitData.M(i)/OrbitData.n(i); 
461 
OrbitData.q(i) = OrbitData.a(i)*(1?OrbitData.e(i)); 
462 
end 
463 
464 
num 

pairs=0; 
for sat1=1:num 

satellites?1 
466 
for sat2=sat1+1:num satellites 
467 
num 

pairs = num pairs +1; 
468 
end 
469 
end 

471 
% Preallocated variables 
472 
for i=1:num satellites 
473 
n = zeros(1, num satellites); % Unperturbed mean motion [rad/s] 
474 
M = zeros(1, num satellites); % Mean anomaly [rad] 

Fn = zeros(1, num satellites); % Eccentric anomaly from Kepler's Equation for hyperbolic orbit (n) [rad] 
476 
Fn1 = zeros(1, num satellites); % Eccentric anomaly from Kepler's Equation for hyperbolic orbit (n+1) [rad] 
477 
f = zeros(1, num satellites); % True Anomaly [rad] 
478 
A = zeros(1, num satellites); % Barker's Equation parameter 
479 
B = zeros(1, num satellites); % Barker's Equation parameter 

C = zeros(1, num satellites); % Barker's Equation parameter 
481 
En = zeros(1, num satellites); % Eccentric anomaly from Kepler's Equation (n) [rad] 
482 
En1 = zeros(1, num satellites); % Eccentric anomaly from Kepler's Equation (n+1) [rad] 
483 
Px = zeros(1, num satellites); % First component of the unit orientation vector (dynamical center?periapsis) [m] 
484 
Py = zeros(1, num satellites); % Second component of the unit orientation vector (dynamical center?periapsis) [m] 

Pz = zeros(1, num satellites); % Third component of the unit orientation vector (dynamical center?periapsis) [m] 
486 
Qx = zeros(1, num satellites); % First component of the unit orientation vector (advanced to P by a right angle in the ... 
motion direction) [m] 
487 
Qy = zeros(1, num satellites); % Second component of the unit orientation vector (advanced to P by a right angle in the ... 
motion direction) [m] 
488 
Qz = zeros(1, num satellites); % Third component of the unit orientation vector (advanced to P by a right angle in the ... 
motion direction) [m] 
489 
r = zeros(1, num satellites); % Magnitude of the vector from the center of the primary body to the satellite [m] 

xi = zeros(1, num satellites); % Component of r vector in the periapsis line [m] 
491 
eta = zeros(1, num satellites); % Component of r vector in the descending node line [m] 
492 
r 

fullvector = [0 0 0]; % Intermediate vector to store the pair of r vectors [m] 
493 
r 

vector = zeros(num satellites, 3); % Vector from the center of the primary body to the satellite [m] 
494 
parameter = zeros(1, num satellites); % Semi?parameter of the orbit [m] 

Rsimple1 = 0; % Visibility parameter [m] 
496 
Rsimple2 = 0; % Visibility parameter [m] 
497 
Rcomplex = zeros(num steps, num pairs); % Visibility parameter [m] 
498 
Rangle = 0; % Visibility parameter [m] 
499 
Rv = 0; % Distance from earth to satellite?satellite line [m] 

csv data = cell(num steps, 27, 2, num pairs); % Array of matrix to store relevant data 
501 
WindowsData = struct('start', zeros(num satellites, num satellites, 1000), 'end', zeros(num satellites, num satellites, 1000), 'time', zeros(num satellites, ... 
num satellites, 1000)); 
502 
WindowsDataFirst = struct('start', zeros(num satellites, num satellites, 10), 'end', zeros(num satellites, num satellites, 10), 'time', zeros(num satellites, ... 

num satellites, 10)); 
503 
end 
504 


%% Log file module 

506 
507 
prompt = 'Name this analysis: Log file format will be yyyymmddHHMMSS?Name.txt'; 

4 



CHAPTER 
1. 
MATLAB 
CODE 


508 
dlgtitle = 'Log file name'; 
509 
dims = [1 69]; 
name log = inputdlg(prompt,dlgtitle,dims); 
511 
512 
if isempty(name log) 
513 
disp('User selected Cancel'); 
514 
return 
end 
516 
517 
date log = datestr(now,'yyyymmddHHMMSS'); 
518 
519 
full name log = sprintf('%s?%s.txt',date log,name logf1g); 
fopen(fullfile([pwd, '/logs'], full name log), 'w'); % Create log file overwriting old one 
521 
fid log = fopen(fullfile([pwd, '/logs'], full name log), 'a'); % Setting log file to append mode 
522 
if fid log == ?1 
523 
error('Cannot open log file.'); 
524 
end 
526 
fprintf(fid log, '%s: %snn', datestr(datetime('now', 'TimeZone', 'UTC')), 'Starting InterLink...'); 
527 
fprintf(fid log, '%s: %snn', datestr(datetime('now', 'TimeZone', 'UTC')), start time to log); % Appending simulation start time to log file 
528 
fprintf(fid log, '%s: %snn', datestr(datetime('now', 'TimeZone', 'UTC')), end time to log); % Appending simulation end time to log file 
529 
fprintf(fid log, '%s: %snn', datestr(datetime('now', 'TimeZone', 'UTC')), 'TLE data collected. Format: ID?designation?PRN?i?RAAN?omega?M?n?a?e?date?BC?epoch?T?q'); % ... 
Log file print 
for i=1:num satellites 
531 
532 
tle log print = strcat(OrbitData.IDfig,'?',OrbitData.designationfig,'?',OrbitData.PRNfig,'?',num2str(OrbitData.i(i)),'?',num2str(OrbitData.RAAN(i)),'?',... 
num2str(OrbitData.omega(i)),'?',num2str(OrbitData.M(i)),'?',num2str(OrbitData.n(i)),'?',num2str(OrbitData.a(i)),'?',num2str(OrbitData.e(i)),'?',... 
533 
534 
OrbitData.datefig,'?',num2str(OrbitData.BC(i)),'?',num2str(OrbitData.epoch(i)),'?',num2str(OrbitData.T(i)),'?',num2str(OrbitData.q(i))); 
fprintf(fid log, '%s: %snn', datestr(datetime('now', 'TimeZone', 'UTC')), tle log print); % Log file print 
536 
end 
537 
disp('TLE data collected:'); % Command window print 
538 
disp(OrbitData); % Command window print 
539 
% Print TLE parameters in command window 
541 
542 
% Log file is closed with "fclose" function once the algorithm is ended 
543 
544 
%% Populate CSV with TLE and Simulation Data 
546 
for m=1:num satellites 
547 
548 
current sat name = strcat(OrbitData.IDfmg,OrbitData.designationfmg); 
if m == 1 
549 
all sat names = current sat name; 
else 
551 
all sat names = strcat(all sat names,'?',current sat name); 
552 
end 
553 
end 
554 
num pairs = 0; 
556 
for sat1=1:num satellites?1 
557 
for sat2=sat1+1:num satellites 
558 
num pairs = num pairs + 1; 
559 
for i=1:num steps 
j = sat1; 
561 
for x=1:2 
562 
563 
564 
566 
567 
568 
569 
571 
csv datafi,1,j,num pairs} 
= full name log; 
csv datafi,2,j,num pairs} 
= 'Visibility Analysis'; 
csv datafi,7,j,num pairs} 
= num2str(num satellites); 
csv datafi,8,j,num pairs} 
= all sat names; 
csv datafi,11,j,num pairs} 
= strcat(OrbitData.IDfjg,OrbitData.designationfjg); 
csv datafi,12,j,num pairs} 
= OrbitData.PRNfjg; 
csv datafi,20,j,num pairs} 
= OrbitData.datefjg; 
csv datafi,21,j,num pairs} 
= OrbitData.Bstar(j); 
csv datafi,22,j,num pairs} 
= OrbitData.BC(j); 
j = sat2; 
572 
end 
573 
end 
574 
end 
end 
576 
577 
%% 3D Visuals module 
578 
579 
% Add path to the Earth plotting function and TLE data preparation 
addpath([pwd, 'nPlot Earth']); 
581 
addpath([pwd, 'nTLE Plotter']); 
582 
583 
% Simulation Start Date 
584 
simStart = start time; 
586 
% Compute sidereal time 
587 
GMST = utc2gmst(datevec(simStart)); % [rad] 
588 
589 
% Create a time vector 
tSim = linspace(start time unix, end time unix, num steps); 
591 
592 
% Allocate space 
593 
RSave = NaN(length(tSim), 3, num satellites); 
594 
%% Visibility Algorithm 
596 
597 
addpath([pwd, 'nSGP4']); 
598 
599 
OrbitDataProp = OrbitData; 
601 
num pairs = 0; 
602 
603 
tic; % Runtime start 
604 
for sat1=1:num satellites?1 
606 
607 
for sat2=sat1+1:num satellites 
608 
609 
num pairs= num pairs + 1; 
611 
num windows = 0; 
612 
613 
step count=1; 
614 
for t=t:increment:t end % Simulation time and time discretization 
616 
617 
% Time since the simulation started 
618 
tsince = (t? 
start time unix)/60; % from [s] to [min] for sgp4 function 
619 
i = sat1; 
621 
for x=1:2 
622 
623 
[pos, vel, OrbitDataProp] = sgp4(tsince, OrbitData, i); 
624 
OrbitDataProp.a(i) = ( mu / OrbitDataProp.n(i)ˆ2 )ˆ(1/3); 
OrbitDataProp.q(i) = OrbitDataProp.a(i)*(1?OrbitDataProp.e(i)); 
626 
627 
% Step 1? 
Finding unperturbed mean motion 
628 
if OrbitDataProp.e(i) 0 
629 
n(i) = OrbitDataProp.n(i); 
else 
631 
error('Eccentricity cannot be a negative value') 
632 
end 
633 
634 
% Step 2? 
Solving Mean Anomaly 
M(i) = n(i)*(t?OrbitData.T(i)); 
636 
637 
% Step 3? 
Finding true anomaly 
638 
if OrbitDataProp.e(i)> 
1 

5 



CHAPTER 
1. 
MATLAB 
CODE 


639 
Fn(i) = 6*M(i); 

error = 1; 
641 
while error> 
1e?8 
642 
Fn1(i) = Fn(i) + (M(i)?OrbitDataProp.e(i)*sinh(Fn(i))+Fn(i))/(OrbitDataProp.e(i)*cosh(Fn(i))?1); 
643 
error = abs(Fn1(i)?Fn(i)); 
644 
Fn(i) = Fn1(i); 

end 

646 
647 
f(i) = atan((?sinh(Fn(i))*sqrt(OrbitDataProp.e(i)ˆ2?1))/(cosh(Fn(i))?OrbitDataProp.e(i))); 
648 
649 
elseif OrbitDataProp.e(i) == 1 

A(i) = (3/2)*M(i); 
651 
B(i) = (sqrt(A(i)ˆ2+1)+A(i))ˆ(1/3); 
652 
C(i) = B(i)?1/B(i); 
653 
f(i) = 2*atan(C(i)); 
654 


elseif OrbitDataProp.e(i)< 
1 && OrbitDataProp.e(i) 0 
656 
% Convert mean anomaly to true anomaly. 
657 
% First, compute the eccentric anomaly. 
658 
Ea = Keplers 

Eqn(M(i),OrbitDataProp.e(i)); 

659 


% Compute the true anomaly f. 

661 
y = sin(Ea)*sqrt(1?OrbitDataProp.e(i)ˆ2)/(1?OrbitDataProp.e(i)*cos(Ea)); 
662 
z = (cos(Ea)?OrbitDataProp.e(i))/(1?OrbitDataProp.e(i)*cos(Ea)); 
663 
664 
f(i) = atan2(y,z); 

666 
else 
667 
error('Eccentricity cannot be a negative value') 
668 
end 
669 


% Step 4? 
Finding primary body center to satellite distance 

671 
r(i) = (1+OrbitDataProp.e(i))*OrbitDataProp.q(i)/(1+OrbitDataProp.e(i)*cos(f(i))); 
672 
673 
% Step 5? 
Finding standard orientation vectors 
674 
Px(i) = cos(OrbitDataProp.omega(i))*cos(OrbitDataProp.RAAN(i))?sin(OrbitDataProp.omega(i))*sin(OrbitDataProp.RAAN(i))*cos(OrbitDataProp.i(i)); 

Py(i) = cos(OrbitDataProp.omega(i))*sin(OrbitDataProp.RAAN(i))+sin(OrbitDataProp.omega(i))*cos(OrbitDataProp.RAAN(i))*cos(OrbitDataProp.i(i)); 
676 
Pz(i) = sin(OrbitDataProp.omega(i))*sin(OrbitDataProp.i(i)); 
677 
Qx(i) =?sin(OrbitDataProp.omega(i))*cos(OrbitDataProp.RAAN(i))+cos(OrbitDataProp.omega(i))*sin(OrbitDataProp.RAAN(i))*cos(OrbitDataProp.i(i)); 
678 
Qy(i) =?sin(OrbitDataProp.omega(i))*sin(OrbitDataProp.RAAN(i))+cos(OrbitDataProp.omega(i))*cos(OrbitDataProp.RAAN(i))*cos(OrbitDataProp.i(i)); 
679 
Qz(i) = cos(OrbitDataProp.omega(i))*sin(OrbitDataProp.i(i)); 

681 
% Step 6? 
Finding components of the primary body center to satellite vector in the orbital plane 
682 
xi(i) = r(i)*cos(f(i)); 
683 
eta(i) = r(i)*sin(f(i)); 
684 


% Step 7? 
Finding primary body center to satellite vector 

686 
r fullvector = xi(i)*[Px(i) Py(i) Pz(i)] + eta(i)*[Qx(i) Qy(i) Qz(i)]; 
687 
for j=1:3 
688 
r vector(i,j) = r fullvector(j); 
689 
end 

691 
% Step 8? 
Finding Parameter or Semi?parameter 
692 
parameter(i) = OrbitDataProp.a(i)*(1?OrbitDataProp.e(i)ˆ2); 
693 
694 
% Step 9? 
Transformation for 3D visuals 

% Adjust RAAN such that we are consisten with Earth's current 
696 
% orientation. This is a conversion to Longitude of the 
697 
% Ascending Node (LAN). 
698 
RAAN2 = OrbitDataProp.RAAN(i)? 
GMST; 
699 


% Convert to ECI and save the data. 

701 
[X,:] = COE2RV(OrbitDataProp.a(i), OrbitDataProp.e(i), OrbitDataProp.i(i), RAAN2, OrbitDataProp.omega(i), M(i)); 
702 
RSave(step count,:,i) = X'; 
703 
704 
% CSV insertion 

csv 

datafstep count,13,i,num 

pairs} 
= OrbitDataProp.i(i); 
706 
csv 

datafstep count,14,i,num 

pairs} 
= OrbitDataProp.RAAN(i); 
707 
csv 

datafstep count,15,i,num 

pairs} 
= OrbitDataProp.omega(i); 
708 
csv 

datafstep count,16,i,num 

pairs} 
= M(i); 
709 
csv 

datafstep count,17,i,num 

pairs} 
= OrbitDataProp.n(i); 
csv 

datafstep count,18,i,num 

pairs} 
= OrbitDataProp.a(i); 
711 
csv 

datafstep count,19,i,num 

pairs} 
= OrbitDataProp.e(i); 
712 
csv 

datafstep count,23,i,num 

pairs} 
= f(i); 
713 
csv 

datafstep count,24,i,num 

pairs} 
= xi(i); 
714 
csv 

datafstep count,25,i,num 

pairs} 
= eta(i); 
csv 

datafstep count,26,i,num 

pairs} 
= parameter(i); 
716 
csv 

datafstep count,27,i,num 

pairs} 
= r(i); 

717 
718 
i = sat2; 
719 
end 

721 
% Step 10? 
Solving visibility equation 
722 
723 
P1 = [Px(sat1) Py(sat1) Pz(sat1)]; 
724 
P2 = [Px(sat2) Py(sat2) Pz(sat2)]; 

Q1 = [Qx(sat1) Qy(sat1) Qz(sat1)]; 
726 
Q2 = [Qx(sat2) Qy(sat2) Qz(sat2)]; 
727 
A1 = dot(P1,P2); 
728 
A2 = dot(Q1,P2); 
729 
A3 = dot(P1,Q2); 

A4 = dot(Q1,Q2); 

731 
732 
sin gamma = A2/sqrt(A1ˆ2+A2ˆ2); 
733 
cos gamma = A1/sqrt(A1ˆ2+A2ˆ2); 
734 
sin psi = A4/sqrt(A3ˆ2+A4ˆ2); 

cos psi = A3/sqrt(A3ˆ2+A4ˆ2); 

736 
737 
D1 = sqrt(A1ˆ2+A2ˆ2); 
738 
D2 = sqrt(A3ˆ2+A4ˆ2); 
739 


r1dotr2complex = (parameter(sat1)*parameter(sat2)/((1+OrbitDataProp.e(sat1)*cos(f(sat1)))*(1+OrbitDataProp.e(sat2)*cos(f(sat2)))))* ... 
741 
(D1*cos(f(sat2))*(cos 

gamma*cos(f(sat1))+sin 

gamma*sin(f(sat1)))+D2*sin(f(sat2))*(cos 

psi*cos(f(sat1))+sin 

psi*sin(f(sat1)))); 
742 
Rcomplex(step count, num pairs) = parameter(sat1)ˆ2 * parameter(sat2)ˆ2 * ( D1*cos(f(sat2))*(cos gamma*cos(f(sat1))+sin gamma*sin(f(sat1))) + ... 
743 
D2*sin(f(sat2))*(cos 

psi*cos(f(sat1))+sin 

psi*sin(f(sat1))) )ˆ2? 
parameter(sat1)ˆ2*parameter(sat2)ˆ2 + Sˆ2*( ... 
parameter(sat1)ˆ2* ... 
744 
(1+OrbitDataProp.e(sat2)*cos(f(sat2)))ˆ2 + parameter(sat2)ˆ2*(1+OrbitDataProp.e(sat1)*cos(f(sat1)))ˆ2 )? 
... 
2*Sˆ2*parameter(sat1)*parameter(sat2)* ... 
( D1*cos(f(sat2))* ( cos 

gamma*cos(f(sat1))+sin 

gamma*sin(f(sat1)) ) + D2*sin(f(sat2))* ( ... 
cos 

psi*cos(f(sat1))+sin psi*sin(f(sat1)) ) ) * ... 
746 
(1+OrbitDataProp.e(sat1)*cos(f(sat1))) * (1+OrbitDataProp.e(sat2)*cos(f(sat2))); 
747 
Rv = sqrt((r(sat1)ˆ2 * r(sat2)ˆ2? 
r1dotr2complexˆ2)/(r(sat1)ˆ2 + r(sat2)ˆ2? 
2*r1dotr2complex))? 
body 

radius; 

748 
749 
% Step 9: Print Results for the given epoch time 
pair result = 'The result for %s%s and %s%s at %s is %d '; 
751 
visibility '?

= ?? 
Direct line of sight'; 
752 
non 

visibility= '??visibility';

?? 
Non 

753 
754 
t todatetime = datetime(t, 'ConvertFrom', 'posixtime'); 

756 
result to log = sprintf(pair result, OrbitData.IDfsat1g, OrbitData.designationfsat1g, OrbitData.IDfsat2g, OrbitData.designationfsat2g, t todatetime, ... 
Rcomplex(step 

count, num 

pairs)); 
757 
fprintf(result 

to 

log); % Command window print 

758 
759 
if Rcomplex(step count, num pairs)< 
0 
disp(visibility); % Command window print 
761 
fprintf(fid 

log, '%s: %s%snn', datestr(datetime('now', 'TimeZone', 'UTC')), result 

to 

log, visibility); % Appending visibility analysis result to log file 
762 
else 
763 
disp(non visibility); % Command window print 
764 
fprintf(fid 

log, '%s: %s%snn', datestr(datetime('now', 'TimeZone', 'UTC')), result 

to 

log, non 

visibility); % Appending visibility analysis result to ... 
log file 

end 

766 


6 



CHAPTER 
1. 
MATLAB 
CODE 


767 
% Pathfinder feed 
768 
if Rcomplex(step count,num pairs)< 
0 && (step count == 1 j| 
Rcomplex(step count?1,num 

pairs) 0) 
769 
num windows = num windows + 1; 
WindowsData.start(sat1,sat2,num windows) = t; 
771 
WindowsData.start(sat2,sat1,num windows) = WindowsData.start(sat1,sat2,num 

windows); 
772 
end 
773 
if step count> 
1 
774 
if Rcomplex(step 

count,num 

pairs) 0 && Rcomplex(step 

count?1,num 

pairs)< 
0 
WindowsData.end(sat1,sat2,num windows) = t; 
776 
WindowsData.time(sat1,sat2,num windows) = t?WindowsData.start(sat1,sat2,num 

windows); 
777 
WindowsData.end(sat2,sat1,num 

windows) = WindowsData.end(sat1,sat2,num windows); 
778 
WindowsData.time(sat2,sat1,num 

windows) = WindowsData.time(sat1,sat2,num windows); 
779 
end 

end 
781 
if step count> 
1 
782 
if Rcomplex(step 

count,num pairs)< 
0 && Rcomplex(step count?1,num pairs)< 
0 && step count == num 

steps 
783 
WindowsData.end(sat1,sat2,num windows) = t; 
784 
WindowsData.time(sat1,sat2,num windows) = t?WindowsData.start(sat1,sat2,num 

windows); 
WindowsData.end(sat2,sat1,num windows) = WindowsData.end(sat1,sat2,num 

windows); 
786 
WindowsData.time(sat2,sat1,num 

windows) = WindowsData.time(sat1,sat2,num windows); 
787 
end 
788 
end 
789 


% CSV insertion 

791 
csv 

datafstep count,3,sat1,num 

pairs} 
= t todatetime; 
792 
csv 

datafstep count,4,sat1,num 

pairs} 
= t; 
793 
csv 

datafstep count,3,sat2,num 

pairs} 
= t todatetime; 
794 
csv 

datafstep count,4,sat2,num 

pairs} 
= t; 

796 
csv 

datafstep count,5,sat1,num 

pairs} 
= strcat(OrbitData.IDfsat1g,OrbitData.designationfsat1g); 
797 
csv 

datafstep count,6,sat1,num 

pairs} 
= strcat(OrbitData.IDfsat2g,OrbitData.designationfsat2g); 
798 
csv 

datafstep count,5,sat2,num 

pairs} 
= strcat(OrbitData.IDfsat1g,OrbitData.designationfsat1g); 
799 
csv 

datafstep count,6,sat2,num 

pairs} 
= strcat(OrbitData.IDfsat2g,OrbitData.designationfsat2g); 

801 
csv 

datafstep count,9,sat1,num 

pairs} 
= Rcomplex(step count,num 

pairs); 
802 
csv 

datafstep count,10,sat1,num 

pairs} 
= Rv; 
803 
csv 

datafstep count,9,sat2,num 

pairs} 
= Rcomplex(step count,num 

pairs); 
804 
csv 

datafstep count,10,sat2,num 

pairs} 
= Rv; 

806 
step count = step count + 1; 
807 
808 
end 
809 


t = start time 

unix; 

811 
812 
end 
813 
814 
end 

816 
toc; % Runtime end 
817 
818 
%% CSV output file module 
819 


if isfile(fullfile([pwd, 'nData Output Files'],'InterlinkData.csv')) 
821 
else 
822 
disp('Creating CSV file...') % Command window print 
823 
fprintf(fid 

log, '%s: %snn', datestr(datetime('now', 'TimeZone', 'UTC')), 'Creating CSV file...'); % Log print 
824 
fid csv = fopen(fullfile([pwd, 'nData Output Files'],'InterlinkData.csv'), 'w'); 
if fid 

csv == ?1 
826 
error('Cannot open file'); 
827 
end 
828 
headers = f'Simulation ID', 'Analysis', 'Simulation Date Time', 'Simualtion Unix Time', 'Satellite 1', 'Satellite 2', 'Satellites Number', 'Satellites Names', ... 

'R 

Visibility', 'R Margin', 'Satellite ID', 'PRN', ... 
829 
'Inclination', 'RAAN', 'Argument periapsis', 'Mean Anomaly', 'Mean Motion', 'Semimajor axis', 'Eccentricity', 'TLE Date', 'Bstar', 'Ballistic ... 
Coefficient', 'True Anomaly', 'Xi', 'Eta', 'Parameter', 'R 

vector'g; 
fprintf(fid 

csv,'%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%snn', headersf1:27g); 
831 
end 
832 
833 
disp('Inserting data to CSV file...') % Command window print 
834 
fprintf(fid 

log, '%s: %snn', datestr(datetime('now', 'TimeZone', 'UTC')), 'Inserting data to CSV file...'); % Log print 
fid csv = fopen(fullfile([pwd, 'nData Output Files'],'InterlinkData.csv'), 'a'); 
836 
if fid 

csv>0 
837 
num pairs = 0; 
838 
for sat1=1:num satellites?1 
839 
for sat2=sat1+1:num 

satellites 
num pairs = num pairs + 1; 
841 
for i=1:num 

steps 
842 
j = sat1; 
843 
for x=1:2 
844 
fprintf(fid csv,'%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%snn',csv 

datafi,:,j,num 

pairsg); 

j = sat2; 
846 
end 
847 
end 
848 
end 
849 
end 

end 

851 
852 
fclose(fid 

csv); % Closing InterlinkData csv file 
853 
fclose(fid 

log); % Closing log file 

854 


%% Plot the orbit 

856 
857 
% Plot the Earth 
858 
% If you want a color Earth, use 'neomap', 'BlueMarble' 
859 
% If you want a black and white Earth, use 'neomap', 'BlueMarble 

bw' 

% A smaller sample step gives a finer resolution Earth 
861 
disp('Opening plot module...') % Command window print 
862 
863 
fid 

log = fopen(fullfile([pwd, '/logs'], full name log), 'a'); % Setting log file to append mode 

864 


if fid 

log == ?1 
866 
error('Cannot open log file.'); 
867 
end 
868 
869 
fprintf(fid 

log, '%s: %snn', datestr(datetime('now', 'TimeZone', 'UTC')), 'Opening plot module...'); 
fclose(fid 

log); % Closing log file 

871 
872 
% Simualtion Unix time vector converted to DateTimes strings inside a cell 
873 
tSim 

strings = fstep count?1g; 
874 
for t=1:step count?1 

tSim stringsft} 
= datestr(datetime(tSim(t),'ConvertFrom','posixtime')); 
876 
end 
877 
878 
plot list = f'Static Plot', 'Live Plots. See color legend in 1 vs 1 plot to identify satellites. It may take a lot of time. MP4 Animation will be created in Data ... 

Output Files (Warning: do not move the figure windows while recording).'g; 
879 
[indx,:] = listdlg('ListString',plot list,'Name','3D Plot','PromptString','Select a plot ... 
mode:','SelectionMode','single','ListSize',[1000,300],'OKString','Plot','CancelString','Quit'); 

881 
colors = lines(num 

satellites); 

882 
883 
if indx == 2 
884 
% Static plot 

h1 = plotearth('neomap', 'BlueMarble bw', 'SampleStep', 1); 
886 
for i=1:num 

satellites 
887 
plot3(RSave(:,1,i) / body 

radius, RSave(:,2,i) / body radius, RSave(:,3,i) / body radius,... 
888 
'color', colors(i,:), 'LineWidth', 1, 'DisplayName', strcat(OrbitData.IDfig, OrbitData.designationfig,'? 
Orbit')) 
889 
plot3(RSave(1,1,i) / body 

radius, RSave(1,2,i) / body radius, RSave(1,3,i) / body radius,... 

'.', 'color', colors(i,:), 'MarkerSize', 30, 'DisplayName', strcat(OrbitData.IDfig, OrbitData.designationfig,'? 
Starting Point')) 
891 
end 
892 
lgd2 = legend('AutoUpdate', 'off'); 
893 
894 
% Live 3D plot 

disp('Do not maximize Live Plot window (animation being recorded)') % Command window print 

7 



CHAPTER 
1. 
MATLAB 
CODE 


896 
897 
fid 

log = fopen(fullfile([pwd, '/logs'], full name log), 'a'); % Setting log file to append mode 

898 
899 
if fid 

log == ?1 

error('Cannot open log file.'); 
901 
end 
902 
903 
fprintf(fid 

log, '%s: %snn', datestr(datetime('now', 'TimeZone', 'UTC')), 'Do not maximize Live Plot window (animation being recorded)'); 
904 
fprintf(fid 

log, '%s: %snn', datestr(datetime('now', 'TimeZone', 'UTC')), 'The video''s width and height has been padded to be a multiple of two as required by ... 
the H.264 codec'); 
fclose(fid 

log); % Closing log file 

906 
907 
num pairs = 0; 
908 
num frames = 0; 
909 


% Counting number of frames for preallocation 

911 
for sat1=1:num satellites?1 
912 
for sat2=sat1+1:num 

satellites 
913 
num pairs = num pairs + 1; 
914 
for t=1:step 

count?1 
for x=1:2 
916 
num 

frames = num frames + 1; 
917 
end 
918 
end 
919 
end 

end 

921 
922 
Frames = moviein(num 

frames); 
923 
num pairs = 0; 
924 
% Create the video writer with the desired fps 

writerObj = VideoWriter(fullfile([pwd, 'nData Output Files'],sprintf('LivePlot?%s.mp4',sprintf('%s?%s',date log,name logf1g))), 'MPEG?4'); 
926 
writerObj.FrameRate = 10; 
927 
% Set the seconds per image 
928 
% Open the video writer 
929 
open(writerObj); 

931 
h2 = plotearth('neomap', 'BlueMarble bw', 'SampleStep', 1); 
932 
for sat1=1:num satellites?1 
933 
934 
for sat2=sat1+1:num 

satellites 

num pairs = num pairs + 1; 
936 
hold on 
937 
938 
for t=1:step 

count?1 
939 
i = sat1; 

for x=1:2 
941 
if Rcomplex(t, num pairs)< 
0 && i == sat1 
942 
curve = animatedline('LineWidth',2,'color', [100, 255, 110] / 255, 'DisplayName', 'Visibility', 'HandleVisibility', 'on'); % Green color 
943 
elseif Rcomplex(t, num pairs) 0 && i == sat1 
944 
curve = animatedline('LineWidth',2,'color', [225, 90, 90] / 255, 'DisplayName', 'Non?visibility', 'HandleVisibility', 'on'); % Red color 

elseif Rcomplex(t, num pairs)< 
0 && i == sat2 
946 
curve = animatedline('LineWidth',2,'color', [100, 255, 110] / 255, 'DisplayName', 'Visibility', 'HandleVisibility', 'off'); % Green color 
947 
elseif Rcomplex(t, num pairs) 0 && i == sat2 
948 
curve = animatedline('LineWidth',2,'color', [225, 90, 90] / 255, 'DisplayName', 'Non?visibility', 'HandleVisibility', 'off'); % Red color 
949 
end 

if i == sat1 
951 
head1 = scatter3(RSave(t,1,sat1) / body radius, RSave(t,2,sat1) / body radius, RSave(t,3,sat1) / body radius, 'filled', 'MarkerFaceColor', ... 

colors(sat1,:),... 
952 
'DisplayName', strcat(OrbitData.IDfsat1g, OrbitData.designationfsat1g), 'HandleVisibility', 'on'); 
953 
elseif i == sat2 
954 
head2 = scatter3(RSave(t,1,sat2) / body radius, RSave(t,2,sat2) / body radius, RSave(t,3,sat2) / body radius, 'filled', 'MarkerFaceColor', ... 

colors(sat2,:),... 

'DisplayName', strcat(OrbitData.IDfsat2g, OrbitData.designationfsat2g), 'HandleVisibility', 'on'); 
956 
end 
957 
addpoints(curve, RSave(1:t,1,i) / body radius, RSave(1:t,2,i) / body radius, RSave(1:t,3,i) / body radius); 
958 
drawnow; 
959 
F = getframe(gcf); 

writeVideo(writerObj, F); 
961 
pause(0.01) 
962 
i = sat2; 
963 
end 
964 


lgd = legend(tSim stringsftg); 
966 
lgd.FontSize = 15; 
967 
delete(head1); 
968 
delete(head2); 
969 
end 

971 
end 
972 
973 
end 
974 


% Close the writer object 

976 
close(writerObj); 
977 
978 
elseif indx == 1 
979 
% Static plot 

h1 = plotearth('neomap', 'BlueMarble bw', 'SampleStep', 1); 
981 
for i=1:num 

satellites 
982 
plot3(RSave(:,1,i) / body 

radius, RSave(:,2,i) / body radius, RSave(:,3,i) / body radius,... 
983 
'color', colors(i,:), 'LineWidth', 1, 'DisplayName', strcat(OrbitData.IDfig, OrbitData.designationfig,'? 
Orbit')) 
984 
plot3(RSave(1,1,i) / body 

radius, RSave(1,2,i) / body radius, RSave(1,3,i) / body radius,... 

'.', 'color', colors(i,:), 'MarkerSize', 30, 'DisplayName', strcat(OrbitData.IDfig, OrbitData.designationfig,'? 
Starting Point')) 
986 
end 
987 
lgd2 = legend(); 
988 
end 
989 


%% Pathfinder Algorithm 

991 
path 

tle list = cell(1,num satellites); 

992 
993 
for i=1:num satellites 
994 
satellite string = strcat(OrbitData.IDfig,OrbitData.designationfig); 

path 

tle 

listfi} 
= satellite string; 
996 
end 
997 
998 
[indx,tf] = listdlg('ListString',path tle list,'Name','Pathfinder. Satellite sender','PromptString','Select sender',... 
999 
'SelectionMode','single','ListSize',[500,300],'OKString','Next','CancelString','Quit'); 

1001 
if tf == 0 
1002 
disp('User selected Quit'); 
1003 
else 
1004 
start sat = indx; 

1006 
[indx,:] = listdlg('ListString',path tle list,'Name','Pathfinder. Satellite receiver','PromptString','Select receiver',... 
1007 
'SelectionMode','single','ListSize',[500,300],'OKString','Next','CancelString','Quit'); 
1008 
1009 
end sat = indx; 

1011 
prompt = f'Transfer duration [s]:'g; 
1012 
dlgtitle = 'Pathfinder transfer time'; 
1013 
dims = [1 70]; 
1014 
pathfinder answer = inputdlg(prompt,dlgtitle,dims); 

transfer time = str2double(pathfinder answerf1g); 

1016 
1017 
fid 

log = fopen(fullfile([pwd, '/logs'], full name log), 'a'); % Setting log file to append mode 

1018 
1019 
if fid 

log == ?1 

error('Cannot open log file.'); 
1021 
end 
1022 
1023 
pathfinder 

selection = sprintf('Sender satellite selected: %s? 
Receiver satellite selected: %s? 
Transfer duration [s]: ... 
%s',strcat(OrbitData.IDfstart 

satg,OrbitData.designationfstart 

satg),... 
1024 
strcat(OrbitData.IDfend 

satg,OrbitData.designationfend 

satg),pathfinder 

answerf1g); 

8 



CHAPTER 
1. 
MATLAB 
CODE 


1026 
fprintf('%snn',pathfinder selection); % Command window print 
1027 
1028 
fprintf(fid log, '%s: %snn', datestr(datetime('now', 'TimeZone', 'UTC')), pathfinder selection); % Log print 
1029 
% Windows per pair able to transfer the required data 
1031 
for sat1=1:num satellites?1 
1032 
1033 
for sat2=sat1+1:num satellites 
1034 
i=sat1; 
j=sat2; 
1036 
for x=1:2 
1037 
% 10 Windows per pair 
1038 
num windows = 1; 
1039 
for y=1:10 
while WindowsData.time(i,j,num windows)< 
transfer time && num windows< 
length(WindowsData.time) 
1041 
num windows = num windows + 1; 
1042 
end 
1043 
if WindowsData.time(i,j,num windows)> 
transfer time && WindowsData.start(i,j,num windows)> 
0 
1044 
WindowsDataFirst.start(i,j,y) = WindowsData.start(i,j,num windows); 
WindowsDataFirst.end(i,j,y) = WindowsData.end(i,j,num windows); 
1046 
WindowsDataFirst.time(i,j,y) = WindowsData.time(i,j,num windows); 
1047 
num windows = num windows + 1; 
1048 
end 
1049 
end 
1051 
i=sat2; 
1052 
j=sat1; 
1053 
1054 
end 
1056 
end 
1057 
1058 
end 
1059 
% Path Solution 
1061 
1062 
PathSolution1 = struct('sat start', zeros(1, 1), 'sat end', zeros(1, 1), 'start', zeros(1, 1), 'end', zeros(1, 1), 'total time', zeros(1, 1)); 
1063 
PathSolution2 = struct('sat start', zeros(num satellites?2, 2), 'sat end', zeros(num satellites?2, 2), 'start', zeros(num satellites?2, 2), 'end', ... 
zeros(num satellites?2, 2), 'total time', zeros(num satellites?2, 2)); 
1064 
PathSolution3 = struct('sat start', zeros((num satellites?2)*((num satellites?2)?1), 3), 'sat end', zeros((num satellites?2)*((num satellites?2)?1), 3), 'start', ... 
zeros((num satellites?2)*((num satellites?2)?1), 3), 'end', zeros((num satellites?2)*((num satellites?2)?1), 3), 'total time', ... 
zeros((num satellites?2)*((num satellites?2)?1), 3)); 
1066 
% One Jump Path 
1067 
PathSolution1.sat start(1,1) = start sat; 
1068 
PathSolution1.sat end(1,1) = end sat; 
1069 
PathSolution1.start(1,1) = WindowsDataFirst.start(start sat,end sat,1); 
PathSolution1.end(1,1) = WindowsDataFirst.start(start sat,end sat,1) + transfer time; 
1071 
PathSolution1.total time(1,1) = PathSolution1.end(1,1)? 
start time unix; 
1072 
1073 
% Two Jumps Path 
1074 
if num satellites> 
2 
index count = 0; 
1076 
for x=1:num satellites 
1077 
y = x; 
1078 
1079 
while y == end sat j| 
y == start sat 
y = y+1; 
end 
1081 
if y> 
num satellites 
1082 
else 
1083 
index count = index count + 1; 
1084 
PathSolution2.sat start(index count,1) = start sat; 
PathSolution2.sat end(index count,1) = y; 
1086 
PathSolution2.start(index count,1) = WindowsDataFirst.start(start sat,y,1); 
1087 
PathSolution2.end(index count,1) = WindowsDataFirst.start(start sat,y,1) + transfer time; 
1088 
PathSolution2.total time(index count,1) = PathSolution2.end(index count,1)? 
start time unix; 
1089 
num windows = 1; 
1091 
k = num windows; 
1092 
while num windows 10 && WindowsDataFirst.end(y,end sat,num windows)?transfer time< 
PathSolution2.end(index count,1) 
1093 
num windows = num windows + 1; 
1094 
k = num windows; 
end 
1096 
if k> 
10 
1097 
else 
1098 
PathSolution2.sat start(index count,2) = y; 
1099 
PathSolution2.sat end(index count,2) = end sat; 
if PathSolution2.end(index count,1)< 
WindowsDataFirst.start(y,end sat,k) 
1101 
PathSolution2.start(index count,2) = WindowsDataFirst.start(y,end sat,k); 
1102 
else 
1103 
PathSolution2.start(index count,2) = PathSolution2.end(index count,1); 
1104 
end 
PathSolution2.end(index count,2) = PathSolution2.start(index count,2) + transfer time; 
1106 
PathSolution2.total time(index count,2) = PathSolution2.end(index count,2)? 
start time unix; 
1107 
end 
1108 
end 
1109 
end 
end 
1111 
1112 
% Three Jumps Path 
1113 
if num satellites> 
3 
1114 
index count = 0; 
for x=1:num satellites 
1116 
y = x; 
1117 
1118 
while y == end sat j| 
y == start sat 
y = y+1; 
1119 
end 
if y> 
num satellites 
1121 
else 
1122 
for z=1:num satellites 
1123 
q = z; 
1124 
while q == end sat j| 
q == start sat j| 
q == y 
q = q+1; 
1126 
end 
1127 
if q> 
num satellites 
1128 
else 
1129 
index count = index count + 1; 
PathSolution3.sat start(index count,1) = start sat; 
1131 
PathSolution3.sat end(index count,1) = y; 
1132 
PathSolution3.start(index count,1) = WindowsDataFirst.start(start sat,y,1); 
1133 
PathSolution3.end(index count,1) = WindowsDataFirst.start(start sat,y,1) + transfer time; 
1134 
PathSolution3.total time(index count,1) = PathSolution3.end(index count,1)? 
start time unix; 
1136 
num windows=1; 
1137 
k = num windows; 
1138 
while num windows 10 && WindowsDataFirst.end(y,q,num windows)?transfer time< 
PathSolution3.end(index count,1) 
1139 
num windows = num windows + 1; 
k = num windows; 
1141 
end 
1142 
if k> 
10 
1143 
else 
1144 
PathSolution3.sat start(index count,2) = y; 
PathSolution3.sat end(index count,2) = q; 
1146 
if PathSolution3.end(index count,1)< 
WindowsDataFirst.start(y,q,k) 
1147 
PathSolution3.start(index count,2) = WindowsDataFirst.start(y,q,k); 
1148 
else 
1149 
PathSolution3.start(index count,2) = PathSolution3.end(index count,1); 
end 
1151 
PathSolution3.end(index count,2) = PathSolution3.start(index count,2) + transfer time; 
1152 
PathSolution3.total time(index count,2) = PathSolution3.end(index count,2)? 
start time unix; 
1153 
end 
1154 


9 



CHAPTER 
1. 
MATLAB 
CODE 


num 

windows=1; 
1156 
m = num windows; 
1157 
while num windows 10 && WindowsDataFirst.end(q,end 

sat,num windows)?transfer time< 
PathSolution3.end(index 

count,2) 
1158 
num windows = num windows + 1; 
1159 
m = num 

windows; 

end 
1161 
if m> 
10 
1162 
else 
1163 
PathSolution3.sat start(index count,3) = q; 
1164 
PathSolution3.sat end(index 

count,3) = end sat; 
if PathSolution3.end(index 

count,2)< 
WindowsDataFirst.start(q,end 

sat,m) 
1166 
PathSolution3.start(index count,3) = WindowsDataFirst.start(q,end 

sat,m); 
1167 
else 
1168 
PathSolution3.start(index count,3) = PathSolution3.end(index 

count,2); 
1169 
end 
PathSolution3.end(index count,3) = PathSolution3.start(index count,3) + transfer time; 
1171 
PathSolution3.total 

time(index count,3) = PathSolution3.end(index count,3)? 
start time unix; 
1172 
end 
1173 
end 
1174 
end 

end 
1176 
end 
1177 
end 
1178 
1179 
% Best one jump path 

satellite1 name = strcat(OrbitData.IDfPathSolution1.sat startg,OrbitData.designationfPathSolution1.sat startg); 
1181 
satellite2 name = strcat(OrbitData.IDfPathSolution1.sat 

endg,OrbitData.designationfPathSolution1.sat endg); 
1182 
fprintf(sprintf('One?jump path from %s to %s is:nn',satellite1 name,satellite2 name)); % Command window print 
1183 
fprintf(fid 

log, '%s: %snn', datestr(datetime('now', 'TimeZone', 'UTC')), sprintf('One?jump path from %s to %s is:',satellite1 name,satellite2 name)); % Log print 
1184 
date1 = datestr(datetime(PathSolution1.start,'ConvertFrom','posixtime')); 
date2 = datestr(datetime(PathSolution1.end,'ConvertFrom','posixtime')); 

1186 
1187 
if PathSolution1.total time 0 
1188 
disp('Path is not possible') % Command window print 
1189 
fprintf(fid 

log, '%s: %snn', datestr(datetime('now', 'TimeZone', 'UTC')), 'Path is not possible'); % Log print 

else 

1191 
fprintf(sprintf('Jump. Sender Satellite: %s? 
Receiver Satellite: %s? 
Start date time %s? 
End date time: %s? 
Total time since Simulation start: %snn', ... 
satellite1 

name,... 
1192 
satellite2 

name, date1, date2, num2str(PathSolution1.total time))); % Command window print 
1193 
fprintf(fid 

log, '%s: %snn', datestr(datetime('now', 'TimeZone', 'UTC')),... 
1194 
sprintf('Jump. Sender Satellite: %s? 
Receiver Satellite: %s? 
Start date time %s? 
End date time: %s? 
Total time since Simulation start: %s',... 
satellite1 name, satellite2 

name, date1, date2, num2str(PathSolution1.total time))); % Log print 
1196 
end 
1197 
1198 
% Best two?jumps path 
1199 
if num satellites> 
2 

quick path2 = start time unix; 
1201 
for i=1:length(PathSolution2.total time) 
1202 
if PathSolution2.total 

time(i,1)> 
0 
1203 
if PathSolution2.total time(i,2)> 
0 
1204 
if PathSolution2.total time(i,2)< 
quick 

path2 
quick path2 = PathSolution2.total 

time(i,2); 
1206 
quick 

path2 id = i; 
1207 
end 
1208 
end 
1209 
end 

end 

1211 
1212 
satellite start name = strcat(OrbitData.IDfstart satg,OrbitData.designationfstart 

satg); 
1213 
satellite end name = strcat(OrbitData.IDfend satg,OrbitData.designationfend 

satg); 
1214 
fprintf(sprintf('Quickest two?jump path from %s to %s is:nn',satellite 

start name,satellite 

end 

name)); % Command window print 
fprintf(fid 

log, '%s: %snn', datestr(datetime('now', 'TimeZone', 'UTC')), sprintf('Quickest two?jump path from %s to %s ... 
is:',satellite 

start 

name,satellite end 

name)); % Log print 

1216 
1217 
if quick path2 == start time 

unix 
1218 
disp('Path is not possible') % Command window print 
1219 
fprintf(fid 

log, '%s: %snn', datestr(datetime('now', 'TimeZone', 'UTC')), 'Path is not possible'); % Log print 

else 

1221 
satellite1 name = strcat(OrbitData.IDfPathSolution2.sat start(quick path2 id,1)g,OrbitData.designationfPathSolution2.sat start(quick path2 

id,1)g); 
1222 
satellite2 

name = strcat(OrbitData.IDfPathSolution2.sat end(quick path2 id,1)g,OrbitData.designationfPathSolution2.sat end(quick path2 id,1)g); 
1223 
satellite3 name = strcat(OrbitData.IDfPathSolution2.sat start(quick path2 id,2)g,OrbitData.designationfPathSolution2.sat start(quick path2 

id,2)g); 
1224 
satellite4 

name = strcat(OrbitData.IDfPathSolution2.sat end(quick path2 id,2)g,OrbitData.designationfPathSolution2.sat end(quick path2 id,2)g); 
date1 = datestr(datetime(PathSolution2.start(quick path2 

id,1),'ConvertFrom','posixtime')); 
1226 
date2 = datestr(datetime(PathSolution2.end(quick path2 id,1),'ConvertFrom','posixtime')); 
1227 
date3 = datestr(datetime(PathSolution2.start(quick path2 id,2),'ConvertFrom','posixtime')); 
1228 
date4 = datestr(datetime(PathSolution2.end(quick path2 id,2),'ConvertFrom','posixtime')); 
1229 


fprintf(sprintf('First Jump. Sender Satellite: %s? 
Receiver Satellite: %s? 
Start date time %s? 
End date time: %s? 
Total time since Simulation start: ... 
%snn', satellite1 

name,... 
1231 
satellite2 name, date1, date2, num2str(PathSolution2.total 

time(quick 

path2 

id,1)))); % Command window print 
1232 
fprintf(fid 

log, '%s: %snn', datestr(datetime('now', 'TimeZone', 'UTC')),... 
1233 
sprintf('First Jump. Sender Satellite: %s? 
Receiver Satellite: %s? 
Start date time %s? 
End date time: %s? 
Total time since Simulation ... 
start: %s',... 
1234 
satellite1 name, satellite2 name, date1, date2, num2str(PathSolution2.total 

time(quick 

path2 

id,1)))); % Log print 
fprintf(sprintf('Second Jump. Sender Satellite: %s? 
Receiver Satellite: %s? 
Start date time %s? 
End date time: %s? 
Total time since Simulation start: ... 
%snn', satellite3 

name,... 
1236 
satellite4 name, date3, date4, num2str(PathSolution2.total 

time(quick 

path2 

id,2)))); % Command window print 
1237 
fprintf(fid 

log, '%s: %snn', datestr(datetime('now', 'TimeZone', 'UTC')),... 
1238 
sprintf('Second Jump. Sender Satellite: %s? 
Receiver Satellite: %s? 
Start date time %s? 
End date time: %s? 
Total time since Simulation ... 
start: %s',... 
1239 
satellite3 name, satellite4 name, date3, date4, num2str(PathSolution2.total 

time(quick 

path2 

id,2)))); % Log print 

end 
1241 
end 
1242 
1243 
% Best three?jumps path 
1244 


if num satellites> 
3 
1246 
quick path3 = start time 

unix; 
1247 
for i=1:length(PathSolution3.total time) 
1248 
if PathSolution3.total 

time(i,1)> 
0 
1249 
if PathSolution3.total time(i,2)> 
0 
if PathSolution3.total time(i,3)> 
0 
1251 
if PathSolution3.total 

time(i,3)< 
quick path3 
1252 
quick path3 = PathSolution3.total time(i,3); 
1253 
quick 

path3 id = i; 
1254 
end 

end 
1256 
end 
1257 
end 
1258 
end 
1259 


satellite start name = strcat(OrbitData.IDfstart satg,OrbitData.designationfstart satg); 
1261 
satellite end name = strcat(OrbitData.IDfend satg,OrbitData.designationfend 

satg); 
1262 
fprintf(sprintf('Quickest three?jump path from %s to %s is:nn',satellite start name,satellite 

end 

name)); % Command window 
1263 
fprintf(fid 

log, '%s: %snn', datestr(datetime('now', 'TimeZone', 'UTC')), sprintf('Quickest three?jump path from %s to %s ... 
is:',satellite 

start 

name,satellite end 

name)); % Log print 

1264 


if quick path3 == start time unix 
1266 
disp('Path is not possible') % Command window print 
1267 
fprintf(fid 

log, '%s: %snn', datestr(datetime('now', 'TimeZone', 'UTC')), 'Path is not possible'); % Log print 
1268 
else 
1269 
satellite1 name = strcat(OrbitData.IDfPathSolution3.sat start(quick path3 id,1)g,OrbitData.designationfPathSolution3.sat start(quick path3 

id,1)g); 
satellite2 name = strcat(OrbitData.IDfPathSolution3.sat end(quick path3 id,1)g,OrbitData.designationfPathSolution3.sat end(quick path3 

id,1)g); 
1271 
satellite3 name = strcat(OrbitData.IDfPathSolution3.sat start(quick path3 id,2)g,OrbitData.designationfPathSolution3.sat start(quick path3 

id,2)g); 
1272 
satellite4 

name = strcat(OrbitData.IDfPathSolution3.sat end(quick path3 id,2)g,OrbitData.designationfPathSolution3.sat end(quick path3 id,2)g); 
1273 
satellite5 name = strcat(OrbitData.IDfPathSolution3.sat start(quick path3 id,3)g,OrbitData.designationfPathSolution3.sat start(quick path3 

id,3)g); 
1274 
satellite6 

name = strcat(OrbitData.IDfPathSolution3.sat end(quick path3 id,3)g,OrbitData.designationfPathSolution3.sat end(quick path3 id,3)g); 
date1 = datestr(datetime(PathSolution3.start(quick path3 

id,1),'ConvertFrom','posixtime')); 
1276 
date2 = datestr(datetime(PathSolution3.end(quick path3 id,1),'ConvertFrom','posixtime')); 
1277 
date3 = datestr(datetime(PathSolution3.start(quick path3 id,2),'ConvertFrom','posixtime')); 
1278 
date4 = datestr(datetime(PathSolution3.end(quick path3 id,2),'ConvertFrom','posixtime')); 
1279 
date5 = datestr(datetime(PathSolution3.start(quick path3 id,3),'ConvertFrom','posixtime')); 

date6 = datestr(datetime(PathSolution3.end(quick path3 

id,3),'ConvertFrom','posixtime')); 

10 



CHAPTER 
1. 
MATLAB 
CODE 


1281 


1282 
fprintf(sprintf('First Jump. Sender Satellite: %s? 
Receiver Satellite: %s? 
Start date time %s? 
End date time: %s? 
Total time since Simulation start: ... 
%snn', satellite1 

name,... 
1283 
satellite2 name, date1, date2, num2str(PathSolution3.total 

time(quick 

path3 

id,1)))); % Command winodow print 
1284 
fprintf(fid 

log, '%s: %snn', datestr(datetime('now', 'TimeZone', 'UTC')),... 
sprintf('First Jump. Sender Satellite: %s? 
Receiver Satellite: %s? 
Start date time %s? 
End date time: %s? 
Total time since Simulation ... 
start: %s',... 
1286 
satellite1 name, satellite2 name, date1, date2, num2str(PathSolution3.total 

time(quick 

path3 

id,1)))); % Log print 
1287 
fprintf(sprintf('Second Jump. Sender Satellite: %s? 
Receiver Satellite: %s? 
Start date time %s? 
End date time: %s? 
Total time since Simulation start: ... 
%snn', satellite3 

name,... 
1288 
satellite4 name, date3, date4, num2str(PathSolution3.total 

time(quick 

path3 

id,2)))); % Command winodow print 
1289 
fprintf(fid 

log, '%s: %snn', datestr(datetime('now', 'TimeZone', 'UTC')),... 
sprintf('Second Jump. Sender Satellite: %s? 
Receiver Satellite: %s? 
Start date time %s? 
End date time: %s? 
Total time since Simulation ... 
start: %s',... 
1291 
satellite3 name, satellite4 name, date3, date4, num2str(PathSolution3.total 

time(quick 

path3 

id,2)))); % Log print 
1292 
fprintf(sprintf('Third Jump. Sender Satellite: %s? 
Receiver Satellite: %s? 
Start date time %s? 
End date time: %s? 
Total time since Simulation start: ... 
%snn', satellite5 

name,... 
1293 
satellite6 name, date5, date6, num2str(PathSolution3.total 

time(quick 

path3 

id,3)))); % Command winodow print 
1294 
fprintf(fid 

log, '%s: %snn', datestr(datetime('now', 'TimeZone', 'UTC')),... 
sprintf('Third Jump. Sender Satellite: %s? 
Receiver Satellite: %s? 
Start date time %s? 
End date time: %s? 
Total time since Simulation ... 
start: %s',... 
1296 
satellite5 name, satellite6 name, date5, date6, num2str(PathSolution3.total 

time(quick 

path3 

id,3)))); % Log print 

1297 
end 

1298 
end 

1299 
fclose(fid log); % Closing log file 

end 

1301 


1302 
%% The End 

1303 


1304 
disp('InterLink ended successfully') % Command winodow print 

1306 
fid log = fopen(fullfile([pwd, '/logs'], full name log), 'a'); % Setting log file to append mode 

1307 
1308 
if fid 

log == ?1 

1309 
error('Cannot open log file.'); 
end 

1311 


1312 
fprintf(fid 

log, '%s: %snn', datestr(datetime('now', 'TimeZone', 'UTC')), 'InterLink ended successfully'); 
1313 
fclose(fid 

log); % Closing log file 

11 

