function Chapter2_SignalsAndSystemsApp
%CHAPTER2_SIGNALSANDSYSTEMSAPP Interactive GUI for MEC3079S Chapter 2 — Signals and systems.
%
%   Run Chapter2_SignalsAndSystemsApp to open the app. The tabs follow the chapter:
%     1. System properties  (2.2): test additivity, homogeneity (linearity),
%        time-invariance and causality of a system numerically.
%     2. ODE to P(s)        (2.3-2.5.2): differential equation, its Laplace
%        transform (zero initial conditions) and the transfer function.
%     3. Laplace transforms (2.4, 2.6): forward/inverse transforms and the
%        properties of Table 2.1, checked against the transform rules.
%     4. P(s) from data     (2.5.3): P(s) = L{y(t)}/L{u(t)}.
%
%   Interaction:
%     - Tab 1: drag on the time-invariance plot to set the delay tau, and on
%       the causality plot to set t_n; drag up/down on the linearity plot to
%       change alpha and on the inputs/outputs plot to change beta.
%     - Tab 2: drag the poles (x) and zeros (o) of P(s); the differential
%       equation coefficients follow.
%     - Tab 3: drag g(t) left/right to change the time shift tau.
%     - Tab 4: drag the poles (x) and zeros (o) of the identified P(s); the
%       output y(t) = L^-1{P(s)U(s)} is regenerated (the DC gain is kept).
%
%   Signals are entered as MATLAB expressions in t (e.g. sin(10*t), 5*t,
%   exp(-a*t)), Laplace-domain functions in s (e.g. 1/(s/10+1)), and
%   transfer functions in s (e.g. s/(1+s/2)).
%
%   Requires the Control System Toolbox and the Symbolic Math Toolbox.

% Colours used throughout the app
c1c = [0.00 0.45 0.74];
c2c = [0.85 0.33 0.10];
c3c = [0.47 0.67 0.19];
cGr = [0.55 0.55 0.55];
cSel = [0.47 0.67 0.19];

fig = uifigure('Name','MEC3079S Chapter 2 — Signals and systems', ...
    'Position',[60 40 1320 860]);
mainGrid = uigridlayout(fig,[1 1],'Padding',[0 0 0 0]);
tg = uitabgroup(mainGrid);

% Drag state shared by all interactive plots
drag = struct('active',false,'ax',[],'move',[],'done',[],'p0',[0 0], ...
    'last',[],'xl',[],'yl',[],'t',tic);
fig.WindowButtonMotionFcn = @(~,~) onMotion();
fig.WindowButtonUpFcn = @(~,~) onRelease();

%% =====================================================================
%  Tab 1: System properties
%  =====================================================================
t1 = uitab(tg,'Title','System properties');
g1 = uigridlayout(t1,[1 2],'ColumnWidth',{340,'1x'});

c1 = uigridlayout(g1,[13 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{80,22,22,22,22,22,22,22,22,22,22,'1x',22});
at(uilabel(c1,'Text',['Causal LTI systems are linear (additive and homogeneous), ' ...
    'time-invariant and causal. Each property is tested numerically below. ' ...
    'Drag on the lower plots to set τ and t_n.'],'FontWeight','bold','WordWrap','on'),1,[1 2]);

% name, kind, P(s), u1, u2, alpha, beta
presets1 = { ...
    'Ex 2.2.3 additivity: P(s) = s/(1+s/2)',   'lti',     's/(1+s/2)',  'sin(10*t)', '5*t', 1,  1
    'Ex 2.2.3 homogeneity: P(s) = 1/(1+s/10)', 'lti',     '1/(1+s/10)', 'sin(10*t)', '5*t', 17, 0
    'Pure time delay: y(t) = u(t - 0.5)',      'delay',   '',           'sin(10*t)', '5*t', 2,  1
    'Static nonlinear: y = u^2',               'square',  '',           'sin(10*t)', '5*t', 2,  1
    'Offset: y = u + 1',                       'offset',  '',           'sin(10*t)', '5*t', 2,  1
    'Saturation: y = sat(u), |y| <= 1',        'sat',     '',           'sin(10*t)', '5*t', 17, 0
    'Time-varying gain: y = t u(t)',           'tv',      '',           'sin(10*t)', '5*t', 2,  1
    'Acausal: y(t) = u(t + 0.5)',              'advance', '',           'sin(10*t)', '5*t', 2,  1
    'Custom', '', '', '', '', [], []};
at(uilabel(c1,'Text','System'),2,1);
dd1Sys = at(uidropdown(c1,'Items',presets1(:,1)','Value',presets1{1,1}),2,2);
at(uilabel(c1,'Text','P(s) (LTI)'),3,1);
ef1P = at(uieditfield(c1,'text','Value',presets1{1,3}, ...
    'Tooltip','Transfer function for the LTI systems; edit it for a custom LTI system'),3,2);
at(uilabel(c1,'Text','Input u₁(t)'),4,1);
ef1u1 = at(uieditfield(c1,'text','Value',presets1{1,4},'Tooltip', ...
    'MATLAB expression in t, e.g. sin(10*t), 5*t, exp(-t), 1. Taken as zero for t < 0.'),4,2);
at(uilabel(c1,'Text','Input u₂(t)'),5,1);
ef1u2 = at(uieditfield(c1,'text','Value',presets1{1,5},'Tooltip',ef1u1.Tooltip),5,2);
at(uilabel(c1,'Text','Scalar α'),6,1);
ef1al = at(uieditfield(c1,'numeric','Value',presets1{1,6}),6,2);
at(uilabel(c1,'Text','Scalar β'),7,1);
ef1be = at(uieditfield(c1,'numeric','Value',presets1{1,7}),7,2);
at(uilabel(c1,'Text','Delay τ (s)'),8,1);
ef1tau = at(uieditfield(c1,'numeric','Value',1,'Limits',[0 Inf], ...
    'Tooltip','Time shift for the time-invariance test (drag on its plot)'),8,2);
at(uilabel(c1,'Text','Causality t_n (s)'),9,1);
ef1tn = at(uieditfield(c1,'numeric','Value',2,'Limits',[0 Inf], ...
    'Tooltip','The test input is changed only for t > t_n (drag on its plot)'),9,2);
at(uilabel(c1,'Text','Final time (s)'),10,1);
ef1T = at(uieditfield(c1,'numeric','Value',5,'Limits',[0.1 Inf]),10,2);
at(uilabel(c1,'Text','Results','FontWeight','bold'),11,[1 2]);
ta1 = at(uitextarea(c1,'Editable','off','FontName','Monospaced'),12,[1 2]);
btn1 = at(uibutton(c1,'Text','Update'),13,[1 2]);

r1 = uigridlayout(g1,[2 2]);
ax1u = uiaxes(r1);
ax1L = uiaxes(r1);
ax1T = uiaxes(r1);
ax1C = uiaxes(r1);

dd1Sys.ValueChangedFcn = @(~,~) loadPreset1();
ef1P.ValueChangedFcn = @(~,~) markCustom(dd1Sys,@update1);
[ef1u1.ValueChangedFcn, ef1u2.ValueChangedFcn, ef1al.ValueChangedFcn, ef1be.ValueChangedFcn, ...
    ef1tau.ValueChangedFcn, ef1tn.ValueChangedFcn, ef1T.ValueChangedFcn] = deal(@(~,~) update1());
btn1.ButtonPushedFcn = @(~,~) update1();
[ax1T.Interactions, ax1C.Interactions, ax1L.Interactions, ax1u.Interactions] = deal([]);
ax1L.ButtonDownFcn = @(~,~) startDrag(ax1L,@(pt,p0) setScalar1(ef1al,pt,p0),@update1);
ax1u.ButtonDownFcn = @(~,~) startDrag(ax1u,@(pt,p0) setScalar1(ef1be,pt,p0),@update1);
ax1T.ButtonDownFcn = @(~,~) startDrag(ax1T,@(pt,~) setTau1(pt(1)),@update1,true);
ax1C.ButtonDownFcn = @(~,~) startDrag(ax1C,@(pt,~) setTn1(pt(1)),@update1,true);

%% =====================================================================
%  Tab 2: Differential equation to transfer function
%  =====================================================================
t2 = uitab(tg,'Title','ODE to P(s)');
g2 = uigridlayout(t2,[1 2],'ColumnWidth',{340,'1x'});

c2 = uigridlayout(g2,[11 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{96,22,22,22,22,22,22,22,22,'1x',22});
at(uilabel(c2,'Text',['b₀y + b₁ẏ + … + bₙy⁽ⁿ⁾ = a₀u + a₁u̇ + … + aₘu⁽ᵐ⁾. With zero initial ' ...
    'conditions, d^k/dt^k → s^k, so P(s) = Y(s)/U(s) = (a₀ + a₁s + …)/(b₀ + b₁s + …). ' ...
    'Drag the poles/zeros of P(s) to change the coefficients.'], ...
    'FontWeight','bold','WordWrap','on'),1,[1 2]);

presets2 = { ...
    'Ex 2.3.1: 2y + dy/dt = 3u',                   '[2 1]',   '[3]'
    'Second order: 5y + 2dy/dt + d²y/dt² = 5u',     '[5 2 1]', '[5]'
    'Input derivative: 2y + 3ẏ + ÿ = u + u̇',       '[2 3 1]', '[1 1]'
    'Not causal (m > n): y + ẏ = u + u̇ + ü',       '[1 1]',   '[1 1 1]'
    'Custom', '', ''};
at(uilabel(c2,'Text','Example'),2,1);
dd2Preset = at(uidropdown(c2,'Items',presets2(:,1)','Value',presets2{1,1}),2,2);
at(uilabel(c2,'Text','Output coeffs b'),3,1);
ef2b = at(uieditfield(c2,'text','Value',presets2{1,2},'Tooltip', ...
    '[b0 b1 ... bn]: coefficients of y, dy/dt, ..., d^n y/dt^n'),3,2);
at(uilabel(c2,'Text','Input coeffs a'),4,1);
ef2a = at(uieditfield(c2,'text','Value',presets2{1,3},'Tooltip', ...
    '[a0 a1 ... am]: coefficients of u, du/dt, ..., d^m u/dt^m'),4,2);
at(uilabel(c2,'Text','Input u(t)'),5,1);
dd2In = at(uidropdown(c2,'Items',{'Unit step','Unit impulse','Unit ramp','Sinusoid'}),5,2);
at(uilabel(c2,'Text','Amplitude'),6,1);
ef2A = at(uieditfield(c2,'numeric','Value',1),6,2);
at(uilabel(c2,'Text','Frequency ω (rad/s)'),7,1);
ef2w = at(uieditfield(c2,'numeric','Value',2,'Limits',[0 Inf]),7,2);
at(uilabel(c2,'Text','Final time (0=auto)'),8,1);
ef2T = at(uieditfield(c2,'numeric','Value',0,'Limits',[0 Inf]),8,2);
at(uilabel(c2,'Text','Results','FontWeight','bold'),9,[1 2]);
ta2 = at(uitextarea(c2,'Editable','off','FontName','Monospaced'),10,[1 2]);
btn2 = at(uibutton(c2,'Text','Update'),11,[1 2]);

r2 = uigridlayout(g2,[4 2],'RowHeight',{'fit','fit','fit','1x'},'ColumnWidth',{'1x','1.4x'});
lbl2ode = at(uilabel(r2,'Text','','Interpreter','latex','FontSize',17),1,[1 2]);
lbl2lap = at(uilabel(r2,'Text','','Interpreter','latex','FontSize',17),2,[1 2]);
lbl2tf  = at(uilabel(r2,'Text','','Interpreter','latex','FontSize',17),3,[1 2]);
ax2pz = at(uiaxes(r2),4,1);
ax2y  = at(uiaxes(r2),4,2);

dd2Preset.ValueChangedFcn = @(~,~) loadPreset2();
[ef2b.ValueChangedFcn, ef2a.ValueChangedFcn] = deal(@(~,~) markCustom(dd2Preset,@update2));
[dd2In.ValueChangedFcn, ef2A.ValueChangedFcn, ef2w.ValueChangedFcn, ef2T.ValueChangedFcn] = deal(@(~,~) update2());
btn2.ButtonPushedFcn = @(~,~) update2();
ax2pz.Interactions = [];
pz2 = struct('roots',[],'K',1,'r0',[],'K0',1,'selKind','','selVal',[]);

%% =====================================================================
%  Tab 3: Laplace transforms
%  =====================================================================
t3 = uitab(tg,'Title','Laplace transforms');
g3 = uigridlayout(t3,[1 2],'ColumnWidth',{340,'1x'});

c3 = uigridlayout(g3,[13 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{80,22,22,22,22,22,22,22,22,22,'1x',22,0});
at(uilabel(c3,'Text',['F(s) = L{f(t)} = ∫₀^∞ f(t)e^(−st) dt (one-sided: f(t) for t < 0 is ' ...
    'ignored). Pick a property from Table 2.1 to see it applied and checked. ' ...
    'For the time shift, drag g(t).'],'FontWeight','bold','WordWrap','on'),1,[1 2]);

% name, direction, expression, a, b, property, parameter
presets3 = { ...
    'Ex 2.4.1: f(t) = e^{-at}',                  'f(t) → F(s)', 'exp(-a*t)',          -1, 3, 'None', 1
    'Ex 2.4.2: time shift of a step, τ = 3',      'f(t) → F(s)', 'heaviside(t)',        1, 1, 'Time shift', 3
    'Ex 2.6.2(1): y(t) = 2e^{-3t}',               'f(t) → F(s)', '2*exp(-3*t)',         1, 1, 'None', 1
    'Ex 2.6.2(2): Y(s) = 1/(s/10+1)',             'F(s) → f(t)', '1/(s/10+1)',          1, 1, 'None', 1
    'Ex 2.6.3: Y(s) = 1/(s/10+1) + 2/(s+3)',      'F(s) → f(t)', '1/(s/10+1)+2/(s+3)',  1, 1, 'None', 1
    'Sinusoid: f(t) = a sin(bt)',                 'f(t) → F(s)', 'a*sin(b*t)',          1, 2, 'Frequency shift', -0.5
    'Custom', '', '', [], [], '', []};
props3 = {'None','Time shift','Frequency shift','Time scaling','Homogeneity','Time derivative','Time integral'};
at(uilabel(c3,'Text','Example'),2,1);
dd3Preset = at(uidropdown(c3,'Items',presets3(:,1)','Value',presets3{1,1}),2,2);
at(uilabel(c3,'Text','Direction'),3,1);
dd3Dir = at(uidropdown(c3,'Items',{'f(t) → F(s)','F(s) → f(t)'}),3,2);
lbl3Expr = at(uilabel(c3,'Text','f(t) ='),4,1);
ef3Expr = at(uieditfield(c3,'text','Value',presets3{1,3},'Tooltip', ...
    'Expression in t (forward) or s (inverse); may use parameters a and b, heaviside, dirac.'),4,2);
at(uilabel(c3,'Text','Parameter a'),5,1);
ef3a = at(uieditfield(c3,'numeric','Value',presets3{1,4}),5,2);
at(uilabel(c3,'Text','Parameter b'),6,1);
ef3b = at(uieditfield(c3,'numeric','Value',presets3{1,5}),6,2);
at(uilabel(c3,'Text','Property'),7,1);
dd3Prop = at(uidropdown(c3,'Items',props3,'Value',presets3{1,6}),7,2);
lbl3c = at(uilabel(c3,'Text','Parameter c'),8,1);
ef3c = at(uieditfield(c3,'numeric','Value',presets3{1,7}),8,2);
at(uilabel(c3,'Text','Plot up to t (s)'),9,1);
ef3T = at(uieditfield(c3,'numeric','Value',8,'Limits',[0.1 Inf]),9,2);
at(uilabel(c3,'Text','Results','FontWeight','bold'),10,[1 2]);
ta3 = at(uitextarea(c3,'Editable','off','FontName','Monospaced'),11,[1 2]);
btn3 = at(uibutton(c3,'Text','Update'),12,[1 2]);

r3 = uigridlayout(g3,[5 2],'RowHeight',{'fit','fit','fit','1x',250},'ColumnWidth',{'1x','1x'});
lbl3pair = at(uilabel(r3,'Text','','Interpreter','latex','FontSize',17),1,[1 2]);
lbl3num  = at(uilabel(r3,'Text','','Interpreter','latex','FontSize',17),2,[1 2]);
lbl3prop = at(uilabel(r3,'Text','','Interpreter','latex','FontSize',17),3,[1 2]);
ax3 = at(uiaxes(r3),4,[1 2]);
tbl3p = at(uitable(r3,'ColumnName',{'Table 2.1 property','Time domain','Laplace domain'},'RowName',{}, ...
    'Data',{ 'Time derivative','df/dt','sF(s) − f(0)'; 'Time integral','∫₀ᵗ f(τ)dτ','F(s)/s'; ...
             'Frequency shift','e^(at) f(t)','F(s − a)'; 'Time shift','f(t − a)u(t − a)','e^(−as) F(s)'; ...
             'Time scaling','f(at)','(1/a) F(s/a)'; 'Convolution','f(t) * g(t)','F(s) G(s)'; ...
             'Homogeneous','k f(t)','k F(s)'; 'Additive','f₁(t) + f₂(t)','F₁(s) + F₂(s)'}),5,1);
tbl3t = at(uitable(r3,'ColumnName',{'Table 2.2 function','f(t)','F(s)'},'RowName',{}, ...
    'Data',{ 'Impulse','a δ(t)','a'; 'Step','a','a/s'; 'Ramp','a t','a/s²'; 'Parabolic','a t²/2','a/s³'; ...
             'nth order','a tⁿ/n!','a/s^(n+1)'; 'Exponential decay','a e^(−bt)','a/(s + b)'; ...
             'Sinusoid','a sin(ωt)','aω/(s² + ω²)'; 'Cosinusoid','a cos(ωt)','as/(s² + ω²)'}),5,2);

dd3Preset.ValueChangedFcn = @(~,~) loadPreset3();
ef3Expr.ValueChangedFcn = @(~,~) markCustom(dd3Preset,@() update3(true));
[dd3Dir.ValueChangedFcn, ef3a.ValueChangedFcn, ef3b.ValueChangedFcn, dd3Prop.ValueChangedFcn, ...
    ef3c.ValueChangedFcn, ef3T.ValueChangedFcn] = deal(@(~,~) update3(true));
btn3.ButtonPushedFcn = @(~,~) update3(true);
ax3.Interactions = [];
cache3 = struct('key','');

%% =====================================================================
%  Tab 4: Transfer function from input-output data
%  =====================================================================
t4 = uitab(tg,'Title','P(s) from data');
g4 = uigridlayout(t4,[1 2],'ColumnWidth',{340,'1x'});

c4 = uigridlayout(g4,[8 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{64,22,22,22,22,22,'1x',22});
at(uilabel(c4,'Text',['P(s) = Y(s)/U(s) = L{y(t)}/L{u(t)}: a model from a measured input ' ...
    'and output. The model is checked by simulating P(s) with u(t).'], ...
    'FontWeight','bold','WordWrap','on'),1,[1 2]);

presets4 = { ...
    'Ex 2.5.3: u(t) = 2, y(t) = 10t^2',            '2',    '10*t^2'
    'First order: u(t) = 1, y(t) = 1 - e^{-2t}',    '1',    '1 - exp(-2*t)'
    'Ramp input: u(t) = t, y(t) = t - 1 + e^{-t}',  't',    't - 1 + exp(-t)'
    'Custom', '', ''};
at(uilabel(c4,'Text','Example'),2,1);
dd4Preset = at(uidropdown(c4,'Items',presets4(:,1)','Value',presets4{1,1}),2,2);
at(uilabel(c4,'Text','Input u(t)'),3,1);
ef4u = at(uieditfield(c4,'text','Value',presets4{1,2},'Tooltip','Expression in t, valid for t >= 0'),3,2);
at(uilabel(c4,'Text','Output y(t)'),4,1);
ef4y = at(uieditfield(c4,'text','Value',presets4{1,3},'Tooltip','Expression in t, valid for t >= 0'),4,2);
at(uilabel(c4,'Text','Plot up to t (s)'),5,1);
ef4T = at(uieditfield(c4,'numeric','Value',5,'Limits',[0.1 Inf]),5,2);
at(uilabel(c4,'Text','Results','FontWeight','bold'),6,[1 2]);
ta4 = at(uitextarea(c4,'Editable','off','FontName','Monospaced'),7,[1 2]);
btn4 = at(uibutton(c4,'Text','Update'),8,[1 2]);

r4 = uigridlayout(g4,[4 1],'RowHeight',{'fit','fit','fit','1x'});
lbl4u = at(uilabel(r4,'Text','','Interpreter','latex','FontSize',17),1,1);
lbl4y = at(uilabel(r4,'Text','','Interpreter','latex','FontSize',17),2,1);
lbl4P = at(uilabel(r4,'Text','','Interpreter','latex','FontSize',17),3,1);
g4p = at(uigridlayout(r4,[1 2],'Padding',[0 0 0 0],'ColumnWidth',{'1.6x','1x'}),4,1);
ax4 = uiaxes(g4p);
ax4p = uiaxes(g4p);
ax4p.Interactions = [];

dd4Preset.ValueChangedFcn = @(~,~) loadPreset4();
[ef4u.ValueChangedFcn, ef4y.ValueChangedFcn] = deal(@(~,~) markCustom(dd4Preset,@update4));
ef4T.ValueChangedFcn = @(~,~) update4();
btn4.ButtonPushedFcn = @(~,~) update4();

% Initial draw
update1(); update2(); update3(true); update4();

%% =====================================================================
%  Dragging
%  =====================================================================
    function startDrag(ax,moveFcn,doneFcn,applyNow)
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
        if nargin > 3 && applyNow
            applyDrag(drag.p0);
        end
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
        drag.v0 = [];  drag.pz4 = [];
        if isvalid(drag.ax)
            drag.ax.XLimMode = 'auto';
            drag.ax.YLimMode = 'auto';
        end
        if ~isempty(drag.done), drag.done(); end
    end

    function applyDrag(pt)
        drag.move(pt,drag.p0);
        % Hold the dragged axes still so the curve follows the mouse
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

%% =====================================================================
%  Tab 1 callbacks
%  =====================================================================
    function loadPreset1()
        i = find(strcmp(presets1(:,1),dd1Sys.Value));
        if isempty(presets1{i,2}), return, end
        if ~isempty(presets1{i,3}), ef1P.Value = presets1{i,3}; end
        ef1u1.Value = presets1{i,4};
        ef1u2.Value = presets1{i,5};
        ef1al.Value = presets1{i,6};
        ef1be.Value = presets1{i,7};
        update1();
    end

    function setTau1(x)
        ef1tau.Value = min(max(x,0),ef1T.Value);
        update1();
    end

    function setScalar1(ef,pt,p0)
        % Vertical drag: the full axes height changes the scalar by 4 (or 2x its size).
        if ~isfield(drag,'v0') || isempty(drag.v0), drag.v0 = ef.Value; end
        span = max(4,2*abs(drag.v0));
        ef.Value = round(drag.v0 + (pt(2) - p0(2))/diff(drag.yl)*span,2);
        update1();
    end

    function setTn1(x)
        ef1tn.Value = min(max(x,0),ef1T.Value);
        update1();
    end

    function update1()
        try
            i = find(strcmp(presets1(:,1),dd1Sys.Value));
            kind = presets1{i,2};
            if isempty(kind), kind = 'lti'; end
            ef1P.Enable = onoff(strcmp(kind,'lti'));
            if strcmp(kind,'lti'), P = parseTF(ef1P.Value); else, P = []; end
            sys = @(uf,tq) systemOutput(kind,P,uf,tq);

            % Time grid; tau and t_n are snapped to it so shifts are exact
            N = 2000;
            Tf = ef1T.Value;
            dt = Tf/N;
            t = (0:N)'*dt;
            kTau = round(ef1tau.Value/dt);  tau = kTau*dt;
            kTn  = round(ef1tn.Value/dt);   tn  = kTn*dt;
            al = ef1al.Value;  be = ef1be.Value;
            u1 = makeSignal(ef1u1.Value);
            u2 = makeSignal(ef1u2.Value);

            y1 = sys(u1,t);
            y2 = sys(u2,t);

            % Additivity, homogeneity and their combination (linearity)
            yA  = sys(@(tt) u1(tt) + u2(tt),t);
            k   = al; if k == 1, k = 2; end      % homogeneity needs k ~= 1 to be a test
            yH  = sys(@(tt) k*u1(tt),t);
            yL  = sys(@(tt) al*u1(tt) + be*u2(tt),t);
            yLs = al*y1 + be*y2;
            [okA,eA] = same(yA,y1 + y2);
            [okH,eH] = same(yH,k*y1);
            [okL,eL] = same(yL,yLs);

            % Time invariance: response to u1(t - tau) vs y1(t - tau)
            yS  = sys(@(tt) u1(tt - tau),t);
            y1s = sys(u1,t - tau);
            [okT,eT] = same(yS,y1s);

            % Causality: change the input only for t > t_n; the output for t < t_n must not change
            up = @(tt) u1(tt) + (tt > tn + dt/2);
            yP = sys(up,t);
            before = t < tn - dt/2;
            [okC,eC] = same(yP(before),y1(before));

            % Inputs and outputs
            cla(ax1u); hold(ax1u,'on');
            plot(ax1u,t,u1(t),'--','Color',c1c,'LineWidth',1.2);
            plot(ax1u,t,u2(t),'--','Color',c2c,'LineWidth',1.2);
            plot(ax1u,t,y1,'Color',c1c,'LineWidth',2);
            plot(ax1u,t,y2,'Color',c2c,'LineWidth',2);
            hold(ax1u,'off'); grid(ax1u,'on');
            legend(ax1u,{'u_1(t)','u_2(t)','y_1(t) = p(u_1)','y_2(t) = p(u_2)'},'Location','best');
            title(ax1u,'Inputs and outputs (drag \uparrow\downarrow: \beta)'); xlabel(ax1u,'Time (s)');
            noHit(ax1u);

            cla(ax1L); hold(ax1L,'on');
            plot(ax1L,t,yL,'Color',c3c,'LineWidth',2.5);
            plot(ax1L,t,yLs,'--','Color','r','LineWidth',1.5);
            hold(ax1L,'off'); grid(ax1L,'on');
            legend(ax1L,{sprintf('p(%gu_1 + %gu_2)',al,be),sprintf('%gy_1 + %gy_2',al,be)},'Location','best');
            title(ax1L,sprintf('Linearity  %s   (drag \\uparrow\\downarrow: \\alpha)',mark(okL))); xlabel(ax1L,'Time (s)');
            noHit(ax1L);

            cla(ax1T); hold(ax1T,'on');
            plot(ax1T,t,u1(t - tau),':','Color',cGr,'LineWidth',1.2);
            plot(ax1T,t,yS,'Color',c3c,'LineWidth',2.5);
            plot(ax1T,t,y1s,'--','Color','r','LineWidth',1.5);
            xline(ax1T,tau,'-k',sprintf(' τ = %.3g s (drag)',tau),'LineWidth',1.5, ...
                'LabelOrientation','horizontal','LabelVerticalAlignment','bottom');
            hold(ax1T,'off'); grid(ax1T,'on');
            legend(ax1T,{'u_1(t − τ)','p(u_1(t − τ))','y_1(t − τ)'},'Location','best');
            title(ax1T,sprintf('Time invariance  %s',mark(okT))); xlabel(ax1T,'Time (s)');
            noHit(ax1T);

            cla(ax1C); hold(ax1C,'on');
            yl = [min([y1; yP]) max([y1; yP])]; yl = yl + [-0.05 0.05]*max(diff(yl),1e-6);
            patch(ax1C,[0 tn tn 0],yl([1 1 2 2]),[0.9 0.95 1],'EdgeColor','none');
            plot(ax1C,t,y1,'Color',c1c,'LineWidth',2.5);
            plot(ax1C,t,yP,'--','Color','r','LineWidth',1.5);
            xline(ax1C,tn,'-k',sprintf(' t_n = %.3g s (drag)',tn),'LineWidth',1.5, ...
                'LabelOrientation','horizontal','LabelVerticalAlignment','bottom');
            hold(ax1C,'off'); grid(ax1C,'on'); ylim(ax1C,yl);
            legend(ax1C,{'t ≤ t_n','p(u_1)','p(u_1 + step after t_n)'},'Location','best');
            title(ax1C,sprintf('Causality  %s',mark(okC))); xlabel(ax1C,'Time (s)');
            noHit(ax1C);

            nm = {'additive','homogeneous','linear','time-invariant','causal'};
            ok = [okA okH okL okT okC];
            txt = { ...
                sprintf('%s  Additive:       p(u1+u2) = y1+y2',mark(okA))
                sprintf('     max rel. error %.2g',eA)
                sprintf('%s  Homogeneous:    p(k u1) = k y1, k = %g',mark(okH),k)
                sprintf('     max rel. error %.2g',eH)
                sprintf('%s  Linear:         p(au1+bu2) = ay1+by2',mark(okL))
                sprintf('     a = %g, b = %g, max rel. error %.2g',al,be,eL)
                sprintf('%s  Time-invariant: p(u1(t-tau)) = y1(t-tau)',mark(okT))
                sprintf('     tau = %.3g s, max rel. error %.2g',tau,eT)
                sprintf('%s  Causal: output for t < t_n unchanged',mark(okC))
                sprintf('     t_n = %.3g s, max rel. error %.2g',tn,eC)
                ''};
            if all(ok)
                txt{end+1} = '=> causal LTI system (for these signals)';
            else
                txt{end+1} = ['=> not ' strjoin(nm(~ok),', not ')];
            end
            txt{end+1} = '';
            txt{end+1} = 'A numerical test can only disprove a';
            txt{end+1} = 'property; passing it for some signals';
            txt{end+1} = 'does not prove it for all signals.';
            if strcmp(kind,'sat') && okL
                txt{end+1} = '';
                txt{end+1} = 'Try a larger alpha: saturation only';
                txt{end+1} = 'shows up once |u| exceeds 1.';
            end
            ta1.Value = flatLines(txt);
        catch err
            showError(ta1,err);
        end
    end

%% =====================================================================
%  Tab 2 callbacks
%  =====================================================================
    function loadPreset2()
        i = find(strcmp(presets2(:,1),dd2Preset.Value));
        if isempty(presets2{i,2}), return, end
        ef2b.Value = presets2{i,2};
        ef2a.Value = presets2{i,3};
        pz2.selKind = '';  pz2.selVal = [];
        update2();
    end

    function update2()
        try
            b = trimCoeffs(parseVector(ef2b.Value));
            a = trimCoeffs(parseVector(ef2a.Value));
            if isempty(b) || all(b == 0), error('The output coefficients b cannot all be zero.'); end
            n = numel(b) - 1;  m = numel(a) - 1;

            lbl2ode.Text = ['$' odeSide(b,'y') '=' odeSide(a,'u') '$'];
            lbl2lap.Text = ['$' laplaceSide(b,'Y') '=' laplaceSide(a,'U') '$'];
            lbl2tf.Text  = sprintf('$P(s)=\\frac{Y(s)}{U(s)}=\\frac{%s}{%s}$',polyTex(a),polyTex(b));

            P = tf(fliplr(a),fliplr(b));
            causal = m <= n;
            drawRoots2(P);

            cla(ax2y);
            if causal
                t = timeVector2(ef2T.Value,pole(P));
                A = ef2A.Value;  w = ef2w.Value;
                switch dd2In.Value
                    case 'Unit step',    u = A*ones(size(t)); y = A*step(P,t);    uName = sprintf('u(t) = %g',A);
                    case 'Unit impulse', u = zeros(size(t));  y = A*impulse(P,t); uName = sprintf('u(t) = %g\\delta(t)',A);
                    case 'Unit ramp',    u = A*t;             y = lsim(P,u,t);    uName = sprintf('u(t) = %gt',A);
                    case 'Sinusoid',     u = A*sin(w*t);      y = lsim(P,u,t);    uName = sprintf('u(t) = %g sin(%gt)',A,w);
                end
                hold(ax2y,'on');
                plot(ax2y,t,u,'--','Color',cGr,'LineWidth',1.5);
                plot(ax2y,t,y,'Color',c1c,'LineWidth',2);
                hold(ax2y,'off'); grid(ax2y,'on');
                legend(ax2y,{uName,'y(t)'},'Location','best');
                title(ax2y,'Response with zero initial conditions');
            else
                text(ax2y,0.5,0.5,{'m > n: P(s) is improper,','so the system is not causal'}, ...
                    'Units','normalized','HorizontalAlignment','center','FontSize',14,'Color','r');
                title(ax2y,'');
            end
            xlabel(ax2y,'Time (s)');

            pOL = pole(P);  zOL = zero(P);
            txt = { ...
                sprintf('n = %d (order of the output derivatives)',n)
                sprintf('m = %d (order of the input derivatives)',m)};
            if causal
                txt{end+1} = '=> m <= n: causal (proper P(s))';
            else
                txt{end+1} = '=> m > n: NOT causal (improper P(s))';
            end
            txt = [txt; {''
                sprintf('b = [%s]  (b0 ... bn)',numList(b))
                sprintf('a = [%s]  (a0 ... am)',numList(a))
                ''
                'Poles (roots of b0 + b1 s + ...):'; rootsStr(pOL)
                'Zeros (roots of a0 + a1 s + ...):'; rootsStr(zOL)}];
            if b(1) ~= 0
                txt{end+1} = sprintf('DC gain P(0) = a0/b0 = %.4g',a(1)/b(1));
            end
            ta2.Value = flatLines(txt);
        catch err
            showError(ta2,err);
        end
    end

    function drawRoots2(P)
        % Draggable poles/zeros of P(s); dragging rewrites the ODE coefficients.
        ax = ax2pz;
        [z,p,K] = zpkdata(zpk(P),'v');
        rl = rootList(z,p);
        pz2.roots = rl;  pz2.K = K;
        if drag.active && isequal(drag.ax,ax)
            xl = drag.xl; yl = drag.yl;
        else
            vals = [z; p; 0];
            R = max(1,1.3*max(abs(vals(isfinite(vals)))));
            xl = [-R R]; yl = [-R R];
        end
        cla(ax); hold(ax,'on');
        patch(ax,[0 xl(2) xl(2) 0],yl([1 1 2 2]),[1 0.9 0.9],'EdgeColor','none','HitTest','off');
        xline(ax,0,'k','HitTest','off');
        yline(ax,0,'k','HitTest','off');
        sel = selectedIndex2();
        for j = 1:numel(rl)
            v = rl(j).val;
            if rl(j).pair, xs = [real(v) real(v)]; ys = [imag(v) -imag(v)];
            else, xs = real(v); ys = 0; end
            if rl(j).kind == 'p', mk = 'x'; ms = 14; else, mk = 'o'; ms = 10; end
            col = c2c; lw = 2.5;
            if j == sel, col = cSel; lw = 3.5; end
            plot(ax,xs,ys,mk,'Color',col,'MarkerSize',ms,'LineWidth',lw, ...
                'ButtonDownFcn',@(~,~) rootDown2(j));
        end
        hold(ax,'off'); grid(ax,'on');
        ax.DataAspectRatio = [1 1 1];
        xlim(ax,xl); ylim(ax,yl);
        title(ax,'Poles (x) and zeros (o) of P(s): drag them');
        xlabel(ax,'Real axis'); ylabel(ax,'Imaginary axis');
    end

    function rootDown2(j)
        pz2.selKind = pz2.roots(j).kind;
        pz2.selVal = pz2.roots(j).val;
        pz2.r0 = pz2.roots;
        pz2.K0 = pz2.K;
        startDrag(ax2pz,@(pt,~) moveRoot2(j,pt),@update2);
    end

    function moveRoot2(j,pt)
        rl = pz2.r0;
        tol = 0.02*diff(drag.xl);
        if rl(j).pair
            % Complex pairs stay complex: the conjugate mirrors the mouse
            v = complex(pt(1),max(abs(pt(2)),tol));
        else
            % Real roots slide along the real axis and snap onto the origin
            v = pt(1);
            if abs(v) < tol, v = 0; end
        end
        rl(j).val = v;
        pz2.selVal = v;
        % Keep the low-frequency gain fixed while moving a root
        K = pz2.K0*lowFreqProduct(pz2.r0)/lowFreqProduct(rl);
        [a,b] = rootsToCoeffs(rl,K);
        ef2b.Value = ['[' numList(b) ']'];
        ef2a.Value = ['[' numList(a) ']'];
        dd2Preset.Value = 'Custom';
        update2();
    end

    function j = selectedIndex2()
        j = 0;
        rl = pz2.roots;
        if isempty(pz2.selVal) || isempty(rl), return, end
        idx = find([rl.kind] == pz2.selKind);
        if isempty(idx), return, end
        [~,m] = min(abs([rl(idx).val] - pz2.selVal));
        j = idx(m);
    end

%% =====================================================================
%  Tab 3 callbacks
%  =====================================================================
    function loadPreset3()
        i = find(strcmp(presets3(:,1),dd3Preset.Value));
        if isempty(presets3{i,2}), return, end
        dd3Dir.Value = presets3{i,2};
        ef3Expr.Value = presets3{i,3};
        ef3a.Value = presets3{i,4};
        ef3b.Value = presets3{i,5};
        dd3Prop.Value = presets3{i,6};
        ef3c.Value = presets3{i,7};
        update3(true);
    end

    function setShift3(c)
        ef3c.Value = c;
        update3(false);
    end

    function update3(full)
        % full = false while dragging the time shift: only the plot and the
        % time-shift equation are updated (no symbolic transforms).
        try
            [t,s,a,b] = deal(sym('t'),sym('s'),sym('a'),sym('b'));
            fwd = strcmp(dd3Dir.Value,'f(t) → F(s)');
            if fwd, lbl3Expr.Text = 'f(t) ='; else, lbl3Expr.Text = 'F(s) ='; end
            av = ef3a.Value;  bv = ef3b.Value;
            prop = dd3Prop.Value;
            if strcmp(prop,'Time scaling') && ef3c.Value <= 0, ef3c.Value = 2; end   % a value left from another property
            cv = ef3c.Value;
            names = {'None','',''; 'Time shift','Shift τ (s)','tau'; 'Frequency shift','Shift a','a'; ...
                'Time scaling','Scale a (> 0)','a'; 'Homogeneity','Gain k','k'; ...
                'Time derivative','',''; 'Time integral','',''};
            ip = find(strcmp(names(:,1),prop));
            lbl3c.Text = names{ip,2};
            ef3c.Visible = onoff(~isempty(names{ip,2}));
            lbl3c.Visible = ef3c.Visible;

            % Transform pair (cached, so dragging does not repeat the symbolic work)
            key = sprintf('%d|%s|%.15g|%.15g',fwd,ef3Expr.Value,av,bv);
            if ~strcmp(key,cache3.key)
                e = str2sym(ef3Expr.Value);
                if fwd
                    f = e;  F = simplify(laplace(f,t,s));
                else
                    F = e;  f = ilaplace(F,s,t);     % unsimplified: keeps the sum of table terms
                end
                fN = subs(f,[a b],[av bv]);
                FN = simplify(subs(F,[a b],[av bv]));
                cache3 = struct('key',key,'f',f,'F',F,'fN',fN,'FN',FN, ...
                    'fh',symToFun(fN,t),'hasAB',~isempty(intersect(symvar([f F]),[a b])));
            end
            C = cache3;

            lbl3pair.Text = sprintf('$f(t)=%s\\quad\\Longleftrightarrow\\quad F(s)=%s$',latex(C.f),latex(C.F));
            if C.hasAB
                lbl3num.Text = sprintf('$a=%g,\\ b=%g:\\quad f(t)=%s\\quad\\Longleftrightarrow\\quad F(s)=%s$', ...
                    av,bv,latex(C.fN),latex(C.FN));
            else
                lbl3num.Text = '';
            end

            % Property of Table 2.1: g(t) and the rule for G(s)
            T = ef3T.Value;
            tt = linspace(-1,T,1500)';
            fv = C.fh(tt);
            if ~fwd, fv(tt < 0) = 0; end       % ilaplace gives f(t) for t >= 0
            gv = []; ruleTex = ''; check = '';
            if ~strcmp(prop,'None')
                [g,rule,ruleTex,gv] = applyProperty(prop,C.fN,C.FN,cv,tt,full);
                if full
                    G = simplify(laplace(g,t,s));
                    if isAlways(simplify(G - rule) == 0,'Unknown','false')
                        check = 'L{g(t)} computed directly agrees with the rule ✔';
                    else
                        check = 'L{g(t)} computed directly differs from the rule ✘';
                    end
                    ruleTex = sprintf('%s=%s',ruleTex,latex(simplify(rule)));
                end
                lbl3prop.Text = ['$' ruleTex '$'];
            else
                lbl3prop.Text = '';
            end

            % Plot f(t) (and g(t)); the part for t < 0 is ignored by the one-sided transform
            cla(ax3); hold(ax3,'on');
            neg = tt < 0;
            plot(ax3,tt(~neg),fv(~neg),'Color',c1c,'LineWidth',2.5);
            leg = {'f(t), t ≥ 0'};
            if fwd && any(abs(fv(neg)) > 0)
                plot(ax3,tt(neg),fv(neg),'--','Color',cGr,'LineWidth',1.5);
                leg{end+1} = 'f(t), t < 0 (ignored)';
            end
            if ~isempty(gv)
                hg = plot(ax3,tt,gv,'Color',c2c,'LineWidth',2.5);
                leg{end+1} = sprintf('g(t): %s',lower(prop));
                if strcmp(prop,'Time shift')
                    leg{end} = 'g(t) = f(t − τ)u(t − τ) (drag)';
                    hg.ButtonDownFcn = @(~,~) startDrag(ax3,@(pt,p0) setShift3(cv + pt(1) - p0(1)), ...
                        @() update3(true));
                end
            end
            xline(ax3,0,':k');
            hold(ax3,'off'); grid(ax3,'on');
            legend(ax3,leg,'Location','best');
            title(ax3,'Time-domain signals'); xlabel(ax3,'Time t (s)');
            noHit(ax3);
            if ~isempty(gv), hg.HitTest = 'on'; end

            if full
                txt = { ...
                    ['f(t) = ' char(C.f)]
                    ['F(s) = ' char(C.F)]};
                if C.hasAB
                    txt = [txt; {''; sprintf('With a = %g, b = %g:',av,bv); ...
                        ['f(t) = ' char(C.fN)]; ['F(s) = ' char(C.FN)]}];
                end
                if ~strcmp(prop,'None')
                    txt = [txt; {''; [prop ':']; ['g(t) = ' char(simplify(g))]; ...
                        ['G(s) = ' char(simplify(rule))]; check}];
                end
                ta3.Value = flatLines(txt);
            end
        catch err
            showError(ta3,err);
        end
    end

%% =====================================================================
%  Tab 4 callbacks
%  =====================================================================
    function loadPreset4()
        i = find(strcmp(presets4(:,1),dd4Preset.Value));
        if isempty(presets4{i,2}), return, end
        ef4u.Value = presets4{i,2};
        ef4y.Value = presets4{i,3};
        update4();
    end

    function drawPZ4(P,U)
        % Poles and zeros of the identified P(s), draggable when it is rational.
        cla(ax4p);  hold(ax4p,'on');  grid(ax4p,'on');  box(ax4p,'on');
        title(ax4p,'Poles (x) and zeros (o) of P(s): drag');
        xlabel(ax4p,'Real axis');  ylabel(ax4p,'Imaginary axis');
        try
            [n,d] = numden(P);
            Pz = zpk(tf(sym2poly(n),sym2poly(d)));
        catch
            text(ax4p,0.5,0.5,'P(s) is not rational','Units','normalized','HorizontalAlignment','center');
            hold(ax4p,'off');  return
        end
        z = Pz.Z{1};  p = Pz.P{1};  k = Pz.K;
        Rm = max([1; abs([z; p])])*1.4;
        patch(ax4p,[0 Rm Rm 0],[-Rm -Rm Rm Rm],[1 0.93 0.93],'EdgeColor','none','PickableParts','none');
        xline(ax4p,0,'k');  yline(ax4p,0,'k');
        for kind = 'zp'
            if kind == 'z', r = z; mk = 'o'; col = c1c; else, r = p; mk = 'x'; col = c2c; end
            for q = 1:numel(r)
                if imag(r(q)) < -1e-9, continue, end
                h = plot(ax4p,real(r(q))*[1 1],imag(r(q))*[1 -1],mk,'Color',col,'MarkerSize',13,'LineWidth',2.5);
                h.ButtonDownFcn = @(~,~) startDrag(ax4p,@(pt,~) moveRoot4(z,p,k,U,kind,q,pt),@update4);
            end
        end
        hold(ax4p,'off');
        ax4p.DataAspectRatio = [1 1 1];
        xlim(ax4p,[-Rm Rm]);  ylim(ax4p,[-Rm Rm]);
    end

    function moveRoot4(z,p,k,U,kind,q,pt)
        % Move one pole/zero (a complex pair together; real roots stay real and snap to
        % the origin) and regenerate the output y(t) = L^-1{P(s)U(s)}.
        tol = 0.02*diff(drag.xl);
        nz = @(v) v(abs(v) > 1e-12);
        Kb = k*prod(-nz(z))/prod(-nz(p));      % DC gain (without integrators) is kept
        if kind == 'z', r = z; else, r = p; end
        x = pt(1);  if abs(x) < tol, x = 0; end
        if abs(imag(r(q))) > 1e-9
            y = max(abs(pt(2)),tol);
            c = find(abs(r - conj(r(q))) < 1e-9 & (1:numel(r))' ~= q,1);
            r(q) = complex(x,y);  r(c) = complex(x,-y);
        else
            r(q) = x;
        end
        if kind == 'z', z = r; else, p = r; end
        k = real(Kb*prod(-nz(p))/prod(-nz(z)));
        sv = sym('s');
        Ps = poly2sym(sym(round(k*real(poly(z)),6)),sv)/poly2sym(sym(round(real(poly(p)),6)),sv);
        y = ilaplace(Ps*U,sv,sym('t'));
        ef4y.Value = char(vpa(simplify(y),5));
        dd4Preset.Value = 'Custom';
        update4();
    end

    function update4()
        try
            [t,s] = deal(sym('t'),sym('s'));
            u = str2sym(ef4u.Value);
            y = str2sym(ef4y.Value);
            U = simplify(laplace(u,t,s));
            Y = simplify(laplace(y,t,s));
            P = simplify(Y/U);
            lbl4u.Text = sprintf('$u(t)=%s\\quad\\Longrightarrow\\quad U(s)=\\mathcal{L}\\{u(t)\\}=%s$',latex(u),latex(U));
            lbl4y.Text = sprintf('$y(t)=%s\\quad\\Longrightarrow\\quad Y(s)=\\mathcal{L}\\{y(t)\\}=%s$',latex(y),latex(Y));
            lbl4P.Text = sprintf('$P(s)=\\frac{Y(s)}{U(s)}=\\frac{%s}{%s}=%s$',latex(Y),latex(U),latex(P));

            % Check: simulate P(s) with u(t) and compare with the measured y(t)
            T = ef4T.Value;
            tt = linspace(0,T,1500)';
            uv = symToFun(u,t);  yv = symToFun(y,t);
            uData = uv(tt);  yData = yv(tt);
            txt = {['U(s) = ' char(U)]; ['Y(s) = ' char(Y)]; ['P(s) = Y/U = ' char(P)]; ''};
            cla(ax4); hold(ax4,'on');
            plot(ax4,tt,uData,'--','Color',cGr,'LineWidth',1.5);
            plot(ax4,tt,yData,'o','Color',c1c,'MarkerIndices',1:40:numel(tt),'MarkerSize',6,'LineWidth',1.2);
            leg = {'u(t)','y(t) (data)'};
            [num,den] = numden(P);
            try
                Ptf = tf(sym2poly(num),sym2poly(den));
                if numel(sym2poly(num)) <= numel(sym2poly(den))
                    ySim = lsim(Ptf,uData,tt);
                    plot(ax4,tt,ySim,'Color',c2c,'LineWidth',2);
                    leg{end+1} = 'P(s) simulated with u(t)';
                    err = max(abs(ySim - yData))/max(max(abs(yData)),1e-9);
                    txt{end+1} = sprintf('Simulated vs data: max rel. error %.2g',err);
                    if err < 1e-3
                        txt{end+1} = '=> P(s) reproduces the data ✔';
                    end
                else
                    txt{end+1} = 'P(s) is improper (not causal): not simulated.';
                end
            catch
                txt{end+1} = 'P(s) is not a rational function of s:';
                txt{end+1} = 'not simulated.';
            end
            hold(ax4,'off'); grid(ax4,'on');
            legend(ax4,leg,'Location','best');
            title(ax4,'Input, measured output and model response'); xlabel(ax4,'Time (s)');
            drawPZ4(P,U);
            ta4.Value = flatLines(txt);
        catch err
            showError(ta4,err);
        end
    end
end

%% =========================================================================
%  Helper functions
%  =========================================================================

function y = systemOutput(kind,P,uf,tq)
% Output of the selected system for input function uf on the grid tq (which
% may start before t = 0; inputs are zero for t < 0 and LTI systems start at rest).
tq = tq(:);
switch kind
    case 'lti'
        y = zeros(size(tq));
        idx = tq >= -1e-9*max(1,abs(tq(end)));
        tp = tq(idx);
        if numel(tp) > 1
            y(idx) = lsim(P,uf(tp),tp - tp(1));
        end
    case 'delay',   y = uf(tq - 0.5);
    case 'advance', y = uf(tq + 0.5);
    case 'square',  y = uf(tq).^2;
    case 'offset',  y = uf(tq) + 1;
    case 'sat',     y = min(max(uf(tq),-1),1);
    case 'tv',      y = tq.*uf(tq);
end
end

function uf = makeSignal(str)
% Signal from a MATLAB expression in t, zero for t < 0.
str = strtrim(str);
if isempty(str), error('Input signal is empty.'); end
str = regexprep(str,'(?<!\.)([\*\/\^])','.$1');   % element-wise operators
f = str2func(['@(t) ' str]);
uf = @(t) (t >= 0).*(f(t) + 0*t);
end

function [ok,err] = same(a,b)
% Two signals agree to within numerical precision.
a = a(:); b = b(:);
if isempty(a), ok = true; err = 0; return, end
err = max(abs(a - b))/max([max(abs(a)) max(abs(b)) 1e-9]);
ok = err < 1e-6;
end

function s = mark(ok)
if ok, s = '✔'; else, s = '✘'; end
end

function sys = parseTF(str)
% Evaluate a MATLAB expression in s as a transfer function.
str = strtrim(str);
if isempty(str), error('Transfer function is empty.'); end
f = str2func(['@(s) ' str]);
sys = tf(f(tf('s')));
end

function v = parseVector(str)
v = str2num(str); %#ok<ST2NM>
if isempty(v) || ~isnumeric(v) || ~isvector(v)
    error('Enter the coefficients as a vector, e.g. [2 1].');
end
v = real(v(:)');
end

function c = trimCoeffs(c)
% Drop zero highest-order coefficients.
k = find(c ~= 0,1,'last');
if isempty(k), c = 0; else, c = c(1:k); end
end

function str = odeSide(c,v)
% One side of the differential equation, e.g. 2y(t)+\dot{y}(t), from c = [c0 c1 ...].
terms = cell(1,0);
for i = 0:numel(c)-1
    switch i
        case 0, d = [v '(t)'];
        case 1, d = ['\dot{' v '}(t)'];
        case 2, d = ['\ddot{' v '}(t)'];
        otherwise, d = sprintf('\\frac{d^{%d}%s(t)}{dt^{%d}}',i,v,i);
    end
    terms{end+1} = {c(i+1),d}; %#ok<AGROW>
end
str = joinTerms(terms);
end

function str = laplaceSide(c,V)
% One side of the Laplace-transformed equation, e.g. 2Y(s)+sY(s).
terms = cell(1,0);
for i = 0:numel(c)-1
    switch i
        case 0, d = [V '(s)'];
        case 1, d = ['s' V '(s)'];
        otherwise, d = sprintf('s^{%d}%s(s)',i,V);
    end
    terms{end+1} = {c(i+1),d}; %#ok<AGROW>
end
str = joinTerms(terms);
end

function str = polyTex(c)
% Polynomial c0 + c1 s + c2 s^2 + ... in LaTeX (ascending order, as in the notes).
terms = cell(1,0);
for i = 0:numel(c)-1
    switch i
        case 0, d = '';
        case 1, d = 's';
        otherwise, d = sprintf('s^{%d}',i);
    end
    terms{end+1} = {c(i+1),d}; %#ok<AGROW>
end
str = joinTerms(terms);
end

function str = joinTerms(terms)
% Join {coefficient, symbol} pairs into a signed sum, skipping zero terms.
str = '';
for k = 1:numel(terms)
    cf = terms{k}{1};  d = terms{k}{2};
    if cf == 0, continue, end
    mag = abs(cf);
    if isempty(d)
        term = sprintf('%.4g',mag);
    elseif abs(mag - 1) < 1e-12
        term = d;
    else
        term = sprintf('%.4g%s',mag,d);
    end
    if isempty(str)
        if cf < 0, str = ['-' term]; else, str = term; end
    elseif cf < 0
        str = [str '-' term]; %#ok<AGROW>
    else
        str = [str '+' term]; %#ok<AGROW>
    end
end
if isempty(str), str = '0'; end
end

function s = numList(v)
s = strjoin(arrayfun(@(x) sprintf('%.4g',x),v,'UniformOutput',false),' ');
end

function t = timeVector2(Tf,p)
% Simulation time: user value, or ~8 time constants of the slowest pole.
if Tf <= 0
    sig = -real(p);
    if isempty(sig)
        Tf = 5;
    elseif any(sig <= 1e-9)
        Tf = 10;
    else
        Tf = min(max(8/min(sig),1),200);
    end
end
t = linspace(0,Tf,2000)';
end

function str = rootsStr(p)
if isempty(p)
    str = {'  (none)'};
    return
end
str = cell(numel(p),1);
for i = 1:numel(p)
    if abs(imag(p(i))) < 1e-9
        str{i} = sprintf('  %.4g',real(p(i)));
    else
        str{i} = sprintf('  %.4g %+.4gj',real(p(i)),imag(p(i)));
    end
end
end

function [g,rule,ruleTex,gv] = applyProperty(prop,f,F,c,tt,full)
% Table 2.1: g(t) obtained from f(t) by the property, the rule for G(s) in
% terms of F(s), the rule in LaTeX and g evaluated on tt.
[t,s] = deal(sym('t'),sym('s'));
g = sym([]);  rule = sym([]);
fh = symToFun(f,t);
switch prop
    case 'Time shift'
        ruleTex = sprintf('g(t)=f(t-%g)u(t-%g)\\ \\Longleftrightarrow\\ G(s)=e^{-%gs}F(s)',c,c,c);
        gv = fh(tt - c).*(tt >= c);
        if full
            g = subs(f,t,t - c);
            if ~has(f,heaviside(t)), g = g*heaviside(t - c); end
            rule = exp(-c*s)*F;
        end
    case 'Frequency shift'
        ruleTex = sprintf('g(t)=e^{%gt}f(t)\\ \\Longleftrightarrow\\ G(s)=F(s-(%g))',c,c);
        gv = exp(c*tt).*fh(tt).*(tt >= 0);
        g = exp(c*t)*f;  rule = subs(F,s,s - c);
    case 'Time scaling'
        if c <= 0, error('The time-scaling factor must be positive.'); end
        ruleTex = sprintf('g(t)=f(%gt)\\ \\Longleftrightarrow\\ G(s)=\\frac{1}{%g}F\\left(\\frac{s}{%g}\\right)',c,c,c);
        gv = fh(c*tt).*(tt >= 0);
        g = subs(f,t,c*t);  rule = subs(F,s,s/c)/c;
    case 'Homogeneity'
        ruleTex = sprintf('g(t)=%gf(t)\\ \\Longleftrightarrow\\ G(s)=%gF(s)',c,c);
        gv = c*fh(tt).*(tt >= 0);
        g = c*f;  rule = c*F;
    case 'Time derivative'
        f0 = limit(f,t,0,'right');
        ruleTex = sprintf('g(t)=\\dot{f}(t)\\ \\Longleftrightarrow\\ G(s)=sF(s)-f(0)=sF(s)-(%s)',latex(f0));
        g = diff(f,t);  rule = s*F - f0;
        gv = symToFun(g,t);  gv = gv(tt).*(tt >= 0);
    case 'Time integral'
        tau = sym('tau');
        ruleTex = 'g(t)=\int_0^t f(\tau)d\tau\ \Longleftrightarrow\ G(s)=\frac{F(s)}{s}';
        g = int(subs(f,t,tau),tau,0,t);  rule = F/s;
        gv = symToFun(g,t);  gv = gv(tt).*(tt >= 0);
end
end

function fh = symToFun(f,t)
% Numeric function of t from a symbolic expression; impulses are not drawn.
try
    f = mapSymType(f,'dirac',@(x) sym(0));
catch
end
h = matlabFunction(f,'Vars',t);
fh = @(tt) real(double(h(tt)) + 0*tt);
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

function g = lowFreqProduct(rl)
% prod(-z)/prod(-p) over roots away from the origin, so that the
% low-frequency gain lim s^k P(s) equals K*g for zpk gain K.
g = 1;
for j = 1:numel(rl)
    v = rl(j).val;
    if abs(v) < 1e-12, continue, end
    if rl(j).pair, f = abs(v)^2; else, f = -real(v); end
    if rl(j).kind == 'z', g = g*f; else, g = g/f; end
end
end

function [a,b] = rootsToCoeffs(rl,K)
% ODE coefficients (ascending, b_n = 1) of K*prod(s-z)/prod(s-p).
z = []; p = [];
for j = 1:numel(rl)
    v = rl(j).val;
    if rl(j).pair, vv = [v; conj(v)]; else, vv = v; end
    if rl(j).kind == 'z', z = [z; vv]; else, p = [p; vv]; end %#ok<AGROW>
end
a = fliplr(real(K*poly(z)));
b = fliplr(real(poly(p)));
end

function noHit(ax)
% Let clicks on the plotted objects pass through to the axes.
set(ax.Children,'HitTest','off');
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
% Editing an expression by hand switches the example selector to Custom.
dd.Value = 'Custom';
updateFcn();
end

function showError(ta,err)
ta.Value = {'Error:'; err.message; ''; ...
    'Signals: MATLAB expressions in t, e.g. sin(10*t) or 5*t.'; ...
    'Transforms: expressions in s, e.g. 1/(s/10+1).'};
end
