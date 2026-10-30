function Chapter7_FrequencyResponseTechniquesApp
%CHAPTER7_FREQUENCYRESPONSETECHNIQUESAPP Interactive GUI for MEC3079S Chapter 7 — Frequency response techniques.
%
%   Run Chapter7_FrequencyResponseTechniquesApp to open the app. The tabs follow the chapter:
%     1. Sinusoidal response   (7.2, 7.4): a sinusoid into P(s); after the
%        natural response decays, y(t) = M_P M_U sin(ωt + φ_P + φ_U).
%     2. Nyquist, Bode, log-polar (7.3): three views of the same frequency
%        response, with a shared frequency cursor, gain k and time delay τ.
%     3. Characteristics       (7.5): DC gain, high-frequency gain, number of
%        integrators and relative degree, read from the frequency response.
%     4. Filters               (7.6): first/second-order low-pass, high-pass
%        and band-pass filters: bandwidth, peak response and roll-off.
%
%   Interaction: drag the frequency cursor (filled marker) on any Bode,
%   Nyquist or log-polar plot; drag a curve on tab 2 to change the gain k;
%   drag the poles (x) and zeros (o) on tab 3; drag the bandwidth, peak and
%   test-frequency markers on tab 4.
%
%   Transfer functions are entered as MATLAB expressions in s, for example
%   1/(s+10), (s+5)/(s^2*(1+s/10)) or exp(-0.07*s)/(1+s).
%
%   Requires the Control System Toolbox.

cOrange = [0.85 0.33 0.10];
cBlue   = [0.00 0.45 0.74];
cPurple = [0.49 0.18 0.56];
cGreen  = [0.47 0.67 0.19];
cRed    = [0.85 0.10 0.10];
cGrey   = [0.60 0.60 0.60];
cSel    = [0.10 0.60 0.10];
addItems = {'Add pole/zero…','Real pole','Complex pole pair','Real zero','Complex zero pair'};

fig = uifigure('Name','MEC3079S Chapter 7 — Frequency response techniques', ...
    'Position',[50 40 1340 860]);
mainGrid = uigridlayout(fig,[1 1],'Padding',[0 0 0 0]);
tg = uitabgroup(mainGrid);

% Drag state shared by all interactive plots
drag = struct('active',false,'ax',[],'move',[],'done',[],'p0',[0 0], ...
    'last',[],'xl',[],'yl',[],'t',tic);
fig.WindowButtonMotionFcn = @(~,~) onMotion();
fig.WindowButtonUpFcn = @(~,~) onRelease();

%% =====================================================================
%  Tab 1: Sinusoidal response
%  =====================================================================
t1 = uitab(tg,'Title','Sinusoidal response');
g1 = uigridlayout(t1,[1 2],'ColumnWidth',{340,'1x'});

c1 = uigridlayout(g1,[10 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{112,22,22,22,22,22,22,22,'1x',22});
at(uilabel(c1,'Text',['A sinusoid u(t) = M_U sin(ωt + φ_U) into a stable P(s): once the natural ' ...
    'response has decayed, y(t) = M_P M_U sin(ωt + φ_P + φ_U) with M_P = |P(jω)| and ' ...
    'φ_P = ∠P(jω). Drag the frequency cursor on the Bode or Nyquist plot.'],'FontWeight','bold','WordWrap','on'),1,[1 2]);
% name, P(s), omega, M_U, phi_U (deg)
presets1 = { ...
    '7.2.5: P = 1/(s+10), u = sin(2t)',           '1/(s+10)',              2,    1, 0
    '7.4: P = 1/(s²+s+1), ω = 0.99',              '1/(s^2+s+1)',           0.99, 1, 0
    '7.4: P = 1/(s²+s+1), ω = 3',                 '1/(s^2+s+1)',           3,    1, 0
    '7.2.4: P = e^(−0.07s)/(1+s), ω = 5',         'exp(-0.07*s)/(1+s)',    5,    1, 0
    'Ex 1: P = 5/s (integrator), ω = 2',          '5/s',                   2,    1, 0
    '7.2.2: u = 2 sin(ωt + 30°), P = 1/(s+1)',    '1/(s+1)',               1,    2, 30
    'Custom', '', [], [], []};
at(uilabel(c1,'Text','Example'),2,1);
dd1 = at(uidropdown(c1,'Items',presets1(:,1)','Value',presets1{1,1}),2,2);
at(uilabel(c1,'Text','P(s)'),3,1);
ef1 = at(uieditfield(c1,'text','Value',presets1{1,2}),3,2);
at(uilabel(c1,'Text','Frequency ω (rad/s)'),4,1);
ef1w = at(uieditfield(c1,'numeric','Value',2,'Limits',[1e-6 Inf],'ValueDisplayFormat','%.4g'),4,2);
at(uilabel(c1,'Text','Amplitude M_U'),5,1);
ef1M = at(uieditfield(c1,'numeric','Value',1,'ValueDisplayFormat','%.4g'),5,2);
at(uilabel(c1,'Text','Phase φ_U (deg)'),6,1);
ef1ph = at(uieditfield(c1,'numeric','Value',0,'ValueDisplayFormat','%.4g'),6,2);
cb1T = at(uicheckbox(c1,'Text','Show the transient (natural response)','Value',true),7,[1 2]);
at(uilabel(c1,'Text','Results','FontWeight','bold'),8,[1 2]);
ta1 = at(uitextarea(c1,'Editable','off','FontName','Monospaced'),9,[1 2]);
btn1 = at(uibutton(c1,'Text','Update'),10,[1 2]);

r1 = uigridlayout(g1,[4 3],'RowHeight',{'fit','fit','1.1x','1x'},'ColumnWidth',{'1x','1x','1x'});
lbl1P = at(uilabel(r1,'Text','','Interpreter','latex','FontSize',18),1,[1 3]);
lbl1y = at(uilabel(r1,'Text','','Interpreter','latex','FontSize',18),2,[1 3]);
ax1t = at(uiaxes(r1),3,[1 3]);
ax1m = at(uiaxes(r1),4,1);
ax1p = at(uiaxes(r1),4,2);
ax1n = at(uiaxes(r1),4,3);
[ax1t.Interactions, ax1m.Interactions, ax1p.Interactions, ax1n.Interactions] = deal([]);

dd1.ValueChangedFcn = @(~,~) loadPreset1();
[ef1.ValueChangedFcn, ef1w.ValueChangedFcn, ef1M.ValueChangedFcn, ef1ph.ValueChangedFcn] = ...
    deal(@(~,~) markCustom(dd1,@update1));
cb1T.ValueChangedFcn = @(~,~) update1();
btn1.ButtonPushedFcn = @(~,~) update1();

%% =====================================================================
%  Tab 2: Nyquist, Bode and log-polar
%  =====================================================================
t2 = uitab(tg,'Title','Nyquist, Bode, log-polar');
g2 = uigridlayout(t2,[1 2],'ColumnWidth',{340,'1x'});

c2 = uigridlayout(g2,[10 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{112,22,22,22,22,22,22,22,'1x',22});
at(uilabel(c2,'Text',['The same L(jω) = a + jb = |L|e^(j∠L) in three views: Nyquist (a vs b), ' ...
    'Bode (|L|_dB and ∠L vs log ω) and log-polar (|L|_dB vs ∠L). A gain k shifts the Bode ' ...
    'magnitude and log-polar curves by 20log₁₀|k| dB; a delay only adds phase lag ωτ. Drag the ' ...
    'cursor (ω) or a curve (k).'],'FontWeight','bold','WordWrap','on'),1,[1 2]);
% name, L(s), k, tau, omega
presets2 = { ...
    '7.3.1: L = 1/(1+s)',                          '1/(1+s)',                     1,   0,    1
    '7.3.2: L = 5(s+10)/(s(1+s)²), k = 1.5',       '5*(s+10)/(s*(1+s)^2)',        1.5, 0,    1
    '7.3.3: L = 5(s+10)/(s(1+s)²), k = 2',         '5*(s+10)/(s*(1+s)^2)',        2,   0,    1
    '7.3: P = (s+3)(s+5)/(s(s+2)(s+4))',           '(s+3)*(s+5)/(s*(s+2)*(s+4))', 1,   0,    1
    '7.2.4: 1/(1+s) with delay τ = 0.07',          '1/(1+s)',                     1,   0.07, 5
    '7.6.2: 1/(s²+0.8s+1)',                        '1/(s^2+0.8*s+1)',             1,   0,    1
    'Custom', '', [], [], []};
at(uilabel(c2,'Text','Example'),2,1);
dd2 = at(uidropdown(c2,'Items',presets2(:,1)','Value',presets2{1,1}),2,2);
at(uilabel(c2,'Text','L(s)'),3,1);
ef2 = at(uieditfield(c2,'text','Value',presets2{1,2}),3,2);
at(uilabel(c2,'Text','Gain k'),4,1);
ef2k = at(uieditfield(c2,'numeric','Value',1,'ValueDisplayFormat','%.4g'),4,2);
at(uilabel(c2,'Text','Delay τ (s)'),5,1);
ef2tau = at(uieditfield(c2,'numeric','Value',0,'Limits',[0 Inf],'ValueDisplayFormat','%.4g'),5,2);
at(uilabel(c2,'Text','Cursor ω (rad/s)'),6,1);
ef2w = at(uieditfield(c2,'numeric','Value',1,'Limits',[1e-9 Inf],'ValueDisplayFormat','%.4g'),6,2);
cb2O = at(uicheckbox(c2,'Text','Also show L(s) without k and τ','Value',true),7,[1 2]);
at(uilabel(c2,'Text','Results','FontWeight','bold'),8,[1 2]);
ta2 = at(uitextarea(c2,'Editable','off','FontName','Monospaced'),9,[1 2]);
btn2 = at(uibutton(c2,'Text','Update'),10,[1 2]);

r2 = uigridlayout(g2,[3 3],'RowHeight',{'fit','1x','1x'},'ColumnWidth',{'1x','1x','1x'});
lbl2 = at(uilabel(r2,'Text','','Interpreter','latex','FontSize',18),1,[1 3]);
ax2n = at(uiaxes(r2),[2 3],1);
ax2m = at(uiaxes(r2),2,2);
ax2p = at(uiaxes(r2),3,2);
ax2c = at(uiaxes(r2),[2 3],3);
[ax2n.Interactions, ax2m.Interactions, ax2p.Interactions, ax2c.Interactions] = deal([]);

dd2.ValueChangedFcn = @(~,~) loadPreset2();
[ef2.ValueChangedFcn, ef2k.ValueChangedFcn, ef2tau.ValueChangedFcn] = deal(@(~,~) markCustom(dd2,@update2));
[ef2w.ValueChangedFcn, cb2O.ValueChangedFcn] = deal(@(~,~) update2());
btn2.ButtonPushedFcn = @(~,~) update2();

%% =====================================================================
%  Tab 3: System characteristics from the frequency response
%  =====================================================================
t3 = uitab(tg,'Title','Characteristics');
g3 = uigridlayout(t3,[1 2],'ColumnWidth',{340,'1x'});

c3 = uigridlayout(g3,[9 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{112,22,22,22,22,22,'1x',22,0});
at(uilabel(c3,'Text',['DC gain P(0) → y∞ = G_dc β; high-frequency gain P(∞) → y(0⁺) = G_hf β. ' ...
    'With poles/zeros in the OLHP (and A_p > 0), the phase tends to −90k° at low frequency ' ...
    '(k integrators) and to −90(n−m)° at high frequency (relative degree). Drag the poles and ' ...
    'zeros, e.g. a zero into the ORHP, to see when the rules fail.'],'FontWeight','bold','WordWrap','on'),1,[1 2]);
presets3 = { ...
    '7.5.1: P = (s+10)/(s²+5s+1)',                '(s+10)/(s^2+5*s+1)',          1
    '7.5.2: P = (s+10)/(2s+5), β = 8',            '(s+10)/(2*s+5)',              8
    '7.5.3/7.5.4: P = (s+5)/(s²(1+s/10))',        '(s+5)/(s^2*(1+s/10))',        1
    '7.3: P = (s+3)(s+5)/(s(s+2)(s+4))',          '(s+3)*(s+5)/(s*(s+2)*(s+4))', 1
    'Zero at the origin: 10s/(s+10)²',            '10*s/(s+10)^2',               1
    'ORHP zero: (5−s)/((s+1)(s+2))',              '(5-s)/((s+1)*(s+2))',         1
    'Custom', '', []};
at(uilabel(c3,'Text','Example'),2,1);
dd3 = at(uidropdown(c3,'Items',presets3(:,1)','Value',presets3{1,1}),2,2);
at(uilabel(c3,'Text','P(s)'),3,1);
ef3 = at(uieditfield(c3,'text','Value',presets3{1,2}),3,2);
at(uilabel(c3,'Text','Step size β'),4,1);
ef3b = at(uieditfield(c3,'numeric','Value',1,'ValueDisplayFormat','%.4g'),4,2);
g3r = at(uigridlayout(c3,[1 2],'Padding',[0 0 0 0]),5,[1 2]);
dd3Add = uidropdown(g3r,'Items',addItems);
btn3Del = uibutton(g3r,'Text','Delete selected');
at(uilabel(c3,'Text','Results','FontWeight','bold'),6,[1 2]);
ta3 = at(uitextarea(c3,'Editable','off','FontName','Monospaced'),7,[1 2]);
btn3 = at(uibutton(c3,'Text','Update'),8,[1 2]);
sel3 = 0;      % selected pole/zero entry (0 = none)

r3 = uigridlayout(g3,[4 2],'RowHeight',{'fit','fit','1x','1x'},'ColumnWidth',{'1.2x','1x'});
lbl3a = at(uilabel(r3,'Text','','Interpreter','latex','FontSize',18),1,[1 2]);
lbl3b = at(uilabel(r3,'Text','','Interpreter','latex','FontSize',18),2,[1 2]);
ax3m = at(uiaxes(r3),3,1);
ax3p = at(uiaxes(r3),4,1);
ax3y = at(uiaxes(r3),3,2);
ax3s = at(uiaxes(r3),4,2);
[ax3m.Interactions, ax3p.Interactions, ax3y.Interactions, ax3s.Interactions] = deal([]);

dd3.ValueChangedFcn = @(~,~) loadPreset3();
[ef3.ValueChangedFcn, ef3b.ValueChangedFcn] = deal(@(~,~) markCustom(dd3,@update3));
dd3Add.ValueChangedFcn = @(~,~) addRoot3();
btn3Del.ButtonPushedFcn = @(~,~) deleteRoot3();
btn3.ButtonPushedFcn = @(~,~) update3();

%% =====================================================================
%  Tab 4: Common filters
%  =====================================================================
t4 = uitab(tg,'Title','Filters');
g4 = uigridlayout(t4,[1 2],'ColumnWidth',{340,'1x'});

c4 = uigridlayout(g4,[12 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{112,22,22,22,22,22,22,22,22,22,'1x',22});
at(uilabel(c4,'Text',['Low-pass filters pass ω below the bandwidth ω₀ (−3 dB point) and attenuate ' ...
    'above it; high-pass filters do the opposite; the band-pass filter peaks at ωₙ. Drag the ' ...
    'bandwidth (◆) or peak (●) markers to change ω₀/ωₙ and ζ, and the test-frequency markers (■) ' ...
    'to change the test sinusoids.'],'FontWeight','bold','WordWrap','on'),1,[1 2]);
types4 = {'1st-order low-pass','2nd-order low-pass','1st-order high-pass','2nd-order high-pass','2nd-order band-pass'};
% name, type, gain, w0 (or wn), zeta, test1 (x w0), test2 (x w0)
presets4 = { ...
    '7.6.1: low-pass, A_s = 1.4, ω₀ = 5',        1, 1.4, 5,  0.7,    0.3, 5
    '7.6.2: low-pass, ζ = 0.4, ωₙ = 1',           2, 1,   1,  0.4,    0.3, 5
    '7.6.2: low-pass, ζ = 0.2 (resonant)',        2, 1,   1,  0.2,    1,   5
    '7.6.3: high-pass, ω₀ = 1',                   3, 1,   1,  0.7,    0.3, 5
    '7.6.4: high-pass, ζ = 0.5, ωₙ = 1',          4, 1,   1,  0.5,    0.3, 5
    '7.6.5: band-pass, k = 2, ζ = 0.7071, ωₙ = 1', 5, 2,   1,  0.7071, 0.1, 1
    'Custom', [], [], [], [], [], []};
at(uilabel(c4,'Text','Example'),2,1);
dd4 = at(uidropdown(c4,'Items',presets4(:,1)','Value',presets4{1,1}),2,2);
at(uilabel(c4,'Text','Filter'),3,1);
dd4T = at(uidropdown(c4,'Items',types4),3,2);
lbl4k = at(uilabel(c4,'Text','Gain'),4,1);
ef4k = at(uieditfield(c4,'numeric','Value',1,'ValueDisplayFormat','%.4g'),4,2);
lbl4w = at(uilabel(c4,'Text','ω₀ (rad/s)'),5,1);
ef4w = at(uieditfield(c4,'numeric','Value',1,'Limits',[1e-6 Inf],'ValueDisplayFormat','%.4g'),5,2);
lbl4z = at(uilabel(c4,'Text','Damping ratio ζ'),6,1);
ef4z = at(uieditfield(c4,'numeric','Value',0.5,'Limits',[0.01 5],'ValueDisplayFormat','%.4g'),6,2);
at(uilabel(c4,'Text','Test ω₁ (rad/s)'),7,1);
ef4t1 = at(uieditfield(c4,'numeric','Value',1.5,'Limits',[1e-6 Inf],'ValueDisplayFormat','%.4g'),7,2);
at(uilabel(c4,'Text','Test ω₂ (rad/s)'),8,1);
ef4t2 = at(uieditfield(c4,'numeric','Value',25,'Limits',[1e-6 Inf],'ValueDisplayFormat','%.4g'),8,2);
cb4F = at(uicheckbox(c4,'Text','Compare ζ = 0.2, 0.4, 0.5, 0.7, 0.9'),9,[1 2]);
at(uilabel(c4,'Text','Results','FontWeight','bold'),10,[1 2]);
ta4 = at(uitextarea(c4,'Editable','off','FontName','Monospaced'),11,[1 2]);
btn4 = at(uibutton(c4,'Text','Update'),12,[1 2]);

r4 = uigridlayout(g4,[4 2],'RowHeight',{'fit','1x','1x','1x'},'ColumnWidth',{'1.25x','1x'});
lbl4 = at(uilabel(r4,'Text','','Interpreter','latex','FontSize',17),1,[1 2]);
ax4m = at(uiaxes(r4),[2 3],1);
ax4p = at(uiaxes(r4),4,1);
ax4y = at(uiaxes(r4),2,2);
ax4u1 = at(uiaxes(r4),3,2);
ax4u2 = at(uiaxes(r4),4,2);
[ax4m.Interactions, ax4p.Interactions, ax4y.Interactions, ax4u1.Interactions, ax4u2.Interactions] = deal([]);

dd4.ValueChangedFcn = @(~,~) loadPreset4();
[dd4T.ValueChangedFcn, ef4k.ValueChangedFcn, ef4w.ValueChangedFcn, ef4z.ValueChangedFcn, ...
    ef4t1.ValueChangedFcn, ef4t2.ValueChangedFcn] = deal(@(~,~) markCustom(dd4,@update4));
cb4F.ValueChangedFcn = @(~,~) update4();
btn4.ButtonPushedFcn = @(~,~) update4();

% Initial draw
loadPreset1(); loadPreset2(); loadPreset3(); loadPreset4();

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
        if isempty(presets1{k,3}), update1(); return, end
        ef1.Value = presets1{k,2};
        [ef1w.Value, ef1M.Value, ef1ph.Value] = presets1{k,3:5};
        update1();
    end

    function update1()
        try
            P = parseTF(ef1.Value);
            w0 = ef1w.Value;  MU = ef1M.Value;  phU = ef1ph.Value;
            w = freqGrid(P,w0);
            [Pw,ph] = freqData(P,w);
            [~,i0] = min(abs(w - w0));
            M = abs(Pw(i0));  phi = ph(i0);       % phi in degrees
            a = real(Pw(i0));  b = imag(Pw(i0));
            p = pole(P);
            stable = all(real(p) < -1e-9);
            MY = M*abs(MU);  phiY = phi + phU;

            lbl1P.Text = sprintf(['$P(j\\omega)\\big|_{\\omega=%s}=%s%sj=%se^{j(%s^\\circ)},\\quad M_P=%s\\ (%s\\,\\mathrm{dB}),' ...
                '\\ \\phi_P=%s^\\circ$'],num(w0),num(a),signedNum(b),num(M),num(phi),num(M),num(20*log10(M)),num(phi));
            lbl1y.Text = sprintf('$y_{ss}(t)=M_PM_U\\sin(\\omega t+\\phi_P+\\phi_U)=%s\\sin(%st%s^\\circ)$', ...
                num(MY),num(w0),signedNum(phiY));

            % Time response: long enough for the natural response to decay
            Tp = 2*pi/w0;
            if stable, Tset = 5/min(-real(p)); else, Tset = 0; end
            if isempty(p), Tset = 0; end
            Tset = Tset + totalDelay(P);
            T = min(Tset,400*Tp) + 5*Tp;
            N = min(max(4000,round(80*T/Tp)),2e5);
            t = linspace(0,T,N)';
            u = MU*sin(w0*t + deg2rad(phU));
            y = lsim(P,u,t);
            yss = MY*sin(w0*t + deg2rad(phiY));
            cla(ax1t); hold(ax1t,'on');
            if cb1T.Value
                tv = t;
            else
                tv = t(t >= T - 5*Tp);
            end
            yAll = [u; y; yss];
            yl = [min(yAll) max(yAll)];  yl = yl + [-0.08 0.08]*max(diff(yl),1e-6);
            if stable && cb1T.Value && Tset > 0
                patch(ax1t,[0 Tset Tset 0],yl([1 1 2 2]),[0.93 0.93 0.93],'EdgeColor','none','HitTest','off');
                text(ax1t,Tset/2,yl(2),'transient','HorizontalAlignment','center','VerticalAlignment','top', ...
                    'Color',[0.4 0.4 0.4],'FontSize',11,'HitTest','off');
            end
            idx = t >= tv(1);
            plot(ax1t,t(idx),u(idx),'k','LineWidth',1.2,'DisplayName','u(t)');
            plot(ax1t,t(idx),y(idx),'Color',cBlue,'LineWidth',2,'DisplayName','y(t) (lsim)');
            plot(ax1t,t(idx),yss(idx),'--','Color',cRed,'LineWidth',1.6, ...
                'DisplayName',sprintf('%s sin(%st %s°)',num(MY),num(w0),signedNum(phiY)));
            hold(ax1t,'off'); grid(ax1t,'on');
            showLegend(ax1t);
            xlim(ax1t,[tv(1) T]); ylim(ax1t,yl);
            xlabel(ax1t,'t (seconds)');
            if stable
                title(ax1t,'Input and output: after the transient, y(t) follows the predicted sinusoid');
            else
                title(ax1t,'P(s) is not strictly stable: the natural response does not decay');
            end

            % Bode and Nyquist with the cursor
            drawBode(ax1m,ax1p,w,Pw,ph,w0,@(pt) setW1(pt(1)),@update1);
            cla(ax1n); hold(ax1n,'on');
            [xl,ylN] = nyqLimits(Pw,Pw(i0));
            plot(ax1n,xl,[0 0],'k-',[0 0],ylN,'k-','HitTest','off');
            plot(ax1n,real(Pw),imag(Pw),'Color',cBlue,'LineWidth',2,'HitTest','off');
            plot(ax1n,[0 a],[0 b],'-','Color',cRed,'LineWidth',2,'HitTest','off');
            h = plot(ax1n,a,b,'o','MarkerSize',10,'MarkerFaceColor',cRed,'MarkerEdgeColor','k');
            draggable(h,ax1n,@(pt,~) setW1(nearestW(ax1n,pt,real(Pw),imag(Pw),w)),@update1);
            text(ax1n,a,b,sprintf('  P(j%s)',num(w0)),'Color',cRed,'FontSize',12,'HitTest','off');
            hold(ax1n,'off'); grid(ax1n,'on');
            xlim(ax1n,xl); ylim(ax1n,ylN);
            title(ax1n,'Nyquist: P(jω) = M_P e^{jφ_P}'); xlabel(ax1n,'Real axis'); ylabel(ax1n,'Imaginary axis');

            % Results
            txt = {sprintf('w = %s rad/s (period %s s)',num(w0),num(Tp)); ...
                sprintf('P(jw) = %s %s j',num(a),signedNum(b)); ...
                sprintf('M_P = |P(jw)| = %s (%s dB)',num(M),num(20*log10(M))); ...
                sprintf('phi_P = %s deg = %s rad',num(phi),num(deg2rad(phi))); ''; ...
                sprintf('Output amplitude M_P*M_U = %s',num(MY)); ...
                sprintf('Output phase phi_P + phi_U = %s deg',num(phiY))};
            if phi < 0
                txt{end+1} = sprintf('y lags u by %s s (= |phi_P|/w)',num(-deg2rad(phi)/w0));
            else
                txt{end+1} = sprintf('y leads u by %s s (= phi_P/w)',num(deg2rad(phi)/w0));
            end
            tau = totalDelay(P);
            if tau > 0
                txt{end+1} = sprintf('Delay adds -w*tau = %s deg of phase',num(-rad2deg(w0*tau)));
            end
            txt{end+1} = '';
            if stable
                txt{end+1} = sprintf('Stable: transient gone after ~%s s.',num(Tset));
                txt{end+1} = sprintf('Measured max|y| over the last period: %s',num(max(abs(y(t >= T - Tp)))));
            else
                txt = [txt; {'Not strictly stable: the natural response'; ...
                    'does not decay, so y(t) never becomes the'; ...
                    'pure sinusoid predicted by P(jw).'}];
            end
            ta1.Value = txt(:);
        catch err
            showError(ta1,err);
        end
    end

    function setW1(wNew)
        ef1w.Value = max(wNew,1e-6);
        dd1.Value = 'Custom';
        update1();
    end

    function drawBode(axM,axP,w,Pw,ph,wc,moveFcn,doneFcn)
        % Bode magnitude and phase of Pw with a draggable cursor at wc.
        [~,ic] = min(abs(w - wc));
        magDB = 20*log10(abs(Pw));
        cla(axM); hold(axM,'on');
        plot(axM,w,magDB,'Color',cBlue,'LineWidth',2,'HitTest','off');
        plot(axM,[wc wc],[min(magDB) max(magDB)],':','Color',cRed,'HitTest','off');
        h = plot(axM,wc,magDB(ic),'o','MarkerSize',10,'MarkerFaceColor',cRed,'MarkerEdgeColor','k');
        draggable(h,axM,@(pt,~) moveFcn(pt),doneFcn);
        hold(axM,'off'); grid(axM,'on');
        set(axM,'XScale','log'); xlim(axM,[w(1) w(end)]);
        title(axM,'Bode magnitude'); ylabel(axM,'|P(jω)| (dB)');
        cla(axP); hold(axP,'on');
        plot(axP,w,ph,'Color',cBlue,'LineWidth',2,'HitTest','off');
        plot(axP,[wc wc],[min(ph) max(ph)] + [-1 1],':','Color',cRed,'HitTest','off');
        h = plot(axP,wc,ph(ic),'o','MarkerSize',10,'MarkerFaceColor',cRed,'MarkerEdgeColor','k');
        draggable(h,axP,@(pt,~) moveFcn(pt),doneFcn);
        hold(axP,'off'); grid(axP,'on');
        set(axP,'XScale','log'); xlim(axP,[w(1) w(end)]);
        title(axP,'Bode phase'); ylabel(axP,'∠P(jω) (deg)'); xlabel(axP,'ω (rad/s)');
    end

%% =====================================================================
%  Tab 2 callbacks
%  =====================================================================
    function loadPreset2()
        k = find(strcmp(presets2(:,1),dd2.Value));
        if isempty(presets2{k,3}), update2(); return, end
        ef2.Value = presets2{k,2};
        [ef2k.Value, ef2tau.Value, ef2w.Value] = presets2{k,3:5};
        update2();
    end

    function update2()
        try
            L0 = parseTF(ef2.Value);
            k = ef2k.Value;  tau = ef2tau.Value;  wc = ef2w.Value;
            if k == 0, error('The gain k must be nonzero.'); end
            L = k*L0;  L.InputDelay = L.InputDelay + tau;
            w = freqGrid(L,wc);
            if tau > 0, w = logspace(log10(w(1)),log10(min(w(end),30/tau)),2000)'; w = unique([w; wc]); end
            [Lw,ph] = freqData(L,w);
            [L0w,ph0] = freqData(L0,w);
            [~,ic] = min(abs(w - wc));
            magDB = 20*log10(abs(Lw));  mag0 = 20*log10(abs(L0w));
            showOrig = cb2O.Value && (k ~= 1 || tau > 0);
            a = real(Lw(ic));  b = imag(Lw(ic));

            lbl2.Text = sprintf(['$L(j\\omega)\\big|_{\\omega=%s}=a+jb=%s%sj=|L|e^{j\\angle L}=%se^{j(%s^\\circ)},' ...
                '\\quad |L|_{dB}=%s\\,\\mathrm{dB},\\quad 20\\log_{10}|k|=%s\\,\\mathrm{dB}$'], ...
                num(wc),num(a),signedNum(b),num(abs(Lw(ic))),num(ph(ic)),num(magDB(ic)),num(20*log10(abs(k))));

            % Frequencies to label on the loci (decades)
            dec = 10.^(ceil(log10(w(1))):floor(log10(w(end))));
            idec = arrayfun(@(v) find(w >= v,1),dec);

            % Nyquist
            cla(ax2n); hold(ax2n,'on');
            if showOrig, [xl,yl] = nyqLimits([Lw; L0w],Lw(ic)); else, [xl,yl] = nyqLimits(Lw,Lw(ic)); end
            plot(ax2n,xl,[0 0],'k-',[0 0],yl,'k-','HitTest','off');
            plot(ax2n,-1,0,'+','Color',cRed,'MarkerSize',10,'LineWidth',1.5,'HitTest','off');
            if showOrig
                plot(ax2n,real(L0w),imag(L0w),'--','Color',cGrey,'LineWidth',1.5,'HitTest','off');
            end
            h = plot(ax2n,real(Lw),imag(Lw),'Color',cBlue,'LineWidth',2.2);
            draggable(h,ax2n,@(pt,p0) scaleK2(abs(complex(pt(1),pt(2)))/max(abs(complex(p0(1),p0(2))),eps),k),@update2);
            jn = spreadOut(real(Lw(idec)),imag(Lw(idec)),xl,yl);
            plot(ax2n,real(Lw(idec)),imag(Lw(idec)),'k.','MarkerSize',14,'HitTest','off');
            text(ax2n,real(Lw(idec(jn))),imag(Lw(idec(jn))),arrayfun(@(v) sprintf('  ω=%s',num(v)),dec(jn),'UniformOutput',false), ...
                'FontSize',10,'HitTest','off','Clipping','on');
            h = plot(ax2n,a,b,'o','MarkerSize',11,'MarkerFaceColor',cRed,'MarkerEdgeColor','k');
            draggable(h,ax2n,@(pt,~) setW2(nearestW(ax2n,pt,real(Lw),imag(Lw),w)),@update2);
            hold(ax2n,'off'); grid(ax2n,'on');
            xlim(ax2n,xl); ylim(ax2n,yl);
            title(ax2n,'Nyquist diagram (ω ≥ 0)'); xlabel(ax2n,'Real axis, a(ω)'); ylabel(ax2n,'Imaginary axis, b(ω)');

            % Bode
            cla(ax2m); hold(ax2m,'on');
            if showOrig, plot(ax2m,w,mag0,'--','Color',cGrey,'LineWidth',1.5,'HitTest','off'); end
            h = plot(ax2m,w,magDB,'Color',cBlue,'LineWidth',2.2);
            draggable(h,ax2m,@(pt,p0) scaleK2(10^((pt(2)-p0(2))/20),k),@update2);
            h = plot(ax2m,wc,magDB(ic),'o','MarkerSize',11,'MarkerFaceColor',cRed,'MarkerEdgeColor','k');
            draggable(h,ax2m,@(pt,~) setW2(pt(1)),@update2);
            hold(ax2m,'off'); grid(ax2m,'on'); set(ax2m,'XScale','log'); xlim(ax2m,[w(1) w(end)]);
            title(ax2m,'Bode magnitude (drag the curve to change k)'); ylabel(ax2m,'|L(jω)| (dB)');
            cla(ax2p); hold(ax2p,'on');
            if showOrig, plot(ax2p,w,ph0,'--','Color',cGrey,'LineWidth',1.5,'HitTest','off'); end
            plot(ax2p,w,ph,'Color',cBlue,'LineWidth',2.2,'HitTest','off');
            h = plot(ax2p,wc,ph(ic),'o','MarkerSize',11,'MarkerFaceColor',cRed,'MarkerEdgeColor','k');
            draggable(h,ax2p,@(pt,~) setW2(pt(1)),@update2);
            hold(ax2p,'off'); grid(ax2p,'on'); set(ax2p,'XScale','log'); xlim(ax2p,[w(1) w(end)]);
            title(ax2p,'Bode phase'); ylabel(ax2p,'∠L(jω) (deg)'); xlabel(ax2p,'ω (rad/s)');

            % Log-polar (Nichols)
            cla(ax2c); hold(ax2c,'on');
            if showOrig, plot(ax2c,ph0,mag0,'--','Color',cGrey,'LineWidth',1.5,'HitTest','off'); end
            h = plot(ax2c,ph,magDB,'Color',cBlue,'LineWidth',2.2);
            draggable(h,ax2c,@(pt,p0) scaleK2(10^((pt(2)-p0(2))/20),k),@update2);
            jc = spreadOut(ph(idec),magDB(idec),[min(ph) max(ph)],[min(magDB) max(magDB)]);
            plot(ax2c,ph(idec),magDB(idec),'k.','MarkerSize',14,'HitTest','off');
            text(ax2c,ph(idec(jc)),magDB(idec(jc)),arrayfun(@(v) sprintf('  ω=%s',num(v)),dec(jc),'UniformOutput',false), ...
                'FontSize',10,'HitTest','off','Clipping','on');
            h = plot(ax2c,ph(ic),magDB(ic),'o','MarkerSize',11,'MarkerFaceColor',cRed,'MarkerEdgeColor','k');
            draggable(h,ax2c,@(pt,~) setW2(nearestW(ax2c,pt,ph,magDB,w)),@update2);
            hold(ax2c,'off'); grid(ax2c,'on');
            yl = [min(magDB) max(magDB)];
            if showOrig, yl = [min([yl mag0']) max([yl mag0'])]; end
            yl = [max(yl(1),magDB(ic)-80) min(yl(2),magDB(ic)+80)];
            ylim(ax2c,yl + [-5 5]);
            title(ax2c,'Log-polar plot'); xlabel(ax2c,'∠L(jω) (deg)'); ylabel(ax2c,'|L(jω)| (dB)');

            % Results
            txt = {sprintf('Cursor w = %s rad/s',num(wc)); ...
                sprintf('Rectangular: a = %s, b = %s',num(a),num(b)); ...
                sprintf('Polar: |L| = %s, angle = %s deg',num(abs(Lw(ic))),num(ph(ic))); ...
                sprintf('       |L|_dB = 20log10|L| = %s dB',num(magDB(ic))); ''; ...
                sprintf('Gain k = %s: shifts |L|_dB by %s dB',num(k),num(20*log10(abs(k)))); ...
                '  at every frequency (Bode and log-polar'; ...
                '  move up/down; Nyquist is scaled).'};
            if k < 0, txt{end+1} = '  k < 0 also adds 180 deg of phase.'; end
            if tau > 0
                txt = [txt; {sprintf('Delay tau = %s s: |L| unchanged,',num(tau)); ...
                    sprintf('  phase -w*tau = %s deg at the cursor.',num(-rad2deg(wc*tau)))}];
            end
            txt = [txt; {''; 'All three plots show the same complex'; ...
                'numbers; the dots mark decades of w.'}];
            ta2.Value = txt(:);
        catch err
            showError(ta2,err);
        end
    end

    function setW2(wNew)
        ef2w.Value = max(wNew,1e-9);
        update2();
    end

    function scaleK2(ratio,k0)
        % Drag a curve: scale the gain relative to the value at the start of the drag.
        if ~isfinite(ratio) || ratio <= 0, return, end
        ef2k.Value = k0*ratio;
        dd2.Value = 'Custom';
        update2();
    end

%% =====================================================================
%  Tab 3 callbacks
%  =====================================================================
    function loadPreset3()
        k = find(strcmp(presets3(:,1),dd3.Value));
        if isempty(presets3{k,3}), update3(); return, end
        ef3.Value = presets3{k,2};
        ef3b.Value = presets3{k,3};
        sel3 = 0;
        update3();
    end

    function update3()
        try
            P = parseTF(ef3.Value);
            [z,p,K] = zpkdata(P,'v');
            b = ef3b.Value;
            n = numel(p);  m = numel(z);
            nInt = sum(abs(p) < 1e-9) - sum(abs(z) < 1e-9);    % net integrators
            rd = n - m;
            % Gains
            Kint = K*prod(-z(abs(z) >= 1e-9))/prod(-p(abs(p) >= 1e-9));   % lim s^k P(s)
            if nInt > 0, Gdc = Inf; elseif nInt < 0, Gdc = 0; else, Gdc = Kint; end
            if rd > 0, Ghf = 0; elseif rd < 0, Ghf = Inf; else, Ghf = K; end
            w = freqGrid(P,[]);
            [Pw,ph] = freqData(P,w);
            magDB = 20*log10(abs(Pw));
            phLow = ph(1);  phHigh = ph(end);
            kFromPhase = -phLow/90;  rdFromPhase = -phHigh/90;
            ruleOK = K > 0 && all(real(z(abs(z) >= 1e-9)) < 0) && all(real(p(abs(p) >= 1e-9)) < 0);

            lbl3a.Text = sprintf(['$G_{dc}=\\lim_{s\\to0}P(s)=%s,\\quad G_{hf}=\\lim_{s\\to\\infty}P(s)=%s,' ...
                '\\quad k=%d\\ \\mathrm{integrators},\\quad n-m=%d-%d=%d$'],gainTex(Gdc),gainTex(Ghf),nInt,n,m,rd);
            lbl3b.Text = sprintf(['$\\angle P(j\\omega)\\to%s^\\circ\\ (-90k=%d^\\circ)\\ \\mathrm{as}\\ \\omega\\to0,\\quad' ...
                '\\angle P(j\\omega)\\to%s^\\circ\\ (-90(n-m)=%d^\\circ)\\ \\mathrm{as}\\ \\omega\\to\\infty$'], ...
                num(round(phLow,1)),-90*nInt,num(round(phHigh,1)),-90*rd);
            okC = [0 0 0];  if ~ruleOK, okC = [0.75 0 0]; end
            lbl3b.FontColor = okC;

            % Bode with asymptotes
            cla(ax3m); hold(ax3m,'on');
            plot(ax3m,w,magDB,'Color',cBlue,'LineWidth',2.2,'DisplayName','|P(jω)|');
            wl = w(w <= w(1)*100);
            plot(ax3m,wl,20*log10(abs(Kint)) - 20*nInt*log10(wl),'--','Color',cOrange,'LineWidth',1.8, ...
                'DisplayName',sprintf('low ω: %s dB/dec',num(-20*nInt)));
            wh = w(w >= w(end)/100);
            plot(ax3m,wh,20*log10(abs(K)) - 20*rd*log10(wh),'--','Color',cPurple,'LineWidth',1.8, ...
                'DisplayName',sprintf('high ω: %s dB/dec',num(-20*rd)));
            hold(ax3m,'off'); grid(ax3m,'on'); set(ax3m,'XScale','log'); xlim(ax3m,[w(1) w(end)]);
            showLegend(ax3m);
            title(ax3m,'Bode magnitude with asymptotes'); ylabel(ax3m,'|P(jω)| (dB)');
            cla(ax3p); hold(ax3p,'on');
            plot(ax3p,w,ph,'Color',cBlue,'LineWidth',2.2,'DisplayName','∠P(jω)');
            plot(ax3p,w([1 end]),-90*nInt*[1 1],'--','Color',cOrange,'LineWidth',1.5,'DisplayName','-90k°');
            plot(ax3p,w([1 end]),-90*rd*[1 1],'--','Color',cPurple,'LineWidth',1.5,'DisplayName','-90(n-m)°');
            hold(ax3p,'off'); grid(ax3p,'on'); set(ax3p,'XScale','log'); xlim(ax3p,[w(1) w(end)]);
            showLegend(ax3p);
            title(ax3p,'Bode phase'); ylabel(ax3p,'∠P(jω) (deg)'); xlabel(ax3p,'ω (rad/s)');

            % Step response
            cla(ax3y); hold(ax3y,'on');
            stable = all(real(p) < -1e-9);
            if rd >= 0
                tEnd = 8;
                if ~isempty(p) && stable, tEnd = 6/min(-real(p)); end
                if ~stable, tEnd = 10; end
                t = linspace(0,tEnd,2000)';
                y = b*step(P,t);
                plot(ax3y,t,b*ones(size(t)),'k-','LineWidth',1.2,'DisplayName','u(t) = β');
                plot(ax3y,t,y,'Color',cBlue,'LineWidth',2.2,'DisplayName','y(t)');
                if isfinite(Ghf)
                    plot(ax3y,0,b*Ghf,'o','MarkerSize',10,'MarkerFaceColor',cPurple,'MarkerEdgeColor','k', ...
                        'DisplayName',sprintf('y(0^+) = G_{hf}β = %s',num(b*Ghf)));
                end
                if stable && isfinite(Gdc)
                    plot(ax3y,[0 tEnd],b*Gdc*[1 1],'--','Color',cOrange,'LineWidth',1.6, ...
                        'DisplayName',sprintf('y_∞ = G_{dc}β = %s',num(b*Gdc)));
                end
                xlim(ax3y,[0 tEnd]);
                title(ax3y,sprintf('Response to a step of size β = %s',num(b)));
            else
                title(ax3y,'Improper P(s): no step response');
            end
            hold(ax3y,'off'); grid(ax3y,'on'); showLegend(ax3y); xlabel(ax3y,'t (seconds)');

            % s-plane with draggable poles and zeros
            rl = rootList(z,p);
            drawRoots3(rl);

            % Results
            txt = {sprintf('n = %d poles, m = %d zeros',n,m); ...
                sprintf('Integrators k = %d, relative degree n-m = %d',nInt,rd); ''; ...
                sprintf('DC gain  G_dc = %s',gainStr(Gdc)); ...
                sprintf('HF gain  G_hf = %s',gainStr(Ghf)); ''; ...
                'From the phase response:'; ...
                sprintf('  low w:  %s deg -> k = %s',num(phLow),num(kFromPhase)); ...
                sprintf('  high w: %s deg -> n-m = %s',num(phHigh),num(rdFromPhase))};
            if ruleOK
                txt{end+1} = '  (agrees: all poles/zeros in the OLHP)';
            else
                txt = [txt; {'  The phase rules assume A_p > 0 and all'; ...
                    '  nonzero poles/zeros in the OLHP. Each'; ...
                    '  ORHP pole/zero (or A_p < 0) adds extra'; ...
                    '  +/-180 deg, so the rules do not apply.'}];
            end
            if stable && isfinite(Gdc)
                txt{end+1} = '';
                txt{end+1} = sprintf('Step beta = %s: y(inf) = %s',num(b),num(b*Gdc));
                if isfinite(Ghf), txt{end+1} = sprintf('                 y(0+)  = %s',num(b*Ghf)); end
            elseif ~stable
                txt = [txt; {''; 'Not strictly stable: y(inf) is not G_dc*beta.'}];
            end
            ta3.Value = txt(:);
        catch err
            showError(ta3,err);
        end
    end

    function drawRoots3(rl)
        cla(ax3s); hold(ax3s,'on');
        v = [rl.val];
        R = max([abs(v) 1]);
        xl = [min([real(v) 0]) - 0.3*R, max([real(v) 0]) + 0.3*R];
        yl = [-1 1]*max([abs(imag(v))*1.3, 0.35*diff(xl)]);
        patch(ax3s,[0 xl(2) xl(2) 0],yl([1 1 2 2]),[1 0.92 0.92],'EdgeColor','none','HitTest','off');
        plot(ax3s,xl,[0 0],'k-',[0 0],yl,'k-','HitTest','off');
        for j = 1:numel(rl)
            if j == sel3, col = cSel; else, col = cPurple; end
            if rl(j).kind == 'p', mk = 'x'; ms = 16; lw = 3; else, mk = 'o'; ms = 12; lw = 2.5; end
            vals = rl(j).val;
            if rl(j).pair, vals = [vals conj(vals)]; end %#ok<AGROW>
            for q = 1:numel(vals)
                h = plot(ax3s,real(vals(q)),imag(vals(q)),mk,'MarkerSize',ms,'LineWidth',lw,'Color',col);
                draggable(h,ax3s,@(pt,~) moveRoot3(j,pt,rl),@update3);
            end
        end
        % Multiplicity labels for repeated roots (e.g. double integrators)
        [u,~,ic] = unique(round(v*1e6)/1e6);
        for q = 1:numel(u)
            if sum(ic == q) > 1
                text(ax3s,real(u(q)),imag(u(q)) + 0.06*diff(yl),sprintf('×%d',sum(ic == q)), ...
                    'HorizontalAlignment','center','Color',cPurple,'FontSize',12,'HitTest','off');
            end
        end
        hold(ax3s,'off'); grid(ax3s,'on');
        xlim(ax3s,xl); ylim(ax3s,yl);
        title(ax3s,'s-plane: drag poles (x) and zeros (o)'); xlabel(ax3s,'Real axis'); ylabel(ax3s,'Imaginary axis');
    end

    function moveRoot3(j,pt,rl)
        xr = diff(ax3s.XLim);  yr = diff(ax3s.YLim);
        x = pt(1);
        if abs(x) < 0.02*xr, x = 0; end
        if rl(j).pair
            rl(j).val = complex(x,max(abs(pt(2)),0.02*yr));
        else
            rl(j).val = x;
        end
        sel3 = j;
        setRoots3(rl);
    end

    function setRoots3(rl)
        [~,~,K] = zpkdata(parseTF(ef3.Value),'v');
        ef3.Value = rootsToExpr(rl,K,0);
        dd3.Value = 'Custom';
        update3();
    end

    function addRoot3()
        item = dd3Add.Value;
        dd3Add.Value = addItems{1};
        if strcmp(item,addItems{1}), return, end
        [z,p] = zpkdata(parseTF(ef3.Value),'v');
        rl = rootList(z,p);
        switch item
            case 'Real pole',          rl(end+1) = rootEntry('p',-1,false);
            case 'Complex pole pair',  rl(end+1) = rootEntry('p',complex(-1,1),true);
            case 'Real zero',          rl(end+1) = rootEntry('z',-2,false);
            case 'Complex zero pair',  rl(end+1) = rootEntry('z',complex(-2,2),true);
        end
        sel3 = numel(rl);
        setRoots3(rl);
    end

    function deleteRoot3()
        [z,p] = zpkdata(parseTF(ef3.Value),'v');
        rl = rootList(z,p);
        if sel3 < 1 || sel3 > numel(rl), return, end
        rl(sel3) = [];
        sel3 = 0;
        setRoots3(rl);
    end

%% =====================================================================
%  Tab 4 callbacks
%  =====================================================================
    function loadPreset4()
        k = find(strcmp(presets4(:,1),dd4.Value));
        if isempty(presets4{k,2}), update4(); return, end
        dd4T.Value = types4{presets4{k,2}};
        [ef4k.Value, ef4w.Value, ef4z.Value] = presets4{k,3:5};
        ef4t1.Value = presets4{k,6}*presets4{k,4};
        ef4t2.Value = presets4{k,7}*presets4{k,4};
        update4();
    end

    function update4()
        try
            type = find(strcmp(types4,dd4T.Value));
            second = type == 2 || type >= 4;
            set([lbl4z ef4z],'Visible',onoff(second));
            cb4F.Enable = onoff(second);
            if second, lbl4w.Text = 'ωₙ (rad/s)'; else, lbl4w.Text = 'ω₀ (rad/s)'; end
            labs = {'DC gain A_s','DC gain k','HF gain k','HF gain k','Peak gain k'};
            lbl4k.Text = labs{type};
            k = ef4k.Value;  wn = ef4w.Value;  zeta = ef4z.Value;
            if k == 0, error('The gain must be nonzero.'); end
            P = filterTF(type,k,wn,zeta);
            w = logspace(log10(wn) - 2.5,log10(wn) + 2.5,3000)';
            w = unique([w; ef4t1.Value; ef4t2.Value]);
            [Pw,ph] = freqData(P,w);
            magDB = 20*log10(abs(Pw));
            [ref,refName] = filterRef(type,k);         % reference level for the -3 dB points
            refDB = 20*log10(abs(ref));
            bw = crossings(w,magDB,refDB - 20*log10(sqrt(2)));
            [mPk,iPk] = max(magDB);
            hasPeak = mPk > refDB + 0.01 && iPk > 1 && iPk < numel(w);

            % Equations and formulas from the notes
            switch type
                case 1
                    eq = sprintf(['P_L(s)=\\frac{A_s}{s/\\omega_0+1}=\\frac{%s}{s/%s+1},\\quad |P_L(j\\omega_0)|_{dB}=' ...
                        '20\\log_{10}A_s-3\\,\\mathrm{dB},\\ \\angle P_L(j\\omega_0)=-45^\\circ,\\ T_c=1/\\omega_0=%s\\,\\mathrm{s}'], ...
                        num(k),num(wn),num(1/wn));
                case 2
                    eq = sprintf(['P_L(s)=\\frac{k\\omega_n^2}{s^2+2\\zeta\\omega_ns+\\omega_n^2},\\ \\omega_p=\\omega_n\\sqrt{1-2\\zeta^2},' ...
                        '\\ M_p=\\frac{k}{2\\zeta\\sqrt{1-\\zeta^2}},\\ \\omega_0=\\omega_n\\sqrt{1-2\\zeta^2+\\sqrt{4\\zeta^4-4\\zeta^2+2}}']);
                case 3
                    eq = sprintf(['P_H(s)=1-P_L(s)=k\\frac{s/\\omega_0}{s/\\omega_0+1}=\\frac{%ss/%s}{s/%s+1},\\quad ' ...
                        '|P_H(j\\omega_0)|_{dB}=20\\log_{10}k-3\\,\\mathrm{dB},\\ \\angle P_H(j\\omega_0)=45^\\circ'],coefTex(k),num(wn),num(wn));
                case 4
                    eq = sprintf(['P_H(s)=k\\frac{s^2/\\omega_n^2+(2\\zeta/\\omega_n)s}{s^2/\\omega_n^2+(2\\zeta/\\omega_n)s+1},' ...
                        '\\ \\omega_p=\\omega_n\\sqrt{\\frac{1+\\sqrt{1+8\\zeta^2}}{2}},\\ |P_H(j\\omega)|=k\\ \\mathrm{at}\\ ' ...
                        '\\omega=\\frac{\\omega_n}{\\sqrt2}']);
                otherwise
                    eq = sprintf(['P_B(s)=k\\frac{2\\zeta\\omega_ns}{s^2+2\\zeta\\omega_ns+\\omega_n^2},\\quad ' ...
                        '|P_B(j\\omega_n)|=|k|,\\ \\angle P_B(j\\omega_n)=0^\\circ']);
            end
            lbl4.Text = ['$' eq '$'];

            % Bode magnitude
            cla(ax4m); hold(ax4m,'on');
            if second && cb4F.Value
                st = {'-','--',':','-.','-'};
                Z = [0.2 0.4 0.5 0.7 0.9];
                for q = 1:5
                    [Fw,~] = freqData(filterTF(type,k,wn,Z(q)),w);
                    plot(ax4m,w,20*log10(abs(Fw)),st{q},'Color',[0.62 0.62 0.62],'LineWidth',1.3,'HitTest','off', ...
                        'DisplayName',sprintf('ζ = %g',Z(q)));
                end
            end
            [asW,asM] = filterAsymptotes(type,k,wn,w);
            plot(ax4m,asW,asM,'--','Color',cOrange,'LineWidth',1.5,'HitTest','off','DisplayName','asymptotes');
            plot(ax4m,w,magDB,'Color',cBlue,'LineWidth',2.4,'HitTest','off','DisplayName','|P(jω)|');
            plot(ax4m,w([1 end]),(refDB - 3.0103)*[1 1],':','Color',[0.3 0.3 0.3],'HitTest','off', ...
                'DisplayName',sprintf('%s − 3 dB',refName));
            for q = 1:numel(bw)
                h = plot(ax4m,bw(q),refDB - 3.0103,'d','MarkerSize',11,'MarkerFaceColor',cGreen,'MarkerEdgeColor','k');
                draggable(h,ax4m,@(pt,~) moveBW4(pt,bw(q)/wn),@update4);
                text(ax4m,bw(q),refDB - 3.0103,sprintf('  %s',num(bw(q))),'Color',cGreen*0.8,'FontSize',12, ...
                    'VerticalAlignment','top','HitTest','off');
            end
            if hasPeak || type == 5
                if type == 5, [~,iPk] = min(abs(w - wn)); end
                h = plot(ax4m,w(iPk),magDB(iPk),'o','MarkerSize',11,'MarkerFaceColor',cRed,'MarkerEdgeColor','k');
                draggable(h,ax4m,@(pt,~) movePeak4(pt),@update4);
                text(ax4m,w(iPk),magDB(iPk),sprintf('  peak %s dB at %s',num(magDB(iPk)),num(w(iPk))), ...
                    'Color',cRed,'FontSize',12,'VerticalAlignment','bottom','HitTest','off');
            end
            tw = [ef4t1.Value ef4t2.Value];
            for q = 1:2
                [~,it] = min(abs(w - tw(q)));
                h = plot(ax4m,w(it),magDB(it),'s','MarkerSize',10,'MarkerFaceColor',[0.2 0.2 0.2],'MarkerEdgeColor','k');
                draggable(h,ax4m,@(pt,~) moveTest4(q,pt(1)),@update4);
                text(ax4m,w(it),magDB(it),sprintf('  ω_%d',q),'FontSize',12,'VerticalAlignment','top','HitTest','off');
            end
            hold(ax4m,'off'); grid(ax4m,'on'); set(ax4m,'XScale','log'); xlim(ax4m,[w(1) w(end)]);
            yl = [max(min(magDB),refDB - 70) max(magDB) + 6];
            ylim(ax4m,yl);
            showLegend(ax4m);
            title(ax4m,['Bode magnitude: ' types4{type}]); ylabel(ax4m,'|P(jω)| (dB)');

            % Bode phase
            cla(ax4p); hold(ax4p,'on');
            if second && cb4F.Value
                for q = 1:5
                    [~,Fp] = freqData(filterTF(type,k,wn,Z(q)),w);
                    plot(ax4p,w,Fp,st{q},'Color',[0.62 0.62 0.62],'LineWidth',1.3,'HitTest','off');
                end
            end
            plot(ax4p,w,ph,'Color',cBlue,'LineWidth',2.4,'HitTest','off');
            for q = 1:numel(bw)
                [~,ib] = min(abs(w - bw(q)));
                plot(ax4p,bw(q),ph(ib),'d','MarkerSize',10,'MarkerFaceColor',cGreen,'MarkerEdgeColor','k','HitTest','off');
                text(ax4p,bw(q),ph(ib),sprintf('  %s°',num(ph(ib))),'Color',cGreen*0.8,'FontSize',12,'HitTest','off');
            end
            hold(ax4p,'off'); grid(ax4p,'on'); set(ax4p,'XScale','log'); xlim(ax4p,[w(1) w(end)]);
            title(ax4p,'Bode phase'); ylabel(ax4p,'∠P(jω) (deg)'); xlabel(ax4p,'ω (rad/s)');

            % Step response
            sp = pole(P);
            tEnd = 6/min(-real(sp));
            t = linspace(0,tEnd,2000)';
            y = step(P,t);
            cla(ax4y);
            plot(ax4y,t,y,'Color',cBlue,'LineWidth',2.2);
            grid(ax4y,'on'); xlim(ax4y,[0 tEnd]);
            title(ax4y,'Unit step response'); xlabel(ax4y,'t (seconds)');

            % Test sinusoids
            axU = [ax4u1 ax4u2];  gains = zeros(1,2);  phs = zeros(1,2);
            for q = 1:2
                [~,it] = min(abs(w - tw(q)));
                gains(q) = abs(Pw(it));  phs(q) = ph(it);
                Tq = 2*pi/tw(q);
                T = tEnd + 6*Tq;
                tq = linspace(0,T,max(3000,round(60*T/Tq)))';
                tq = tq(1:min(end,2e5));
                uq = sin(tw(q)*tq);
                yq = lsim(P,uq,tq);
                keep = tq >= T - min(6*Tq,T);
                cla(axU(q)); hold(axU(q),'on');
                plot(axU(q),tq(keep),uq(keep),'k','LineWidth',1.2,'DisplayName',sprintf('u_%d = sin(%st)',q,num(tw(q))));
                plot(axU(q),tq(keep),yq(keep),'Color',cRed,'LineWidth',2,'DisplayName',sprintf('y_%d(t)',q));
                hold(axU(q),'off'); grid(axU(q),'on'); showLegend(axU(q));
                xlim(axU(q),[tq(find(keep,1)) T]);
                title(axU(q),sprintf('ω_%d = %s: gain %s, phase %s° (steady state)',q,num(tw(q)),num(gains(q)),num(phs(q))));
            end
            xlabel(ax4u2,'t (seconds)');

            % Results
            txt = {types4{type}; sprintf('Poles: %s',strjoin(arrayfun(@cplx,sp','UniformOutput',false),', '))};
            txt{end+1} = sprintf('Reference level (%s): %s dB',refName,num(refDB));
            if isempty(bw)
                txt{end+1} = '-3 dB point: none in the plotted range';
            else
                txt{end+1} = sprintf('-3 dB point(s): %s rad/s',strjoin(arrayfun(@num,bw','UniformOutput',false),', '));
            end
            switch type
                case 1
                    txt{end+1} = sprintf('Formula: w0 = %s, T_c = %s s',num(wn),num(1/wn));
                    txt{end+1} = 'Roll-off above w0: -20 dB/decade';
                case 2
                    if zeta < 1/sqrt(2)
                        txt{end+1} = sprintf('w_p = wn*sqrt(1-2z^2) = %s',num(wn*sqrt(1 - 2*zeta^2)));
                        txt{end+1} = sprintf('M_p = k/(2z sqrt(1-z^2)) = %s',num(abs(k)/(2*zeta*sqrt(1 - zeta^2))));
                        txt{end+1} = sprintf('    = %s dB (plot: %s dB)',num(20*log10(abs(k)/(2*zeta*sqrt(1 - zeta^2)))),num(mPk));
                    else
                        txt{end+1} = 'zeta >= 0.707: no resonant peak';
                    end
                    txt{end+1} = sprintf('w0 formula = %s',num(wn*sqrt(1 - 2*zeta^2 + sqrt(4*zeta^4 - 4*zeta^2 + 2))));
                    if zeta < 1
                        txt{end+1} = sprintf('Step %%OS = %s',num(100*exp(-zeta*pi/sqrt(1 - zeta^2))));
                    end
                    txt{end+1} = 'Roll-off above wn: -40 dB/decade';
                case 3
                    txt{end+1} = sprintf('Formula: w0 = %s, phase there 45 deg',num(wn));
                    txt{end+1} = 'Below w0: +20 dB/decade, phase lead';
                case 4
                    if hasPeak
                        txt{end+1} = sprintf('Peak at %s rad/s (plot)',num(w(iPk)));
                        txt{end+1} = sprintf('wn*sqrt((1+sqrt(1+8z^2))/2) = %s',num(wn*sqrt((1 + sqrt(1 + 8*zeta^2))/2)));
                    end
                    txt{end+1} = sprintf('|P| = k at wn/sqrt(2) = %s',num(wn/sqrt(2)));
                    txt{end+1} = 'Below wn: +20 dB/dec (the s term),';
                    txt{end+1} = '  +40 dB/dec only if zeta is small';
                otherwise
                    txt{end+1} = sprintf('Peak |k| = %s at wn = %s',num(abs(k)),num(wn));
                    if zeta < 1
                        tp = acos(zeta)/(wn*sqrt(1 - zeta^2));
                        txt{end+1} = sprintf('Step peak t_p = %s s,',num(tp));
                        txt{end+1} = sprintf('  y_p = 2kz e^(-z acos z/sqrt(1-z^2)) = %s',num(2*k*zeta*exp(-zeta*acos(zeta)/sqrt(1 - zeta^2))));
                    end
            end
            txt{end+1} = '';
            for q = 1:2
                if gains(q) >= abs(ref)/sqrt(2), band = 'passband'; else, band = 'attenuated'; end
                txt{end+1} = sprintf('w%d = %s: gain %s, %s deg (%s)',q,num(tw(q)),num(gains(q)),num(phs(q)),band); %#ok<AGROW>
            end
            ta4.Value = txt(:);
        catch err
            showError(ta4,err);
        end
    end

    function moveBW4(pt,ratio)
        % The -3 dB frequency scales with w0/wn: keep its ratio fixed.
        ef4w.Value = max(pt(1)/ratio,1e-6);
        dd4.Value = 'Custom';
        update4();
    end

    function movePeak4(pt)
        type = find(strcmp(types4,dd4T.Value));
        k = ef4k.Value;  zeta = ef4z.Value;
        switch type
            case 2
                % Height sets zeta through M_p = |k|/(2 zeta sqrt(1-zeta^2)); position sets wn
                M = 10^(pt(2)/20)/abs(k);
                if M > 1.0001
                    zeta = sqrt((1 - sqrt(1 - 1/M^2))/2);
                    ef4z.Value = max(zeta,0.01);
                end
                ef4w.Value = pt(1)/sqrt(1 - 2*ef4z.Value^2);
            case 4
                ef4w.Value = pt(1)/sqrt((1 + sqrt(1 + 8*zeta^2))/2);
            case 5
                ef4w.Value = pt(1);
                ef4k.Value = sign(k)*10^(pt(2)/20);
        end
        dd4.Value = 'Custom';
        update4();
    end

    function moveTest4(q,wNew)
        if q == 1, ef4t1.Value = max(wNew,1e-6); else, ef4t2.Value = max(wNew,1e-6); end
        dd4.Value = 'Custom';
        update4();
    end
end

%% =========================================================================
%  Frequency-response helpers
%  =========================================================================
function [Pw,ph] = freqData(P,w)
% Frequency response and continuous phase (deg): each pole/zero factor is
% unwrapped on its own, so integrators start at -90k deg as in the notes.
[z,p,k] = zpkdata(P,'v');
jw = 1j*w(:);
Pw = k*ones(size(jw));
ph = zeros(size(jw));
if k < 0, ph = ph + 180; end
for i = 1:numel(z)
    f = jw - z(i);
    Pw = Pw.*f;  ph = ph + unwrap(angle(f))*180/pi;
end
for i = 1:numel(p)
    f = jw - p(i);
    Pw = Pw./f;  ph = ph - unwrap(angle(f))*180/pi;
end
tau = totalDelay(P);
Pw = Pw.*exp(-jw*tau);
ph = ph - w(:)*tau*180/pi;
end

function tau = totalDelay(P)
tau = P.InputDelay + P.OutputDelay;
if isprop(P,'IODelay'), tau = tau + P.IODelay; end
end

function w = freqGrid(P,extra)
% Logarithmic grid two decades either side of the poles and zeros.
[z,p] = zpkdata(P,'v');
c = abs([z; p]);  c = c(c > 1e-9);
if isempty(c), c = 1; end
lo = min(c)/100;  hi = max(c)*100;
if ~isempty(extra), lo = min(lo,extra/10);  hi = max(hi,extra*10); end
w = logspace(log10(lo),log10(hi),2000)';
if ~isempty(extra), w = unique([w; extra(:)]); end
end

function [xl,yl] = nyqLimits(Pw,keepPts)
% Axis limits for a Nyquist plot, ignoring the part of the locus that runs
% off to infinity (integrators).
m = abs(Pw);
cap = max([2, 4*median(m), 1.5*abs(keepPts(:))']);
pts = [Pw(m <= cap); keepPts(:); 0];
xl = [min(real(pts)) max(real(pts))];
yl = [min(imag(pts)) max(imag(pts))];
r = max([diff(xl) diff(yl) 1e-3]);
xl = xl + [-0.12 0.12]*r;  yl = yl + [-0.12 0.12]*r;
end

function keep = spreadOut(X,Y,xl,yl)
% Indices of label positions at least 6% of the axis size from the last kept one.
keep = [];
for i = 1:numel(X)
    if ~(X(i) >= xl(1) && X(i) <= xl(2) && Y(i) >= yl(1) && Y(i) <= yl(2)), continue, end
    if isempty(keep) || hypot((X(i) - X(keep(end)))/diff(xl),(Y(i) - Y(keep(end)))/diff(yl)) > 0.06
        keep(end+1) = i; %#ok<AGROW>
    end
end
end

function wOut = nearestW(ax,pt,X,Y,w)
% Frequency of the locus point nearest the mouse (in normalised axis units).
dx = (X(:) - pt(1))/diff(ax.XLim);
dy = (Y(:) - pt(2))/diff(ax.YLim);
[~,i] = min(dx.^2 + dy.^2);
wOut = w(i);
end

function P = filterTF(type,k,wn,zeta)
s = tf('s');
switch type
    case 1, P = k/(s/wn + 1);
    case 2, P = k*wn^2/(s^2 + 2*zeta*wn*s + wn^2);
    case 3, P = k*(s/wn)/(s/wn + 1);
    case 4, P = k*(s^2/wn^2 + 2*zeta/wn*s)/(s^2/wn^2 + 2*zeta/wn*s + 1);
    otherwise, P = k*2*zeta*wn*s/(s^2 + 2*zeta*wn*s + wn^2);
end
P = zpk(P);
end

function [ref,name] = filterRef(type,k)
% Gain that the -3 dB points are measured from.
switch type
    case {1,2}, ref = k;  name = 'DC gain';
    case {3,4}, ref = k;  name = 'HF gain';
    otherwise,  ref = k;  name = 'peak gain';
end
end

function [aw,am] = filterAsymptotes(type,k,wn,w)
% Straight-line Bode magnitude asymptotes (NaN separates the segments).
lo = w(w <= wn);  hi = w(w >= wn);
K = 20*log10(abs(k));
switch type
    case 1, aw = [lo; NaN; hi];  am = [K*ones(size(lo)); NaN; K - 20*log10(hi/wn)];
    case 2, aw = [lo; NaN; hi];  am = [K*ones(size(lo)); NaN; K - 40*log10(hi/wn)];
    case 3, aw = [lo; NaN; hi];  am = [K + 20*log10(lo/wn); NaN; K*ones(size(hi))];
    case 4, aw = [lo; NaN; hi];  am = [K + 20*log10(lo/wn); NaN; K*ones(size(hi))];
    otherwise, aw = [lo; NaN; hi];  am = [K + 20*log10(lo/wn); NaN; K - 20*log10(hi/wn)];
end
end

function x = crossings(w,mDB,level)
% Frequencies at which the magnitude crosses a level (linear interpolation in log w).
d = mDB(:) - level;
i = find(d(1:end-1).*d(2:end) < 0);
x = zeros(numel(i),1);
for q = 1:numel(i)
    lw = log10(w(i(q):i(q)+1));
    x(q) = 10^interp1(d(i(q):i(q)+1),lw,0);
end
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
% Coefficient in front of a symbol: 1 and -1 are written as '' and '-'.
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

function s = gainTex(g)
if isinf(g), s = '\infty'; else, s = num(g); end
end

function s = gainStr(g)
if isinf(g), s = 'infinite'; else, s = num(g); end
end

%% =========================================================================
%  Pole-zero editing helpers
%  =========================================================================
function sys = parseTF(str)
% Evaluate a MATLAB expression in s as a zpk model (time delays allowed).
str = strtrim(str);
if isempty(str), error('Transfer function is empty.'); end
f = str2func(['@(s) ' str]);
sys = zpk(f(tf('s')));
if ~isscalar(sys.k), error('Enter a single-input, single-output transfer function.'); end
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

function expr = rootsToExpr(rl,K,tau)
% MATLAB expression in s for the zpk model K*prod(s-z)/prod(s-p)*exp(-tau s).
num_ = factorStr(rl([rl.kind] == 'z'));
den = factorStr(rl([rl.kind] == 'p'));
expr = sprintf('%.6g',K);
if ~isempty(num_), expr = [expr '*' num_]; end
if ~isempty(den), expr = [expr '/(' den ')']; end
if tau > 0, expr = sprintf('%s*exp(-%.6g*s)',expr,tau); end
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
%  UI helpers
%  =========================================================================
function showLegend(ax)
% Legend of the curves that have a DisplayName (markers and guides have none).
h = flipud(findobj(ax,'Type','line','-not','DisplayName',''));
if isempty(h), legend(ax,'off');
else, legend(ax,h,'Location','southwest','AutoUpdate','off'); end
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
    'e.g. 1/(s+10) or exp(-0.07*s)/(1+s).'};
end
