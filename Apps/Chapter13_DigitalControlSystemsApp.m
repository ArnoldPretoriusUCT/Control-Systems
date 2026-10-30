function Chapter13_DigitalControlSystemsApp
%CHAPTER13_DIGITALCONTROLSYSTEMSAPP Interactive GUI for MEC3079S Chapter 13 — Digital control systems.
%
%   Run Chapter13_DigitalControlSystemsApp to open the app. The tabs follow the chapter:
%     1. Sampling & hold    (13.1-13.2.1): samples f[k] = f(kΔT), the zero-order
%        hold staircase (about a ΔT/2 delay), aliasing and ADC quantisation.
%     2. Sampling in the loop (13.2.2): L*(s) = L(s)(1 − sΔT/2) against the
%        design bounds, compared with the true sampled-data (ZOH) loop.
%     3. Z-transform         (13.3): sequences, F(z), the delay property and a
%        difference equation as a discrete transfer function.
%     4. Tustin transform    (13.4): s ≈ 2(z − 1)/(ΔT(z + 1)); pole/zero mapping
%        to the z-plane and frequency warping.
%     5. Digital controller  (13.5): G(s) → G(z) → difference equation, generated
%        code, and a digital versus analogue closed-loop simulation.
%
%   Interaction: drag a sample (tab 1), the ΔT marker and the L* curve (tab 2),
%   the poles/zeros (tab 4) and the first ZOH step (tab 5).
%
%   Requires the Control System Toolbox (the Symbolic Math Toolbox is used for
%   G(z) as a function of ΔT on tab 4 when available).

cOrange = [0.85 0.33 0.10];
cBlue   = [0.00 0.45 0.74];
cPurple = [0.49 0.18 0.56];
cGreen  = [0.47 0.67 0.19];
cRed    = [0.85 0.10 0.10];
cGrey   = [0.60 0.60 0.60];
cSel    = [0.10 0.60 0.10];
addItems = {'Add pole/zero…','Real pole','Complex pole pair','Real zero','Complex zero pair'};

fig = uifigure('Name','MEC3079S Chapter 13 — Digital control systems', ...
    'Position',[50 40 1340 860]);
mainGrid = uigridlayout(fig,[1 1],'Padding',[0 0 0 0]);
tg = uitabgroup(mainGrid);

% Drag state shared by all interactive plots
drag = struct('active',false,'ax',[],'move',[],'done',[],'p0',[0 0], ...
    'last',[],'xl',[],'yl',[],'t',tic);
fig.WindowButtonMotionFcn = @(~,~) onMotion();
fig.WindowButtonUpFcn = @(~,~) onRelease();

%% =====================================================================
%  Tab 1: Sampling and hold
%  =====================================================================
t1 = uitab(tg,'Title','Sampling & hold');
g1 = uigridlayout(t1,[1 2],'ColumnWidth',{340,'1x'});
c1 = uigridlayout(g1,[12 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{112,22,22,22,22,22,22,22,22,22,'1x',22});
at(uilabel(c1,'Text',['The ADC samples f(t) every ΔT seconds: f[k] = f(kΔT). The DAC holds each value ' ...
    '(zero-order hold), giving a staircase that lags f(t) by about ΔT/2. Sample slower than twice ' ...
    'the signal frequency (Nyquist) and the samples describe a different, aliased signal. ' ...
    'Drag the second sample to change ΔT.'],'FontWeight','bold','WordWrap','on'),1,[1 2]);
sigs1 = {'Sinusoid','Two sinusoids','Damped response','Custom f(t)'};
% name, signal, f (Hz), dT, hold, bits, custom
presets1 = { ...
    'Sine 0.5 Hz, ΔT = 0.1 s (fine)',              1, 0.5, 0.1,  1, 0,  ''
    'Sine 0.5 Hz, ΔT = 0.4 s (coarse ZOH)',        1, 0.5, 0.4,  1, 0,  ''
    'Sine 1.6 Hz, ΔT = 0.5 s (fs = 2 Hz: aliasing)', 1, 1.6, 0.5, 1, 0,  ''
    'Sine 1 Hz sampled at 1 Hz (looks constant!)', 1, 1,   1,    1, 0,  ''
    'Damped response, 4-bit ADC',                   3, 0.5, 0.05, 1, 4,  ''
    'Custom: square-ish wave',                      4, 0.5, 0.1,  1, 0,  'sign(sin(2*pi*0.5*t))'
    'Custom', [], [], [], [], [], ''};
holds1 = {'Zero-order hold (staircase)','First-order hold (ramps)','Samples only'};
at(uilabel(c1,'Text','Example'),2,1);
dd1 = at(uidropdown(c1,'Items',presets1(:,1)','Value',presets1{1,1}),2,2);
at(uilabel(c1,'Text','Signal'),3,1);
dd1S = at(uidropdown(c1,'Items',sigs1),3,2);
lbl1f = at(uilabel(c1,'Text','Frequency f (Hz)'),4,1);
ef1f = at(uieditfield(c1,'numeric','Value',0.5,'Limits',[1e-3 Inf],'ValueDisplayFormat','%.4g'),4,2);
lbl1c = at(uilabel(c1,'Text','f(t) ='),5,1);
ef1c = at(uieditfield(c1,'text','Value','sign(sin(2*pi*0.5*t))'),5,2);
at(uilabel(c1,'Text','Sample time ΔT (s)'),6,1);
ef1T = at(uieditfield(c1,'numeric','Value',0.1,'Limits',[1e-3 Inf],'ValueDisplayFormat','%.4g'),6,2);
at(uilabel(c1,'Text','Reconstruction'),7,1);
dd1H = at(uidropdown(c1,'Items',holds1),7,2);
at(uilabel(c1,'Text','ADC bits (0 = ideal)'),8,1);
ef1b = at(uieditfield(c1,'numeric','Value',0,'Limits',[0 16],'RoundFractionalValues','on'),8,2);
cb1D = at(uicheckbox(c1,'Text','Show f(t − ΔT/2): the ZOH acts like a delay','Value',true),9,[1 2]);
at(uilabel(c1,'Text','Results','FontWeight','bold'),10,[1 2]);
ta1 = at(uitextarea(c1,'Editable','off','FontName','Monospaced'),11,[1 2]);
btn1 = at(uibutton(c1,'Text','Update'),12,[1 2]);

r1 = uigridlayout(g1,[2 1],'RowHeight',{'1.4x','1x'});
ax1t = uiaxes(r1);
ax1e = uiaxes(r1);
[ax1t.Interactions, ax1e.Interactions] = deal([]);

dd1.ValueChangedFcn = @(~,~) loadPreset1();
[dd1S.ValueChangedFcn, ef1f.ValueChangedFcn, ef1c.ValueChangedFcn, ef1T.ValueChangedFcn, dd1H.ValueChangedFcn, ...
    ef1b.ValueChangedFcn] = deal(@(~,~) markCustom(dd1,@update1));
cb1D.ValueChangedFcn = @(~,~) update1();
btn1.ButtonPushedFcn = @(~,~) update1();

%% =====================================================================
%  Tab 2: Sampling in the feedback loop
%  =====================================================================
t2 = uitab(tg,'Title','Sampling in the loop');
g2 = uigridlayout(t2,[1 2],'ColumnWidth',{340,'1x'});
c2 = uigridlayout(g2,[13 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{112,22,22,22,22,22,22,22,22,22,22,'1x',22});
at(uilabel(c2,'Text',['A digital controller approximately adds an ORHP zero at 2/ΔT: L*(s) = L(s)(1 − sΔT/2), ' ...
    'which adds gain and phase lag that grow with ω and ΔT. The step response compares the ' ...
    'continuous loop, the L* approximation and the true sampled-data loop (ZOH plant, Tustin ' ...
    'controller). Drag the ΔT marker or the L*(jω) curve (gain K).'],'FontWeight','bold','WordWrap','on'),1,[1 2]);
% name, P, G0, K, dT, OS, Ts, bound
presets2 = { ...
    '13.2.2: P = 10/(s(s+2)), K = 0.17, ΔT = 1.5',   '10/(s*(s+2))',   '1',   0.17, 1.5, 25, 5, 2
    '13.2.2: same with K = 0.1',                      '10/(s*(s+2))',   '1',   0.1,  1.5, 25, 5, 2
    '13.2.2: K = 0.17 without sampling (ΔT → 0)',     '10/(s*(s+2))',   '1',   0.17, 1e-3, 25, 5, 2
    '13.2.2: L = 5/(s(1+s/10)), ΔT = 0.18',           '5/(s*(1+s/10))', '1',   1,    0.18, 25, 2, 1
    'Same loop, ΔT = 0.85 (unstable!)',               '5/(s*(1+s/10))', '1',   1,    0.85, 25, 2, 1
    'Custom', '', '', [], [], [], [], []};
bounds2 = {'Ch 11: M_B = 0.98 for ω ≤ ω_p','Ch 13 example: M_B = 1/√2 for ω ≤ ω₀'};
at(uilabel(c2,'Text','Example'),2,1);
dd2 = at(uidropdown(c2,'Items',presets2(:,1)','Value',presets2{1,1}),2,2);
at(uilabel(c2,'Text','P(s)'),3,1);
ef2P = at(uieditfield(c2,'text','Value','10/(s*(s+2))'),3,2);
at(uilabel(c2,'Text','G₀(s)'),4,1);
ef2G = at(uieditfield(c2,'text','Value','1'),4,2);
at(uilabel(c2,'Text','Gain K (G = KG₀)'),5,1);
ef2K = at(uieditfield(c2,'numeric','Value',0.17,'Limits',[1e-9 Inf],'ValueDisplayFormat','%.4g'),5,2);
at(uilabel(c2,'Text','Sample time ΔT (s)'),6,1);
ef2T = at(uieditfield(c2,'numeric','Value',1.5,'Limits',[1e-4 Inf],'ValueDisplayFormat','%.4g'),6,2);
at(uilabel(c2,'Text','%OS spec'),7,1);
ef2OS = at(uieditfield(c2,'numeric','Value',25,'Limits',[0.5 80],'ValueDisplayFormat','%.4g'),7,2);
at(uilabel(c2,'Text','T_s spec (s)'),8,1);
ef2Ts = at(uieditfield(c2,'numeric','Value',5,'Limits',[1e-3 Inf],'ValueDisplayFormat','%.4g'),8,2);
at(uilabel(c2,'Text','Stay-above bound'),9,1);
dd2B = at(uidropdown(c2,'Items',bounds2),9,2);
at(uilabel(c2,'Text','Results','FontWeight','bold'),11,[1 2]);
ta2 = at(uitextarea(c2,'Editable','off','FontName','Monospaced'),12,[1 2]);
btn2 = at(uibutton(c2,'Text','Update'),13,[1 2]);

r2 = uigridlayout(g2,[3 2],'RowHeight',{'fit','1x','1x'},'ColumnWidth',{'1.15x','1x'});
lbl2 = at(uilabel(r2,'Text','','Interpreter','latex','FontSize',17),1,[1 2]);
ax2c = at(uiaxes(r2),[2 3],1);
ax2y = at(uiaxes(r2),2,2);
ax2d = at(uiaxes(r2),3,2);
[ax2c.Interactions, ax2y.Interactions, ax2d.Interactions] = deal([]);

dd2.ValueChangedFcn = @(~,~) loadPreset2();
[ef2P.ValueChangedFcn, ef2G.ValueChangedFcn, ef2K.ValueChangedFcn, ef2T.ValueChangedFcn, ef2OS.ValueChangedFcn, ...
    ef2Ts.ValueChangedFcn, dd2B.ValueChangedFcn] = deal(@(~,~) markCustom(dd2,@update2));
btn2.ButtonPushedFcn = @(~,~) update2();

%% =====================================================================
%  Tab 3: Z-transform
%  =====================================================================
t3 = uitab(tg,'Title','Z-transform');
g3 = uigridlayout(t3,[1 2],'ColumnWidth',{340,'1x'});
c3 = uigridlayout(g3,[11 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{112,22,22,22,22,22,22,22,22,'1x',22});
at(uilabel(c3,'Text',['F(z) = Σ f[k] z^(−k): each sample is tagged by its position. Delaying a sequence by ' ...
    'x samples multiplies F(z) by z^(−x). A difference equation such as y[n] = a·u[n] − b·u[n−1] ' ...
    'therefore becomes Y(z) = (a − bz^(−1))U(z), i.e. P(z) = a − bz^(−1). Drag the stems of f[n].'], ...
    'FontWeight','bold','WordWrap','on'),1,[1 2]);
presets3 = { ...
    '13.3.1: f[n] = {0,1,2,2,3,2,1,0}',      '[0 1 2 2 3 2 1 0]', 2, 2, 1
    'Unit pulse, delayed by 3',             '[1 0 0 0 0 0 0 0]', 3, 1, 0.5
    'Ramp, advanced by 1',                  '[0 1 2 3 4 5 6 7]', -1, 1, 1
    'Custom', '', [], [], []};
at(uilabel(c3,'Text','Example'),2,1);
dd3 = at(uidropdown(c3,'Items',presets3(:,1)','Value',presets3{1,1}),2,2);
at(uilabel(c3,'Text','f[n], n = 0, 1, …'),3,1);
ef3f = at(uieditfield(c3,'text','Value','[0 1 2 2 3 2 1 0]'),3,2);
at(uilabel(c3,'Text','Shift x (delay > 0)'),4,1);
ef3x = at(uieditfield(c3,'numeric','Value',2,'RoundFractionalValues','on','Limits',[-5 8]),4,2);
at(uilabel(c3,'Text','Difference equation: y[n] = a u[n] − b u[n−1], u = unit step','FontAngle','italic','WordWrap','on'),5,[1 2]);
at(uilabel(c3,'Text','a'),6,1);
ef3a = at(uieditfield(c3,'numeric','Value',2,'ValueDisplayFormat','%.4g'),6,2);
at(uilabel(c3,'Text','b'),7,1);
ef3b = at(uieditfield(c3,'numeric','Value',1,'ValueDisplayFormat','%.4g'),7,2);
at(uilabel(c3,'Text','Results','FontWeight','bold'),9,[1 2]);
ta3 = at(uitextarea(c3,'Editable','off','FontName','Monospaced'),10,[1 2]);
btn3 = at(uibutton(c3,'Text','Update'),11,[1 2]);

r3 = uigridlayout(g3,[5 1],'RowHeight',{'fit','fit','1x','fit','1x'});
lbl3a = uilabel(r3,'Text','','Interpreter','latex','FontSize',17);
lbl3b = uilabel(r3,'Text','','Interpreter','latex','FontSize',17);
ax3f = uiaxes(r3);
lbl3c = uilabel(r3,'Text','','Interpreter','latex','FontSize',17);
ax3d = uiaxes(r3);
[ax3f.Interactions, ax3d.Interactions] = deal([]);

dd3.ValueChangedFcn = @(~,~) loadPreset3();
[ef3f.ValueChangedFcn, ef3x.ValueChangedFcn, ef3a.ValueChangedFcn, ef3b.ValueChangedFcn] = deal(@(~,~) markCustom(dd3,@update3));
btn3.ButtonPushedFcn = @(~,~) update3();

%% =====================================================================
%  Tab 4: Tustin transform
%  =====================================================================
t4 = uitab(tg,'Title','Tustin transform');
g4 = uigridlayout(t4,[1 2],'ColumnWidth',{340,'1x'});
c4 = uigridlayout(g4,[10 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{112,22,22,22,22,22,22,'1x',22,0});
at(uilabel(c4,'Text',['Trapezoidal integration gives s ≈ 2(z − 1)/(ΔT(z + 1)), i.e. z ≈ (1 + sΔT/2)/(1 − sΔT/2). ' ...
    'The OLHP maps inside the unit circle, the jω-axis onto it, and s = ∞ to z = −1. The exact ' ...
    'mapping of poles is z = e^(sΔT). Frequencies are warped: ω = ∞ lands at the Nyquist frequency ' ...
    'π/ΔT. Drag the poles and zeros of G(s).'],'FontWeight','bold','WordWrap','on'),1,[1 2]);
presets4 = { ...
    '13.4.2 Ex 2: G = 5/(s+1), ΔT = 0.1',          '5/(s+1)',               0.1
    '13.4.2: G = 5/(s+1), ΔT = 1',                 '5/(s+1)',               1
    '13.4.1: G = 10(1+s)/s, ΔT = 0.1',             '10*(1+s)/s',            0.1
    'Lightly damped: G = 25/(s²+s+25), ΔT = 0.2',  '25/(s^2+s+25)',         0.2
    'Same, ΔT = 0.5 (poles near Nyquist)',         '25/(s^2+s+25)',         0.5
    'Custom', '', []};
at(uilabel(c4,'Text','Example'),2,1);
dd4 = at(uidropdown(c4,'Items',presets4(:,1)','Value',presets4{1,1}),2,2);
at(uilabel(c4,'Text','G(s)'),3,1);
ef4 = at(uieditfield(c4,'text','Value','5/(s+1)'),3,2);
at(uilabel(c4,'Text','Sample time ΔT (s)'),4,1);
ef4T = at(uieditfield(c4,'numeric','Value',0.1,'Limits',[1e-4 Inf],'ValueDisplayFormat','%.4g'),4,2);
g4r = at(uigridlayout(c4,[1 2],'Padding',[0 0 0 0]),5,[1 2]);
dd4Add = uidropdown(g4r,'Items',addItems);
btn4Del = uibutton(g4r,'Text','Delete selected');
at(uilabel(c4,'Text','Results','FontWeight','bold'),6,[1 2]);
ta4 = at(uitextarea(c4,'Editable','off','FontName','Monospaced'),[7 8],[1 2]);
btn4 = at(uibutton(c4,'Text','Update'),9,[1 2]);
sel4 = 0;

r4 = uigridlayout(g4,[4 2],'RowHeight',{'fit','fit','1x','1x'},'ColumnWidth',{'1x','1x'});
lbl4a = at(uilabel(r4,'Text','','Interpreter','latex','FontSize',17),1,[1 2]);
lbl4b = at(uilabel(r4,'Text','','Interpreter','latex','FontSize',17),2,[1 2]);
ax4s = at(uiaxes(r4),3,1);
ax4z = at(uiaxes(r4),3,2);
ax4b = at(uiaxes(r4),4,[1 2]);
[ax4s.Interactions, ax4z.Interactions, ax4b.Interactions] = deal([]);

dd4.ValueChangedFcn = @(~,~) loadPreset4();
[ef4.ValueChangedFcn, ef4T.ValueChangedFcn] = deal(@(~,~) markCustom(dd4,@update4));
dd4Add.ValueChangedFcn = @(~,~) addRoot4();
btn4Del.ButtonPushedFcn = @(~,~) deleteRoot4();
btn4.ButtonPushedFcn = @(~,~) update4();

%% =====================================================================
%  Tab 5: Implementing a digital controller
%  =====================================================================
t5 = uitab(tg,'Title','Digital controller');
g5 = uigridlayout(t5,[1 2],'ColumnWidth',{340,'1x'});
c5 = uigridlayout(g5,[10 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{112,22,22,22,22,22,22,22,'1x',22});
at(uilabel(c5,'Text',['G(s) → (Tustin) → G(z) → difference equation u[n] = Σ aⱼ e[n−j] − Σ bⱼ u[n−j], ' ...
    'run once every ΔT seconds. The code box shows a ready-to-use implementation. The plots ' ...
    'compare the digital loop (ZOH, sampled every ΔT) with the analogue design. Drag the first ' ...
    'step of u[n] to change ΔT.'],'FontWeight','bold','WordWrap','on'),1,[1 2]);
% name, P, G, dT, r
presets5 = { ...
    '13.5.2: P = 0.5/s, G = 5/(s+1), ΔT = 0.3',       '0.5/s',          '5/(s+1)',            0.3,   1
    'Same, ΔT = 0.05',                                '0.5/s',          '5/(s+1)',            0.05,  1
    'Same, ΔT = 1 (too slow)',                        '0.5/s',          '5/(s+1)',            1,     1
    '13.5.3: PI G = 10(1+5s)/(5s), ΔT = 0.001',       '1/(s+1)',        '10*(1+5*s)/(5*s)',   0.001, 1
    'PI with ΔT = 0.2',                               '1/(s+1)',        '10*(1+5*s)/(5*s)',   0.2,   1
    '13.2.2: P = 10/(s(s+2)), K = 0.1, ΔT = 1.5',     '10/(s*(s+2))',   '0.1',                1.5,   1
    'Custom', '', '', [], []};
langs5 = {'MATLAB','Arduino (C++)'};
at(uilabel(c5,'Text','Example'),2,1);
dd5 = at(uidropdown(c5,'Items',presets5(:,1)','Value',presets5{1,1}),2,2);
at(uilabel(c5,'Text','Plant P(s)'),3,1);
ef5P = at(uieditfield(c5,'text','Value','0.5/s'),3,2);
at(uilabel(c5,'Text','Controller G(s)'),4,1);
ef5G = at(uieditfield(c5,'text','Value','5/(s+1)'),4,2);
at(uilabel(c5,'Text','Sample time ΔT (s)'),5,1);
ef5T = at(uieditfield(c5,'numeric','Value',0.3,'Limits',[1e-5 Inf],'ValueDisplayFormat','%.4g'),5,2);
at(uilabel(c5,'Text','Reference step r'),6,1);
ef5r = at(uieditfield(c5,'numeric','Value',1,'ValueDisplayFormat','%.4g'),6,2);
at(uilabel(c5,'Text','Code'),7,1);
dd5L = at(uidropdown(c5,'Items',langs5),7,2);
at(uilabel(c5,'Text','Generated code','FontWeight','bold'),8,[1 2]);
ta5 = at(uitextarea(c5,'Editable','off','FontName','Monospaced','FontSize',11),9,[1 2]);
btn5 = at(uibutton(c5,'Text','Update'),10,[1 2]);

r5 = uigridlayout(g5,[4 1],'RowHeight',{'fit','fit','1x','1x'});
lbl5a = uilabel(r5,'Text','','Interpreter','latex','FontSize',17);
lbl5b = uilabel(r5,'Text','','Interpreter','latex','FontSize',17);
ax5y = uiaxes(r5);
ax5u = uiaxes(r5);
[ax5y.Interactions, ax5u.Interactions] = deal([]);

dd5.ValueChangedFcn = @(~,~) loadPreset5();
[ef5P.ValueChangedFcn, ef5G.ValueChangedFcn, ef5T.ValueChangedFcn, ef5r.ValueChangedFcn] = deal(@(~,~) markCustom(dd5,@update5));
dd5L.ValueChangedFcn = @(~,~) update5();
btn5.ButtonPushedFcn = @(~,~) update5();

% Initial draw
loadPreset1(); loadPreset2(); loadPreset3(); loadPreset4(); loadPreset5();

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

    function setField(ef,dd,v,updFcn)
        ef.Value = min(max(v,ef.Limits(1)),ef.Limits(2));
        dd.Value = 'Custom';
        updFcn();
    end

%% =====================================================================
%  Tab 1 callbacks
%  =====================================================================
    function loadPreset1()
        k = find(strcmp(presets1(:,1),dd1.Value));
        if isempty(presets1{k,2}), update1(); return, end
        dd1S.Value = sigs1{presets1{k,2}};
        [ef1f.Value, ef1T.Value] = presets1{k,3:4};
        dd1H.Value = holds1{presets1{k,5}};
        ef1b.Value = presets1{k,6};
        if ~isempty(presets1{k,7}), ef1c.Value = presets1{k,7}; end
        update1();
    end

    function update1()
        try
            sig = find(strcmp(sigs1,dd1S.Value));
            set([lbl1f ef1f],'Visible',onoff(sig <= 2));
            set([lbl1c ef1c],'Visible',onoff(sig == 4));
            f0 = ef1f.Value;  dT = ef1T.Value;  bits = ef1b.Value;
            switch sig
                case 1, fn = @(t) sin(2*pi*f0*t);  Tend = max(4/f0,8*dT);
                case 2, fn = @(t) 0.7*sin(2*pi*f0*t) + 0.3*sin(2*pi*3*f0*t);  Tend = max(3/f0,8*dT);
                case 3, fn = @(t) 1 - exp(-0.8*t).*cos(3*t);  Tend = 6;
                otherwise
                    fc = str2func(['@(t) ' ef1c.Value]);
                    fn = @(t) fc(t).*ones(size(t));  Tend = 6;
            end
            t = linspace(0,Tend,4000)';
            f = fn(t);
            k = (0:floor(Tend/dT))';
            tk = k*dT;
            fk = fn(tk);
            if bits > 0
                % Quantise over the range of the signal with 2^bits levels
                lo = min(f) - 1e-9;  hi = max(f) + 1e-9;
                q = (hi - lo)/(2^bits - 1);
                fk = lo + q*round((fk - lo)/q);
            end
            % Reconstruction
            hold1 = find(strcmp(holds1,dd1H.Value));
            switch hold1
                case 1, fr = fk(min(floor(t/dT) + 1,numel(fk)));
                case 2   % causal first-order hold: the ramp reaches f[k] one sample later
                    fr = [fk(1)*ones(sum(t < dT),1); interp1(tk + dT,fk,t(t >= dT),'linear',fk(end))];
                otherwise, fr = [];
            end

            cla(ax1t); hold(ax1t,'on');
            plot(ax1t,t,f,'Color',cGrey,'LineWidth',2,'DisplayName','f(t) (analogue)');
            if cb1D.Value && hold1 == 1
                plot(ax1t,t,fn(t - dT/2).*(t >= dT/2),':','Color',cPurple,'LineWidth',1.8,'DisplayName','f(t − ΔT/2)');
            end
            if ~isempty(fr)
                plot(ax1t,t,fr,'Color',cBlue,'LineWidth',2.2,'DisplayName',pick(hold1 == 1,'ZOH output (DAC)','first-order hold'));
            end
            stem(ax1t,tk,fk,'filled','Color',cRed,'MarkerSize',5,'LineWidth',1,'HitTest','off','DisplayName','samples f[k]');
            if numel(tk) >= 2
                h = plot(ax1t,tk(2),fk(2),'o','MarkerSize',13,'MarkerFaceColor',cOrange,'MarkerEdgeColor','k','DisplayName','drag: ΔT');
                draggable(h,ax1t,@(pt,~) setField(ef1T,dd1,max(pt(1),1e-3),@update1),@update1);
            end
            alias = [];
            if sig == 1
                fs = 1/dT;
                fa = abs(f0 - fs*round(f0/fs));
                if fa < f0 - 1e-9
                    alias = fa;
                    sgn = sign(sin(2*pi*f0*dT))*sign(sin(2*pi*fa*dT) + eps);
                    plot(ax1t,t,sgn*sin(2*pi*fa*t),'--','Color',cGreen,'LineWidth',2,'DisplayName',sprintf('alias at %s Hz',num(fa)));
                end
            end
            hold(ax1t,'off'); grid(ax1t,'on'); xlim(ax1t,[0 Tend]);
            showLegend(ax1t,'northeastoutside');
            title(ax1t,sprintf('Sampling every ΔT = %s s (f_s = %s Hz, Nyquist frequency %s Hz)',num(dT),num(1/dT),num(0.5/dT)));
            xlabel(ax1t,'t (s)');

            % Reconstruction error
            cla(ax1e);
            if ~isempty(fr)
                plot(ax1e,t,f - fr,'Color',cBlue,'LineWidth',1.5);
                title(ax1e,sprintf('Reconstruction error f(t) − output (RMS %s)',num(sqrt(mean((f - fr).^2)))));
            else
                title(ax1e,'No reconstruction selected');
            end
            grid(ax1e,'on'); xlim(ax1e,[0 Tend]); xlabel(ax1e,'t (s)');

            txt = {sprintf('dT = %s s -> f_s = %s Hz',num(dT),num(1/dT)); ...
                sprintf('Nyquist frequency f_s/2 = %s Hz',num(0.5/dT))};
            if sig <= 2
                fmax = f0*(1 + 2*(sig == 2));
                txt{end+1} = sprintf('Highest signal frequency: %s Hz',num(fmax));
                if fmax < 0.5/dT
                    txt{end+1} = 'Sampled fast enough (f_s > 2 f_max).';
                else
                    txt{end+1} = 'TOO SLOW: f_s < 2 f_max -> aliasing.';
                end
                if ~isempty(alias)
                    txt{end+1} = sprintf('The samples look like a %s Hz sine.',num(alias));
                end
            end
            txt{end+1} = '';
            txt{end+1} = sprintf('The ZOH output lags f(t) by about dT/2 = %s s',num(dT/2));
            txt{end+1} = sprintf('(at f = %s Hz that is %s deg of phase lag).',num(f0),num(360*f0*dT/2));
            if bits > 0
                txt{end+1} = sprintf('ADC: %d bits -> %d levels, step %s.',bits,2^bits,num(q));
            end
            ta1.Value = txt(:);
        catch err
            showError(ta1,err);
        end
    end

%% =====================================================================
%  Tab 2 callbacks
%  =====================================================================
    function loadPreset2()
        k = find(strcmp(presets2(:,1),dd2.Value));
        if isempty(presets2{k,4}), update2(); return, end
        ef2P.Value = presets2{k,2};  ef2G.Value = presets2{k,3};
        [ef2K.Value, ef2T.Value, ef2OS.Value, ef2Ts.Value] = presets2{k,4:7};
        dd2B.Value = bounds2{presets2{k,8}};
        update2();
    end

    function update2()
        try
            P = parseTF(ef2P.Value);  G0 = parseTF(ef2G.Value);  K = ef2K.Value;  dT = ef2T.Value;
            s = zpk('s');
            L = K*G0*P;
            Ls = L*(1 - s*dT/2);
            OS = ef2OS.Value;  Ts = ef2Ts.Value;
            zeta = zetaFromOS(OS);  MA = 1/(2*zeta*sqrt(1 - zeta^2));
            if strcmp(dd2B.Value,bounds2{1})
                wn = 4/(zeta*Ts);  wB = wn*sqrt(max(1 - 2*zeta^2,0));  MB = 0.98;  nmB = '\omega_p';
            else
                z2 = 0.71;  wn = 4/(z2*Ts);
                wB = wn*sqrt((1 - 2*z2^2) + sqrt(4*z2^4 - 4*z2^2 + 2));  MB = 1/sqrt(2);  nmB = '\omega_0';
            end
            w = freqGrid(L,[wB 2/dT]);
            w = w(w <= 50/dT);
            [Lw,ph] = freqData(L,w);
            [Lsw,phs] = freqData(Ls,w);
            T = abs(Lsw./(1 + Lsw));
            okA = all(T <= MA*(1 + 1e-6));  okB = all(T(w <= wB) >= MB*(1 - 1e-6));

            lbl2.Text = sprintf(['$L^*(s)=L(s)\\left(1-s\\frac{\\Delta T}{2}\\right),\\ \\Delta T=%s:\\ \\mathrm{zero\\ at}\\ ' ...
                's=\\frac{2}{\\Delta T}=%s,\\quad M_A=%s,\\ M_B=%s\\ \\mathrm{for}\\ \\omega\\le%s=%s$'], ...
                num(dT),num(2/dT),num(MA),num(MB),nmB,num(wB));

            % Log-polar comparison with bounds
            [phLo,phHi] = phaseWindow([ph; phs]);
            cla(ax2c); hold(ax2c,'on');
            shadeRegions(ax2c,phLo,phHi,[-40 40],@(Lc) abs(Lc./(1 + Lc)) > MA,[0.3 0.5 1]);
            shadeRegions(ax2c,phLo,phHi,[-40 40],@(Lc) abs(Lc./(1 + Lc)) < MB,[0.4 0.85 0.3]);
            plot(ax2c,ph,20*log10(abs(Lw)),'Color',[0.35 0.35 0.35],'LineWidth',1.8,'DisplayName','L(jω) (continuous)');
            h = plot(ax2c,phs,20*log10(abs(Lsw)),'Color',cRed,'LineWidth',2.5,'DisplayName','L*(jω) (drag: K)');
            draggable(h,ax2c,@(pt,p0) setField(ef2K,dd2,K*10^((pt(2) - p0(2))/20),@update2),@update2);
            for wm = [wB 1/dT]
                [~,im] = min(abs(w - wm));
                plot(ax2c,[ph(im) phs(im)],20*log10(abs([Lw(im) Lsw(im)])),'k:','HitTest','off');
                plot(ax2c,ph(im),20*log10(abs(Lw(im))),'o','MarkerFaceColor',[0.35 0.35 0.35],'MarkerEdgeColor','k','HitTest','off');
                plot(ax2c,phs(im),20*log10(abs(Lsw(im))),'o','MarkerFaceColor',cRed,'MarkerEdgeColor','k','HitTest','off');
                text(ax2c,phs(im),20*log10(abs(Lsw(im))),sprintf('  ω = %s',num(wm)),'FontSize',11,'HitTest','off');
            end
            c = -180 + 360*(ceil((phLo + 180)/360):floor((phHi + 180)/360));
            plot(ax2c,c,zeros(size(c)),'o','MarkerSize',8,'MarkerFaceColor',cRed,'MarkerEdgeColor','k','HitTest','off');
            hold(ax2c,'off'); grid(ax2c,'on'); xlim(ax2c,[phLo phHi]); ylim(ax2c,[-40 40]);
            showLegend(ax2c,'southeast');
            title(ax2c,sprintf('Log-polar: L* stays out of blue %s and green (ω ≤ %s) %s',mark(okA),strrep(nmB,'\omega','ω'),mark(okB)));
            xlabel(ax2c,'phase (deg)'); ylabel(ax2c,'magnitude (dB)');

            % Step responses: continuous, approximation, sampled-data
            Tc = feedback(L,1);  Ta = feedback(Ls,1);
            Pd = c2d(ss(P),dT,'zoh');  Gd = c2d(ss(K*G0),dT,'tustin');
            Td = feedback(Gd*Pd,1);
            stc = isStableC(Tc);  sta = isStableC(Ta);  std = all(abs(pole(Td)) < 1 - 1e-9);
            tEnd = 2.5*Ts;
            t = linspace(0,tEnd,2000)';
            cla(ax2y); hold(ax2y,'on');
            patch(ax2y,[Ts tEnd tEnd Ts],[0.98 0.98 1.02 1.02],[0.88 0.96 0.85],'EdgeColor','none','HitTest','off');
            plot(ax2y,[0 tEnd],(1 + OS/100)*[1 1],'--','Color',cOrange,'LineWidth',1.5,'HitTest','off');
            plot(ax2y,[Ts Ts],[0 1.5],'--','Color',cBlue,'LineWidth',1.5,'HitTest','off');
            info = {};
            if stc
                yc = step(Tc,t);  Sc = stepinfo(yc,t,1);
                plot(ax2y,t,yc,'Color',[0.35 0.35 0.35],'LineWidth',1.8,'DisplayName','continuous');
                info{end+1} = sprintf('continuous   %%OS %5.1f  T_s %6.2f',Sc.Overshoot,Sc.SettlingTime);
            end
            if sta
                ya = step(Ta,t);  Sa = stepinfo(ya,t,1);
                plot(ax2y,t,ya,'--','Color',cRed,'LineWidth',2,'DisplayName','L* approximation');
                info{end+1} = sprintf('L* approx    %%OS %5.1f  T_s %6.2f',Sa.Overshoot,Sa.SettlingTime);
            else
                info{end+1} = 'L* approx    unstable';
            end
            if std
                % Plant output between samples: continuous plant driven by the held u[k]
                Ud = feedback(Gd,Pd);
                kk = (0:floor(tEnd/dT))';
                uk = step(Ud,kk*dT);
                uz = uk(min(floor(t/dT) + 1,numel(uk)));
                yd = lsim(P,uz,t);  Sd = stepinfo(yd,t,1);
                plot(ax2y,t,yd,'Color',cBlue,'LineWidth',2.5,'DisplayName','sampled-data (true)');
                ys = step(Td,kk*dT);
                plot(ax2y,kk*dT,ys,'.','Color',cBlue,'MarkerSize',12,'HitTest','off');
                info{end+1} = sprintf('sampled-data %%OS %5.1f  T_s %6.2f',Sd.Overshoot,Sd.SettlingTime);
            else
                info{end+1} = 'sampled-data unstable';
            end
            hold(ax2y,'off'); grid(ax2y,'on'); xlim(ax2y,[0 tEnd]); ylim(ax2y,[0 1.6]);
            showLegend(ax2y,'southeast');
            title(ax2y,sprintf('Step responses (specs: %%OS ≤ %s, T_s ≤ %s s)',num(OS),num(Ts))); xlabel(ax2y,'t (s)');

            % Performance against the sample time
            dTg = linspace(dT/20,max(3*dT,dT + 1e-3),40);
            ws = warning('off','all');  cleanup = onCleanup(@() warning(ws));   % margin warns for unstable loops
            pmA = nan(size(dTg));  pmD = nan(size(dTg));
            for q = 1:numel(dTg)
                [~,pmA(q)] = margin(L*(1 - s*dTg(q)/2));
                try
                    [~,pmD(q)] = margin(c2d(ss(K*G0),dTg(q),'tustin')*c2d(ss(P),dTg(q),'zoh'));
                catch
                end
            end
            [~,pmC] = margin(L);
            cla(ax2d); hold(ax2d,'on');
            plot(ax2d,dTg,pmA,'--','Color',cRed,'LineWidth',2,'DisplayName','L* approximation');
            plot(ax2d,dTg,pmD,'Color',cBlue,'LineWidth',2.5,'DisplayName','sampled-data');
            plot(ax2d,dTg([1 end]),pmC*[1 1],':','Color',[0.35 0.35 0.35],'LineWidth',1.5,'DisplayName','continuous');
            plot(ax2d,dTg([1 end]),[0 0],'k-','HitTest','off');
            yl = [min([pmA pmD 0 pmC]) - 5 max([pmA pmD pmC]) + 5];
            if any(~isfinite(yl)), yl = [-30 90]; end
            h = plot(ax2d,[dT dT],yl,'-','Color',cOrange,'LineWidth',3,'DisplayName','ΔT (drag)');
            draggable(h,ax2d,@(pt,~) setField(ef2T,dd2,max(pt(1),1e-4),@update2),@update2);
            hold(ax2d,'off'); grid(ax2d,'on'); xlim(ax2d,dTg([1 end])); ylim(ax2d,yl);
            showLegend(ax2d,'northeast');
            title(ax2d,'Phase margin against sample time'); xlabel(ax2d,'ΔT (s)'); ylabel(ax2d,'PM (deg)');

            [~,pmNow] = margin(Ls);
            txt = {sprintf('RHP zero of L*: s = 2/dT = %s',num(2/dT)); ...
                sprintf('At w = 1/dT the factor adds +%s dB and -%s deg', ...
                num(20*log10(abs(1 - 1i/2))),num(rad2deg(atan(0.5)))); ''; ...
                sprintf('PM: continuous %s deg, L* %s deg',num(pmC),num(pmNow)); ''};
            txt = [txt; info(:); {''; sprintf('Bounds on L*: M_A %s, M_B %s',mark(okA),mark(okB))}];
            ta2.Value = txt(:);
        catch err
            showError(ta2,err);
        end
    end

%% =====================================================================
%  Tab 3 callbacks
%  =====================================================================
    function loadPreset3()
        k = find(strcmp(presets3(:,1),dd3.Value));
        if isempty(presets3{k,3}), update3(); return, end
        ef3f.Value = presets3{k,2};
        [ef3x.Value, ef3a.Value, ef3b.Value] = presets3{k,3:5};
        update3();
    end

    function update3()
        try
            f = str2num(ef3f.Value); %#ok<ST2NM>
            if isempty(f) || ~isnumeric(f), error('Enter the sequence as numbers, e.g. [0 1 2 2 3].'); end
            f = f(:)';
            x = ef3x.Value;
            n = 0:numel(f) - 1;
            nShift = n + x;
            keep = nShift >= 0;                       % samples shifted before n = 0 are lost
            lbl3a.Text = ['$F(z)=\sum_k f[k]z^{-k}=' zSeries(f,0) '$'];
            if x >= 0
                lbl3b.Text = sprintf('$\\mathcal{Z}\\{f[n-%d]\\}=z^{-%d}F(z)=%s$',x,x,zSeries(f,x));
            else
                lost = ~keep;
                lbl3b.Text = sprintf('$\\mathcal{Z}\\{f[n+%d]\\}=%s\\quad(\\mathrm{%d\\ sample(s)\\ before}\\ n=0\\ \\mathrm{are\\ dropped})$', ...
                    -x,zSeries(f(keep),0),sum(lost));
            end
            nMax = max([n nShift]) + 1;
            cla(ax3f); hold(ax3f,'on');
            stem(ax3f,n,f,'filled','Color',cBlue,'LineWidth',2,'MarkerSize',7,'DisplayName','f[n]');
            stem(ax3f,nShift(keep) + 0.12,f(keep),'filled','Color',cOrange,'LineWidth',2,'MarkerSize',7, ...
                'DisplayName',sprintf('f[n%s]',signedInt(-x)));
            for q = 1:numel(f)
                h = plot(ax3f,n(q),f(q),'o','MarkerSize',13,'MarkerEdgeColor',cBlue,'LineWidth',1.5);
                draggable(h,ax3f,@(pt,~) setSample3(q,pt(2)),@update3);
            end
            hold(ax3f,'off'); grid(ax3f,'on'); xlim(ax3f,[min([0 nShift]) - 0.5 nMax]);
            showLegend(ax3f,'northeast');
            title(ax3f,'Sequences (drag the blue circles to change f[n])'); xlabel(ax3f,'n');

            % Difference equation y[n] = a u[n] - b u[n-1] with a unit step input
            a = ef3a.Value;  b = ef3b.Value;
            N = 10;  nn = 0:N;
            u = ones(size(nn));
            y = a*u - b*[0 u(1:end-1)];
            lbl3c.Text = sprintf(['$y[n]=%su[n]-%su[n-1]\\Rightarrow Y(z)=(%s-%sz^{-1})U(z),\\quad P(z)=\\frac{Y(z)}{U(z)}=' ...
                '%s-%sz^{-1}=\\frac{%sz-%s}{z}$'],num(a),num(b),num(a),num(b),num(a),num(b),num(a),num(b));
            cla(ax3d); hold(ax3d,'on');
            stem(ax3d,nn,u,'Color',cGrey,'LineWidth',1.5,'DisplayName','u[n] = 1');
            stem(ax3d,nn + 0.1,y,'filled','Color',cRed,'LineWidth',2,'DisplayName','y[n]');
            ysys = step(tf([a -b],[1 0],1),N);       % check with a discrete tf (sample time 1)
            hold(ax3d,'off'); grid(ax3d,'on'); xlim(ax3d,[-0.5 N + 0.5]);
            showLegend(ax3d,'southeast');
            title(ax3d,'Difference equation with a unit step input'); xlabel(ax3d,'n');

            txt = {sprintf('F(z) has %d term(s); f[k] multiplies z^-k.',sum(f ~= 0)); ...
                sprintf('Shift x = %d: F(z) is multiplied by z^%d',x,-x)};
            if x < 0
                txt = [txt; {'Advance: samples moved before n = 0 are'; ...
                    'lost, so z^x F(z) is only exact when those'; 'samples are zero.'}];
            end
            txt = [txt; {''; sprintf('y[n] = %s u[n] - %s u[n-1]:',num(a),num(b)); ...
                sprintf('  y[0] = %s, then y[n] = %s',num(y(1)),num(y(end))); ...
                sprintf('  check with step(P(z)): max diff %.1e',max(abs(ysys(:)' - y)))}];
            ta3.Value = txt(:);
        catch err
            showError(ta3,err);
        end
    end

    function setSample3(q,v)
        f = str2num(ef3f.Value); %#ok<ST2NM>
        f(q) = round(v*2)/2;
        ef3f.Value = ['[' strjoin(arrayfun(@num,f,'UniformOutput',false),' ') ']'];
        dd3.Value = 'Custom';
        update3();
    end

%% =====================================================================
%  Tab 4 callbacks
%  =====================================================================
    function loadPreset4()
        k = find(strcmp(presets4(:,1),dd4.Value));
        if isempty(presets4{k,3}), update4(); return, end
        ef4.Value = presets4{k,2};  ef4T.Value = presets4{k,3};
        sel4 = 0;
        update4();
    end

    function update4()
        try
            G = parseTF(ef4.Value);  dT = ef4T.Value;
            Gz = c2d(G,dT,'tustin');
            [nz,dz] = tfdata(tf(Gz),'v');
            [z,p,K] = zpkdata(G,'v');
            [zz,pz] = zpkdata(Gz,'v');
            lbl4a.Text = sprintf('$G(z)=G(s)\\big|_{s=\\frac{2(z-1)}{\\Delta T(z+1)}}=\\frac{%s}{%s}\\quad(\\Delta T=%s)$', ...
                polyTex(nz,'z'),polyTex(dz,'z'),num(dT));
            lbl4b.Text = symbolicGz(G);

            % s-plane with draggable poles and zeros
            rl = rootList(z,p);
            cla(ax4s); hold(ax4s,'on');
            v = [rl.val];
            R = max([abs(v) 1])*1.4;
            plot(ax4s,[-R R],[0 0],'k-',[0 0],[-R R],'k-','HitTest','off');
            plot(ax4s,[-R R NaN -R R],pi/dT*[1 1 NaN -1 -1],':','Color',cOrange,'LineWidth',1.5,'HitTest','off');
            text(ax4s,-R,pi/dT,' ω = π/ΔT (Nyquist)','Color',cOrange,'FontSize',11,'VerticalAlignment','bottom','HitTest','off');
            for j = 1:numel(rl)
                col = pick(j == sel4,cSel,cPurple);
                vals = rl(j).val;
                if rl(j).pair, vals = [vals conj(vals)]; end %#ok<AGROW>
                for q = 1:numel(vals)
                    if rl(j).kind == 'p'
                        h = plot(ax4s,real(vals(q)),imag(vals(q)),'x','MarkerSize',16,'LineWidth',3,'Color',col);
                    else
                        h = plot(ax4s,real(vals(q)),imag(vals(q)),'o','MarkerSize',12,'LineWidth',2.5,'Color',col);
                    end
                    draggable(h,ax4s,@(pt,~) moveRoot4(j,pt,rl),@update4);
                end
            end
            hold(ax4s,'off'); grid(ax4s,'on'); axis(ax4s,'equal'); xlim(ax4s,[-R R]); ylim(ax4s,[-R R]);
            title(ax4s,'s-plane: drag the poles and zeros of G(s)'); xlabel(ax4s,'Re s'); ylabel(ax4s,'Im s');

            % z-plane
            th = linspace(0,2*pi,300);
            cla(ax4z); hold(ax4z,'on');
            patch(ax4z,cos(th),sin(th),[0.92 0.96 1],'EdgeColor',[0.3 0.3 0.3],'LineWidth',1.5,'HitTest','off');
            plot(ax4z,[-1.6 1.6],[0 0],'k-',[0 0],[-1.6 1.6],'k-','HitTest','off');
            pe = exp(p*dT);  ze = exp(z*dT);
            plot(ax4z,real(pe),imag(pe),'x','MarkerSize',12,'LineWidth',1.5,'Color',cGrey,'DisplayName','e^{sΔT} (exact)');
            plot(ax4z,real(ze),imag(ze),'o','MarkerSize',10,'LineWidth',1.5,'Color',cGrey,'HitTest','off');
            plot(ax4z,real(pz),imag(pz),'x','MarkerSize',16,'LineWidth',3,'Color',cRed,'DisplayName','Tustin poles');
            if ~isempty(zz)
                plot(ax4z,real(zz),imag(zz),'o','MarkerSize',12,'LineWidth',2.5,'Color',cRed,'DisplayName','Tustin zeros');
            end
            hold(ax4z,'off'); grid(ax4z,'on'); axis(ax4z,'equal'); xlim(ax4z,[-1.6 1.6]); ylim(ax4z,[-1.6 1.6]);
            showLegend(ax4z,'southwest');
            title(ax4z,'z-plane (shaded: inside the unit circle = stable)'); xlabel(ax4z,'Re z'); ylabel(ax4z,'Im z');

            % Frequency responses: G(jw) and G(e^{jw dT}) up to the Nyquist frequency
            wN = pi/dT;
            w = logspace(log10(wN) - 3,log10(wN*0.999),600)';
            Gc = squeeze(freqresp(G,w));  Gd = squeeze(freqresp(Gz,w));
            cla(ax4b); hold(ax4b,'on');
            plot(ax4b,w,20*log10(abs(Gc)),'Color',[0.35 0.35 0.35],'LineWidth',2,'DisplayName','|G(jω)| (continuous)');
            plot(ax4b,w,20*log10(abs(Gd)),'Color',cRed,'LineWidth',2.5,'DisplayName','|G(e^{jωΔT})| (Tustin)');
            yl = ylim(ax4b);
            plot(ax4b,[wN wN],yl,'--','Color',cOrange,'LineWidth',2,'DisplayName','Nyquist ω = π/ΔT');
            hold(ax4b,'off'); grid(ax4b,'on'); set(ax4b,'XScale','log'); xlim(ax4b,[w(1) wN*1.5]);
            showLegend(ax4b,'southwest');
            title(ax4b,'Frequency response: Tustin matches at low ω, warps towards the Nyquist frequency');
            xlabel(ax4b,'ω (rad/s)'); ylabel(ax4b,'dB');

            txt = {sprintf('dT = %s s, Nyquist w = pi/dT = %s rad/s',num(dT),num(wN)); ''; 'Poles: s -> z (Tustin | exact e^(s dT))'};
            for q = 1:numel(p)
                zt = (1 + p(q)*dT/2)/(1 - p(q)*dT/2);
                txt{end+1} = sprintf('  %s -> %s | %s',cplx(p(q)),cplx(zt),cplx(exp(p(q)*dT))); %#ok<AGROW>
            end
            if ~isempty(z)
                txt{end+1} = 'Zeros:';
                for q = 1:numel(z)
                    txt{end+1} = sprintf('  %s -> %s',cplx(z(q)),cplx((1 + z(q)*dT/2)/(1 - z(q)*dT/2))); %#ok<AGROW>
                end
            end
            nInf = numel(p) - numel(z);
            if nInf > 0
                txt{end+1} = sprintf('%d zero(s) at s = inf -> z = -1',nInf);
            end
            txt{end+1} = '';
            txt{end+1} = sprintf('DC gain: G(0) = %s, G(z=1) = %s',num(dcgain(G)),num(dcgain(Gz)));
            ta4.Value = txt(:);
        catch err
            showError(ta4,err);
        end
    end

    function moveRoot4(j,pt,rl)
        xr = diff(ax4s.XLim);
        x = pt(1);
        if abs(x) < 0.02*xr, x = 0; end
        if rl(j).pair, rl(j).val = complex(x,max(abs(pt(2)),0.02*xr)); else, rl(j).val = x; end
        sel4 = j;
        setRoots4(rl);
    end

    function setRoots4(rl)
        [~,~,K] = zpkdata(parseTF(ef4.Value),'v');
        ef4.Value = rootsToExpr(rl,K);
        dd4.Value = 'Custom';
        update4();
    end

    function addRoot4()
        item = dd4Add.Value;  dd4Add.Value = addItems{1};
        if strcmp(item,addItems{1}), return, end
        [z,p] = zpkdata(parseTF(ef4.Value),'v');
        rl = rootList(z,p);
        switch item
            case 'Real pole',          rl(end+1) = rootEntry('p',-1,false);
            case 'Complex pole pair',  rl(end+1) = rootEntry('p',complex(-1,2),true);
            case 'Real zero',          rl(end+1) = rootEntry('z',-2,false);
            case 'Complex zero pair',  rl(end+1) = rootEntry('z',complex(-2,2),true);
        end
        sel4 = numel(rl);
        setRoots4(rl);
    end

    function deleteRoot4()
        [z,p] = zpkdata(parseTF(ef4.Value),'v');
        rl = rootList(z,p);
        if sel4 < 1 || sel4 > numel(rl), return, end
        rl(sel4) = [];  sel4 = 0;
        setRoots4(rl);
    end

%% =====================================================================
%  Tab 5 callbacks
%  =====================================================================
    function loadPreset5()
        k = find(strcmp(presets5(:,1),dd5.Value));
        if isempty(presets5{k,4}), update5(); return, end
        ef5P.Value = presets5{k,2};  ef5G.Value = presets5{k,3};
        [ef5T.Value, ef5r.Value] = presets5{k,4:5};
        update5();
    end

    function update5()
        try
            P = parseTF(ef5P.Value);  G = parseTF(ef5G.Value);  dT = ef5T.Value;  r = ef5r.Value;
            if ~isproper(G), error('G(s) must be proper to be implemented.'); end
            Gz = c2d(tf(G),dT,'tustin');
            [a,b] = tfdata(Gz,'v');
            a = a/b(1);  b = b/b(1);                 % normalise so that b(1) = 1 (a first!)
            N = numel(b) - 1;

            % Difference equation in LaTeX
            terms = {};
            for j = 0:N
                if abs(a(j+1)) > 1e-12, terms{end+1} = sprintf('%s%se[n%s]',sgnStr(a(j+1),isempty(terms)),num(abs(a(j+1))),lagStr(j)); end %#ok<AGROW>
            end
            for j = 1:N
                if abs(b(j+1)) > 1e-12, terms{end+1} = sprintf('%s%su[n%s]',sgnStr(-b(j+1),isempty(terms)),num(abs(b(j+1))),lagStr(j)); end %#ok<AGROW>
            end
            [ng,dg] = tfdata(tf(G),'v');
            lbl5a.Text = sprintf('$G(s)=\\frac{%s}{%s}\\ \\rightarrow\\ G(z)=\\frac{%s}{%s}\\quad(\\mathrm{Tustin},\\ \\Delta T=%s)$', ...
                polyTex(ng,'s'),polyTex(dg,'s'),polyTex(a,'z'),polyTex(b,'z'),num(dT));
            lbl5b.Text = ['$u[n]=' strjoin(terms,'') '$'];

            % Code
            if strcmp(dd5L.Value,langs5{1})
                code = matlabCode(a,b,dT,ef5G.Value);
            else
                code = arduinoCode(a,b,dT,ef5G.Value);
            end
            ta5.Value = code;

            % Simulation: analogue loop against the digital loop
            Tc = feedback(P*G,1);  Uc = feedback(G,P);
            Pd = c2d(ss(P),dT,'zoh');
            Td = feedback(Gz*Pd,1);  Ud = feedback(Gz,Pd);
            stD = all(abs(pole(Td)) < 1 - 1e-9);
            pc = pole(Tc);
            if all(real(pc) < -1e-9), tEnd = min(6/min(-real(pc)),200); else, tEnd = 20; end
            tEnd = max(tEnd,15*dT);
            t = linspace(0,tEnd,3000)';
            kk = (0:floor(tEnd/dT))';
            uk = r*step(Ud,kk*dT);
            if numel(kk) > 1e5, error('Too many samples: increase dT or shorten the simulation.'); end
            uz = uk(min(floor(t/dT) + 1,numel(uk)));
            yd = lsim(P,uz,t);
            yk = r*step(Td,kk*dT);
            cla(ax5y); hold(ax5y,'on');
            plot(ax5y,[0 tEnd],[r r],'k--','LineWidth',1.2,'DisplayName','r');
            if all(real(pc) < 1e-9), plot(ax5y,t,r*step(Tc,t),'Color',[0.4 0.4 0.4],'LineWidth',2,'DisplayName','analogue G(s)'); end
            plot(ax5y,t,yd,'Color',cBlue,'LineWidth',2.5,'DisplayName','digital G(z), ZOH');
            if numel(kk) <= 400
                plot(ax5y,kk*dT,yk,'.','Color',cBlue,'MarkerSize',14,'DisplayName','y[n] (what the controller sees)');
            end
            hold(ax5y,'off'); grid(ax5y,'on'); xlim(ax5y,[0 tEnd]);
            yl = ylim(ax5y);  ylim(ax5y,[min(yl(1),0) min(yl(2),3*abs(r) + 1)]);
            showLegend(ax5y,'southeast');
            title(ax5y,sprintf('Output: digital loop %s',pick(stD,'stable','UNSTABLE'))); xlabel(ax5y,'t (s)');
            cla(ax5u); hold(ax5u,'on');
            if all(real(pc) < 1e-9), plot(ax5u,t,r*step(Uc,t),'Color',[0.4 0.4 0.4],'LineWidth',2,'DisplayName','analogue u(t)'); end
            stairs(ax5u,[kk; kk(end) + 1]*dT,[uk; uk(end)],'Color',cRed,'LineWidth',2.2,'DisplayName','digital u[n] (held)');
            if numel(kk) >= 2
                h = plot(ax5u,dT,uk(2),'s','MarkerSize',12,'MarkerFaceColor',cOrange,'MarkerEdgeColor','k','DisplayName','drag: ΔT');
                draggable(h,ax5u,@(pt,~) setField(ef5T,dd5,max(pt(1),1e-5),@update5),@update5);
            end
            hold(ax5u,'off'); grid(ax5u,'on'); xlim(ax5u,[0 tEnd]);
            showLegend(ax5u,'northeast');
            title(ax5u,'Control action: the DAC holds u[n] for ΔT seconds'); xlabel(ax5u,'t (s)');
        catch err
            showError(ta5,err);
        end
    end
end

%% =========================================================================
%  Code generation
%  =========================================================================
function code = matlabCode(a,b,dT,gStr)
N = numel(b) - 1;
code = {sprintf('%% Digital controller for G(s) = %s',gStr); ...
    sprintf('%% Tustin transform, sample time dT = %s s',num(dT)); ...
    sprintf('a = %s;  %% numerator of G(z)',vecStr(a)); ...
    sprintf('b = %s;  %% denominator (b(1) = 1)',vecStr(b)); ...
    sprintf('e_ = zeros(%d,1);  %% past errors e[n-1] ... e[n-%d]',N,N); ...
    sprintf('u_ = zeros(%d,1);  %% past actions u[n-1] ... u[n-%d]',N,N); ''; ...
    '% every dT seconds:'; ...
    'e = r - y;                          % tracking error e[n]'};
if N > 0
    code = [code; {'u = a*[e; e_] - b(2:end)*u_;     % difference equation'; ...
        'u_ = [u; u_(1:end-1)];             % shift the past values'; ...
        'e_ = [e; e_(1:end-1)];'}];
else
    code = [code; {'u = a(1)*e;                        % static gain'}];
end
code = [code; {''; 'Difference equation:'; diffEqStr(a,b)}];
end

function code = arduinoCode(a,b,dT,gStr)
N = numel(b) - 1;
code = {sprintf('// Digital controller for G(s) = %s',gStr); ...
    sprintf('// Tustin transform, dT = %s s',num(dT)); ...
    sprintf('const unsigned long DT_US = %d;',round(dT*1e6)); ...
    sprintf('const float a[%d] = {%s};',N + 1,strjoin(arrayfun(@(v) sprintf('%.7gf',v),a,'UniformOutput',false),', '))};
if N > 0
    code = [code; {sprintf('const float b[%d] = {%s};',N + 1,strjoin(arrayfun(@(v) sprintf('%.7gf',v),b,'UniformOutput',false),', ')); ...
        sprintf('float e_[%d] = {0};  // e[n-1] ...',N); ...
        sprintf('float u_[%d] = {0};  // u[n-1] ...',N)}];
end
code = [code; {'unsigned long tNext = 0;'; ''; 'void loop() {'; ...
    '  if (micros() < tNext) return;'; '  tNext += DT_US;'; ...
    '  float e = reference() - readSensor();'; '  float u = a[0]*e;'}];
if N > 0
    code = [code; {sprintf('  for (int j = 0; j < %d; j++)',N); ...
        '    u += a[j+1]*e_[j] - b[j+1]*u_[j];'; ...
        sprintf('  for (int j = %d; j > 0; j--) {',N - 1); ...
        '    e_[j] = e_[j-1];  u_[j] = u_[j-1];'; '  }'; ...
        '  e_[0] = e;  u_[0] = u;'}];
end
code = [code; {'  writeActuator(u);   // the DAC/PWM holds u'; '}'}];
end

function s = diffEqStr(a,b)
N = numel(b) - 1;
s = 'u[n] =';
for j = 0:N
    if abs(a(j+1)) > 1e-12, s = sprintf('%s %+.6g e[n%s]',s,a(j+1),lagStr(j)); end
end
s = strrep(s,'= +','= ');
for j = 1:N
    if abs(b(j+1)) > 1e-12, s = sprintf('%s %+.6g u[n%s]',s,-b(j+1),lagStr(j)); end
end
end

function s = lagStr(j)
if j == 0, s = ''; else, s = sprintf('-%d',j); end
end

function s = sgnStr(v,first)
if v < 0, s = '-'; elseif first, s = ''; else, s = '+'; end
end

function s = vecStr(v)
s = ['[' strjoin(arrayfun(@(x) sprintf('%.7g',x),v,'UniformOutput',false),' ') ']'];
end

function s = symbolicGz(G)
% G(z) as a ratio of polynomials in z with symbolic dT (as in 13.4.2 Example 1).
s = '';
try
    z = sym('z');  dT = sym('dT');
    [ng,dg] = tfdata(tf(G),'v');
    ss_ = 2*(z - 1)/(dT*(z + 1));
    Gs = poly2sym(ng,sym('s'))/poly2sym(dg,sym('s'));
    Gzs = simplify(subs(Gs,sym('s'),ss_));
    [nz,dz] = numden(Gzs);
    nz = collect(expand(nz),z);  dz = collect(expand(dz),z);
    s = ['$G(z)=\frac{' latex(nz) '}{' latex(dz) '}\quad(\mathrm{any}\ \Delta T)$'];
    s = strrep(s,'\mathrm{dT}','\Delta T');
    s = strrep(s,'dT','\Delta T');
catch
end
end

%% =========================================================================
%  Z-transform helpers
%  =========================================================================
function s = zSeries(f,shift)
% sum_k f[k] z^-(k+shift) in LaTeX.
s = '';
for k = 0:numel(f) - 1
    v = f(k+1);
    if v == 0, continue, end
    pw = k + shift;
    if pw == 0, zz = ''; else, zz = sprintf('z^{-%d}',pw); end
    if abs(v) == 1 && ~isempty(zz), c = ''; else, c = num(abs(v)); end
    if isempty(s), sg = pick(v < 0,'-',''); else, sg = pick(v < 0,'-','+'); end
    s = [s sg c zz]; %#ok<AGROW>
end
if isempty(s), s = '0'; end
end

function s = signedInt(x)
if x == 0, s = ''; elseif x > 0, s = sprintf('+%d',x); else, s = sprintf('%d',x); end
end

%% =========================================================================
%  Frequency-response and bound helpers
%  =========================================================================
function [Pw,ph] = freqData(P,w)
% Frequency response and continuous phase (deg), each factor unwrapped.
[z,p,k] = zpkdata(zpk(P),'v');
jw = 1j*w(:);
Pw = k*ones(size(jw));
ph = zeros(size(jw));
if k < 0, ph = ph + 180; end
for i = 1:numel(z)
    f = jw - z(i);  Pw = Pw.*f;  ph = ph + unwrap(angle(f))*180/pi;
end
for i = 1:numel(p)
    f = jw - p(i);  Pw = Pw./f;  ph = ph - unwrap(angle(f))*180/pi;
end
ph = ph - 360*ceil(ph(1)/360 - 1e-9);          % low-frequency phase in (-360, 0]
end

function w = freqGrid(P,extra)
% Logarithmic grid two decades either side of the poles and zeros.
[z,p] = zpkdata(zpk(P),'v');
c = abs([z; p]);  c = c(c > 1e-9);
if isempty(c), c = 1; end
lo = min(c)/100;  hi = max(c)*100;
if ~isempty(extra), lo = min(lo,min(extra)/10);  hi = max(hi,max(extra)*10); end
w = logspace(log10(lo),log10(hi),3000)';
if ~isempty(extra), w = unique([w; extra(:)]); end
end

function shadeRegions(ax,phLo,phHi,dbLim,test,col)
% Shade the part of the log-polar plane where test(L) is true.
[PH,DB] = meshgrid(linspace(phLo,phHi,400),linspace(dbLim(1),dbLim(2),300));
Lc = 10.^(DB/20).*exp(1i*PH*pi/180);
mask = test(Lc);
img = repmat(reshape(col,1,1,3),size(mask,1),size(mask,2));
image(ax,[phLo phHi],dbLim,img,'AlphaData',0.28*mask,'HitTest','off');
ax.YDir = 'normal';
end

function [lo,hi] = phaseWindow(ph)
lo = min(-360,90*floor(min(ph)/90));
hi = max(0,90*ceil(max(ph)/90));
lo = max(lo,-720);  hi = min(hi,360);
end

function ok = isStableC(sys)
ok = all(real(pole(sys)) < -1e-9);
end

function zeta = zetaFromOS(OS)
Lg = log(OS/100);
zeta = -Lg/sqrt(pi^2 + Lg^2);
end

%% =========================================================================
%  Pole-zero editing helpers
%  =========================================================================
function sys = parseTF(str)
% Evaluate a MATLAB expression in s as a zpk model.
str = strtrim(str);
if isempty(str), error('Transfer function is empty.'); end
f = str2func(['@(s) ' str]);
sys = zpk(f(tf('s')));
end

function rl = rootList(z,p)
% Poles/zeros as draggable entries; a complex pair is one entry (imag > 0).
rl = repmat(rootEntry('p',0,false),1,0);
kinds = {'z','p'};
vals = {z(:), p(:)};
for m = 1:2
    v = vals{m};
    tol = 1e-6*max(1,abs(v));
    for q = 1:numel(v)
        if abs(imag(v(q))) < tol(q)
            rl(end+1) = rootEntry(kinds{m},real(v(q)),false); %#ok<AGROW>
        elseif imag(v(q)) > 0
            rl(end+1) = rootEntry(kinds{m},v(q),true); %#ok<AGROW>
        end
    end
end
end

function r = rootEntry(kind,val,pair)
r = struct('kind',kind,'val',val,'pair',pair);
end

function expr = rootsToExpr(rl,K)
% MATLAB expression in s for the zpk model K*prod(s-z)/prod(s-p).
num_ = factorStr(rl([rl.kind] == 'z'));
den = factorStr(rl([rl.kind] == 'p'));
expr = sprintf('%.6g',K);
if ~isempty(num_), expr = [expr '*' num_]; end
if ~isempty(den), expr = [expr '/(' den ')']; end
end

function str = factorStr(rl)
% Product of first/second-order factors, with repeated factors as powers.
f = cell(1,numel(rl));
for j = 1:numel(rl)
    v = rl(j).val;
    if rl(j).pair
        f{j} = sprintf('(s^2%+.5g*s%+.5g)',-2*real(v),abs(v)^2);
    elseif abs(v) < 1e-12
        f{j} = 's';
    else
        f{j} = sprintf('(s%+.5g)',-real(v));
    end
end
[u,~,ic] = unique(f,'stable');
parts = cell(1,numel(u));
for m = 1:numel(u)
    n = sum(ic == m);
    if n > 1, parts{m} = sprintf('%s^%d',u{m},n); else, parts{m} = u{m}; end
end
str = strjoin(parts,'*');
end

%% =========================================================================
%  Text and UI helpers
%  =========================================================================
function s = num(x)
if abs(x) >= 1e4 && abs(x) < 1e7, s = sprintf('%.0f',x); else, s = sprintf('%.4g',x); end
if strcmp(s,'-0'), s = '0'; end
end

function s = cplx(z)
if abs(imag(z)) < 1e-9*max(1,abs(z)), s = num(real(z));
else, s = sprintf('%.4g%+.4gj',real(z),imag(z)); end
end

function s = mark(ok)
if ok, s = '✔'; else, s = '✘'; end
end

function s = pick(c,a,b)
if c, s = a; else, s = b; end
end

function str = polyTex(c,v)
% Polynomial in descending powers of v ('s' or 'z'), in LaTeX.
c(abs(c) < 1e-12*max(abs(c))) = 0;
idx = find(c ~= 0,1);
if isempty(idx), str = '0'; return, end
c = c(idx:end);  n = numel(c) - 1;  str = '';
for i = 1:numel(c)
    if c(i) == 0, continue, end
    pw = n - i + 1;  mag = abs(c(i));
    if pw == 0, term = num(mag);
    else
        if pw == 1, vv = v; else, vv = sprintf('%s^{%d}',v,pw); end
        if abs(mag - 1) < 1e-12, term = vv; else, term = [num(mag) vv]; end
    end
    if isempty(str)
        if c(i) < 0, str = ['-' term]; else, str = term; end
    elseif c(i) < 0, str = [str '-' term]; %#ok<AGROW>
    else, str = [str '+' term]; %#ok<AGROW>
    end
end
end

function showLegend(ax,loc)
% Legend of the curves that have a DisplayName (markers and guides have none).
h = flipud(findobj(ax,'Type','line','-or','Type','stem','-or','Type','stair'));
h = h(arrayfun(@(q) ~isempty(q.DisplayName),h));
if isempty(h), legend(ax,'off');
else, legend(ax,h,'Location',loc,'AutoUpdate','off'); end
end

function s = onoff(b)
if b, s = 'on'; else, s = 'off'; end
end

function h = at(h,row,col)
% Place a component in a grid layout cell (row, col may be spans like [1 2]).
h.Layout.Row = row;
h.Layout.Column = col;
end

function markCustom(dd,updateFcn)
% Editing a parameter by hand switches the example selector to Custom.
dd.Value = 'Custom';
updateFcn();
end

function showError(ta,err)
ta.Value = {'Error:'; err.message; ''; ...
    'Enter transfer functions as MATLAB expressions in s,'; ...
    'e.g. 5/(s+1) or 10*(1+5*s)/(5*s).'};
end
