function Chapter6_SystemCharacterisationApp
%CHAPTER6_SYSTEMCHARACTERISATIONAPP Interactive GUI for MEC3079S Chapter 6 — System characterisation.
%
%   Run Chapter6_SystemCharacterisationApp to open the app. The tabs follow the chapter:
%     1. First-order         (6.1-6.2): K/(s − p) and K(s − z)/(s − p); forced
%        and natural response, steady-state value, time constant, settling
%        time and initial slope.
%     2. Second-order types  (6.3-6.4): overdamped, critically damped,
%        underdamped and undamped responses (Table 6.1, Fig 6.6).
%     3. Underdamped specs   (6.5): peak time, percentage overshoot and
%        settling time, and the matching pole locations (Fig 6.8).
%     4. Extra poles & zeros (6.6-6.7): dominant poles, model order reduction,
%        leading/lagging responses, nonminimum phase and approximate
%        pole-zero cancellation.
%     5. Identify from data  (6.2.4, 6.5.7): measure a step response and
%        build a first- or second-order model from it.
%
%   Interaction: drag the poles (x) and zeros (o) in the s-plane plots, and
%   the markers on the response plots (steady-state lines, T_c, T_p/y_max,
%   T_s, measurement cursors).
%
%   Transfer functions are entered as MATLAB expressions in s, for example
%   2/(s+6) or 9/(s^2+0.9*s+9).
%
%   Requires the Control System Toolbox.

cOrange = [0.85 0.33 0.10];
cBlue   = [0.00 0.45 0.74];
cPurple = [0.49 0.18 0.56];
cGreen  = [0.47 0.67 0.19];
cRed    = [0.85 0.10 0.10];
cGrey   = [0.60 0.60 0.60];
cOS     = [0.40 0.58 0.90];     % Fig 6.8 colours
cTs     = [0.90 0.40 0.40];
cTp     = [0.70 0.40 0.62];

fig = uifigure('Name','MEC3079S Chapter 6 — System characterisation', ...
    'Position',[50 40 1340 860]);
mainGrid = uigridlayout(fig,[1 1],'Padding',[0 0 0 0]);
tg = uitabgroup(mainGrid);

% Drag state shared by all interactive plots
drag = struct('active',false,'ax',[],'move',[],'done',[],'p0',[0 0], ...
    'last',[],'xl',[],'yl',[],'t',tic);
fig.WindowButtonMotionFcn = @(~,~) onMotion();
fig.WindowButtonUpFcn = @(~,~) onRelease();

%% =====================================================================
%  Tab 1: First-order systems
%  =====================================================================
t1 = uitab(tg,'Title','First-order');
g1 = uigridlayout(t1,[1 2],'ColumnWidth',{340,'1x'});

c1 = uigridlayout(g1,[11 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{112,22,22,22,22,22,22,22,22,'1x',22});
at(uilabel(c1,'Text',['Step response of a first-order system. The input pole (s = 0) gives the ' ...
    'forced response y_f, the pole of P(s) the natural response y_n = λe^(pt). For p < 0: ' ...
    'T_c = −1/p (63% of the way), T_s ≈ 4T_c (2%). Drag the pole/zero, the T_c marker or the ' ...
    'y∞ line.'],'FontWeight','bold','WordWrap','on'),1,[1 2]);
forms1 = {'K/(s − p)','K(s − z)/(s − p)'};
% name, form, K, p, z, beta
presets1 = { ...
    '6.1.2: P = (s+0.5)/(s+7.5)',              2, 1, -7.5, -0.5, 1
    '6.2: P = 1/(s+5)',                        1, 1, -5,    0,   1
    '6.2.2: P = 2/(s+6) (time constant)',      1, 2, -6,    0,   1
    '6.2.3: P = 6/(s+6) (settling time)',      1, 6, -6,    0,   1
    'Zero closer to 0: P = (s+1)/(s+5)',       2, 1, -5,   -1,   1
    'Zero further out: P = (s+5)/(s+1)',       2, 1, -1,   -5,   1
    'Unstable: P = 1/(s−1)',                   1, 1,  1,    0,   1
    'Custom', [], [], [], [], []};
at(uilabel(c1,'Text','Example'),2,1);
dd1 = at(uidropdown(c1,'Items',presets1(:,1)','Value',presets1{1,1}),2,2);
at(uilabel(c1,'Text','Form of P(s)'),3,1);
dd1F = at(uidropdown(c1,'Items',forms1),3,2);
at(uilabel(c1,'Text','Gain K'),4,1);
ef1K = at(uieditfield(c1,'numeric','Value',1,'ValueDisplayFormat','%.4g'),4,2);
at(uilabel(c1,'Text','Pole p'),5,1);
ef1p = at(uieditfield(c1,'numeric','Value',-5,'ValueDisplayFormat','%.4g'),5,2);
lbl1z = at(uilabel(c1,'Text','Zero z'),6,1);
ef1z = at(uieditfield(c1,'numeric','Value',-0.5,'ValueDisplayFormat','%.4g'),6,2);
at(uilabel(c1,'Text','Step size β'),7,1);
ef1b = at(uieditfield(c1,'numeric','Value',1,'ValueDisplayFormat','%.4g'),7,2);
g1cb = at(uigridlayout(c1,[1 3],'Padding',[0 0 0 0],'ColumnSpacing',4),8,[1 2]);
cb1T = uicheckbox(g1cb,'Text','T_c, T_s','Value',true);
cb1S = uicheckbox(g1cb,'Text','Initial slope','Value',true);
cb1C = uicheckbox(g1cb,'Text','y_f and y_n','Value',false);
at(uilabel(c1,'Text','Results','FontWeight','bold'),9,[1 2]);
ta1 = at(uitextarea(c1,'Editable','off','FontName','Monospaced'),10,[1 2]);
btn1 = at(uibutton(c1,'Text','Update'),11,[1 2]);

r1 = uigridlayout(g1,[3 2],'RowHeight',{'fit','fit','1x'},'ColumnWidth',{'1.5x','1x'});
lbl1P = at(uilabel(r1,'Text','','Interpreter','latex','FontSize',18),1,[1 2]);
lbl1y = at(uilabel(r1,'Text','','Interpreter','latex','FontSize',18),2,[1 2]);
ax1y = at(uiaxes(r1),3,1);
ax1s = at(uiaxes(r1),3,2);
ax1y.Interactions = [];  ax1s.Interactions = [];

dd1.ValueChangedFcn = @(~,~) loadPreset1();
[dd1F.ValueChangedFcn, ef1K.ValueChangedFcn, ef1p.ValueChangedFcn, ef1z.ValueChangedFcn, ...
    ef1b.ValueChangedFcn] = deal(@(~,~) markCustom(dd1,@update1));
[cb1T.ValueChangedFcn, cb1S.ValueChangedFcn, cb1C.ValueChangedFcn] = deal(@(~,~) update1());
btn1.ButtonPushedFcn = @(~,~) update1();

%% =====================================================================
%  Tab 2: Second-order system types
%  =====================================================================
t2 = uitab(tg,'Title','Second-order types');
g2 = uigridlayout(t2,[1 2],'ColumnWidth',{340,'1x'});

c2 = uigridlayout(g2,[11 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{112,22,22,22,22,22,22,22,22,'1x',22});
at(uilabel(c2,'Text',['The damping ratio ζ sets the type of response (Table 6.1); ω_n scales ' ...
    'time. Drag a pole: off the real axis gives a complex pair (underdamped, or undamped on the ' ...
    'jω-axis); on the real axis the poles are real (overdamped, or critically damped when they ' ...
    'meet). Drag the y∞ line to change K.'],'FontWeight','bold','WordWrap','on'),1,[1 2]);
forms2 = {'K/(s² + d₁s + d₂)  (6.3)','Kωₙ²/(s² + 2ζωₙs + ωₙ²)  (6.4)'};
% name, form, K, zeta, wn, compare
presets2 = { ...
    '6.3.1 Overdamped: K = 6, p = −17, −7',      1, 6, 24/(2*sqrt(119)), sqrt(119), false
    '6.3.2 Critically damped: K = 6, p = −17 (×2)', 1, 6, 1, 17, false
    '6.3.3 Underdamped: K = 7, p = −8 ± 16j',     1, 7, 8/sqrt(320), sqrt(320), false
    '6.3.3 Envelope: K = 7, p = −3 ± 36j',        1, 7, 3/sqrt(1305), sqrt(1305), false
    '6.3.4 Undamped: K = 7, p = ±7j',             1, 7, 0, 7, false
    '6.4.3 Fig 6.6: ζ = 0.5, ωₙ = 1.8',           2, 1, 0.5, 1.8, true
    'Custom', [], [], [], [], []};
at(uilabel(c2,'Text','Example'),2,1);
dd2 = at(uidropdown(c2,'Items',presets2(:,1)','Value',presets2{1,1}),2,2);
at(uilabel(c2,'Text','Form of P(s)'),3,1);
dd2F = at(uidropdown(c2,'Items',forms2),3,2);
at(uilabel(c2,'Text','Gain K'),4,1);
ef2K = at(uieditfield(c2,'numeric','Value',1,'ValueDisplayFormat','%.4g'),4,2);
at(uilabel(c2,'Text','Damping ratio ζ'),5,1);
ef2z = at(uieditfield(c2,'numeric','Value',0.5,'Limits',[0 Inf],'ValueDisplayFormat','%.4g'),5,2);
at(uilabel(c2,'Text','Natural freq. ωₙ'),6,1);
ef2w = at(uieditfield(c2,'numeric','Value',1,'Limits',[1e-6 Inf],'ValueDisplayFormat','%.4g'),6,2);
cb2C = at(uicheckbox(c2,'Text','Compare ζ = 0, 0.5, 1, 1.5 (Fig 6.6)'),7,[1 2]);
cb2E = at(uicheckbox(c2,'Text','Show envelope / exponential terms','Value',true),8,[1 2]);
at(uilabel(c2,'Text','Results','FontWeight','bold'),9,[1 2]);
ta2 = at(uitextarea(c2,'Editable','off','FontName','Monospaced'),10,[1 2]);
btn2 = at(uibutton(c2,'Text','Update'),11,[1 2]);

r2 = uigridlayout(g2,[4 2],'RowHeight',{'fit','fit',132,'1x'},'ColumnWidth',{'1.5x','1x'});
lbl2P = at(uilabel(r2,'Text','','Interpreter','latex','FontSize',17),1,[1 2]);
lbl2y = at(uilabel(r2,'Text','','Interpreter','latex','FontSize',17),2,[1 2]);
tbl2 = at(uitable(r2,'ColumnName',{'System type','Damping ratio','Poles','Poles now'}, ...
    'RowName',{},'ColumnWidth',{150,110,230,'auto'},'FontSize',13, ...
    'Data',{'Undamped','ζ = 0','±jωₙ','';
            'Underdamped','0 < ζ < 1','−ζωₙ ± jωₙ√(1−ζ²)','';
            'Critically damped','ζ = 1','−ζωₙ (repeated)','';
            'Overdamped','ζ > 1','−ζωₙ ± ωₙ√(ζ²−1)',''}),3,[1 2]);
ax2y = at(uiaxes(r2),4,1);
ax2s = at(uiaxes(r2),4,2);
ax2y.Interactions = [];  ax2s.Interactions = [];

dd2.ValueChangedFcn = @(~,~) loadPreset2();
[dd2F.ValueChangedFcn, ef2K.ValueChangedFcn, ef2z.ValueChangedFcn, ef2w.ValueChangedFcn] = ...
    deal(@(~,~) markCustom(dd2,@update2));
[cb2C.ValueChangedFcn, cb2E.ValueChangedFcn] = deal(@(~,~) update2());
btn2.ButtonPushedFcn = @(~,~) update2();

%% =====================================================================
%  Tab 3: Underdamped performance specifications
%  =====================================================================
t3 = uitab(tg,'Title','Underdamped specs');
g3 = uigridlayout(t3,[1 2],'ColumnWidth',{340,'1x'});

c3 = uigridlayout(g3,[11 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{112,22,22,22,22,22,22,22,22,'1x',22});
at(uilabel(c3,'Text',['P(s) = Kωₙ²/(s² + 2ζωₙs + ωₙ²), 0 < ζ < 1, poles a ± jb. ' ...
    'T_p = π/b, %OS depends only on ζ = cos θ, T_s ≈ 4/|a|. Drag the peak or the T_s line on ' ...
    'the response, the pole in the s-plane, or the point on the %OS curve. Specify the system ' ...
    'by any pair of quantities.'],'FontWeight','bold','WordWrap','on'),1,[1 2]);
modes3 = {'ζ and ωₙ','%OS and T_p','%OS and T_s (≈ 4/ζωₙ)','Poles a ± jb'};
% name, K, zeta, wn
presets3 = { ...
    '6.5: ζ = 0.5, ωₙ = 1',                  1,   0.5,    1
    '6.5.1: K = 2, ζ = 0.5, ωₙ = 2',         2,   0.5,    2
    '6.5.3: K = 2.5, ζ = 0.3579, ωₙ = 24.84', 2.5, 0.3579, 24.8392
    '6.5.5: K = 4, ζ = 0.1, ωₙ = 18',        4,   0.1,    18
    '6.5.6: K = 1, ζ = 0.6, ωₙ = 39',        1,   0.6,    39
    'Custom', [], [], []};
at(uilabel(c3,'Text','Example'),2,1);
dd3 = at(uidropdown(c3,'Items',presets3(:,1)','Value',presets3{1,1}),2,2);
at(uilabel(c3,'Text','Specify by'),3,1);
dd3M = at(uidropdown(c3,'Items',modes3),3,2);
at(uilabel(c3,'Text','Gain K'),4,1);
ef3K = at(uieditfield(c3,'numeric','Value',1,'Limits',[1e-9 Inf],'ValueDisplayFormat','%.4g'),4,2);
lbl3a = at(uilabel(c3,'Text','Damping ratio ζ'),5,1);
ef3a = at(uieditfield(c3,'numeric','Value',0.5,'ValueDisplayFormat','%.4g'),5,2);
lbl3b = at(uilabel(c3,'Text','Natural freq. ωₙ'),6,1);
ef3b = at(uieditfield(c3,'numeric','Value',1,'ValueDisplayFormat','%.4g'),6,2);
cb3E = at(uicheckbox(c3,'Text','Show envelope K(1 ± e^(−ζωₙt)/√(1−ζ²))','Value',true),7,[1 2]);
cb3L = at(uicheckbox(c3,'Text','Show constant T_p, T_s, %OS lines (Fig 6.8)','Value',true),8,[1 2]);
at(uilabel(c3,'Text','Results','FontWeight','bold'),9,[1 2]);
ta3 = at(uitextarea(c3,'Editable','off','FontName','Monospaced'),10,[1 2]);
btn3 = at(uibutton(c3,'Text','Update'),11,[1 2]);
mode3 = 1;      % mode the fields are currently expressed in

r3 = uigridlayout(g3,[4 2],'RowHeight',{'fit','fit','1.15x','1x'},'ColumnWidth',{'1x','1x'});
lbl3P = at(uilabel(r3,'Text','','Interpreter','latex','FontSize',17),1,[1 2]);
lbl3S = at(uilabel(r3,'Text','','Interpreter','latex','FontSize',17),2,[1 2]);
ax3y = at(uiaxes(r3),3,[1 2]);
ax3s = at(uiaxes(r3),4,1);
ax3o = at(uiaxes(r3),4,2);
ax3y.Interactions = [];  ax3s.Interactions = [];  ax3o.Interactions = [];

dd3.ValueChangedFcn = @(~,~) loadPreset3();
dd3M.ValueChangedFcn = @(~,~) changeMode3();
[ef3K.ValueChangedFcn, ef3a.ValueChangedFcn, ef3b.ValueChangedFcn] = deal(@(~,~) markCustom(dd3,@update3));
[cb3E.ValueChangedFcn, cb3L.ValueChangedFcn] = deal(@(~,~) update3());
btn3.ButtonPushedFcn = @(~,~) update3();

%% =====================================================================
%  Tab 4: Additional poles and zeros
%  =====================================================================
t4 = uitab(tg,'Title','Extra poles & zeros');
g4 = uigridlayout(t4,[1 2],'ColumnWidth',{340,'1x'});

c4 = uigridlayout(g4,[11 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{112,22,22,22,22,22,22,22,22,'1x',22});
at(uilabel(c4,'Text',['A dominant underdamped pair plus an extra real pole a₃ and/or zero z. ' ...
    'The second-order approximation P̂(s) keeps the DC gain. A far-away pole (a₃ ≤ −5ζωₙ) or ' ...
    'zero barely changes the response; nearby, a pole makes it lag and an LHP zero makes it lead. ' ...
    'An RHP zero gives undershoot. Drag the poles and zero.'],'FontWeight','bold','WordWrap','on'),1,[1 2]);
kinds4 = {'Extra real pole a₃ (6.6)','Real zero z (6.7)','Pole a₃ and zero z (6.7.6)'};
% name, kind, zeta, wn, a3, z
presets4 = { ...
    '6.6.4: ζ = 0.3, ωₙ = 40, a₃ = −151',        1, 0.3, 40, -151, -100
    'Pole not dominant enough: a₃ = −20',        1, 0.3, 40,  -20, -100
    '6.7.3: ζ = 0.6, ωₙ = 14, z = −118',         2, 0.6, 14, -100, -118
    '6.7.4: nearby zero z = −6 (leading)',       2, 0.6, 14, -100,   -6
    '6.7.5: nonminimum phase z = +37',           2, 0.6, 31, -100,   37
    '6.7.6: near cancellation a₃ = −3, z = −3.3', 3, 0.5, 2,    -3, -3.3
    'Custom', [], [], [], [], []};
at(uilabel(c4,'Text','Example'),2,1);
dd4 = at(uidropdown(c4,'Items',presets4(:,1)','Value',presets4{1,1}),2,2);
at(uilabel(c4,'Text','Extra dynamics'),3,1);
dd4K = at(uidropdown(c4,'Items',kinds4),3,2);
at(uilabel(c4,'Text','Damping ratio ζ'),4,1);
ef4z = at(uieditfield(c4,'numeric','Value',0.3,'Limits',[0.001 0.999],'ValueDisplayFormat','%.4g'),4,2);
at(uilabel(c4,'Text','Natural freq. ωₙ'),5,1);
ef4w = at(uieditfield(c4,'numeric','Value',40,'Limits',[1e-6 Inf],'ValueDisplayFormat','%.4g'),5,2);
lbl4a = at(uilabel(c4,'Text','Pole a₃'),6,1);
ef4a = at(uieditfield(c4,'numeric','Value',-151,'Limits',[-Inf -1e-6],'ValueDisplayFormat','%.4g'),6,2);
lbl4zz = at(uilabel(c4,'Text','Zero z'),7,1);
ef4zz = at(uieditfield(c4,'numeric','Value',-100,'ValueDisplayFormat','%.4g'),7,2);
cb4D = at(uicheckbox(c4,'Text','Show ŷ and −(dŷ/dt)/z (6.7.4)','Value',false),8,[1 2]);
at(uilabel(c4,'Text','Results','FontWeight','bold'),9,[1 2]);
ta4 = at(uitextarea(c4,'Editable','off','FontName','Monospaced'),10,[1 2]);
btn4 = at(uibutton(c4,'Text','Update'),11,[1 2]);

r4 = uigridlayout(g4,[3 2],'RowHeight',{'fit','fit','1x'},'ColumnWidth',{'1.4x','1x'});
lbl4P = at(uilabel(r4,'Text','','Interpreter','latex','FontSize',17),1,[1 2]);
lbl4c = at(uilabel(r4,'Text','','Interpreter','latex','FontSize',17),2,[1 2]);
ax4y = at(uiaxes(r4),3,1);
ax4s = at(uiaxes(r4),3,2);
ax4y.Interactions = [];  ax4s.Interactions = [];

dd4.ValueChangedFcn = @(~,~) loadPreset4();
[dd4K.ValueChangedFcn, ef4z.ValueChangedFcn, ef4w.ValueChangedFcn, ef4a.ValueChangedFcn, ...
    ef4zz.ValueChangedFcn] = deal(@(~,~) markCustom(dd4,@update4));
cb4D.ValueChangedFcn = @(~,~) update4();
btn4.ButtonPushedFcn = @(~,~) update4();

%% =====================================================================
%  Tab 5: Transfer functions from step-response data
%  =====================================================================
t5 = uitab(tg,'Title','Identify from data');
g5 = uigridlayout(t5,[1 2],'ColumnWidth',{340,'1x'});

c5 = uigridlayout(g5,[12 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{112,22,22,22,22,22,22,22,22,22,'1x',22});
at(uilabel(c5,'Text',['Measured step response of an unknown system. First-order: read y∞ and the ' ...
    'time T_c at which y = 0.63y∞, then P̂ = A_s/(T_cs + 1). Underdamped: read y∞ and the peak ' ...
    '(T_p, y_max), giving %OS → ζ and T_p → ωₙ. Drag the cursors (or Auto-measure) and compare ' ...
    'the model with the data.'],'FontWeight','bold','WordWrap','on'),1,[1 2]);
models5 = {'First-order (6.2.4)','Underdamped second-order (6.5.7)'};
% name, model, true P(s), beta, noise (%)
presets5 = { ...
    '6.2.4: first-order step test',              1, '2/(s+6)', 1, 1
    '6.5.7: second-order step test (6.5.3)',     2, '2.5*24.8392^2/(s^2+2*0.3579*24.8392*s+24.8392^2)', 1, 1
    'DC motor speed, step of 5 V',               1, '3/(0.4*s+1)', 5, 3
    'Lightly damped, step of 2',                 2, '0.8*9/(s^2+2*0.15*3*s+9)', 2, 2
    'Second-order data, first-order model?',     1, '4/(s^2+2*s+4)', 1, 1
    'Random first-order system',                 1, '', 1, 2
    'Random second-order system',                2, '', 1, 2
    'Custom', [], '', [], []};
at(uilabel(c5,'Text','Example'),2,1);
dd5 = at(uidropdown(c5,'Items',presets5(:,1)','Value',presets5{1,1}),2,2);
at(uilabel(c5,'Text','Model'),3,1);
dd5M = at(uidropdown(c5,'Items',models5),3,2);
at(uilabel(c5,'Text','Step size β'),4,1);
ef5b = at(uieditfield(c5,'numeric','Value',1,'ValueDisplayFormat','%.4g'),4,2);
at(uilabel(c5,'Text','Noise (% of y∞)'),5,1);
ef5n = at(uieditfield(c5,'numeric','Value',1,'Limits',[0 50],'ValueDisplayFormat','%.3g'),5,2);
g5b = at(uigridlayout(c5,[1 2],'Padding',[0 0 0 0]),6,[1 2]);
btn5New = uibutton(g5b,'Text','New random system');
btn5Auto = uibutton(g5b,'Text','Auto-measure');
cb5R = at(uicheckbox(c5,'Text','Reveal the true system'),7,[1 2]);
lbl5P = at(uilabel(c5,'Text','True P(s)'),8,1);
ef5P = at(uieditfield(c5,'text','Value',''),8,2);
at(uilabel(c5,'Text','Results','FontWeight','bold'),10,[1 2]);
ta5 = at(uitextarea(c5,'Editable','off','FontName','Monospaced'),11,[1 2]);
btn5 = at(uibutton(c5,'Text','Update'),12,[1 2]);

r5 = uigridlayout(g5,[2 1],'RowHeight',{'fit','1x'});
lbl5M = uilabel(r5,'Text','','Interpreter','latex','FontSize',18);
ax5 = uiaxes(r5);
ax5.Interactions = [];

% Hidden system, noise and measurement cursors
sys5 = tf(1,[1 1]);  e5 = [];  t5 = [];
cur5 = struct('yinf',1,'Tc',1,'Tp',1,'ymax',1.2);

dd5.ValueChangedFcn = @(~,~) loadPreset5(true);
dd5M.ValueChangedFcn = @(~,~) update5();
[ef5b.ValueChangedFcn, ef5n.ValueChangedFcn] = deal(@(~,~) update5());
ef5P.ValueChangedFcn = @(~,~) customSystem5();
btn5New.ButtonPushedFcn = @(~,~) randomSystem5(dd5M.Value);
btn5Auto.ButtonPushedFcn = @(~,~) autoMeasure5();
cb5R.ValueChangedFcn = @(~,~) update5();
btn5.ButtonPushedFcn = @(~,~) update5();

% Initial draw
loadPreset1(); loadPreset2(); loadPreset3(); loadPreset4(); loadPreset5(true);

%% =====================================================================
%  Dragging
%  =====================================================================
    function startDrag(ax,moveFcn,doneFcn)
        % Begin a drag on ax. moveFcn(pt,p0) is called with the current and
        % starting mouse positions (data units) while the mouse moves, and
        % doneFcn() redraws with normal axis scaling once the mouse is released.
        drawnow
        drag.active = true;
        drag.ax = ax;
        drag.move = moveFcn;
        drag.done = doneFcn;
        drag.xl = ax.XLim;
        drag.yl = ax.YLim;
        drag.p0 = mousePoint(ax);
        drag.last = [];
        drag.t = tic;
    end

    function onMotion()
        if ~drag.active, return, end
        drag.last = mousePoint(drag.ax);
        % Limit the redraw rate so the app keeps up with the mouse
        if toc(drag.t) < 0.04, return, end
        applyDrag(drag.last);
    end

    function onRelease()
        if ~drag.active, return, end
        applyDrag(mousePoint(drag.ax));     % apply the release position exactly
        drag.active = false;
        if isvalid(drag.ax)
            drag.ax.XLimMode = 'auto';
            drag.ax.YLimMode = 'auto';
        end
        if ~isempty(drag.done), drag.done(); end
    end

    function applyDrag(pt)
        drag.move(pt,drag.p0);
        % Hold the dragged axes still so the markers follow the mouse
        if isvalid(drag.ax)
            drag.ax.XLim = drag.xl;
            drag.ax.YLim = drag.yl;
        end
        drawnow limitrate
        drag.t = tic;
    end

    function pt = mousePoint(ax)
        % TestPoint in fig.UserData lets scripted tests stand in for the mouse.
        if isstruct(fig.UserData) && isfield(fig.UserData,'TestPoint')
            pt = fig.UserData.TestPoint;
        else
            pt = ax.CurrentPoint(1,1:2);
        end
    end

    function draggable(h,ax,moveFcn,doneFcn)
        set(h,'ButtonDownFcn',@(~,~) startDrag(ax,moveFcn,doneFcn),'PickableParts','visible');
    end

%% =====================================================================
%  Tab 1 callbacks
%  =====================================================================
    function loadPreset1()
        k = find(strcmp(presets1(:,1),dd1.Value));
        if isempty(presets1{k,2}), update1(); return, end
        dd1F.Value = forms1{presets1{k,2}};
        [ef1K.Value, ef1p.Value, ef1z.Value, ef1b.Value] = presets1{k,3:6};
        update1();
    end

    function update1()
        try
            isZ = strcmp(dd1F.Value,forms1{2});
            set([lbl1z ef1z],'Visible',onoff(isZ));
            set(cb1S,'Enable','on');
            K = ef1K.Value;  p = ef1p.Value;  z = ef1z.Value;  b = ef1b.Value;
            integ = abs(p) < 1e-9;
            stable = p < 0 && ~integ;
            if isZ, y0 = b*K; else, y0 = 0; end
            if stable
                tEnd = 6/(-p);
                if isZ && z ~= 0, tEnd = max(tEnd,1.2*log(abs(1 - p/z)/0.02)/(-p)); end
            elseif integ, tEnd = 5;
            else, tEnd = 4/p; end
            t = linspace(0,tEnd,1500)';
            if integ
                % Double pole at the origin: a ramp
                if isZ, y = b*K*(1 - z*t); else, y = b*K*t; end
            else
                if isZ, yf = b*K*z/p;  c = b*K*(1 - z/p);
                else,   yf = -b*K/p;   c = b*K/p; end
                yn = c*exp(p*t);
                y = yf + yn;
            end

            % Equations
            if isZ
                if K == 1, numZ = polyTex([1 -z]); else, numZ = sprintf('%s(%s)',coefTex(K),polyTex([1 -z])); end
                eqP = sprintf('P(s)=\\frac{K(s-z)}{s-p}=\\frac{%s}{%s}',numZ,polyTex([1 -p]));
                if stable, eqP = [eqP sprintf(',\\quad P(0)=\\frac{Kz}{p}=%s',num(K*z/p))]; end
                gen = '\beta K\left[\frac{z}{p}+\left(1-\frac{z}{p}\right)e^{pt}\right]';
            else
                eqP = sprintf('P(s)=\\frac{K}{s-p}=\\frac{%s}{%s}',num(K),polyTex([1 -p]));
                if stable
                    eqP = [eqP sprintf('=\\frac{A_s}{T_cs+1}=\\frac{%s}{%ss+1},\\quad \\alpha=-p=%s', ...
                        num(-K/p),num(-1/p),num(-p))];
                end
                gen = '\beta\frac{K}{p}\left(e^{pt}-1\right)';
            end
            if b == 1, gen = strrep(gen,'\beta',''); end
            lbl1P.Text = ['$' eqP '$'];
            if integ
                if isZ, lbl1y.Text = sprintf('$y(t)=\\beta K(1-zt)=%s%st\\quad(\\mathrm{pole\\ at\\ the\\ origin})$',num(b*K),signedNum(-b*K*z));
                else,   lbl1y.Text = sprintf('$y(t)=\\beta Kt=%st\\quad(\\mathrm{pole\\ at\\ the\\ origin})$',num(b*K)); end
            else
                lbl1y.Text = sprintf('$y(t)=y_f+y_n=%s=%s%s$',gen,num(yf),expTerm(c,p,''));
            end

            % Step response
            cla(ax1y); hold(ax1y,'on');
            if cb1C.Value && ~integ
                plot(ax1y,t,yf*ones(size(t)),'--','Color',cOrange,'LineWidth',1.5,'HitTest','off', ...
                    'DisplayName','y_f (input pole s = 0)');
                plot(ax1y,t,yn,'--','Color',cPurple,'LineWidth',1.5,'HitTest','off', ...
                    'DisplayName','y_n (pole of P at s = p)');
            end
            plot(ax1y,t,y,'Color',cBlue,'LineWidth',2.5,'HitTest','off','DisplayName','y(t)');
            Ts = NaN;
            if stable
                Tc = -1/p;
                h = plot(ax1y,[0 tEnd],[yf yf],'--','Color',cGreen,'LineWidth',2);
                draggable(h,ax1y,@(pt,~) moveYinf1(pt),@update1);
                text(ax1y,tEnd,yf,sprintf('y_\\infty = %s  ',num(yf)),'Color',cGreen,'FontSize',12, ...
                    'HorizontalAlignment','right','VerticalAlignment','bottom','HitTest','off');
                if cb1T.Value
                    yTc = yf + (y0 - yf)*exp(-1);
                    plot(ax1y,[Tc Tc NaN 0 Tc],[0 yTc NaN yTc yTc],'-','Color',cRed,'HitTest','off');
                    hm = plot(ax1y,Tc,yTc,'o','MarkerSize',11,'MarkerFaceColor',cRed,'MarkerEdgeColor','k');
                    draggable(hm,ax1y,@(pt,~) moveTc1(pt),@update1);
                    text(ax1y,Tc,yTc,sprintf('   T_c = %s s (63%%)',num(Tc)),'Color',cRed,'FontSize',12, ...
                        'VerticalAlignment','top','HitTest','off');
                    if isZ
                        d = abs(yf - y0);
                        if yf ~= 0 && d > 0.02*abs(yf), Ts = log(d/(0.02*abs(yf)))/(-p); else, Ts = 0; end
                        tsLab = sprintf('T_s = %s s',num(Ts));
                    else
                        Ts = 4*Tc;  tsLab = sprintf('T_s \\approx 4T_c = %s s',num(Ts));
                    end
                    band = yf + 0.02*abs(yf)*[-1 1];
                    plot(ax1y,[0 tEnd NaN 0 tEnd],[band(1) band(1) NaN band(2) band(2)],':','Color',[0.3 0.3 0.3], ...
                        'HitTest','off');
                    yTs = yf + (y0 - yf)*exp(p*Ts);
                    plot(ax1y,[Ts Ts],[0 yTs],'-','Color',cRed,'HitTest','off');
                    plot(ax1y,Ts,yTs,'s','MarkerSize',9,'MarkerFaceColor',cRed,'MarkerEdgeColor','k','HitTest','off');
                    text(ax1y,Ts,yf + (y0 - yf)*pick(isZ,0.15,0.92),['  ' tsLab],'Color',cRed,'FontSize',12,'HitTest','off');
                end
                if cb1S.Value
                    plot(ax1y,[0 Tc],[y0 yf],'-.','Color',cRed,'LineWidth',1.5,'HitTest','off', ...
                        'DisplayName','initial slope (reaches y_\infty at T_c)');
                end
            end
            hold(ax1y,'off'); grid(ax1y,'on');
            showLegend(ax1y);
            xlabel(ax1y,'t (seconds)'); ylabel(ax1y,'y(t)');
            if b == 1, title(ax1y,'Unit step response');
            else, title(ax1y,sprintf('Response to a step of size \\beta = %s',num(b))); end
            xlim(ax1y,[0 tEnd]);

            % s-plane
            xs = [0 p];  if isZ, xs(end+1) = z; end
            R = max([abs(xs) 1]);
            xl = [min(xs) - 0.35*R, max([xs 0]) + 0.35*R];
            yl = [-0.5 0.5]*diff(xl);
            cla(ax1s); hold(ax1s,'on');
            patch(ax1s,[0 xl(2) xl(2) 0],[yl(1) yl(1) yl(2) yl(2)],[1 0.9 0.9],'EdgeColor','none','HitTest','off');
            plot(ax1s,xl,[0 0],'k-',[0 0],yl,'k-','HitTest','off');
            plot(ax1s,0,0,'x','MarkerSize',14,'LineWidth',2.5,'Color',cOrange,'HitTest','off');
            text(ax1s,0,-0.16*diff(yl),' input pole s = 0','Color',cOrange,'FontSize',11,'HitTest','off');
            hp = plot(ax1s,p,0,'x','MarkerSize',18,'LineWidth',3.5,'Color',cPurple);
            draggable(hp,ax1s,@(pt,~) movePZ1('p',pt),@update1);
            text(ax1s,p,-0.08*diff(yl),sprintf('p = %s',num(p)),'Color',cPurple,'FontSize',12, ...
                'HorizontalAlignment','center','HitTest','off');
            if isZ
                hz = plot(ax1s,z,0,'o','MarkerSize',14,'LineWidth',2.5,'Color',cPurple);
                draggable(hz,ax1s,@(pt,~) movePZ1('z',pt),@update1);
                text(ax1s,z,0.08*diff(yl),sprintf('z = %s',num(z)),'Color',cPurple,'FontSize',12, ...
                    'HorizontalAlignment','center','HitTest','off');
            end
            hold(ax1s,'off'); grid(ax1s,'on');
            xlim(ax1s,xl); ylim(ax1s,yl);
            title(ax1s,'Poles and zeros of Y(s): drag p and z'); xlabel(ax1s,'Real axis'); ylabel(ax1s,'Imaginary axis');

            % Results
            txt = {'Poles of Y(s) = P(s)U(s), U(s) = β/s:'; ...
                '  s = 0  (input)  -> forced response y_f'; ...
                sprintf('  s = %s  (P(s)) -> natural response y_n',num(p))};
            if isZ, txt{end+1} = sprintf('Zero of P(s): s = %s',num(z)); end
            txt{end+1} = '';
            if stable
                txt{end+1} = sprintf('Steady state y(inf) = %s',num(yf));
                txt{end+1} = sprintf('  (A_s = P(0) = %s)',num(yf/b));
                txt{end+1} = sprintf('Time constant T_c = -1/p = %s s',num(-1/p));
                txt{end+1} = sprintf('Exp. frequency alpha = -p = %s 1/s',num(-p));
                if ~isnan(Ts), txt{end+1} = sprintf('Settling time T_s (2%%) = %s s',num(Ts)); end
                if isZ
                    txt{end+1} = sprintf('y(0+) = beta*K = %s (P is biproper)',num(y0));
                    txt{end+1} = sprintf('Initial slope = beta*K*(p - z) = %s',num(b*K*(p - z)));
                else
                    txt{end+1} = sprintf('Initial slope dy/dt(0) = beta*K = %s',num(b*K));
                    txt{end+1} = '(the tangent at t = 0 reaches y(inf) at T_c)';
                end
                txt = [txt; {''; 'The further left the pole, the faster the'; ...
                    'natural response decays. The amplitudes of'; ...
                    'y_f and y_n depend on both the pole and zero.'}];
            elseif integ
                txt = [txt; {'Pole at the origin: with the step input, Y(s)'; ...
                    'has a double pole at 0 and y(t) is a ramp.'}];
            else
                txt = [txt; {'p > 0: the pole is in the ORHP, so the natural'; ...
                    'response e^(pt) grows without bound (unstable).'}];
            end
            ta1.Value = flatLines(txt);
        catch err
            showError(ta1,err);
        end
    end

    function moveYinf1(pt)
        p = ef1p.Value;  b = ef1b.Value;  K = ef1K.Value;
        if b == 0, return, end
        if strcmp(dd1F.Value,forms1{2})
            if K == 0, return, end
            ef1z.Value = pt(2)*p/(b*K);
        else
            ef1K.Value = -p*pt(2)/b;
        end
        dd1.Value = 'Custom';
        update1();
    end

    function moveTc1(pt)
        Tc = max(pt(1),diff(ax1y.XLim)/200);
        ef1p.Value = -1/Tc;
        dd1.Value = 'Custom';
        update1();
    end

    function movePZ1(which,pt)
        x = pt(1);
        if abs(x) < 0.01*diff(ax1s.XLim), x = 0; end
        if which == 'p', ef1p.Value = x; else, ef1z.Value = x; end
        dd1.Value = 'Custom';
        update1();
    end

%% =====================================================================
%  Tab 2 callbacks
%  =====================================================================
    function loadPreset2()
        k = find(strcmp(presets2(:,1),dd2.Value));
        if isempty(presets2{k,2}), update2(); return, end
        dd2F.Value = forms2{presets2{k,2}};
        [ef2K.Value, ef2z.Value, ef2w.Value, cb2C.Value] = presets2{k,3:6};
        update2();
    end

    function update2()
        try
            K = ef2K.Value;  zeta = ef2z.Value;  wn = ef2w.Value;
            formK = strcmp(dd2F.Value,forms2{1});
            if formK, N0 = K; else, N0 = K*wn^2; end
            d1 = 2*zeta*wn;  d2 = wn^2;
            [p,kind,row] = secondPoles(zeta,wn);
            A = N0/d2;
            P = tf(N0,[1 d1 d2]);

            % Time vector
            if row == 1, tEnd = 5*2*pi/wn; else, tEnd = 6/min(-real(p)); end
            if cb2C.Value, tEnd = max(tEnd,12/wn); end
            t = linspace(0,tEnd,2000)';

            % Analytic response (6.3.1-6.3.4)
            terms = {};
            switch row
                case 4   % overdamped
                    B = N0/(p(1)*(p(1)-p(2)));  C = -N0/(p(2)*(p(1)-p(2)));
                    y = A + B*exp(p(1)*t) + C*exp(p(2)*t);
                    terms = {B*exp(p(1)*t), cPurple, sprintf('%se^{%st}',num(B),num(p(1))); ...
                             C*exp(p(2)*t), cGreen,  sprintf('%se^{%st}',num(C),num(p(2)))};
                    eqy = sprintf('y(t)=A+Be^{p_1t}+Ce^{p_2t}=%s%s%s', ...
                        num(A),expTerm(B,p(1),''),expTerm(C,p(2),''));
                case 3   % critically damped
                    pc = real(p(1));
                    B = N0/pc;  C = -N0/pc^2;
                    y = A + B*t.*exp(pc*t) + C*exp(pc*t);
                    terms = {B*t.*exp(pc*t), cPurple, 'Bte^{p_1t}'; C*exp(pc*t), cGreen, 'Ce^{p_1t}'};
                    eqy = sprintf('y(t)=A+Bte^{p_1t}+Ce^{p_1t}=%s%s%s', ...
                        num(A),expTerm(B,pc,'t'),expTerm(C,pc,''));
                case 2   % underdamped
                    a = real(p(1));  bw = imag(p(1));
                    B = -A;  C = a*A/bw;
                    D = hypot(B,C);  phi = atan2(C,B);
                    y = A + D*exp(a*t).*cos(bw*t - phi);
                    eqy = sprintf(['y(t)=A+De^{at}\\cos(bt-\\phi)=%s%s\\cos(%st%s),' ...
                        '\\quad D=\\sqrt{B^2+C^2},\\ \\phi=\\angle(B+jC)=%s'], ...
                        num(A),expTerm(D,a,''),num(bw),signedNum(-phi),num(phi));
                otherwise % undamped
                    bw = wn;
                    y = A - A*cos(bw*t);
                    eqy = sprintf('y(t)=A+B\\cos(bt)=%s%s\\cos(%st)',num(A),signedNum(-A),num(bw));
            end
            ySim = step(P,t);
            chk = max(abs(y - ySim));

            if formK, numTex = 'K'; else, numTex = 'K\omega_n^2'; end
            lbl2P.Text = sprintf(['$P(s)=\\frac{%s}{s^2+d_1s+d_2}=\\frac{%s}{%s},\\quad d_1=2\\zeta\\omega_n=%s,' ...
                '\\ d_2=\\omega_n^2=%s,\\quad A_s=%s$'],numTex,num(N0),polyTex([1 d1 d2]),num(d1),num(d2),num(A));
            lbl2y.Text = ['$' eqy '$'];

            % Table 6.1 with the current case highlighted
            data = tbl2.Data;
            data(:,4) = {''};
            pNow = cleanNum2(p);
            if row == 3, pNow = pNow(1); end
            data{row,4} = strjoin(arrayfun(@cplx,pNow','UniformOutput',false),',  ');
            tbl2.Data = data;
            removeStyle(tbl2);
            addStyle(tbl2,uistyle('BackgroundColor',[1 0.93 0.55],'FontWeight','bold'),'row',row);

            % Step response
            cla(ax2y); hold(ax2y,'on');
            if cb2C.Value
                Z = [0 0.5 1 1.5];
                nm = {'Undamped','Underdamped','Critically damped','Overdamped'};
                st = {'-','--',':','-.'};
                for q = 1:4
                    yq = step(tf(A*wn^2,[1 2*Z(q)*wn wn^2]),t);
                    plot(ax2y,t,yq,st{q},'Color',[0.6 0.6 0.6],'LineWidth',1.5,'HitTest','off', ...
                        'DisplayName',sprintf('ζ = %g (%s)',Z(q),nm{q}));
                end
            end
            if cb2E.Value
                if row == 2
                    env = D*exp(a*t);
                    plot(ax2y,[t; NaN; t],[A+env; NaN; A-env],'--','Color',cGrey,'LineWidth',1.3,'HitTest','off', ...
                        'DisplayName','envelope A ± De^{at}');
                elseif ~isempty(terms)
                    for q = 1:size(terms,1)
                        plot(ax2y,t,terms{q,1},'--','Color',terms{q,2},'LineWidth',1.5,'HitTest','off', ...
                            'DisplayName',terms{q,3});
                    end
                end
            end
            plot(ax2y,t,y,'Color',cBlue,'LineWidth',2.5,'HitTest','off','DisplayName','y(t)');
            h = plot(ax2y,[0 tEnd],[A A],'--','Color',cGreen,'LineWidth',2);
            draggable(h,ax2y,@(pt,~) moveA2(pt),@update2);
            text(ax2y,tEnd,A,sprintf('A_s = %s  ',num(A)),'Color',cGreen,'FontSize',12, ...
                'HorizontalAlignment','right','VerticalAlignment','bottom','HitTest','off');
            if row == 2
                Ts = -4/a;
                if Ts < tEnd
                    plot(ax2y,[Ts Ts],[0 A],'-','Color',cRed,'HitTest','off');
                    text(ax2y,Ts,0.5*A,sprintf('  T_s \\approx -4/a = %s',num(Ts)),'Color',cRed,'FontSize',12,'HitTest','off');
                end
            end
            hold(ax2y,'off'); grid(ax2y,'on');
            showLegend(ax2y);
            xlim(ax2y,[0 tEnd]);
            xlabel(ax2y,'t (seconds)'); ylabel(ax2y,'y(t)');
            title(ax2y,sprintf('%s step response (ζ = %s, ωₙ = %s)',kind,num(zeta),num(wn)));

            % s-plane
            R = 1.3*max([wn; abs(p)]);
            cla(ax2s); hold(ax2s,'on');
            plot(ax2s,[-R 0.35*R],[0 0],'k-',[0 0],[-R R],'k-','HitTest','off');
            th = linspace(pi/2,3*pi/2,100);
            plot(ax2s,wn*cos(th),wn*sin(th),':','Color',cGrey,'LineWidth',1.2,'HitTest','off');
            text(ax2s,-wn*cos(pi/4),wn*sin(pi/4),' |p| = ωₙ','Color',cGrey,'FontSize',11, ...
                'HorizontalAlignment','right','VerticalAlignment','bottom','HitTest','off');
            if row == 2
                plot(ax2s,[0 1.25*a],[0 1.25*bw],'-','Color',cOS,'HitTest','off');
                plot(ax2s,[0 1.25*a],[0 -1.25*bw],'-','Color',cOS,'HitTest','off');
            end
            if row == 4, pc = {cPurple, cGreen}; else, pc = {cPurple, cPurple}; end
            for j = 1:2
                hp = plot(ax2s,real(p(j)),imag(p(j)),'x','MarkerSize',18,'LineWidth',3.5,'Color',pc{j});
                draggable(hp,ax2s,@(pt,~) movePole2(j,pt,p),@update2);
            end
            if row == 3
                text(ax2s,real(p(1)),0.09*R,'×2','Color',cPurple,'FontSize',12,'HorizontalAlignment','center','HitTest','off');
            end
            hold(ax2s,'off'); grid(ax2s,'on');
            xlim(ax2s,[-R 0.35*R]); ylim(ax2s,[-R R]);
            title(ax2s,'Poles of P(s): drag them'); xlabel(ax2s,'Real axis'); ylabel(ax2s,'Imaginary axis');

            % Results
            txt = {sprintf('%s (zeta = %s)',kind,num(zeta)); ''; 'Poles:'};
            txt = [txt; rootsStr(p)];
            txt{end+1} = sprintf('d1 = 2*zeta*wn = %s,  d2 = wn^2 = %s',num(d1),num(d2));
            txt{end+1} = sprintf('Steady state A_s = %s/%s = %s',num(N0),num(d2),num(A));
            txt{end+1} = '';
            switch row
                case 4
                    txt = [txt; {sprintf('B = %s, C = %s',num(B),num(C)); ...
                        sprintf('Time constants: %s s and %s s',num(-1/p(1)),num(-1/p(2))); ...
                        sprintf('The slow pole %s dominates; T_s ~ %s s',num(p(1)),num(4/-p(1)))}];
                case 3
                    txt = [txt; {sprintf('B = %s, C = %s',num(B),num(C)); ...
                        'Repeated pole: a decaying ramp t e^(pt) plus'; ...
                        'a decaying exponential. Fastest response'; 'without overshoot.'}];
                case 2
                    txt = [txt; {sprintf('a = %s, b = %s',num(a),num(bw)); ...
                        sprintf('B = %s, C = %s',num(B),num(C)); ...
                        sprintf('D = %s, phi = %s rad',num(D),num(phi)); ...
                        sprintf('Damped frequency b = %s rad/s',num(bw)); ...
                        sprintf('Period 2*pi/b = %s s',num(2*pi/bw)); ...
                        sprintf('Envelope time constant -1/a = %s s',num(-1/a)); ...
                        sprintf('T_s ~ -4/a = %s s',num(-4/a))}];
                otherwise
                    txt = [txt; {sprintf('Oscillation at b = wn = %s rad/s that',num(wn)); ...
                        'never decays (e^(0t) = 1): between 0 and 2A_s.'}];
            end
            txt{end+1} = '';
            txt{end+1} = sprintf('Check: max |formula - step()| = %.1e',chk);
            ta2.Value = flatLines(txt);
        catch err
            showError(ta2,err);
        end
    end

    function moveA2(pt)
        wn = ef2w.Value;
        if strcmp(dd2F.Value,forms2{1}), ef2K.Value = pt(2)*wn^2; else, ef2K.Value = pt(2); end
        dd2.Value = 'Custom';
        update2();
    end

    function movePole2(j,pt,pOld)
        % Real-axis drags move one pole (the other stays); off the axis the
        % poles become a complex pair. Snap to critical damping and to the jω-axis.
        xr = diff(ax2s.XLim);  yr = diff(ax2s.YLim);
        x = min(pt(1),-0.005*xr);
        if abs(pt(2)) < 0.03*yr
            other = pOld(3-j);
            if abs(imag(other)) > 1e-9, q = x; else, q = real(other); end
            if abs(x - q) < 0.02*xr, x = q; end
            wn = sqrt(x*q);  zeta = -(x + q)/(2*wn);
        else
            a = pt(1);
            if a > -0.02*xr, a = 0; end
            wn = hypot(a,pt(2));  zeta = abs(a)/wn;
        end
        ef2z.Value = zeta;  ef2w.Value = wn;
        dd2.Value = 'Custom';
        update2();
    end

%% =====================================================================
%  Tab 3 callbacks
%  =====================================================================
    function loadPreset3()
        k = find(strcmp(presets3(:,1),dd3.Value));
        if isempty(presets3{k,2}), update3(); return, end
        ef3K.Value = presets3{k,2};
        set3(presets3{k,3},presets3{k,4});
        update3();
    end

    function changeMode3()
        % Re-express the current system in the newly chosen pair of quantities.
        try
            [zeta,wn] = get3();
        catch
            zeta = 0.5;  wn = 1;
        end
        mode3 = find(strcmp(modes3,dd3M.Value));
        set3(zeta,wn);
        update3();
    end

    function [zeta,wn] = get3()
        u = ef3a.Value;  v = ef3b.Value;
        switch mode3
            case 1
                zeta = u;  wn = v;
            case 2
                if u <= 0 || u >= 100, error('%%OS must be between 0 and 100.'); end
                zeta = zetaFromOS(u);  wn = pi/(v*sqrt(1 - zeta^2));
            case 3
                if u <= 0 || u >= 100, error('%%OS must be between 0 and 100.'); end
                zeta = zetaFromOS(u);  wn = 4/(zeta*v);
            case 4
                if u >= 0 || v <= 0, error('Underdamped poles need a < 0 and b > 0.'); end
                wn = hypot(u,v);  zeta = -u/wn;
        end
        if ~(zeta > 0 && zeta < 1), error('Underdamped systems need 0 < zeta < 1.'); end
        if ~(wn > 0 && isfinite(wn)), error('The natural frequency must be positive.'); end
    end

    function set3(zeta,wn)
        labs = {'Damping ratio ζ','Natural freq. ωₙ'; '%OS','Peak time T_p (s)'; ...
            '%OS','Settling time T_s (s)'; 'Real part a','Imag. part b'};
        lbl3a.Text = labs{mode3,1};  lbl3b.Text = labs{mode3,2};
        os = 100*exp(-zeta*pi/sqrt(1 - zeta^2));
        switch mode3
            case 1, u = zeta;  v = wn;
            case 2, u = os;    v = pi/(wn*sqrt(1 - zeta^2));
            case 3, u = os;    v = 4/(zeta*wn);
            case 4, u = -zeta*wn;  v = wn*sqrt(1 - zeta^2);
        end
        ef3a.Value = u;  ef3b.Value = v;
    end

    function update3()
        try
            [zeta,wn] = get3();
            K = ef3K.Value;
            a = -zeta*wn;  bw = wn*sqrt(1 - zeta^2);  theta = acos(zeta);
            P = tf(K*wn^2,[1 2*zeta*wn wn^2]);
            Tp = pi/bw;  OS = 100*exp(-zeta*pi/sqrt(1 - zeta^2));  ymax = K*(1 + OS/100);
            Ts4 = 4/(zeta*wn);  TsEnv = -log(0.02*sqrt(1 - zeta^2))/(zeta*wn);
            tEnd = max(1.25*TsEnv,1.6*Tp);
            t = linspace(0,tEnd,3000)';
            y = step(P,t);
            S = stepinfo(y,t,K,'SettlingTimeThreshold',0.02);
            phi = atan(zeta/sqrt(1 - zeta^2));

            lbl3P.Text = sprintf(['$P(s)=\\frac{K\\omega_n^2}{s^2+2\\zeta\\omega_ns+\\omega_n^2}=\\frac{%s}{%s},' ...
                '\\quad p_{1,2}=a\\pm jb=%s\\pm j%s,\\quad \\zeta=\\cos\\theta=%s,\\ \\omega_n=%s$'], ...
                num(K*wn^2),polyTex([1 2*zeta*wn wn^2]),num(a),num(bw),num(zeta),num(wn));
            lbl3S.Text = sprintf(['$T_p=\\frac{\\pi}{\\omega_n\\sqrt{1-\\zeta^2}}=\\frac{\\pi}{b}=%s\\,\\mathrm{s},' ...
                '\\quad \\%%OS=100e^{-\\zeta\\pi/\\sqrt{1-\\zeta^2}}=%s,\\quad T_s\\approx\\frac{4}{\\zeta\\omega_n}' ...
                '=\\frac{4}{|a|}=%s\\,\\mathrm{s}$'],num(Tp),num(OS),num(Ts4));

            % Step response
            cla(ax3y); hold(ax3y,'on');
            band = K*[0.98 1.02];
            plot(ax3y,[0 tEnd NaN 0 tEnd],[band(1) band(1) NaN band(2) band(2)],':','Color',[0.3 0.3 0.3], ...
                'HitTest','off','DisplayName','±2% band');
            if cb3E.Value
                env = K*exp(-zeta*wn*t)/sqrt(1 - zeta^2);
                plot(ax3y,[t; NaN; t],[K+env; NaN; K-env],'--','Color',cGrey,'LineWidth',1.2,'HitTest','off', ...
                    'DisplayName','envelope');
            end
            plot(ax3y,t,y,'Color',cBlue,'LineWidth',2.5,'HitTest','off','DisplayName','y(t)');
            plot(ax3y,[0 tEnd],[K K],'-','Color',cGreen,'LineWidth',1.2,'HitTest','off');
            plot(ax3y,[Tp Tp NaN 0 Tp],[0 ymax NaN ymax ymax],'-','Color',cRed,'HitTest','off');
            hpk = plot(ax3y,Tp,ymax,'o','MarkerSize',12,'MarkerFaceColor',cRed,'MarkerEdgeColor','k');
            draggable(hpk,ax3y,@(pt,~) movePeak3(pt),@update3);
            text(ax3y,Tp,ymax,sprintf('   T_p = %s s,  y_{max} = %s  (%%OS = %s)',num(Tp),num(ymax),num(OS)), ...
                'Color',cRed,'FontSize',12,'VerticalAlignment','bottom','HitTest','off');
            hts = plot(ax3y,[Ts4 Ts4],[0 K],'-','Color',cTs,'LineWidth',3);
            draggable(hts,ax3y,@(pt,~) moveTs3(pt),@update3);
            text(ax3y,Ts4,0.06*K,sprintf('  T_s \\approx 4/\\zeta\\omega_n = %s s',num(Ts4)),'Color',cTs, ...
                'FontSize',12,'HitTest','off');
            if ~isnan(S.SettlingTime)
                yS = interp1(t,y,S.SettlingTime);
                plot(ax3y,S.SettlingTime,yS,'d','MarkerSize',9,'MarkerFaceColor',cGreen,'MarkerEdgeColor','k', ...
                    'DisplayName',sprintf('actual 2%% settling: %s s',num(S.SettlingTime)));
            end
            hold(ax3y,'off'); grid(ax3y,'on');
            showLegend(ax3y);
            xlim(ax3y,[0 tEnd]);
            xlabel(ax3y,'t (seconds)'); ylabel(ax3y,'y(t)');
            title(ax3y,'Step response: drag the peak (sets %OS and T_p) or the T_s line (sets ωₙ)');

            % s-plane (Fig 6.8)
            R = 1.35*wn;
            cla(ax3s); hold(ax3s,'on');
            plot(ax3s,[-R 0.35*R],[0 0],'k-',[0 0],[-R R],'k-','HitTest','off');
            if cb3L.Value
                plot(ax3s,[0 1.3*a NaN 0 1.3*a],[0 1.3*bw NaN 0 -1.3*bw],'-','Color',cOS,'LineWidth',1.5,'HitTest','off');
                text(ax3s,1.3*a,1.3*bw,sprintf('%%OS = %s',num(OS)),'Color',cOS,'FontSize',11, ...
                    'HorizontalAlignment','center','VerticalAlignment','bottom','HitTest','off');
                plot(ax3s,[a a],[-R R],'-','Color',cTs,'LineWidth',1.5,'HitTest','off');
                text(ax3s,a,-0.92*R,sprintf(' T_s ≈ %s',num(Ts4)),'Color',cTs,'FontSize',11,'HitTest','off');
                plot(ax3s,[-R 0 NaN -R 0],[bw bw NaN -bw -bw],'-','Color',cTp,'LineWidth',1.5,'HitTest','off');
                text(ax3s,-R,bw,sprintf(' T_p = %s',num(Tp)),'Color',cTp,'FontSize',11, ...
                    'VerticalAlignment','bottom','HitTest','off');
            end
            th = linspace(pi/2,3*pi/2,100);
            plot(ax3s,wn*cos(th),wn*sin(th),':','Color',cGrey,'HitTest','off');
            arc = linspace(pi - theta,pi,40);
            plot(ax3s,0.3*wn*cos(arc),0.3*wn*sin(arc),'-','Color',cBlue,'HitTest','off');
            text(ax3s,0.36*wn*cos(pi - theta/2),0.36*wn*sin(pi - theta/2),sprintf('θ = %s°',num(rad2deg(theta))), ...
                'Color',cBlue,'FontSize',11,'HorizontalAlignment','right','HitTest','off');
            for sg = [1 -1]
                hp = plot(ax3s,a,sg*bw,'x','MarkerSize',18,'LineWidth',3.5,'Color',cPurple);
                draggable(hp,ax3s,@(pt,~) movePole3(pt),@update3);
            end
            hold(ax3s,'off'); grid(ax3s,'on');
            xlim(ax3s,[-R 0.35*R]); ylim(ax3s,[-R R]);
            title(ax3s,'s-plane: drag a pole'); xlabel(ax3s,'Real axis'); ylabel(ax3s,'Imaginary axis');

            % %OS versus zeta (6.5.4)
            zz = linspace(0,0.999,300);
            cla(ax3o); hold(ax3o,'on');
            plot(ax3o,zz,100*exp(-zz*pi./sqrt(1 - zz.^2)),'Color',cBlue,'LineWidth',2,'HitTest','off');
            plot(ax3o,[zeta zeta NaN 0 zeta],[0 OS NaN OS OS],':','Color',cRed,'HitTest','off');
            ho = plot(ax3o,zeta,OS,'o','MarkerSize',12,'MarkerFaceColor',cRed,'MarkerEdgeColor','k');
            draggable(ho,ax3o,@(pt,~) moveZeta3(pt),@update3);
            text(ax3o,zeta,OS,sprintf('   ζ = %s, %%OS = %s',num(zeta),num(OS)),'Color',cRed,'FontSize',12, ...
                'VerticalAlignment','bottom','HitTest','off');
            hold(ax3o,'off'); grid(ax3o,'on');
            xlim(ax3o,[0 1]); ylim(ax3o,[0 100]);
            xlabel(ax3o,'Damping ratio ζ'); ylabel(ax3o,'%OS');
            title(ax3o,'%OS depends only on ζ: drag the point');

            % Results
            txt = {sprintf('zeta = %s,  wn = %s rad/s',num(zeta),num(wn)); ...
                sprintf('Poles a +/- jb = %s +/- j%s',num(a),num(bw)); ...
                sprintf('theta = acos(zeta) = %s deg',num(rad2deg(theta))); ''; ...
                sprintf('T_p = pi/b         = %s s',num(Tp)); ...
                sprintf('y_max = K(1+%%OS/100) = %s',num(ymax)); ...
                sprintf('%%OS                = %s',num(OS)); ...
                sprintf('T_s ~ 4/(zeta wn)  = %s s',num(Ts4)); ...
                sprintf('T_s from envelope  = %s s',num(TsEnv)); ...
                '  -ln(0.02 sqrt(1-zeta^2))/(zeta wn)'; ...
                sprintf('T_s simulated (2%%) = %s s',num(S.SettlingTime)); ...
                sprintf('Simulated %%OS = %s, T_p = %s s',num(S.Overshoot),num(S.PeakTime)); ''; ...
                'y(t) = K[1 - e^(-zeta wn t)'; ...
                '         x cos(bt - phi)/sqrt(1-zeta^2)]'; ...
                sprintf('phi = atan(zeta/sqrt(1-zeta^2)) = %s',num(phi)); ''; ...
                'The envelope estimate assumes the cosine is'; ...
                'at a peak, so the simulated settling time'; ...
                'is never larger than it.'};
            ta3.Value = txt;
        catch err
            showError(ta3,err);
        end
    end

    function movePeak3(pt)
        K = ef3K.Value;
        Tp = max(pt(1),diff(ax3y.XLim)/500);
        OS = min(max(100*(pt(2) - K)/K,0.01),99);
        zeta = zetaFromOS(OS);
        set3(zeta,pi/(Tp*sqrt(1 - zeta^2)));
        dd3.Value = 'Custom';
        update3();
    end

    function moveTs3(pt)
        [zeta,~] = get3();
        Ts = max(pt(1),diff(ax3y.XLim)/500);
        set3(zeta,4/(zeta*Ts));
        dd3.Value = 'Custom';
        update3();
    end

    function movePole3(pt)
        xr = diff(ax3s.XLim);  yr = diff(ax3s.YLim);
        a = min(pt(1),-0.005*xr);
        b = max(abs(pt(2)),0.005*yr);
        wn = hypot(a,b);
        set3(min(-a/wn,0.995),wn);
        dd3.Value = 'Custom';
        update3();
    end

    function moveZeta3(pt)
        [~,wn] = get3();
        set3(min(max(pt(1),0.005),0.995),wn);
        dd3.Value = 'Custom';
        update3();
    end

%% =====================================================================
%  Tab 4 callbacks
%  =====================================================================
    function loadPreset4()
        k = find(strcmp(presets4(:,1),dd4.Value));
        if isempty(presets4{k,2}), update4(); return, end
        dd4K.Value = kinds4{presets4{k,2}};
        [ef4z.Value, ef4w.Value, ef4a.Value, ef4zz.Value] = presets4{k,3:6};
        cb4D.Value = presets4{k,2} == 2 && ef4zz.Value > 0;
        update4();
    end

    function update4()
        try
            kind = find(strcmp(kinds4,dd4K.Value));
            hasP = kind ~= 2;  hasZ = kind ~= 1;
            set([lbl4a ef4a],'Visible',onoff(hasP));
            set([lbl4zz ef4zz],'Visible',onoff(hasZ));
            cb4D.Enable = onoff(kind == 2);
            zeta = ef4z.Value;  wn = ef4w.Value;  a3 = ef4a.Value;  z = ef4zz.Value;
            s = tf('s');
            G2 = tf(wn^2,[1 2*zeta*wn wn^2]);
            E = tf(1);  E0 = 1;
            if hasP, E = E/(s - a3);  E0 = -E0/a3; end
            if hasZ, E = E*(s - z);   E0 = -E0*z; end
            P = G2*E;  Phat = E0*G2;
            sig = zeta*wn;  a = -sig;  bw = wn*sqrt(1 - zeta^2);

            pAll = [a + 1j*bw; a - 1j*bw];
            if hasP, pAll(end+1) = a3; end
            tEnd = min(6/min(-real(pAll)),40*6/sig);
            t = linspace(0,tEnd,3000)';
            y = step(P,t);  yh = step(Phat,t);

            % Equations
            den2 = 's^2+2\zeta\omega_ns+\omega_n^2';
            switch kind
                case 1
                    eqP = sprintf(['P(s)=\\frac{\\omega_n^2}{(%s)(s-a_3)}\\approx\\hat P(s)=\\frac{-\\omega_n^2/a_3}{%s}' ...
                        '=\\frac{%s}{%s}'],den2,den2,num(E0*wn^2),polyTex([1 2*sig wn^2]));
                    ok = a3 <= -5*sig;
                    eqc = sprintf('a_3=%s\\ %s\\ -5\\zeta\\omega_n=%s\\ \\Rightarrow\\ %s',num(a3),leq(ok),num(-5*sig), ...
                        pick(ok,'\mathrm{complex\ pair\ dominates:\ approximation\ is\ good}', ...
                        '\mathrm{pole\ too\ close:\ response\ lags\ the\ approximation}'));
                case 2
                    eqP = sprintf(['P(s)=\\frac{\\omega_n^2(s-z)}{%s}\\approx\\hat P(s)=\\frac{-z\\omega_n^2}{%s}' ...
                        '=\\frac{%s}{%s},\\qquad P(s)=(1-s/z)\\hat P(s)'],den2,den2,num(E0*wn^2),polyTex([1 2*sig wn^2]));
                    if z > 0
                        eqc = sprintf(['z=%s>0:\\ \\mathrm{nonminimum\\ phase,}\\ \\hat y\\ \\mathrm{and}\\ ' ...
                            '-\\dot{\\hat y}/z\\ \\mathrm{start\\ with\\ opposite\\ signs\\ (undershoot)}'],num(z));
                    else
                        eqc = sprintf(['z=%s,\\ |z|/\\zeta\\omega_n=%s:\\ y=\\hat y-\\dot{\\hat y}/z\\ ' ...
                            '\\mathrm{leads\\ the\\ approximation}%s'],num(z),num(-z/sig), ...
                            pick(z <= -5*sig,'\mathrm{\ (slightly)}',''));
                    end
                otherwise
                    eqP = sprintf(['P(s)=\\frac{\\omega_n^2(s-z)}{(%s)(s-a_3)}\\approx\\hat P(s)=' ...
                        '\\frac{\\omega_n^2\\,z/a_3}{%s}=\\frac{%s}{%s}'],den2,den2,num(E0*wn^2),polyTex([1 2*sig wn^2]));
                    eqc = sprintf(['|z-a_3|=%s,\\ \\mathrm{gain}\\ z/a_3=%s:\\ \\mathrm{%s}'],num(abs(z - a3)),num(z/a3), ...
                        pick(abs(z - a3) < 0.2*abs(a3),'approximate\ cancellation\ is\ reasonable', ...
                        'pole\ and\ zero\ too\ far\ apart\ to\ cancel'));
            end
            lbl4P.Text = ['$' eqP '$'];
            lbl4c.Text = ['$' eqc '$'];

            % Responses
            cla(ax4y); hold(ax4y,'on');
            if kind == 2 && cb4D.Value
                dyh = impulse(Phat,t);
                plot(ax4y,t,-dyh/z,'--','Color',cGreen,'LineWidth',1.8,'HitTest','off', ...
                    'DisplayName','-(dŷ/dt)/z');
            end
            plot(ax4y,t,yh,'Color',cRed,'LineWidth',2,'HitTest','off','DisplayName','ŷ(t) from P̂(s)');
            plot(ax4y,t,y,'Color',cBlue,'LineWidth',2.5,'HitTest','off','DisplayName','y(t) from P(s)');
            hold(ax4y,'off'); grid(ax4y,'on');
            showLegend(ax4y);
            xlim(ax4y,[0 tEnd]);
            xlabel(ax4y,'t (seconds)'); ylabel(ax4y,'y(t)');
            title(ax4y,'Unit step responses of P(s) and its second-order approximation');

            % s-plane
            xs = [a 0];
            if hasP, xs(end+1) = a3; end
            if hasZ, xs(end+1) = z; end
            R = max([abs(xs) wn]);
            xl = [min(xs) - 0.2*R, max(xs) + 0.25*R];
            yl = [-1 1]*max(1.3*bw,0.35*diff(xl));
            cla(ax4s); hold(ax4s,'on');
            if kind == 1
                patch(ax4s,[xl(1) -5*sig -5*sig xl(1)],[yl(1) yl(1) yl(2) yl(2)],[0.9 0.97 0.85],'EdgeColor','none','HitTest','off');
                text(ax4s,-5*sig,0.85*yl(2),' a_3 \leq -5\zeta\omega_n ','HorizontalAlignment','right','Color',cGreen*0.8, ...
                    'FontSize',11,'HitTest','off');
            end
            if xl(2) > 0
                patch(ax4s,[0 xl(2) xl(2) 0],[yl(1) yl(1) yl(2) yl(2)],[1 0.92 0.92],'EdgeColor','none','HitTest','off');
            end
            plot(ax4s,xl,[0 0],'k-',[0 0],yl,'k-','HitTest','off');
            for sg = [1 -1]
                hp = plot(ax4s,a,sg*bw,'x','MarkerSize',18,'LineWidth',3.5,'Color',cRed);
                draggable(hp,ax4s,@(pt,~) movePair4(pt),@update4);
            end
            if hasP
                hp = plot(ax4s,a3,0,'x','MarkerSize',18,'LineWidth',3.5,'Color',cBlue);
                draggable(hp,ax4s,@(pt,~) moveExtra4('p',pt),@update4);
                text(ax4s,a3,-0.08*diff(yl),sprintf('a_3 = %s',num(a3)),'Color',cBlue,'FontSize',12, ...
                    'HorizontalAlignment','center','HitTest','off');
            end
            if hasZ
                hz = plot(ax4s,z,0,'o','MarkerSize',14,'LineWidth',2.5,'Color',cBlue);
                draggable(hz,ax4s,@(pt,~) moveExtra4('z',pt),@update4);
                text(ax4s,z,0.08*diff(yl),sprintf('z = %s',num(z)),'Color',cBlue,'FontSize',12, ...
                    'HorizontalAlignment','center','HitTest','off');
            end
            hold(ax4s,'off'); grid(ax4s,'on');
            xlim(ax4s,xl); ylim(ax4s,yl);
            title(ax4s,'s-plane: drag the poles and zero'); xlabel(ax4s,'Real axis'); ylabel(ax4s,'Imaginary axis');

            % Results: performance of y and its approximation
            txt = {sprintf('Dominant poles: %s +/- j%s',num(a),num(bw)); ''};
            txt(end) = [];
            if hasP, txt{end+1} = sprintf('Extra pole a3 = %s (%s x further)',num(a3),num(a3/a)); end
            if hasZ, txt{end+1} = sprintf('Zero z = %s',num(z)); end
            txt{end+1} = sprintf('DC gain P(0) = P^(0) = %s',num(E0));
            txt{end+1} = '';
            if E0 ~= 0
                Sy = stepinfo(y,t,E0,'SettlingTimeThreshold',0.02);
                Sh = stepinfo(yh,t,E0,'SettlingTimeThreshold',0.02);
                txt{end+1} = '              %OS      T_p      T_s';
                txt{end+1} = sprintf('y  (P)     %7.3g  %7.3g  %7.3g',Sy.Overshoot,Sy.PeakTime,Sy.SettlingTime);
                txt{end+1} = sprintf('y^ (P^)    %7.3g  %7.3g  %7.3g',Sh.Overshoot,Sh.PeakTime,Sh.SettlingTime);
                txt{end+1} = sprintf('formulas   %7.3g  %7.3g  %7.3g',100*exp(-zeta*pi/sqrt(1 - zeta^2)),pi/bw,4/sig);
                if Sy.Undershoot > 0.5
                    txt{end+1} = sprintf('Undershoot of y: %s %%',num(Sy.Undershoot));
                end
                txt{end+1} = '';
            end
            switch kind
                case 1
                    txt = [txt(:); {'The extra pole makes the response more'; ...
                        'sluggish (it lags y^). Rule of thumb:'; ...
                        'a3 <= -5*zeta*wn for the approximation.'}];
                case 2
                    txt = [txt(:); {'y = y^ - (dy^/dt)/z. For z < 0 the'; ...
                        'derivative term adds to y^, so y leads'; ...
                        '(more overshoot, shorter peak time).'; ...
                        'For z > 0 it subtracts at first: the'; ...
                        'response starts the wrong way.'}];
                otherwise
                    txt = [txt(:); {'A zero close to a real pole nearly cancels'; ...
                        'it; keep the gain z/a3 in the approximation.'; ...
                        'The leftover residue is small and slow.'}];
            end
            ta4.Value = txt(:);
        catch err
            showError(ta4,err);
        end
    end

    function movePair4(pt)
        xr = diff(ax4s.XLim);  yr = diff(ax4s.YLim);
        a = min(pt(1),-0.002*xr);
        b = max(abs(pt(2)),0.002*yr);
        wn = hypot(a,b);
        ef4w.Value = wn;
        ef4z.Value = min(max(-a/wn,0.001),0.999);
        dd4.Value = 'Custom';
        update4();
    end

    function moveExtra4(which,pt)
        if which == 'p'
            ef4a.Value = min(pt(1),-1e-3*diff(ax4s.XLim));
        else
            ef4zz.Value = pt(1);
        end
        dd4.Value = 'Custom';
        update4();
    end

%% =====================================================================
%  Tab 5 callbacks
%  =====================================================================
    function loadPreset5(resetCursors)
        k = find(strcmp(presets5(:,1),dd5.Value));
        if isempty(presets5{k,2})          % Custom: keep the typed system
            customSystem5();
            return
        end
        dd5M.Value = models5{presets5{k,2}};
        ef5b.Value = presets5{k,4};
        ef5n.Value = presets5{k,5};
        if isempty(presets5{k,3})
            randomSystem5(dd5M.Value);
            return
        end
        ef5P.Value = presets5{k,3};
        newSystem5(parseTF(presets5{k,3}),k,resetCursors);
    end

    function customSystem5()
        try
            dd5.Value = 'Custom';
            newSystem5(parseTF(ef5P.Value),0,true);
        catch err
            showError(ta5,err);
        end
    end

    function randomSystem5(model)
        rs = RandStream('mt19937ar','Seed','shuffle');
        if strcmp(model,models5{1})
            K = round(0.5 + 4.5*rand(rs),2);  p = -round(0.5 + 9.5*rand(rs),2);
            ef5P.Value = sprintf('%g/(s%+g)',K,-p);
        else
            K = round(0.5 + 2.5*rand(rs),2);  zeta = round(0.1 + 0.6*rand(rs),2);  wn = round(1 + 19*rand(rs),1);
            ef5P.Value = sprintf('%g*%g^2/(s^2+2*%g*%g*s+%g^2)',K,wn,zeta,wn,wn);
        end
        if ~startsWith(dd5.Value,'Random'), dd5.Value = 'Custom'; end
        newSystem5(parseTF(ef5P.Value),randi(rs,1e6),true);
    end

    function newSystem5(sys,seed,resetCursors)
        sys5 = tf(sys);
        p = pole(sys5);
        if any(real(p) >= 0), error('The test system must be stable to give a steady-state value.'); end
        t5 = linspace(0,6/min(-real(p)),500)';
        rs = RandStream('mt19937ar','Seed',seed);
        e5 = randn(rs,numel(t5),1);
        if resetCursors
            % Start the cursors away from the answer, so they have to be placed
            yEnd = ef5b.Value*dcgain(sys5);
            cur5 = struct('yinf',0.85*yEnd,'Tc',0.3*t5(end),'Tp',0.35*t5(end),'ymax',1.1*yEnd);
        end
        update5();
    end

    function y = data5()
        yTrue = ef5b.Value*step(sys5,t5);
        y = yTrue + ef5n.Value/100*abs(yTrue(end))*e5;
    end

    function autoMeasure5()
        y = data5();
        ys = movmean(y,9);
        n = numel(y);
        yinf = mean(y(round(0.9*n):end));
        cur5.yinf = yinf;
        if strcmp(dd5M.Value,models5{1})
            i = find(sign(yinf)*ys >= 0.632*abs(yinf),1);
            if ~isempty(i) && i > 1
                cur5.Tc = interp1(ys(i-1:i),t5(i-1:i),0.632*yinf);
            end
        else
            [~,i] = max(sign(yinf)*ys);
            cur5.Tp = t5(i);  cur5.ymax = ys(i);
        end
        update5();
    end

    function update5()
        try
            isFirst = strcmp(dd5M.Value,models5{1});
            set([lbl5P ef5P],'Visible',onoff(cb5R.Value || strcmp(dd5.Value,'Custom')));
            b = ef5b.Value;
            if b == 0, error('The step size must be nonzero.'); end
            y = data5();
            yinf = cur5.yinf;
            tEnd = t5(end);

            % Identified model
            if isFirst
                Tc = max(cur5.Tc,tEnd/1000);
                As = yinf/b;
                Phat = tf(As,[Tc 1]);
                lbl5M.Text = sprintf(['$\\hat P(s)=\\frac{A_s}{T_cs+1}=\\frac{y_\\infty/\\beta}{T_cs+1}=' ...
                    '\\frac{%s}{%ss+1}=\\frac{%s}{%s}$'],num(As),num(Tc),num(As/Tc),polyTex([1 1/Tc]));
            else
                OS = 100*(cur5.ymax - yinf)/yinf;
                if ~(OS > 0 && OS < 100)
                    error('Place the peak cursor above y_inf (0 < %%OS < 100).');
                end
                zeta = zetaFromOS(OS);
                wn = pi/(cur5.Tp*sqrt(1 - zeta^2));
                Kh = yinf/b;
                Phat = tf(Kh*wn^2,[1 2*zeta*wn wn^2]);
                lbl5M.Text = sprintf(['$\\%%OS=%s\\Rightarrow\\zeta=\\frac{-\\ln(\\%%OS/100)}{\\sqrt{\\pi^2+\\ln^2(\\%%OS/100)}}=%s,' ...
                    '\\ \\omega_n=\\frac{\\pi}{T_p\\sqrt{1-\\zeta^2}}=%s,\\quad \\hat P(s)=\\frac{%s}{%s}$'], ...
                    num(OS),num(zeta),num(wn),num(Kh*wn^2),polyTex([1 2*zeta*wn wn^2]));
            end
            yModel = b*step(Phat,t5);

            % Plot
            cla(ax5); hold(ax5,'on');
            plot(ax5,t5,y,'.','Color',[0.45 0.45 0.45],'MarkerSize',7,'HitTest','off','DisplayName','measured y(t)');
            if cb5R.Value
                plot(ax5,t5,b*step(sys5,t5),'k--','LineWidth',1.5,'HitTest','off','DisplayName','true system');
            end
            plot(ax5,t5,yModel,'Color',cRed,'LineWidth',2.2,'HitTest','off','DisplayName','model P̂(s)');
            h = plot(ax5,[0 tEnd],[yinf yinf],'-','Color',cGreen,'LineWidth',2.5);
            draggable(h,ax5,@(pt,~) moveCursor5('yinf',pt),@update5);
            text(ax5,tEnd,yinf,sprintf('y_\\infty = %s  ',num(yinf)),'Color',cGreen,'FontSize',12, ...
                'HorizontalAlignment','right','VerticalAlignment','bottom','HitTest','off');
            if isFirst
                y63 = 0.632*yinf;
                plot(ax5,[0 tEnd],[y63 y63],'--','Color',cGreen,'HitTest','off');
                text(ax5,tEnd,y63,'0.63y_\infty  ','Color',cGreen,'FontSize',12, ...
                    'HorizontalAlignment','right','VerticalAlignment','top','HitTest','off');
                h = plot(ax5,[Tc Tc],[0 y63],'-','Color',cBlue,'LineWidth',3);
                draggable(h,ax5,@(pt,~) moveCursor5('Tc',pt),@update5);
                hm = plot(ax5,Tc,y63,'o','MarkerSize',11,'MarkerFaceColor',cBlue,'MarkerEdgeColor','k');
                draggable(hm,ax5,@(pt,~) moveCursor5('Tc',pt),@update5);
                text(ax5,Tc,0.08*yinf,sprintf('  T_c = %s s',num(Tc)),'Color',cBlue,'FontSize',12,'HitTest','off');
            else
                plot(ax5,[cur5.Tp cur5.Tp NaN 0 cur5.Tp],[0 cur5.ymax NaN cur5.ymax cur5.ymax],':', ...
                    'Color',cBlue,'LineWidth',1.5,'HitTest','off');
                hm = plot(ax5,cur5.Tp,cur5.ymax,'o','MarkerSize',12,'MarkerFaceColor',cBlue,'MarkerEdgeColor','k');
                draggable(hm,ax5,@(pt,~) moveCursor5('peak',pt),@update5);
                text(ax5,cur5.Tp,cur5.ymax,sprintf('   T_p = %s s, y_{max} = %s',num(cur5.Tp),num(cur5.ymax)), ...
                    'Color',cBlue,'FontSize',12,'VerticalAlignment','bottom','HitTest','off');
            end
            hold(ax5,'off'); grid(ax5,'on');
            showLegend(ax5);
            xlim(ax5,[0 tEnd]);
            xlabel(ax5,'t (seconds)'); ylabel(ax5,'y(t)');
            if isFirst, hint = 'drag y_\infty and T_c'; else, hint = 'drag y_\infty and the peak'; end
            title(ax5,sprintf('Step test (\\beta = %s): %s',num(b),hint));

            % Results
            rmsErr = sqrt(mean((yModel - b*step(sys5,t5)).^2));
            txt = {'Measured:'; sprintf('  y_inf = %s  (step size beta = %s)',num(yinf),num(b))};
            if isFirst
                txt = [txt; {sprintf('  T_c   = %s s',num(Tc)); ''; 'Model:'; ...
                    sprintf('  A_s = y_inf/beta = %s',num(As)); ...
                    sprintf('  p = -1/T_c = %s',num(-1/Tc)); ...
                    sprintf('  K = A_s/T_c = %s',num(As/Tc))}];
            else
                txt = [txt; {sprintf('  T_p = %s s,  y_max = %s',num(cur5.Tp),num(cur5.ymax)); ''; 'Model:'; ...
                    sprintf('  %%OS = %s  ->  zeta = %s',num(OS),num(zeta)); ...
                    sprintf('  wn = pi/(T_p sqrt(1-zeta^2)) = %s',num(wn)); ...
                    sprintf('  K = y_inf/beta = %s',num(Kh))}];
            end
            txt{end+1} = sprintf('  RMS error vs true: %s',num(rmsErr));
            if cb5R.Value
                [nT,dT] = tfdata(sys5,'v');
                txt = [txt; {''; 'True system: P(s) = N(s)/D(s)'; ['  N = ' mat2str(round(nT(find(nT,1):end),4))]; ...
                    ['  D = ' mat2str(round(dT,4))]}];
                pt = pole(sys5);
                txt = [txt; {'  poles:'}; rootsStr(pt)];
                txt{end+1} = sprintf('  DC gain = %s',num(dcgain(sys5)));
                if numel(pt) == 2 && all(imag(pt) ~= 0)
                    [wt,zt] = damp(sys5);
                    txt{end+1} = sprintf('  zeta = %s, wn = %s',num(zt(1)),num(wt(1)));
                end
            end
            ta5.Value = txt;
        catch err
            showError(ta5,err);
        end
    end

    function moveCursor5(which,pt)
        switch which
            case 'yinf', cur5.yinf = pt(2);
            case 'Tc',   cur5.Tc = max(pt(1),t5(2));
            case 'peak', cur5.Tp = max(pt(1),t5(2));  cur5.ymax = pt(2);
        end
        update5();
    end
end

%% =========================================================================
%  Second-order helpers
%  =========================================================================
function [p,kind,row] = secondPoles(zeta,wn)
% Poles and type of wn^2/(s^2 + 2 zeta wn s + wn^2) (Table 6.1). For the
% overdamped case p(1) is the slower pole.
if zeta < 1e-9
    p = [1j; -1j]*wn;  kind = 'Undamped';  row = 1;
elseif abs(zeta - 1) < 1e-9
    p = -wn*[1; 1];  kind = 'Critically damped';  row = 3;
elseif zeta < 1
    a = -zeta*wn;  b = wn*sqrt(1 - zeta^2);
    p = [a + 1j*b; a - 1j*b];  kind = 'Underdamped';  row = 2;
else
    r = wn*sqrt(zeta^2 - 1);
    p = [-zeta*wn + r; -zeta*wn - r];  kind = 'Overdamped';  row = 4;
end
end

function zeta = zetaFromOS(OS)
L = log(OS/100);
zeta = -L/sqrt(pi^2 + L^2);
end

%% =========================================================================
%  Text and LaTeX helpers
%  =========================================================================
function s = num(x)
if abs(x) >= 1e4 && abs(x) < 1e7, s = sprintf('%.0f',x); else, s = sprintf('%.4g',x); end
if strcmp(s,'-0'), s = '0'; end
end

function v = cleanNum2(v)
% Remove round-off in the real and imaginary parts of a vector.
for i = 1:numel(v)
    m = max(abs(v(i)),1);
    re = real(v(i));  im = imag(v(i));
    if abs(re) < 1e-9*m, re = 0; end
    if abs(im) < 1e-9*m, im = 0; end
    v(i) = complex(re,im);
end
end

function s = coefTex(x)
% Coefficient in front of a bracket: 1 and -1 are written as '' and '-'.
if abs(x - 1) < 1e-12, s = ''; elseif abs(x + 1) < 1e-12, s = '-'; else, s = num(x); end
end

function s = signedNum(x)
if x >= 0, s = ['+' num(x)]; else, s = num(x); end
end

function s = cplx(z)
z = cleanNum2(z);
if imag(z) == 0, s = num(real(z));
else, s = sprintf('%.4g%+.4gj',real(z),imag(z)); end
end

function s = expTerm(c,p,pre)
% Signed LaTeX term c*pre*e^(pt), e.g. '-e^{-6t}' or '+0.8te^{-t}'.
if abs(c - 1) < 1e-12, s = '+'; elseif abs(c + 1) < 1e-12, s = '-'; else, s = signedNum(c); end
if abs(p + 1) < 1e-12, ex = '-t'; elseif abs(p - 1) < 1e-12, ex = 't'; else, ex = [num(p) 't']; end
s = sprintf('%s%se^{%s}',s,pre,ex);
end

function s = leq(ok)
if ok, s = '\le'; else, s = '>'; end
end

function s = pick(c,a,b)
if c, s = a; else, s = b; end
end

function str = polyTex(c)
% Polynomial in descending powers of s, in LaTeX.
c(abs(c) < 1e-12*max(abs(c))) = 0;
idx = find(c ~= 0,1);
if isempty(idx), str = '0'; return, end
c = c(idx:end);  n = numel(c) - 1;  str = '';
for i = 1:numel(c)
    if c(i) == 0, continue, end
    pw = n - i + 1;  mag = abs(c(i));
    if pw == 0, term = num(mag);
    else
        if pw == 1, v = 's'; else, v = sprintf('s^{%d}',pw); end
        if abs(mag - 1) < 1e-12, term = v; else, term = [num(mag) v]; end
    end
    if isempty(str)
        if c(i) < 0, str = ['-' term]; else, str = term; end
    elseif c(i) < 0, str = [str '-' term]; %#ok<AGROW>
    else, str = [str '+' term]; %#ok<AGROW>
    end
end
end

function str = rootsStr(p)
if isempty(p), str = {'  (none)'}; return, end
str = arrayfun(@(v) ['  ' cplx(v)],p(:),'UniformOutput',false);
end

function sys = parseTF(str)
% Evaluate a MATLAB expression in s as a transfer function.
str = strtrim(str);
if isempty(str), error('Transfer function is empty.'); end
f = str2func(['@(s) ' str]);
sys = tf(f(tf('s')));
end

%% =========================================================================
%  UI helpers
%  =========================================================================
function showLegend(ax)
% Legend of the curves that have a DisplayName (markers and guides have none).
h = flipud(findobj(ax,'Type','line','-not','DisplayName',''));
if isempty(h), legend(ax,'off');
else, legend(ax,h,'Location','southeast','AutoUpdate','off'); end
end

function s = onoff(b)
if b, s = 'on'; else, s = 'off'; end
end

function h = at(h,row,col)
% Place a component in a grid layout cell (row, col may be spans like [1 2]).
h.Layout.Row = row;
h.Layout.Column = col;
end

function out = flatLines(txt)
% Flatten a cell array of char rows and nested cell arrays into one column.
out = {};
for i = 1:numel(txt)
    if iscell(txt{i}), out = [out; txt{i}(:)]; else, out = [out; txt(i)]; end %#ok<AGROW>
end
end

function markCustom(dd,updateFcn)
% Editing a parameter by hand switches the example selector to Custom.
dd.Value = 'Custom';
updateFcn();
end

function showError(ta,err)
ta.Value = {'Error:'; err.message; ''; ...
    'Enter transfer functions as MATLAB expressions in s,'; ...
    'e.g. 2/(s+6) or 9/(s^2+0.9*s+9).'};
end
