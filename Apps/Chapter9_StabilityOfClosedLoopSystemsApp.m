function Chapter9_StabilityOfClosedLoopSystemsApp
%CHAPTER9_STABILITYOFCLOSEDLOOPSYSTEMSAPP Interactive GUI for MEC3079S Chapter 9 — Stability of closed-loop systems.
%
%   Run Chapter9_StabilityOfClosedLoopSystemsApp to open the app. The tabs follow the chapter:
%     1. Closed-loop poles   (9.2): poles/zeros of L(s) and T(s) = N/(N+D),
%        and the critical point L(jw) = -1.
%     2. Stability test      (9.3): phase/gain crossover frequencies and the
%        |L(jw_pc)| < 1 test on Nyquist, Bode and log-polar plots.
%     3. Margins             (9.4): gain margin, phase margin and stability
%        margin, plus the effect of an extra loop gain k.
%     4. Conditional stability (9.5): closed-loop stability as the loop gain
%        is raised or lowered, including negative gain margins.
%
%   Interaction:
%     - Drag the red poles (x) and zeros (o) of L(s) in any s-plane plot;
%       complex poles/zeros move as conjugate pairs. Blue crosses are the
%       resulting closed-loop poles. Use "Add"/"Delete selected" to change
%       the number of poles and zeros.
%     - Drag the L(jw) curve on the Bode magnitude, Nyquist or log-polar
%       plots to change the loop gain.
%     - Drag on the |T(jw)| plot (tab 1) to set the sinusoid frequency, and
%       on the stability-vs-gain plot (tab 4) to set k.
%
%   Transfer functions are entered as MATLAB expressions in s, for example
%   1/(s*(1+s)^2), 100/s/(1+s)^2 or exp(-5*s)/s.
%
%   Requires the Control System Toolbox.

c = appColours();
keepItems = {'Low-frequency gain','zpk gain K'};
addItems = {'Add pole/zero…','Real pole','Complex pole pair','Real zero','Complex zero pair'};

fig = uifigure('Name','MEC3079S Chapter 9 — Stability of closed-loop systems', ...
    'Position',[60 40 1320 860]);
mainGrid = uigridlayout(fig,[1 1],'Padding',[0 0 0 0]);
tg = uitabgroup(mainGrid);

% Drag state shared by all interactive plots
drag = struct('active',false,'ax',[],'move',[],'done',[],'p0',[0 0], ...
    'last',[],'xl',[],'yl',[],'t',tic);
fig.WindowButtonMotionFcn = @(~,~) onMotion();
fig.WindowButtonUpFcn = @(~,~) onRelease();

% Pole-zero editors, one per tab
pz = struct('ax',{},'ef',{},'dd',{},'upd',{},'keep',{},'roots',{},'K',{}, ...
    'tau',{},'r0',{},'K0',{},'selKind',{},'selVal',{});

%% =====================================================================
%  Tab 1: Closed-loop poles and the critical point
%  =====================================================================
t1 = uitab(tg,'Title','Closed-loop poles');
g1 = uigridlayout(t1,[1 2],'ColumnWidth',{340,'1x'});

c1 = uigridlayout(g1,[10 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{80,22,22,22,22,22,22,22,'1x',22});
at(uilabel(c1,'Text',['T(s) = L(s)/(1+L(s)) = N(s)/(N(s)+D(s)): closed-loop ' ...
    'poles are the roots of N(s)+D(s) = 0. Drag the red poles/zeros of L(s), ' ...
    'or drag on the |T(jω)| plot to set ω₀.'],'FontWeight','bold','WordWrap','on'),1,[1 2]);

presets1 = { ...
    'Ex 9.2.1: L = (1+s/5)/(1+s/20)',         '(1+s/5)/(1+s/20)', 1
    'Ex 9.2.2: L = 1/s^2 (hits -1 at w = 1)', '1/s^2',            1
    'Ex 9.3.4(1): L = 1/(s(1+s)^2)',          '1/(s*(1+s)^2)',    1
    'Ex 9.3.4(2): L = 100/(s(1+s)^2)',        '100/(s*(1+s)^2)',  1
    'Open-loop unstable: L = 1/(s-2)',        '1/(s-2)',          1
    'Custom', '', []};
at(uilabel(c1,'Text','Example'),2,1);
dd1Preset = at(uidropdown(c1,'Items',presets1(:,1)','Value',presets1{2,1}),2,2);
at(uilabel(c1,'Text','L(s) = P(s)G(s)'),3,1);
ef1L = at(uieditfield(c1,'text','Value',presets1{2,2}),3,2);
at(uilabel(c1,'Text','Sine input ω₀'),4,1);
ef1w = at(uieditfield(c1,'numeric','Value',presets1{2,3},'Limits',[0 Inf], ...
    'Tooltip','Frequency (rad/s) of the test sinusoid r(t) = sin(w0 t)'),4,2);
at(uilabel(c1,'Text','Final time (0=auto)'),5,1);
ef1T = at(uieditfield(c1,'numeric','Value',0,'Limits',[0 Inf], ...
    'Tooltip','0 = choose automatically from the closed-loop poles'),5,2);
[dd1Keep,dd1Add,btn1Del] = rootControls(c1,6,keepItems,addItems);
at(uilabel(c1,'Text','Results','FontWeight','bold'),8,[1 2]);
ta1 = at(uitextarea(c1,'Editable','off','FontName','Monospaced'),9,[1 2]);
btn1 = at(uibutton(c1,'Text','Update'),10,[1 2]);

r1 = uigridlayout(g1,[2 2]);
ax1pz = uiaxes(r1);
ax1T  = uiaxes(r1);
ax1s  = uiaxes(r1);
ax1w  = uiaxes(r1);

dd1Preset.ValueChangedFcn = @(~,~) loadPreset1();
ef1L.ValueChangedFcn = @(~,~) markCustom(dd1Preset,@update1);
[ef1w.ValueChangedFcn, ef1T.ValueChangedFcn] = deal(@(~,~) update1());
btn1.ButtonPushedFcn = @(~,~) update1();
registerEditor(1,ax1pz,ef1L,dd1Preset,@update1,dd1Keep,dd1Add,btn1Del);
disableDefaultInteractivity(ax1T);
ax1T.ButtonDownFcn = @(~,~) startDrag(ax1T,@(pt,~) setW0(pt(1)),@update1,true);

%% =====================================================================
%  Tab 2: Stability from the open-loop frequency response
%  =====================================================================
t2 = uitab(tg,'Title','Stability test');
g2 = uigridlayout(t2,[1 2],'ColumnWidth',{340,'1x'});

c2 = uigridlayout(g2,[11 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{80,22,22,22,30,220,22,22,22,'1x',22});
at(uilabel(c2,'Text',['Nyquist stability criterion (open-loop poles in the CLHP): ' ...
    'the closed loop is stable if |L(jω_pc)| < 1, where ∠L(jω_pc) = −180°. ' ...
    'Drag the L(jω) curves to change k.'], ...
    'FontWeight','bold','WordWrap','on'),1,[1 2]);

presets2 = { ...
    'Ex 9.3.1(1): L = 10/(s+1)',          '10/(s+1)'
    'Ex 9.3.1(2): L = e^{-5s}/s',         'exp(-5*s)/s'
    'Ex 9.3.4(1): L = 1/(s(1+s)^2)',      '1/(s*(1+s)^2)'
    'Ex 9.3.4(2): L = 100/(s(1+s)^2)',    '100/(s*(1+s)^2)'
    'Custom', ''};
at(uilabel(c2,'Text','Example'),2,1);
dd2Preset = at(uidropdown(c2,'Items',presets2(:,1)','Value',presets2{3,1}),2,2);
at(uilabel(c2,'Text','L(s) = P(s)G(s)'),3,1);
ef2L = at(uieditfield(c2,'text','Value',presets2{3,2}),3,2);
at(uilabel(c2,'Text','Gain multiplier k'),4,1);
ef2k = at(uieditfield(c2,'numeric','Value',1, ...
    'Tooltip','The loop analysed is k*L(s); change k to move |L| up or down'),4,2);
lbl2R = at(uilabel(c2,'Text','','Interpreter','latex','FontSize',13),5,[1 2]);
ax2pz = at(uiaxes(c2),6,[1 2]);
[dd2Keep,dd2Add,btn2Del] = rootControls(c2,7,keepItems,addItems);
at(uilabel(c2,'Text','Results','FontWeight','bold'),9,[1 2]);
ta2 = at(uitextarea(c2,'Editable','off','FontName','Monospaced'),10,[1 2]);
btn2 = at(uibutton(c2,'Text','Update'),11,[1 2]);

r2 = uigridlayout(g2,[2 2]);
ax2m  = at(uiaxes(r2),1,1);
ax2p  = at(uiaxes(r2),2,1);
ax2ny = at(uiaxes(r2),1,2);
ax2ni = at(uiaxes(r2),2,2);

dd2Preset.ValueChangedFcn = @(~,~) loadPreset2();
ef2L.ValueChangedFcn = @(~,~) markCustom(dd2Preset,@update2);
ef2k.ValueChangedFcn = @(~,~) update2();
btn2.ButtonPushedFcn = @(~,~) update2();
registerEditor(2,ax2pz,ef2L,dd2Preset,@update2,dd2Keep,dd2Add,btn2Del);
[ax2m.Interactions, ax2ny.Interactions, ax2ni.Interactions] = deal([]);

%% =====================================================================
%  Tab 3: Margins of stability
%  =====================================================================
t3 = uitab(tg,'Title','Margins');
g3 = uigridlayout(t3,[1 2],'ColumnWidth',{340,'1x'});

c3 = uigridlayout(g3,[12 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{80,22,22,22,22,30,220,22,22,22,'1x',22});
at(uilabel(c3,'Text',['G_M = −|L(jω_pc)|_dB,  φ_M = 180° + ∠L(jω_gc),  ' ...
    's_M = min |1 + L(jω)| (distance from L(jω) to the critical point). ' ...
    'Drag the L(jω) curves to scale L(s).'], ...
    'FontWeight','bold','WordWrap','on'),1,[1 2]);

presets3 = { ...
    'Ex 9.4.1: L = 1/(s(1+s)^2), k = 2.1',                 '1/(s*(1+s)^2)', 2.1
    'Ex 9.4.2: L = 0.38(s^2+0.1s+0.55)/(s(s+1)(s^2+0.06s+0.5))', ...
        '0.38*(s^2+0.1*s+0.55)/(s*(s+1)*(s^2+0.06*s+0.5))', 1
    'Ex 9.3.1(1): L = 10/(s+1)',                           '10/(s+1)', 1
    'Delay: L = 0.2e^{-5s}/s, k = 1.5',                    '0.2*exp(-5*s)/s', 1.5
    'Custom', '', []};
at(uilabel(c3,'Text','Example'),2,1);
dd3Preset = at(uidropdown(c3,'Items',presets3(:,1)','Value',presets3{1,1}),2,2);
at(uilabel(c3,'Text','L(s) = P(s)G(s)'),3,1);
ef3L = at(uieditfield(c3,'text','Value',presets3{1,2}),3,2);
at(uilabel(c3,'Text','Extra gain k'),4,1);
ef3k = at(uieditfield(c3,'numeric','Value',presets3{1,3}, ...
    'Tooltip','Compares the step response of T(s) with that of T_k(s) = kL/(1+kL)'),4,2);
at(uilabel(c3,'Text','Final time (0=auto)'),5,1);
ef3T = at(uieditfield(c3,'numeric','Value',0,'Limits',[0 Inf]),5,2);
lbl3R = at(uilabel(c3,'Text','','Interpreter','latex','FontSize',13),6,[1 2]);
ax3pz = at(uiaxes(c3),7,[1 2]);
[dd3Keep,dd3Add,btn3Del] = rootControls(c3,8,keepItems,addItems);
at(uilabel(c3,'Text','Results','FontWeight','bold'),10,[1 2]);
ta3 = at(uitextarea(c3,'Editable','off','FontName','Monospaced'),11,[1 2]);
btn3 = at(uibutton(c3,'Text','Update'),12,[1 2]);

r3 = uigridlayout(g3,[6 2]);
ax3m  = at(uiaxes(r3),[1 2],1);
ax3p  = at(uiaxes(r3),[3 4],1);
ax3s  = at(uiaxes(r3),[5 6],1);
ax3ny = at(uiaxes(r3),[1 3],2);
ax3ni = at(uiaxes(r3),[4 6],2);

dd3Preset.ValueChangedFcn = @(~,~) loadPreset3();
ef3L.ValueChangedFcn = @(~,~) markCustom(dd3Preset,@update3);
[ef3k.ValueChangedFcn, ef3T.ValueChangedFcn] = deal(@(~,~) update3());
btn3.ButtonPushedFcn = @(~,~) update3();
registerEditor(3,ax3pz,ef3L,dd3Preset,@update3,dd3Keep,dd3Add,btn3Del);
[ax3m.Interactions, ax3ny.Interactions, ax3ni.Interactions] = deal([]);

%% =====================================================================
%  Tab 4: Conditional stability
%  =====================================================================
t4 = uitab(tg,'Title','Conditional stability');
g4 = uigridlayout(t4,[1 2],'ColumnWidth',{340,'1x'});

c4 = uigridlayout(g4,[12 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{80,22,22,40,22,30,220,22,22,22,'1x',22});
at(uilabel(c4,'Text',['Scale the loop gain: kL(s). A conditionally stable loop ' ...
    'goes unstable if k is too small (negative gain margin) as well as too large. ' ...
    'Drag the log-polar locus or the stability-vs-gain plot to set k.'], ...
    'FontWeight','bold','WordWrap','on'),1,[1 2]);

presets4 = { ...
    'Ex 9.5: L = 0.1(1+s)(1+s/0.1)/(s^3(1+s/5)^2)', '0.1*(1+s)*(1+s/0.1)/(s^3*(1+s/5)^2)'
    'Ex 9.3.4(1): L = 1/(s(1+s)^2)',               '1/(s*(1+s)^2)'
    'Ex 9.3.1(1): L = 10/(s+1)',                   '10/(s+1)'
    'Custom', ''};
at(uilabel(c4,'Text','Example'),2,1);
dd4Preset = at(uidropdown(c4,'Items',presets4(:,1)','Value',presets4{1,1}),2,2);
at(uilabel(c4,'Text','L(s) = P(s)G(s)'),3,1);
ef4L = at(uieditfield(c4,'text','Value',presets4{1,2}),3,2);
at(uilabel(c4,'Text','Gain k (dB)'),4,1);
sl4k = at(uislider(c4,'Limits',[-40 40],'Value',0,'MajorTicks',-40:20:40),4,2);
at(uilabel(c4,'Text','k (dB) / k'),5,1);
g4k = at(uigridlayout(c4,[1 2],'Padding',[0 0 0 0]),5,2);
ef4kdB = uieditfield(g4k,'numeric','Value',0,'Limits',[-40 40]);
lbl4k = uilabel(g4k,'Text','k = 1');
lbl4R = at(uilabel(c4,'Text','','Interpreter','latex','FontSize',13),6,[1 2]);
ax4pz = at(uiaxes(c4),7,[1 2]);
[dd4Keep,dd4Add,btn4Del] = rootControls(c4,8,keepItems,addItems);
at(uilabel(c4,'Text','Results','FontWeight','bold'),10,[1 2]);
ta4 = at(uitextarea(c4,'Editable','off','FontName','Monospaced'),11,[1 2]);
btn4 = at(uibutton(c4,'Text','Update'),12,[1 2]);

r4 = uigridlayout(g4,[2 2]);
ax4ni = at(uiaxes(r4),[1 2],1);
ax4k  = at(uiaxes(r4),1,2);
ax4s  = at(uiaxes(r4),2,2);

dd4Preset.ValueChangedFcn = @(~,~) loadPreset4();
ef4L.ValueChangedFcn = @(~,~) markCustom(dd4Preset,@update4);
sl4k.ValueChangedFcn = @(~,~) setGain4(sl4k.Value);
ef4kdB.ValueChangedFcn = @(~,~) setGain4(ef4kdB.Value);
btn4.ButtonPushedFcn = @(~,~) update4();
registerEditor(4,ax4pz,ef4L,dd4Preset,@update4,dd4Keep,dd4Add,btn4Del);
[ax4ni.Interactions, ax4k.Interactions] = deal([]);
ax4k.ButtonDownFcn = @(~,~) startDrag(ax4k,@(pt,~) setGain4(pt(1)),@update4,true);

% Initial draw
update1(); update2(); update3(); update4();

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

    function gainDown(ax,mode,getK,setK,doneFcn)
        % Drag a frequency-response curve to scale the loop gain.
        k0 = getK();
        startDrag(ax,@(pt,p0) setK(scaledGain(mode,k0,pt,p0)),doneFcn);
    end

    function loopGainDown(i,ax,mode)
        % Drag a curve to scale L(s) itself (its zpk gain).
        pz(i).r0 = pz(i).roots;
        pz(i).K0 = pz(i).K;
        gainDown(ax,mode,@() 1,@(f) setLoop(i,pz(i).r0,pz(i).K0*f),pz(i).upd);
    end

    function nicholsDown4()
        kdB0 = ef4kdB.Value;
        startDrag(ax4ni,@(pt,p0) setGain4(kdB0 + pt(2) - p0(2)),@update4);
    end

%% =====================================================================
%  Pole-zero editors
%  =====================================================================
    function registerEditor(i,ax,ef,dd,updFcn,keepDD,addDD,delBtn)
        pz(i).ax = ax;
        pz(i).ef = ef;
        pz(i).dd = dd;
        pz(i).upd = updFcn;
        pz(i).keep = keepDD;
        pz(i).selKind = '';
        pz(i).selVal = [];
        ax.Interactions = [];
        addDD.ValueChangedFcn = @(src,~) addRoot(i,src);
        delBtn.ButtonPushedFcn = @(~,~) deleteRoot(i);
    end

    function drawRoots(i,L0,pCL,big)
        % Draw the draggable open-loop poles/zeros of L0 and the closed-loop poles.
        ax = pz(i).ax;
        [z,p,K] = zpkdata(zpk(L0),'v');
        rl = rootList(z,p);
        pz(i).roots = rl;
        pz(i).K = K;
        pz(i).tau = totaldelay(L0);

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
        hCL = plot(ax,real(pCL),imag(pCL),'x','Color',c.cl,'MarkerSize',9,'LineWidth',2,'HitTest','off');

        sel = selectedIndex(i);
        hP = gobjects(0); hZ = gobjects(0);
        for j = 1:numel(rl)
            v = rl(j).val;
            if rl(j).pair, xs = [real(v) real(v)]; ys = [imag(v) -imag(v)];
            else, xs = real(v); ys = 0; end
            if rl(j).kind == 'p', mk = 'x'; ms = 14; else, mk = 'o'; ms = 10; end
            col = c.ol; lw = 2.5;
            if j == sel, col = c.gm; lw = 3.5; end
            h = plot(ax,xs,ys,mk,'Color',col,'MarkerSize',ms,'LineWidth',lw, ...
                'ButtonDownFcn',@(~,~) rootDown(i,j));
            if rl(j).kind == 'p', hP(end+1) = h; else, hZ(end+1) = h; end %#ok<AGROW>
        end
        hold(ax,'off'); grid(ax,'on');
        ax.DataAspectRatio = [1 1 1];
        xlim(ax,xl); ylim(ax,yl);
        if big
            hs = [hP(1:min(end,1)) hZ(1:min(end,1)) hCL];
            names = {'poles of L (drag)','zeros of L (drag)','poles of T'};
            names = names([~isempty(hP) ~isempty(hZ) true]);
            legend(ax,hs,names,'Location','best');
            title(ax,'s-plane: drag the poles/zeros of L(s)');
            xlabel(ax,'Real axis'); ylabel(ax,'Imaginary axis');
        else
            legend(ax,'off');
            title(ax,'Drag poles (x) / zeros (o) of L;  blue x: closed loop','FontSize',10, ...
                'FontWeight','normal');
            ax.FontSize = 9;
        end
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
        pz(i).ef.Value = rootsToExpr(rl,K,pz(i).tau);
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
            uialert(fig,'L(s) cannot have more zeros than poles.','Not allowed');
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
        ef1L.Value = presets1{i,2};
        ef1w.Value = presets1{i,3};
        update1();
    end

    function setW0(w0)
        ef1w.Value = max(w0,1e-6);
        update1();
    end

    function update1()
        try
            L = parseTF(ef1L.Value);
            T = feedback(L,1);
            [pCL,approx] = clPoles(L);
            pOL = pole(L);
            zOL = zero(L);
            [~,cls] = stabClass(pCL);

            drawRoots(1,L,pCL,true);

            % |T(jw)| and |L(jw)|; drag on this plot to set w0
            w0 = ef1w.Value;
            w = freqGrid(L,w0);
            Tw = squeeze(freqresp(T,w)); Lw = squeeze(freqresp(L,w));
            cla(ax1T); hold(ax1T,'on');
            hL = plot(ax1T,w,20*log10(abs(Lw)),'Color',c.ol,'LineWidth',1.5);
            hT = plot(ax1T,w,20*log10(abs(Tw)),'Color',c.cl,'LineWidth',2);
            if w0 > 0, xline(ax1T,w0,'--k','\omega_0 (drag)','LineWidth',1.5); end
            hold(ax1T,'off'); grid(ax1T,'on'); ax1T.XScale = 'log';
            xlim(ax1T,[w(1) w(end)]);
            legend(ax1T,[hL hT],{'|L(j\omega)|','|T(j\omega)| = |L|/|1+L|'},'Location','best');
            title(ax1T,'Frequency response magnitude (drag to set \omega_0)');
            xlabel(ax1T,'Frequency (rad/s)'); ylabel(ax1T,'Magnitude (dB)');
            noHit(ax1T,[]);

            % Step and sinusoidal responses of T
            t = timeVector(ef1T.Value,pCL);
            y = step(T,t);
            cla(ax1s); hold(ax1s,'on');
            plot(ax1s,t,ones(size(t)),'Color',c.ref,'LineWidth',1.5);
            plot(ax1s,t,y,'Color',c.cl,'LineWidth',2);
            hold(ax1s,'off'); grid(ax1s,'on');
            legend(ax1s,{'r(t) = 1','y(t)'},'Location','best');
            title(ax1s,'Closed-loop step response'); xlabel(ax1s,'Time (s)');

            r = sin(w0*t);
            ys = lsim(T,r,t);
            cla(ax1w); hold(ax1w,'on');
            plot(ax1w,t,r,'Color',c.ref,'LineWidth',1.5);
            plot(ax1w,t,ys,'Color',c.cl,'LineWidth',2);
            hold(ax1w,'off'); grid(ax1w,'on');
            legend(ax1w,{sprintf('r(t) = sin(%.3g t)',w0),'y(t)'},'Location','best');
            title(ax1w,'Closed-loop response to a sinusoid'); xlabel(ax1w,'Time (s)');

            % Results
            [n,d] = tfdata(L,'v');
            Lw0 = squeeze(freqresp(L,w0));
            txt = { ...
                ['L(s) = ' tfStr(L)]
                ['N(s) = ' polyStr(n)]
                ['D(s) = ' polyStr(d)]
                ['N(s) + D(s) = ' polyStr(padAdd(n,d))]
                ''
                'Open-loop poles:'; rootsStr(pOL)
                'Open-loop zeros (= zeros of T):'; rootsStr(zOL)
                ''
                'Closed-loop poles (roots of N+D):'; rootsStr(pCL)
                ['=> closed loop is ' cls]};
            if approx
                txt = [txt; {'(delay replaced by a Padé approximation)'}];
            end
            txt = [txt; {''
                sprintf('L(jw0) = %s',cplxStr(Lw0))
                sprintf('|1 + L(jw0)| = %.4g',abs(1+Lw0))}];
            if abs(1+Lw0) < 1e-6
                txt = [txt; {'L(jw0) = -1: the critical point is hit,'; ...
                    'so |T(jw0)| -> infinity.'}];
            end
            if any(real(pOL) > 1e-9)
                txt = [txt; {''; 'Note: L(s) has RHP poles. The frequency-'; ...
                    'response tests of Section 9.3 assume open-loop'; ...
                    'poles in the CLHP.'}];
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
        ef2L.Value = presets2{i,2};
        ef2k.Value = 1;
        update2();
    end

    function setK2(k)
        ef2k.Value = k;
        update2();
    end

    function update2()
        try
            L0 = parseTF(ef2L.Value);
            L = ef2k.Value*L0;
            mg = allmargin(L);
            [wpc,wgc] = crossovers(mg);
            [w,H,magdB,ph] = freqData(L,[wpc; wgc]);
            [pCL,approx] = clPoles(L);
            stable = mg.Stable;

            drawRoots(2,L0,pCL,false);
            hM = plotBode(ax2m,ax2p,w,magdB,ph,wpc,wgc,false);
            title(ax2m,'Bode diagram of kL(j\omega) (drag |L| to change k)');
            hN = plotNyquist(ax2ny,H,L,wpc,wgc,NaN);
            hC = plotNichols(ax2ni,magdB,ph,w,wpc,wgc,false);
            hM.ButtonDownFcn = @(~,~) gainDown(ax2m,'dB',@() ef2k.Value,@setK2,@update2);
            hN.ButtonDownFcn = @(~,~) gainDown(ax2ny,'radial',@() ef2k.Value,@setK2,@update2);
            hC.ButtonDownFcn = @(~,~) gainDown(ax2ni,'dB',@() ef2k.Value,@setK2,@update2);

            Lpc = abs(squeeze(freqresp(L,wpc)));
            if isempty(wpc)
                lbl2R.Text = ['$\mathrm{No}\ \omega_{pc}\ \mathrm{exists} \Rightarrow ' ...
                    '\mathrm{closed\ loop\ stable}$'];
            else
                if Lpc(1) < 1, rel = '<'; verdict = 'stable'; else, rel = '>'; verdict = 'unstable'; end
                lbl2R.Text = sprintf(['$|L(j\\omega_{pc})|_{dB}=%.3g\\ \\mathrm{dB} %s 0' ...
                    '\\Rightarrow \\mathrm{%s}$'],20*log10(Lpc(1)),rel,verdict);
            end

            txt = { ...
                ['L(s) = ' tfStr(L)]
                sprintf('k = %.4g',ef2k.Value)
                ''
                'Phase crossover frequencies (angle = -180 deg):'};
            if isempty(wpc)
                txt{end+1} = '  none -> infinite gain margin';
            end
            if numel(mg.GMFrequency(isfinite(mg.GMFrequency) & mg.GMFrequency > 0)) > numel(wpc)
                txt{end+1} = '  (lowest shown; the delay gives infinitely many)';
            end
            for i = 1:numel(wpc)
                txt{end+1} = sprintf('  w_pc = %.4g rad/s, |L| = %.4g (%.3g dB)', ...
                    wpc(i),Lpc(i),20*log10(Lpc(i))); %#ok<AGROW>
            end
            txt = [txt; {''; 'Gain crossover frequencies (|L| = 1, 0 dB):'}];
            if isempty(wgc), txt{end+1} = '  none'; end
            for i = 1:numel(wgc)
                txt{end+1} = sprintf('  w_gc = %.4g rad/s, angle L = %.4g deg', ...
                    wgc(i),interpLog(w,ph,wgc(i))); %#ok<AGROW>
            end
            txt = [txt; {''
                ['Closed loop (exact check): ' stabWord(stable)]
                'Closed-loop poles:'; rootsStr(pCL)}];
            if approx, txt{end+1} = '(delay replaced by a Padé approximation)'; end
            if any(real(pole(L)) > 1e-9)
                txt = [txt; {''; 'WARNING: L(s) has RHP poles, so the simple'; ...
                    '|L(jw_pc)| < 1 test does not apply.'}];
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
        ef3L.Value = presets3{i,2};
        ef3k.Value = presets3{i,3};
        update3();
    end

    function update3()
        try
            L = parseTF(ef3L.Value);
            k = ef3k.Value;
            mg = allmargin(L);
            [wpc,wgc] = crossovers(mg);
            ws = warning('off','all');   % margin warns when the loop is unstable; shown in Results
            [Gm,Pm,Wpc,Wgc] = margin(L);
            warning(ws);
            [w,H,magdB,ph] = freqData(L,[wpc; wgc]);
            [sM,wsM] = stabilityMargin(L,w);
            [p1,~] = clPoles(L);

            drawRoots(3,L,p1,false);
            hM = plotBode(ax3m,ax3p,w,magdB,ph,Wpc(isfinite(Wpc)),Wgc(isfinite(Wgc)),true);
            title(ax3m,'G_M at \omega_{pc} and \phi_M at \omega_{gc} (drag |L| to scale L)');
            hN = plotNyquist(ax3ny,H,L,wpc,wgc,[sM wsM]);
            hC = plotNichols(ax3ni,magdB,ph,w,Wpc(isfinite(Wpc)),Wgc(isfinite(Wgc)),true);
            hM.ButtonDownFcn = @(~,~) loopGainDown(3,ax3m,'dB');
            hN.ButtonDownFcn = @(~,~) loopGainDown(3,ax3ny,'radial');
            hC.ButtonDownFcn = @(~,~) loopGainDown(3,ax3ni,'dB');

            % Step responses of T and T_k
            T  = feedback(L,1);
            Tk = feedback(k*L,1);
            [pk,~] = clPoles(k*L);
            stableK = allmargin(k*L).Stable;
            t = timeVector(ef3T.Value,[p1; pk]);
            y  = step(T,t);
            yk = step(Tk,t);
            if ~stableK
                % Keep the unstable response from swamping the plot
                lim = 5*max(1,max(abs(y)));
                yk(abs(yk) > lim) = NaN;
            end
            cla(ax3s); hold(ax3s,'on');
            plot(ax3s,t,y,'Color',c.cl,'LineWidth',2);
            plot(ax3s,t,yk,'Color',c.k,'LineWidth',2);
            hold(ax3s,'off'); grid(ax3s,'on');
            legend(ax3s,{'y(t): T = L/(1+L)',sprintf('y_k(t): k = %g (%s)',k,stabWord(stableK))}, ...
                'Location','best');
            title(ax3s,'Closed-loop step responses'); xlabel(ax3s,'Time (s)');

            lbl3R.Text = sprintf('$G_M=%s\\ \\mathrm{dB},\\ \\phi_M=%s^\\circ,\\ s_M=%.3g$', ...
                texNum(20*log10(Gm)),texNum(Pm),sM);

            txt = { ...
                ['L(s) = ' tfStr(L)]
                ''
                'margin(L) (smallest margins):'
                sprintf('  G_M  = %s dB (x%s) at w_pc = %s rad/s',fmtNum(20*log10(Gm)),fmtNum(Gm),fmtNum(Wpc))
                sprintf('  phi_M = %s deg at w_gc = %s rad/s',fmtNum(Pm),fmtNum(Wgc))
                sprintf('  s_M  = min|1+L(jw)| = %.4g at w = %.4g rad/s',sM,wsM)};
            if hasdelay(L)
                txt{end+1} = sprintf('  delay margin = %s s',fmtNum(min(mg.DelayMargin)));
            end
            if numel(wpc) > 1
                txt{end+1} = '';
                txt{end+1} = 'Gain margins at the lowest w_pc (allmargin):';
                for i = find(ismember(mg.GMFrequency,wpc))
                    txt{end+1} = sprintf('  %+.3g dB at %.4g rad/s',20*log10(mg.GainMargin(i)), ...
                        mg.GMFrequency(i)); %#ok<AGROW>
                end
            end
            txt = [txt; {''
                sprintf('Extra gain k = %g (%.3g dB):',k,20*log10(abs(k)))
                ['  T_k is ' stabWord(stableK)]}];
            if isfinite(Gm)
                txt{end+1} = sprintf('  (expected unstable for k >= %.4g)',Gm);
            end
            txt = [txt; {''; 'Typical targets: G_M 6-14 dB, phi_M 30-60 deg,'; 's_M 0.5-0.8.'}];
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
        setGain4(0);
    end

    function setGain4(kdB)
        kdB = min(max(kdB,sl4k.Limits(1)),sl4k.Limits(2));
        sl4k.Value = kdB;
        ef4kdB.Value = kdB;
        update4();
    end

    function update4()
        try
            L0 = parseTF(ef4L.Value);
            kdB = ef4kdB.Value;
            k = 10^(kdB/20);
            lbl4k.Text = sprintf('k = %.4g',k);
            L = k*L0;
            mg = allmargin(L);
            [wpc,wgc] = crossovers(mg);
            [w,~,magdB,ph] = freqData(L,[wpc; wgc]);
            stable = mg.Stable;
            [pCL,approx] = clPoles(L);

            drawRoots(4,L0,pCL,false);
            hC = plotNichols(ax4ni,magdB,ph,w,wpc,wgc,false);
            title(ax4ni,sprintf('Log-polar plot of kL(j\\omega), k = %.3g dB (drag to change k)',kdB));
            hC.ButtonDownFcn = @(~,~) nicholsDown4();

            % Closed-loop stability as a function of the loop gain
            kgrid = linspace(-40,40,401);
            maxRe = gainSweep(L0,kgrid);
            stab = maxRe < -1e-9;
            cla(ax4k); hold(ax4k,'on');
            yl = [min([maxRe -0.1]) max([maxRe 0.1])];
            yl = yl + [-0.1 0.1]*diff(yl);
            shadeRegions(ax4k,kgrid,stab,yl,[0.85 0.95 0.85]);
            plot(ax4k,kgrid,maxRe,'Color',c.cl,'LineWidth',2);
            yline(ax4k,0,'k');
            xline(ax4k,kdB,'-','Color',c.k,'LineWidth',2.5);
            gm0 = allmargin(L0);
            gmF = isfinite(gm0.GMFrequency) & gm0.GMFrequency > 0;
            for g = 20*log10(gm0.GainMargin(gmF))
                xline(ax4k,g,':r',sprintf('%+.3g dB',g),'LineWidth',1.5);
            end
            hold(ax4k,'off'); grid(ax4k,'on');
            xlim(ax4k,kgrid([1 end])); ylim(ax4k,yl);
            title(ax4k,'Closed-loop stability vs gain (green: stable; drag to set k)');
            xlabel(ax4k,'k (dB)'); ylabel(ax4k,'max Re(closed-loop poles)');
            noHit(ax4k,[]);

            t = timeVector(0,pCL);
            y = step(feedback(L,1),t);
            if ~stable
                y(abs(y) > 20) = NaN;
            end
            cla(ax4s);
            plot(ax4s,t,y,'Color',c.cl,'LineWidth',2);
            grid(ax4s,'on');
            title(ax4s,sprintf('Closed-loop step response (%s)',stabWord(stable)));
            xlabel(ax4s,'Time (s)');

            if stable
                lbl4R.Text = sprintf('$k=%.3g\\ \\mathrm{dB}\\Rightarrow\\ \\mathrm{stable}$',kdB);
            else
                lbl4R.Text = sprintf('$k=%.3g\\ \\mathrm{dB}\\Rightarrow\\ \\mathrm{unstable}$',kdB);
            end

            txt = { ...
                ['L(s) = ' tfStr(L0)]
                sprintf('k = %.4g (%.3g dB)',k,kdB)
                ''
                'Gain margins of L (allmargin):'};
            if ~any(gmF), txt{end+1} = '  none (infinite gain margin)'; end
            for i = find(gmF)
                g = 20*log10(gm0.GainMargin(i));
                if g < 0, kind = 'reduction'; else, kind = 'increase'; end
                txt{end+1} = sprintf('  %+.3g dB at %.4g rad/s (gain %s)',g,gm0.GMFrequency(i),kind); %#ok<AGROW>
            end
            txt = [txt; {''; 'Stable gain range(s), from -40 to 40 dB:'}];
            txt = [txt; rangesStr(kgrid,stab)];
            txt = [txt; {''
                ['Closed loop with this k: ' stabWord(stable)]
                'Closed-loop poles:'; rootsStr(pCL)}];
            if approx, txt{end+1} = '(delay replaced by a Padé approximation)'; end
            if any(diff(stab) == 1) && any(diff(stab) == -1)
                txt = [txt; {''; 'Stability is conditional: too little gain'; ...
                    'also destabilises the loop (negative G_M).'}];
            end
            ta4.Value = flatLines(txt);
        catch err
            showError(ta4,err);
        end
    end
end

%% =========================================================================
%  Plotting helpers
%  =========================================================================
function c = appColours()
c.ol  = [0.85 0.33 0.10];   % open loop
c.cl  = [0.00 0.45 0.74];   % closed loop / L(jw)
c.ref = [0.50 0.50 0.50];
c.k   = [0.49 0.18 0.56];
c.gm  = [0.47 0.67 0.19];
c.pm  = [0.93 0.69 0.13];
c.crit = [0.85 0.10 0.10];
end

function hMag = plotBode(axM,axP,w,magdB,ph,wpc,wgc,showMargins)
% Bode magnitude and phase of L(jw), marking w_pc and w_gc. Returns the
% magnitude curve so it can be made draggable.
c = appColours();
cla(axM); hold(axM,'on');
hMag = plot(axM,w,magdB,'Color',c.cl,'LineWidth',2.5);
yline(axM,0,':k');
cla(axP); hold(axP,'on');
plot(axP,w,ph,'Color',c.cl,'LineWidth',2);
for crit = critPhases(ph)
    yline(axP,crit,':k');
end
for i = 1:numel(wpc)
    m = interpLog(w,magdB,wpc(i));
    p = interpLog(w,ph,wpc(i));
    crit = nearestCrit(p);
    if showMargins
        plot(axM,[wpc(i) wpc(i)],[m 0],'-','Color',c.gm,'LineWidth',3);
        text(axM,wpc(i),m/2,sprintf('  G_M = %.3g dB',-m),'Color',c.gm,'FontWeight','bold');
    end
    plot(axM,wpc(i),m,'s','Color',c.crit,'MarkerFaceColor',c.crit);
    plot(axP,wpc(i),crit,'s','Color',c.crit,'MarkerFaceColor',c.crit);
    xline(axM,wpc(i),'--','Color',c.crit);
    xline(axP,wpc(i),'--','Color',c.crit);
    text(axP,wpc(i),crit,sprintf('  \\omega_{pc} = %.3g',wpc(i)),'Color',c.crit, ...
        'VerticalAlignment','top');
end
for i = 1:numel(wgc)
    p = interpLog(w,ph,wgc(i));
    crit = nearestCrit(p);
    if showMargins
        plot(axP,[wgc(i) wgc(i)],[crit p],'-','Color',c.pm,'LineWidth',3);
        text(axP,wgc(i),(crit+p)/2,sprintf('  \\phi_M = %.3g°',p-crit),'Color',[0.6 0.4 0], ...
            'FontWeight','bold');
    end
    plot(axM,wgc(i),0,'o','Color',c.k,'MarkerFaceColor',c.k);
    plot(axP,wgc(i),p,'o','Color',c.k,'MarkerFaceColor',c.k);
    xline(axM,wgc(i),'--','Color',c.k);
    xline(axP,wgc(i),'--','Color',c.k);
    text(axM,wgc(i),0,sprintf('  \\omega_{gc} = %.3g',wgc(i)),'Color',c.k, ...
        'VerticalAlignment','bottom');
end
hold(axM,'off'); hold(axP,'off');
grid(axM,'on'); grid(axP,'on');
axM.XScale = 'log'; axP.XScale = 'log';
xlim(axM,[w(1) w(end)]); xlim(axP,[w(1) w(end)]);
ylim(axM,clipRange(magdB,[-100 100],0));
ylim(axP,clipRange(ph,[-Inf Inf],-180));
ylabel(axM,'Magnitude (dB)'); ylabel(axP,'Phase (deg)');
xlabel(axP,'Frequency (rad/s)');
title(axP,'');
noHit(axM,hMag);
noHit(axP,[]);
end

function hL = plotNyquist(ax,H,L,wpc,wgc,sM)
% Nyquist plot of L(jw) with the critical point, the unit circle and
% (optionally) the stability margin circle sM = [radius, frequency].
c = appColours();
cla(ax); hold(ax,'on');
th = linspace(0,2*pi,200);
plot(ax,cos(th),sin(th),':','Color',[0.6 0.6 0.6]);
hL = plot(ax,real(H),imag(H),'Color',c.cl,'LineWidth',2.5);
plot(ax,real(H),-imag(H),'--','Color',[c.cl 0.4],'LineWidth',1);
leg = {'unit circle','L(j\omega), \omega > 0','\omega < 0'};
Lpc = squeeze(freqresp(L,wpc));
if ~isempty(wpc)
    plot(ax,real(Lpc),imag(Lpc),'s','Color',c.crit,'MarkerFaceColor',c.crit);
    leg{end+1} = 'L(j\omega_{pc})';
end
if ~isempty(wgc)
    Lgc = squeeze(freqresp(L,wgc));
    plot(ax,real(Lgc),imag(Lgc),'o','Color',c.k,'MarkerFaceColor',c.k);
    leg{end+1} = 'L(j\omega_{gc})';
end
if ~isnan(sM(1))
    plot(ax,-1+sM(1)*cos(th),sM(1)*sin(th),'-','Color',c.gm,'LineWidth',1.5);
    Ls = squeeze(freqresp(L,sM(2)));
    plot(ax,[-1 real(Ls)],[0 imag(Ls)],'-','Color',c.gm,'LineWidth',2);
    leg = [leg {sprintf('s_M = %.3g',sM(1)),''}];
end
plot(ax,-1,0,'+','Color',c.crit,'MarkerSize',14,'LineWidth',2.5);
leg{end+1} = 'critical point (-1,0)';
hold(ax,'off'); grid(ax,'on');

% Choose a view that shows the critical point region clearly
A = abs(H);
if max(A) <= 20
    Rv = 1.15*max([A; 1.3]);
else
    Rv = max([2.5; 1.5*abs(Lpc(:))]);
end
ax.DataAspectRatio = [1 1 1];
xlim(ax,[-Rv Rv]); ylim(ax,[-Rv Rv]);
legend(ax,leg,'Location','best');
title(ax,'Nyquist plot of L(j\omega) (drag to scale)');
xlabel(ax,'Real axis'); ylabel(ax,'Imaginary axis');
noHit(ax,hL);
end

function hL = plotNichols(ax,magdB,ph,w,wpc,wgc,showMargins)
% Log-polar (Nichols) plot: phase on x, magnitude in dB on y.
c = appColours();
cla(ax); hold(ax,'on');
hL = plot(ax,ph,magdB,'Color',c.cl,'LineWidth',2.5);
for i = 1:numel(wpc)
    m = interpLog(w,magdB,wpc(i));
    crit = nearestCrit(interpLog(w,ph,wpc(i)));
    if showMargins
        plot(ax,[crit crit],[m 0],'-','Color',c.gm,'LineWidth',3);
        text(ax,crit,m/2,sprintf('  G_M = %.3g dB',-m),'Color',c.gm,'FontWeight','bold');
    end
    plot(ax,crit,m,'s','Color',c.crit,'MarkerFaceColor',c.crit);
end
for i = 1:numel(wgc)
    p = interpLog(w,ph,wgc(i));
    crit = nearestCrit(p);
    if showMargins
        plot(ax,[crit p],[0 0],'-','Color',c.pm,'LineWidth',3);
        text(ax,(crit+p)/2,0,sprintf('\\phi_M = %.3g°',p-crit),'Color',[0.6 0.4 0], ...
            'FontWeight','bold','VerticalAlignment','bottom','HorizontalAlignment','center');
    end
    plot(ax,p,0,'o','Color',c.k,'MarkerFaceColor',c.k);
end
xr = [min(ph) max(ph)];
xr = [min(xr(1),-200) max(xr(2),-160)];
for crit = critPhases(xr)
    plot(ax,crit,0,'+','Color',c.crit,'MarkerSize',16,'LineWidth',2.5);
end
hold(ax,'off'); grid(ax,'on');
xr = xr + [-10 10];
xlim(ax,xr);
ylim(ax,clipRange(magdB,[-80 80],0));
if diff(xr) <= 300, dx = 45; elseif diff(xr) <= 800, dx = 90; else, dx = 180; end
ax.XTick = dx*ceil(xr(1)/dx):dx:dx*floor(xr(2)/dx);
title(ax,'Log-polar plot (critical point: 0 dB, -180°)');
xlabel(ax,'Phase (deg)'); ylabel(ax,'Magnitude (dB)');
noHit(ax,hL);
end

function shadeRegions(ax,x,mask,yl,colour)
% Shade the x-intervals where mask is true.
d = diff([false mask false]);
st = find(d == 1); en = find(d == -1) - 1;
for i = 1:numel(st)
    patch(ax,x([st(i) en(i) en(i) st(i)]),yl([1 1 2 2]),colour,'EdgeColor','none');
end
end

%% =========================================================================
%  Analysis helpers
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
% Gain after dragging from p0 to pt: vertically in dB, or radially on a
% Nyquist plot.
switch mode
    case 'dB'
        k = k0*10^((pt(2) - p0(2))/20);
    case 'radial'
        r0 = hypot(p0(1),p0(2));
        if r0 < eps, k = k0; else, k = k0*hypot(pt(1),pt(2))/r0; end
end
end

function [p,approx] = clPoles(L)
% Closed-loop poles of L in unity feedback (Padé approximation for delays).
approx = hasdelay(L);
if approx
    p = pole(feedback(pade(L,8),1));
else
    p = pole(feedback(L,1));
end
end

function [stable,str] = stabClass(p)
tol = 1e-7;
stable = all(real(p) < -tol);
if stable
    str = 'stable (all poles in the OLHP)';
elseif any(real(p) > tol)
    str = 'UNSTABLE (pole(s) in the RHP)';
else
    str = 'marginally stable (pole(s) on the jw-axis)';
end
end

function str = stabWord(stable)
if stable, str = 'stable'; else, str = 'unstable'; end
end

function [wpc,wgc] = crossovers(mg)
% Phase and gain crossover frequencies from allmargin.
% Only the lowest few are kept, as a delay gives infinitely many.
nMax = 4;
wpc = sort(mg.GMFrequency(isfinite(mg.GMFrequency) & mg.GMFrequency > 0));
wgc = sort(mg.PMFrequency(isfinite(mg.PMFrequency) & mg.PMFrequency > 0));
wpc = wpc(1:min(end,nMax)); wgc = wgc(1:min(end,nMax));
wpc = wpc(:); wgc = wgc(:);
end

function w = freqGrid(L,extraW)
% Log-spaced frequencies spanning the poles, zeros and frequencies of interest.
extraW = extraW(:);
rts = abs([pole(L); zero(L); extraW]);
rts = rts(rts > 1e-6 & isfinite(rts));
if isempty(rts), rts = 1; end
wmin = 10^(floor(log10(min(rts)))-2);
wmax = 10^(ceil(log10(max(rts)))+2);
tau = totaldelay(L);
if tau > 0
    % Delays make the phase wrap endlessly; keep the range near the crossovers
    ex = sort(extraW(extraW > 0));
    wmax = max([min(wmax,10/tau); 1.5*ex(1:min(end,3)); 10*wmin]);
end
w = logspace(log10(wmin),log10(wmax),4000)';
end

function [w,H,magdB,ph] = freqData(L,extraW)
% Frequency response with phase unwrapped to start at its low-frequency value.
w = freqGrid(L,extraW);
H = squeeze(freqresp(L,w));
H = H(:);
magdB = 20*log10(abs(H));
ph = unwrap(angle(H))*180/pi;
[k,Kk] = typeAndGain(L);
ph0 = -90*k - 180*(Kk < 0);
ph = ph - 360*round((ph(1) - ph0)/360);
end

function v = interpLog(w,y,w0)
v = interp1(log10(w),y,log10(w0));
end

function crit = nearestCrit(p)
% Nearest odd multiple of 180 degrees to phase p.
crit = 360*round((p+180)/360) - 180;
end

function cs = critPhases(ph)
% All odd multiples of 180 degrees within the range of ph.
lo = min(ph); hi = max(ph);
cs = 360*ceil((lo+180)/360)-180 : 360 : 360*floor((hi+180)/360)-180;
if isempty(cs), cs = -180; end
end

function [sM,wsM] = stabilityMargin(L,w)
% s_M = min |1 + L(jw)|, refined around the grid minimum.
d = abs(1 + squeeze(freqresp(L,w)));
[~,i] = min(d);
lo = log10(w(max(i-1,1))); hi = log10(w(min(i+1,numel(w))));
f = @(lw) abs(1 + freqresp(L,10^lw));
[lw,sM] = fminbnd(f,lo,hi);
wsM = 10^lw;
end

function maxRe = gainSweep(L,kdB)
% Largest real part of the closed-loop poles of k*L for each gain in dB.
if hasdelay(L), L = pade(L,8); end
[n,d] = tfdata(L,'v');
maxRe = zeros(size(kdB));
for i = 1:numel(kdB)
    maxRe(i) = max(real(roots(d + 10^(kdB(i)/20)*n)));
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

function t = timeVector(Tf,p)
% Simulation time: user value, or ~8 time constants of the slowest pole.
if Tf <= 0
    sig = -real(p);
    if isempty(sig)
        Tf = 10;
    elseif any(sig <= 1e-7)
        Tf = 50;
    else
        Tf = min(max(8/min(sig),1),200);
    end
end
t = linspace(0,Tf,3000)';
end

function r = clipRange(y,bounds,mustInclude)
% Axis limits covering y (clipped to bounds) and the value mustInclude.
y = y(isfinite(y));
lo = max(min([y; mustInclude]),bounds(1));
hi = min(max([y; mustInclude]),bounds(2));
pad = 0.08*max(hi-lo,1);
r = [lo-pad hi+pad];
end

%% =========================================================================
%  Text helpers
%  =========================================================================
function str = fmtNum(x)
if isempty(x) || isnan(x(1)), str = '-'; return, end
x = x(1);
if x == 0, x = 0; end   % avoid printing -0
if isinf(x)
    if x > 0, str = '∞'; else, str = '-∞'; end
else
    str = sprintf('%.4g',x);
end
end

function str = texNum(x)
if isinf(x)
    if x > 0, str = '\infty'; else, str = '-\infty'; end
else
    str = sprintf('%.3g',x);
end
end

function str = cplxStr(z)
if isinf(abs(z)) || isnan(z)
    str = '∞';
else
    str = sprintf('%.4g %+.4gj',real(z),imag(z));
end
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

function out = rangesStr(x,mask)
% Describe the intervals where mask is true.
d = diff([false mask false]);
st = find(d == 1); en = find(d == -1) - 1;
if isempty(st)
    out = {'  none'};
    return
end
out = cell(numel(st),1);
for i = 1:numel(st)
    out{i} = sprintf('  %.3g dB to %.3g dB (k = %.3g to %.3g)', ...
        x(st(i)),x(en(i)),10^(x(st(i))/20),10^(x(en(i))/20));
end
end

function c = padAdd(a,b)
n = max(numel(a),numel(b));
c = [zeros(1,n-numel(a)) a] + [zeros(1,n-numel(b)) b];
end

function str = tfStr(sys)
[n,d] = tfdata(sys,'v');
str = sprintf('(%s) / (%s)',polyStr(n),polyStr(d));
tau = totaldelay(sys);
if tau > 0
    str = sprintf('%s * exp(-%gs)',str,tau);
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

%% =========================================================================
%  UI helpers
%  =========================================================================
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
    'e.g. 1/(s*(1+s)^2) or exp(-5*s)/s.'};
end
