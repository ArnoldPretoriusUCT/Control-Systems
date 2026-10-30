function Chapter10_SteadyStateErrorApp
%CHAPTER10_STEADYSTATEERRORAPP Interactive GUI for MEC3079S Chapter 10 — Steady-state error.
%
%   Run Chapter10_SteadyStateErrorApp to open the app. The tabs follow the chapter:
%     1. Reference tracking  (10.2, 10.4–10.6): test inputs, system type,
%        static error constants Kp, Kv, Ka, and e(inf) via final value theorem.
%     2. P-control design    (10.7): choose G(s) = K to meet an e(inf) spec.
%     3. Disturbances        (10.8): e(inf) = e_R(inf) + e_D(inf) for a
%        step-like plant input disturbance.
%     4. Frequency response  (10.9): read Kp, Kv, Ka off the Bode magnitude
%        response of L(s).
%
%   Interaction:
%     - Drag the red poles (x) and zeros (o) in the s-plane editor on each
%       tab (of P(s) or G(s), as selected); complex poles/zeros move as
%       conjugate pairs and real ones snap onto the origin, adding an
%       integrator. Blue crosses are the closed-loop poles. Use
%       "Add"/"Delete selected" to change the number of poles and zeros.
%     - Tab 1: drag r(t) up/down to change the amplitude a.
%     - Tab 2: drag the e(inf) spec line to redesign K, or drag along the
%       e(inf)-vs-K plot to set the simulated K.
%     - Tab 3: drag d(t) or r(t) up/down to change d or a.
%     - Tab 4: drag |L(jw)| up/down to scale L(s).
%
%   Transfer functions are entered as MATLAB expressions in s, for example
%   10/(1+s/10), 10/s/(1+s/10) or 36*(1+s)/s.
%
%   Requires the Control System Toolbox.

% Colours used throughout the app
cRef  = [0.00 0.45 0.74];
cOut  = [0.85 0.33 0.10];
cErr  = [0.47 0.67 0.19];
cDist = [0.49 0.18 0.56];
cHi   = [0.80 0.90 1.00];
cHi2  = [1.00 0.93 0.60];
keepItems = {'Low-frequency gain','zpk gain K'};
addItems = {'Add pole/zero…','Real pole','Complex pole pair','Real zero','Complex zero pair'};

fig = uifigure('Name','MEC3079S Chapter 10 — Steady-state error', ...
    'Position',[80 40 1280 880]);
mainGrid = uigridlayout(fig,[1 1],'Padding',[0 0 0 0]);
tg = uitabgroup(mainGrid);

% Drag state shared by all interactive plots
drag = struct('active',false,'ax',[],'move',[],'done',[],'p0',[0 0], ...
    'last',[],'xl',[],'yl',[],'t',tic);
fig.WindowButtonMotionFcn = @(~,~) onMotion();
fig.WindowButtonUpFcn = @(~,~) onRelease();

% Pole-zero editors, one per tab
pz = struct('ax',{},'efs',{},'target',{},'dd',{},'upd',{},'keep',{},'roots',{}, ...
    'K',{},'tau',{},'r0',{},'K0',{},'selKind',{},'selVal',{});
kSign2 = 1;   % sign of the designed K on tab 2

%% =====================================================================
%  Tab 1: Reference tracking
%  =====================================================================
t1 = uitab(tg,'Title','Reference tracking');
g1 = uigridlayout(t1,[1 2],'ColumnWidth',{340,'1x'});

c1 = uigridlayout(g1,[15 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{48,22,22,22,22,22,22,48,200,22,22,22,22,'1x',22});
at(uilabel(c1,'Text',['Unity feedback: E(s) = R(s)/(1+L(s)),  L(s) = P(s)G(s). ' ...
    'Drag poles/zeros below, or drag r(t) to change a.'], ...
    'FontWeight','bold','WordWrap','on'),1,[1 2]);

presets1 = { ...
    'Ex 10.4.2(1): L = 10/(1+s/10), step',      '10/(1+s/10)',          '1',  'Step'
    'Ex 10.4.2(2): L = 10/(s(1+s/10)), step',   '10/(s*(1+s/10))',      '1',  'Step'
    'Ex 10.4.3(1): L = 10/(1+s/10), ramp',      '10/(1+s/10)',          '1',  'Ramp'
    'Ex 10.4.3(2): L = 10/(s(1+s/10)), ramp',   '10/(s*(1+s/10))',      '1',  'Ramp'
    'Ex 10.7.2: P = 1/(s(s+1)), G = 10, ramp',  '1/(s*(s+1))',          '10', 'Ramp'
    'Type-2: L = 10(s+1)/(s^2(s+10)), parabola','10*(s+1)/(s^2*(s+10))','1',  'Parabolic'
    'Custom', '', '', ''};
at(uilabel(c1,'Text','Example'),2,1);
dd1Preset = at(uidropdown(c1,'Items',presets1(:,1)','Value',presets1{2,1}),2,2);
at(uilabel(c1,'Text','Plant P(s)'),3,1);
ef1P = at(uieditfield(c1,'text','Value',presets1{2,2}),3,2);
at(uilabel(c1,'Text','Controller G(s)'),4,1);
ef1G = at(uieditfield(c1,'text','Value',presets1{2,3}),4,2);
at(uilabel(c1,'Text','Test input r(t)'),5,1);
dd1In = at(uidropdown(c1,'Items',{'Step','Ramp','Parabolic'},'Value',presets1{2,4}),5,2);
at(uilabel(c1,'Text','Amplitude a'),6,1);
ef1a = at(uieditfield(c1,'numeric','Value',1),6,2);
at(uilabel(c1,'Text','Final time (0=auto)'),7,1);
ef1T = at(uieditfield(c1,'numeric','Value',0,'Limits',[0 Inf], ...
    'Tooltip','0 = choose automatically from the closed-loop poles'),7,2);
lbl1R = at(uilabel(c1,'Text','','Interpreter','latex','FontSize',15),8,[1 2]);
ax1pz = at(uiaxes(c1),9,[1 2]);
at(uilabel(c1,'Text','Edit in s-plane'),10,1);
dd1Tgt = at(uidropdown(c1,'Items',{'P(s)','G(s)'}),10,2);
[dd1Keep,dd1Add,btn1Del] = rootControls(c1,11,keepItems,addItems);
at(uilabel(c1,'Text','Results','FontWeight','bold'),13,1);
btn1 = at(uibutton(c1,'Text','Update'),13,2);
ta1 = at(uitextarea(c1,'Editable','off','FontName','Monospaced'),14,[1 2]);
at(uilabel(c1,'Text','Analysis is only valid if the closed loop is BIBO stable.', ...
    'FontAngle','italic','WordWrap','on'),15,[1 2]);

r1 = uigridlayout(g1,[3 1],'RowHeight',{'1x','1x',185});
ax1y = uiaxes(r1);
ax1e = uiaxes(r1);
tbl1 = uitable(r1,'ColumnName',{'Type-0','Type-1','Type-2','This L(s)'}, ...
    'RowName',{'Kp = lim L(s)','Kv = lim sL(s)','Ka = lim s²L(s)', ...
               'e(∞), r = a','e(∞), r = at','e(∞), r = at²/2'}, ...
    'ColumnWidth',{140,140,140,'auto'});

dd1Preset.ValueChangedFcn = @(~,~) loadPreset1();
[ef1P.ValueChangedFcn, ef1G.ValueChangedFcn] = deal(@(~,~) markCustom(dd1Preset,@update1));
[dd1In.ValueChangedFcn, ef1a.ValueChangedFcn, ef1T.ValueChangedFcn] = deal(@(~,~) update1());
btn1.ButtonPushedFcn = @(~,~) update1();
registerEditor(1,ax1pz,{ef1P,ef1G},dd1Tgt,dd1Preset,@update1,dd1Keep,dd1Add,btn1Del);
ax1y.Interactions = [];

%% =====================================================================
%  Tab 2: Proportional control design
%  =====================================================================
t2 = uitab(tg,'Title','P-control design');
g2 = uigridlayout(t2,[1 2],'ColumnWidth',{340,'1x'});

c2 = uigridlayout(g2,[15 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{64,22,22,22,22,48,22,22,200,22,22,22,'1x',22,34});
at(uilabel(c2,'Text',['Design G(s) = K so that the finite steady-state error ' ...
    'for the unit test input matching the type of P(s) equals the spec. ' ...
    'Drag the spec line, the e(∞)-vs-K plot, or the poles/zeros of P(s).'], ...
    'FontWeight','bold','WordWrap','on'),1,[1 2]);

presets2 = { ...
    'Ex 10.7.2: P = 1/(s(s+1)), e = 0.1',   '1/(s*(s+1))',          0.1
    'Type-0: P = 2/((s+1)(s+2)), e = 0.05', '2/((s+1)*(s+2))',      0.05
    'Type-2: P = (s+1)/(s^2(s+10)), e = 0.5','(s+1)/(s^2*(s+10))',  0.5
    'Custom', '', []};
at(uilabel(c2,'Text','Example'),2,1);
dd2Preset = at(uidropdown(c2,'Items',presets2(:,1)','Value',presets2{1,1}),2,2);
at(uilabel(c2,'Text','Plant P(s)'),3,1);
ef2P = at(uieditfield(c2,'text','Value',presets2{1,2}),3,2);
at(uilabel(c2,'Text','Desired e(∞)'),4,1);
ef2e = at(uieditfield(c2,'numeric','Value',presets2{1,3}),4,2);
at(uilabel(c2,'Text','Designed K'),5,1);
lbl2Kd = at(uilabel(c2,'Text','','FontWeight','bold'),5,2);
lbl2Eq = at(uilabel(c2,'Text','','Interpreter','latex','FontSize',15),6,[1 2]);
at(uilabel(c2,'Text','Simulated K'),7,1);
ef2K = at(uieditfield(c2,'numeric','Value',10, ...
    'Tooltip','Change K to see how the steady-state error and stability change'),7,2);
btn2Use = at(uibutton(c2,'Text','Use designed K'),8,[1 2]);
ax2pz = at(uiaxes(c2),9,[1 2]);
[dd2Keep,dd2Add,btn2Del] = rootControls(c2,10,keepItems,addItems);
at(uilabel(c2,'Text','Results','FontWeight','bold'),12,[1 2]);
ta2 = at(uitextarea(c2,'Editable','off','FontName','Monospaced'),13,[1 2]);
at(uilabel(c2,'Text','Final time (0=auto)'),14,1);
ef2T = at(uieditfield(c2,'numeric','Value',0,'Limits',[0 Inf], ...
    'Tooltip','0 = choose automatically from the closed-loop poles'),14,2);
at(uilabel(c2,'Text','Note: no consideration is given to the transient response.', ...
    'FontAngle','italic','WordWrap','on'),15,[1 2]);

r2 = uigridlayout(g2,[2 2],'RowHeight',{'1x','1x'},'ColumnWidth',{'1x','1x'});
ax2y = uiaxes(r2);
ax2y.Layout.Column = [1 2];
ax2e = uiaxes(r2);
ax2K = uiaxes(r2);

dd2Preset.ValueChangedFcn = @(~,~) loadPreset2();
ef2P.ValueChangedFcn = @(~,~) markCustom(dd2Preset,@() update2(true));
ef2e.ValueChangedFcn = @(~,~) update2(true);
[ef2K.ValueChangedFcn, ef2T.ValueChangedFcn] = deal(@(~,~) update2(false));
btn2Use.ButtonPushedFcn = @(~,~) update2(true);
registerEditor(2,ax2pz,{ef2P},[],dd2Preset,@() update2(true),dd2Keep,dd2Add,btn2Del);
[ax2e.Interactions, ax2K.Interactions] = deal([]);
ax2K.ButtonDownFcn = @(~,~) startDrag(ax2K,@(pt,~) setK2(pt(1)),@() update2(false),true);

%% =====================================================================
%  Tab 3: Disturbances
%  =====================================================================
t3 = uitab(tg,'Title','Disturbances');
g3 = uigridlayout(t3,[1 2],'ColumnWidth',{340,'1x'});

c3 = uigridlayout(g3,[15 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{64,22,22,22,22,22,22,22,30,200,22,22,22,22,'1x'});
at(uilabel(c3,'Text',['Plant input disturbance:  E(s) = S(s)R(s) − P(s)S(s)D(s),  ' ...
    'S(s) = 1/(1+P(s)G(s)). Drag d(t), r(t), or the poles/zeros of P(s) or G(s).'], ...
    'FontWeight','bold','WordWrap','on'),1,[1 2]);

presets3 = { ...
    'Ex 10.8.2(1): P = 1/s, G = K = 30',          '1/s', '30'
    'Ex 10.8.2(2): P = 1/s, G = 36(1+s)/s',       '1/s', '36*(1+s)/s'
    'Type-0 plant: P = 1/(s+1), G = 5',           '1/(s+1)', '5'
    'Type-0 plant, PI: P = 1/(s+1), G = 5(s+1)/s','1/(s+1)', '5*(s+1)/s'
    'Custom', '', ''};
at(uilabel(c3,'Text','Example'),2,1);
dd3Preset = at(uidropdown(c3,'Items',presets3(:,1)','Value',presets3{1,1}),2,2);
at(uilabel(c3,'Text','Plant P(s)'),3,1);
ef3P = at(uieditfield(c3,'text','Value',presets3{1,2}),3,2);
at(uilabel(c3,'Text','Controller G(s)'),4,1);
ef3G = at(uieditfield(c3,'text','Value',presets3{1,3}),4,2);
at(uilabel(c3,'Text','Reference r(t)'),5,1);
dd3In = at(uidropdown(c3,'Items',{'None (R = 0)','Step','Ramp','Parabolic'}, ...
    'Value','None (R = 0)'),5,2);
at(uilabel(c3,'Text','Reference amp. a'),6,1);
ef3a = at(uieditfield(c3,'numeric','Value',1),6,2);
at(uilabel(c3,'Text','Disturbance d'),7,1);
ef3d = at(uieditfield(c3,'numeric','Value',1,'Tooltip','D(s) = d/s (step-like disturbance)'),7,2);
at(uilabel(c3,'Text','Final time (0=auto)'),8,1);
ef3T = at(uieditfield(c3,'numeric','Value',0,'Limits',[0 Inf], ...
    'Tooltip','0 = choose automatically from the closed-loop poles'),8,2);
lbl3R = at(uilabel(c3,'Text','','Interpreter','latex','FontSize',13),9,[1 2]);
ax3pz = at(uiaxes(c3),10,[1 2]);
at(uilabel(c3,'Text','Edit in s-plane'),11,1);
dd3Tgt = at(uidropdown(c3,'Items',{'P(s)','G(s)'},'Value','G(s)'),11,2);
[dd3Keep,dd3Add,btn3Del] = rootControls(c3,12,keepItems,addItems);
at(uilabel(c3,'Text','Results','FontWeight','bold'),14,1);
btn3 = at(uibutton(c3,'Text','Update'),14,2);
ta3 = at(uitextarea(c3,'Editable','off','FontName','Monospaced'),15,[1 2]);

r3 = uigridlayout(g3,[2 1],'RowHeight',{'1x','1x'});
ax3y = uiaxes(r3);
ax3e = uiaxes(r3);

dd3Preset.ValueChangedFcn = @(~,~) loadPreset3();
[ef3P.ValueChangedFcn, ef3G.ValueChangedFcn] = deal(@(~,~) markCustom(dd3Preset,@update3));
[dd3In.ValueChangedFcn, ef3a.ValueChangedFcn, ef3d.ValueChangedFcn, ef3T.ValueChangedFcn] ...
    = deal(@(~,~) update3());
btn3.ButtonPushedFcn = @(~,~) update3();
registerEditor(3,ax3pz,{ef3P,ef3G},dd3Tgt,dd3Preset,@update3,dd3Keep,dd3Add,btn3Del);
ax3y.Interactions = [];

%% =====================================================================
%  Tab 4: Frequency response
%  =====================================================================
t4 = uitab(tg,'Title','Frequency response');
g4 = uigridlayout(t4,[1 2],'ColumnWidth',{340,'1x'});

c4 = uigridlayout(g4,[11 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{64,22,22,22,48,200,22,22,22,'1x',22});
at(uilabel(c4,'Text',['Read the static error constants off the low-frequency ' ...
    'asymptote of |L(jω)|. Drag |L(jω)| to scale L(s), or drag its poles/zeros.'], ...
    'FontWeight','bold','WordWrap','on'),1,[1 2]);

presets4 = { ...
    'Ex 10.9.1: L = 10/(1+s/10)  (Type-0)',       '10/(1+s/10)'
    'Ex 10.9.2: L = 10/(s(1+s/10))  (Type-1)',    '10/(s*(1+s/10))'
    'Type-2: L = 10(s+1)/(s^2(s+10))',            '10*(s+1)/(s^2*(s+10))'
    'Custom', ''};
at(uilabel(c4,'Text','Example'),2,1);
dd4Preset = at(uidropdown(c4,'Items',presets4(:,1)','Value',presets4{1,1}),2,2);
at(uilabel(c4,'Text','L(s) = P(s)G(s)'),3,1);
ef4L = at(uieditfield(c4,'text','Value',presets4{1,2}),3,2);
at(uilabel(c4,'Text','Frequency range'),4,1);
ef4W = at(uieditfield(c4,'text','Value','auto', ...
    'Tooltip','"auto" or [wmin wmax] in rad/s, e.g. [0.1 100]'),4,2);
lbl4R = at(uilabel(c4,'Text','','Interpreter','latex','FontSize',15),5,[1 2]);
ax4pz = at(uiaxes(c4),6,[1 2]);
[dd4Keep,dd4Add,btn4Del] = rootControls(c4,7,keepItems,addItems);
at(uilabel(c4,'Text','Results','FontWeight','bold'),9,[1 2]);
ta4 = at(uitextarea(c4,'Editable','off','FontName','Monospaced'),10,[1 2]);
btn4 = at(uibutton(c4,'Text','Update'),11,[1 2]);

r4 = uigridlayout(g4,[2 1],'RowHeight',{'3x','2x'});
ax4m = uiaxes(r4);
ax4e = uiaxes(r4);

dd4Preset.ValueChangedFcn = @(~,~) loadPreset4();
ef4L.ValueChangedFcn = @(~,~) markCustom(dd4Preset,@update4);
ef4W.ValueChangedFcn = @(~,~) update4();
btn4.ButtonPushedFcn = @(~,~) update4();
registerEditor(4,ax4pz,{ef4L},[],dd4Preset,@update4,dd4Keep,dd4Add,btn4Del);
ax4m.Interactions = [];

% Initial draw
update1(); update2(true); update3(); update4();

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

    function valueDown(ax,mode,getV,setV,doneFcn)
        % Drag a curve vertically to scale the value it represents.
        v0 = getV();
        startDrag(ax,@(pt,p0) setV(scaledGain(mode,v0,pt,p0)),doneFcn);
    end

    function loopGainDown(i,ax)
        % Drag |L(jw)| to scale the edited transfer function (its zpk gain).
        pz(i).r0 = pz(i).roots;
        pz(i).K0 = pz(i).K;
        valueDown(ax,'dB',@() 1,@(f) setLoop(i,pz(i).r0,pz(i).K0*f),pz(i).upd);
    end

%% =====================================================================
%  Pole-zero editors
%  =====================================================================
    function registerEditor(i,ax,efs,targetDD,dd,updFcn,keepDD,addDD,delBtn)
        pz(i).ax = ax;
        pz(i).efs = efs;
        pz(i).target = targetDD;
        pz(i).dd = dd;
        pz(i).upd = updFcn;
        pz(i).keep = keepDD;
        pz(i).selKind = '';
        pz(i).selVal = [];
        ax.Interactions = [];
        addDD.ValueChangedFcn = @(src,~) addRoot(i,src);
        delBtn.ButtonPushedFcn = @(~,~) deleteRoot(i);
        if ~isempty(targetDD)
            targetDD.ValueChangedFcn = @(~,~) changeTarget(i);
        end
    end

    function ef = editedField(i)
        % Edit field of the transfer function that the s-plane editor changes.
        ef = pz(i).efs{1};
        if ~isempty(pz(i).target) && strcmp(pz(i).target.Value,'G(s)')
            ef = pz(i).efs{2};
        end
    end

    function changeTarget(i)
        pz(i).selKind = '';
        pz(i).selVal = [];
        pz(i).upd();
    end

    function drawRoots(i,sys,pCL)
        % Draw the draggable poles/zeros of sys and the closed-loop poles.
        ax = pz(i).ax;
        [z,p,K] = zpkdata(zpk(sys),'v');
        rl = rootList(z,p);
        pz(i).roots = rl;
        pz(i).K = K;
        pz(i).tau = totaldelay(sys);

        if drag.active && isequal(drag.ax,ax)
            xl = drag.xl; yl = drag.yl;
        else
            vals = [z; p; pCL; 0];
            R = max(1,1.3*max(abs(vals(isfinite(vals)))));
            xl = [-R R]; yl = [-R R];
        end
        cla(ax); hold(ax,'on');
        patch(ax,[0 xl(2) xl(2) 0],yl([1 1 2 2]),[1 0.9 0.9],'EdgeColor','none','HitTest','off');
        xline(ax,0,'k','HitTest','off');
        yline(ax,0,'k','HitTest','off');
        plot(ax,real(pCL),imag(pCL),'x','Color',cRef,'MarkerSize',9,'LineWidth',2,'HitTest','off');

        sel = selectedIndex(i);
        for j = 1:numel(rl)
            v = rl(j).val;
            if rl(j).pair, xs = [real(v) real(v)]; ys = [imag(v) -imag(v)];
            else, xs = real(v); ys = 0; end
            if rl(j).kind == 'p', mk = 'x'; ms = 14; else, mk = 'o'; ms = 10; end
            col = cOut; lw = 2.5;
            if j == sel, col = cErr; lw = 3.5; end
            plot(ax,xs,ys,mk,'Color',col,'MarkerSize',ms,'LineWidth',lw, ...
                'ButtonDownFcn',@(~,~) rootDown(i,j));
        end
        hold(ax,'off'); grid(ax,'on');
        ax.DataAspectRatio = [1 1 1];
        xlim(ax,xl); ylim(ax,yl);
        name = 'L';
        if ~isempty(pz(i).target), name = pz(i).target.Value(1); end
        if i == 2, name = 'P'; end
        title(ax,sprintf('Drag poles (x) / zeros (o) of %s(s);  blue x: closed loop',name), ...
            'FontSize',10,'FontWeight','normal');
        ax.FontSize = 9;
    end

    function rootDown(i,j)
        pz(i).selKind = pz(i).roots(j).kind;
        pz(i).selVal = pz(i).roots(j).val;
        pz(i).r0 = pz(i).roots;
        pz(i).K0 = pz(i).K;
        startDrag(pz(i).ax,@(pt,~) moveRoot(i,j,pt),pz(i).upd);
    end

    function moveRoot(i,j,pt)
        rl = pz(i).r0;
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
        pz(i).selVal = v;
        setLoop(i,rl,heldGain(i,rl));
    end

    function K = heldGain(i,rl)
        % New zpk gain after moving roots, keeping the chosen quantity fixed.
        if strcmp(pz(i).keep.Value,keepItems{1})
            K = pz(i).K0*lowFreqProduct(pz(i).r0)/lowFreqProduct(rl);
        else
            K = pz(i).K0;
        end
    end

    function setLoop(i,rl,K)
        ef = editedField(i);
        ef.Value = rootsToExpr(rl,K,pz(i).tau);
        pz(i).dd.Value = 'Custom';
        pz(i).upd();
    end

    function addRoot(i,src)
        choice = src.Value;
        src.Value = addItems{1};
        R = max(abs(pz(i).ax.XLim))/2;
        switch choice
            case 'Real pole',         new = rootEntry('p',-R,false);
            case 'Complex pole pair', new = rootEntry('p',complex(-R/2,R/2),true);
            case 'Real zero',         new = rootEntry('z',-R,false);
            case 'Complex zero pair', new = rootEntry('z',complex(-R/2,R/2),true);
            otherwise, return
        end
        rl = [pz(i).roots new];
        if ~isProper(rl)
            uialert(fig,'A transfer function cannot have more zeros than poles.','Not allowed');
            return
        end
        pz(i).selKind = new.kind;
        pz(i).selVal = new.val;
        pz(i).r0 = pz(i).roots;
        pz(i).K0 = pz(i).K;
        setLoop(i,rl,heldGain(i,rl));
    end

    function deleteRoot(i)
        j = selectedIndex(i);
        if j == 0
            uialert(fig,'Click a pole or zero first to select it.','Nothing selected');
            return
        end
        rl = pz(i).roots;
        rl(j) = [];
        if ~isProper(rl)
            uialert(fig,'Removing this pole would leave more zeros than poles.','Not allowed');
            return
        end
        pz(i).r0 = pz(i).roots;
        pz(i).K0 = pz(i).K;
        pz(i).selKind = '';
        pz(i).selVal = [];
        setLoop(i,rl,heldGain(i,rl));
    end

    function j = selectedIndex(i)
        % The root of the selected kind nearest the selected value (0 if none).
        j = 0;
        rl = pz(i).roots;
        if isempty(pz(i).selVal) || isempty(rl), return, end
        idx = find([rl.kind] == pz(i).selKind);
        if isempty(idx), return, end
        [~,m] = min(abs([rl(idx).val] - pz(i).selVal));
        j = idx(m);
    end

%% =====================================================================
%  Tab 1 callbacks
%  =====================================================================
    function loadPreset1()
        i = find(strcmp(presets1(:,1),dd1Preset.Value));
        if isempty(presets1{i,2}), return, end
        ef1P.Value = presets1{i,2};
        ef1G.Value = presets1{i,3};
        dd1In.Value = presets1{i,4};
        update1();
    end

    function setA1(a)
        ef1a.Value = a;
        update1();
    end

    function update1()
        try
            s = tf('s');
            P = parseTF(ef1P.Value);
            G = parseTF(ef1G.Value);
            L = minreal(P*G,1e-8);
            a = ef1a.Value;
            q = find(strcmp(dd1In.Items,dd1In.Value)) - 1;   % 0 step, 1 ramp, 2 parabolic

            T = feedback(L,1);
            S = feedback(1,L);
            pCL = pole(T);
            stable = isStable(pCL);

            if strcmp(dd1Tgt.Value,'G(s)'), drawRoots(1,G,pCL); else, drawRoots(1,P,pCL); end

            [k,~] = typeAndGain(L);
            Kc = [limGain(L,0), limGain(L,1), limGain(L,2)];
            eTheory = a*[1/(1+Kc(1)), 1/Kc(2), 1/Kc(3)];

            % Simulation
            t = timeVector(ef1T.Value,pCL,q);
            r = a*t.^q/factorial(q);
            y = step(a*T/s^q,t);
            e = step(a*S/s^q,t);

            % Plots; r(t) can be dragged to change a
            cla(ax1y); hold(ax1y,'on');
            hr = plot(ax1y,t,r,'Color',cRef,'LineWidth',2.5);
            plot(ax1y,t,y,'Color',cOut,'LineWidth',2);
            hold(ax1y,'off'); grid(ax1y,'on');
            legend(ax1y,{'$r(t)$ (drag)','$y(t)$'},'Interpreter','latex','Location','best');
            title(ax1y,sprintf('%s input, a = %.3g', lower(dd1In.Value), a));
            xlabel(ax1y,'Time (s)'); ylabel(ax1y,'Amplitude');
            noHit(ax1y,hr);
            hr.ButtonDownFcn = @(~,~) valueDown(ax1y,'ratio',@() ef1a.Value,@setA1,@update1);

            cla(ax1e); hold(ax1e,'on');
            plot(ax1e,t,e,'Color',cErr,'LineWidth',2);
            leg = {'$e(t)=r(t)-y(t)$'};
            if stable && isfinite(eTheory(q+1))
                yline(ax1e,eTheory(q+1),'--k',sprintf('$e(\\infty)=%.4g$',eTheory(q+1)), ...
                    'Interpreter','latex','LabelHorizontalAlignment','left');
                leg{end+1} = '$e(\infty)$';
            end
            hold(ax1e,'off'); grid(ax1e,'on');
            legend(ax1e,leg,'Interpreter','latex','Location','best');
            title(ax1e,'Tracking error');
            xlabel(ax1e,'Time (s)'); ylabel(ax1e,'Error');

            % Error summary label
            eqs = {sprintf('\\frac{%s}{1+K_p}',num2tex(a)), ...
                   sprintf('\\frac{%s}{K_v}',num2tex(a)), ...
                   sprintf('\\frac{%s}{K_a}',num2tex(a))};
            if stable
                lbl1R.Text = sprintf('$e(\\infty)=%s=%s$',eqs{q+1},num2tex(eTheory(q+1)));
            else
                lbl1R.Text = '$\mathrm{Unstable:\ FVT\ not\ valid}$';
            end

            % Table 10.1
            gen = {'finite','∞','∞'; '0','finite','∞'; '0','0','finite';
                   'a/(1+Kp)','0','0'; '∞','a/Kv','0'; '∞','∞','a/Ka'};
            this = [arrayfun(@fmtNum,Kc,'UniformOutput',false)'; ...
                    arrayfun(@fmtNum,eTheory,'UniformOutput',false)'];
            if ~stable, this(4:6) = {'N/A (unstable)'}; end
            tbl1.Data = [gen this];
            tbl1.ColumnName = {'Type-0','Type-1','Type-2',sprintf('This L(s): Type-%d',k)};
            removeStyle(tbl1);
            if k >= 0 && k <= 2
                addStyle(tbl1,uistyle('BackgroundColor',cHi),'cell',[(1:6)' repmat(k+1,6,1)]);
                addStyle(tbl1,uistyle('BackgroundColor',cHi2,'FontWeight','bold'),'cell',[q+4 k+1]);
            end
            addStyle(tbl1,uistyle('BackgroundColor',cHi2,'FontWeight','bold'),'cell',[q+4 4]);

            % Results text
            txt = { ...
                ['L(s) = ' tfStr(L)]
                ''
                sprintf('System type k = %d (integrators in L)',k)
                ''
                'Closed-loop poles (roots of 1+L):'
                polesStr(pCL)
                ['=> ' stabStr(stable)]
                ''
                sprintf('Kp = lim L(s)      = %s',fmtNum(Kc(1)))
                sprintf('Kv = lim s L(s)    = %s',fmtNum(Kc(2)))
                sprintf('Ka = lim s^2 L(s)  = %s',fmtNum(Kc(3)))
                ''
                sprintf('Input: R(s) = %s',inputStr(a,q))
                sprintf('e(inf) predicted  = %s',fmtNum(eTheory(q+1)))
                sprintf('e(t_end) simulated = %.4g',e(end))};
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
        ef2P.Value = presets2{i,2};
        ef2e.Value = presets2{i,3};
        update2(true);
    end

    function setSpec2(e)
        ef2e.Value = max(e,1e-6);
        update2(true);
    end

    function setK2(absK)
        ef2K.Value = kSign2*max(absK,1e-9);
        update2(false);
    end

    function update2(useDesign)
        try
            s = tf('s');
            P = minreal(parseTF(ef2P.Value),1e-8);
            eSpec = ef2e.Value;
            [k,Pk] = typeAndGain(P);

            names = {'step','ramp','parabolic'};
            limNames = {'lim P(s)','lim sP(s)','lim s^2P(s)'};
            if k < 0 || k > 2
                drawRoots(2,P,pole(feedback(ef2K.Value*P,1)));
                error(['P(s) is Type-%d. A proportional controller only gives a ' ...
                    'finite, adjustable e(inf) for Type-0, -1 or -2 plants.'],k);
            end
            q = k;   % test input with a finite error for this plant

            % Section 10.7.2: solve e(inf) = 1/(1+K*Kp), 1/(K*Kv) or 1/(K*Ka)
            if q == 0
                Kd = (1/eSpec - 1)/Pk;
                lbl2Eq.Text = sprintf('$e(\\infty)=\\frac{1}{1+K\\lim_{s\\to0}P(s)}=%s$',num2tex(eSpec));
            else
                Kd = 1/(eSpec*Pk);
                pw = {'','s','s^2'};
                lbl2Eq.Text = sprintf('$e(\\infty)=\\frac{1}{K\\lim_{s\\to0}%sP(s)}=%s$',pw{q+1},num2tex(eSpec));
            end
            lbl2Kd.Text = sprintf('K = %.4g',Kd);
            if useDesign, ef2K.Value = Kd; end
            K = ef2K.Value;
            kSign2 = sign(Kd); if kSign2 == 0, kSign2 = 1; end

            L = K*P;
            T = feedback(L,1);
            S = feedback(1,L);
            pCL = pole(T);
            stable = isStable(pCL);
            eK = errorForGain(K,Pk,q);

            drawRoots(2,P,pCL);

            t = timeVector(ef2T.Value,pCL,q);
            r = t.^q/factorial(q);
            y = step(T/s^q,t);
            e = step(S/s^q,t);

            % Response
            cla(ax2y); hold(ax2y,'on');
            plot(ax2y,t,r,'Color',cRef,'LineWidth',2);
            plot(ax2y,t,y,'Color',cOut,'LineWidth',2);
            hold(ax2y,'off'); grid(ax2y,'on');
            legend(ax2y,{'$r(t)$','$y(t)$'},'Interpreter','latex','Location','best');
            title(ax2y,sprintf('Unit %s reference, G(s) = K = %.4g',names{q+1},K));
            xlabel(ax2y,'Time (s)'); ylabel(ax2y,'Amplitude');

            % Tracking error; the spec line can be dragged to redesign K
            cla(ax2e); hold(ax2e,'on');
            plot(ax2e,t,e,'Color',cErr,'LineWidth',2);
            hs = yline(ax2e,eSpec,'--k',sprintf('spec: $e(\\infty)=%.4g$ (drag)',eSpec), ...
                'Interpreter','latex','LabelHorizontalAlignment','left','LineWidth',2);
            hold(ax2e,'off'); grid(ax2e,'on');
            legend(ax2e,{'$e(t)$','spec'},'Interpreter','latex','Location','best');
            title(ax2e,'Tracking error'); xlabel(ax2e,'Time (s)'); ylabel(ax2e,'Error');
            noHit(ax2e,hs);
            hs.ButtonDownFcn = @(~,~) startDrag(ax2e,@(pt,~) setSpec2(pt(2)),@() update2(true));

            % e(inf) vs K, with unstable gains in red; drag along it to set K
            Kref = abs(Kd); if ~isfinite(Kref) || Kref == 0, Kref = 1; end
            Kg = kSign2*logspace(log10(Kref)-2,log10(Kref)+2,400);
            eg = errorForGain(Kg,Pk,q);
            [nP,dP] = tfdata(P,'v');
            stab = arrayfun(@(kk) isStable(roots(dP + kk*nP)),Kg);
            eS = eg; eS(~stab) = NaN;
            eU = eg; eU(stab) = NaN;
            cla(ax2K); hold(ax2K,'on');
            plot(ax2K,abs(Kg),eS,'Color',cRef,'LineWidth',2);
            plot(ax2K,abs(Kg),eU,'r','LineWidth',2);
            plot(ax2K,abs(Kd),eSpec,'kp','MarkerSize',12,'MarkerFaceColor','y');
            plot(ax2K,abs(K),eK,'o','Color',cOut,'MarkerFaceColor',cOut,'MarkerSize',9);
            hold(ax2K,'off'); grid(ax2K,'on');
            ax2K.XScale = 'log';
            if all(eg > 0), ax2K.YScale = 'log'; else, ax2K.YScale = 'linear'; end
            legend(ax2K,{'stable','unstable','designed K','simulated K'},'Location','best');
            title(ax2K,sprintf('e(\\infty) vs K (unit %s; drag to set K)',names{q+1}));
            xlabel(ax2K,'|K|'); ylabel(ax2K,'e(\infty)');
            noHit(ax2K,[]);

            txt = { ...
                ['P(s) = ' tfStr(P)]
                sprintf('P(s) is Type-%d  =>  finite error for %s inputs',k,names{q+1})
                sprintf('%s = %.4g',limNames{q+1},Pk)
                ''
                sprintf('Designed K = %.4g',Kd)
                sprintf('Simulated K = %.4g  ->  e(inf) = %s',K,fmtNum(eK))
                ''
                'Closed-loop poles:'
                polesStr(pCL)
                ['=> ' stabStr(stable)]};
            if ~isStable(pole(feedback(Kd*P,1)))
                txt{end+1} = '';
                txt{end+1} = 'WARNING: the designed K destabilises the loop,';
                txt{end+1} = 'so the specification cannot be met with G = K.';
            end
            ta2.Value = flatLines(txt);
        catch err
            showError(ta2,err);
        end
    end

%% =====================================================================
%  Tab 3 callbacks
%  =====================================================================
    function loadPreset3()
        i = find(strcmp(presets3(:,1),dd3Preset.Value));
        if isempty(presets3{i,2}), return, end
        ef3P.Value = presets3{i,2};
        ef3G.Value = presets3{i,3};
        update3();
    end

    function setD3(d)
        ef3d.Value = d;
        update3();
    end

    function setA3(a)
        ef3a.Value = a;
        update3();
    end

    function update3()
        try
            s = tf('s');
            P = parseTF(ef3P.Value);
            G = parseTF(ef3G.Value);
            L = minreal(P*G,1e-8);
            a = ef3a.Value;
            d = ef3d.Value;
            q = find(strcmp(dd3In.Items,dd3In.Value)) - 2;   % -1 none, 0 step, 1 ramp, 2 parabolic

            T  = feedback(L,1);
            S  = feedback(1,L);
            PS = minreal(feedback(P,G),1e-8);
            pCL = pole(T);
            stable = isStable(pCL);

            if strcmp(dd3Tgt.Value,'G(s)'), drawRoots(3,G,pCL); else, drawRoots(3,P,pCL); end

            % e_R(inf) from the static error constants of L
            if q < 0
                eR = 0;
            else
                Kq = limGain(L,q);
                if q == 0, eR = a/(1+Kq); else, eR = a/Kq; end
            end
            % e_D(inf) = -d * lim 1/(1/P(s) + G(s))
            Pdc = limGain(P,0);
            Gdc = limGain(G,0);
            [kG,~] = typeAndGain(G);
            eD = -d/(1/Pdc + Gdc);
            if isnan(eD), eD = -d*dcgain(PS); end
            eTot = eR + eD;

            t = timeVector(ef3T.Value,pCL,max(q,0));
            if q < 0
                r = zeros(size(t)); eRt = zeros(size(t)); yR = zeros(size(t));
            else
                r = a*t.^q/factorial(q);
                eRt = step(a*S/s^q,t);
                yR = step(a*T/s^q,t);
            end
            eDt = step(-d*PS,t);
            y = yR - eDt;
            e = eRt + eDt;

            % d(t) and r(t) can be dragged to change d and a
            cla(ax3y); hold(ax3y,'on');
            hr = plot(ax3y,t,r,'Color',cRef,'LineWidth',2.5);
            plot(ax3y,t,y,'Color',cOut,'LineWidth',2);
            hd = plot(ax3y,t,d*ones(size(t)),':','Color',cDist,'LineWidth',3);
            hold(ax3y,'off'); grid(ax3y,'on');
            legend(ax3y,{'$r(t)$ (drag)','$y(t)$','$d(t)$ (drag)'},'Interpreter','latex','Location','best');
            title(ax3y,'Reference, output and disturbance');
            xlabel(ax3y,'Time (s)'); ylabel(ax3y,'Amplitude');
            noHit(ax3y,[hr hd]);
            hd.ButtonDownFcn = @(~,~) startDrag(ax3y,@(pt,~) setD3(pt(2)),@update3);
            if q >= 0
                hr.ButtonDownFcn = @(~,~) valueDown(ax3y,'ratio',@() ef3a.Value,@setA3,@update3);
            end

            cla(ax3e); hold(ax3e,'on');
            plot(ax3e,t,e,'Color',cErr,'LineWidth',2.5);
            plot(ax3e,t,eDt,'--','Color',cDist,'LineWidth',1.5);
            leg = {'$e(t)=e_R(t)+e_D(t)$','$e_D(t)$'};
            if q >= 0
                plot(ax3e,t,eRt,'--','Color',cRef,'LineWidth',1.5);
                leg{end+1} = '$e_R(t)$';
            end
            if stable && isfinite(eTot)
                yline(ax3e,eTot,'--k',sprintf('$e(\\infty)=%.4g$',eTot),'Interpreter','latex', ...
                    'LabelHorizontalAlignment','left');
                leg{end+1} = '$e(\infty)$';
            end
            hold(ax3e,'off'); grid(ax3e,'on');
            legend(ax3e,leg,'Interpreter','latex','Location','best');
            title(ax3e,'Error components'); xlabel(ax3e,'Time (s)'); ylabel(ax3e,'Error');

            if stable
                lbl3R.Text = sprintf('$e(\\infty)=e_R(\\infty)+e_D(\\infty)=%s+(%s)=%s$', ...
                    num2tex(eR),num2tex(eD),num2tex(eTot));
            else
                lbl3R.Text = '$\mathrm{Unstable:\ FVT\ not\ valid}$';
            end

            txt = { ...
                ['P(s) = ' tfStr(P)]
                ['G(s) = ' tfStr(G)]
                ''
                'Closed-loop poles:'
                polesStr(pCL)
                ['=> ' stabStr(stable)]
                ''
                sprintf('L(s) is Type-%d, G(s) is Type-%d',typeAndGain(L),kG)
                sprintf('lim P(s) = %s,  lim G(s) = %s',fmtNum(Pdc),fmtNum(Gdc))
                ''
                sprintf('D(s) = %.4g/s',d)
                'e_D(inf) = -d * lim 1/(1/P(s) + G(s))'
                sprintf('         = %s',fmtNum(eD))
                sprintf('e_R(inf) = %s',fmtNum(eR))
                sprintf('e(inf)   = %s',fmtNum(eTot))
                ''};
            if isinf(Gdc)
                txt{end+1} = 'G(s) has an integrator => step disturbance fully rejected.';
            else
                txt{end+1} = 'G(s) has no integrator => finite disturbance error remains.';
            end
            ta3.Value = flatLines(txt);
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
        ef4L.Value = presets4{i,2};
        update4();
    end

    function update4()
        try
            s = tf('s');
            L = minreal(parseTF(ef4L.Value),1e-8);
            [k,Kk] = typeAndGain(L);
            T = feedback(L,1);
            S = feedback(1,L);
            pCL = pole(T);
            stable = isStable(pCL);

            drawRoots(4,L,pCL);

            % Frequency range
            if k ~= 0 && Kk ~= 0, wc = abs(Kk)^(1/k); else, wc = []; end
            if strcmpi(strtrim(ef4W.Value),'auto')
                rts = abs([pole(L); zero(L); wc]);
                rts = rts(rts > 1e-6 & isfinite(rts));
                if isempty(rts), rts = 1; end
                w = logspace(floor(log10(min(rts)))-2,ceil(log10(max(rts)))+1,1000);
            else
                wr = str2num(ef4W.Value); %#ok<ST2NM>
                if numel(wr) ~= 2 || any(wr <= 0), error('Frequency range must be [wmin wmax] with wmin > 0.'); end
                w = logspace(log10(wr(1)),log10(wr(2)),1000);
            end
            magdB = 20*log10(squeeze(abs(freqresp(L,w))));

            % Low-frequency asymptote |L'(jw)| = |K_k| / w^k
            asym = 20*log10(abs(Kk)) - 20*k*log10(w);
            cla(ax4m); hold(ax4m,'on');
            hM = plot(ax4m,w,magdB,'Color',cRef,'LineWidth',2.5);
            leg = {'$|L(j\omega)|$ (drag)'};
            hA = gobjects(0);
            if Kk ~= 0
                hA = plot(ax4m,w,asym,'--','Color',cOut,'LineWidth',2);
                leg{end+1} = sprintf('LF asymptote (%+d dB/dec)',-20*k);
            end
            yline(ax4m,0,':k');
            leg{end+1} = '0 dB';
            constNames = {'K_p','K_v','K_a'};
            if k == 0
                yline(ax4m,20*log10(abs(Kk)),'--k',sprintf('$20\\log_{10}K_p=%.3g$ dB',20*log10(abs(Kk))), ...
                    'Interpreter','latex','LabelHorizontalAlignment','left');
                leg{end+1} = '$20\log_{10}K_p$';
            elseif k > 0 && Kk ~= 0
                plot(ax4m,wc,0,'ko','MarkerFaceColor','y','MarkerSize',9);
                if k == 1
                    lab = sprintf('$\\omega=K_v=%.4g$',wc);
                elseif k == 2
                    lab = sprintf('$\\omega=\\sqrt{K_a}=%.4g$',wc);
                else
                    lab = sprintf('$\\omega=K_%d^{1/%d}=%.4g$',k,k,wc);
                end
                text(ax4m,wc,0,['  ' lab],'Interpreter','latex','VerticalAlignment','bottom','FontSize',13);
                leg{end+1} = 'asymptote crosses 0 dB';
            end
            hold(ax4m,'off'); grid(ax4m,'on');
            ax4m.XScale = 'log';
            xlim(ax4m,[w(1) w(end)]);
            yl = [min(magdB) max(magdB)];
            ylim(ax4m,[max(yl(1),yl(2)-150)-10, yl(2)+10]);
            legend(ax4m,leg,'Interpreter','latex','Location','best');
            title(ax4m,sprintf('Bode magnitude of L(s): Type-%d (drag to scale L)',k));
            xlabel(ax4m,'Frequency (rad/s)'); ylabel(ax4m,'Magnitude (dB)');
            noHit(ax4m,[hM hA]);
            hM.ButtonDownFcn = @(~,~) loopGainDown(4,ax4m);
            if ~isempty(hA), hA.ButtonDownFcn = hM.ButtonDownFcn; end

            % Tracking error for the input that gives a finite error
            q = min(max(k,0),2);
            names = {'step','ramp','parabolic'};
            Kc = [limGain(L,0), limGain(L,1), limGain(L,2)];
            eTh = [1/(1+Kc(1)), 1/Kc(2), 1/Kc(3)];
            t = timeVector(0,pCL,q);
            e = step(S/s^q,t);
            cla(ax4e); hold(ax4e,'on');
            plot(ax4e,t,e,'Color',cErr,'LineWidth',2);
            if stable && isfinite(eTh(q+1))
                yline(ax4e,eTh(q+1),'--k',sprintf('$e(\\infty)=%.4g$',eTh(q+1)),'Interpreter','latex', ...
                    'LabelHorizontalAlignment','left');
            end
            hold(ax4e,'off'); grid(ax4e,'on');
            title(ax4e,sprintf('Tracking error, unit %s reference',names{q+1}));
            xlabel(ax4e,'Time (s)'); ylabel(ax4e,'e(t)');

            if k >= 0 && k <= 2
                eqs = {'\frac{1}{1+K_p}','\frac{1}{K_v}','\frac{1}{K_a}'};
                lbl4R.Text = sprintf('$%s=%s\\Rightarrow e(\\infty)=%s=%s$', ...
                    constNames{k+1},num2tex(Kk),eqs{k+1},num2tex(eTh(k+1)));
            else
                lbl4R.Text = '';
            end

            txt = { ...
                ['L(s) = ' tfStr(L)]
                ''
                sprintf('Type-%d: low-frequency slope = %d dB/decade',k,-20*k)};
            txt = [txt; {
                ''
                sprintf('Kp = %s   ->  e(inf), unit step     = %s',fmtNum(Kc(1)),fmtNum(eTh(1)))
                sprintf('Kv = %s   ->  e(inf), unit ramp     = %s',fmtNum(Kc(2)),fmtNum(eTh(2)))
                sprintf('Ka = %s   ->  e(inf), unit parabola = %s',fmtNum(Kc(3)),fmtNum(eTh(3)))
                ''
                'Reading the Bode plot:'}];
            switch k
                case 0
                    txt{end+1} = sprintf('  LF gain = 20log10(Kp) = %.4g dB',20*log10(abs(Kk)));
                case 1
                    txt{end+1} = sprintf('  -20 dB/dec asymptote meets 0 dB at w = Kv = %.4g',wc);
                case 2
                    txt{end+1} = sprintf('  -40 dB/dec asymptote meets 0 dB at w = sqrt(Ka) = %.4g',wc);
                otherwise
                    txt{end+1} = '  (outside the cases treated in Section 10.9)';
            end
            txt = [txt; {''; 'Closed-loop poles:'; polesStr(pCL); ['=> ' stabStr(stable)]}];
            ta4.Value = flatLines(txt);
        catch err
            showError(ta4,err);
        end
    end
end

%% =========================================================================
%  Helper functions
%  =========================================================================
function sys = parseTF(str)
% Evaluate a MATLAB expression in s as a transfer function. zpk arithmetic
% keeps repeated poles/zeros exact, which the pole-zero editors rely on.
str = strtrim(str);
if isempty(str), error('Transfer function is empty.'); end
f = str2func(['@(s) ' str]);
try
    sys = zpk(f(zpk('s')));
catch
    sys = zpk(f(tf('s')));
end
end

%% =========================================================================
%  Pole-zero editing helpers
%  =========================================================================
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

function ok = isProper(rl)
n = 1 + [rl.pair];
ok = sum(n([rl.kind] == 'z')) <= sum(n([rl.kind] == 'p'));
end

function g = lowFreqProduct(rl)
% prod(-z)/prod(-p) over roots away from the origin, so that the
% low-frequency gain lim s^k L(s) equals K*g for zpk gain K.
g = 1;
for j = 1:numel(rl)
    v = rl(j).val;
    if abs(v) < 1e-12, continue, end
    if rl(j).pair, f = abs(v)^2; else, f = -real(v); end
    if rl(j).kind == 'z', g = g*f; else, g = g/f; end
end
end

function expr = rootsToExpr(rl,K,tau)
% MATLAB expression in s for the zpk model K*prod(s-z)/prod(s-p)*exp(-tau s).
num = factorStr(rl([rl.kind] == 'z'));
den = factorStr(rl([rl.kind] == 'p'));
expr = sprintf('%.6g',K);
if ~isempty(num), expr = [expr '*' num]; end
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

function k = scaledGain(mode,k0,pt,p0)
% Value after dragging from p0 to pt: vertically in dB on a Bode plot, or in
% proportion to the height grabbed on a curve that scales with the value.
switch mode
    case 'dB'
        k = k0*10^((pt(2) - p0(2))/20);
    case 'ratio'
        if abs(p0(2)) < eps, k = k0; else, k = k0*pt(2)/p0(2); end
end
end

function [k,Kk] = typeAndGain(sys)
% System type k (net number of poles at the origin) and Kk = lim s^k sys(s).
[z,p,g] = zpkdata(zpk(sys),'v');
tol = 1e-6;
zo = abs(z) < tol;
po = abs(p) < tol;
k = sum(po) - sum(zo);
Kk = real(g*prod(-z(~zo))/prod(-p(~po)));
end

function K = limGain(sys,j)
% lim_{s->0} s^j sys(s), e.g. Kp (j=0), Kv (j=1), Ka (j=2).
[k,Kk] = typeAndGain(sys);
if Kk == 0
    K = 0;
elseif j < k
    K = Inf*sign(Kk);
elseif j > k
    K = 0;
else
    K = Kk;
end
end

function e = errorForGain(K,Pk,q)
% e(inf) for unit test input q with G(s) = K and P(s) of type q (Section 10.7.2).
if q == 0
    e = 1./(1 + K*Pk);
else
    e = 1./(K*Pk);
end
end

function tf_ = isStable(p)
tf_ = all(real(p) < -1e-9);
end

function t = timeVector(Tf,p,q)
% Simulation time: user value, or ~8 time constants of the slowest pole
% (at least 5 s for ramp/parabolic inputs so the steady-state trend shows).
if Tf <= 0
    sig = -real(p);
    if isempty(sig)
        Tf = 5;
    elseif any(sig <= 1e-9)
        Tf = 10;
    else
        Tf = min(max(8/min(sig),0.5),500);
    end
    if q >= 1, Tf = max(Tf,5); end
end
t = linspace(0,Tf,2000)';
end

function str = fmtNum(x)
if x == 0, x = 0; end   % avoid printing -0
if isinf(x)
    if x > 0, str = '∞'; else, str = '-∞'; end
else
    str = sprintf('%.4g',x);
end
end

function str = num2tex(x)
if x == 0, x = 0; end
if isinf(x)
    if x > 0, str = '\infty'; else, str = '-\infty'; end
else
    str = sprintf('%.4g',x);
end
end

function str = stabStr(stable)
if stable
    str = 'closed loop is stable (all poles in OLHP)';
else
    str = 'closed loop is NOT stable -> FVT does not apply';
end
end

function str = polesStr(p)
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

function str = inputStr(a,q)
switch q
    case 0, str = sprintf('%g/s   (r = %g)',a,a);
    case 1, str = sprintf('%g/s^2 (r = %g t)',a,a);
    case 2, str = sprintf('%g/s^3 (r = %g t^2/2)',a,a);
end
end

function str = tfStr(sys)
[n,d] = tfdata(sys,'v');
str = sprintf('(%s) / (%s)',polyStr(n),polyStr(d));
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

function [keepDD,addDD,delBtn] = rootControls(grid,row,keepItems,addItems)
% "Keep fixed" selector and add/delete controls for a pole-zero editor.
at(uilabel(grid,'Text','Dragging keeps'),row,1);
keepDD = at(uidropdown(grid,'Items',keepItems,'Tooltip', ...
    ['Low-frequency gain: corner frequencies move without shifting the ' ...
    'low-frequency asymptote. zpk gain K: K in K*prod(s-z)/prod(s-p) is fixed.']),row,2);
g = at(uigridlayout(grid,[1 2],'Padding',[0 0 0 0]),row+1,[1 2]);
addDD = uidropdown(g,'Items',addItems);
delBtn = uibutton(g,'Text','Delete selected');
end

function noHit(ax,keep)
% Let clicks pass through everything on ax except the objects in keep.
ch = ax.Children;
set(ch(~ismember(ch,keep)),'HitTest','off');
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
% Editing a transfer function by hand switches the example selector to Custom.
dd.Value = 'Custom';
updateFcn();
end

function showError(ta,err)
ta.Value = {'Error:'; err.message; ''; ...
    'Enter transfer functions as MATLAB expressions in s,'; ...
    'e.g. 10/(s*(1+s/10)) or 36*(1+s)/s.'};
end
