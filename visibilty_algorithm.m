mu = 3.986E14;


n = 15.72125391; % Mean motion
e = 0.0006703; % eccentricity
omega = 130.536; %w Argument of perigee 
RAAN = 

t1 = datetime('2020-12-24 22:05:24');
t1.TimeZone = 'Europe/London';
t = posixtime(t1) % Simulation Time

te = datetime('2020-05-24 22:05:24');
te.TimeZone = 'Europe/London';
T = posixtime(te) % Epoch Time from TLE extracted (array later)
for i=1:2
    
    a(i) = (mu/n(i)^2 )^(1/3);
    q(i) = a(i)*(1-e(i));
    
    % Step 1 ¡ Finding unperturbed mean motion
    if e(i) >= 0
        n(i) = n(i);
    else
        error('Eccentricity cannot be a negative value')
    end
    % Step 2 ¡ Solving Mean Anomaly
    M(i) = n(i)*(t-T(i));
    
    % Step 3 ¡ Finding true anomaly
    if e(i) > 1
        Fn(i) = 6*M(i);
        error = 1;
        while error > 1e-8
            Fn1(i) = Fn(i)+(M(i)-e(i)*sinh(Fn(i))+Fn(i))/(e(i)*cosh(Fn(i))-1);
            error = abs(Fn1(i)-Fn(i));
            Fn(i) = Fn1(i);
        end
        
        f(i) = atan((-sinh(Fn(i))*sqrt(e(i)^2-1))/(cosh(Fn(i))-e(i)));
        
    elseif e(i) == 1
        A(i) = (3/2)*M(i);
        B(i) = (sqrt(A(i)^2+1)+A(i))^(1/3);
        C(i) = B(i)-1/B(i);
        f(i) = 2*atan(C(i));
        
    elseif e(i) < 1 && e(i) >= 0
        % Convert mean anomaly to true anomaly.
        % First, compute the eccentric anomaly.
        Ea = Keplers_Eqn(M(i),e(i));
        
        % Compute the true anomaly f.
        y = sin(Ea)*sqrt(1-e(i)^2)/(1-e(i)*cos(Ea));
        z = (cos(Ea)-e(i))/(1-e(i)*cos(Ea));
        
        f(i) = atan2(y,z);
    else
        error('Eccentricity cannot be a negative value')
    end
    
    % Step 4 ¡ Finding primary body center to satellite distance
    r(i) = (1+e(i))*q(i)/(1+e(i)*cos(f(i)));
    
    % Step 5 ¡ Finding standard orientation vectors
    Px(i) = cos(omega(i))*cos(RAAN(i))-sin(omega(i))*sin(RAAN(i))*cos(inc(i));
    Py(i) = cos(omega(i))*sin(RAAN(i))+sin(omega(i))*cos(RAAN(i))*cos(inc(i));
    Pz(i) = sin(omega(i))*sin(inc(i));
    Qx(i) = -sin(omega(i))*cos(RAAN(i))+cos(omega(i))*sin(RAAN(i))*cos(inc(i));
    Qy(i) = -sin(omega(i))*sin(RAAN(i))+cos(omega(i))*cos(RAAN(i))*cos(inc(i));
    Qz(i) = cos(omega(i))*sin(inc(i));
    
    % Step 6 ¡ Finding components of the primary body center to satellite vector in the orbital plane
    xi(i) = r(i)*cos(f(i));
    eta(i) = r(i)*sin(f(i));
    
    % Step 7 ¡ Finding primary body center to satellite vector
    r_fullvector = xi(i)*[Px(i) Py(i) Pz(i)] + eta(i)*[Qx(i) Qy(i) Qz(i)];
    for j=1:3
        r_vector(i,j) = r_fullvector(j);
    end
    
    % Step 8 ¡ Finding Parameter or Semi¡parameter
    parameter(i) = a(i)*(1-e(i)^2);
    
end

% Step 9 ¡ Solving visibility equation

sat1=1;
sat2=2;

P1 = [Px(sat1) Py(sat1) Pz(sat1)];
P2 = [Px(sat2) Py(sat2) Pz(sat2)];
Q1 = [Qx(sat1) Qy(sat1) Qz(sat1)];
Q2 = [Qx(sat2) Qy(sat2) Qz(sat2)];
A1 = dot(P1,P2);
A2 = dot(Q1,P2);
A3 = dot(P1,Q2);
A4 = dot(Q1,Q2);

D1 = sqrt(A1^2+A2^2);
D2 = sqrt(A3^2+A4^2);

r1dotr2complex = (parameter(sat1)*parameter(sat2)/...
    ((1+e(sat1)*cos(f(sat1)))*(1+e(sat2)*...
    cos(f(sat2)))))*(D1*cos(f(sat2))*(cos_gamma*cos(f(sat1))+sin_gamma*...
    sin(f(sat1)))+D2*sin(f(sat2))*(cos_psi*cos(f(sat1))+sin_psi*sin(f(sat1))));

Rcomplex = parameter(sat1)^2*parameter(sat2)^2*(D1*cos(f(sat2))*(cos_gamma*cos(f(sat1))+sin_gamma*sin(f(sat1)))+D2*sin(f(sat2))*(cos_psi*cos(f(sat1))+sin_psi*sin(f(sat1))) )^2-parameter(sat1)^2*parameter(sat2)^2+S^2*(parameter(sat1)^2*...
    (1+e(sat2)*cos(f(sat2)))^2+parameter(sat2)^2*...
    (1+e(sat1)*cos(f(sat1)))^2)-2*S^2*parameter(sat1)...
    *parameter(sat2)*(D1*cos(f(sat2))*(cos_gamma*cos(f(sat1))+sin_gamma*...
    sin(f(sat1)))+D2*sin(f(sat2))*(cos_psi*cos(f(sat1))+sin_psi*...
    sin(f(sat1))))*(1+e(sat1)*cos(f(sat1)))*...
    (1+e(sat2)*cos(f(sat2)));

Rv = sqrt((r(sat1)^2 * r(sat2)^2 - r1dotr2complex^2)/(r(sat1)^2+ r(sat2)^2-2*r1dotr2complex))-body_radius;

% Step 10: Print Results for the given epoch time
pair_result = 'The result for %s%s and %s%s at %s is %d ';
visibility = '¡¡¡ Direct line of sight';
non_visibility= '¡¡¡ Non¡visibility';

t_todatetime = datetime(t, 'ConvertFrom', 'posixtime');

result_to_log = sprintf(pair_result, ID{sat1}, designation{sat1},ID{sat2}, designation{sat2}, t_todatetime, Rcomplex{num});
fprintf(result_to_log); % Command window print

if Rcomplex < 0
    disp(visibility); % Command window print
    fprintf(fid_log, '%s: %s%s\n', datestr(datetime('now', 'TimeZone', ...
        'UTC')), result_to_log, visibility); % Appending visibility analysis ...
    result to log file
else
    disp(non_visibility); % Command window print
    fprintf(fid_log, '%s: %s%s\n', datestr(datetime('now', 'TimeZone', ...
        'UTC')), result_to_log, non_visibility); % Appending visibility ...
    analysis result to log file
end