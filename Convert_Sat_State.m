%-------------------------------------------------------------------
%------------------------- Convert_Sat_State -----------------------
% Meysam Mahooti (2020). SGP4 (https://www.mathworks.com/matlabcentral/fileexchange/62013-sgp4), 
% MATLAB Central File Exchange. Retrieved December 28, 2020.
%-------------------------------------------------------------------
function [p, v] = Convert_Sat_State(pos, vel)
xkmper = 6378.135;
p = zeros(3,1);
v = zeros(3,1);
for i=1:3
    p(i) = pos.v(i) * xkmper;
    v(i) = vel.v(i) * xkmper / 60;
end
