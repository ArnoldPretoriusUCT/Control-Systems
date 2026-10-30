function Chapter11_TransientDesignSpecificationsApp
%CHAPTER11_TRANSIENTDESIGNSPECIFICATIONSAPP Interactive GUI for MEC3079S Chapter 11 — Transient design specifications.
%
%   Run Chapter11_TransientDesignSpecificationsApp to open the app. The tabs follow the chapter:
%     1. M contours        (11.2-11.3): |S(jω)| = M and |T(jω)| = M as circles in
%        the Nyquist plane, as contours in the log-polar plane (inverse Nichols
%        and Nichols charts) and as a line on the Bode plot; s_M = 1/|S|max.
%     2. First-order design (11.4.3): settling-time and steady-state error
%        constraints on a proportional gain K.
%     3. Reference models  (11.4.4): second-order tracking model M_R(s) from
%        %OS and T_s, and band-pass disturbance model M_D(s) from y_p and T_s.
%     4. Tracking bounds   (11.5): stay-below M_A (all ω) and stay-above
%        M_B = 0.98 (ω ≤ ω_p) on |T|, shown as stay-out regions for L(jω).
%     5. Disturbance bounds (11.6): |PS(jω)| ≤ γ(ω) as frequency-dependent
%        circles |1 + L(jω)| ≥ |P(jω)|/γ(ω).
%
%   Interaction: drag the L(jω) curve (gain), the M line, the K marker and the
%   specification lines on the time responses.
%
%   Transfer functions are entered as MATLAB expressions in s, e.g. 5/(s*(s+2)).
%
%   Requires the Control System Toolbox.

cOrange = [0.85 0.33 0.10];
cBlue   = [0.00 0.45 0.74];
cPurple = [0.49 0.18 0.56];
cGreen  = [0.47 0.67 0.19];
cRed    = [0.85 0.10 0.10];
cGrey   = [0.60 0.60 0.60];

fig = uifigure('Name','MEC3079S Chapter 11 — Transient design specifications', ...
    'Position',[50 40 1340 860]);
mainGrid = uigridlayout(fig,[1 1],'Padding',[0 0 0 0]);
tg = uitabgroup(mainGrid);

% Drag state shared by all interactive plots
drag = struct('active',false,'ax',[],'move',[],'done',[],'p0',[0 0], ...
    'last',[],'xl',[],'yl',[],'t',tic);
fig.WindowButtonMotionFcn = @(~,~) onMotion();
fig.WindowButtonUpFcn = @(~,~) onRelease();

%% =====================================================================
%  Tab 1: M contours for S and T
%  =====================================================================
t1 = uitab(tg,'Title','M contours');
g1 = uigridlayout(t1,[1 2],'ColumnWidth',{340,'1x'});
c1 = uigridlayout(g1,[10 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{112,22,22,22,22,22,22,22,'1x',22});
at(uilabel(c1,'Text',['|S(jω)| = 1/|1 + L(jω)| = M is a circle of radius 1/M around −1; ' ...
    '|T(jω)| = M is a circle too (via 1/L). In the log-polar plane these become the inverse ' ...
    'Nichols and Nichols charts. Where L(jω) crosses the contour, |S| or |T| equals M. ' ...
    'Drag the M line on the Bode plot or the L(jω) curve (gain k).'],'FontWeight','bold','WordWrap','on'),1,[1 2]);
% name, L, k, function (1 S, 2 T), M
presets1 = { ...
    '11.2.2: L = 5/(s(s+1)), |S|max → s_M',         '5/(s*(s+1))',    1, 1, 2.49
    '11.2.3: L = 1/(s(s+0.8)), |S| vs M = 1.5',     '1/(s*(s+0.8))',  1, 1, 1.5
    '11.3.2: L = 1/(s(s+0.8)), |T| vs M = 1.5',     '1/(s*(s+0.8))',  1, 2, 1.5
    '11.5.2: L = 5/(s(s+2)), |T| vs M_A = 1.354',   '5/(s*(s+2))',    1, 2, 1.3537
    'Third order: L = 4/(s+1)³',                     '4/(s+1)^3',      1, 1, 2
    'Custom', '', [], [], []};
funcs1 = {'Sensitivity |S(jω)| (inverse Nichols)','Complementary |T(jω)| (Nichols)'};
at(uilabel(c1,'Text','Example'),2,1);
dd1 = at(uidropdown(c1,'Items',presets1(:,1)','Value',presets1{1,1}),2,2);
at(uilabel(c1,'Text','L₀(s)'),3,1);
ef1 = at(uieditfield(c1,'text','Value',presets1{1,2}),3,2);
at(uilabel(c1,'Text','Gain k (L = kL₀)'),4,1);
ef1k = at(uieditfield(c1,'numeric','Value',1,'Limits',[1e-9 Inf],'ValueDisplayFormat','%.4g'),4,2);
at(uilabel(c1,'Text','Function'),5,1);
dd1F = at(uidropdown(c1,'Items',funcs1),5,2);
at(uilabel(c1,'Text','Contour level M'),6,1);
ef1M = at(uieditfield(c1,'numeric','Value',2,'Limits',[0.05 50],'ValueDisplayFormat','%.4g'),6,2);
cb1G = at(uicheckbox(c1,'Text','Also draw a grid of M = 0.5, 0.7, 1, 1.5, 2, 3','Value',false),7,[1 2]);
at(uilabel(c1,'Text','Results','FontWeight','bold'),8,[1 2]);
ta1 = at(uitextarea(c1,'Editable','off','FontName','Monospaced'),9,[1 2]);
btn1 = at(uibutton(c1,'Text','Update'),10,[1 2]);

r1 = uigridlayout(g1,[3 2],'RowHeight',{'fit','1x','1x'},'ColumnWidth',{'1x','1.15x'});
lbl1 = at(uilabel(r1,'Text','','Interpreter','latex','FontSize',18),1,[1 2]);
ax1n = at(uiaxes(r1),2,1);
ax1b = at(uiaxes(r1),3,1);
ax1c = at(uiaxes(r1),[2 3],2);
[ax1n.Interactions, ax1b.Interactions, ax1c.Interactions] = deal([]);

dd1.ValueChangedFcn = @(~,~) loadPreset1();
[ef1.ValueChangedFcn, ef1k.ValueChangedFcn, dd1F.ValueChangedFcn, ef1M.ValueChangedFcn] = deal(@(~,~) markCustom(dd1,@update1));
cb1G.ValueChangedFcn = @(~,~) update1();
btn1.ButtonPushedFcn = @(~,~) update1();

%% =====================================================================
%  Tab 2: First-order synthesis
%  =====================================================================
t2 = uitab(tg,'Title','First-order design');
g2 = uigridlayout(t2,[1 2],'ColumnWidth',{340,'1x'});
c2 = uigridlayout(g2,[11 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{112,22,22,22,22,22,22,22,22,'1x',22});
at(uilabel(c2,'Text',['P(s) = a₀/(b₀ + b₁s) with G(s) = K gives T(s) = A_s/(1 + sT_c), ' ...
    'A_s = Ka₀/(Ka₀ + b₀), T_c = b₁/(Ka₀ + b₀). T_s ≈ 4T_c ≤ T_s,spec and e(∞) = b₀/(Ka₀ + b₀) ≤ e_spec ' ...
    'each give a lower bound on K; the smallest admissible K keeps the control action small. ' ...
    'Drag the K marker or the specification lines.'],'FontWeight','bold','WordWrap','on'),1,[1 2]);
% name, a0, b0, b1, Ts, ess, K
presets2 = { ...
    '11.4.3: P = 2/(1+2s), T_s ≤ 10, e ≤ 0.1',   2, 1, 2,   10, 0.1,  4.5
    'Same plant, T_s ≤ 1 s',                     2, 1, 2,   1,  0.1,  4.5
    'Slow plant: P = 1/(5+20s), T_s ≤ 4, e ≤ 0.05', 1, 5, 20, 4, 0.05, 20
    'Custom', [], [], [], [], [], []};
at(uilabel(c2,'Text','Example'),2,1);
dd2 = at(uidropdown(c2,'Items',presets2(:,1)','Value',presets2{1,1}),2,2);
labs2 = {'a₀','b₀','b₁','T_s spec (s)','e(∞) spec','Gain K'};
ef2 = gobjects(1,6);
for q = 1:6
    at(uilabel(c2,'Text',labs2{q}),2 + q,1);
    ef2(q) = at(uieditfield(c2,'numeric','Value',1,'ValueDisplayFormat','%.4g'),2 + q,2);
end
at(uilabel(c2,'Text','Results','FontWeight','bold'),9,[1 2]);
ta2 = at(uitextarea(c2,'Editable','off','FontName','Monospaced'),10,[1 2]);
btn2 = at(uibutton(c2,'Text','Update'),11,[1 2]);

r2 = uigridlayout(g2,[3 1],'RowHeight',{'fit','1x','1.2x'});
lbl2 = uilabel(r2,'Text','','Interpreter','latex','FontSize',18);
ax2k = uiaxes(r2);
ax2y = uiaxes(r2);
[ax2k.Interactions, ax2y.Interactions] = deal([]);

dd2.ValueChangedFcn = @(~,~) loadPreset2();
for q = 1:6, ef2(q).ValueChangedFcn = @(~,~) markCustom(dd2,@update2); end
btn2.ButtonPushedFcn = @(~,~) update2();

%% =====================================================================
%  Tab 3: Second-order reference models
%  =====================================================================
t3 = uitab(tg,'Title','Reference models');
g3 = uigridlayout(t3,[1 2],'ColumnWidth',{340,'1x'});
c3 = uigridlayout(g3,[10 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{112,22,22,22,22,22,22,22,'1x',22});
at(uilabel(c3,'Text',['Tracking: M_R(s) = ωₙ²/(s² + 2ζωₙs + ωₙ²) with ζ from %OS and ωₙ = 4/(ζT_s). ' ...
    'Disturbance rejection: M_D(s) = 2kζωₙs/(s² + 2ζωₙs + ωₙ²), usually ζ = 0.7071, with k from ' ...
    'the allowed peak y_p. Drag the %OS / y_p and T_s lines on the time response.'],'FontWeight','bold','WordWrap','on'),1,[1 2]);
% name, type, OS or yp, Ts, zeta (disturbance)
presets3 = { ...
    '11.4.4: tracking, T_s = 5 s, %OS = 25',     1, 25, 5, 0.7071
    'Tracking, T_s = 2 s, %OS = 5',              1, 5,  2, 0.7071
    '11.6: disturbance, y_p = 3, T_s = 5 s',     2, 3,  5, 0.7071
    'Disturbance, y_p = 1, T_s = 2 s, ζ = 0.5',  2, 1,  2, 0.5
    'Custom', [], [], [], []};
types3 = {'Tracking model M_R(s)','Disturbance model M_D(s)'};
at(uilabel(c3,'Text','Example'),2,1);
dd3 = at(uidropdown(c3,'Items',presets3(:,1)','Value',presets3{1,1}),2,2);
at(uilabel(c3,'Text','Model'),3,1);
dd3T = at(uidropdown(c3,'Items',types3),3,2);
lbl3a = at(uilabel(c3,'Text','%OS'),4,1);
ef3a = at(uieditfield(c3,'numeric','Value',25,'Limits',[1e-6 Inf],'ValueDisplayFormat','%.4g'),4,2);
at(uilabel(c3,'Text','T_s (s)'),5,1);
ef3T = at(uieditfield(c3,'numeric','Value',5,'Limits',[1e-6 Inf],'ValueDisplayFormat','%.4g'),5,2);
lbl3z = at(uilabel(c3,'Text','Damping ratio ζ'),6,1);
ef3z = at(uieditfield(c3,'numeric','Value',0.7071,'Limits',[0.05 0.99],'ValueDisplayFormat','%.4g'),6,2);
at(uilabel(c3,'Text','Results','FontWeight','bold'),8,[1 2]);
ta3 = at(uitextarea(c3,'Editable','off','FontName','Monospaced'),9,[1 2]);
btn3 = at(uibutton(c3,'Text','Update'),10,[1 2]);

r3 = uigridlayout(g3,[2 2],'RowHeight',{'fit','1x'},'ColumnWidth',{'1x','1x'});
lbl3 = at(uilabel(r3,'Text','','Interpreter','latex','FontSize',18),1,[1 2]);
ax3b = at(uiaxes(r3),2,1);
ax3y = at(uiaxes(r3),2,2);
[ax3b.Interactions, ax3y.Interactions] = deal([]);

dd3.ValueChangedFcn = @(~,~) loadPreset3();
[dd3T.ValueChangedFcn, ef3a.ValueChangedFcn, ef3T.ValueChangedFcn, ef3z.ValueChangedFcn] = deal(@(~,~) markCustom(dd3,@update3));
btn3.ButtonPushedFcn = @(~,~) update3();

%% =====================================================================
%  Tab 4: Setpoint tracking bounds
%  =====================================================================
t4 = uitab(tg,'Title','Tracking bounds');
g4 = uigridlayout(t4,[1 2],'ColumnWidth',{340,'1x'});
c4 = uigridlayout(g4,[10 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{112,22,22,22,22,22,22,22,'1x',22});
at(uilabel(c4,'Text',['Simplified bounds M_B ≤ |T(jω)| ≤ M_A: M_A = 1/(2ζ√(1−ζ²)) for all ω (overshoot), ' ...
    'M_B = 0.98 for ω ≤ ω_p = ωₙ√(1−2ζ²) (speed). In the log-polar plane L(jω) must stay out of ' ...
    'the blue region at all ω, and out of the green region up to ω_p (thick part of the locus). ' ...
    'Drag L(jω) to change k, or the %OS and T_s lines on the step response.'],'FontWeight','bold','WordWrap','on'),1,[1 2]);
% name, L0, k, OS, Ts
presets4 = { ...
    '11.5.2: L = 5/(s(s+2)), T_s = 5, %OS = 25',     '5/(s*(s+2))',              1,  25, 5
    '11.5.2: L = 10/(s(s+2)) (too much gain)',        '5/(s*(s+2))',              2,  25, 5
    'L = 1/(s(s+2)) (too slow)',                     '5/(s*(s+2))',              0.2, 25, 5
    'Lead loop, T_s = 2, %OS = 15: find a k that works', '20*(s+1)/(s*(s+2)*(0.1*s+1))', 1, 15, 2
    'Third order, %OS = 30, T_s = 10: too much gain', '2/(s*(s+1)*(0.5*s+1))', 0.6, 30, 10
    'Custom', '', [], [], []};
at(uilabel(c4,'Text','Example'),2,1);
dd4 = at(uidropdown(c4,'Items',presets4(:,1)','Value',presets4{1,1}),2,2);
at(uilabel(c4,'Text','L₀(s)'),3,1);
ef4 = at(uieditfield(c4,'text','Value',presets4{1,2}),3,2);
at(uilabel(c4,'Text','Gain k (L = kL₀)'),4,1);
ef4k = at(uieditfield(c4,'numeric','Value',1,'Limits',[1e-9 Inf],'ValueDisplayFormat','%.4g'),4,2);
at(uilabel(c4,'Text','%OS spec'),5,1);
ef4OS = at(uieditfield(c4,'numeric','Value',25,'Limits',[0.1 90],'ValueDisplayFormat','%.4g'),5,2);
at(uilabel(c4,'Text','T_s spec (s)'),6,1);
ef4Ts = at(uieditfield(c4,'numeric','Value',5,'Limits',[1e-3 Inf],'ValueDisplayFormat','%.4g'),6,2);
at(uilabel(c4,'Text','Results','FontWeight','bold'),8,[1 2]);
ta4 = at(uitextarea(c4,'Editable','off','FontName','Monospaced'),9,[1 2]);
btn4 = at(uibutton(c4,'Text','Update'),10,[1 2]);

r4 = uigridlayout(g4,[3 2],'RowHeight',{'fit','1x','1x'},'ColumnWidth',{'1.2x','1x'});
lbl4 = at(uilabel(r4,'Text','','Interpreter','latex','FontSize',17),1,[1 2]);
ax4c = at(uiaxes(r4),[2 3],1);
ax4b = at(uiaxes(r4),2,2);
ax4y = at(uiaxes(r4),3,2);
[ax4c.Interactions, ax4b.Interactions, ax4y.Interactions] = deal([]);

dd4.ValueChangedFcn = @(~,~) loadPreset4();
[ef4.ValueChangedFcn, ef4k.ValueChangedFcn, ef4OS.ValueChangedFcn, ef4Ts.ValueChangedFcn] = deal(@(~,~) markCustom(dd4,@update4));
btn4.ButtonPushedFcn = @(~,~) update4();

%% =====================================================================
%  Tab 5: Disturbance rejection bounds
%  =====================================================================
t5 = uitab(tg,'Title','Disturbance bounds');
g5 = uigridlayout(t5,[1 2],'ColumnWidth',{340,'1x'});
c5 = uigridlayout(g5,[12 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{112,22,22,22,22,22,22,22,22,22,'1x',22});
at(uilabel(c5,'Text',['Bound the disturbance response by a band-pass model: |P(jω)S(jω)| ≤ γ(ω), ' ...
    'i.e. |1 + L(jω)| ≥ |P(jω)|/γ(ω). Each frequency gets its own circle around −1 (log-polar ' ...
    'contour); L(jωᵢ) must lie outside the contour of the same colour. Drag L(jω) to change the ' ...
    'controller gain, or the y_p and T_s lines on the disturbance response.'],'FontWeight','bold','WordWrap','on'),1,[1 2]);
% name, P, G0, k, yp, Ts, zeta
presets5 = { ...
    '11.6: P = 5/(s+2), G = 0.2/s, y_p = 3, T_s = 5',  '5/(s+2)',   '1/s',          0.2, 3,   5, 0.7071
    'Same, higher gain G = 1/s',                       '5/(s+2)',   '1/s',          1,   3,   5, 0.7071
    'PI: G = 2(s+2)/s, y_p = 1, T_s = 2',              '5/(s+2)',   '(s+2)/s',      2,   1,   2, 0.7071
    'Slow plant: P = 1/(s+0.5)², G = 3(s+0.5)/s',      '1/(s+0.5)^2','(s+0.5)/s',   3,   1.5, 6, 0.7071
    'Custom', '', '', [], [], [], []};
at(uilabel(c5,'Text','Example'),2,1);
dd5 = at(uidropdown(c5,'Items',presets5(:,1)','Value',presets5{1,1}),2,2);
at(uilabel(c5,'Text','P(s)'),3,1);
ef5P = at(uieditfield(c5,'text','Value','5/(s+2)'),3,2);
at(uilabel(c5,'Text','G₀(s)'),4,1);
ef5G = at(uieditfield(c5,'text','Value','1/s'),4,2);
at(uilabel(c5,'Text','Gain k (G = kG₀)'),5,1);
ef5k = at(uieditfield(c5,'numeric','Value',0.2,'Limits',[1e-9 Inf],'ValueDisplayFormat','%.4g'),5,2);
at(uilabel(c5,'Text','Peak y_p (unit step d)'),6,1);
ef5yp = at(uieditfield(c5,'numeric','Value',3,'Limits',[1e-6 Inf],'ValueDisplayFormat','%.4g'),6,2);
at(uilabel(c5,'Text','T_s spec (s)'),7,1);
ef5Ts = at(uieditfield(c5,'numeric','Value',5,'Limits',[1e-3 Inf],'ValueDisplayFormat','%.4g'),7,2);
at(uilabel(c5,'Text','Damping ratio ζ'),8,1);
ef5z = at(uieditfield(c5,'numeric','Value',0.7071,'Limits',[0.05 0.99],'ValueDisplayFormat','%.4g'),8,2);
at(uilabel(c5,'Text','Results','FontWeight','bold'),10,[1 2]);
ta5 = at(uitextarea(c5,'Editable','off','FontName','Monospaced'),11,[1 2]);
btn5 = at(uibutton(c5,'Text','Update'),12,[1 2]);

r5 = uigridlayout(g5,[3 2],'RowHeight',{'fit','1x','1x'},'ColumnWidth',{'1.2x','1x'});
lbl5 = at(uilabel(r5,'Text','','Interpreter','latex','FontSize',17),1,[1 2]);
ax5c = at(uiaxes(r5),[2 3],1);
ax5b = at(uiaxes(r5),2,2);
ax5y = at(uiaxes(r5),3,2);
[ax5c.Interactions, ax5b.Interactions, ax5y.Interactions] = deal([]);

dd5.ValueChangedFcn = @(~,~) loadPreset5();
[ef5P.ValueChangedFcn, ef5G.ValueChangedFcn, ef5k.ValueChangedFcn, ef5yp.ValueChangedFcn, ...
    ef5Ts.ValueChangedFcn, ef5z.ValueChangedFcn] = deal(@(~,~) markCustom(dd5,@update5));
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

    function scaleField(ef,dd,ratio,v0,updFcn)
        % Drag a curve: scale a gain relative to its value at the start of the drag.
        if ~isfinite(ratio) || ratio <= 0, return, end
        ef.Value = max(v0*ratio,1e-9);
        dd.Value = 'Custom';
        updFcn();
    end

%% =====================================================================
%  Tab 1 callbacks
%  =====================================================================
    function loadPreset1()
        k = find(strcmp(presets1(:,1),dd1.Value));
        if isempty(presets1{k,3}), update1(); return, end
        ef1.Value = presets1{k,2};  ef1k.Value = presets1{k,3};
        dd1F.Value = funcs1{presets1{k,4}};  ef1M.Value = presets1{k,5};
        update1();
    end

    function update1()
        try
            L = ef1k.Value*parseTF(ef1.Value);
            isT = strcmp(dd1F.Value,funcs1{2});
            M = ef1M.Value;
            w = freqGrid(L,[]);
            [Lw,ph] = freqData(L,w);
            magDB = 20*log10(abs(Lw));
            Sw = 1./(1 + Lw);  Tw = Lw./(1 + Lw);
            if isT, Fw = abs(Tw); fname = 'T'; else, Fw = abs(Sw); fname = 'S'; end
            [Fmax,iMax] = max(Fw);
            above = Fw > M;
            sM = min(abs(1 + Lw));

            % Nyquist with M circles
            cla(ax1n); hold(ax1n,'on');
            if cb1G.Value
                for Mg = [0.5 0.7 1 1.5 2 3]
                    z = mContour(Mg,isT,'nyquist');
                    plot(ax1n,real(z),imag(z),':','Color',cGrey,'HitTest','off');
                end
            end
            z = mContour(M,isT,'nyquist');
            plot(ax1n,real(z),imag(z),'-','Color',cRed,'LineWidth',2,'HitTest','off');
            if ~isT
                plot(ax1n,[-1 real(Lw(iMax))],[0 imag(Lw(iMax))],'--','Color',cOrange,'LineWidth',1.5,'HitTest','off');
            end
            plot(ax1n,real(Lw),imag(Lw),'Color',cBlue,'LineWidth',2,'HitTest','off');
            plot(ax1n,real(Lw(above)),imag(Lw(above)),'.','Color',cRed,'MarkerSize',8,'HitTest','off');
            plot(ax1n,-1,0,'+','Color',cRed,'MarkerSize',12,'LineWidth',2,'HitTest','off');
            hold(ax1n,'off'); grid(ax1n,'on'); axis(ax1n,'equal');
            xlim(ax1n,[-3 1.5]); ylim(ax1n,[-2.5 1.5]);
            title(ax1n,sprintf('Nyquist: |%s| = %s circle (red dots: |%s| > M)',fname,num(M),fname));

            % Bode of |S| or |T| with draggable M line
            cla(ax1b); hold(ax1b,'on');
            plot(ax1b,w,20*log10(Fw),'Color',cBlue,'LineWidth',2.2,'HitTest','off');
            h = plot(ax1b,w([1 end]),20*log10(M)*[1 1],'-','Color',cRed,'LineWidth',3);
            draggable(h,ax1b,@(pt,~) setM1(10^(pt(2)/20)),@update1);
            plot(ax1b,w(iMax),20*log10(Fmax),'o','MarkerSize',9,'MarkerFaceColor',cOrange,'MarkerEdgeColor','k','HitTest','off');
            text(ax1b,w(iMax),20*log10(Fmax),sprintf('  |%s|_{max} = %s (%s dB)',fname,num(Fmax),num(20*log10(Fmax))), ...
                'Color',cOrange,'FontSize',12,'VerticalAlignment','bottom','HitTest','off');
            text(ax1b,w(1),20*log10(M),sprintf('  M = %s (%s dB): drag',num(M),num(20*log10(M))),'Color',cRed, ...
                'FontSize',12,'VerticalAlignment','bottom','HitTest','off');
            hold(ax1b,'off'); grid(ax1b,'on'); set(ax1b,'XScale','log'); xlim(ax1b,w([1 end]));
            yl = [max(min(20*log10(Fw)),-40) max([20*log10(Fw); 20*log10(M)]) + 4];
            ylim(ax1b,yl);
            title(ax1b,sprintf('|%s(jω)|',fname)); xlabel(ax1b,'ω (rad/s)'); ylabel(ax1b,'dB');

            % Log-polar chart
            cla(ax1c); hold(ax1c,'on');
            [phLo,phHi] = phaseWindow(ph);
            if cb1G.Value
                for Mg = [0.5 0.7 1 1.5 2 3]
                    [cx,cy] = logPolarContour(Mg,isT,phLo,phHi);
                    plot(ax1c,cx,cy,':','Color',cGrey,'HitTest','off');
                    [~,j] = max(cy);
                    if ~isempty(j), text(ax1c,cx(j),cy(j),sprintf('%g',Mg),'Color',cGrey,'FontSize',10,'HitTest','off'); end
                end
            end
            [cx,cy] = logPolarContour(M,isT,phLo,phHi);
            plot(ax1c,cx,cy,'-','Color',cRed,'LineWidth',2.2,'HitTest','off');
            h = plot(ax1c,ph,magDB,'Color',cBlue,'LineWidth',2.2);
            draggable(h,ax1c,@(pt,p0) scaleField(ef1k,dd1,10^((pt(2) - p0(2))/20),ef1k.Value,@update1),@update1);
            plot(ax1c,ph(above),magDB(above),'.','Color',cRed,'MarkerSize',8,'HitTest','off');
            critical(ax1c,phLo,phHi);
            hold(ax1c,'off'); grid(ax1c,'on');
            xlim(ax1c,[phLo phHi]); ylim(ax1c,[-40 40]);
            if isT, nm = 'Nichols chart'; else, nm = 'Inverse Nichols chart'; end
            title(ax1c,sprintf('%s: |%s| = %s contour (drag L(jω) to change k)',nm,fname,num(M)));
            xlabel(ax1c,'∠L(jω) (deg)'); ylabel(ax1c,'|L(jω)| (dB)');

            if isT
                lbl1.Text = sprintf(['$|T(j\\omega)|=\\left|\\frac{L}{1+L}\\right|=M=%s,\\quad |T|_{max}=%s\\ (%s\\,\\mathrm{dB})' ...
                    ',\\quad \\mathrm{at}\\ \\omega=%s$'],num(M),num(Fmax),num(20*log10(Fmax)),num(w(iMax)));
            else
                lbl1.Text = sprintf(['$|S(j\\omega)|=\\frac{1}{|1+L(j\\omega)|}=M\\iff|L+1|=\\frac{1}{M}=%s,\\quad ' ...
                    '|S|_{max}=%s=\\frac{1}{s_M},\\ s_M=\\min|1+L|=%s$'],num(1/M),num(Fmax),num(sM));
            end

            txt = {sprintf('max |%s(jw)| = %s (%s dB) at w = %s',fname,num(Fmax),num(20*log10(Fmax)),num(w(iMax))); ...
                sprintf('Stability margin s_M = min|1+L| = %s',num(sM)); ...
                sprintf('1/|S|max = %s',num(1/max(abs(Sw)))); ''};
            if any(above)
                wa = w(above);
                txt{end+1} = sprintf('|%s| > M = %s for w in [%s, %s]',fname,num(M),num(wa(1)),num(wa(end)));
                txt{end+1} = '(L(jw) is inside the contour there)';
            else
                txt{end+1} = sprintf('|%s| never exceeds M = %s',fname,num(M));
                txt{end+1} = '(L(jw) stays outside the contour)';
            end
            ta1.Value = txt(:);
        catch err
            showError(ta1,err);
        end
    end

    function setM1(M)
        ef1M.Value = min(max(M,0.05),50);
        dd1.Value = 'Custom';
        update1();
    end

%% =====================================================================
%  Tab 2 callbacks
%  =====================================================================
    function loadPreset2()
        k = find(strcmp(presets2(:,1),dd2.Value));
        if isempty(presets2{k,2}), update2(); return, end
        for q = 1:6, ef2(q).Value = presets2{k,1+q}; end
        update2();
    end

    function update2()
        try
            a0 = ef2(1).Value;  b0 = ef2(2).Value;  b1 = ef2(3).Value;
            TsSpec = ef2(4).Value;  eSpec = ef2(5).Value;  K = ef2(6).Value;
            if a0 <= 0 || b1 <= 0, error('Use a0 > 0 and b1 > 0.'); end
            Kts = (4*b1/TsSpec - b0)/a0;                 % 4 b1/(K a0 + b0) <= Ts
            Kss = (b0/eSpec - b0)/a0;                    % b0/(K a0 + b0) <= e
            Kmin = max([Kts Kss 0]);
            As = K*a0/(K*a0 + b0);  Tc = b1/(K*a0 + b0);  einf = b0/(K*a0 + b0);
            okTs = 4*Tc <= TsSpec*(1 + 1e-9);  okE = einf <= eSpec*(1 + 1e-9);

            lbl2.Text = sprintf(['$T(s)=\\frac{Ka_0}{Ka_0+b_0+b_1s}=\\frac{%s}{%s},\\quad A_s=%s,\\ T_c=%s,\\quad ' ...
                '4T_c\\le T_s\\Rightarrow K\\ge%s,\\quad e(\\infty)\\le%s\\Rightarrow K\\ge%s$'], ...
                num(K*a0),polyTex([b1 K*a0 + b0]),num(As),num(Tc),num(Kts),num(eSpec),num(Kss));

            % Constraint plot against K
            Kmax = max([3*Kmin, 2*K, 1]);
            Kg = linspace(0,Kmax,600);
            cla(ax2k); hold(ax2k,'on');
            yyaxis(ax2k,'left'); cla(ax2k);
            plot(ax2k,Kg,4*b1./(Kg*a0 + b0),'-','Color',cBlue,'LineWidth',2,'HitTest','off');
            plot(ax2k,[0 Kmax],[TsSpec TsSpec],'--','Color',cBlue,'LineWidth',1.5,'HitTest','off');
            ylabel(ax2k,'settling time 4T_c (s)'); ax2k.YColor = cBlue;
            ylim(ax2k,[0 max(4*b1/b0,TsSpec)*1.1]);
            yyaxis(ax2k,'right'); cla(ax2k);
            plot(ax2k,Kg,b0./(Kg*a0 + b0),'-','Color',cOrange,'LineWidth',2,'HitTest','off');
            plot(ax2k,[0 Kmax],[eSpec eSpec],'--','Color',cOrange,'LineWidth',1.5,'HitTest','off');
            ylabel(ax2k,'e(∞) for a unit step'); ax2k.YColor = cOrange;
            ylim(ax2k,[0 1.05]);
            yyaxis(ax2k,'left');
            yl = ax2k.YLim;
            patch(ax2k,[0 Kmin Kmin 0],yl([1 1 2 2]),[1 0.88 0.88],'EdgeColor','none','FaceAlpha',0.6,'HitTest','off');
            h = plot(ax2k,[K K],yl,'-','Color',cRed,'LineWidth',3);
            draggable(h,ax2k,@(pt,~) setK2(pt(1)),@update2);
            text(ax2k,K,yl(2),sprintf('  K = %s',num(K)),'Color',cRed,'FontSize',13,'VerticalAlignment','top','HitTest','off');
            text(ax2k,Kmin,yl(1) + 0.05*diff(yl),sprintf('  K_{min} = %s',num(Kmin)),'Color',[0.6 0 0],'FontSize',12,'HitTest','off');
            hold(ax2k,'off'); grid(ax2k,'on'); xlim(ax2k,[0 Kmax]);
            title(ax2k,'Constraints on K (shaded: not admissible). Drag the red line.'); xlabel(ax2k,'K');

            % Step response
            T = tf(K*a0,[b1 K*a0 + b0]);
            tEnd = max(1.5*TsSpec,6*Tc);
            t = linspace(0,tEnd,1000)';
            y = step(T,t);
            cla(ax2y); hold(ax2y,'on');
            plot(ax2y,[0 tEnd],[1 1],'k--','LineWidth',1.2,'DisplayName','r(t)');
            patch(ax2y,[0 tEnd tEnd 0],[1-eSpec 1-eSpec 1 1],[0.88 0.96 0.85],'EdgeColor','none','FaceAlpha',0.7, ...
                'HitTest','off','DisplayName','allowed e(∞)');
            h = plot(ax2y,[0 tEnd],(1 - eSpec)*[1 1],'-','Color',cOrange,'LineWidth',2.5,'DisplayName',sprintf('1 − e_{spec} (drag)'));
            draggable(h,ax2y,@(pt,~) setE2(1 - pt(2)),@update2);
            h = plot(ax2y,[TsSpec TsSpec],[0 1.1],'-','Color',cBlue,'LineWidth',2.5,'DisplayName','T_s spec (drag)');
            draggable(h,ax2y,@(pt,~) setTs2(pt(1)),@update2);
            plot(ax2y,t,y,'Color',cRed,'LineWidth',2.5,'DisplayName','y(t)');
            plot(ax2y,4*Tc,0.98*As,'o','MarkerSize',9,'MarkerFaceColor',cRed,'MarkerEdgeColor','k','DisplayName','4T_c');
            hold(ax2y,'off'); grid(ax2y,'on'); xlim(ax2y,[0 tEnd]); ylim(ax2y,[0 1.15]);
            showLegend(ax2y,'southeast');
            title(ax2y,sprintf('Closed-loop step response: settling %s, error %s',mark(okTs),mark(okE)));
            xlabel(ax2y,'t (s)');

            txt = {sprintf('Settling: 4*b1/(K a0 + b0) <= %s',num(TsSpec)); ...
                sprintf('   -> K >= %s',num(Kts)); ...
                sprintf('Error:    b0/(K a0 + b0) <= %s',num(eSpec)); ...
                sprintf('   -> K >= %s',num(Kss)); ...
                sprintf('Admissible: K >= %s',num(Kmin)); ''; ...
                sprintf('With K = %s:',num(K)); ...
                sprintf('  T_s ~ 4T_c = %s s %s',num(4*Tc),mark(okTs)); ...
                sprintf('  e(inf) = %s %s',num(einf),mark(okE)); ...
                sprintf('  u(0+) = K = %s (control action)',num(K)); ''; ...
                'One parameter cannot meet both specs with'; ...
                'equality: one of them is over-designed.'};
            ta2.Value = txt(:);
        catch err
            showError(ta2,err);
        end
    end

    function setK2(K)
        ef2(6).Value = max(K,0);  dd2.Value = 'Custom';  update2();
    end
    function setE2(e)
        ef2(5).Value = min(max(e,1e-3),0.99);  dd2.Value = 'Custom';  update2();
    end
    function setTs2(T)
        ef2(4).Value = max(T,1e-3);  dd2.Value = 'Custom';  update2();
    end

%% =====================================================================
%  Tab 3 callbacks
%  =====================================================================
    function loadPreset3()
        k = find(strcmp(presets3(:,1),dd3.Value));
        if isempty(presets3{k,2}), update3(); return, end
        dd3T.Value = types3{presets3{k,2}};
        [ef3a.Value, ef3T.Value, ef3z.Value] = presets3{k,3:5};
        update3();
    end

    function update3()
        try
            dist = strcmp(dd3T.Value,types3{2});
            set([lbl3z ef3z],'Visible',onoff(dist));
            Ts = ef3T.Value;
            s = tf('s');
            if dist
                lbl3a.Text = 'Peak y_p';
                zeta = ef3z.Value;  yp = ef3a.Value;
                wn = 4/(zeta*Ts);
                k = yp/(2*zeta*exp(-zeta*acos(zeta)/sqrt(1 - zeta^2)));
                Mm = k*2*zeta*wn*s/(s^2 + 2*zeta*wn*s + wn^2);
                tp = acos(zeta)/(wn*sqrt(1 - zeta^2));
                lbl3.Text = sprintf(['$M_D(s)=\\frac{2k\\zeta\\omega_ns}{s^2+2\\zeta\\omega_ns+\\omega_n^2}=\\frac{%ss}{%s},\\quad ' ...
                    'k=\\frac{y_p}{2\\zeta}e^{\\zeta\\cos^{-1}\\zeta/\\sqrt{1-\\zeta^2}}=%s,\\ \\omega_n=\\frac{4}{\\zeta T_s}=%s$'], ...
                    num(2*k*zeta*wn),polyTex([1 2*zeta*wn wn^2]),num(k),num(wn));
            else
                lbl3a.Text = '%OS';
                OS = ef3a.Value;
                if OS >= 100, error('%%OS must be below 100.'); end
                zeta = zetaFromOS(OS);  wn = 4/(zeta*Ts);
                Mm = wn^2/(s^2 + 2*zeta*wn*s + wn^2);
                MA = 1/(2*zeta*sqrt(1 - zeta^2));  wp = wn*sqrt(max(1 - 2*zeta^2,0));
                lbl3.Text = sprintf(['$M_R(s)=\\frac{\\omega_n^2}{s^2+2\\zeta\\omega_ns+\\omega_n^2}=\\frac{%s}{%s},\\quad ' ...
                    '\\zeta=%s,\\ \\omega_n=\\frac{4}{\\zeta T_s}=%s,\\ M_A=%s,\\ \\omega_p=%s$'], ...
                    num(wn^2),polyTex([1 2*zeta*wn wn^2]),num(zeta),num(wn),num(MA),num(wp));
            end
            w = logspace(log10(wn) - 2,log10(wn) + 2,800)';
            mag = 20*log10(abs(squeeze(freqresp(Mm,w))));
            cla(ax3b); hold(ax3b,'on');
            plot(ax3b,w,mag,'Color',cBlue,'LineWidth',2.5,'HitTest','off');
            if ~dist && zeta < 1/sqrt(2)
                plot(ax3b,w([1 end]),20*log10(MA)*[1 1],'--','Color',cBlue,'HitTest','off');
                plot(ax3b,wp,20*log10(MA),'o','MarkerFaceColor',cRed,'MarkerEdgeColor','k','MarkerSize',9,'HitTest','off');
                text(ax3b,wp,20*log10(MA),sprintf('  M_A = %s at ω_p = %s',num(MA),num(wp)),'FontSize',12, ...
                    'VerticalAlignment','bottom','HitTest','off');
            elseif dist
                plot(ax3b,wn,20*log10(k),'o','MarkerFaceColor',cRed,'MarkerEdgeColor','k','MarkerSize',9,'HitTest','off');
                text(ax3b,wn,20*log10(k),sprintf('  peak |k| = %s at ωₙ',num(k)),'FontSize',12,'VerticalAlignment','bottom','HitTest','off');
            end
            hold(ax3b,'off'); grid(ax3b,'on'); set(ax3b,'XScale','log'); xlim(ax3b,w([1 end]));
            title(ax3b,'Bode magnitude of the reference model'); xlabel(ax3b,'ω (rad/s)'); ylabel(ax3b,'dB');

            tEnd = 1.6*Ts;
            t = linspace(0,tEnd,1500)';
            y = step(Mm,t);
            cla(ax3y); hold(ax3y,'on');
            if dist
                h = plot(ax3y,[0 tEnd],[yp yp],'-','Color',cOrange,'LineWidth',2.5);
                draggable(h,ax3y,@(pt,~) setA3(pt(2)),@update3);
                patch(ax3y,[0 tEnd tEnd 0],0.02*yp*[-1 -1 1 1],[0.88 0.96 0.85],'EdgeColor','none','HitTest','off');
                text(ax3y,tEnd,yp,sprintf('y_p = %s  ',num(yp)),'Color',cOrange,'HorizontalAlignment','right', ...
                    'VerticalAlignment','bottom','FontSize',12,'HitTest','off');
                plot(ax3y,tp,yp,'o','MarkerFaceColor',cRed,'MarkerEdgeColor','k','MarkerSize',9,'HitTest','off');
                ttl = 'Response to a unit step disturbance (green: ±2% of y_p)';
            else
                h = plot(ax3y,[0 tEnd],(1 + OS/100)*[1 1],'-','Color',cOrange,'LineWidth',2.5);
                draggable(h,ax3y,@(pt,~) setA3(100*(pt(2) - 1)),@update3);
                patch(ax3y,[0 tEnd tEnd 0],[0.98 0.98 1.02 1.02],[0.88 0.96 0.85],'EdgeColor','none','HitTest','off');
                text(ax3y,tEnd,1 + OS/100,sprintf('%%OS = %s  ',num(OS)),'Color',cOrange,'HorizontalAlignment','right', ...
                    'VerticalAlignment','bottom','FontSize',12,'HitTest','off');
                ttl = 'Unit step response (green: ±2% band)';
            end
            h = plot(ax3y,[Ts Ts],[min([y; 0]) max([y; 1.1])],'-','Color',cBlue,'LineWidth',2.5);
            draggable(h,ax3y,@(pt,~) setT3(pt(1)),@update3);
            text(ax3y,Ts,0,sprintf('  T_s = %s',num(Ts)),'Color',cBlue,'FontSize',12,'VerticalAlignment','bottom','HitTest','off');
            plot(ax3y,t,y,'Color',cRed,'LineWidth',2.5,'HitTest','off');
            hold(ax3y,'off'); grid(ax3y,'on'); xlim(ax3y,[0 tEnd]);
            title(ax3y,ttl); xlabel(ax3y,'t (s)');

            if dist
                txt = {sprintf('zeta = %s, wn = 4/(zeta Ts) = %s',num(zeta),num(wn)); ...
                    sprintf('k = %s',num(k)); ...
                    sprintf('Peak %s at t_p = %s s',num(max(y)),num(tp)); ...
                    sprintf('Time to stay within 2%% of y_p: %s s',num(lastOutside(t,y,0.02*yp)))};
            else
                S = stepinfo(Mm);
                txt = {sprintf('zeta = %s, wn = %s',num(zeta),num(wn)); ...
                    sprintf('M_A = 1/(2 zeta sqrt(1-zeta^2)) = %s',num(MA)); ...
                    sprintf('        = %s dB',num(20*log10(MA))); ...
                    sprintf('w_p = wn sqrt(1-2zeta^2) = %s',num(wp)); ''; ...
                    sprintf('Step: %%OS %s, T_s (2%%) %s s',num(S.Overshoot),num(S.SettlingTime)); ...
                    '(4/(zeta wn) is an approximation)'};
            end
            ta3.Value = txt(:);
        catch err
            showError(ta3,err);
        end
    end

    function setA3(v)
        ef3a.Value = min(max(v,0.1),89);  dd3.Value = 'Custom';  update3();
    end
    function setT3(T)
        ef3T.Value = max(T,1e-3);  dd3.Value = 'Custom';  update3();
    end

%% =====================================================================
%  Tab 4 callbacks
%  =====================================================================
    function loadPreset4()
        k = find(strcmp(presets4(:,1),dd4.Value));
        if isempty(presets4{k,3}), update4(); return, end
        ef4.Value = presets4{k,2};
        [ef4k.Value, ef4OS.Value, ef4Ts.Value] = presets4{k,3:5};
        update4();
    end

    function update4()
        try
            L = ef4k.Value*parseTF(ef4.Value);
            OS = ef4OS.Value;  Ts = ef4Ts.Value;
            zeta = zetaFromOS(OS);  wn = 4/(zeta*Ts);
            MA = 1/(2*zeta*sqrt(1 - zeta^2));  MB = 0.98;
            if zeta >= 1/sqrt(2), error('This %%OS gives zeta >= 0.707: M_R has no peak (choose a larger %%OS).'); end
            wp = wn*sqrt(1 - 2*zeta^2);
            w = freqGrid(L,wp);
            [Lw,ph] = freqData(L,w);
            magDB = 20*log10(abs(Lw));
            Tw = abs(Lw./(1 + Lw));
            low = w <= wp;
            okA = all(Tw <= MA*(1 + 1e-6));
            okB = all(Tw(low) >= MB*(1 - 1e-6));
            [~,ip] = min(abs(w - wp));

            lbl4.Text = sprintf(['$\\zeta=%s,\\ \\omega_n=%s,\\quad M_A=\\frac{1}{2\\zeta\\sqrt{1-\\zeta^2}}=%s\\ (%s\\,\\mathrm{dB}),' ...
                '\\quad M_B=0.98\\ (-0.18\\,\\mathrm{dB})\\ \\mathrm{for}\\ \\omega\\le\\omega_p=%s$'], ...
                num(zeta),num(wn),num(MA),num(20*log10(MA)),num(wp));

            % Log-polar with shaded stay-out regions
            [phLo,phHi] = phaseWindow(ph);
            cla(ax4c); hold(ax4c,'on');
            shadeRegions(ax4c,phLo,phHi,[-40 40],@(Lc) abs(Lc./(1 + Lc)) > MA,[0.3 0.5 1]);
            shadeRegions(ax4c,phLo,phHi,[-40 40],@(Lc) abs(Lc./(1 + Lc)) < MB,[0.4 0.85 0.3]);
            [cx,cy] = logPolarContour(MA,true,phLo,phHi);
            plot(ax4c,cx,cy,'--','Color',[0.1 0.3 0.9],'LineWidth',2,'HitTest','off');
            [cx,cy] = logPolarContour(MB,true,phLo,phHi);
            plot(ax4c,cx,cy,'-','Color',[0.2 0.6 0.1],'LineWidth',2,'HitTest','off');
            h = plot(ax4c,ph,magDB,'Color',[0.2 0.2 0.2],'LineWidth',1.5);
            draggable(h,ax4c,@(pt,p0) scaleField(ef4k,dd4,10^((pt(2) - p0(2))/20),ef4k.Value,@update4),@update4);
            h = plot(ax4c,ph(low),magDB(low),'Color',cRed,'LineWidth',4);
            draggable(h,ax4c,@(pt,p0) scaleField(ef4k,dd4,10^((pt(2) - p0(2))/20),ef4k.Value,@update4),@update4);
            plot(ax4c,ph(ip),magDB(ip),'o','MarkerSize',10,'MarkerFaceColor',cRed,'MarkerEdgeColor','k','HitTest','off');
            text(ax4c,ph(ip),magDB(ip),'  L(jω_p)','FontSize',13,'HitTest','off');
            critical(ax4c,phLo,phHi);
            hold(ax4c,'off'); grid(ax4c,'on'); xlim(ax4c,[phLo phHi]); ylim(ax4c,[-40 40]);
            title(ax4c,sprintf('Stay out of blue (|T| > M_A) %s and green for ω ≤ ω_p (|T| < M_B) %s',mark(okA),mark(okB)));
            xlabel(ax4c,'∠L(jω) (deg)'); ylabel(ax4c,'|L(jω)| (dB)');

            % Bode of |T| with the Fig 11.6 bounds
            s = tf('s');
            MR = wn^2/(s^2 + 2*zeta*wn*s + wn^2);
            cla(ax4b); hold(ax4b,'on');
            plot(ax4b,w,20*log10(abs(squeeze(freqresp(MR,w)))),':','Color',cGrey,'LineWidth',1.5,'DisplayName','|M_R(jω)|');
            plot(ax4b,w([1 end]),20*log10(MA)*[1 1],'--','Color',[0.1 0.3 0.9],'LineWidth',2,'DisplayName','M_A');
            plot(ax4b,[w(1) wp wp],[20*log10(MB) 20*log10(MB) -20],'-','Color',[0.2 0.6 0.1],'LineWidth',2,'DisplayName','M_B (ω ≤ ω_p)');
            plot(ax4b,w,20*log10(Tw),'Color',cRed,'LineWidth',2.5,'DisplayName','|T(jω)|');
            hold(ax4b,'off'); grid(ax4b,'on'); set(ax4b,'XScale','log'); xlim(ax4b,w([1 end]));
            ylim(ax4b,[max(min(20*log10(Tw)),-30) max(max(20*log10(Tw)),20*log10(MA)) + 3]);
            showLegend(ax4b,'southwest');
            title(ax4b,'|T(jω)| and the simplified bounds (Fig 11.6)'); xlabel(ax4b,'ω (rad/s)'); ylabel(ax4b,'dB');

            % Step response check
            T = feedback(L,1);
            clStable = all(real(pole(T)) < -1e-9);
            cla(ax4y); hold(ax4y,'on');
            tEnd = 1.6*Ts;
            if clStable
                t = linspace(0,tEnd,2000)';
                y = step(T,t);
                S = stepinfo(y,t,1);
                patch(ax4y,[Ts tEnd tEnd Ts],[0.98 0.98 1.02 1.02],[0.88 0.96 0.85],'EdgeColor','none','HitTest','off');
                h = plot(ax4y,[0 tEnd],(1 + OS/100)*[1 1],'-','Color',cOrange,'LineWidth',2.5);
                draggable(h,ax4y,@(pt,~) setOS4(100*(pt(2) - 1)),@update4);
                h = plot(ax4y,[Ts Ts],[0 1.1 + OS/100],'-','Color',cBlue,'LineWidth',2.5);
                draggable(h,ax4y,@(pt,~) setTs4(pt(1)),@update4);
                plot(ax4y,t,step(MR,t),':','Color',cGrey,'LineWidth',1.5,'HitTest','off');
                plot(ax4y,t,y,'Color',cRed,'LineWidth',2.5,'HitTest','off');
                okOS = S.Overshoot <= OS + 1e-6;  okTs = S.SettlingTime <= Ts;
                title(ax4y,sprintf('Step: %%OS = %s %s, T_s = %s s %s (drag the spec lines)',num(S.Overshoot),mark(okOS), ...
                    num(S.SettlingTime),mark(okTs)));
                xlim(ax4y,[0 tEnd]); ylim(ax4y,[0 max(1.15 + OS/100,max(y) + 0.05)]);
            else
                okOS = false;  okTs = false;  S = struct('Overshoot',NaN,'SettlingTime',NaN);
                title(ax4y,'Closed loop unstable');
            end
            hold(ax4y,'off'); grid(ax4y,'on'); xlabel(ax4y,'t (s)');

            txt = {sprintf('zeta = %s, wn = %s rad/s',num(zeta),num(wn)); ...
                sprintf('M_A = %s, M_B = 0.98, w_p = %s',num(MA),num(wp)); ''; ...
                sprintf('max |T| = %s  (<= M_A: %s)',num(max(Tw)),mark(okA)); ...
                sprintf('min |T| for w <= w_p = %s  (>= M_B: %s)',num(min(Tw(low))),mark(okB)); ''; ...
                sprintf('Step: %%OS = %s %s',num(S.Overshoot),mark(okOS)); ...
                sprintf('      T_s = %s s %s',num(S.SettlingTime),mark(okTs))};
            if (okA && okB) ~= (okOS && okTs)
                txt = [txt; {''; 'The frequency bounds and the time response'; ...
                    'disagree here: the simplified bounds are a'; 'guide, not a guarantee. Always check the'; 'step response.'}];
            end
            ta4.Value = txt(:);
        catch err
            showError(ta4,err);
        end
    end

    function setOS4(v)
        ef4OS.Value = min(max(v,0.5),60);  dd4.Value = 'Custom';  update4();
    end
    function setTs4(T)
        ef4Ts.Value = max(T,1e-3);  dd4.Value = 'Custom';  update4();
    end

%% =====================================================================
%  Tab 5 callbacks
%  =====================================================================
    function loadPreset5()
        k = find(strcmp(presets5(:,1),dd5.Value));
        if isempty(presets5{k,4}), update5(); return, end
        ef5P.Value = presets5{k,2};  ef5G.Value = presets5{k,3};
        [ef5k.Value, ef5yp.Value, ef5Ts.Value, ef5z.Value] = presets5{k,4:7};
        update5();
    end

    function update5()
        try
            P = parseTF(ef5P.Value);  G = ef5k.Value*parseTF(ef5G.Value);
            L = P*G;
            zeta = ef5z.Value;  yp = ef5yp.Value;  Ts = ef5Ts.Value;
            wn = 4/(Ts*zeta);
            kk = yp/(2*zeta*exp(-zeta*acos(zeta)/sqrt(1 - zeta^2)));
            s = tf('s');
            gam = kk*2*zeta*wn*s/(s^2 + 2*zeta*wn*s + wn^2);
            wi = wn*[0.1 0.3 1 3 10];
            w = freqGrid(L,wi);
            [Lw,ph] = freqData(L,w);
            magDB = 20*log10(abs(Lw));
            Pw = abs(squeeze(freqresp(P,w)));  gw = abs(squeeze(freqresp(gam,w)));
            PSw = Pw./abs(1 + Lw);
            ratio = PSw./gw;
            okF = all(ratio <= 1 + 1e-6);

            lbl5.Text = sprintf(['$\\gamma(s)=\\frac{2k\\zeta\\omega_ns}{s^2+2\\zeta\\omega_ns+\\omega_n^2},\\ k=%s,\\ \\omega_n=%s,' ...
                '\\quad |P(j\\omega)S(j\\omega)|\\le\\gamma(\\omega)\\iff|1+L(j\\omega)|\\ge\\frac{|P(j\\omega)|}{\\gamma(\\omega)}$'], ...
                num(kk),num(wn));

            % Log-polar: one stay-out contour per frequency
            [phLo,phHi] = phaseWindow(ph);
            cols = [0.20 0.40 0.90; 0.10 0.65 0.75; 0.30 0.65 0.20; 0.90 0.55 0.10; 0.85 0.15 0.15];
            cla(ax5c); hold(ax5c,'on');
            h = plot(ax5c,ph,magDB,'Color',[0.2 0.2 0.2],'LineWidth',2);
            draggable(h,ax5c,@(pt,p0) scaleField(ef5k,dd5,10^((pt(2) - p0(2))/20),ef5k.Value,@update5),@update5);
            okI = true(1,numel(wi));
            for q = 1:numel(wi)
                [~,iq] = min(abs(w - wi(q)));
                Mq = gw(iq)/Pw(iq);                    % |1 + L| >= 1/Mq: a sensitivity-type contour
                [cx,cy] = logPolarContour(Mq,false,phLo,phHi);
                plot(ax5c,cx,cy,'--','Color',cols(q,:),'LineWidth',2,'HitTest','off');
                okI(q) = abs(1 + Lw(iq)) >= 1/Mq*(1 - 1e-6);
                plot(ax5c,ph(iq),magDB(iq),'o','MarkerSize',10,'MarkerFaceColor',cols(q,:),'MarkerEdgeColor','k','HitTest','off');
                text(ax5c,ph(iq),magDB(iq),sprintf('  ω = %s %s',num(wi(q)),mark(okI(q))),'Color',cols(q,:)*0.8, ...
                    'FontSize',12,'FontWeight','bold','HitTest','off');
            end
            critical(ax5c,phLo,phHi);
            hold(ax5c,'off'); grid(ax5c,'on'); xlim(ax5c,[phLo phHi]); ylim(ax5c,[-40 40]);
            title(ax5c,'Each L(jωᵢ) must lie outside the contour of its own colour (drag L to change the gain)');
            xlabel(ax5c,'∠L(jω) (deg)'); ylabel(ax5c,'|L(jω)| (dB)');

            cla(ax5b); hold(ax5b,'on');
            plot(ax5b,w,20*log10(gw),'--','Color',[0.2 0.2 0.2],'LineWidth',2,'DisplayName','γ(ω)');
            plot(ax5b,w,20*log10(PSw),'Color',cRed,'LineWidth',2.5,'DisplayName','|P(jω)S(jω)|');
            for q = 1:numel(wi)
                [~,iq] = min(abs(w - wi(q)));
                plot(ax5b,wi(q),20*log10(PSw(iq)),'o','MarkerFaceColor',cols(q,:),'MarkerEdgeColor','k','MarkerSize',8,'HitTest','off');
            end
            hold(ax5b,'off'); grid(ax5b,'on'); set(ax5b,'XScale','log'); xlim(ax5b,w([1 end]));
            yl = [min(20*log10([PSw; gw])) max(20*log10([PSw; gw])) + 5];
            ylim(ax5b,[max(yl(1),yl(2) - 70) yl(2)]);
            showLegend(ax5b,'southwest');
            title(ax5b,sprintf('|PS(jω)| ≤ γ(ω) %s',mark(okF))); xlabel(ax5b,'ω (rad/s)'); ylabel(ax5b,'dB');

            % Time-domain check: y(t) for a unit step disturbance
            PS = feedback(P,G);
            clStable = all(real(pole(PS)) < -1e-9);
            cla(ax5y); hold(ax5y,'on');
            tEnd = 2*Ts;
            if clStable
                t = linspace(0,tEnd,2000)';
                y = step(PS,t);  yg = step(gam,t);
                patch(ax5y,[Ts tEnd tEnd Ts],0.02*yp*[-1 -1 1 1],[0.88 0.96 0.85],'EdgeColor','none','HitTest','off');
                h = plot(ax5y,[0 tEnd],[yp yp],'-','Color',cOrange,'LineWidth',2.5);
                draggable(h,ax5y,@(pt,~) setYp5(pt(2)),@update5);
                h = plot(ax5y,[Ts Ts],[min([y; 0]) max([y; yp])*1.1],'-','Color',cBlue,'LineWidth',2.5);
                draggable(h,ax5y,@(pt,~) setTs5(pt(1)),@update5);
                plot(ax5y,t,yg,':','Color',[0.2 0.2 0.2],'LineWidth',1.5,'HitTest','off');
                plot(ax5y,t,y,'Color',cRed,'LineWidth',2.5,'HitTest','off');
                ypk = max(abs(y));  tset = lastOutside(t,y,0.02*yp);
                okP = ypk <= yp;  okT = tset <= Ts;
                title(ax5y,sprintf('Unit step d: peak %s %s, within 2%% of y_p after %s s %s',num(ypk),mark(okP),num(tset),mark(okT)));
                xlim(ax5y,[0 tEnd]);
            else
                okP = false;  okT = false;  ypk = NaN;  tset = NaN;
                title(ax5y,'Closed loop unstable');
            end
            hold(ax5y,'off'); grid(ax5y,'on'); xlabel(ax5y,'t (s)');

            txt = {sprintf('zeta = %s, wn = 4/(Ts zeta) = %s',num(zeta),num(wn)); ...
                sprintf('k = %s (peak of the model = y_p)',num(kk)); ''; ...
                sprintf('max |PS|/gamma = %s %s',num(max(ratio)),mark(okF))};
            for q = 1:numel(wi)
                txt{end+1} = sprintf('  w = %-7s |1+L| = %-7s >= %-7s %s',num(wi(q)), ...
                    num(abs(1 + Lw(find(w >= wi(q),1)))),num(Pw(find(w >= wi(q),1))/gw(find(w >= wi(q),1))),mark(okI(q))); %#ok<AGROW>
            end
            txt = [txt(:); {''; sprintf('Time domain: peak %s %s',num(ypk),mark(okP)); ...
                sprintf('  within 2%% of y_p after %s s %s',num(tset),mark(okT))}];
            if okF && ~(okP && okT)
                txt = [txt; {''; 'The frequency bound holds, but the time'; ...
                    'spec does not: the band-pass bound is only'; 'a guide. Check the time response.'}];
            end
            ta5.Value = txt(:);
        catch err
            showError(ta5,err);
        end
    end

    function setYp5(v)
        ef5yp.Value = max(v,1e-3);  dd5.Value = 'Custom';  update5();
    end
    function setTs5(T)
        ef5Ts.Value = max(T,1e-3);  dd5.Value = 'Custom';  update5();
    end

%% =====================================================================
%  Shared plotting
%  =====================================================================
    function critical(ax,phLo,phHi)
        % Critical points (-180 deg + k360, 0 dB) in the log-polar window.
        c = -180 + 360*(ceil((phLo + 180)/360):floor((phHi + 180)/360));
        plot(ax,c,zeros(size(c)),'o','MarkerSize',8,'MarkerFaceColor',cRed,'MarkerEdgeColor','k','HitTest','off');
    end
end

%% =========================================================================
%  M contours and regions
%  =========================================================================
function z = mContour(M,isT,~)
% Points L in the complex plane with |S| = M (circle around -1) or |T| = M.
phi = linspace(0,2*pi,1500);
K = -1 + exp(1i*phi)/M;
if isT, z = 1./K; else, z = K; end
z(abs(z) > 1e3) = NaN;
end

function [cx,cy] = logPolarContour(M,isT,phLo,phHi)
% |S| = M or |T| = M contour in the log-polar plane, repeated every 360 deg
% to cover the phase window [phLo, phHi].
z = mContour(M,isT);
mag = 20*log10(abs(z));
ph0 = angle(z)*180/pi;
ph0(ph0 > 0) = ph0(ph0 > 0) - 360;              % (-360, 0]
cx = [];  cy = [];
for off = 360*(floor(phLo/360):ceil(phHi/360))
    x = ph0 + off;
    % break the curve where it wraps
    jump = [false abs(diff(x)) > 180];
    x(jump) = NaN;
    cx = [cx NaN x]; %#ok<AGROW>
    cy = [cy NaN mag]; %#ok<AGROW>
end
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
% Phase axis window: multiples of 90 deg covering the locus, at least [-360, 0].
lo = min(-360,90*floor(min(ph)/90));
hi = max(0,90*ceil(max(ph)/90));
lo = max(lo,-720);  hi = min(hi,360);
end

function tLast = lastOutside(t,y,band)
% Last time |y| is outside +/-band (0 if never).
i = find(abs(y) > band,1,'last');
if isempty(i), tLast = 0; elseif i == numel(t), tLast = Inf; else, tLast = t(i + 1); end
end

function zeta = zetaFromOS(OS)
Lg = log(OS/100);
zeta = -Lg/sqrt(pi^2 + Lg^2);
end

%% =========================================================================
%  Frequency-response helpers
%  =========================================================================
function [Pw,ph] = freqData(P,w)
% Frequency response and continuous phase (deg), each factor unwrapped.
[z,p,k] = zpkdata(P,'v');
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
tau = P.InputDelay + P.OutputDelay + P.IODelay;
Pw = Pw.*exp(-jw*tau);
ph = ph - w(:)*tau*180/pi;
end

function w = freqGrid(P,extra)
% Logarithmic grid two decades either side of the poles and zeros.
[z,p] = zpkdata(P,'v');
c = abs([z; p]);  c = c(c > 1e-9);
if isempty(c), c = 1; end
lo = min(c)/100;  hi = max(c)*100;
if ~isempty(extra), lo = min(lo,min(extra)/10);  hi = max(hi,max(extra)*10); end
w = logspace(log10(lo),log10(hi),3000)';
if ~isempty(extra), w = unique([w; extra(:)]); end
end

function sys = parseTF(str)
% Evaluate a MATLAB expression in s as a zpk model.
str = strtrim(str);
if isempty(str), error('Transfer function is empty.'); end
f = str2func(['@(s) ' str]);
sys = zpk(f(tf('s')));
end

%% =========================================================================
%  Text and UI helpers
%  =========================================================================
function s = num(x)
if abs(x) >= 1e4 && abs(x) < 1e7, s = sprintf('%.0f',x); else, s = sprintf('%.4g',x); end
if strcmp(s,'-0'), s = '0'; end
end

function s = mark(ok)
if ok, s = '✔'; else, s = '✘'; end
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

function showLegend(ax,loc)
% Legend of the curves that have a DisplayName (markers and guides have none).
h = flipud(findobj(ax,'Type','line','-not','DisplayName',''));
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
    'e.g. 5/(s*(s+2)) or 0.2/s.'};
end
