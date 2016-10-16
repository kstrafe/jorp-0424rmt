% Main script
clc; clear all; close all;

fprintf('Mexing the subsystem\n');
mex ./modelR2016bMAC/Subsystem_sf.c ...
	./modelR2016bMAC/Subsystem_sfcn_rtw/rtGetNaN.c ...
	./modelR2016bMAC/Subsystem_sfcn_rtw/rtGetInf.c

addpath(genpath('./modelR2016bMAC/'));
modelR2016bMAC;

m_rb = [460  0     0   0; ...
        0    460   0   0; ...
        0    0     460 0; ...
        0    0     0   105];

m_a = [290 0   0   0; ...
       0   300 0   0; ...
       0   0   330 0; ...
       0   0   0   55];

m_tot = m_a + m_rb;

d_l = [234 0   0   0; ...
       0   292 0   0; ...
       0   0   263 0; ...
       0   0   0   25];

j = @(phi) [cos(phi) -sin(phi) 0 0; ...
            sin(phi) cos(phi)  0 0; ...
            0        0         1 0; ...
            0        0         0 1];

Eta0 = [0; 0; 2; 45*pi/180; 0; 0]';
CurrentEnabled    = 0;
HiPAPpeaksEnabled = 0;
SensNoiseEnabled  = 0;
WavesEnabled      = 0;

surge_thrust = [-220 480];
sway_thrust  = [-220 220];
heave_thrust = [-180 390];

A = eye(5);
B = eye(5);
D = eye(5);
K = -2*eye(5);
U0 = [0, 0, 5, 0]'; 

