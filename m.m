% Main script
clc; clearvars -except compiled; close all;

if exist('compiled', 'var') == 0
    fprintf('Mexing the subsystem\n');
    mex ./modelR2016bMAC/Subsystem_sf.c ...
        ./modelR2016bMAC/Subsystem_sfcn_rtw/rtGetNaN.c ...
        ./modelR2016bMAC/Subsystem_sfcn_rtw/rtGetInf.c
    compiled = true;
end

addpath(genpath('./modelR2016bMAC/'));
modelR2016bMAC;

% Example case, decides initial condition and thrust
model_case = 6;

% Various states of simulation
CurrentEnabled    = 1;
HiPAPpeaksEnabled = 1;
SensNoiseEnabled  = 1;
WavesEnabled      = 1;

% Defining constants for framsforming between radians and degrees
deg2rad = pi/180;
rad2deg =180/pi;

% Vessel model
Ma = [290 0   0   0;
    0   300 0   0;
    0   0   330 0;
    0   0   0   55];

Mrb = [460 0   0   0;
    0   460 0   0;
    0   0   460 0;
    0   0   0   105];

M = Ma + Mrb;

D    = [234 0   0   0;
    0   292 0   0;
    0   0   263 0;
    0   0   0   25];

g = [0,0,5,0];

% Wave model
Omega = diag([0.7,0.7,0.7,3]); % TUNING
Lambda = diag([0.06,0.06,0.02,0.1]); % TUNING
Aw = [zeros(4), eye(4); -Omega^2, -2*Lambda*Omega];
Kw = diag([0.2,0.2,1.0,0.2]); % TUNING
Ew = blkdiag(zeros(4,4), Kw);
Cw = [zeros(4), eye(4)];

% Bias model
Tb = diag([15,5,85,100]); % TUNING
Eb = diag([20,30,20,1]); % TUNING

% EKF
T = 0.2;
B = [zeros(8,4); zeros(4,4); zeros(4,4); inv(M)];
E = blkdiag(Ew, zeros(4), Eb, zeros(4));
H = [Cw, eye(4), zeros(4), zeros(4)];
Q = blkdiag(zeros(4), diag([10,10,10,10]), 0.1*eye(4), diag([0.1,0.1,0.1,0.1]), 0.1*eye(4)); % TUNING
R = diag([0.014, 0.0141, 0.0148, 7.5122e-5]); % TUNING

% Controller
% Tuned for less than 0.2 m error in surge and sway, 0.1 m in heave and 2
% degrees in yaw during 240 seconds
Gd = diag([200 200 300 450]);
Gp = diag([500 100 150 30]);
Gi = diag([100 30 30 80]);
Gpd = [Gp Gd];


switch model_case
    case 1
        % Initial condition of the system
        Eta0 = [0; 0; 2; 0; 0; 45*pi/180]';
        % Constant thrust given by the vessel
        u = [0, 0, 5, 0]';
    case 2
        Eta0 = [0; 0; 300; 0; 0; 45*pi/180]';
        u = [300, 0, 0, 0]';
    case 3
        Eta0 = [0; 0; 300; 0; 0; 45*pi/180]';
        u = [100, 0, 0, 0.2]';
    case 4
        Eta0 = [0; 0; 1; 0; 0; 45*pi/180]';
        u = [0, 0, 320, 0.012]';
        
    case 5
        Eta0 = [0; 0; 200; 0; 0; 0;]';
        pos.x = [Eta0(1) Eta0(1)];
        pos.y = [Eta0(2) Eta0(2)] ;
        pos.z = [Eta0(3) Eta0(3)];
        pos.psi =[Eta0(6) Eta0(6)];
        
        
    case 6
        Eta0 = [0; 0; 200; 0; 0; 0;]';
        pos.x = [Eta0(1) 0];
        pos.y = [Eta0(2) 0] ;
        pos.z = [Eta0(3) 200];
        pos.psi =[Eta0(6) 320*deg2rad ];
        
        
    case 7
        
        Eta0 = [0; 0; 200; 0; 0; 0;]';
        pos.x = [Eta0(1) 100];
        pos.y = [Eta0(2) 60] ;
        pos.z = [Eta0(3) 150];
        pos.psi =[Eta0(6) 320*deg2rad];
        
        
    case 8
        
        Eta0 = [0; 0; 1; 0; 0; 0;]';
        pos.x = [Eta0(1) 10];
        pos.y = [Eta0(2) Eta0(2)] ;
        pos.z = [Eta0(3) 5];
        pos.psi =[Eta0(6) Eta0(6)];
        
end

% Initial values:
x0 = [zeros(1,8),Eta0(1:3),Eta0(6),zeros(1,8)];
P0 = blkdiag(eye(8), eye(4)*10, eye(4), eye(4));
e0 = [0 0 0 0]';
u0 = [0, 0, 0, 0]';
Transf = [cos(Eta0(6)) sin(Eta0(6)) 0 0;
         -sin(Eta0(6)) cos(Eta0(6)) 0 0;
            0             0         1 0;
            0             0         0 1];

% Trajectory generation
time = [0 240];
step = 5;
path = zeros(4, max(time)/step + 1); % Matrix containing the path vectors

t = 0: step: max(time); % Adding time to the path description
path(1,:) = spline(time, pos.x, t); % Path in x direction
path(2,:) = spline(time, pos.y, t); % Path in y direction
path(3,:) = spline(time, pos.z, t); % Path in z direction
path(4,:) = spline(time, pos.psi, t); % Path for the heading

