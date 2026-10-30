function Chapter5_PredictionOfSystemResponseApp
%CHAPTER5_PREDICTIONOFSYSTEMRESPONSEAPP Interactive GUI for MEC3079S Chapter 5 — Prediction of system response.
%
%   Run Chapter5_PredictionOfSystemResponseApp to open the app. The tabs follow the chapter:
%     1. Poles & zeros   (5.2): factorised form, relative degree (strictly
%        proper / biproper / improper) and pole-zero cancellation.
%     2. Response        (5.3-5.6): partial fraction expansion of
%        Y(s) = P(s)U(s); each pole contributes one term of y(t), plotted in
%        the same colour as its pole.
%     3. Stability       (5.7): unstable, marginally stable and strictly
%        (BIBO) stable systems, with a bounded test input.
%     4. Initial & final value (5.8): IVT and FVT, and when they apply.
%
%   Interaction: on every tab, drag the poles (x) and zeros (o) of P(s);
%   complex poles/zeros move as conjugate pairs. Use "Add"/"Delete selected"
%   to change their number. The input poles (squares) of a sinusoid (±jω) or
%   exponential (−c) can be dragged too, to change ω or c.
%
%   Transfer functions are entered as MATLAB expressions in s, for example
%   5/(s+s^2/10) or 1/((s+2)^2*(s+5)).
%
%   Requires the Control System Toolbox and the Symbolic Math Toolbox.

cOrange = [0.85 0.33 0.10];
cBlue   = [0.00 0.45 0.74];
cPurple = [0.49 0.18 0.56];
cGreen  = [0.47 0.67 0.19];
cGrey   = [0.55 0.55 0.55];
cSel    = [0.10 0.60 0.10];
addItems = {'Add pole/zero…','Real pole','Complex pole pair','Real zero','Complex zero pair'};

fig = uifigure('Name','MEC3079S Chapter 5 — Prediction of system response', ...
    'Position',[50 40 1340 860]);
mainGrid = uigridlayout(fig,[1 1],'Padding',[0 0 0 0]);
tg = uitabgroup(mainGrid);

% Drag state shared by all interactive plots
drag = struct('active',false,'ax',[],'move',[],'done',[],'p0',[0 0], ...
    'last',[],'xl',[],'yl',[],'t',tic);
fig.WindowButtonMotionFcn = @(~,~) onMotion();
fig.WindowButtonUpFcn = @(~,~) onRelease();

% Pole-zero editors, one per tab (1-3)
pz = struct('ax',{},'ef',{},'dd',{},'upd',{},'roots',{},'K',{},'tau',{}, ...
    'r0',{},'K0',{},'selKind',{},'selVal',{});

%% =====================================================================
%  Tab 1: Poles and zeros
%  =====================================================================
t1 = uitab(tg,'Title','Poles & zeros');
g1 = uigridlayout(t1,[1 2],'ColumnWidth',{340,'1x'});

c1 = uigridlayout(g1,[7 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{96,22,22,22,22,'1x',22});
at(uilabel(c1,'Text',['P(s) = N(s)/D(s) = A_p ∏(s − zᵢ)/∏(s − pᵢ): zeros are the roots of N(s), ' ...
    'poles the roots of D(s). A pole and zero at the same place cancel. Drag the poles (x) and ' ...
    'zeros (o), or add and delete them.'],'FontWeight','bold','WordWrap','on'),1,[1 2]);
presets1 = { ...
    'Ex 5.2.1(1): P = 2/(s(s/5+1))',              '2/(s*(s/5+1))'
    'Ex 5.2.1(2): P = 2(0.5+s)/(s²+2s+1)',        '2*(0.5+s)/(s^2+2*s+1)'
    'Ex 5.2.3(1): P = (s+5)/(s²+10s+25)',         '(s+5)/(s^2+10*s+25)'
    'Ex 5.2.3(2): L = (s+1)/(s+2) · (s+3)/((s+1)(s+5))', '(s+1)/(s+2)*(s+3)/((s+1)*(s+5))'
    'Fig 5.1: P = (a+s)/(b+s), a = 1, b = 4',      '(1+s)/(4+s)'
    'Biproper: F₂ = (1+s)/(2+s)',                  '(1+s)/(2+s)'
    'Improper: (s²+1)/(s+1)',                     '(s^2+1)/(s+1)'
    'Custom', ''};
at(uilabel(c1,'Text','Example'),2,1);
dd1 = at(uidropdown(c1,'Items',presets1(:,1)','Value',presets1{1,1}),2,2);
at(uilabel(c1,'Text','P(s)'),3,1);
ef1 = at(uieditfield(c1,'text','Value',presets1{1,2}),3,2);
[dd1Add,btn1Del] = rootControls(c1,4,addItems);
at(uilabel(c1,'Text','Results','FontWeight','bold'),5,[1 2]);
ta1 = at(uitextarea(c1,'Editable','off','FontName','Monospaced'),6,[1 2]);
btn1 = at(uibutton(c1,'Text','Update'),7,[1 2]);

r1 = uigridlayout(g1,[4 1],'RowHeight',{'fit','fit','fit','1x'});
lbl1a = uilabel(r1,'Text','','Interpreter','latex','FontSize',18);
lbl1b = uilabel(r1,'Text','','Interpreter','latex','FontSize',18);
lbl1c = uilabel(r1,'Text','','FontSize',15,'FontWeight','bold');
ax1 = uiaxes(r1);

dd1.ValueChangedFcn = @(~,~) loadPreset(1);
ef1.ValueChangedFcn = @(~,~) markCustom(dd1,@update1);
btn1.ButtonPushedFcn = @(~,~) update1();
registerEditor(1,ax1,ef1,dd1,@update1,dd1Add,btn1Del);

%% =====================================================================
%  Tab 2: Response (partial fractions)
%  =====================================================================
t2 = uitab(tg,'Title','Response');
g2 = uigridlayout(t2,[1 2],'ColumnWidth',{340,'1x'});

c2 = uigridlayout(g2,[11 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{112,22,22,22,22,22,22,22,22,'1x',22});
at(uilabel(c2,'Text',['Y(s) = P(s)U(s) = Σ rᵢ/(s − pᵢ): each pole of Y(s) adds one term rᵢe^(pᵢt) ' ...
    'to y(t) (t^k e^(pt) for repeated poles; a decaying or growing cosine for a complex pair). ' ...
    'Poles from P(s) give the natural response, poles from U(s) the forced response. ' ...
    'Terms and poles share colours.'],'FontWeight','bold','WordWrap','on'),1,[1 2]);
% name, P(s), input, parameter
presets2 = { ...
    'Ex 5.3.1: P = 5/(s+s²/10), impulse',          '5/(s+s^2/10)',          'Impulse',      1
    'Ex 5.3.2: P = 1/(s³+s²), impulse',            '1/(s^3+s^2)',           'Impulse',      1
    'Ex 5.4.2: P = 1/((s+3)(s+10)), impulse',      '1/((s+3)*(s+10))',      'Impulse',      1
    'Ex 5.4.3: P = 1/((s+2)²(s+5)), impulse',      '1/((s+2)^2*(s+5))',     'Impulse',      1
    'Ex 5.4.4: P = 1/(s²+6s+34), impulse',         '1/(s^2+6*s+34)',        'Impulse',      1
    'Ex 5.5.2: P = 1/(s+2), unit step',            '1/(s+2)',               'Unit step',    1
    'Ex 5.5.4: P = 1/(s²+2s+2), unit step',        '1/(s^2+2*s+2)',         'Unit step',    1
    '5.6: P = 1/(s+1), u = sin(2t)',               '1/(s+1)',               'Sinusoid sin(ωt)', 2
    '5.7.2: P = 1/(s²+16), u = sin(4t)',           '1/(s^2+16)',            'Sinusoid sin(ωt)', 4
    'Custom', '', '', []};
inputs2 = {'Impulse','Unit step','Unit ramp','Sinusoid sin(ωt)','Exponential e^(−ct)','Custom U(s)'};
at(uilabel(c2,'Text','Example'),2,1);
dd2 = at(uidropdown(c2,'Items',presets2(:,1)','Value',presets2{7,1}),2,2);
at(uilabel(c2,'Text','P(s)'),3,1);
ef2 = at(uieditfield(c2,'text','Value',presets2{7,2}),3,2);
at(uilabel(c2,'Text','Input u(t)'),4,1);
dd2In = at(uidropdown(c2,'Items',inputs2,'Value',presets2{7,3}),4,2);
lbl2Par = at(uilabel(c2,'Text','ω (rad/s)'),5,1);
ef2Par = at(uieditfield(c2,'numeric','Value',1),5,2);
lbl2U = at(uilabel(c2,'Text','U(s)'),6,1);
ef2U = at(uieditfield(c2,'text','Value','1/(s+1)^2'),6,2);
at(uilabel(c2,'Text','Final time (0=auto)'),7,1);
ef2T = at(uieditfield(c2,'numeric','Value',0,'Limits',[0 Inf]),7,2);
[dd2Add,btn2Del] = rootControls(c2,8,addItems);
at(uilabel(c2,'Text','Results','FontWeight','bold'),9,1);
ta2 = at(uitextarea(c2,'Editable','off','FontName','Monospaced'),10,[1 2]);
btn2 = at(uibutton(c2,'Text','Update'),11,[1 2]);

r2 = uigridlayout(g2,[4 2],'RowHeight',{'fit','fit','fit','1x'},'ColumnWidth',{'1x','1.5x'});
lbl2Y  = at(uilabel(r2,'Text','','Interpreter','latex','FontSize',17),1,[1 2]);
lbl2PF = at(uilabel(r2,'Text','','Interpreter','latex','FontSize',17),2,[1 2]);
lbl2y  = at(uilabel(r2,'Text','','Interpreter','latex','FontSize',17),3,[1 2]);
ax2 = at(uiaxes(r2),4,1);
ax2y = at(uiaxes(r2),4,2);

dd2.ValueChangedFcn = @(~,~) loadPreset(2);
ef2.ValueChangedFcn = @(~,~) markCustom(dd2,@update2);
[dd2In.ValueChangedFcn, ef2Par.ValueChangedFcn, ef2U.ValueChangedFcn, ef2T.ValueChangedFcn] = deal(@(~,~) update2());
btn2.ButtonPushedFcn = @(~,~) update2();
registerEditor(2,ax2,ef2,dd2,@update2,dd2Add,btn2Del);

%% =====================================================================
%  Tab 3: Stability
%  =====================================================================
t3 = uitab(tg,'Title','Stability');
g3 = uigridlayout(t3,[1 2],'ColumnWidth',{340,'1x'});

c3 = uigridlayout(g3,[9 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{112,22,22,22,22,22,22,'1x',22});
at(uilabel(c3,'Text',['Strictly (BIBO) stable: all poles in the OLHP. Marginally stable: distinct ' ...
    'poles on the imaginary axis (an input with a matching pole gives an unbounded output). ' ...
    'Unstable: any pole in the ORHP, or repeated poles on the imaginary axis. Drag the poles across the ' ...
    'regions.'],'FontWeight','bold','WordWrap','on'),1,[1 2]);
presets3 = { ...
    'Ex 5.7.1: P = (s+5)/(s³+s²−s+1)',            '(s+5)/(s^3+s^2-s+1)',       'Unit step',  1
    'Ex 5.7.3: P = (s+5)²/(s³+2s²+5s+1)',         '(s+5)^2/(s^3+2*s^2+5*s+1)', 'Unit step',  1
    '5.7.2: P = 1/s with a step',                 '1/s',                       'Unit step',  1
    '5.7.2: P = 1/(s²+16) with sin(4t)',          '1/(s^2+16)',                'Sinusoid sin(ωt)', 4
    'Repeated poles on the jω-axis: 1/(s²+16)²',  '1/(s^2+16)^2',              'Impulse',    4
    'Custom', '', '', []};
at(uilabel(c3,'Text','Example'),2,1);
dd3 = at(uidropdown(c3,'Items',presets3(:,1)','Value',presets3{1,1}),2,2);
at(uilabel(c3,'Text','P(s)'),3,1);
ef3 = at(uieditfield(c3,'text','Value',presets3{1,2}),3,2);
at(uilabel(c3,'Text','Bounded input'),4,1);
dd3In = at(uidropdown(c3,'Items',{'Impulse','Unit step','Sinusoid sin(ωt)'},'Value','Unit step'),4,2);
lbl3w = at(uilabel(c3,'Text','ω (rad/s)'),5,1);
ef3w = at(uieditfield(c3,'numeric','Value',4,'Limits',[0 Inf]),5,2);
[dd3Add,btn3Del] = rootControls(c3,6,addItems);
ta3 = at(uitextarea(c3,'Editable','off','FontName','Monospaced'),8,[1 2]);
btn3 = at(uibutton(c3,'Text','Update'),9,[1 2]);

r3 = uigridlayout(g3,[2 2],'RowHeight',{'fit','1x'},'ColumnWidth',{'1x','1.3x'});
lbl3 = at(uilabel(r3,'Text','','FontSize',22,'FontWeight','bold','HorizontalAlignment','center'),1,[1 2]);
ax3 = at(uiaxes(r3),2,1);
ax3y = at(uiaxes(r3),2,2);

dd3.ValueChangedFcn = @(~,~) loadPreset(3);
ef3.ValueChangedFcn = @(~,~) markCustom(dd3,@update3);
[dd3In.ValueChangedFcn, ef3w.ValueChangedFcn] = deal(@(~,~) update3());
btn3.ButtonPushedFcn = @(~,~) update3();
registerEditor(3,ax3,ef3,dd3,@update3,dd3Add,btn3Del);

%% =====================================================================
%  Tab 4: Initial and final value theorems
%  =====================================================================
t4 = uitab(tg,'Title','Initial & final value');
g4 = uigridlayout(t4,[1 2],'ColumnWidth',{340,'1x'});

c4 = uigridlayout(g4,[9 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{112,22,22,22,22,22,22,'1x',22});
at(uilabel(c4,'Text',['IVT: y(0) = lim_{s→∞} sY(s), valid when Y(s) is strictly proper. ' ...
    'FVT: y(∞) = lim_{s→0} sY(s), valid only when y(t) settles, i.e. all poles of sY(s) are in the ' ...
    'OLHP. Otherwise the limit can still be computed, but it is meaningless.'],'FontWeight','bold','WordWrap','on'),1,[1 2]);
presets4 = { ...
    'Ex 5.8: Y(s) = −10/(s+5) (impulse into a/(s+b))', '-10/(s+5)',     'Impulse',  1
    'Unit step into 1/(s²+2s+2)',                       '1/(s^2+2*s+2)', 'Unit step', 1
    'Unit step into (s+4)/(s+2)',                       '(s+4)/(s+2)',   'Unit step', 1
    'FVT invalid: unit step into 1/s (ramp)',           '1/s',           'Unit step', 1
    'FVT invalid: unit step into 1/(s−1)',              '1/(s-1)',       'Unit step', 1
    'FVT invalid: sin(2t) into 1/(s+1)',                '1/(s+1)',       'Sinusoid sin(ωt)', 2
    'Custom', '', '', []};
at(uilabel(c4,'Text','Example'),2,1);
dd4 = at(uidropdown(c4,'Items',presets4(:,1)','Value',presets4{1,1}),2,2);
at(uilabel(c4,'Text','P(s)'),3,1);
ef4 = at(uieditfield(c4,'text','Value',presets4{1,2}),3,2);
at(uilabel(c4,'Text','Input u(t)'),4,1);
dd4In = at(uidropdown(c4,'Items',{'Impulse','Unit step','Unit ramp','Sinusoid sin(ωt)'}),4,2);
lbl4w = at(uilabel(c4,'Text','ω (rad/s)'),5,1);
ef4w = at(uieditfield(c4,'numeric','Value',2,'Limits',[0 Inf]),5,2);
at(uilabel(c4,'Text','Final time (0=auto)'),6,1);
ef4T = at(uieditfield(c4,'numeric','Value',0,'Limits',[0 Inf]),6,2);
[dd4Add,btn4Del] = rootControls(c4,7,addItems);
ta4 = at(uitextarea(c4,'Editable','off','FontName','Monospaced'),8,[1 2]);
btn4 = at(uibutton(c4,'Text','Update'),9,[1 2]);

r4 = uigridlayout(g4,[4 2],'RowHeight',{'fit','fit','fit','1x'},'ColumnWidth',{'1x','1.5x'});
lbl4Y = at(uilabel(r4,'Text','','Interpreter','latex','FontSize',18),1,[1 2]);
lbl4I = at(uilabel(r4,'Text','','Interpreter','latex','FontSize',18),2,[1 2]);
lbl4F = at(uilabel(r4,'Text','','Interpreter','latex','FontSize',18),3,[1 2]);
ax4p = at(uiaxes(r4),4,1);
ax4 = at(uiaxes(r4),4,2);

dd4.ValueChangedFcn = @(~,~) loadPreset(4);
ef4.ValueChangedFcn = @(~,~) markCustom(dd4,@update4);
[dd4In.ValueChangedFcn, ef4w.ValueChangedFcn, ef4T.ValueChangedFcn] = deal(@(~,~) update4());
btn4.ButtonPushedFcn = @(~,~) update4();
registerEditor(4,ax4p,ef4,dd4,@update4,dd4Add,btn4Del);

% Initial draw
update1(); loadPreset(2); update3(); loadPreset(4);

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
        % Hold the dragged axes still so the poles follow the mouse
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
%  Pole-zero editors
%  =====================================================================
    function registerEditor(i,ax,ef,dd,updFcn,addDD,delBtn)
        pz(i).ax = ax;
        pz(i).ef = ef;
        pz(i).dd = dd;
        pz(i).upd = updFcn;
        pz(i).selKind = '';
        pz(i).selVal = [];
        ax.Interactions = [];
        addDD.ValueChangedFcn = @(src,~) addRoot(i,src);
        delBtn.ButtonPushedFcn = @(~,~) deleteRoot(i);
    end

    function drawRoots(i,sys,opts)
        % Draggable poles/zeros of sys. opts.colour(v) gives the colour of a
        % root, opts.extra(ax) draws additional items, opts.regions shades
        % the stability regions.
        ax = pz(i).ax;
        [z,p,K] = zpkdata(zpk(sys),'v');
        rl = rootList(z,p);
        pz(i).roots = rl;  pz(i).K = K;  pz(i).tau = totaldelay(sys);
        if drag.active && isequal(drag.ax,ax)
            xl = drag.xl; yl = drag.yl;
        else
            vals = [z; p; getfieldDefault(opts,'more',[]); 0];
            R = max(1,1.3*max(abs(vals(isfinite(vals)))));
            xl = [-R R]; yl = [-R R];
        end
        cla(ax); hold(ax,'on');
        if getfieldDefault(opts,'regions',false)
            patch(ax,[xl(1) 0 0 xl(1)],yl([1 1 2 2]),[0.88 0.96 0.88],'EdgeColor','none','HitTest','off');
            patch(ax,[0 xl(2) xl(2) 0],yl([1 1 2 2]),[1 0.88 0.88],'EdgeColor','none','HitTest','off');
            plot(ax,[0 0],yl,'-','Color',[0.95 0.6 0.1],'LineWidth',4,'HitTest','off');
            text(ax,xl(1)*0.95,yl(2)*0.9,'OLHP: stable','FontWeight','bold','Color',[0.1 0.45 0.1],'HitTest','off');
            text(ax,xl(2)*0.95,yl(2)*0.9,'ORHP: unstable','FontWeight','bold','Color',[0.6 0 0], ...
                'HorizontalAlignment','right','HitTest','off');
        else
            patch(ax,[0 xl(2) xl(2) 0],yl([1 1 2 2]),[1 0.93 0.93],'EdgeColor','none','HitTest','off');
        end
        xline(ax,0,'k','HitTest','off');
        yline(ax,0,'k','HitTest','off');
        if isfield(opts,'extra'), opts.extra(ax); end
        sel = selectedIndex(i);
        for j = 1:numel(rl)
            v = rl(j).val;
            if rl(j).pair, xs = [real(v) real(v)]; ys = [imag(v) -imag(v)];
            else, xs = real(v); ys = 0; end
            if rl(j).kind == 'p', mk = 'x'; ms = 15; else, mk = 'o'; ms = 11; end
            if isfield(opts,'colour') && rl(j).kind == 'p', col = opts.colour(v); else, col = cOrange; end
            if rl(j).kind == 'z', col = cBlue; end
            lw = 3;
            if j == sel, lw = 4.5; plot(ax,xs,ys,'o','MarkerSize',22,'Color',cSel,'LineWidth',1.5,'HitTest','off'); end
            plot(ax,xs,ys,mk,'Color',col,'MarkerSize',ms,'LineWidth',lw,'ButtonDownFcn',@(~,~) rootDown(i,j));
        end
        hold(ax,'off'); grid(ax,'on');
        ax.DataAspectRatio = [1 1 1];
        xlim(ax,xl); ylim(ax,yl);
        xlabel(ax,'Real axis'); ylabel(ax,'Imaginary axis');
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
            if abs(pt(1)) < tol, v = complex(0,imag(v)); end      % snap onto the jw-axis
        else
            % Real roots slide along the real axis and snap onto the origin
            v = pt(1);
            if abs(v) < tol, v = 0; end
        end
        rl(j).val = v;
        pz(i).selVal = v;
        setLoop(i,rl,pz(i).K0);            % A_p is kept fixed
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
        pz(i).selKind = new.kind;
        pz(i).selVal = new.val;
        setLoop(i,rl,pz(i).K);
    end

    function deleteRoot(i)
        j = selectedIndex(i);
        if j == 0
            uialert(fig,'Click a pole or zero first to select it.','Nothing selected');
            return
        end
        rl = pz(i).roots;
        rl(j) = [];
        if isempty(rl) || ~any([rl.kind] == 'p')
            uialert(fig,'Keep at least one pole.','Not allowed');
            return
        end
        pz(i).selKind = '';
        pz(i).selVal = [];
        setLoop(i,rl,pz(i).K);
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
%  Presets
%  =====================================================================
    function loadPreset(i)
        switch i
            case 1
                k = find(strcmp(presets1(:,1),dd1.Value));
                if isempty(presets1{k,2}), return, end
                ef1.Value = presets1{k,2};
                update1();
            case 2
                k = find(strcmp(presets2(:,1),dd2.Value));
                if isempty(presets2{k,2}), return, end
                ef2.Value = presets2{k,2};  dd2In.Value = presets2{k,3};  ef2Par.Value = presets2{k,4};
                update2();
            case 3
                k = find(strcmp(presets3(:,1),dd3.Value));
                if isempty(presets3{k,2}), return, end
                ef3.Value = presets3{k,2};  dd3In.Value = presets3{k,3};  ef3w.Value = presets3{k,4};
                update3();
            case 4
                k = find(strcmp(presets4(:,1),dd4.Value));
                if isempty(presets4{k,2}), return, end
                ef4.Value = presets4{k,2};  dd4In.Value = presets4{k,3};  ef4w.Value = presets4{k,4};
                update4();
        end
        if i <= numel(pz), pz(i).selKind = ''; end
    end

%% =====================================================================
%  Tab 1 callbacks
%  =====================================================================
    function update1()
        try
            P = parseTF(ef1.Value);                  % as entered (no cancellation)
            Pm = minreal(P,1e-6);                    % after pole-zero cancellation
            [z,p,K] = zpkdata(P,'v');
            [zm,pm] = zpkdata(Pm,'v');
            canc = cancelled(z,p);
            drawRoots(1,P,struct('extra',@(ax) markCancelled(ax,canc)));
            title(ax1,'s-plane: poles (x), zeros (o), cancelled pairs (grey ring)');

            [n,d] = tfdata(P,'v');
            lbl1a.Text = sprintf('$P(s)=\\frac{%s}{%s}=%s$',polyTex(n),polyTex(d),zpkTex(K,z,p));
            if ~isempty(canc)
                lbl1b.Text = sprintf('$\\mathrm{after\\ cancellation:}\\quad P(s)=%s$',zpkTex(K,zm,pm));
            else
                lbl1b.Text = '';
            end
            nn = numel(pm);  mm = numel(zm);
            if mm < nn
                cls = sprintf('Strictly proper: relative degree n − m = %d − %d = %d > 0',nn,mm,nn-mm);
            elseif mm == nn
                cls = sprintf('Biproper: relative degree n − m = %d − %d = 0 (also proper)',nn,mm);
            else
                cls = sprintf('Improper: relative degree n − m = %d − %d < 0 (not causal)',nn,mm);
            end
            lbl1c.Text = cls;

            txt = {sprintf('A_p = %.4g',K); ''; 'Zeros (roots of N(s) = 0):'};
            txt = [txt; rootsStr(z); {'Poles (roots of D(s) = 0):'}; rootsStr(p)];
            if ~isempty(canc)
                txt = [txt; {''; 'Cancelled pole-zero pairs:'}; rootsStr(canc)];
                txt{end+1} = 'minreal(P) removes them.';
            end
            txt = [txt; {''; sprintf('n = %d poles, m = %d zeros (after cancellation)',nn,mm)}];
            ta1.Value = flatLines(txt);
        catch err
            showError(ta1,err);
        end
    end

    function markCancelled(ax,canc)
        for k = 1:numel(canc)
            plot(ax,real(canc(k)),imag(canc(k)),'o','MarkerSize',26,'Color',cGrey,'LineWidth',2.5,'HitTest','off');
        end
    end

%% =====================================================================
%  Tab 2 callbacks
%  =====================================================================
    function update2()
        try
            P = minreal(parseTF(ef2.Value),1e-6);
            [U,uTex,uName] = inputTF(dd2In.Value,ef2Par.Value,ef2U.Value);
            set([lbl2Par ef2Par],'Visible',onoff(any(strcmp(dd2In.Value,{'Sinusoid sin(ωt)','Exponential e^(−ct)'}))));
            if strcmp(dd2In.Value,'Exponential e^(−ct)'), lbl2Par.Text = 'c'; else, lbl2Par.Text = 'ω (rad/s)'; end
            set([lbl2U ef2U],'Visible',onoff(strcmp(dd2In.Value,'Custom U(s)')));

            Y = minreal(P*U,1e-6);
            [nY,dY] = tfdata(Y,'v');
            [r,pl,kk] = residue(nY,dY);
            terms = pfTerms(r,pl);
            pP = pole(P);  pU = pole(U);
            cols = lines(max(numel(terms),1));
            colourOf = @(v) termColour(v,terms,cols);

            % s-plane: plant poles draggable; input poles as squares
            drawRoots(2,P,struct('colour',colourOf,'more',pU, ...
                'extra',@(ax) drawInputPoles(ax,pU,colourOf,dd2In.Value,ef2Par,@update2)));
            title(ax2,'Poles of P(s) (x, drag) and of U(s) (squares)');

            % Time responses
            tEnd = ef2T.Value;
            if tEnd <= 0, tEnd = autoTime(pl); end
            t = linspace(0,tEnd,2000)';
            cla(ax2y); hold(ax2y,'on');
            ysum = zeros(size(t));
            leg = {};
            for k = 1:numel(terms)
                yk = terms(k).f(t);
                ysum = ysum + yk;
                plot(ax2y,t,yk,'-','Color',cols(k,:),'LineWidth',1.5);
                leg{end+1} = sprintf('%s (%s)',terms(k).name,terms(k).src(pP,pU)); %#ok<AGROW>
            end
            plot(ax2y,t,ysum,'k','LineWidth',2.8);
            leg{end+1} = 'y(t) = sum of terms';
            ok = true;  err = 0;
            if isempty(kk) || all(kk == 0)
                ychk = impulse(Y,t);
                plot(ax2y,t,ychk,'--','Color',[0.9 0 0],'LineWidth',1.5);
                leg{end+1} = 'simulated (impulse of Y)';
                err = max(abs(ychk - ysum))/max([max(abs(ychk)) 1e-9]);
                ok = err < 1e-4;
            end
            hold(ax2y,'off'); grid(ax2y,'on');
            legend(ax2y,leg,'Location','best','Interpreter','tex');
            title(ax2y,sprintf('y(t) for %s, built from its partial-fraction terms',uName)); xlabel(ax2y,'Time (s)');

            [nP,dP] = tfdata(P,'v');
            lbl2Y.Text = sprintf('$Y(s)=P(s)U(s)=\\frac{%s}{%s}\\cdot %s$',polyTex(nP),polyTex(dP),uTex);
            lbl2PF.Text = ['$Y(s)=' pfTex(terms,kk) '$'];
            lbl2y.Text = ['$y(t)=' timeTex(terms,kk) '$'];

            txt = {'Residues r_i and poles p_i of Y(s):'};
            for k = 1:numel(terms)
                txt{end+1,1} = sprintf('  %s:  r = %s',terms(k).name,cplx(terms(k).r)); %#ok<AGROW>
            end
            if ~isempty(kk) && any(kk ~= 0)
                txt{end+1,1} = sprintf('  direct term k = %.4g (impulse k*delta(t))',kk(1));
            end
            txt = [txt; {''; sprintf('Sum of terms vs simulation: %s (max rel. error %.1e)',mark(ok),err); ''}];
            txt = [txt; behaviourLines(pl,pP,pU)];
            ta2.Value = flatLines(txt);
        catch err
            showError(ta2,err);
        end
    end

    function drawInputPoles(ax,pU,colourOf,kind,efPar,updFcn)
        % Input poles as squares; for a sinusoid (±jω) or an exponential (−c) they can be
        % dragged along the jω-axis or the real axis to change ω or c.
        for k = 1:numel(pU)
            h = plot(ax,real(pU(k)),imag(pU(k)),'s','MarkerSize',14,'LineWidth',2.5, ...
                'Color',colourOf(pU(k)),'HitTest','off');
            switch kind
                case 'Sinusoid sin(ωt)'
                    set(h,'HitTest','on','ButtonDownFcn',@(~,~) startDrag(ax, ...
                        @(pt,~) setPar(efPar,max(abs(pt(2)),1e-3),updFcn),updFcn));
                case 'Exponential e^(−ct)'
                    set(h,'HitTest','on','ButtonDownFcn',@(~,~) startDrag(ax, ...
                        @(pt,~) setPar(efPar,-pt(1),updFcn),updFcn));
            end
        end
    end

    function setPar(ef,v,updFcn)
        ef.Value = v;
        updFcn();
    end

%% =====================================================================
%  Tab 3 callbacks
%  =====================================================================
    function update3()
        try
            P = minreal(parseTF(ef3.Value),1e-6);
            set([lbl3w ef3w],'Visible',onoff(strcmp(dd3In.Value,'Sinusoid sin(ωt)')));
            p = pole(P);
            [cls,why,col] = stabilityClass(p);
            lbl3.Text = cls;  lbl3.FontColor = col;
            [U,~,uName] = inputTF(dd3In.Value,ef3w.Value,'1');
            pU = pole(U);
            drawRoots(3,P,struct('regions',true,'more',pU, ...
                'extra',@(ax) drawInputPoles(ax,pU,@(~) [0.47 0.67 0.19],dd3In.Value,ef3w,@update3)));
            title(ax3,'s-plane (Fig 5.8): drag the poles (x) and input poles (squares)');

            Y = minreal(P*U,1e-6);
            pY = pole(Y);
            tEnd = autoTime(pY);
            t = linspace(0,tEnd,3000)';
            y = impulse(Y,t);
            cla(ax3y);
            plot(ax3y,t,y,'Color',cBlue,'LineWidth',2);
            grid(ax3y,'on');
            bounded = all(real(pY) < -1e-6 | (abs(real(pY)) <= 1e-6 & ~isRepeated(pY)));
            if bounded, bt = 'bounded'; else, bt = 'unbounded'; end
            title(ax3y,sprintf('Response to %s: %s',uName,bt)); xlabel(ax3y,'Time (s)');

            txt = [{'Poles of P(s):'}; rootsStr(p); {''; why}];
            txt = [txt; {''; sprintf('With %s, the poles of Y(s) = P(s)U(s)',uName)}];
            txt = [txt; {sprintf('are:')}; rootsStr(pY)];
            if bounded
                txt{end+1} = '=> y(t) stays bounded for this input.';
            else
                txt{end+1} = '=> y(t) grows without bound for this input.';
            end
            if contains(cls,'MARGINALLY')
                wAxis = abs(imag(p(abs(real(p)) < 1e-6)));
                txt = [txt; {''; 'Marginal: an input with a pole that matches a'; ...
                    'pole on the jw-axis makes the output unbounded,'; ...
                    sprintf('e.g. a step (w = 0) or sin(wt) with w = %s.',strjoin(arrayfun(@(v) sprintf('%.3g',v),unique(round(wAxis,6))','UniformOutput',false),', '))}];
            end
            ta3.Value = flatLines(txt);
        catch err
            showError(ta3,err);
        end
    end

%% =====================================================================
%  Tab 4 callbacks
%  =====================================================================
    function update4()
        try
            P = minreal(parseTF(ef4.Value),1e-6);
            set([lbl4w ef4w],'Visible',onoff(strcmp(dd4In.Value,'Sinusoid sin(ωt)')));
            [U,uTex,uName] = inputTF(dd4In.Value,ef4w.Value,'1');
            pU = pole(U);
            drawRoots(4,P,struct('regions',true,'more',pU, ...
                'extra',@(ax) drawInputPoles(ax,pU,@(~) [0.47 0.67 0.19],dd4In.Value,ef4w,@update4)));
            title(ax4p,'Poles of P(s) (x, drag) and of U(s) (squares)');
            Y = minreal(P*U,1e-6);
            s = sym('s');
            [nY,dY] = tfdata(Y,'v');
            Ys = poly2sym(nY,s)/poly2sym(dY,s);
            y0 = limit(s*Ys,s,inf);
            yinf = limit(s*Ys,s,0,'right');
            sY = minreal(tf('s')*Y,1e-6);
            psY = pole(sY);
            fvtOK = all(real(psY) < -1e-9);
            ivtOK = numel(nY(find(nY,1):end)) < numel(dY(find(dY,1):end));

            [nP,dP] = tfdata(P,'v');
            lbl4Y.Text = sprintf('$Y(s)=P(s)U(s)=\\frac{%s}{%s}\\cdot %s=\\frac{%s}{%s}$', ...
                polyTex(nP),polyTex(dP),uTex,polyTex(nY),polyTex(dY));
            lbl4I.Text = sprintf('$\\mathrm{IVT:}\\ y(0)=\\lim_{s\\to\\infty}sY(s)=%s\\quad %s$',latex(y0),tick(ivtOK));
            lbl4F.Text = sprintf('$\\mathrm{FVT:}\\ y(\\infty)=\\lim_{s\\to 0}sY(s)=%s\\quad %s$',latex(yinf),tick(fvtOK));
            lbl4I.FontColor = okColour(ivtOK);  lbl4F.FontColor = okColour(fvtOK);

            tEnd = ef4T.Value;
            if tEnd <= 0, tEnd = autoTime(pole(Y)); end
            t = linspace(0,tEnd,2000)';
            y = impulse(Y,t);
            cla(ax4); hold(ax4,'on');
            plot(ax4,t,y,'Color',cBlue,'LineWidth',2);
            y0d = double(y0);  yinfd = double(yinf);
            if isfinite(y0d) && ivtOK
                plot(ax4,0,y0d,'o','MarkerSize',10,'MarkerFaceColor',cOrange,'MarkerEdgeColor','k');
                text(ax4,0,y0d,sprintf('  y(0) = %.4g (IVT)',y0d),'Color',cOrange,'FontSize',13,'VerticalAlignment','bottom');
            end
            if isfinite(yinfd)
                if fvtOK, ls = '--'; lc = cGreen; lab = sprintf('y(\\infty) = %.4g (FVT)',yinfd);
                else, ls = ':'; lc = [0.8 0 0]; lab = sprintf('FVT gives %.4g, but it does not apply',yinfd); end
                yline(ax4,yinfd,ls,lab,'Color',lc,'LineWidth',2,'FontSize',12,'LabelHorizontalAlignment','right');
            end
            hold(ax4,'off'); grid(ax4,'on');
            title(ax4,sprintf('y(t) for %s',uName)); xlabel(ax4,'Time (s)');

            txt = {['sY(s) poles:']};
            txt = [txt; rootsStr(psY)];
            if fvtOK
                txt{end+1} = '=> all in the OLHP: y(t) settles, FVT applies.';
            else
                txt{end+1} = '=> not all in the OLHP: y(t) does not settle';
                txt{end+1} = '   to a constant, so the FVT result is invalid.';
            end
            txt{end+1} = '';
            if ivtOK
                txt{end+1} = 'Y(s) strictly proper: IVT applies.';
            else
                txt{end+1} = 'Y(s) not strictly proper: y(t) has an impulse';
                txt{end+1} = 'at t = 0 and the IVT limit is infinite.';
            end
            ta4.Value = flatLines(txt);
        catch err
            showError(ta4,err);
        end
    end

    function c = okColour(ok)
        if ok, c = [0 0 0]; else, c = [0.75 0 0]; end
    end
end

%% =========================================================================
%  Partial fractions and responses
%  =========================================================================
function terms = pfTerms(r,p)
% Group residue() output into terms: r/(s-p)^j for real poles, and combined
% conjugate pairs (shown once, for Im{p} > 0).
terms = struct('p',{},'r',{},'j',{},'pair',{},'f',{},'name',{},'src',{});
n = numel(p);
for k = 1:n
    % multiplicity index: residue() lists repeated poles with increasing powers
    j = 1;
    for q = k-1:-1:1
        if abs(p(q) - p(k)) < 1e-6*max(1,abs(p(k))), j = j + 1; else, break, end
    end
    pk = cleanNum(p(k),1e-6);  rk = cleanNum(r(k),1e-9);
    if abs(imag(pk)) > 0
        if imag(pk) < 0, continue, end
        f = @(t) real(2*rk*t.^(j-1)/factorial(j-1).*exp(pk*t));
        name = sprintf('pair %s',cplx(pk));
        if j > 1, name = sprintf('%s (power %d)',name,j); end
        pair = true;
    else
        pk = real(pk);  rk = real(rk);
        f = @(t) rk*t.^(j-1)/factorial(j-1).*exp(pk*t);
        if j > 1, name = sprintf('p = %.3g (power %d)',pk,j); else, name = sprintf('p = %.3g',pk); end
        pair = false;
    end
    terms(end+1) = struct('p',pk,'r',rk,'j',j,'pair',pair,'f',f,'name',name, ...
        'src',@(pP,pU) poleSource(pk,pP,pU)); %#ok<AGROW>
end
end

function s = poleSource(p,pP,pU)
inP = any(abs(pP - p) < 1e-5*max(1,abs(p)));
inU = any(abs(pU - p) < 1e-5*max(1,abs(p)));
if inP && inU, s = 'P and U';
elseif inP, s = 'natural, from P';
elseif inU, s = 'forced, from U';
else, s = '';
end
end

function c = termColour(v,terms,cols)
% Colour of the term whose pole is nearest to v (conjugates share a colour).
if isempty(terms), c = [0.85 0.33 0.10]; return, end
d = arrayfun(@(T) min(abs(T.p - v),abs(conj(T.p) - v)) + 1e3*(T.j > 1),terms);
[~,k] = min(d);
c = cols(k,:);
end

function s = pfTex(terms,kk)
parts = {};
for k = 1:numel(terms)
    T = terms(k);
    if T.j > 1, den = sprintf('(s%s)^{%d}',signedNum(-T.p),T.j); else, den = sprintf('s%s',signedNum(-T.p)); end
    if T.pair
        if T.j > 1, pw = sprintf('^{%d}',T.j); else, pw = ''; end
        parts{end+1} = sprintf('\\frac{%s}{(s%s)%s}+\\frac{%s}{(s%s)%s}',cplxTex(T.r),cplxSigned(-T.p),pw, ...
            cplxTex(conj(T.r)),cplxSigned(-conj(T.p)),pw); %#ok<AGROW>
    else
        if abs(T.p) < 1e-12
            if T.j > 1, den = sprintf('s^{%d}',T.j); else, den = 's'; end
        end
        parts{end+1} = sprintf('\\frac{%s}{%s}',num(T.r),den); %#ok<AGROW>
    end
end
if ~isempty(kk) && any(kk ~= 0), parts{end+1} = num(kk(1)); end
s = strjoin(parts,'+');
s = strrep(s,'+-','-');
end

function s = timeTex(terms,kk)
parts = {};
for k = 1:numel(terms)
    T = terms(k);
    if T.j > 1
        tp = sprintf('\\frac{t^{%d}}{%d}',T.j-1,factorial(T.j-1));
        if T.j == 2, tp = 't'; end
    else
        tp = '';
    end
    if T.pair
        a = real(T.p);  b = imag(T.p);
        amp = 2*abs(T.r);  ph = angle(T.r);
        e = '';
        if abs(a) > 1e-12, e = sprintf('e^{%st}',coefTex(a)); end
        parts{end+1} = sprintf('%s%s%s\\cos(%st%s)',coefTex(amp),tp,e,coefTex(b),signedNum(ph)); %#ok<AGROW>
    else
        e = '';
        if abs(T.p) > 1e-12, e = sprintf('e^{%st}',coefTex(T.p)); end
        if isempty(tp) && isempty(e), parts{end+1} = num(T.r);
        else, parts{end+1} = [coefTex(T.r) tp e]; end %#ok<AGROW>
    end
end
if ~isempty(kk) && any(kk ~= 0), parts{end+1} = [num(kk(1)) '\delta(t)']; end
if isempty(parts), parts = {'0'}; end
s = strjoin(parts,'+');
s = strrep(s,'+-','-');
end

function L = behaviourLines(pl,pP,pU)
% How each pole shapes y(t) (Sections 5.4-5.6).
L = {};
a = real(pl);
if all(a < -1e-9)
    L{end+1} = 'All poles of Y(s) in the OLHP: every term decays.';
elseif any(a > 1e-9)
    L{end+1} = 'A pole of Y(s) in the ORHP: its term grows without bound.';
else
    L{end+1} = 'Pole(s) on the imaginary axis: constant, ramp or';
    L{end+1} = 'sustained oscillation terms (repeated ones grow).';
end
if any(abs(imag(pl)) > 1e-9)
    L{end+1} = 'Complex pairs: Im{p} sets the oscillation frequency,';
    L{end+1} = 'Re{p} the exponential envelope.';
end
if ~isempty(pU) && any(real(pU) > 1e-9)
    L{end+1} = 'The input itself has an ORHP pole, so y(t) diverges';
    L{end+1} = 'regardless of P(s).';
end
if ~isempty(pP) && isRepeated(pl) && ~isRepeated(pP)
    L{end+1} = 'A pole of U(s) matches a pole of P(s): repeated pole.';
end
L = L(:);
end

function [cls,why,col] = stabilityClass(p)
tol = 1e-6;
onAxis = abs(real(p)) <= tol;
if any(real(p) > tol)
    cls = 'UNSTABLE';  why = 'At least one pole is in the ORHP.';  col = [0.75 0 0];
elseif any(onAxis) && isRepeated(p(onAxis))
    cls = 'UNSTABLE';  why = 'Repeated poles on the imaginary axis.';  col = [0.75 0 0];
elseif any(onAxis)
    cls = 'MARGINALLY STABLE';  why = 'Distinct pole(s) on the imaginary axis, none in the ORHP.';
    col = [0.85 0.45 0];
else
    cls = 'STRICTLY (BIBO) STABLE';  why = 'All poles are in the OLHP.';  col = [0.1 0.5 0.1];
end
end

function tf_ = isRepeated(p)
tf_ = false;
for k = 1:numel(p)
    if sum(abs(p - p(k)) < 1e-5*max(1,abs(p(k)))) > 1, tf_ = true; return, end
end
end

function [U,tex,name] = inputTF(kind,par,custom)
s = tf('s');
switch kind
    case 'Impulse',             U = tf(1);               tex = '1';  name = 'u(t) = \delta(t)';
    case 'Unit step',           U = 1/s;                 tex = '\frac{1}{s}';  name = 'a unit step';
    case 'Unit ramp',           U = 1/s^2;               tex = '\frac{1}{s^2}';  name = 'a unit ramp';
    case 'Sinusoid sin(ωt)',    U = par/(s^2 + par^2);   tex = sprintf('\\frac{%s}{s^2+%s}',num(par),num(par^2));
                                name = sprintf('u(t) = sin(%gt)',par);
    case 'Exponential e^(−ct)', U = 1/(s + par);         tex = sprintf('\\frac{1}{s%s}',signedNum(par));
                                name = sprintf('u(t) = e^{-%gt}',par);
    case 'Custom U(s)',         U = parseTF(custom);     tex = ['(' custom ')'];  name = 'the custom input';
end
end

function T = autoTime(p)
a = real(p);
if isempty(a), T = 5; return, end
if any(a > 1e-9)
    T = min(max(5/max(a),1),30);
elseif any(abs(a) <= 1e-9)
    T = 15;
else
    T = min(max(7/min(-a),1),200);
end
w = abs(imag(p));
if any(w > 0), T = max(T, min(4*2*pi/max(w),T*3)); end
end

function z = cancelled(zz,pp)
% Zeros that coincide with poles (cancelled pairs).
z = [];
pp = pp(:);
for k = 1:numel(zz)
    d = abs(pp - zz(k));
    [m,j] = min(d);
    if ~isempty(m) && m < 1e-5*max(1,abs(zz(k)))
        z(end+1,1) = zz(k); %#ok<AGROW>
        pp(j) = Inf;
    end
end
end

%% =========================================================================
%  Text and LaTeX helpers
%  =========================================================================
function s = num(x)
s = sprintf('%.4g',x);
if strcmp(s,'-0'), s = '0'; end
end

function v = cleanNum(v,tol)
% Remove round-off: real or imaginary parts that are negligible relative to |v|.
m = max(abs(v),1e-300);
re = real(v);  im = imag(v);
if abs(re) < tol*max(m,1), re = 0; end
if abs(im) < tol*max(m,1), im = 0; end
v = complex(re,im);
if im == 0, v = re; end
end

function s = coefTex(x)
% Coefficient in front of a symbol: 1 and -1 are written as '' and '-'.
if abs(x - 1) < 1e-12, s = ''; elseif abs(x + 1) < 1e-12, s = '-'; else, s = num(x); end
end

function s = signedNum(x)
if x >= 0, s = ['+' num(x)]; else, s = num(x); end
end

function s = cplx(z)
z = cleanNum(z,1e-6);
if imag(z) == 0, s = num(real(z));
else, s = sprintf('%.4g%+.4gj',real(z),imag(z)); end
end

function s = cplxTex(z)
z = cleanNum(z,1e-6);
if imag(z) == 0, s = num(real(z));
else, s = sprintf('(%s%sj)',num(real(z)),signedNum(imag(z))); end
end

function s = cplxSigned(z)
s = ['+' cplxTex(z)];
end

function s = tick(ok)
if ok, s = '\mathrm{(applies)}'; else, s = '\mathrm{(does\ not\ apply)}'; end
end

function s = zpkTex(K,z,p)
% A_p prod(s - z)/prod(s - p) with conjugate pairs written out.
if abs(K - 1) < 1e-12, s = ''; else, s = num(K); end
f = @(v) factorTex(v);
nz = strjoin(arrayfun(f,z(:)','UniformOutput',false),'');
np = strjoin(arrayfun(f,p(:)','UniformOutput',false),'');
if isempty(nz), nz = '1'; end
if isempty(np), np = '1'; end
s = sprintf('%s\\frac{%s}{%s}',s,nz,np);
end

function s = factorTex(v)
v = cleanNum(v,1e-6);
if abs(v) < 1e-12, s = 's';
elseif abs(imag(v)) < 1e-12, s = sprintf('(s%s)',signedNum(-real(v)));
else, s = sprintf('(s%s)',cplxSigned(-v)); end
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

function s = mark(ok)
if ok, s = '✔'; else, s = '✘'; end
end

%% =========================================================================
%  Pole-zero editing helpers
%  =========================================================================
function sys = parseTF(str)
% Evaluate a MATLAB expression in s as a transfer function (zpk arithmetic
% keeps repeated and cancelling poles/zeros exact).
str = strtrim(str);
if isempty(str), error('Transfer function is empty.'); end
f = str2func(['@(s) ' str]);
try
    sys = zpk(f(zpk('s')));
catch
    sys = zpk(f(tf('s')));
end
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

function [addDD,delBtn] = rootControls(grid,row,addItems)
% Add/delete controls for a pole-zero editor.
g = at(uigridlayout(grid,[1 2],'Padding',[0 0 0 0]),row,[1 2]);
addDD = uidropdown(g,'Items',addItems);
delBtn = uibutton(g,'Text','Delete selected');
end

%% =========================================================================
%  UI helpers
%  =========================================================================
function v = getfieldDefault(s,f,d)
if isfield(s,f), v = s.(f); else, v = d; end
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
% Editing a transfer function by hand switches the example selector to Custom.
dd.Value = 'Custom';
updateFcn();
end

function showError(ta,err)
ta.Value = {'Error:'; err.message; ''; ...
    'Enter transfer functions as MATLAB expressions in s,'; ...
    'e.g. 5/(s+s^2/10) or 1/((s+2)^2*(s+5)).'};
end
