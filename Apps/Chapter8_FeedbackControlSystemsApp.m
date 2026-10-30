function Chapter8_FeedbackControlSystemsApp
%CHAPTER8_FEEDBACKCONTROLSYSTEMSAPP Interactive GUI for MEC3079S Chapter 8 — Feedback control systems.
%
%   Run Chapter8_FeedbackControlSystemsApp to open the app. The tabs follow the chapter:
%     1. Open vs closed loop (8.1, 8.2, 8.4.1 example): an uncertain plant
%        driven in open loop or with feedback G(s) = K·G₀(s); tracking error
%        and control action against K, with saturation and rate limits on u.
%     2. Gang of four        (8.3): pick an input (R, D, N) and an output
%        (Y, U, E) on the block diagram to see which of S, T, PS, GS relates
%        them, with its frequency and step responses.
%     3. Cost of feedback    (8.4.2-8.4.4): reference, disturbance and noise
%        acting together; the contribution of each to y(t) and u(t), and the
%        |T(jω)| specification of Fig 8.6.
%
%   Interaction: drag the K marker and the u_max line on tab 1, click the
%   signal names on the block diagram and drag the |L(jω)| curve on tab 2,
%   and drag the |L(jω)| curve and the specification corners on tab 3.
%
%   Transfer functions are entered as MATLAB expressions in s, for example
%   5/(s+10) or 20*(s+10)/s.
%
%   Requires the Control System Toolbox.

cOrange = [0.85 0.33 0.10];
cBlue   = [0.00 0.45 0.74];
cPurple = [0.49 0.18 0.56];
cGreen  = [0.47 0.67 0.19];
cRed    = [0.85 0.10 0.10];
cGrey   = [0.60 0.60 0.60];
cSig = struct('R',[0.91 0.42 0.42],'D',[0.70 0.45 0.62],'N',[0.98 0.66 0.30], ...
    'Y',[0.36 0.66 0.58],'U',[0.20 0.20 0.20],'E',[0.20 0.20 0.20]);

fig = uifigure('Name','MEC3079S Chapter 8 — Feedback control systems', ...
    'Position',[50 40 1340 860]);
mainGrid = uigridlayout(fig,[1 1],'Padding',[0 0 0 0]);
tg = uitabgroup(mainGrid);

% Drag state shared by all interactive plots
drag = struct('active',false,'ax',[],'move',[],'done',[],'p0',[0 0], ...
    'last',[],'xl',[],'yl',[],'t',tic);
fig.WindowButtonMotionFcn = @(~,~) onMotion();
fig.WindowButtonUpFcn = @(~,~) onRelease();

%% =====================================================================
%  Tab 1: Open loop versus closed loop
%  =====================================================================
t1 = uitab(tg,'Title','Open vs closed loop');
g1 = uigridlayout(t1,[1 2],'ColumnWidth',{340,'1x'});

c1 = uigridlayout(g1,[15 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{112,22,22,22,22,22,22,22,22,22,22,22,22,'1x',22});
at(uilabel(c1,'Text',['The plant gain is uncertain: P(s) = (1 ± δ)P₀(s). In open loop the input ' ...
    'u = r/P₀(0) is calibrated for the nominal plant, so the error follows the uncertainty. With ' ...
    'feedback G(s) = K·G₀(s) a larger K reduces the error for every plant (tracking), at the cost ' ...
    'of a larger control action. Drag the K marker or the u_max line.'],'FontWeight','bold','WordWrap','on'),1,[1 2]);
% name, P0, delta (%), mode, K, G0, r, umax, rate
presets1 = { ...
    '8.4.1: P = (5±2)/(s+10), open loop',          '5/(s+10)',      40, 1, 212.1, '1',              1, Inf, Inf
    '8.4.1: P = (5±2)/(s+10), G = 212.1',          '5/(s+10)',      40, 2, 212.1, '1',              1, Inf, Inf
    '8.4.1: G = 212.1 with |u| ≤ 50',              '5/(s+10)',      40, 2, 212.1, '1',              1, 50,  Inf
    '8.4.1: G = 20',                               '5/(s+10)',      40, 2, 20,    '1',              1, Inf, Inf
    'PI control: G = 20(s+10)/s',                  '5/(s+10)',      40, 2, 20,    '(s+10)/s',       1, Inf, Inf
    'PI control with |u| ≤ 3 (windup)',            '5/(s+10)',      40, 2, 20,    '(s+10)/s',       1, 3,   Inf
    'Rate-limited valve: |du/dt| ≤ 20',            '5/(s+10)',      40, 2, 20,    '1',              1, Inf, 20
    'Custom', '', [], [], [], '', [], [], []};
modes1 = {'Open loop: u = r/P₀(0)','Closed loop: G(s) = K·G₀(s)'};
at(uilabel(c1,'Text','Example'),2,1);
dd1 = at(uidropdown(c1,'Items',presets1(:,1)','Value',presets1{2,1}),2,2);
at(uilabel(c1,'Text','Nominal P₀(s)'),3,1);
ef1P = at(uieditfield(c1,'text','Value','5/(s+10)'),3,2);
at(uilabel(c1,'Text','Gain uncertainty ±δ (%)'),4,1);
ef1d = at(uieditfield(c1,'numeric','Value',40,'Limits',[0 95],'ValueDisplayFormat','%.3g'),4,2);
at(uilabel(c1,'Text','Configuration'),5,1);
dd1M = at(uidropdown(c1,'Items',modes1,'Value',modes1{2}),5,2);
lbl1K = at(uilabel(c1,'Text','Controller gain K'),6,1);
ef1K = at(uieditfield(c1,'numeric','Value',212.1,'Limits',[0 Inf],'ValueDisplayFormat','%.4g'),6,2);
lbl1G = at(uilabel(c1,'Text','G₀(s)'),7,1);
ef1G = at(uieditfield(c1,'text','Value','1'),7,2);
at(uilabel(c1,'Text','Reference step r'),8,1);
ef1r = at(uieditfield(c1,'numeric','Value',1,'ValueDisplayFormat','%.4g'),8,2);
at(uilabel(c1,'Text','|u| ≤ u_max'),9,1);
ef1u = at(uieditfield(c1,'numeric','Value',Inf,'Limits',[0 Inf],'ValueDisplayFormat','%.4g'),9,2);
at(uilabel(c1,'Text','|du/dt| ≤'),10,1);
ef1rt = at(uieditfield(c1,'numeric','Value',Inf,'Limits',[0 Inf],'ValueDisplayFormat','%.4g'),10,2);
at(uilabel(c1,'Text','(Inf = no limit; limits make the loop nonlinear)','FontAngle','italic'),11,[1 2]);
at(uilabel(c1,'Text','Results','FontWeight','bold'),12,[1 2]);
ta1 = at(uitextarea(c1,'Editable','off','FontName','Monospaced'),[13 14],[1 2]);
btn1 = at(uibutton(c1,'Text','Update'),15,[1 2]);

r1 = uigridlayout(g1,[3 2],'RowHeight',{'fit','1x','1x'},'ColumnWidth',{'1x','1x'});
lbl1 = at(uilabel(r1,'Text','','Interpreter','latex','FontSize',18),1,[1 2]);
ax1y = at(uiaxes(r1),2,1);
ax1u = at(uiaxes(r1),2,2);
ax1k = at(uiaxes(r1),3,[1 2]);
[ax1y.Interactions, ax1u.Interactions, ax1k.Interactions] = deal([]);

dd1.ValueChangedFcn = @(~,~) loadPreset1();
[ef1P.ValueChangedFcn, ef1d.ValueChangedFcn, dd1M.ValueChangedFcn, ef1K.ValueChangedFcn, ef1G.ValueChangedFcn, ...
    ef1r.ValueChangedFcn, ef1u.ValueChangedFcn, ef1rt.ValueChangedFcn] = deal(@(~,~) markCustom(dd1,@update1));
btn1.ButtonPushedFcn = @(~,~) update1();

%% =====================================================================
%  Tab 2: Gang of four
%  =====================================================================
t2 = uitab(tg,'Title','Gang of four');
g2 = uigridlayout(t2,[1 2],'ColumnWidth',{340,'1x'});

c2 = uigridlayout(g2,[10 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{112,22,22,22,22,22,22,22,'1x',22});
at(uilabel(c2,'Text',['Every closed-loop relationship is one of S = 1/(1+PG), T = PG/(1+PG), ' ...
    'PS = P/(1+PG) or GS = G/(1+PG), and S + T = 1. Click an input (R, D, N) and an output ' ...
    '(Y, U, E) on the block diagram. Drag the |L(jω)| curve to change K: large loop gain gives ' ...
    'T ≈ 1 and S ≈ 0, but GS → 1/P.'],'FontWeight','bold','WordWrap','on'),1,[1 2]);
presets2 = { ...
    '8.4.1: P = 5/(s+10), G = 212.1',           '5/(s+10)',          212.1, '1'
    'P = 5/(s+10), G = 5',                      '5/(s+10)',          5,     '1'
    'PI: P = 5/(s+10), G = 20(s+10)/s',         '5/(s+10)',          20,    '(s+10)/s'
    'P = 1/(s(s+1)), G = 2',                    '1/(s*(s+1))',       2,     '1'
    'P = 1/(s+1)³, G = 3',                      '1/(s+1)^3',         3,     '1'
    'Lead: P = 1/(s(s+1)), G = 10(s+1)/(0.1s+1)', '1/(s*(s+1))',     10,    '(s+1)/(0.1*s+1)'
    'Custom', '', [], ''};
ins2 = {'R','D','N'};  outs2 = {'Y','U','E'};
at(uilabel(c2,'Text','Example'),2,1);
dd2 = at(uidropdown(c2,'Items',presets2(:,1)','Value',presets2{1,1}),2,2);
at(uilabel(c2,'Text','P(s)'),3,1);
ef2P = at(uieditfield(c2,'text','Value','5/(s+10)'),3,2);
at(uilabel(c2,'Text','Controller gain K'),4,1);
ef2K = at(uieditfield(c2,'numeric','Value',212.1,'Limits',[0 Inf],'ValueDisplayFormat','%.4g'),4,2);
at(uilabel(c2,'Text','G₀(s)  (G = K·G₀)'),5,1);
ef2G = at(uieditfield(c2,'text','Value','1'),5,2);
at(uilabel(c2,'Text','Input'),6,1);
dd2In = at(uidropdown(c2,'Items',{'R(s) reference','D(s) disturbance','N(s) sensor noise'}),6,2);
at(uilabel(c2,'Text','Output'),7,1);
dd2Out = at(uidropdown(c2,'Items',{'Y(s) plant output','U(s) control action','E(s) error'}),7,2);
at(uilabel(c2,'Text','Results','FontWeight','bold'),8,[1 2]);
ta2 = at(uitextarea(c2,'Editable','off','FontName','Monospaced'),9,[1 2]);
btn2 = at(uibutton(c2,'Text','Update'),10,[1 2]);

r2 = uigridlayout(g2,[4 2],'RowHeight',{'fit','fit',230,'1x'},'ColumnWidth',{'1.3x','1x'});
lbl2a = at(uilabel(r2,'Text','','Interpreter','latex','FontSize',18),1,[1 2]);
lbl2b = at(uilabel(r2,'Text','','Interpreter','latex','FontSize',18),2,[1 2]);
ax2d = at(uiaxes(r2),3,[1 2]);
ax2b = at(uiaxes(r2),4,1);
ax2y = at(uiaxes(r2),4,2);
[ax2d.Interactions, ax2b.Interactions, ax2y.Interactions] = deal([]);
ax2d.Toolbar.Visible = 'off';

dd2.ValueChangedFcn = @(~,~) loadPreset2();
[ef2P.ValueChangedFcn, ef2K.ValueChangedFcn, ef2G.ValueChangedFcn] = deal(@(~,~) markCustom(dd2,@update2));
[dd2In.ValueChangedFcn, dd2Out.ValueChangedFcn] = deal(@(~,~) update2());
btn2.ButtonPushedFcn = @(~,~) update2();

%% =====================================================================
%  Tab 3: Cost of feedback
%  =====================================================================
t3 = uitab(tg,'Title','Cost of feedback');
g3 = uigridlayout(t3,[1 2],'ColumnWidth',{340,'1x'});

c3 = uigridlayout(g3,[17 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{112,22,22,22,22,22,22,22,22,22,22,22,22,22,22,'1x',22});
at(uilabel(c3,'Text',['y = T·r + PS·d − T·n and u = GS·r − T·d − GS·n. High loop gain rejects ' ...
    'd and tracks r, but passes n to y wherever |T| ≈ 1 and amplifies it into u by |GS|. ' ...
    'Fig 8.6: aim for |T| > α up to ω₀ and |T| < β beyond ω₁. Drag |L(jω)| to change K and the ' ...
    'specification corners.'],'FontWeight','bold','WordWrap','on'),1,[1 2]);
% name, P, K, G0, r type, r amp, r freq, d amp, d time, n rms, alpha, w0, beta, w1
presets3 = { ...
    '8.4.1 plant, G = 212.1: noisy u',             '5/(s+10)',     212.1, '1',              1, 1, 1,  0.5, 0.3, 0.02, 0.9, 50,  0.1, 3000
    '8.4.1 plant, G = 20',                         '5/(s+10)',     20,    '1',              1, 1, 1,  0.5, 0.3, 0.02, 0.9, 50,  0.1, 3000
    'PI: G = 20(s+10)/s, rejects step d',          '5/(s+10)',     20,    '(s+10)/s',       1, 1, 1,  0.5, 0.3, 0.02, 0.9, 50,  0.1, 3000
    'Lead + roll-off: P = 1/(s(s+1))',             '1/(s*(s+1))',  10,    '(s+1)/((0.1*s+1)*(0.01*s+1))', 2, 1, 1, 0.5, 5, 0.02, 0.8, 3, 0.1, 300
    'Custom', '', [], '', [], [], [], [], [], [], [], [], [], []};
at(uilabel(c3,'Text','Example'),2,1);
dd3 = at(uidropdown(c3,'Items',presets3(:,1)','Value',presets3{1,1}),2,2);
at(uilabel(c3,'Text','P(s)'),3,1);
ef3P = at(uieditfield(c3,'text','Value','5/(s+10)'),3,2);
at(uilabel(c3,'Text','Controller gain K'),4,1);
ef3K = at(uieditfield(c3,'numeric','Value',212.1,'Limits',[0 Inf],'ValueDisplayFormat','%.4g'),4,2);
at(uilabel(c3,'Text','G₀(s)  (G = K·G₀)'),5,1);
ef3G = at(uieditfield(c3,'text','Value','1'),5,2);
at(uilabel(c3,'Text','Reference r(t)'),6,1);
dd3r = at(uidropdown(c3,'Items',{'Step','Sinusoid'}),6,2);
at(uilabel(c3,'Text','r amplitude / ω'),7,1);
g3r = at(uigridlayout(c3,[1 2],'Padding',[0 0 0 0]),7,2);
ef3ra = uieditfield(g3r,'numeric','Value',1,'ValueDisplayFormat','%.4g');
ef3rw = uieditfield(g3r,'numeric','Value',1,'Limits',[0 Inf],'ValueDisplayFormat','%.4g');
at(uilabel(c3,'Text','Step d: size / time'),8,1);
g3d = at(uigridlayout(c3,[1 2],'Padding',[0 0 0 0]),8,2);
ef3da = uieditfield(g3d,'numeric','Value',0.5,'ValueDisplayFormat','%.4g');
ef3dt = uieditfield(g3d,'numeric','Value',0.3,'Limits',[0 Inf],'ValueDisplayFormat','%.4g');
at(uilabel(c3,'Text','Noise n: RMS'),9,1);
ef3n = at(uieditfield(c3,'numeric','Value',0.02,'Limits',[0 Inf],'ValueDisplayFormat','%.4g'),9,2);
at(uilabel(c3,'Text','Spec α, ω₀'),10,1);
g3a = at(uigridlayout(c3,[1 2],'Padding',[0 0 0 0]),10,2);
ef3al = uieditfield(g3a,'numeric','Value',0.9,'Limits',[0 1],'ValueDisplayFormat','%.3g');
ef3w0 = uieditfield(g3a,'numeric','Value',50,'Limits',[1e-6 Inf],'ValueDisplayFormat','%.4g');
at(uilabel(c3,'Text','Spec β, ω₁'),11,1);
g3b = at(uigridlayout(c3,[1 2],'Padding',[0 0 0 0]),11,2);
ef3be = uieditfield(g3b,'numeric','Value',0.1,'Limits',[0 1],'ValueDisplayFormat','%.3g');
ef3w1 = uieditfield(g3b,'numeric','Value',3000,'Limits',[1e-6 Inf],'ValueDisplayFormat','%.4g');
at(uilabel(c3,'Text','Show in y(t), u(t)'),12,1);
g3c = at(uigridlayout(c3,[1 3],'Padding',[0 0 0 0],'ColumnSpacing',2),12,2);
cb3r = uicheckbox(g3c,'Text','from r','Value',true);
cb3d = uicheckbox(g3c,'Text','from d','Value',true);
cb3n = uicheckbox(g3c,'Text','from n','Value',true);
at(uilabel(c3,'Text','Results','FontWeight','bold'),13,[1 2]);
ta3 = at(uitextarea(c3,'Editable','off','FontName','Monospaced'),[14 16],[1 2]);
btn3 = at(uibutton(c3,'Text','Update'),17,[1 2]);
noise3 = [];            % unit noise sequence, fixed so that drags do not reshuffle it

r3 = uigridlayout(g3,[3 2],'RowHeight',{'fit','1x','1x'},'ColumnWidth',{'1x','1x'});
lbl3 = at(uilabel(r3,'Text','','Interpreter','latex','FontSize',17),1,[1 2]);
ax3y = at(uiaxes(r3),2,1);
ax3u = at(uiaxes(r3),3,1);
ax3T = at(uiaxes(r3),2,2);
ax3S = at(uiaxes(r3),3,2);
[ax3y.Interactions, ax3u.Interactions, ax3T.Interactions, ax3S.Interactions] = deal([]);

dd3.ValueChangedFcn = @(~,~) loadPreset3();
[ef3P.ValueChangedFcn, ef3K.ValueChangedFcn, ef3G.ValueChangedFcn, dd3r.ValueChangedFcn, ef3ra.ValueChangedFcn, ...
    ef3rw.ValueChangedFcn, ef3da.ValueChangedFcn, ef3dt.ValueChangedFcn, ef3n.ValueChangedFcn, ef3al.ValueChangedFcn, ...
    ef3w0.ValueChangedFcn, ef3be.ValueChangedFcn, ef3w1.ValueChangedFcn] = deal(@(~,~) markCustom(dd3,@update3));
[cb3r.ValueChangedFcn, cb3d.ValueChangedFcn, cb3n.ValueChangedFcn] = deal(@(~,~) update3());
btn3.ButtonPushedFcn = @(~,~) update3();

% Initial draw
loadPreset1(); loadPreset2(); loadPreset3();

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
        ef1P.Value = presets1{k,2};
        ef1d.Value = presets1{k,3};
        dd1M.Value = modes1{presets1{k,4}};
        ef1K.Value = presets1{k,5};
        ef1G.Value = presets1{k,6};
        [ef1r.Value, ef1u.Value, ef1rt.Value] = presets1{k,7:9};
        update1();
    end

    function update1()
        try
            P0 = parseTF(ef1P.Value);
            G0 = parseTF(ef1G.Value);
            delta = ef1d.Value/100;  K = ef1K.Value;  r = ef1r.Value;
            umax = ef1u.Value;  rate = ef1rt.Value;
            closed = strcmp(dd1M.Value,modes1{2});
            set([lbl1K ef1K lbl1G ef1G],'Enable',onoff(closed));
            G = K*G0;
            P0dc = dcgain(P0);
            fac = 1 + delta*[-1 0 1];
            cols = [cOrange; cBlue; cPurple];
            names = arrayfun(@(f) sprintf('P = %s P_0',num(f)),fac,'UniformOutput',false);

            % Time span from the slowest closed-loop (or open-loop) pole of the family
            pAll = [];  stable = true;
            for i = 1:3
                if closed, pc = pole(feedback(fac(i)*P0*G,1)); else, pc = pole(P0); end
                pAll = [pAll; pc]; %#ok<AGROW>
                stable = stable && all(real(pc) < -1e-9);
            end
            if ~stable, error('The closed loop is unstable for at least one plant: reduce K.'); end
            sig = -real(pAll);
            T = min(6/min(sig),1e4);
            dt = min(T/3000,0.05/max(abs(pAll)));
            if isfinite(rate), dt = min(dt,T/3000); end
            t = (0:dt:T)';
            if numel(t) > 40000, t = linspace(0,T,40000)'; end
            limited = isfinite(umax) || isfinite(rate);

            cla(ax1y); hold(ax1y,'on');  cla(ax1u); hold(ax1u,'on');
            plot(ax1y,[0 T],[r r],'k--','LineWidth',1.2,'DisplayName','r(t)');
            yEnd = zeros(1,3);  uPk = zeros(1,3);
            for i = 1:3
                Pi = fac(i)*P0;
                if closed
                    [y,u] = simLoop(Pi,G,t,r,umax,rate,false,0);
                else
                    [y,u] = simLoop(Pi,G,t,r,umax,rate,true,1/P0dc);
                end
                yEnd(i) = y(end);  uPk(i) = max(abs(u));
                plot(ax1y,t,y,'Color',cols(i,:),'LineWidth',2,'DisplayName',['y: ' names{i}]);
                plot(ax1u,t,u,'Color',cols(i,:),'LineWidth',2,'DisplayName',['u: ' names{i}]);
            end
            hold(ax1y,'off'); grid(ax1y,'on'); showLegend(ax1y,'southeast'); xlim(ax1y,[0 T]);
            title(ax1y,'Output y(t) for the plant family'); xlabel(ax1y,'t (seconds)');
            if isfinite(umax)
                h = plot(ax1u,[0 T],[umax umax],'-','Color',cRed,'LineWidth',2.5);
                draggable(h,ax1u,@(pt,~) setUmax1(abs(pt(2))),@update1);
                plot(ax1u,[0 T],-[umax umax],'-','Color',cRed,'LineWidth',1.5,'HitTest','off');
                text(ax1u,T,umax,'u_{max}  ','Color',cRed,'HorizontalAlignment','right','VerticalAlignment','bottom', ...
                    'FontSize',12,'HitTest','off');
            end
            hold(ax1u,'off'); grid(ax1u,'on'); showLegend(ax1u,'northeast'); xlim(ax1u,[0 T]);
            title(ax1u,'Control action u(t)'); xlabel(ax1u,'t (seconds)');

            % e(inf) and u(0+) against K (linear analysis)
            Kg = logspace(-1,4,200)';
            cla(ax1k);
            yyaxis(ax1k,'left'); cla(ax1k); hold(ax1k,'on');
            G0dc = dcgain(G0);  G0hf = hfGain(G0);  Phf = hfGain(P0);
            for i = 1:3
                Ldc = fac(i)*P0dc*Kg*G0dc;
                eInf = r./(1 + Ldc);
                eInf(isinf(Ldc)) = 0;
                plot(ax1k,Kg,abs(eInf),'-','Color',cols(i,:),'LineWidth',2,'HitTest','off');
            end
            if closed
                Ldc = fac*P0dc*K*G0dc;  eNow = abs(r./(1 + Ldc));  eNow(isinf(Ldc)) = 0;
                h = plot(ax1k,K*[1 1 1],eNow,'o','MarkerSize',10,'MarkerFaceColor',cRed,'MarkerEdgeColor','k');
                draggable(h,ax1k,@(pt,~) setK1(pt(1)),@update1);
                plot(ax1k,[K K],[0 max(abs(r),1e-9)],':','Color',cRed,'HitTest','off');
            end
            hold(ax1k,'off'); ylabel(ax1k,'|e(∞)| = |r|/(1 + P(0)K G₀(0))');
            ax1k.YColor = [0 0 0];
            yyaxis(ax1k,'right'); cla(ax1k);
            plot(ax1k,Kg,abs(r*Kg*G0hf./(1 + Phf*Kg*G0hf)),'--','Color',cGrey,'LineWidth',2,'HitTest','off');
            ylabel(ax1k,'u(0^+) = r K G_0(\infty)'); ax1k.YColor = cGrey*0.8;
            set(ax1k,'XScale','log','YScale','log'); grid(ax1k,'on');
            yyaxis(ax1k,'left'); set(ax1k,'YScale','linear');
            xlim(ax1k,Kg([1 end]));
            title(ax1k,'Steady-state error (solid, one per plant) and initial control action (dashed) vs K: drag the marker');
            xlabel(ax1k,'Controller gain K');

            % Equation
            if closed
                lbl1.Text = sprintf(['$y_\\infty=\\frac{P(0)G(0)}{1+P(0)G(0)}r,\\quad P(0)\\in[%s,\\ %s],\\quad ' ...
                    'G(s)=%s\\cdot G_0(s),\\quad u(0^+)=rK\\,G_0(\\infty)=%s$'],num(fac(1)*P0dc),num(fac(3)*P0dc), ...
                    num(K),num(r*K*G0hf/(1 + Phf*K*G0hf)));
            else
                lbl1.Text = sprintf(['$u=\\frac{r}{P_0(0)}=%s,\\quad y_\\infty=P(0)u=\\frac{P(0)}{P_0(0)}r\\in[%s,\\ %s]$'], ...
                    num(r/P0dc),num(fac(1)*r),num(fac(3)*r));
            end

            % Results
            txt = {sprintf('P0(0) = %s, plant gains %s..%s',num(P0dc),num(fac(1)*P0dc),num(fac(3)*P0dc)); ''; ...
                '            y(end)    e(end)   max|u|'};
            for i = 1:3
                txt{end+1} = sprintf('%-9s %8.4g  %8.4g  %8.4g',sprintf('%.3gP0',fac(i)),yEnd(i),r - yEnd(i),uPk(i)); %#ok<AGROW>
            end
            txt{end+1} = '';
            if closed
                txt{end+1} = sprintf('Spread of y(end): %s (open loop: %s)',num(max(yEnd) - min(yEnd)),num(2*delta*abs(r)));
                txt{end+1} = 'Larger K: smaller error and spread,';
                txt{end+1} = 'faster response, larger control action.';
            else
                txt{end+1} = 'Open loop: y(inf) is off by the same';
                txt{end+1} = sprintf('+/-%s%% as the plant gain.',num(100*delta));
            end
            if limited
                txt{end+1} = '';
                txt{end+1} = 'u is limited: the loop is nonlinear and';
                txt{end+1} = 'the linear e(inf) curve is only a guide.';
            end
            ta1.Value = txt(:);
        catch err
            showError(ta1,err);
        end
    end

    function setK1(K)
        ef1K.Value = max(K,0);
        dd1.Value = 'Custom';
        update1();
    end

    function setUmax1(u)
        ef1u.Value = max(u,1e-6);
        dd1.Value = 'Custom';
        update1();
    end

%% =====================================================================
%  Tab 2 callbacks
%  =====================================================================
    function loadPreset2()
        k = find(strcmp(presets2(:,1),dd2.Value));
        if isempty(presets2{k,3}), update2(); return, end
        ef2P.Value = presets2{k,2};
        ef2K.Value = presets2{k,3};
        ef2G.Value = presets2{k,4};
        update2();
    end

    function update2()
        try
            P = parseTF(ef2P.Value);  G0 = parseTF(ef2G.Value);  K = ef2K.Value;
            G = K*G0;  L = P*G;
            S = minreal(feedback(1,L),1e-7);
            T = minreal(feedback(L,1),1e-7);
            PS = minreal(feedback(P,G),1e-7);
            GS = minreal(feedback(G,P),1e-7);
            in = ins2{find(strcmp(dd2In.Items,dd2In.Value))};
            out = outs2{find(strcmp(dd2Out.Items,dd2Out.Value))};
            % Which gang member, and its sign, relates the chosen input and output
            map = struct('RY',{{'T',1}},'DY',{{'PS',1}},'NY',{{'T',-1}}, ...
                         'RU',{{'GS',1}},'DU',{{'T',-1}},'NU',{{'GS',-1}}, ...
                         'RE',{{'S',1}},'DE',{{'PS',-1}},'NE',{{'S',-1}});
            sel = map.([in out]);
            gang = struct('S',S,'T',T,'PS',PS,'GS',GS);
            H = sel{2}*gang.(sel{1});
            clStable = all(real(pole(T)) < -1e-9);

            % Equations: full expression for the chosen output, chosen term in a box
            terms = struct('Y',{{'T','R';'PS','D';'-T','N'}},'U',{{'GS','R';'-T','D';'-GS','N'}}, ...
                'E',{{'S','R';'-PS','D';'-S','N'}});
            tt = terms.(out);
            str = sprintf('%s(s)=',out);
            for q = 1:3
                term = sprintf('%s(s)%s(s)',strrep(tt{q,1},'-',''),tt{q,2});
                if q > 1 || tt{q,1}(1) == '-'
                    if tt{q,1}(1) == '-', sgn = '-'; else, sgn = '+'; end
                else, sgn = ''; end
                if strcmp(tt{q,2},in), term = ['\underbrace{' term '}_{' in '\to ' out '}']; end
                str = [str sgn term]; %#ok<AGROW>
            end
            names = struct('S','S(s)=\frac{1}{1+P(s)G(s)}\ \mathrm{(sensitivity)}', ...
                'T','T(s)=\frac{P(s)G(s)}{1+P(s)G(s)}\ \mathrm{(complementary\ sensitivity)}', ...
                'PS','PS(s)=\frac{P(s)}{1+P(s)G(s)}\ \mathrm{(load\ sensitivity)}', ...
                'GS','GS(s)=\frac{G(s)}{1+P(s)G(s)}\ \mathrm{(noise\ sensitivity)}');
            lbl2a.Text = ['$' str '$'];
            lbl2b.Text = sprintf('$\\frac{%s(s)}{%s(s)}=%s%s(s),\\quad %s$',out,in,pick(sel{2} < 0,'-',''),sel{1},names.(sel{1}));

            drawDiagram2(in,out);

            % Bode magnitudes of the gang of four and L
            w = freqGrid({P,G0});
            mag = @(sys) 20*log10(abs(squeeze(freqresp(sys,w))));
            cla(ax2b); hold(ax2b,'on');
            gm = {'S',cOrange;'T',cBlue;'PS',cPurple;'GS',cGreen};
            for q = 1:4
                lw = 1.5;  if strcmp(gm{q,1},sel{1}), lw = 4; end
                plot(ax2b,w,mag(gang.(gm{q,1})),'Color',gm{q,2},'LineWidth',lw,'HitTest','off', ...
                    'DisplayName',['|' gm{q,1} '(jω)|']);
            end
            h = plot(ax2b,w,mag(L),'--','Color',[0.3 0.3 0.3],'LineWidth',2,'DisplayName','|L(jω)| (drag)');
            draggable(h,ax2b,@(pt,p0) setK2(K*10^((pt(2) - p0(2))/20)),@update2);
            plot(ax2b,w([1 end]),[0 0],'k:','HitTest','off');
            hold(ax2b,'off'); grid(ax2b,'on'); set(ax2b,'XScale','log'); xlim(ax2b,w([1 end]));
            yl = ylim(ax2b);  ylim(ax2b,[max(yl(1),-100) min(yl(2),100)]);
            showLegend(ax2b,'southwest');
            title(ax2b,'Gang of four and the loop L = PG'); xlabel(ax2b,'ω (rad/s)'); ylabel(ax2b,'Magnitude (dB)');

            % Step response of the selected relationship
            cla(ax2y);
            if clStable
                [yv,tv] = step(H);
                plot(ax2y,tv,yv,'Color',cSig.(in),'LineWidth',2.5);
                title(ax2y,sprintf('%s(t) for a unit step in %s',lower(out),lower(in)));
                xlim(ax2y,[0 tv(end)]);
            else
                title(ax2y,'Closed loop unstable');
            end
            grid(ax2y,'on'); xlabel(ax2y,'t (seconds)');

            % Results
            chk = max(abs(squeeze(freqresp(S + T,w)) - 1));
            txt = {sprintf('%s -> %s:  %s%s(s)',in,out,pick(sel{2} < 0,'-',''),sel{1}); ''; ...
                sprintf('DC gain of %s%s: %s',pick(sel{2} < 0,'-',''),sel{1},num(dcgain(H))); ...
                sprintf('max |%s(jw)| = %s dB',sel{1},num(max(mag(gang.(sel{1})))))};
            txt{end+1} = '';
            txt{end+1} = sprintf('|S(j0)| = %s, |T(j0)| = %s',num(abs(dcgain(S))),num(abs(dcgain(T))));
            txt{end+1} = sprintf('|GS(jw)| at high w: %s (= |G(inf)|)',num(abs(hfGain(GS))));
            txt{end+1} = sprintf('max |S + T - 1| = %.1e', chk);
            if clStable
                txt{end+1} = 'Closed loop stable.';
            else
                txt{end+1} = 'Closed loop UNSTABLE (see Chapter 9).';
            end
            ta2.Value = txt(:);
        catch err
            showError(ta2,err);
        end
    end

    function setK2(K)
        ef2K.Value = max(K,0);
        dd2.Value = 'Custom';
        update2();
    end

    function drawDiagram2(in,out)
        % Fig 8.3, with the forward path from the chosen input to the chosen output highlighted.
        ax = ax2d;
        cla(ax); hold(ax,'on');
        segs = struct( ...
            'R',  [0.4 2; 1.3 2], ...
            'E',  [1.7 2; 3 2], ...
            'U',  [4.4 2; 5.3 2], ...
            'D',  [5.5 3.4; 5.5 2.2], ...
            'V',  [5.7 2; 6.8 2], ...
            'Y',  [8.2 2; 9.8 2], ...
            'FB1',[9 2; 9 0.6; 6.7 0.6], ...
            'N',  [6.5 -0.6; 6.5 0.4], ...
            'FB2',[6.3 0.6; 1.5 0.6; 1.5 1.8]);
        paths = struct('RY',{{'R','E','U','V','Y'}},'RU',{{'R','E','U'}},'RE',{{'R','E'}}, ...
            'DY',{{'D','V','Y'}},'DU',{{'D','V','Y','FB1','FB2','E','U'}},'DE',{{'D','V','Y','FB1','FB2','E'}}, ...
            'NY',{{'N','FB2','E','U','V','Y'}},'NU',{{'N','FB2','E','U'}},'NE',{{'N','FB2','E'}});
        on = paths.([in out]);
        fn = fieldnames(segs);
        for q = 1:numel(fn)
            xy = segs.(fn{q});
            if any(strcmp(on,fn{q})), c = cSig.(in); lw = 4; else, c = [0.25 0.25 0.25]; lw = 1.5; end
            plot(ax,xy(:,1),xy(:,2),'-','Color',c,'LineWidth',lw,'HitTest','off');
            d = xy(end,:) - xy(end-1,:);  d = d/norm(d);
            if ~ismember(fn{q},{'FB1'})
                pa = xy(end,:);  nrm = [-d(2) d(1)];
                patch(ax,pa(1) - [0 0.18*d(1)+0.08*nrm(1) 0.18*d(1)-0.08*nrm(1)], ...
                    pa(2) - [0 0.18*d(2)+0.08*nrm(2) 0.18*d(2)-0.08*nrm(2)],c,'EdgeColor',c,'HitTest','off');
            end
        end
        % Blocks and summing junctions
        rectangle(ax,'Position',[3 1.55 1.4 0.9],'FaceColor','w','EdgeColor','k','LineWidth',1.5,'HitTest','off');
        text(ax,3.7,2,'G(s)','HorizontalAlignment','center','FontSize',15,'HitTest','off');
        rectangle(ax,'Position',[6.8 1.55 1.4 0.9],'FaceColor','w','EdgeColor','k','LineWidth',1.5,'HitTest','off');
        text(ax,7.5,2,'P(s)','HorizontalAlignment','center','FontSize',15,'HitTest','off');
        th = linspace(0,2*pi,60);
        for cxy = [1.5 2; 5.5 2; 6.5 0.6]'
            patch(ax,cxy(1) + 0.2*cos(th),cxy(2) + 0.2*sin(th),'w','EdgeColor','k','LineWidth',1.5,'HitTest','off');
        end
        text(ax,1.2,1.6,'−','FontSize',16,'HitTest','off');
        text(ax,1.05,2.3,'+','FontSize',13,'HitTest','off');
        % Clickable signal names
        lab = {'R',0.2,2.4,'in'; 'D',5.5,3.75,'in'; 'N',6.5,-0.95,'in'; 'Y',9.9,2.4,'out'; 'U',4.75,2.6,'out'; 'E',2.35,2.6,'out'};
        for q = 1:size(lab,1)
            nm = lab{q,1};
            isSel = strcmp(nm,in) || strcmp(nm,out);
            if isSel, fw = 'bold'; fs = 20; else, fw = 'normal'; fs = 16; end
            h = text(ax,lab{q,2},lab{q,3},[nm '(s)'],'FontSize',fs,'FontWeight',fw,'Color',cSig.(nm), ...
                'HorizontalAlignment','center','PickableParts','all');
            if strcmp(lab{q,4},'in')
                h.ButtonDownFcn = @(~,~) pickSignal2(nm,[]);
            else
                h.ButtonDownFcn = @(~,~) pickSignal2([],nm);
            end
            if isSel && strcmp(lab{q,4},'in')
                h.BackgroundColor = [1 0.96 0.85];
            elseif isSel
                h.BackgroundColor = [0.9 0.97 0.93];
            end
        end
        hold(ax,'off');
        axis(ax,'equal'); xlim(ax,[-0.2 10.4]); ylim(ax,[-1.3 4.1]);
        ax.XTick = [];  ax.YTick = [];  ax.XColor = 'none';  ax.YColor = 'none';
        title(ax,'Click an input (R, D, N) and an output (Y, U, E): the highlighted path is the forward path');
    end

    function pickSignal2(in,out)
        if ~isempty(in), dd2In.Value = dd2In.Items{strcmp(ins2,in)}; end
        if ~isempty(out), dd2Out.Value = dd2Out.Items{strcmp(outs2,out)}; end
        update2();
    end

%% =====================================================================
%  Tab 3 callbacks
%  =====================================================================
    function loadPreset3()
        k = find(strcmp(presets3(:,1),dd3.Value));
        if isempty(presets3{k,3}), update3(); return, end
        ef3P.Value = presets3{k,2};  ef3K.Value = presets3{k,3};  ef3G.Value = presets3{k,4};
        dd3r.Value = dd3r.Items{presets3{k,5}};
        [ef3ra.Value, ef3rw.Value, ef3da.Value, ef3dt.Value, ef3n.Value, ef3al.Value, ef3w0.Value, ...
            ef3be.Value, ef3w1.Value] = presets3{k,6:14};
        update3();
    end

    function update3()
        try
            P = parseTF(ef3P.Value);  G0 = parseTF(ef3G.Value);  K = ef3K.Value;
            G = K*G0;  L = P*G;
            S = minreal(feedback(1,L),1e-7);  T = minreal(feedback(L,1),1e-7);
            PS = minreal(feedback(P,G),1e-7);  GS = minreal(feedback(G,P),1e-7);
            pc = pole(T);
            if any(real(pc) >= -1e-9), error('The closed loop is unstable: reduce K.'); end
            al = ef3al.Value;  w0 = ef3w0.Value;  be = ef3be.Value;  w1 = ef3w1.Value;

            % Simulation (linear: superposition of the three contributions)
            Tend = min(max(6/min(-real(pc)),ef3dt.Value*2),200);
            if strcmp(dd3r.Value,'Sinusoid') && ef3rw.Value > 0, Tend = max(Tend,4*2*pi/ef3rw.Value); end
            N = 6000;
            t = linspace(0,Tend,N)';
            dt = t(2) - t(1);
            if strcmp(dd3r.Value,'Step'), r = ef3ra.Value*ones(N,1); else, r = ef3ra.Value*sin(ef3rw.Value*t); end
            d = ef3da.Value*(t >= ef3dt.Value);
            if numel(noise3) ~= N
                rs = RandStream('mt19937ar','Seed',7);
                noise3 = randn(rs,N,1);
            end
            n = ef3n.Value*noise3;
            yr = lsim(T,r,t);  yd = lsim(PS,d,t);  yn = -lsim(T,n,t);
            ur = lsim(GS,r,t); ud = -lsim(T,d,t);  un = -lsim(GS,n,t);
            show = [cb3r.Value cb3d.Value cb3n.Value];
            y = yr*show(1) + yd*show(2) + yn*show(3);
            u = ur*show(1) + ud*show(2) + un*show(3);

            cla(ax3y); hold(ax3y,'on');
            if show(1), plot(ax3y,t,r,'k--','LineWidth',1.2,'DisplayName','r(t)'); end
            if show(2) && show(1), plot(ax3y,t,yd,'Color',cSig.D,'LineWidth',1.3,'DisplayName','from d: PS·d'); end
            if show(3) && (show(1) || show(2)), plot(ax3y,t,yn,'Color',cSig.N,'LineWidth',1,'DisplayName','from n: −T·n'); end
            plot(ax3y,t,y,'Color',cBlue,'LineWidth',2,'DisplayName','y(t)');
            hold(ax3y,'off'); grid(ax3y,'on'); showLegend(ax3y,'southeast'); xlim(ax3y,[0 Tend]);
            title(ax3y,'Plant output y(t)'); xlabel(ax3y,'t (seconds)');
            cla(ax3u); hold(ax3u,'on');
            plot(ax3u,t,u,'Color',[0.25 0.25 0.25],'LineWidth',1.5,'DisplayName','u(t)');
            if show(3) && (show(1) || show(2)), plot(ax3u,t,un,'Color',cSig.N,'LineWidth',1,'DisplayName','from n: −GS·n'); end
            hold(ax3u,'off'); grid(ax3u,'on'); showLegend(ax3u,'northeast'); xlim(ax3u,[0 Tend]);
            title(ax3u,'Control action u(t)'); xlabel(ax3u,'t (seconds)');

            % |T|, |L| and the Fig 8.6 specification
            w = freqGrid({P,G0,tf(1,[1/w0 1]),tf(1,[1/w1 1])});
            Tw = abs(squeeze(freqresp(T,w)));  Lw = abs(squeeze(freqresp(L,w)));
            Sw = abs(squeeze(freqresp(S,w)));  GSw = abs(squeeze(freqresp(GS,w)));
            passLow = all(Tw(w <= w0) > al);
            passHigh = all(Tw(w >= w1) < be);
            cla(ax3T); hold(ax3T,'on');
            yl = [max(min(20*log10([Tw; Lw])),-100) min(max(20*log10([Tw; Lw])),100) + 10];
            patch(ax3T,[w(1) w0 w0 w(1)],[yl(1) yl(1) 20*log10(al) 20*log10(al)],[1 0.9 0.9],'EdgeColor','none','HitTest','off');
            patch(ax3T,[w1 w(end) w(end) w1],[20*log10(be) 20*log10(be) yl(2) yl(2)],[1 0.9 0.9],'EdgeColor','none','HitTest','off');
            h = plot(ax3T,w,20*log10(Lw),'--','Color',[0.3 0.3 0.3],'LineWidth',2,'DisplayName','|L(jω)| (drag)');
            draggable(h,ax3T,@(pt,p0) setK3(K*10^((pt(2) - p0(2))/20)),@update3);
            plot(ax3T,w,20*log10(Tw),'Color',cBlue,'LineWidth',2.5,'HitTest','off','DisplayName','|T(jω)|');
            h = plot(ax3T,w0,20*log10(al),'s','MarkerSize',11,'MarkerFaceColor',cGreen,'MarkerEdgeColor','k');
            draggable(h,ax3T,@(pt,~) setSpec3(1,pt),@update3);
            h = plot(ax3T,w1,20*log10(be),'s','MarkerSize',11,'MarkerFaceColor',cRed,'MarkerEdgeColor','k');
            draggable(h,ax3T,@(pt,~) setSpec3(2,pt),@update3);
            text(ax3T,w0,20*log10(al),sprintf(' |T| > \\alpha = %s up to \\omega_0 %s',num(al),mark(passLow)), ...
                'Color',cGreen*0.7,'FontSize',12,'VerticalAlignment','top','HorizontalAlignment','right','HitTest','off');
            text(ax3T,w1,20*log10(be),sprintf(' |T| < \\beta = %s beyond \\omega_1 %s',num(be),mark(passHigh)), ...
                'Color',cRed,'FontSize',12,'VerticalAlignment','bottom','HitTest','off');
            hold(ax3T,'off'); grid(ax3T,'on'); set(ax3T,'XScale','log'); xlim(ax3T,w([1 end])); ylim(ax3T,yl);
            showLegend(ax3T,'southwest');
            title(ax3T,'|T(jω)| with the Fig 8.6 specification (shaded = not allowed)'); ylabel(ax3T,'dB');
            cla(ax3S); hold(ax3S,'on');
            plot(ax3S,w,20*log10(Sw),'Color',cOrange,'LineWidth',2,'DisplayName','|S(jω)|: d and r → e');
            plot(ax3S,w,20*log10(GSw),'Color',cGreen,'LineWidth',2,'DisplayName','|GS(jω)|: n, r → u');
            hold(ax3S,'off'); grid(ax3S,'on'); set(ax3S,'XScale','log'); xlim(ax3S,w([1 end]));
            showLegend(ax3S,'southeast');
            title(ax3S,'Sensitivity and noise sensitivity'); xlabel(ax3S,'ω (rad/s)'); ylabel(ax3S,'dB');

            lbl3.Text = sprintf(['$y=T\\,r+PS\\,d-T\\,n,\\quad u=GS\\,r-T\\,d-GS\\,n,\\quad |S(j0)|=%s,\\ ' ...
                '|GS(j\\infty)|=%s\\ (%s\\,\\mathrm{dB})$'],num(abs(dcgain(S))),num(abs(hfGain(GS))), ...
                num(20*log10(max(abs(hfGain(GS)),1e-12))));

            % Results
            settled = t >= Tend/2;
            txt = {sprintf('RMS of the noise part of y: %s',num(sqrt(mean(yn(settled).^2)))); ...
                sprintf('RMS of the noise part of u: %s',num(sqrt(mean(un(settled).^2)))); ...
                sprintf('  (noise RMS %s, |GS| at high w = %s)',num(ef3n.Value),num(abs(hfGain(GS)))); ''; ...
                sprintf('Disturbance offset in y(end): %s',num(yd(end))); ...
                sprintf('  = PS(0)*d = %s',num(dcgain(PS)*ef3da.Value)); ...
                sprintf('max |u| = %s',num(max(abs(u)))); ''; ...
                sprintf('Spec low  (|T| > %s for w <= %s): %s',num(al),num(w0),pick(passLow,'met','NOT met')); ...
                sprintf('Spec high (|T| < %s for w >= %s): %s',num(be),num(w1),pick(passHigh,'met','NOT met'))};
            ta3.Value = txt(:);
        catch err
            showError(ta3,err);
        end
    end

    function setK3(K)
        ef3K.Value = max(K,0);
        dd3.Value = 'Custom';
        update3();
    end

    function setSpec3(which,pt)
        v = min(max(10^(pt(2)/20),1e-6),1);
        if which == 1, ef3w0.Value = max(pt(1),1e-6); ef3al.Value = v;
        else, ef3w1.Value = max(pt(1),1e-6); ef3be.Value = v; end
        dd3.Value = 'Custom';
        update3();
    end
end

%% =========================================================================
%  Simulation and frequency helpers
%  =========================================================================
function [y,u] = simLoop(P,G,t,r,umax,rate,openLoop,ffGain)
% Sampled closed-loop (or open-loop) step simulation with saturation and
% rate limits on u. The plant is discretised exactly (zero-order hold) and
% the controller with the Tustin method at the simulation step.
dt = t(2) - t(1);
Pd = c2d(ss(P),dt,'zoh');
[Ap,Bp,Cp,Dp] = ssdata(Pd);
if any(abs(Dp(:)) > 0), error('The plant must be strictly proper for this simulation.'); end
if ~openLoop
    Gs = ss(G);
    if ~isproper(G), error('G(s) must be proper.'); end
    Gd = c2d(Gs,dt,'tustin');
    [Ag,Bg,Cg,Dg] = ssdata(Gd);
    xg = zeros(size(Ag,1),1);
end
x = zeros(size(Ap,1),1);
n = numel(t);  y = zeros(n,1);  u = zeros(n,1);
uPrev = 0;
for k = 1:n
    y(k) = Cp*x;
    if openLoop
        uc = ffGain*r;
    else
        e = r - y(k);
        uc = Cg*xg + Dg*e;
        xg = Ag*xg + Bg*e;
    end
    uc = min(max(uc,-umax),umax);
    if isfinite(rate)
        uc = uPrev + min(max(uc - uPrev,-rate*dt),rate*dt);
    end
    uPrev = uc;
    u(k) = uc;
    x = Ap*x + Bp*uc;
end
end

function g = hfGain(sys)
% lim_{s->inf} of a transfer function (0, finite or Inf).
[z,p,k] = zpkdata(zpk(sys),'v');
rd = numel(p) - numel(z);
if rd > 0, g = 0; elseif rd < 0, g = Inf; else, g = k; end
end

function w = freqGrid(systems)
% Logarithmic grid two decades either side of all poles and zeros.
c = [];
for i = 1:numel(systems)
    [z,p] = zpkdata(zpk(systems{i}),'v');
    c = [c; abs(z); abs(p)]; %#ok<AGROW>
end
c = c(c > 1e-9);
if isempty(c), c = 1; end
w = logspace(log10(min(c)/100),log10(max(c)*100),1500)';
end

%% =========================================================================
%  Text helpers
%  =========================================================================
function s = num(x)
if abs(x) >= 1e4 && abs(x) < 1e7, s = sprintf('%.0f',x); else, s = sprintf('%.4g',x); end
if strcmp(s,'-0'), s = '0'; end
end

function s = pick(c,a,b)
if c, s = a; else, s = b; end
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

%% =========================================================================
%  UI helpers
%  =========================================================================
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
    'e.g. 5/(s+10) or 20*(s+10)/s.'};
end
