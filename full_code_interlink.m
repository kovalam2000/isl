
% STUDY OF THE INTERLINK BETWEEN SMALL SATELLITES IN A CONSTELLATION
% Author: David Puig Puig- david.puig.puig@estudiant.upc.edu
% Director: Miquel Sureda Anfres
% ESEIAAT- UPC
% Visual contact for two satellites analysis

% Reminder: All times are in UTC

%% Menu module

% % Introduction and information input tle list = f'Author: David Puig', 'Director: Miquel Sureda'; 'ESEIAAT- UPC'g;
% input_tle_list = {'Author: David Puig', 'Director: Miquel Sureda', 'ESEIAAT? UPC'};
% [indx,tf] = listdlg('ListString',input_tle_list,'Name','InterLink','PromptString','This tool is used to analyse visibility windows in satellite constellations','SelectionMode','single','ListSize',[500,300],'OKString','Next','CancelString','Quit');
% 
% if tf == 0
%     disp('User selected Quit');
%     return
% end

%% Input Parameters module

% Input Celestial Object System

input_tle_list = {'Earth', 'Other'};

[indx,tf] = listdlg('ListString',input_tle_list,'Name','Celestial Object System','PromptString','Select your analysis system:',...
    'SelectionMode','single','ListSize',[500,300],'OKString','Next','CancelString','Quit');
if tf == 0
    disp('User selected Quit');
    return
end
% Common System Parameters
global mu;
k = 2*pi; % Factor from [rev/s] to [rad/s]
if indx == 1
    % Earth System parameters
    body_radius = 6.378e6; % Radius of the primary body [m]
    extra_radius = 20000; % Extra radius for the primary body [m]
    S = body_radius + extra_radius; % Magnitude of the rise-set vector [m]
    mu = 3.986004418e14; % Standard gravitational parameter [m3/s2]
    
else
    
    % Other system parameters
    
    prompt = {'Primary body radius [m]:', 'Extra radius (atmosphere and other effects) [m]:', 'Mu parameter [m^3/s^2]:'};
    dlgtitle = 'Celestial Object System';
    dims = [1 70; 1 70; 170];
    system_answer = inputdlg(prompt,dlgtitle,dims);
    body_radius = str2double(system_answer{1}); % Radius of the primary body [m]
    extra_radius = str2double(system_answer{2}); % Extra radius for the primary body [m]
    S = body_radius + extra_radius; % Magnitude of the rise-set vector [m]
    mu = str2double(system_answer{1}); % Standard gravitational parameter [m^3/s^2]
    
end

% TLE input menu

input_tle_list = {'Examples', 'From .txt file (without blank lines between set)', 'Paste'};
[indx,tf] = listdlg('ListString',input_tle_list,'Name','Two Line Element (TLE)','PromptString','Select a TLE input mode:',...
    'SelectionMode','single','ListSize',[500,300],'OKString','Next','CancelString','Quit');

if tf == 0
    disp('User selected Quit');
    
    return
end

if indx == 1
    input_examples_list = {'ISS', 'ONEWEB-0010'};
    [indx,tf] = listdlg('ListString',input_examples_list,'Name','Two Line Element (TLE)','PromptString','Select two or more TLE to analyse:',...
        'SelectionMode','multiple','ListSize',[500,300],'OKString','Run','CancelString','Quit');
    
    % Hard-Coded TLE as input examples
    possible_example_answers = {{'ISS (ZARYA)                                  ';
        '1 25544U 98067A 20363.59392067  .00000558  00000-0  18138-4 0 9998 ';
        '2 25544  51.6459 106.5424 0001311 163.9929 321.3790 15.49230614262155'};
        {'ONEWEB-0010                                                          ';
        '1 44058U 19010B 20362.66668981 .00040638  00000-0  97983-1 0 9993 ';
        '2 44058  87.9168 295.7425 0001696 75.0447 241.8035 13.21785907 1721'};};
    
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
        selected_example_answers = cell(1,1);
        count=1;
        for i=1:size(indx,2)
            for j=1:3
                selected_example_answers{1}{count,1} = possible_example_answers{indx(i),1}{j};
                count=count+1;
            end
        end
        % Find the total number of satellites in the file
        num_satellites = size(indx,2);
        % Initialize array
        sat_id_line = zeros(1,num_satellites);
        line_count = 1;
        for i=1:num_satellites
            % Take every 3rd line
            sat_id_line(i) = line_count;
            txt_data = textscan(selected_example_answers{1}{line_count,1},'%s %s %s %s %s %s %s %s %s');
            OrbitData.ID(i) = txt_data{1};
            if isempty(txt_data{2})
                OrbitData.designation(i) = {''};
            else
                OrbitData.designation(i) = txt_data{2};
            end
            
            if isempty(txt_data{3})
                OrbitData.PRN(i) = {''};
            else
                OrbitData.PRN(i) = txt_data{3};
            end
            % Jump to the next Satellite Name line
            line_count = line_count + 3;
        end
        
        % Find the two lines corresponding to the spacecraft in question
        
        for j=1:length(sat_id_line)
            
            % Find the first line of the first satellite
            
            index = sat_id_line(j);
            txt_data_second = textscan(selected_example_answers{1}{index+2,1},'%s %s %s %s %s %s %s %s %s');
            
            % Translate two line element data into obital elements
            OrbitData.i(j) = str2double(txt_data_second{1,3})*(pi/180); % Inclination [deg] to [rad]
            OrbitData.RAAN(j) = str2double(txt_data_second{1,4})*(pi/180); % Right ascention of the ascending node[deg] to [rad]
            OrbitData.omega(j) = str2double(txt_data_second{1,6})*(pi/180); % Argument of the periapsis [deg] to [rad]
            OrbitData.M(j) = str2double(txt_data_second{1,7})*(pi/180); % Mean anomaly [deg] to [rad]
            n = str2double(txt_data_second{1,8}); % Unperturbed mean motion [rev/day]
            OrbitData.n(j) = n*2*pi/24/60/60; % Unperturbed mean motion [rad/s]
            OrbitData.a(j) = ( mu / OrbitData.n(j)^2 )^(1/3); % Semi-major axis [m]
            OrbitData.e(j) = str2double(txt_data_second{1,5})*1e-7; % Eccentricity [unitless]
            
            % Compute the UTC date / time
            txt_data_first = textscan(selected_example_answers{1}{index+1,1},'%s %s %s %s %s %s %s %s %s');
            temp2 = txt_data_first{1,4};
            yy = str2double(temp2{1}(1:2));
            yyyy = 2000 + yy;
            start = datenum([yyyy 0 0 0 0 0]);
            secs = str2double(temp2{1}(3:length(temp2{1})))*24*3600;
            date1 = datevec(addtodate(start,floor(secs),'second'));
            remainder = [0 0 0 0 0 mod(secs,1)];
            OrbitData.date{j} = datestr(date1+remainder,'dd-mmm-yyyy HH:MM:SS.FFF');
            
            % Compute ballistic coefficient in SI units
            temp3 = txt_data_first{1,7};
            if length(temp3{1})== 7
                base = str2double(temp3{1}(1:5));
                expo = str2double(temp3{1}(6:7));
                
            elseif length(temp3{1})== 8
                base = str2double(temp3{1}(2:6));
                expo = str2double(temp3{1}(7:8));
            else
                
                fprintf('Error in ballistic coefficient calculationnn')
                CreateStruct.Interpreter = 'tex';
                CreateStruct.WindowStyle = 'modal';
                msgbox('Error in ballistic coefficient calculationnn','Error',CreateStruct);
                error('End program')
                
            end
            
            OrbitData.Bstar(j) = base*1e-5*10^expo;
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
        fid_input = fopen(fullfile(path,file));
        txt_data = textscan(fid_input,'%s %s %s %s %s %s %s %s %s');
        
        % Find the total number of satellites in the file
        num_satellites = length(txt_data{1})/3;
        
        % Initialize array
        
        sat_id_line = zeros(1,num_satellites);
        line count = 1;
        for i=1:num_satellites
            % Take every 3rd line
            sat_id_line(i) = line_count;
            
            OrbitData.ID(i) = txt_data{1}(line_count);
            if isempty(txt_data{2}(line_count))
                OrbitData.designation(i) = {''};
                
            else
                
                OrbitData.designation(i) = txt_data{2}(line_count);
                
            end
            
            if isempty(txt_data{3}(line_count))
                OrbitData.PRN(i) = {''};
            else
                OrbitData.PRN(i) = txt_data{3}(line_count);
            end
            
            % Jump to the next Satellite Name line
            
            line_count = line_count + 3;
            
        end
        
        % Find the two lines corresponding to the spacecraft in question
        
        for j=1:length(sat_id_line)
            % Find the first line of the first satellite
            index = sat_id_line(j);
            
            % Translate two line element data into obital elements
            OrbitData.i(j) = str2double(txt_data{1,3}{index+2})*(pi/180); % Inclination [deg] to [rad]
            OrbitData.RAAN(j) = str2double(txt_data{1,4}{index+2})*(pi/180); % Right ascention of the ascending node[deg] to [rad]
            OrbitData.omega(j) = str2double(txt_data{1,6}{index+2}); % Argument of the periapsis [deg] to [rad]
            OrbitData.M(j) = str2double(txt_data{1,7}{index+2})*(pi/180); % Mean anomaly [deg] to [rad]
            n = str2double(txt_data{1,8}{index+2}); % Unperturbed mean motion [rev/day]
            OrbitData.n(j) = n*2*pi/24/60/60; % Unperturbed mean motion [rad/s]
            OrbitData.a(j) = ( mu / OrbitData.n(j)^2 )^(1/3); % Semi-major axis [m]
            OrbitData.e(j) = str2double(txt_data{1,5}{index+2})*1e-7; % Eccentricity [unitless]
            % Compute the UTC date / time
            temp2 = txt_data{1,4}{index+1};
            yy = str2double(temp2(1:2));
            yyyy = 2000 + yy;
            start = datenum([yyyy 0 0 0 0 0]);
            secs = str2double(temp2(3:length(temp2)))*24*3600;
            date1 = datevec(addtodate(start,floor(secs),'second'));
            remainder = [0 0 0 0 0 mod(secs,1)];
            OrbitData.date{j} = datestr(date1+remainder,'dd-mmm-yyyy HH:MM:SS.FFF');
            
            % Compute ballistic coefficient in SI units
            
            temp3 = txt_data{1,7}{index+1};
            
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
            
            OrbitData.Bstar(j) = base*1e-5*10^expo;
            OrbitData.BC(j) = 1/12.741621/OrbitData.Bstar(j);
            
        end
    end
    
elseif indx == 3
    
    prompt = 'How many TLE do you want to analyse-';
    dlgtitle = 'Paste TLE';
    dims = [1 69];
    tle_num_answer = inputdlg(prompt,dlgtitle,dims);
    if isempty(tle_num_answer)
        disp('User selected Cancel');
        return
    end
    
    number_of_tle = str2double(tle_num_answer);
    
    if number_of_tle<2
        CreateStruct.Interpreter = 'tex';
        CreateStruct.WindowStyle = 'modal';
        msgbox('A minimum of two TLE set are needed to compute visibility','Error',CreateStruct);
        return
    end
    
    prompt = sprintf('Enter %d sets of TLE without blank lines between set:', number_of_tle);
    dlgtitle = 'Paste TLE';
    dims = [3*number_of_tle 69];
    tle_pasted_answer = inputdlg(prompt,dlgtitle,dims);
    
    if isempty(tle_pasted_answer)
        disp('User selected Cancel');
        
        return
    end
    
    % TLE variables extraction
    % Find the total number of satellites in the file
    num_satellites = str2double(tle_num_answer);
    % Initialize array
    sat_id_line = zeros(1,num_satellites);
    line_count = 1;
    for i=1:num_satellites
        % Take every 3rd line
        sat_id_line(i) = line_count;
        txt_data = textscan(tle_pasted_answer{1}(line_count,1:69),'%s %s %s %s %s %s %s %s %s');
        OrbitData.ID(i) = txt_data{1};
        if isempty(txt_data{2})
            OrbitData.designation(i) = {''};
        else
            OrbitData.designation(i) = txt_data{2};
        end
        if isempty(txt_data{3})
            OrbitData.PRN(i) = {''};
        else
            OrbitData.PRN(i) = txt_data{3};
        end
        % Jump to the next Satellite Name line
        line_count = line_count + 3;
    end
    % Find the two lines corresponding to the spacecraft in question
    for j=1:length(sat_id_line)
        % Find the first line of the first satellite
        index = sat_id_line(j);
        txt_data_second = textscan(tle_pasted_answer{1}(index+2,1:69),'%s %s %s %s %s %s %s %s %s');
        % Translate two line element data into obital elements
        OrbitData.i(j) = str2double(txt_data_second{1,3})*(pi/180); % Inclination [deg] to [rad]
        OrbitData.RAAN(j) = str2double(txt_data_second{1,4})*(pi/180); % Right ascention of the ascending node[deg] to [rad]
        OrbitData.omega(j) = str2double(txt_data_second{1,6})*(pi/180); % Argument of the periapsis [deg] to [rad]
        OrbitData.M(j) = str2double(txt_data_second{1,7})*(pi/180); % Mean anomaly [deg] to [rad]
        n = str2double(txt_data_second{1,8}); % Unperturbed mean motion [rev/day]
        OrbitData.n(j) = n*2*pi/24/60/60; % Unperturbed mean motion [rad/s]
        OrbitData.a(j) = ( mu / OrbitData.n(j)^2 )^(1/3); % Semi-major axis [m]
        OrbitData.e(j) = str2double(txt_data_second{1,5})*1e-7; % Eccentricity [unitless]
        % Compute the UTC date / timef
        txt_data_first = textscan(selected_example_answers{1}{index+1,1},'%s %s %s %s %s %s %s %s %s');
        temp2 = txt_data_first{1,4};
        yy = str2double(temp2{1}(1:2));
        yyyy = 2000 + yy;
        start = datenum([yyyy 0 0 0 0 0]);
        secs = str2double(temp2{1}(3:length(temp2{1})))*24*3600;
        date1 = datevec(addtodate(start,floor(secs),'second'));
        remainder = [0 0 0 0 0 mod(secs,1)];
        OrbitData.date{j} = datestr(date1+remainder,'dd-mmm-yyyy HH:MM:SS.FFF');
        
        % Compute ballistic coefficient in SI units
        
        temp3 = txt_data_first{1,7};
        
        if length(temp3{1})== 7
            base = str2double(temp3{1}(1:5));
            expo = str2double(temp3{1}(6:7));
        elseif length(temp3f1g)== 8
            base = str2double(temp3{1}(2:6));
            expo = str2double(temp3{1}(7:8));
        else
            fprintf('Error in ballistic coefficient calculationnn')
            CreateStruct.Interpreter = 'tex';
            CreateStruct.WindowStyle = 'modal';
            msgbox('Error in ballistic coefficient calculationnn','Error',CreateStruct);
            error('End program')
        end
        OrbitData.Bstar(j) = base*1e-5*10^expo;
        OrbitData.BC(j) = 1/12.741621/OrbitData.Bstar(j);
    end
end
% Simulation Parameters menu
input_simulation_list = {'From Now to Tomorrow (24h simulation) and 500 time divisions', 'Other'};
[indx,tf] = listdlg('ListString',input_simulation_list,'Name','Simulation Time','PromptString','Select a UTC time for your analysis:',...
    'SelectionMode','single','ListSize',[500,300],'OKString','Next','CancelString','Quit');
if tf == 0
    disp('User selected Quit');
    return
end
disp('Starting InterLink...')
if indx == 1
    % Simulation Parameters
    start_time = '30-Dec-2020 12:00:00';
    %start time = datetime('now', 'TimeZone', 'UTC');
    start_time_unix = posixtime(datetime(start_time));
    fprintf('Conversion of the simulation start time: %s is %d in Unix timenn', start_time, start_time_unix); % Command window print
    start_time_to_log = sprintf('Conversion of the simulation start time: %s is %d in Unix time', start_time, start_time_unix);
    
    t = start_time_unix; % Start simulation time in Unix ... time [s]
    end_time = '30-Dec-2020 00:00:00';
    %end
    time = datetime('now', 'TimeZone', 'UTC') + days(1);
    end_time_unix = posixtime(datetime(end_time));
    fprintf('Conversion of the simulation end time: %s is %d in Unix timenn', end_time, end_time_unix); % Command window print
    end_time_to_log = sprintf('Conversion of the simulation end time: %s is %d in Unix time', end_time, end_time_unix);
    t_end = end_time_unix; % End of simulation time in Unix ...time [s]
    
    time_divisions = 1000; %4320 is every 10 seconds for a 12h simulation
else
    prompt = {'Simulation start:', 'Simulation end:', 'Time divisons (steps):'};
    dlgtitle = 'Simulation Time. Example: 22-Jan-2019 13:22:22';
    dims = [1 70; 1 70; 1,70];
    simulation_answer = inputdlg(prompt,dlgtitle,dims);
    start_time = simulation_answer{1};
    end_time = simulation_answer{2}; 
    time_divisions = round(str2double(simulation_answer{3}));
    
    start_time_unix = posixtime(datetime(start_time));
    fprintf('Conversion of the simulation start time: %s is %d in Unix timenn', start_time, start_time_unix); % Command window print
    start_time_to_log = sprintf('Conversion of the simulation start time: %s is %d in Unix time', start_time, start_time_unix);
    t = start_time_unix; % Start simulation time in Unix ... time [s]
    
    end_time_unix = posixtime(datetime(end_time));
    fprintf('Conversion of the simulation end time: %s is %d in Unix timenn', end_time, end_time_unix); % Command window print
    end_time_to_log = sprintf('Conversion of the simulation end time: %s is %d in Unix time', end_time, end_time_unix);
    t_end = end_time_unix; % End of simulation time in Unix time [s]
end 
increment = (end_time_unix-start_time_unix)/time_divisions; % Time increment [s] 
num_steps = time_divisions+1; % Number of time steps 

% Satellite orbit parameters
for i=1:num_satellites
    OrbitData.epoch(i) = posixtime(datetime(char(OrbitData.date(i))));
    OrbitData.T(i) = OrbitData.epoch(i)-OrbitData.M(i)/OrbitData.n(i);
    OrbitData.q(i) = OrbitData.a(i)*(1-OrbitData.e(i));
    
end
num_pairs=0;
for sat1=1:num_satellites-1
    for sat2=sat1+1:num_satellites
        num_pairs = num_pairs +1;
    end
    
end

 
% Preallocated variables 
for i=1:num_satellites
    n = zeros(1, num_satellites); % Unperturbed mean motion [rad/s]
    M = zeros(1, num_satellites); % Mean anomaly [rad]
    Fn = zeros(1, num_satellites); % Eccentric anomaly from Kepler's Equation for hyperbolic orbit (n) [rad]
    Fn1 = zeros(1, num_satellites); % Eccentric anomaly from Kepler's Equation for hyperbolic orbit (n+1) [rad]
    f = zeros(1, num_satellites); % True Anomaly [rad]
    A = zeros(1, num_satellites); % Barker's Equation parameter
    B = zeros(1, num_satellites); % Barker's Equation parameter
    C = zeros(1, num_satellites); % Barker's Equation parameter
    En = zeros(1, num_satellites); % Eccentric anomaly from Kepler's Equation (n) [rad]
    En1 = zeros(1, num_satellites); % Eccentric anomaly from Kepler's Equation (n+1) [rad]
    Px = zeros(1, num_satellites); % First component of the unit orientation vector (dynamical center-periapsis) [m]
    Py = zeros(1, num_satellites); % Second component of the unit orientation vector (dynamical center-periapsis) [m]
    Pz = zeros(1, num_satellites); % Third component of the unit orientation vector (dynamical center-periapsis) [m]
    Qx = zeros(1, num_satellites); % First component of the unit orientation vector (advanced to P by a right angle in the ... motion direction) [m]
    Qy = zeros(1, num_satellites); % Second component of the unit orientation vector (advanced to P by a right angle in the ... otion direction) [m]
    Qz = zeros(1, num_satellites); % Third component of the unit orientation vector (advanced to P by a right angle in the ... motion direction) [m]
    r = zeros(1, num_satellites); % Magnitude of the vector from the center of the primary body to the satellite [m]
    xi = zeros(1, num_satellites); % Component of r vector in the periapsis line [m]
    eta = zeros(1, num_satellites); % Component of r vector in the descending node line [m]
    fullvector = [0 0 0]; % Intermediate vector to store the pair of r vectors [m]
    vector = zeros(num_satellites, 3); % Vector from the center of the primary body to the satellite [m]
    parameter = zeros(1, num_satellites); % Semi-parameter of the orbit [m]
    
    Rsimple1 = 0; % Visibility parameter [m]
    Rsimple2 = 0; % Visibility parameter [m]
    Rcomplex = zeros(num_steps, num_pairs); % Visibility parameter [m]
    Rangle = 0; % Visibility parameter [m]
    Rv = 0; % Distance from earth to satellite-satellite line [m]
    
    csv_data = cell(num_steps, 27, 2, num_pairs); % Array of matrix to store relevant data
    WindowsData = struct('start', zeros(num_satellites, num_satellites, 1000), 'end', zeros(num_satellites, num_satellites, 1000), 'time', zeros(num_satellites, ...
        num_satellites, 1000));
    WindowsDataFirst = struct('start', zeros(num_satellites, num_satellites, 10), 'end', zeros(num_satellites, num_satellites, 10), 'time', zeros(num_satellites, ...
        num_satellites, 10));
 
end
%% Log file module 
prompt = 'Name this analysis: Log file format will be yyyymmddHHMMSS-Name.txt';
dlgtitle = 'Log file name';
dims = [1 69];
name_log = inputdlg(prompt,dlgtitle,dims);
if isempty(name_log)
    disp('User selected Cancel');
    return
end
date_log = datestr(now,'yyyymmddHHMMSS');
full_name_log = sprintf('%s-%s.txt',date_log,name_log{1});
fopen(fullfile([pwd, '/logs'], full_name_log), 'w'); % Create log file overwriting old one
fid_log = fopen(fullfile([pwd, '/logs'], full_name_log), 'a'); % Setting log file to append mode
if fid_log == -1
    error('Cannot open log file.');
end

fprintf(fid_log, '%s: %s\n', datestr(datetime('now', 'TimeZone', 'UTC')), 'Starting InterLink...');
fprintf(fid_log, '%s: %s\n', datestr(datetime('now', 'TimeZone', 'UTC')), start_time_to_log); % Appending simulation start time to log file
fprintf(fid_log, '%s: %s\n', datestr(datetime('now', 'TimeZone', 'UTC')), end_time_to_log); % Appending simulation end time to log file
fprintf(fid_log, '%s: %s\n', datestr(datetime('now', 'TimeZone', 'UTC')), 'TLE data collected. Format: ID-designation-PRN-i-RAAN-omega-M-n-a-e-date-BC-epoch-T-q'); % ... Log file print
for i=1:num_satellites
    tle_log_print = strcat(OrbitData.ID{i},'-',OrbitData.designation{i},'-',OrbitData.PRN{i},'-',num2str(OrbitData.i(i)),'-',num2str(OrbitData.RAAN(i)),'-',...
        num2str(OrbitData.omega(i)),'-',num2str(OrbitData.M(i)),'-',num2str(OrbitData.n(i)),'-',num2str(OrbitData.a(i)),'-',num2str(OrbitData.e(i)),'-',...
        OrbitData.date{i},'-',num2str(OrbitData.BC(i)),'-',num2str(OrbitData.epoch(i)),'-',num2str(OrbitData.T(i)),'-',num2str(OrbitData.q(i)));
    fprintf(fid_log, '%s: %s\n', datestr(datetime('now', 'TimeZone', 'UTC')), tle_log_print); % Log file print
end
disp('TLE data collected:'); % Command window print  
disp(OrbitData); % Command window print 
% Print TLE parameters in command window 
% Log file is closed with "fclose" function once the algorithm is ended 
%% Populate CSV with TLE and Simulation Data  
for m=1:num_satellites
    current_sat_name = strcat(OrbitData.ID{m},OrbitData.designation{m});
    if m == 1
        all_sat_names = current_sat_name;
    else
        all_sat_names = strcat(all_sat_names,'-',current_sat_name);
    end
end
num_pairs = 0; 
for sat1=1:num_satellites-1
    for sat2=sat1+1:num_satellites
        num_pairs = num_pairs + 1;
        for i=1:num_steps
            j = sat1;
            for x=1:2
                
                csv_data{i,1,j,num_pairs} = full_name_log;
                csv_data{i,2,j,num_pairs} = 'Visibility Analysis';
                csv_data{i,7,j,num_pairs} = num2str(num_satellites);
                csv_data{i,8,j,num_pairs} = all_sat_names;
                csv_data{i,11,j,num_pairs} = strcat(OrbitData.ID{j},OrbitData.designation{j});
                csv_data{i,12,j,num_pairs} = OrbitData.PRN{j};
                csv_data{i,20,j,num_pairs} = OrbitData.date{j};
                csv_data{i,21,j,num_pairs} = OrbitData.Bstar(j);
                csv_data{i,22,j,num_pairs} = OrbitData.BC(j);
                j = sat2;
            end
        end
    end
end
%% 3D Visuals module 
% Add path to the Earth plotting function and TLE data preparation 
addpath([pwd, '\Plot Earth']);  
addpath([pwd, '\TLE Plotter']); 
% Simulation Start Date 
simStart = start_time; 
% Compute sidereal time 
GMST = utc2gmst(datevec(simStart)); % [rad]  
% Create a time vector 
tSim = linspace(start_time_unix, end_time_unix, num_steps); 
% Allocate space  
RSave = NaN(length(tSim), 3, num_satellites); 
%% Visibility Algorithm
addpath([pwd, '\SGP4']);
OrbitDataProp = OrbitData;
num_pairs = 0;
tic; % Runtime start
for sat1=1:num_satellites-1
    for sat2=sat1+1:num_satellites
        num_pairs= num_pairs + 1;
        num_windows = 0;
        step_count=1;
        
        for t=t:increment:t_end % Simulation time and time discretization
            % Time since the simulation started
            
            tsince = (t- start_time_unix)/60; % from [s] to [min] for sgp4 function
            
            i = sat1;
            
            for x=1:2
                [pos, vel, OrbitDataProp] = sgp4(tsince, OrbitData, i);
                OrbitDataProp.a(i) = ( mu / OrbitDataProp.n(i)^2 )^(1/3);
                OrbitDataProp.q(i) = OrbitDataProp.a(i)*(1-OrbitDataProp.e(i));
                % Step 1- Finding unperturbed mean motion
                if OrbitDataProp.e(i)>= 0
                    n(i) = OrbitDataProp.n(i);
                else
                    error('Eccentricity cannot be a negative value')
                end
                % Step 2- Solving Mean Anomaly
                M(i) = n(i)*(t-OrbitData.T(i));
                % Step 3- Finding true anomaly
                if OrbitDataProp.e(i) > 1
                    Fn(i) = 6*M(i);
                    error = 1;
                    
                    while error > 1e-8
                        
                        Fn1(i) = Fn(i) + (M(i)-OrbitDataProp.e(i)*sinh(Fn(i))+Fn(i))/(OrbitDataProp.e(i)*cosh(Fn(i))-1);
                        error = abs(Fn1(i)-Fn(i));
                        Fn(i) = Fn1(i);
                        
                    end
                    f(i) = atan((-sinh(Fn(i))*sqrt(OrbitDataProp.e(i)^2-1))/(cosh(Fn(i))-OrbitDataProp.e(i)));
                elseif OrbitDataProp.e(i) == 1
                    
                    A(i) = (3/2)*M(i);
                    B(i) = (sqrt(A(i)^2+1)+A(i))^(1/3);
                    C(i) = B(i)-1/B(i);
                    f(i) = 2*atan(C(i));
                elseif OrbitDataProp.e(i)< 1 && OrbitDataProp.e(i)>= 0
                    
                    % Convert mean anomaly to true anomaly.
                    
                    % First, compute the eccentric anomaly.
                    
                    Ea = Keplers_Eqn(M(i),OrbitDataProp.e(i));
                    % Compute the true anomaly f.
                    y = sin(Ea)*sqrt(1-OrbitDataProp.e(i)^2)/(1-OrbitDataProp.e(i)*cos(Ea));
                    z = (cos(Ea)-OrbitDataProp.e(i))/(1-OrbitDataProp.e(i)*cos(Ea));
                    f(i) = atan2(y,z);
                else
                    error('Eccentricity cannot be a negative value')
                end
                % Step 4- Finding primary body center to satellite distance               
                r(i) = (1+OrbitDataProp.e(i))*OrbitDataProp.q(i)/(1+OrbitDataProp.e(i)*cos(f(i)));
                % Step 5- Finding standard orientation vectors
                Px(i) = cos(OrbitDataProp.omega(i))*cos(OrbitDataProp.RAAN(i))-sin(OrbitDataProp.omega(i))*sin(OrbitDataProp.RAAN(i))*cos(OrbitDataProp.i(i));
                Py(i) = cos(OrbitDataProp.omega(i))*sin(OrbitDataProp.RAAN(i))+sin(OrbitDataProp.omega(i))*cos(OrbitDataProp.RAAN(i))*cos(OrbitDataProp.i(i));
                Pz(i) = sin(OrbitDataProp.omega(i))*sin(OrbitDataProp.i(i));
                Qx(i) =-sin(OrbitDataProp.omega(i))*cos(OrbitDataProp.RAAN(i))+cos(OrbitDataProp.omega(i))*sin(OrbitDataProp.RAAN(i))*cos(OrbitDataProp.i(i));
                Qy(i) =-sin(OrbitDataProp.omega(i))*sin(OrbitDataProp.RAAN(i))+cos(OrbitDataProp.omega(i))*cos(OrbitDataProp.RAAN(i))*cos(OrbitDataProp.i(i));
                Qz(i) = cos(OrbitDataProp.omega(i))*sin(OrbitDataProp.i(i));
                % Step 6- Finding components of the primary body center to satellite vector in the orbital plane
                xi(i) = r(i)*cos(f(i));
                eta(i) = r(i)*sin(f(i));
                % Step 7- Finding primary body center to satellite vector
                r_fullvector = xi(i)*[Px(i) Py(i) Pz(i)] + eta(i)*[Qx(i) Qy(i) Qz(i)];
                for j=1:3
                    r_vector(i,j) = r_fullvector(j);
                end
                % Step 8- Finding Parameter or Semi-parameter
                parameter(i) = OrbitDataProp.a(i)*(1-OrbitDataProp.e(i)^2);
                % Step 9- Transformation for 3D visuals
                % Adjust RAAN such that we are consisten with Earth's current orientation. This is a conversion to Longitude of the
                % Ascending Node (LAN).
                RAAN2 = OrbitDataProp.RAAN(i)- GMST;
                % Convert to ECI and save the data.
                [X,V] = COE2RV(OrbitDataProp.a(i), OrbitDataProp.e(i), OrbitDataProp.i(i),RAAN2, OrbitDataProp.omega(i), M(i));
                RSave(step_count,:,i) = X';
                % csv insertion
                csv_data{step_count,13,i,num_pairs} = OrbitDataProp.i(i);
                csv_data{step_count,14,i,num_pairs} = OrbitDataProp.RAAN(i);
                csv_data{step_count,15,i,num_pairs} = OrbitDataProp.omega(i);
                csv_data{step_count,16,i,num_pairs} = M(i);
                csv_data{step_count,17,i,num_pairs} = OrbitDataProp.n(i);
                csv_data{step_count,18,i,num_pairs} = OrbitDataProp.a(i);
                csv_data{step_count,19,i,num_pairs} = OrbitDataProp.e(i);
                csv_data{step_count,23,i,num_pairs} = f(i);
                csv_data{step_count,24,i,num_pairs} = xi(i);
                csv_data{step_count,25,i,num_pairs} = eta(i);
                csv_data{step_count,26,i,num_pairs} = parameter(i);
                csv_data{step_count,27,i,num_pairs} = r(i);
                
                i = sat2;
            end
            
            % Step 10- Solving visibility equation
            P1 = [Px(sat1) Py(sat1) Pz(sat1)];
            P2 = [Px(sat2) Py(sat2) Pz(sat2)];
            Q1 = [Qx(sat1) Qy(sat1) Qz(sat1)];
            Q2 = [Qx(sat2) Qy(sat2) Qz(sat2)];
            A1 = dot(P1,P2);
            A2 = dot(Q1,P2);
            A3 = dot(P1,Q2);
            A4 = dot(Q1,Q2);
            sin_gamma = A2/sqrt(A1^2+A2^2);
            cos_gamma = A1/sqrt(A1^2+A2^2);
            sin_psi = A4/sqrt(A3^2+A4^2);
            cos_psi = A3/sqrt(A3^2+A4^2);
            D1 = sqrt(A1^2+A2^2);
            D2 = sqrt(A3^2+A4^2);
            
            r1dotr2complex = (parameter(sat1)*parameter(sat2)/((1+OrbitDataProp.e(sat1)*cos(f(sat1)))*(1+OrbitDataProp.e(sat2)*cos(f(sat2)))))* ...
                (D1*cos(f(sat2))*(cos_gamma*cos(f(sat1))+sin_gamma*sin(f(sat1)))+D2*sin(f(sat2))*(cos_psi*cos(f(sat1))+sin_psi*sin(f(sat1))));
            % Visibility condition
            Rcomplex(step_count, num_pairs) = parameter(sat1)^2 * parameter(sat2)^2 * ( D1*cos(f(sat2))*(cos_gamma*cos(f(sat1))+sin_gamma*sin(f(sat1))) + ...
                D2*sin(f(sat2))*(cos_psi*cos(f(sat1))+sin_psi*sin(f(sat1))) )^2-parameter(sat1)^2*parameter(sat2)^2 + S^2*parameter(sat1)^2* ...
                (1+OrbitDataProp.e(sat2)*cos(f(sat2)))^2 + parameter(sat2)^2*(1+OrbitDataProp.e(sat1)*cos(f(sat1)))^2- ...
                2*S^2*parameter(sat1)*parameter(sat2)* ( D1*cos(f(sat2))* ( cos_gamma*cos(f(sat1))+sin_gamma*sin(f(sat1)) ) + D2*sin(f(sat2))* ( ...
                cos_psi*cos(f(sat1))+sin_psi*sin(f(sat1)) ) ) * (1+OrbitDataProp.e(sat1)*cos(f(sat1))) * (1+OrbitDataProp.e(sat2)*cos(f(sat2)));
            
            Rv = sqrt((r(sat1)^2 * r(sat2)^2- r1dotr2complex^2)/(r(sat1)^2 + r(sat2)^2- 2*r1dotr2complex))- body_radius;
            
            % Step 9: Print Results for the given epoch time
            pair_result = 'The result for %s%s and %s%s at %s is %d ';
            
            visibility = '--- Direct line of sight';
            
            non_visibility= '---Non visibility';
            t_todatetime = datetime(t, 'ConvertFrom', 'posixtime');
            result_to_log = sprintf(pair_result, OrbitData.ID{sat1}, OrbitData.designation{sat1}, OrbitData.ID{sat2}, OrbitData.designation{sat2}, t_todatetime, ...
                Rcomplex(step_count, num_pairs));
            
            fprintf(result_to_log); % Command window print
            
            if Rcomplex(step_count, num_pairs)< 0
                disp(visibility); % Command window print
                fprintf(fid_log, '%s: %s%s\n', datestr(datetime('now', 'TimeZone', 'UTC')), result_to_log, visibility); % Appending visibility analysis result to log file
            else
                disp(non_visibility); % Command window print
                fprintf(fid_log, '%s: %s%s\n', datestr(datetime('now', 'TimeZone', 'UTC')), result_to_log, non_visibility); % Appending visibility analysis result to ... log file
            end
            % Pathfinder feed
            if Rcomplex(step_count,num_pairs)< 0 && (step_count == 1 || Rcomplex(step_count-1,num_pairs) >= 0)
                
                num_windows = num_windows + 1;
                WindowsData.start(sat1,sat2,num_windows) = t;
                WindowsData.start(sat2,sat1,num_windows) = WindowsData.start(sat1,sat2,num_windows);
            end
            if step_count > 1
                
                if Rcomplex(step_count,num_pairs) >= 0 && Rcomplex(step_count-1,num_pairs)< 0
                    WindowsData.end(sat1,sat2,num_windows) = t;
                    WindowsData.time(sat1,sat2,num_windows) = t-WindowsData.start(sat1,sat2,num_windows);
                    WindowsData.end(sat2,sat1,num_windows) = WindowsData.end(sat1,sat2,num_windows);
                    WindowsData.time(sat2,sat1,num_windows) = WindowsData.time(sat1,sat2,num_windows);
                end
            end
            if step_count > 1
                if Rcomplex(step_count,num_pairs)< 0 && Rcomplex(step_count-1,num_pairs) < 0 && step_count == num_steps
                    WindowsData.end(sat1,sat2,num_windows) = t;
                    WindowsData.time(sat1,sat2,num_windows) = t-WindowsData.start(sat1,sat2,num_windows);
                    WindowsData.end(sat2,sat1,num_windows) = WindowsData.end(sat1,sat2,num_windows);
                    WindowsData.time(sat2,sat1,num_windows) = WindowsData.time(sat1,sat2,num_windows);
                end
            end
            % CSV insertion
            
            csv_data{step_count,3,sat1,num_pairs} = t_todatetime;
            csv_data{step_count,4,sat1,num_pairs} = t;
            csv_data{step_count,3,sat2,num_pairs} = t_todatetime;
            csv_data{step_count,4,sat2,num_pairs} = t;
            csv_data{step_count,5,sat1,num_pairs} = strcat(OrbitData.ID{sat1},OrbitData.designation{sat1});
            csv_data{step_count,6,sat1,num_pairs} = strcat(OrbitData.ID{sat2},OrbitData.designation{sat2});
            csv_data{step_count,5,sat2,num_pairs} = strcat(OrbitData.ID{sat1},OrbitData.designation{sat1});
            csv_data{step_count,6,sat2,num_pairs} = strcat(OrbitData.ID{sat2},OrbitData.designation{sat2});
            csv_data{step_count,9,sat1,num_pairs} = Rcomplex(step_count,num_pairs);
            csv_data{step_count,10,sat1,num_pairs} = Rv;
            csv_data{step_count,9,sat2,num_pairs} = Rcomplex(step_count,num_pairs);
            csv_data{step_count,10,sat2,num_pairs} = Rv;
                
            step_count = step_count + 1;
        end
        t = start_time_unix;
    end
end
toc; % Runtime end 
%% CSV output file module
if isfile(fullfile([pwd, '\Data Output Files'],'InterlinkData.csv'))
else
    disp('Creating CSV file...') % Command window print
    fprintf(fid_log, '%s: %s\n', datestr(datetime('now', 'TimeZone', 'UTC')), 'Creating CSV file...'); % Log print
    fid_csv = fopen(fullfile([pwd, '\Data Output Files'],'InterlinkData.csv'), 'w');
    if fid_csv == -1
        error('Cannot open file');
    end
    headers = {'Simulation ID', 'Analysis', 'Simulation Date Time', 'Simualtion Unix Time', 'Satellite 1', 'Satellite 2', 'Satellites Number', 'Satellites Names', ...
        'R Visibility', 'R Margin', 'Satellite ID', 'PRN', ...
        'Inclination', 'RAAN', 'Argument periapsis', 'Mean Anomaly', 'Mean Motion', 'Semimajor axis', 'Eccentricity', 'TLE Date', 'Bstar', 'Ballistic Coefficient', 'True Anomaly', 'Xi', 'Eta', 'Parameter', 'R vector'};
fprintf(fid_csv,'%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s\n', headers{1:27});
end
disp('Inserting data to CSV file...') % Command window print
fprintf(fid_log, '%s: %s\n', datestr(datetime('now', 'TimeZone', 'UTC')), 'Inserting data to CSV file...'); % Log print
fid_csv = fopen(fullfile([pwd, '\Data Output Files'],'InterlinkData.csv'), 'a');

if fid_csv>0
    num_pairs = 0;
    
    for sat1=1:num_satellites-1
        for sat2=sat1+1:num_satellites
            num_pairs = num_pairs + 1;
            for i=1:num_steps
                j = sat1;
                for x=1:2
                    fprintf(fid_csv,'%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s\n',csv_data{i,:,j,num_pairs});
                    j = sat2;
                end
            end
        end
    end
end
fclose(fid_csv); % Closing InterlinkData csv file
fclose(fid_log); % Closing log file
%% Plot the orbit 
% Plot the Earth 
% If you want a color Earth, use 'neomap', 'BlueMarble' 
% If you want a black and white Earth, use 'neomap', 'BlueMarble 
% A smaller sample step gives a finer resolution Earth 
disp('Opening plot module...') % Command window print
fid_log = fopen(fullfile([pwd, '/logs'], full_name_log), 'a'); % Setting log file to append mode
if fid_log == -1
    error('Cannot open log file.');
end
fprintf(fid_log, '%s: %s\n', datestr(datetime('now', 'TimeZone', 'UTC')), 'Opening plot module...');
fclose(fid_log); % Closing log file
% Simualtion Unix time vector converted to DateTimes strings inside a cell
tSim_strings = {step_count-1};
for t=1:step_count-1
    tSim_strings{t} = datestr(datetime(tSim(t),'ConvertFrom','posixtime'));
end
plot_list = {'Static Plot', 'Live Plots. See color legend in 1 vs 1 plot to identify satellites. It may take a lot of time MP4 Animation will be created in Data Output Files (Warning: do not move the figure windows while recording).'};

[indx,tf] = listdlg('ListString',plot_list,'Name','3D Plot','PromptString','Select a plot mode:','SelectionMode','single','ListSize',[1000,300],'OKString','Plot','CancelString','Quit');

colors = lines(num_satellites);

if indx == 2
    
    % Static plot
    
    h1 = plotearth('neomap', 'BlueMarble bw', 'SampleStep', 1);
    
    for i=1:num_satellites
        
        plot3(RSave(:,1,i) / body_radius, RSave(:,2,i) / body_radius, RSave(:,3,i) / body_radius,...
            'color', colors(i,:), 'LineWidth', 1, 'DisplayName', strcat(OrbitData.ID{i}, OrbitData.designation{i},'- Orbit'))
        plot3(RSave(1,1,i) / body_radius, RSave(1,2,i) / body_radius, RSave(1,3,i) / body_radius,...
            '.', 'color', colors(i,:), 'MarkerSize', 30, 'DisplayName', strcat(OrbitData.ID{i}, OrbitData.designation{i},'- Starting Point'))
    end
    lgd2 = legend('AutoUpdate', 'off');
    % Live 3D plot
    
    disp('Do not maximize Live Plot window (animation being recorded)') % Command window print
    
    fid_log = fopen(fullfile([pwd, '/logs'], full_name_log), 'a'); % Setting log file to append mode
    if fid_log == -1
        error('Cannot open log file.');
    end
    fprintf(fid_log, '%s: %s\n', datestr(datetime('now', 'TimeZone', 'UTC')), 'Do not maximize Live Plot window (animation being recorded)');
    fprintf(fid_log, '%s: %s\n', datestr(datetime('now', 'TimeZone', 'UTC')), 'The video''s width and height has been padded to be a multiple of two as required by the H.264 codec');
    fclose(fid_log); % Closing log file
    
    num_pairs = 0;
    num_frames = 0;
    % Counting number of frames for preallocation
    for sat1=1:num_satellites-1
        for sat2=sat1+1:num_satellites
            num_pairs = num_pairs + 1;
            for t=1:step            
                count-1
                for x=1:2
                    num_frames = num_frames + 1;
                end
            end
        end
        
    end
    
    Frames = moviein(num_frames);
    num_pairs = 0;
    % Create the video writer with the desired fps
    
    writerObj = VideoWriter(fullfile([pwd, 'nData Output Files'],sprintf('LivePlot-%s.mp4',sprintf('%s-%s',date_log,name_log{i}))), 'MPEG-4');
    writerObj.FrameRate = 10;
    % Set the seconds per image
    % Open the video writer
    open(writerObj);
    h2 = plotearth('neomap', 'BlueMarble bw', 'SampleStep', 1);
    
    for sat1=1:num_satellites-1
        for sat2=sat1+1:num_satellites
            num_pairs = num_pairs + 1;
            hold on
            for t=1:step_count-1
                i = sat1;
                
                for x=1:2
                    if Rcomplex(t, num_pairs)< 0 && i == sat1
                        curve = animatedline('LineWidth',2,'color', [100, 255, 110] / 255, 'DisplayName', 'Visibility', 'HandleVisibility', 'on'); % Green color
                    elseif Rcomplex(t, num_pairs) >= 0 && i == sat1
                        curve = animatedline('LineWidth',2,'color', [225, 90, 90] / 255, 'DisplayName', 'Non-visibility', 'HandleVisibility', 'on'); % Red color
                        
                    elseif Rcomplex(t, num_pairs)< 0 && i == sat2
                        
                        curve = animatedline('LineWidth',2,'color', [100, 255, 110] / 255, 'DisplayName', 'Visibility', 'HandleVisibility', 'off'); % Green color
                    elseif Rcomplex(t, num_pairs) >= 0 && i == sat2
                        curve = animatedline('LineWidth',2,'color', [225, 90, 90] / 255, 'DisplayName', 'Non-visibility', 'HandleVisibility', 'off'); % Red color
                    end
                    
                    if i == sat1
                        head1 = scatter3(RSave(t,1,sat1) / body_radius, RSave(t,2,sat1) / body_radius, RSave(t,3,sat1) / body_radius, 'filled', 'MarkerFaceColor', colors(sat1,:),...
                            'DisplayName', strcat(OrbitData.IDfsat1g, OrbitData.designationfsat1g), 'HandleVisibility', 'on');
                    elseif i == sat2
                        head2 = scatter3(RSave(t,1,sat2) / body_radius, RSave(t,2,sat2) / body_radius, RSave(t,3,sat2) / body_radius, 'filled', 'MarkerFaceColor', colors(sat2,:),...
                            'DisplayName', strcat(OrbitData.IDfsat2g, OrbitData.designationfsat2g), 'HandleVisibility', 'on');
                    end
                    addpoints(curve, RSave(1:t,1,i) / body_radius, RSave(1:t,2,i) / body_radius, RSave(1:t,3,i) / body_radius);
                    drawnow;
                    F = getframe(gcf);
                    
                    writeVideo(writerObj, F);
                    pause(0.01)
                    i = sat2;
                end
                lgd = legend(tSim_strings{t});
                lgd.FontSize = 15;
                delete(head1);
                delete(head2);
            end
        end
    end
    % Close the writer object
    close(writerObj);
elseif indx == 1
    % Static plot
    
    h1 = plotearth('neomap', 'BlueMarble bw', 'SampleStep', 1);
    for i=1:num_satellites
        plot3(RSave(:,1,i) / body_radius, RSave(:,2,i) / body_radius, RSave(:,3,i) / body_radius,...
            'color', colors(i,:), 'LineWidth', 1, 'DisplayName', strcat(OrbitData.ID{i}, OrbitData.designation{i},'- Orbit'))
        plot3(RSave(1,1,i) / body_radius, RSave(1,2,i) / body_radius, RSave(1,3,i) / body_radius,'.', 'color', colors(i,:), 'MarkerSize', 30, 'DisplayName', strcat(OrbitData.ID{i}, OrbitData.designation{i},'- Starting Point'))
    end
    lgd2 = legend();
end


