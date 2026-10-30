function Chapter4_ModellingInTheLaplaceDomainApp
%CHAPTER4_MODELLINGINTHELAPLACEDOMAINAPP Interactive GUI for MEC3079S Chapter 4 — Modelling in the Laplace domain.
%
%   Run Chapter4_ModellingInTheLaplaceDomainApp to open the app. The tabs follow the chapter:
%     1. Transform table    (4.2): common signals and their Laplace
%        transforms; differentiate (x s) and integrate (/ s) to move along
%        the table.
%     2. RLC circuit        (4.3): impedances, transfer functions to any
%        component voltage or the current, response and poles.
%     3. Mass-spring-damper (4.4-4.5): translational and rotational systems,
%        transformed free body diagrams and an animated response.
%     4. Gears              (4.6.1): reflecting impedances and torques to the
%        output or input shaft (example of Fig 4.24).
%     5. Gear train         (4.6.2): cascaded gear ratios.
%
%   Interaction:
%     - Tab 1: drag the poles of F(s) (exponential: b; sinusoids: w).
%     - Tab 2: drag the circuit poles (R and C follow, L fixed); click R, L, C or
%       the current arrow in the circuit to choose the output.
%     - Tab 3: drag the poles (D and K follow, M or J fixed) and the dashed
%       steady-state line (sets the step force F = K x_ss).
%     - Tab 4: drag the mesh point between the gears to change N2 (the ratio).
%     - Tabs 3 and 4: Play animates the response.
%     - Tab 5: drag the first gear to turn the gear train.
%
%   Requires the Control System Toolbox and the Symbolic Math Toolbox.

cBlue  = [0.00 0.45 0.74];
cOrange= [0.85 0.33 0.10];
cGreen = [0.47 0.67 0.19];
cPurple= [0.49 0.18 0.56];
cGrey  = [0.55 0.55 0.55];

fig = uifigure('Name','MEC3079S Chapter 4 — Modelling in the Laplace domain', ...
    'Position',[50 40 1340 860]);
mainGrid = uigridlayout(fig,[1 1],'Padding',[0 0 0 0]);
tg = uitabgroup(mainGrid);

% Drag state shared by all interactive plots
drag = struct('active',false,'ax',[],'move',[],'done',[],'p0',[0 0], ...
    'last',[],'xl',[],'yl',[],'t',tic);
fig.WindowButtonMotionFcn = @(~,~) onMotion();
fig.WindowButtonUpFcn = @(~,~) onRelease();
anim = struct('running',false);   % animation state (tabs 3 and 4)

%% =====================================================================
%  Tab 1: Laplace transform table
%  =====================================================================
t1 = uitab(tg,'Title','Transform table');
g1 = uigridlayout(t1,[1 2],'ColumnWidth',{340,'1x'});

c1 = uigridlayout(g1,[12 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{96,22,22,22,22,22,22,22,22,22,'1x',22});
at(uilabel(c1,'Text',['Table 4.1: one-sided signals (f(t) = 0 for t < 0) and their Laplace ' ...
    'transforms. With zero initial conditions, differentiating multiplies F(s) by s and ' ...
    'integrating divides it by s, moving along the table. Drag the poles of F(s).'], ...
    'FontWeight','bold','WordWrap','on'),1,[1 2]);

% name, a, b (or w), n  (values from the notes' code)
fun1 = { ...
    'Impulse  a δ(t)',            1,  1, 3
    'Step  a',                    3,  1, 3
    'Ramp  a t',                  1,  1, 3
    'Parabolic  a t²/2',          4,  1, 3
    'nth-order  a tⁿ/n!',         1,  1, 3
    'Exponential  a e^(−bt)',    -6,  1, 3
    'Sinusoid  a sin(ωt)',       -5,  9, 3
    'Cosinusoid  a cos(ωt)',      2,  5, 3};
at(uilabel(c1,'Text','Function'),2,1);
dd1Fun = at(uidropdown(c1,'Items',fun1(:,1)','Value',fun1{2,1}),2,2);
at(uilabel(c1,'Text','a'),3,1);
ef1a = at(uieditfield(c1,'numeric','Value',3),3,2);
lbl1b = at(uilabel(c1,'Text','b'),4,1);
ef1b = at(uieditfield(c1,'numeric','Value',1),4,2);
lbl1n = at(uilabel(c1,'Text','n'),5,1);
ef1n = at(uieditfield(c1,'numeric','Value',3,'Limits',[0 10],'RoundFractionalValues','on'),5,2);
g1b = at(uigridlayout(c1,[1 3],'Padding',[0 0 0 0]),6,[1 2]);
btn1Diff = uibutton(g1b,'Text','d/dt  (× s)');
btn1Int  = uibutton(g1b,'Text','∫ dt  (÷ s)');
btn1Reset = uibutton(g1b,'Text','Reset');
lbl1m = at(uilabel(c1,'Text','','FontAngle','italic'),7,[1 2]);
at(uilabel(c1,'Text','Plot up to t (0=auto)'),8,1);
ef1T = at(uieditfield(c1,'numeric','Value',0,'Limits',[0 Inf]),8,2);
at(uilabel(c1,'Text','Results','FontWeight','bold'),10,[1 2]);
ta1 = at(uitextarea(c1,'Editable','off','FontName','Monospaced'),11,[1 2]);
btn1 = at(uibutton(c1,'Text','Update'),12,[1 2]);

r1 = uigridlayout(g1,[3 2],'RowHeight',{'fit','fit','1x'},'ColumnWidth',{'1.6x','1x'});
lbl1Pair = at(uilabel(r1,'Text','','Interpreter','latex','FontSize',18),1,[1 2]);
lbl1Num  = at(uilabel(r1,'Text','','Interpreter','latex','FontSize',18),2,[1 2]);
ax1f = at(uiaxes(r1),3,1);
ax1s = at(uiaxes(r1),3,2);

m1 = 0;   % number of differentiations (> 0) or integrations (< 0)
dd1Fun.ValueChangedFcn = @(~,~) loadFun1();
[ef1a.ValueChangedFcn, ef1b.ValueChangedFcn, ef1n.ValueChangedFcn, ef1T.ValueChangedFcn] = deal(@(~,~) update1());
btn1Diff.ButtonPushedFcn = @(~,~) shift1(1);
btn1Int.ButtonPushedFcn  = @(~,~) shift1(-1);
btn1Reset.ButtonPushedFcn = @(~,~) shift1(-m1);
btn1.ButtonPushedFcn = @(~,~) update1();
ax1s.Interactions = [];

%% =====================================================================
%  Tab 2: RLC circuit
%  =====================================================================
t2 = uitab(tg,'Title','RLC circuit');
g2 = uigridlayout(t2,[1 2],'ColumnWidth',{340,'1x'});

c2 = uigridlayout(g2,[11 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{96,22,22,22,22,22,22,22,22,'1x',22});
at(uilabel(c2,'Text',['Mesh analysis (KVL) or the transform method: replace each component ' ...
    'by its impedance Z_R = R, Z_L = Ls, Z_C = 1/(Cs); then V(s) = [Ls + R + 1/(Cs)] I(s), and ' ...
    'any component voltage is its impedance times I(s).'],'FontWeight','bold','WordWrap','on'),1,[1 2]);
at(uilabel(c2,'Text','Resistance R (Ω)'),2,1);
ef2R = at(uieditfield(c2,'numeric','Value',1,'Limits',[0 Inf]),2,2);
at(uilabel(c2,'Text','Inductance L (H)'),3,1);
ef2L = at(uieditfield(c2,'numeric','Value',1,'Limits',[1e-9 Inf]),3,2);
at(uilabel(c2,'Text','Capacitance C (F)'),4,1);
ef2C = at(uieditfield(c2,'numeric','Value',0.25,'Limits',[1e-12 Inf]),4,2);
at(uilabel(c2,'Text','Output'),5,1);
dd2Out = at(uidropdown(c2,'Items',{'Capacitor voltage V_C','Resistor voltage V_R', ...
    'Inductor voltage V_L','Current I'}),5,2);
at(uilabel(c2,'Text','Step input V (V)'),6,1);
ef2V = at(uieditfield(c2,'numeric','Value',1),6,2);
cb2Z = at(uicheckbox(c2,'Text','Show the transformed circuit (impedances)'),7,[1 2]);
at(uilabel(c2,'Text','Drag the poles; click a component to pick the output.','FontAngle','italic'),8,[1 2]);
at(uilabel(c2,'Text','Results','FontWeight','bold'),9,[1 2]);
ta2 = at(uitextarea(c2,'Editable','off','FontName','Monospaced'),10,[1 2]);
btn2 = at(uibutton(c2,'Text','Update'),11,[1 2]);

r2 = uigridlayout(g2,[3 2],'RowHeight',{'1.1x','fit','1x'},'ColumnWidth',{'1.5x','1x'});
ax2c = at(uiaxes(r2),1,[1 2]);
lbl2TF = at(uilabel(r2,'Text','','Interpreter','latex','FontSize',18,'HorizontalAlignment','center'),2,[1 2]);
ax2y = at(uiaxes(r2),3,1);
ax2p = at(uiaxes(r2),3,2);

[ef2R.ValueChangedFcn, ef2L.ValueChangedFcn, ef2C.ValueChangedFcn, dd2Out.ValueChangedFcn, ...
    ef2V.ValueChangedFcn, cb2Z.ValueChangedFcn] = deal(@(~,~) update2());
btn2.ButtonPushedFcn = @(~,~) update2();
[ax2p.Interactions, ax2y.Interactions] = deal([]);

%% =====================================================================
%  Tab 3: Mass-spring-damper (translational and rotational)
%  =====================================================================
t3 = uitab(tg,'Title','Mass-spring-damper');
g3 = uigridlayout(t3,[1 2],'ColumnWidth',{340,'1x'});

c3 = uigridlayout(g3,[12 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{96,22,22,22,22,22,22,22,22,22,'1x',22});
at(uilabel(c3,'Text',['Sum of mechanical impedances × displacement = applied force (or torque): ' ...
    '[Ms² + Ds + K]X(s) = F(s) and [Js² + Ds + K]θ(s) = T(s). Press Play to animate the ' ...
    'step response.'],'FontWeight','bold','WordWrap','on'),1,[1 2]);
at(uilabel(c3,'Text','System'),2,1);
dd3Sys = at(uidropdown(c3,'Items',{'Translational (4.4.2)','Rotational (4.5.2)'}),2,2);
lbl3M = at(uilabel(c3,'Text','Mass M (kg)'),3,1);
ef3M = at(uieditfield(c3,'numeric','Value',1,'Limits',[1e-9 Inf]),3,2);
lbl3D = at(uilabel(c3,'Text','Damper D (N·s/m)'),4,1);
ef3D = at(uieditfield(c3,'numeric','Value',0.5,'Limits',[0 Inf]),4,2);
lbl3K = at(uilabel(c3,'Text','Spring K (N/m)'),5,1);
ef3K = at(uieditfield(c3,'numeric','Value',4,'Limits',[0 Inf]),5,2);
lbl3F = at(uilabel(c3,'Text','Step force F (N)'),6,1);
ef3F = at(uieditfield(c3,'numeric','Value',1),6,2);
cb3Z = at(uicheckbox(c3,'Text','Show the transformed free body diagram'),7,[1 2]);
btn3Play = at(uibutton(c3,'Text','▶ Play'),8,[1 2]);
at(uilabel(c3,'Text','Results','FontWeight','bold'),10,[1 2]);
ta3 = at(uitextarea(c3,'Editable','off','FontName','Monospaced'),11,[1 2]);
btn3 = at(uibutton(c3,'Text','Update'),12,[1 2]);

r3 = uigridlayout(g3,[3 2],'RowHeight',{'1.1x','fit','1x'},'ColumnWidth',{'1.5x','1x'});
ax3m = at(uiaxes(r3),1,[1 2]);
lbl3TF = at(uilabel(r3,'Text','','Interpreter','latex','FontSize',18,'HorizontalAlignment','center'),2,[1 2]);
ax3y = at(uiaxes(r3),3,1);
ax3p = at(uiaxes(r3),3,2);

[dd3Sys.ValueChangedFcn, ef3M.ValueChangedFcn, ef3D.ValueChangedFcn, ef3K.ValueChangedFcn, ...
    ef3F.ValueChangedFcn, cb3Z.ValueChangedFcn] = deal(@(~,~) update3());
btn3.ButtonPushedFcn = @(~,~) update3();
btn3Play.ButtonPushedFcn = @(~,~) play3();
[ax3p.Interactions, ax3y.Interactions] = deal([]);
sim3 = struct('t',[],'x',[]);

%% =====================================================================
%  Tab 4: Gears (reflecting impedances, Fig 4.24)
%  =====================================================================
t4 = uitab(tg,'Title','Gears');
g4 = uigridlayout(t4,[1 2],'ColumnWidth',{340,'1x'});

c4 = uigridlayout(g4,[15 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{110,22,22,22,22,22,22,22,22,22,22,22,22,'1x',22});
at(uilabel(c4,'Text',['θ₂/θ₁ = N₁/N₂ and T₂/T₁ = N₂/N₁. Impedances are reflected from the source ' ...
    'to the destination shaft by multiplying by (N_destination/N_source)²; the applied torque is ' ...
    'reflected by the gear ratio (Fig 4.24 example). Press Play to animate.'], ...
    'FontWeight','bold','WordWrap','on'),1,[1 2]);
at(uilabel(c4,'Text','Reflect to'),2,1);
dd4Ref = at(uidropdown(c4,'Items',{'Output shaft (θ₂/T₁)','Input shaft (θ₁/T₁)'}),2,2);
names4 = {'J₁ (kg·m²)','D₁ (N·m·s/rad)','N₁ (teeth)','N₂ (teeth)','J₂ (kg·m²)','D₂ (N·m·s/rad)','K₂ (N·m/rad)','Step torque T₁ (N·m)'};
vals4  = [1 1 15 45 2 1 20 1];
ef4 = gobjects(1,numel(names4));
for k = 1:numel(names4)
    at(uilabel(c4,'Text',names4{k}),2+k,1);
    ef4(k) = at(uieditfield(c4,'numeric','Value',vals4(k)),2+k,2);
end
ef4(3).Limits = [1 500]; ef4(4).Limits = [1 500];
btn4Play = at(uibutton(c4,'Text','▶ Play'),11,[1 2]);
at(uilabel(c4,'Text','Results','FontWeight','bold'),13,[1 2]);
ta4 = at(uitextarea(c4,'Editable','off','FontName','Monospaced'),14,[1 2]);
btn4 = at(uibutton(c4,'Text','Update'),15,[1 2]);

r4 = uigridlayout(g4,[3 2],'RowHeight',{'fit','1.3x','1x'},'ColumnWidth',{'1x','1x'});
lbl4TF = at(uilabel(r4,'Text','','Interpreter','latex','FontSize',18,'HorizontalAlignment','center'),1,[1 2]);
ax4g = at(uiaxes(r4),2,[1 2]);
ax4y = at(uiaxes(r4),3,[1 2]);

dd4Ref.ValueChangedFcn = @(~,~) update4();
for k = 1:numel(ef4), ef4(k).ValueChangedFcn = @(~,~) update4(); end
btn4.ButtonPushedFcn = @(~,~) update4();
btn4Play.ButtonPushedFcn = @(~,~) play4();
sim4 = struct('t',[],'th1',[],'th2',[]);

%% =====================================================================
%  Tab 5: Gear train
%  =====================================================================
t5 = uitab(tg,'Title','Gear train');
g5 = uigridlayout(t5,[1 2],'ColumnWidth',{340,'1x'});

c5 = uigridlayout(g5,[11 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{80,22,22,22,22,22,22,22,22,'1x',0});
at(uilabel(c5,'Text',['A gear train cascades smaller ratios: the equivalent ratio is the product ' ...
    'of the individual ratios. Gears on the same shaft turn together. Drag the first gear to ' ...
    'turn the train.'],'FontWeight','bold','WordWrap','on'),1,[1 2]);
vals5 = [12 24 10 25 12 30];
ef5 = gobjects(1,6);
for k = 1:6
    at(uilabel(c5,'Text',sprintf('N%s (teeth)',char(8320+k))),1+k,1);
    ef5(k) = at(uieditfield(c5,'numeric','Value',vals5(k),'Limits',[4 120],'RoundFractionalValues','on'),1+k,2);
end
at(uilabel(c5,'Text','Input angle θ₁ (deg)'),8,1);
ef5th = at(uieditfield(c5,'numeric','Value',0),8,2);
ta5 = at(uitextarea(c5,'Editable','off','FontName','Monospaced'),10,[1 2]);

r5 = uigridlayout(g5,[2 1],'RowHeight',{'fit','1x'});
lbl5 = uilabel(r5,'Text','','Interpreter','latex','FontSize',18,'HorizontalAlignment','center');
ax5 = uiaxes(r5);

for k = 1:6, ef5(k).ValueChangedFcn = @(~,~) update5(); end
ef5th.ValueChangedFcn = @(~,~) update5();
ax5.Interactions = [];

% Initial draw
loadFun1(); update2(); update3(); update4(); update5();

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
        if isvalid(drag.ax)
            drag.ax.XLimMode = 'auto';
            drag.ax.YLimMode = 'auto';
        end
        if ~isempty(drag.done), drag.done(); end
    end

    function applyDrag(pt)
        drag.move(pt,drag.p0);
        % Hold the dragged axes still so the object follows the mouse
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
    function loadFun1()
        i = find(strcmp(fun1(:,1),dd1Fun.Value));
        ef1a.Value = fun1{i,2};
        ef1b.Value = fun1{i,3};
        ef1n.Value = fun1{i,4};
        m1 = 0;
        update1();
    end

    function shift1(d)
        m1 = m1 + d;
        update1();
    end

    function setB1(v)
        ef1b.Value = v;
        update1();
    end

    function update1()
        try
            t = sym('t');  s = sym('s');  tau = sym('tau');
            i = find(strcmp(fun1(:,1),dd1Fun.Value));
            a = ef1a.Value;  b = ef1b.Value;  n = ef1n.Value;
            H = heaviside(t);
            kind = i;
            set([lbl1b ef1b],'Visible',onoff(any(kind == [6 7 8])));
            set([lbl1n ef1n],'Visible',onoff(kind == 5));
            if kind == 6, lbl1b.Text = 'b'; else, lbl1b.Text = 'ω (rad/s)'; end
            switch kind
                case 1, f = a*dirac(t);              gen = {'a\delta(t)','a'};
                case 2, f = a*H;                     gen = {'a','\frac{a}{s}'};
                case 3, f = a*t*H;                   gen = {'at','\frac{a}{s^2}'};
                case 4, f = a*t^2/2*H;               gen = {'\frac{1}{2}at^2','\frac{a}{s^3}'};
                case 5, f = a*t^n/factorial(n)*H;    gen = {'\frac{1}{n!}at^n','\frac{a}{s^{n+1}}'};
                case 6, f = a*exp(-b*t)*H;           gen = {'ae^{-bt}','\frac{a}{s+b}'};
                case 7, f = a*sin(b*t)*H;            gen = {'a\sin(\omega t)','\frac{a\omega}{s^2+\omega^2}'};
                case 8, f = a*cos(b*t)*H;            gen = {'a\cos(\omega t)','\frac{as}{s^2+\omega^2}'};
            end
            F = simplify(laplace(f,t,s));

            % Differentiate (x s) or integrate (/ s) m1 times
            fm = f;
            if m1 > 0 && kind == 1, m1 = 0; end         % the impulse cannot be differentiated here
            for k = 1:abs(m1)
                if m1 > 0
                    if has(fm,dirac(t)), m1 = k - 1; break, end
                    fm = simplify(diff(fm,t));
                else
                    fm = integrateOneSided(fm,t,tau);
                end
            end
            Fm = simplify(laplace(fm,t,s));
            rule = simplify(s^m1*F);
            ok = isAlways(simplify(Fm - rule) == 0,'Unknown','false');
            btn1Diff.Enable = onoff(~has(fm,dirac(t)));

            lbl1Pair.Text = sprintf('$\\mathrm{Table\\ 4.1:}\\quad f(t)=%s\\quad\\Longleftrightarrow\\quad F(s)=%s$',gen{:});
            if m1 == 0
                lbl1Num.Text = sprintf('$f(t)=%s\\quad\\Longleftrightarrow\\quad F(s)=%s$',texOf(f),latex(F));
                lbl1m.Text = '';
            else
                if m1 > 0
                    op = sprintf('\\frac{d^{%d}}{dt^{%d}}f(t)',m1,m1);
                    lbl1m.Text = sprintf('Differentiated %d time(s): F(s) × s^%d',m1,m1);
                else
                    op = sprintf('\\int^{(%d)} f\\,dt',-m1);
                    lbl1m.Text = sprintf('Integrated %d time(s): F(s) ÷ s^%d',-m1,-m1);
                end
                lbl1Num.Text = sprintf('$%s=%s\\quad\\Longleftrightarrow\\quad s^{%d}F(s)=%s$',op,texOf(fm),m1,latex(Fm));
            end

            % Plot (impulses as arrows)
            T = ef1T.Value;
            if T <= 0
                switch kind
                    case 6, T = min(max(5/abs(b),1),50);
                    case {7,8}, T = 4*2*pi/max(abs(b),1e-3);
                    otherwise, T = 5;
                end
            end
            tt = linspace(-0.5,T,2000)';
            [cImp,rest] = splitImpulse(fm,t);
            fh = matlabFunction(rest,'Vars',t);
            fv = double(fh(tt)) + 0*tt;
            cla(ax1f); hold(ax1f,'on');
            plot(ax1f,tt,fv,'Color',cBlue,'LineWidth',2);
            if cImp ~= 0
                yTop = cImp;
                if yTop > 0, mk = '^'; else, mk = 'v'; end
                plot(ax1f,[0 0],[0 yTop],'Color',cOrange,'LineWidth',2.5);
                plot(ax1f,0,yTop,mk,'MarkerFaceColor',cOrange,'MarkerEdgeColor',cOrange,'MarkerSize',10);
                text(ax1f,0.03*T,yTop,sprintf('  %.3g\\delta(t)',cImp),'Color',cOrange,'FontSize',13);
            end
            xline(ax1f,0,':k');  yline(ax1f,0,':k');
            hold(ax1f,'off'); grid(ax1f,'on');
            xlim(ax1f,tt([1 end]));
            title(ax1f,'f(t) (zero for t < 0)'); xlabel(ax1f,'t (s)');

            % Poles and zeros of F(s); exponential and sinusoid poles are draggable
            [nn,dd] = numden(Fm);
            pz = double(roots(sym2poly(dd)));  zz = double(roots(sym2poly(nn)));
            cla(ax1s); hold(ax1s,'on');
            R = max([abs(pz); abs(zz); 1])*1.4;
            xline(ax1s,0,'k'); yline(ax1s,0,'k');
            hp = plot(ax1s,real(pz),imag(pz),'x','Color',cOrange,'MarkerSize',14,'LineWidth',3);
            plot(ax1s,real(zz),imag(zz),'o','Color',cBlue,'MarkerSize',10,'LineWidth',2);
            hold(ax1s,'off'); grid(ax1s,'on');
            ax1s.DataAspectRatio = [1 1 1];
            xlim(ax1s,[-R R]); ylim(ax1s,[-R R]);
            set(ax1s.Children,'HitTest','off');
            if any(kind == [6 7 8])
                hp.HitTest = 'on';
                if kind == 6
                    hp.ButtonDownFcn = @(~,~) startDrag(ax1s,@(pt,~) setB1(-pt(1)),@update1);
                    title(ax1s,'Poles (x) and zeros (o) of F(s): drag the pole (b)');
                else
                    hp.ButtonDownFcn = @(~,~) startDrag(ax1s,@(pt,~) setB1(max(abs(pt(2)),0.05)),@update1);
                    title(ax1s,'Poles (x) and zeros (o) of F(s): drag a pole (ω)');
                end
            else
                title(ax1s,'Poles (x) and zeros (o) of F(s)');
            end
            xlabel(ax1s,'Real axis'); ylabel(ax1s,'Imaginary axis');

            txt = { ...
                ['f(t) = ' char(simplify(fm))]
                ['F(s) = ' char(Fm)]};
            if m1 ~= 0
                txt = [txt; {''; sprintf('Rule: L{f^(%d)} = s^%d F(s) = %s',m1,m1,char(rule)); ...
                    ['L{} computed directly agrees: ' mark(ok)]}];
            end
            txt = [txt; {''; tableEntry(Fm)}];
            if kind == 6 && m1 == 0
                if b > 0, txt{end+1} = 'b > 0: f(t) decays to 0 (pole in the LHP).';
                elseif b < 0, txt{end+1} = 'b < 0: f(t) grows without bound (pole in the RHP).';
                else, txt{end+1} = 'b = 0: f(t) stays at a (pole at the origin).'; end
            end
            if has(fm,dirac(t)) && kind ~= 1
                txt = [txt; {''; 'The one-sided signal jumps at t = 0, so its'; ...
                    'derivative contains an impulse (the 0- definition'; 'of the transform includes it).'}];
            end
            ta1.Value = flatLines(txt);
        catch err
            showError(ta1,err);
        end
    end

%% =====================================================================
%  Tab 2 callbacks
%  =====================================================================
    function update2()
        try
            R = ef2R.Value;  L = ef2L.Value;  C = ef2C.Value;  V0 = ef2V.Value;
            s = tf('s');
            Y = 1/(L*s + R + 1/(C*s));                 % I(s)/V(s)
            Y = minreal(Y);
            switch dd2Out.Value(1:3)
                case 'Cap', G = minreal(Y/(C*s)); name = 'V_C';  sel = 'C';
                    texG = '\frac{V_C(s)}{V(s)}=\frac{\frac{1}{Cs}}{Ls+R+\frac{1}{Cs}}=\frac{\frac{1}{LC}}{s^2+\frac{R}{L}s+\frac{1}{LC}}';
                case 'Res', G = minreal(R*Y);     name = 'V_R';  sel = 'R';
                    texG = '\frac{V_R(s)}{V(s)}=\frac{R}{Ls+R+\frac{1}{Cs}}=\frac{\frac{R}{L}s}{s^2+\frac{R}{L}s+\frac{1}{LC}}';
                case 'Ind', G = minreal(L*s*Y);   name = 'V_L';  sel = 'L';
                    texG = '\frac{V_L(s)}{V(s)}=\frac{Ls}{Ls+R+\frac{1}{Cs}}=\frac{s^2}{s^2+\frac{R}{L}s+\frac{1}{LC}}';
                case 'Cur', G = Y;                name = 'I';    sel = 'I';
                    texG = '\frac{I(s)}{V(s)}=\frac{1}{Ls+R+\frac{1}{Cs}}=\frac{\frac{1}{L}s}{s^2+\frac{R}{L}s+\frac{1}{LC}}';
            end
            lbl2TF.Text = ['$' texG '$'];
            drawRLC(ax2c,cb2Z.Value,sel);

            p = pole(G);  z = zero(G);
            wn = 1/sqrt(L*C);  zeta = R/2*sqrt(C/L);
            Tf = min(max(10/max(zeta*wn,1e-3),1),200);
            t = linspace(0,Tf,2000)';
            y = V0*step(G,t);
            cla(ax2y);
            plot(ax2y,t,y,'Color',cOrange,'LineWidth',2);
            grid(ax2y,'on');
            title(ax2y,sprintf('%s(t) for a %g V step',name,V0)); xlabel(ax2y,'Time (s)');
            if strcmp(sel,'I'), ylabel(ax2y,'Current (A)'); else, ylabel(ax2y,'Voltage (V)'); end
            polePlot(ax2p,p,z,@(j,pt) movePole2(p,j,pt),@update2);

            [nm,dn] = tfdata(G,'v');
            txt = { ...
                'KVL: v = L di/dt + R i + (1/C)∫i dt'
                'V(s) = [Ls + R + 1/(Cs)] I(s)'
                ''
                sprintf('%s(s)/V(s):',name)
                ['  num: ' polyStr(nm)]
                ['  den: ' polyStr(dn)]
                ''
                sprintf('w_n = 1/sqrt(LC) = %.4g rad/s',wn)
                sprintf('zeta = (R/2) sqrt(C/L) = %.4g',zeta)
                'Poles:'};
            txt = [txt; rootsStr(p)];
            txt{end+1} = sprintf('Steady state of %s for the step: %.4g',name,V0*dcgain(G));
            ta2.Value = flatLines(txt);
        catch err
            showError(ta2,err);
        end
    end

%% =====================================================================
%  Tab 3 callbacks
%  =====================================================================
    function update3()
        try
            rot = startsWith(dd3Sys.Value,'Rot');
            if rot
                lbl3M.Text = 'Inertia J (kg·m²)'; lbl3D.Text = 'Damper D (N·m·s/rad)';
                lbl3K.Text = 'Spring K (N·m/rad)'; lbl3F.Text = 'Step torque T (N·m)';
            else
                lbl3M.Text = 'Mass M (kg)'; lbl3D.Text = 'Damper D (N·s/m)';
                lbl3K.Text = 'Spring K (N/m)'; lbl3F.Text = 'Step force F (N)';
            end
            M = ef3M.Value;  D = ef3D.Value;  K = ef3K.Value;  F0 = ef3F.Value;
            s = tf('s');
            G = 1/(M*s^2 + D*s + K);
            if rot
                lbl3TF.Text = '$\left[Z_J+Z_D+Z_S\right]\theta(s)=\left[Js^2+Ds+K\right]\theta(s)=T(s)\ \Rightarrow\ \frac{\theta(s)}{T(s)}=\frac{1}{Js^2+Ds+K}$';
            else
                lbl3TF.Text = '$\left[Z_M+Z_D+Z_S\right]X(s)=\left[Ms^2+Ds+K\right]X(s)=F(s)\ \Rightarrow\ \frac{X(s)}{F(s)}=\frac{1}{Ms^2+Ds+K}$';
            end
            p = pole(G);
            sig = max(-real(p));
            if K > 0 && all(real(p) < 0), Tf = min(max(8/(-max(real(p))),2),100); else, Tf = 10; end
            if ~isfinite(sig), Tf = 10; end
            t = linspace(0,Tf,1500)';
            x = F0*step(G,t);
            sim3 = struct('t',t,'x',x);
            drawMSD(0);

            cla(ax3y);
            plot(ax3y,t,x,'Color',cBlue,'LineWidth',2);
            grid(ax3y,'on'); xlabel(ax3y,'Time (s)');
            if K > 0                     % drag the final value: F = K x_ss
                hold(ax3y,'on');
                h = plot(ax3y,[0 t(end)],F0/K*[1 1],'--','Color',cOrange,'LineWidth',2);
                text(ax3y,t(end),F0/K,sprintf('x_{ss} = F/K = %.3g (drag)  ',F0/K),'Color',cOrange, ...
                    'HorizontalAlignment','right','VerticalAlignment','bottom','PickableParts','none');
                hold(ax3y,'off');
                draggable(h,ax3y,@(pt,~) setF3(pt(2)*K),@update3);
            end
            if rot, title(ax3y,'\theta(t) (rad)'); else, title(ax3y,'x(t) (m)'); end
            polePlot(ax3p,p,[],@(j,pt) movePole3(p,j,pt),@update3);

            if rot
                q = {'J','theta','T'};
            else
                q = {'M','x','F'};
            end
            txt = { ...
                sprintf('%s(s)/%s(s) = 1/(%gs^2 + %gs + %g)',q{2},q{3},M,D,K)
                ''
                'Poles:'};
            txt = [txt; rootsStr(p)];
            if K > 0
                wn = sqrt(K/M); zeta = D/(2*sqrt(K*M));
                txt = [txt; {sprintf('w_n = sqrt(K/%s) = %.4g rad/s',q{1},wn)
                    sprintf('zeta = D/(2 sqrt(K%s)) = %.4g',q{1},zeta)
                    sprintf('Steady state: %s = %s/K = %.4g',q{2},q{3},F0/K)}];
            end
            txt = [txt; {''
                'Electrical analogy (force-voltage):'
                sprintf('  %s <-> L,  D <-> R,  K <-> 1/C',q{1})
                sprintf('  %s <-> charge q,  %s <-> V',q{2},q{3})
                '  [Ls^2 + Rs + 1/C] Q(s) = V(s)'}];
            ta3.Value = flatLines(txt);
        catch err
            showError(ta3,err);
        end
    end

    function play3()
        % Animate the step response in the schematic.
        if anim.running, anim.running = false; return, end
        anim.running = true;
        btn3Play.Text = '■ Stop';
        t = sim3.t;
        nF = 150;
        idx = round(linspace(1,numel(t),nF));
        hc = [];
        for k = idx
            if ~anim.running || ~isvalid(fig), break, end
            drawMSD(k);
            if isempty(hc) || ~isvalid(hc)
                hold(ax3y,'on'); hc = plot(ax3y,t(k),sim3.x(k),'o','MarkerFaceColor',cOrange, ...
                    'MarkerEdgeColor','k','MarkerSize',9,'HandleVisibility','off'); hold(ax3y,'off');
            else
                set(hc,'XData',t(k),'YData',sim3.x(k));
            end
            drawnow
            pause(0.03);
        end
        anim.running = false;
        if isvalid(btn3Play), btn3Play.Text = '▶ Play'; end
    end

    function drawMSD(k)
        % Schematic of the mass (or inertia) with spring and damper; k is the
        % sample of the response to show (0: equilibrium).
        rot = startsWith(dd3Sys.Value,'Rot');
        Z = cb3Z.Value;
        xs = sim3.x;
        scale = 1/max(max(abs(xs)),1e-12);
        if k > 0, d = xs(k)*scale; else, d = 0; end
        ax = ax3m;
        cla(ax); hold(ax,'on');
        if ~rot
            % wall
            drawWall(ax,-0.4,0,-1.5,1.5);
            xm = 4.2 + 0.8*d;                        % left face of the mass
            labK = 'K'; labD = 'D'; labM = 'M';
            if Z, labK = 'K'; labD = 'Ds'; labM = 'Ms^2'; end
            [sx,sy] = springPts(0,xm,0.7,9,0.2);
            plot(ax,sx,sy,'k','LineWidth',1.5);
            text(ax,xm/2,1.1,['$' labK '$'],'Interpreter','latex','FontSize',16,'HorizontalAlignment','center');
            drawDamper(ax,0,xm,-0.7,2.9);
            text(ax,xm/2,-1.25,['$' labD '$'],'Interpreter','latex','FontSize',16,'HorizontalAlignment','center');
            rectangle(ax,'Position',[xm -1.1 1.6 2.2],'FaceColor',[0.85 0.9 1],'EdgeColor','k','LineWidth',1.5);
            text(ax,xm+0.8,0,['$' labM '$'],'Interpreter','latex','FontSize',18,'HorizontalAlignment','center');
            quiver(ax,xm+1.6,0,1.0,0,0,'Color',cOrange,'LineWidth',2.5,'MaxHeadSize',0.8);
            if Z, fl = '$F(s)$'; else, fl = '$f(t)$'; end
            text(ax,xm+2.7,0,fl,'Interpreter','latex','FontSize',16,'Color',cOrange);
            % displacement indicator
            plot(ax,[4.2 4.2],[1.25 1.75],':','Color',cGrey);
            plot(ax,[xm xm],[1.1 1.75],'Color',cBlue,'LineWidth',1.5);
            quiver(ax,xm,1.6,0.6,0,0,'Color',cBlue,'LineWidth',1.5,'MaxHeadSize',0.8);
            if Z, xl = '$X(s)$'; else, xl = '$x(t)$'; end
            text(ax,xm+0.7,1.6,xl,'Interpreter','latex','FontSize',16,'Color',cBlue);
            fitView(ax,[-0.8 9],[-1.8 2.1]);
            title(ax,'Translational mass-spring-damper (displacement scaled for display)');
        else
            th = d*pi/2;                               % rotation scaled to at most 90 deg
            labK = 'K'; labD = 'D'; labJ = 'J';
            if Z, labD = 'Ds'; labJ = 'Js^2'; end
            plot(ax,[-0.5 2],[0 0],'k','LineWidth',2);              % shaft
            % cylinder (side view)
            cx = 2;  a = 0.35;  bb = 1.0;  Lc = 1.8;
            fill(ax,[cx cx+Lc cx+Lc cx],[-bb -bb bb bb],[0.85 0.9 1],'EdgeColor','none');
            plot(ax,[cx cx+Lc],[bb bb],'k','LineWidth',1.5); plot(ax,[cx cx+Lc],[-bb -bb],'k','LineWidth',1.5);
            ph = linspace(-pi/2,pi/2,60);
            plot(ax,cx+Lc+a*cos(ph),bb*sin(ph),'k','LineWidth',1.5);
            ph2 = linspace(0,2*pi,100);
            fill(ax,cx+a*cos(ph2),bb*sin(ph2),[0.75 0.82 0.95],'EdgeColor','k','LineWidth',1.5);
            % rotating marker on the front face
            plot(ax,[cx cx+a*0.9*sin(th)],[0 bb*0.9*cos(th)],'Color',cOrange,'LineWidth',3);
            plot(ax,cx+a*0.9*sin(th),bb*0.9*cos(th),'o','MarkerFaceColor',cOrange,'MarkerEdgeColor','k');
            text(ax,cx+Lc/2+0.2,0,['$' labJ '$'],'Interpreter','latex','FontSize',18,'HorizontalAlignment','center');
            % spring and damper to the wall
            xw = 7;
            drawWall(ax,xw,xw+0.4,-1.5,1.5);
            drawDamper(ax,cx+Lc+a,xw,0.6,1.2,true);
            text(ax,(cx+Lc+a+xw)/2,1.1,['$' labD '$'],'Interpreter','latex','FontSize',16,'HorizontalAlignment','center');
            [sx,sy] = springPts(cx+Lc+a,xw,-0.6,9,0.18);
            plot(ax,sx,sy,'k','LineWidth',1.5);
            text(ax,(cx+Lc+a+xw)/2,-1.05,['$' labK '$'],'Interpreter','latex','FontSize',16,'HorizontalAlignment','center');
            % torque and angle arrows
            arcArrow(ax,0.2,0,0.35,cOrange);
            if Z, tl = '$T(s)$'; al = '$\theta(s)$'; else, tl = '$\tau(t)$'; al = '$\theta(t)$'; end
            text(ax,0.2,0.75,tl,'Interpreter','latex','FontSize',16,'Color',cOrange,'HorizontalAlignment','center');
            arcArrow(ax,1.1,0,0.35,cBlue);
            text(ax,1.1,0.75,al,'Interpreter','latex','FontSize',16,'Color',cBlue,'HorizontalAlignment','center');
            fitView(ax,[-0.8 7.8],[-1.8 1.8]);
            title(ax,'Torsional mass-spring-damper (rotation scaled for display)');
        end
        hold(ax,'off');
    end

%% =====================================================================
%  Tab 4 callbacks
%  =====================================================================
    function update4()
        try
            v = arrayfun(@(e) e.Value,ef4);
            [J1,D1,N1,N2,J2,D2,K2,T1] = deal(v(1),v(2),v(3),v(4),v(5),v(6),v(7),v(8));
            n = N2/N1;                     % T2/T1 = N2/N1, theta2/theta1 = N1/N2
            s = tf('s');
            toOut = startsWith(dd4Ref.Value,'Out');
            Je = n^2*J1 + J2;  De = n^2*D1 + D2;  Ke = K2;
            G2 = n/(Je*s^2 + De*s + Ke);            % theta2/T1
            G1 = G2*n;                              % theta1/T1 = (N2/N1) theta2/T1
            if toOut
                lbl4TF.Text = sprintf(['$J_e=\\left(\\frac{N_2}{N_1}\\right)^2J_1+J_2=%.4g,\\ ' ...
                    'D_e=\\left(\\frac{N_2}{N_1}\\right)^2D_1+D_2=%.4g,\\ K_e=K_2=%.4g\\qquad ' ...
                    '\\frac{\\theta_2(s)}{T_1(s)}=\\frac{N_2/N_1}{J_es^2+D_es+K_e}$'],Je,De,Ke);
            else
                Ji = J1 + J2/n^2;  Di = D1 + D2/n^2;  Ki = K2/n^2;
                lbl4TF.Text = sprintf(['$J_i=J_1+\\left(\\frac{N_1}{N_2}\\right)^2J_2=%.4g,\\ ' ...
                    'D_i=D_1+\\left(\\frac{N_1}{N_2}\\right)^2D_2=%.4g,\\ K_i=\\left(\\frac{N_1}{N_2}\\right)^2K_2=%.4g\\qquad ' ...
                    '\\frac{\\theta_1(s)}{T_1(s)}=\\frac{1}{J_is^2+D_is+K_i}$'],Ji,Di,Ki);
            end
            p = pole(G2);
            if all(real(p) < 0), Tf = min(max(8/(-max(real(p))),2),100); else, Tf = 10; end
            t = linspace(0,Tf,1500)';
            th2 = T1*step(G2,t);  th1 = T1*step(G1,t);
            sim4 = struct('t',t,'th1',th1,'th2',th2);
            drawGears(0);
            cla(ax4y); hold(ax4y,'on');
            plot(ax4y,t,th1,'Color',cOrange,'LineWidth',2);
            plot(ax4y,t,th2,'Color',cBlue,'LineWidth',2);
            hold(ax4y,'off'); grid(ax4y,'on');
            legend(ax4y,{'\theta_1(t)','\theta_2(t)'},'Location','best');
            title(ax4y,sprintf('Step response to T_1 = %g N·m: \\theta_2 = (N_1/N_2)\\theta_1',T1));
            xlabel(ax4y,'Time (s)'); ylabel(ax4y,'Angle (rad)');

            txt = { ...
                sprintf('Gear ratio N2/N1 = %.4g',n)
                sprintf('T2 = (N2/N1) T1,  theta2 = (N1/N2) theta1')
                ''
                'Reflected to the output shaft:'
                sprintf('  Je = (N2/N1)^2 J1 + J2 = %.4g',Je)
                sprintf('  De = (N2/N1)^2 D1 + D2 = %.4g',De)
                sprintf('  Ke = K2 = %.4g',Ke)
                sprintf('  theta2/T1 = %.4g/(%.4gs^2 + %.4gs + %.4g)',n,Je,De,Ke)
                ''
                'Reflected to the input shaft:'
                sprintf('  Ji = J1 + (N1/N2)^2 J2 = %.4g',J1 + J2/n^2)
                sprintf('  Di = D1 + (N1/N2)^2 D2 = %.4g',D1 + D2/n^2)
                sprintf('  Ki = (N1/N2)^2 K2 = %.4g',K2/n^2)
                ''
                sprintf('Steady state: theta2 = %.4g rad, theta1 = %.4g rad',th2(end),th1(end))};
            ta4.Value = flatLines(txt);
        catch err
            showError(ta4,err);
        end
    end

    function play4()
        if anim.running, anim.running = false; return, end
        anim.running = true;
        btn4Play.Text = '■ Stop';
        t = sim4.t;
        idx = round(linspace(1,numel(t),150));
        hc = [];
        for k = idx
            if ~anim.running || ~isvalid(fig), break, end
            drawGears(k);
            if isempty(hc) || ~all(isvalid(hc))
                hold(ax4y,'on');
                hc = [plot(ax4y,t(k),sim4.th1(k),'o','MarkerFaceColor',cOrange,'MarkerEdgeColor','k','MarkerSize',8,'HandleVisibility','off'), ...
                      plot(ax4y,t(k),sim4.th2(k),'o','MarkerFaceColor',cBlue,'MarkerEdgeColor','k','MarkerSize',8,'HandleVisibility','off')];
                hold(ax4y,'off');
            else
                set(hc(1),'XData',t(k),'YData',sim4.th1(k));
                set(hc(2),'XData',t(k),'YData',sim4.th2(k));
            end
            drawnow
            pause(0.03);
        end
        anim.running = false;
        if isvalid(btn4Play), btn4Play.Text = '▶ Play'; end
    end

    function drawGears(k)
        % End-on view of the meshed gears with the shaft loads (Fig 4.24).
        N1 = ef4(3).Value;  N2 = ef4(4).Value;
        sc = 1/max(abs(sim4.th1));                     % rotation scaled for display
        if k > 0, a1 = sim4.th1(k)*sc*pi; else, a1 = 0; end
        a2 = -a1*N1/N2;                                % meshed gears turn in opposite directions
        m = 5/(N1 + N2);
        r1 = m*N1;  r2 = m*N2;
        ax = ax4g;
        cla(ax); hold(ax,'on');
        drawGear(ax,0,0,r1,N1,a1,[1 0.85 0.75]);
        drawGear(ax,r1 + r2,0,r2,N2,a2 + pi/N2*(mod(N2,2)==0),[0.8 0.88 1]);
        text(ax,0,-r1-0.45,sprintf('N_1 = %g,  J_1, D_1\nT_1, \\theta_1',N1),'HorizontalAlignment','center','FontSize',12);
        text(ax,r1+r2,-r2-0.45,sprintf('N_2 = %g,  J_2, D_2, K_2\n\\theta_2 = (N_1/N_2)\\theta_1',N2),'HorizontalAlignment','center','FontSize',12);
        if k == 0                      % mesh point: drag left/right to change the ratio N2/N1
            h = plot(ax,r1,0,'o','MarkerSize',13,'MarkerFaceColor',cOrange,'MarkerEdgeColor','k','LineWidth',1.5);
            text(ax,r1,max(r1,r2)+0.15,sprintf('N_2/N_1 = %.3g  (drag \\bullet)',N2/N1),'HorizontalAlignment','center', ...
                'FontSize',12,'Color',cOrange,'PickableParts','none');
            draggable(h,ax,@(pt,~) setRatio4(pt(1)),@update4);
        end
        hold(ax,'off');
        fitView(ax,[-r1-0.6, r1+2*r2+0.6],[-max(r1,r2)-1.3, max(r1,r2)+0.4]);
        title(ax,'Meshed gears (end view; rotation scaled for display)');
    end

%% =====================================================================
%  Tab 5 callbacks
%  =====================================================================
    function update5()
        N = arrayfun(@(e) e.Value,ef5);
        th1 = ef5th.Value*pi/180;
        r23 = N(1)/N(2);  r45 = N(3)/N(4);  r67 = N(5)/N(6);
        thB = -th1*r23;  thC = -thB*r45;  thD = -thC*r67;
        m = 0.08;
        r = m*N;
        % shafts: A (gear 1), B (gears 2, 3), C (gears 4, 5), D (gear 6)
        cA = [0 0];
        cB = cA + [r(1)+r(2) 0];
        cC = cB + [r(3)+r(4) 0]*[cosd(-35) sind(-35); -sind(-35) cosd(-35)];
        cD = cC + [r(5)+r(6) 0]*[cosd(30) sind(30); -sind(30) cosd(30)];
        ax = ax5;
        cla(ax); hold(ax,'on');
        col = {[1 0.85 0.75],[0.8 0.88 1],[0.85 0.95 0.8],[0.95 0.85 1],[1 0.95 0.75],[0.85 0.85 0.85]};
        % larger gear of a shaft drawn first so the smaller coaxial gear stays visible
        gears = {cA,1,th1; cB,2,thB; cB,3,thB; cC,4,thC; cC,5,thC; cD,6,thD};
        order = [1 2 3 4 5 6];
        if r(3) > r(2), order([2 3]) = [3 2]; end
        if r(5) > r(4), order([4 5]) = [5 4]; end
        hG1 = [];
        for k = order
            cc = gears{k,1};  j = gears{k,2};
            h = drawGear(ax,cc(1),cc(2),r(j),N(j),gears{k,3},col{j});
            h(1).FaceAlpha = 0.6;              % stages lie in different planes
            text(ax,cc(1) + r(j)*0.55*cos(pi/4 + (j==3 || j==5)*pi),cc(2) + r(j)*0.55*sin(pi/4 + (j==3 || j==5)*pi), ...
                sprintf('N_%d',j),'FontSize',11,'FontWeight','bold','HorizontalAlignment','center');
            if j == 1, hG1 = h; end
        end
        hold(ax,'off');
        allc = [cA; cB; cC; cD];
        rr = [r(1); max(r(2),r(3)); max(r(4),r(5)); r(6)];
        fitView(ax,[min(allc(:,1)-rr)-0.3, max(allc(:,1)+rr)+0.3],[min(allc(:,2)-rr)-0.3, max(allc(:,2)+rr)+0.3]);
        title(ax,'Gear train (end view, stages in different planes): drag gear 1 to turn it');
        set(ax.Children,'HitTest','off');
        set(hG1,'HitTest','on','ButtonDownFcn',@(~,~) gearDown5());

        ratio = N(1)*N(3)*N(5)/(N(2)*N(4)*N(6));
        lbl5.Text = sprintf(['$\\theta_4=\\frac{N_1N_3N_5}{N_2N_4N_6}\\theta_1=' ...
            '\\frac{%g\\cdot%g\\cdot%g}{%g\\cdot%g\\cdot%g}\\theta_1=%.4g\\,\\theta_1,\\qquad ' ...
            'T_4=\\frac{N_2N_4N_6}{N_1N_3N_5}T_1=%.4g\\,T_1$'],N(1),N(3),N(5),N(2),N(4),N(6),ratio,1/ratio);
        ta5.Value = { ...
            sprintf('Stage 1: theta2/theta1 = N1/N2 = %.4g',r23)
            sprintf('Stage 2: theta3/theta2 = N3/N4 = %.4g',r45)
            sprintf('Stage 3: theta4/theta3 = N5/N6 = %.4g',r67)
            sprintf('Overall: theta4/theta1 = %.4g (product)',ratio)
            sprintf('         T4/T1 = %.4g',1/ratio)
            ''
            sprintf('theta1 = %.1f deg -> theta2 = %.1f, theta3 = %.1f, theta4 = %.1f deg', ...
                ef5th.Value,abs(thB)*180/pi,abs(thC)*180/pi,abs(thD)*180/pi)
            '(meshed gears turn in opposite directions)'};
    end

    function gearDown5()
        th0 = ef5th.Value;
        startDrag(ax5,@(pt,p0) setTheta5(th0 + (atan2(pt(2),pt(1)) - atan2(p0(2),p0(1)))*180/pi),@update5);
    end

    function setRatio4(x)
        % The centre distance r1 + r2 = 5 is fixed, so the mesh point at x gives N2/N1 = (5 - x)/x.
        x = min(max(x,0.4),4.6);
        ef4(4).Value = min(max(round(ef4(3).Value*(5 - x)/x),1),500);
        update4();
    end

    function setTheta5(v)
        ef5th.Value = v;
        update5();
    end

%% =====================================================================
%  Dragging the poles of a second-order denominator s^2 + a1 s + a0
%  =====================================================================
    function [a1,a0] = movedPoles(p,j,pt,ax)
        % Poles p after moving pole j to the mouse point (left half-plane only).
        % A complex pair moves together; on the real axis the pair becomes repeated.
        x = min(pt(1),-1e-3*diff(ax.XLim));
        p = p(:);
        if numel(p) < 2, p = [p; p]; end
        if abs(imag(p(j))) > 1e-9
            y = abs(pt(2));
            if y < 0.02*diff(ax.YLim), y = 0; end
            p = [complex(x,y); complex(x,-y)];
        else
            p(j) = x;
        end
        a1 = real(-sum(p(1:2)));  a0 = real(prod(p(1:2)));
    end

    function movePole2(p,j,pt)
        [a1,a0] = movedPoles(p,j,pt,ax2p);
        L = ef2L.Value;                       % s^2 + (R/L)s + 1/(LC)
        ef2C.Value = max(1/(L*a0),1e-12);
        ef2R.Value = max(L*a1,0);
        update2();
    end

    function movePole3(p,j,pt)
        [a1,a0] = movedPoles(p,j,pt,ax3p);
        M = ef3M.Value;                       % s^2 + (D/M)s + K/M
        ef3K.Value = max(M*a0,0);
        ef3D.Value = max(M*a1,0);
        update3();
    end

    function setF3(v)
        ef3F.Value = v;
        update3();
    end

    function pickOut2(code)
        items = {'C','R','L','I'};
        dd2Out.Value = dd2Out.Items{strcmp(items,code)};
        update2();
    end

    function draggable(h,ax,moveFcn,doneFcn)
        set(h,'ButtonDownFcn',@(~,~) startDrag(ax,moveFcn,doneFcn),'PickableParts','visible');
    end

%% =====================================================================
%  Drawing helpers that use the app colours
%  =====================================================================
    function drawRLC(ax,Z,sel)
        % Series RLC circuit (Fig 4.4) or its transformed version (Fig 4.6).
        cla(ax); hold(ax,'on');
        hl = @(c) colourIf(c,sel);
        % source
        th = linspace(0,2*pi,100);
        plot(ax,0.55*cos(th),0.55*sin(th),'k','LineWidth',1.5);
        text(ax,0,0.25,'+','FontSize',16,'HorizontalAlignment','center');
        text(ax,0,-0.25,'−','FontSize',16,'HorizontalAlignment','center');
        if Z, vs = '$V(s)$'; else, vs = '$v(t)$'; end
        text(ax,-0.75,0,vs,'Interpreter','latex','FontSize',17,'HorizontalAlignment','right','Color',cOrange);
        plot(ax,[0 0 1],[0.55 2 2],'k','LineWidth',1.5);
        % inductor
        [ix,iy] = coilPts(1,3,2,4);
        hc = plot(ax,ix,iy,'Color',hl('L'),'LineWidth',4);
        if Z, lt = 'Z_L=Ls'; else, lt = 'L'; end
        hc(2) = text(ax,2,2.65,['$' lt '$'],'Interpreter','latex','FontSize',17,'HorizontalAlignment','center','Color',hl('L'));
        set(hc,'ButtonDownFcn',@(~,~) pickOut2('L'));
        plot(ax,[3 3.6],[2 2],'k','LineWidth',1.5);
        % resistor
        [rx,ry] = zigzagPts(3.6,5.6,2,6,0.25);
        hc = plot(ax,rx,ry,'Color',hl('R'),'LineWidth',2.5);
        if Z, rt = 'Z_R=R'; else, rt = 'R'; end
        hc(2) = text(ax,4.6,2.65,['$' rt '$'],'Interpreter','latex','FontSize',17,'HorizontalAlignment','center','Color',hl('R'));
        set(hc,'ButtonDownFcn',@(~,~) pickOut2('R'));
        plot(ax,[5.6 7 7],[2 2 0.18],'k','LineWidth',1.5);
        % capacitor
        cc = hl('C');
        hc = plot(ax,[6.55 7.45],[0.18 0.18],'Color',cc,'LineWidth',3.5);
        hc(2) = plot(ax,[6.55 7.45],[-0.18 -0.18],'Color',cc,'LineWidth',3.5);
        if Z, ct = 'Z_C=\frac{1}{Cs}'; else, ct = 'C'; end
        hc(3) = text(ax,6.4,0,['$' ct '$'],'Interpreter','latex','FontSize',17,'HorizontalAlignment','right','Color',cc);
        set(hc,'ButtonDownFcn',@(~,~) pickOut2('C'));
        text(ax,7.6,0.35,'+','FontSize',14); text(ax,7.6,-0.35,'−','FontSize',14);
        if Z, vc = '$V_C(s)$'; else, vc = '$v_C(t)$'; end
        text(ax,7.9,0,vc,'Interpreter','latex','FontSize',16,'Color',cc);
        plot(ax,[7 7 0 0],[-0.18 -2 -2 -0.55],'k','LineWidth',1.5);
        % current loop
        ph = linspace(3*pi/4,-pi/1.3,60);
        ic = hl('I');
        hc = plot(ax,3.6 + 1.3*cos(ph),0.6*sin(ph),'Color',ic,'LineWidth',2.5);
        e = [3.6 + 1.3*cos(ph(end)), 0.6*sin(ph(end))];
        d = e - [3.6 + 1.3*cos(ph(end-1)), 0.6*sin(ph(end-1))];
        quiver(ax,e(1),e(2),d(1)*3,d(2)*3,0,'Color',ic,'LineWidth',1.5,'MaxHeadSize',3);
        if Z, it = '$I(s)$'; else, it = '$i(t)$'; end
        hc(2) = text(ax,3.6,0,it,'Interpreter','latex','FontSize',16,'HorizontalAlignment','center','Color',ic);
        set(hc,'ButtonDownFcn',@(~,~) pickOut2('I'));
        hold(ax,'off');
        fitView(ax,[-1.9 9.6],[-2.5 3.1]);
        if Z, ttl = 'Transformed circuit: impedances (Fig 4.6)'; else, ttl = 'Series RLC circuit (Fig 4.4)'; end
        title(ax,[ttl ' — click R, L, C or i to choose the output']);
    end

    function c = colourIf(c0,sel)
        if strcmp(c0,sel), c = cOrange; else, c = [0 0 0]; end
        if strcmp(c0,'I') && ~strcmp(sel,'I'), c = cBlue; end
    end

    function polePlot(ax,p,z,moveFcn,doneFcn)
        % Pole-zero map; with moveFcn(j,pt) the poles can be dragged.
        cla(ax); hold(ax,'on');
        R = max([abs(p); abs(z); 1])*1.3;
        patch(ax,[0 R R 0],[-R -R R R],[1 0.92 0.92],'EdgeColor','none','PickableParts','none');
        xline(ax,0,'k'); yline(ax,0,'k');
        if nargin < 4
            plot(ax,real(p),imag(p),'x','Color',cOrange,'MarkerSize',13,'LineWidth',2.5);
        else
            for j = 1:numel(p)
                if imag(p(j)) < -1e-9, continue, end
                h = plot(ax,real(p(j))*[1 1],imag(p(j))*[1 -1],'x','Color',cOrange,'MarkerSize',13,'LineWidth',2.5);
                draggable(h,ax,@(pt,~) moveFcn(j,pt),doneFcn);
            end
        end
        if ~isempty(z), plot(ax,real(z),imag(z),'o','Color',cBlue,'MarkerSize',10,'LineWidth',2); end
        hold(ax,'off'); grid(ax,'on');
        ax.DataAspectRatio = [1 1 1];
        xlim(ax,[-R R]); ylim(ax,[-R R]);
        if nargin < 4, title(ax,'Poles (x) and zeros (o)'); else, title(ax,'Poles (x, drag) and zeros (o)'); end
        xlabel(ax,'Real axis'); ylabel(ax,'Imaginary axis');
    end

    function arcArrow(ax,x0,y0,r,col)
        % Curved arrow around a shaft (rotation sense).
        ph = linspace(-2.4,2.0,50);
        xx = x0 + 0.35*r*cos(ph);  yy = y0 + r*sin(ph);
        plot(ax,xx,yy,'Color',col,'LineWidth',2);
        quiver(ax,xx(end-1),yy(end-1),(xx(end)-xx(end-1))*4,(yy(end)-yy(end-1))*4,0,'Color',col, ...
            'LineWidth',2,'MaxHeadSize',4);
    end
end

%% =========================================================================
%  Helper functions
%  =========================================================================
function [c,rest] = splitImpulse(f,t)
% f = c*dirac(t) + rest; rest has the impulse removed.
rest = mapSymType(f,'dirac',@(x) sym(0));
c = double(simplify((f - rest)/dirac(t)));
if ~isfinite(c), c = 0; end
end

function g = integrateOneSided(f,t,tau)
% Integral from 0- to t of a one-sided signal: an impulse c*delta(t) becomes
% the step c*u(t), and the rest (valid for t > 0) is integrated from 0 to t.
[c,rest] = splitImpulse(f,t);
restPos = subs(rest,heaviside(t),1);
g = simplify((int(subs(restPos,t,tau),tau,0,t) + c)*heaviside(t));
end

function str = texOf(f)
% LaTeX of a one-sided signal, writing heaviside(t) as u(t).
str = latex(simplify(f));
str = strrep(str,'\mathrm{heaviside}\left(t\right)','u(t)');
end

function s = tableEntry(F)
% Name the Table 4.1 entry that F(s) matches, if any.
sv = sym('s');
[n,d] = numden(simplify(F));
dp = sym2poly(d);  np = sym2poly(n);
if numel(np) == 1 && all(dp(2:end) == 0)
    k = numel(dp) - 1;  a = np/dp(1);
    names = {'impulse  a*delta(t)','step  a','ramp  a*t','parabolic  a*t^2/2'};
    if k < numel(names)
        s = sprintf('Table 4.1: %s, with a = %.4g',names{k+1},a);
    else
        s = sprintf('Table 4.1: nth-order  a*t^n/n!, n = %d, a = %.4g',k-1,a);
    end
elseif numel(dp) == 2 && numel(np) == 1
    s = sprintf('Table 4.1: exponential  a*e^(-bt), a = %.4g, b = %.4g',np/dp(1),dp(2)/dp(1));
elseif numel(dp) == 3 && dp(2) == 0 && numel(np) == 1
    w = sqrt(dp(3)/dp(1));
    s = sprintf('Table 4.1: sinusoid  a*sin(wt), w = %.4g, a = %.4g',w,np/dp(1)/w);
elseif numel(dp) == 3 && dp(2) == 0 && numel(np) == 2 && np(2) == 0
    s = sprintf('Table 4.1: cosinusoid  a*cos(wt), w = %.4g, a = %.4g',sqrt(dp(3)/dp(1)),np(1)/dp(1));
else
    s = sprintf('Not a single Table 4.1 entry: F(s) = %s',char(partfrac(F,sv)));
end
end

function [x,y] = springPts(x0,x1,y0,n,amp)
% Zigzag spring from x0 to x1 at height y0 with straight ends.
L = x1 - x0;  e = 0.12*L;
xz = linspace(x0+e,x1-e,2*n+1);
yz = y0 + amp*[0 repmat([1 -1],1,n-1) 1 0];
yz = yz(1:numel(xz));
x = [x0 xz x1];  y = [y0 yz y0];
end

function [x,y] = zigzagPts(x0,x1,y0,n,amp)
[x,y] = springPts(x0,x1,y0,n,amp);
end

function [x,y] = coilPts(x0,x1,y0,n)
% Inductor drawn as n loops above the wire.
ph = linspace(0,2*pi*n,400);
w = (x1 - x0)/n;
x = x0 + w*ph/(2*pi) - 0.25*w*sin(ph);
y = y0 + 0.35*(1 - cos(ph))/2;
end

function drawDamper(ax,x0,x1,y0,len,reversed)
% Viscous damper between x0 (cylinder side) and x1 (rod side); len is the
% cylinder length. With reversed, the cylinder sits at x1.
if nargin < 6, reversed = false; end
h = 0.3;
if ~reversed
    cyl0 = x0 + 0.3;  cyl1 = cyl0 + len;
    plot(ax,[x0 cyl0],[y0 y0],'k','LineWidth',1.5);
    plot(ax,[cyl1 cyl0 cyl0 cyl1],[y0+h y0+h y0-h y0-h],'k','LineWidth',1.5);
    px = min(max(x1 - 1.9, cyl0 + 0.15), cyl1 - 0.1);   % piston follows the rod end at x1
    plot(ax,[px px],[y0-0.7*h y0+0.7*h],'k','LineWidth',2.5);
    plot(ax,[px x1],[y0 y0],'k','LineWidth',1.5);
else
    cyl1 = x1 - 0.3;  cyl0 = cyl1 - len;
    plot(ax,[cyl1 x1],[y0 y0],'k','LineWidth',1.5);
    plot(ax,[cyl0 cyl1 cyl1 cyl0],[y0+h y0+h y0-h y0-h],'k','LineWidth',1.5);
    px = cyl0 + 0.4*len;
    plot(ax,[px px],[y0-0.7*h y0+0.7*h],'k','LineWidth',2.5);
    plot(ax,[x0 px],[y0 y0],'k','LineWidth',1.5);
end
end

function drawWall(ax,x0,x1,y0,y1)
fill(ax,[x0 x1 x1 x0],[y0 y0 y1 y1],[0.88 0.88 0.88],'EdgeColor','k','LineWidth',1.5);
for yy = y0:0.3:y1-0.3
    plot(ax,[x0 x1],[yy yy+0.3],'Color',[0.5 0.5 0.5]);
end
end

function h = drawGear(ax,cx,cy,r,N,ang,col)
% Spur gear with N teeth (outline), a spoke at angle ang and a hub.
tooth = min(0.12*r, 2*pi*r/N*0.45);
ph = linspace(0,2*pi,N*8+1) + ang;
rr = r + tooth*(mod(floor((ph - ang)/(2*pi)*N*2),2) - 0.5);
h = gobjects(0);
if N <= 150
    h(end+1) = fill(ax,cx + rr.*cos(ph),cy + rr.*sin(ph),col,'EdgeColor','k','LineWidth',1);
else
    th = linspace(0,2*pi,200);
    h(end+1) = fill(ax,cx + r*cos(th),cy + r*sin(th),col,'EdgeColor','k','LineWidth',1);
end
h(end+1) = plot(ax,[cx cx + 0.85*r*cos(ang)],[cy cy + 0.85*r*sin(ang)],'k','LineWidth',2.5);
th = linspace(0,2*pi,60);
h(end+1) = fill(ax,cx + 0.1*r*cos(th),cy + 0.1*r*sin(th),[0.3 0.3 0.3],'EdgeColor','none');
end

function fitView(ax,xl,yl)
% Equal scaling, limits stretched to the axes shape, axes hidden.
ax.DataAspectRatio = [1 1 1];
drawnow
pos = getpixelposition(ax);
r = pos(4)/max(pos(3),1);
if diff(xl)*r > diff(yl)
    yl = mean(yl) + [-0.5 0.5]*diff(xl)*r;
else
    xl = mean(xl) + [-0.5 0.5]*diff(yl)/r;
end
xlim(ax,xl);  ylim(ax,yl);
ax.XAxis.Visible = 'off';  ax.YAxis.Visible = 'off';
ax.XGrid = 'off';  ax.YGrid = 'off';
ax.Interactions = [];
ax.Toolbar.Visible = 'off';
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

function str = polyStr(c)
c(abs(c) < 1e-12*max(abs(c))) = 0;
idx = find(c ~= 0,1);
if isempty(idx), str = '0'; return, end
c = c(idx:end);
n = numel(c) - 1;
str = '';
for i = 1:numel(c)
    if c(i) == 0, continue, end
    pw = n - i + 1;
    mag = abs(c(i));
    if pw == 0
        term = sprintf('%.4g',mag);
    elseif abs(mag - 1) < 1e-12
        term = sVar(pw);
    else
        term = sprintf('%.4g %s',mag,sVar(pw));
    end
    if isempty(str)
        if c(i) < 0, str = ['-' term]; else, str = term; end
    elseif c(i) < 0
        str = [str ' - ' term]; %#ok<AGROW>
    else
        str = [str ' + ' term]; %#ok<AGROW>
    end
end
end

function v = sVar(pw)
if pw == 1, v = 's'; else, v = sprintf('s^%d',pw); end
end

function s = mark(ok)
if ok, s = '✔'; else, s = '✘'; end
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

function showError(ta,err)
ta.Value = {'Error:'; err.message};
end
