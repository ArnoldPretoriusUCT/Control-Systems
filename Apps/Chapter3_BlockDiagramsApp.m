function Chapter3_BlockDiagramsApp
%CHAPTER3_BLOCKDIAGRAMSAPP Interactive GUI for MEC3079S Chapter 3 — Block diagrams.
%
%   Run Chapter3_BlockDiagramsApp to open the app. The tabs follow the chapter:
%     1. Topologies       (3.3): cascade, parallel and feedback forms and
%        their equivalent single blocks.
%     2. Equivalent forms (3.4.1-3.4.2): moving blocks over summing junctions
%        and pickoff points, before and after, with the output signals.
%     3. Reduction        (3.4.3): Examples 1 and 2 reduced step by step.
%     4. Signal paths     (3.5): closed-loop and internal transfer behaviour
%        of the general loop, with the forward path and loop highlighted.
%
%   Every diagram is a netlist (blocks, summing junctions, pickoff points),
%   so the transfer functions shown are obtained by solving the signal
%   equations symbolically rather than being typed in.
%
%   Interaction:
%     - Tabs 1 and 4: drag the poles (x) and zeros (o) of the individual blocks in
%       the s-plane; the poles of the equivalent / closed-loop system (black) follow.
%       Tab 4: drag a black closed-loop pole along the root locus to scale G(s).
%     - Tab 2: drag the P(s) block over the summing junction or pickoff point to
%       reveal the equivalent form.
%     - Tab 4: click two signal labels on the diagram to choose "From" and "To".
%     - Tab 3: step through the reduction with the Previous/Next buttons.
%
%   Requires the Control System Toolbox and the Symbolic Math Toolbox.

cPath = [0.85 0.33 0.10];   % forward path
cLoop = [0.00 0.45 0.74];   % feedback loop
cOK   = [0.02 0.42 0.12];
cBad  = [0.70 0.00 0.00];

fig = uifigure('Name','MEC3079S Chapter 3 — Block diagrams','Position',[50 40 1340 860]);
mainGrid = uigridlayout(fig,[1 1],'Padding',[0 0 0 0]);
tg = uitabgroup(mainGrid);

% Drag state shared by all interactive plots
drag = struct('active',false,'ax',[],'move',[],'done',[],'p0',[0 0], ...
    'last',[],'xl',[],'yl',[],'t',tic);
fig.WindowButtonMotionFcn = @(~,~) onMotion();
fig.WindowButtonUpFcn = @(~,~) onRelease();
symCache = containers.Map();     % symbolic results per diagram (they do not depend on the values)

%% =====================================================================
%  Tab 1: Topologies
%  =====================================================================
t1 = uitab(tg,'Title','Topologies');
g1 = uigridlayout(t1,[1 2],'ColumnWidth',{340,'1x'});

c1 = uigridlayout(g1,[13 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{80,22,22,22,22,22,22,22,22,22,'1x',22,0});
at(uilabel(c1,'Text',['Cascade: blocks multiply. Parallel: blocks add (with the junction signs). ' ...
    'Feedback: L/(1 ± LH). Block entries are MATLAB expressions in s (values from the notes'' code).'], ...
    'FontWeight','bold','WordWrap','on'),1,[1 2]);
at(uilabel(c1,'Text','Topology'),2,1);
dd1Top = at(uidropdown(c1,'Items',{'Cascade (3.3.1)','Parallel (3.3.2)','Feedback (3.3.3)'}),2,2);
lbl1A = at(uilabel(c1,'Text','P₁(s)'),3,1);
ef1A = at(uieditfield(c1,'text','Value','1/s'),3,2);
lbl1B = at(uilabel(c1,'Text','P₂(s)'),4,1);
ef1B = at(uieditfield(c1,'text','Value','5'),4,2);
lbl1C = at(uilabel(c1,'Text','P₃(s)'),5,1);
ef1C = at(uieditfield(c1,'text','Value','1/(1+s)'),5,2);
lbl1S = at(uilabel(c1,'Text','Signs (P₁ P₂ P₃)'),6,1);
g1S = at(uigridlayout(c1,[1 3],'Padding',[0 0 0 0]),6,2);
dd1S = gobjects(1,3);
for k = 1:3, dd1S(k) = uidropdown(g1S,'Items',{'+','−'}); end
lbl1F = at(uilabel(c1,'Text','Feedback sign'),7,1);
dd1F = at(uidropdown(c1,'Items',{'− (negative feedback)','+ (positive feedback)'}),7,2);
at(uilabel(c1,'Text','Step response to (s)'),8,1);
ef1T = at(uieditfield(c1,'numeric','Value',10,'Limits',[0.1 Inf]),8,2);
at(uilabel(c1,'Text','Results','FontWeight','bold'),10,[1 2]);
ta1 = at(uitextarea(c1,'Editable','off','FontName','Monospaced'),11,[1 2]);
btn1 = at(uibutton(c1,'Text','Update'),12,[1 2]);

r1 = uigridlayout(g1,[3 1],'RowHeight',{'1.3x','fit','1x'});
ax1d = uiaxes(r1);
lbl1Eq = uilabel(r1,'Text','','Interpreter','latex','FontSize',18,'HorizontalAlignment','center');
g1y = uigridlayout(r1,[1 2],'Padding',[0 0 0 0],'ColumnWidth',{'1.3x','1x'});
ax1y = uiaxes(g1y);
ax1s = uiaxes(g1y);

[dd1Top.ValueChangedFcn, ef1A.ValueChangedFcn, ef1B.ValueChangedFcn, ef1C.ValueChangedFcn, ...
    dd1F.ValueChangedFcn, ef1T.ValueChangedFcn] = deal(@(~,~) update1());
for k = 1:3, dd1S(k).ValueChangedFcn = @(~,~) update1(); end
btn1.ButtonPushedFcn = @(~,~) update1();

%% =====================================================================
%  Tab 2: Equivalent forms
%  =====================================================================
t2 = uitab(tg,'Title','Equivalent forms');
g2 = uigridlayout(t2,[1 2],'ColumnWidth',{340,'1x'});

c2 = uigridlayout(g2,[8 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{96,22,22,22,22,22,'1x',22});
at(uilabel(c2,'Text',['A block can be moved over a summing junction or pickoff point as long as ' ...
    'every output signal is unchanged; the signals that cross the block must be compensated with ' ...
    'P(s) or 1/P(s). The outputs of both diagrams are computed from the diagrams themselves.'], ...
    'FontWeight','bold','WordWrap','on'),1,[1 2]);
rules2 = {'Block backwards over a summing junction (Fig 3.10)', ...
          'Block forwards over a summing junction (Fig 3.11)', ...
          'Block backwards over a pickoff point (Fig 3.12)', ...
          'Block forwards over a pickoff point (Fig 3.13)'};
at(uilabel(c2,'Text','Rule'),2,1);
dd2Rule = at(uidropdown(c2,'Items',rules2),2,2);
at(uilabel(c2,'Text','Junction sign of X'),3,1);
dd2Sign = at(uidropdown(c2,'Items',{'−','+'}),3,2);
cb2Mistake = at(uicheckbox(c2,'Text','Show a common mistake (forget the compensating block)'),4,[1 2]);
at(uilabel(c2,'Text','Drag the P(s) block over the junction / pickoff point.','FontAngle','italic'),5,[1 2]);
at(uilabel(c2,'Text','Results','FontWeight','bold'),6,[1 2]);
ta2 = at(uitextarea(c2,'Editable','off','FontName','Monospaced'),7,[1 2]);
btn2 = at(uibutton(c2,'Text','Show the equivalent form'),8,[1 2]);

r2 = uigridlayout(g2,[2 1],'RowHeight',{'fit','1x'});
lbl2Eq = uilabel(r2,'Text','','Interpreter','latex','FontSize',18,'HorizontalAlignment','center');
ax2d = uiaxes(r2);

revealed2 = false;      % the equivalent form appears once P(s) has been dragged over
[dd2Rule.ValueChangedFcn, dd2Sign.ValueChangedFcn] = deal(@(~,~) reveal2(false));
cb2Mistake.ValueChangedFcn = @(~,~) update2();
btn2.ButtonPushedFcn = @(~,~) reveal2(true);

%% =====================================================================
%  Tab 3: Block diagram reduction
%  =====================================================================
t3 = uitab(tg,'Title','Reduction');
g3 = uigridlayout(t3,[1 2],'ColumnWidth',{340,'1x'});

c3 = uigridlayout(g3,[7 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{64,22,22,'fit',22,'1x',0});
at(uilabel(c3,'Text',['Reduce the diagram to Y(s) = T_e(s)R(s) with the familiar forms and ' ...
    'equivalent forms. Each step is checked: Y(s)/R(s) of the new diagram must equal that of the original.'], ...
    'FontWeight','bold','WordWrap','on'),1,[1 2]);
at(uilabel(c3,'Text','Example'),2,1);
dd3Ex = at(uidropdown(c3,'Items',{'Example 1 (Fig 3.14)','Example 2 (Fig 3.18)'}),2,2);
g3b = at(uigridlayout(c3,[1 3],'Padding',[0 0 0 0],'ColumnWidth',{'1x','1x','1x'}),3,[1 2]);
btn3Prev = uibutton(g3b,'Text','◀ Previous');
lbl3Step = uilabel(g3b,'Text','','HorizontalAlignment','center','FontWeight','bold');
btn3Next = uibutton(g3b,'Text','Next ▶');
lbl3Desc = at(uilabel(c3,'Text','','WordWrap','on','FontSize',13),4,[1 2]);
at(uilabel(c3,'Text','Results','FontWeight','bold'),5,[1 2]);
ta3 = at(uitextarea(c3,'Editable','off','FontName','Monospaced'),6,[1 2]);

r3 = uigridlayout(g3,[2 1],'RowHeight',{'fit','1x'});
lbl3Eq = uilabel(r3,'Text','','Interpreter','latex','FontSize',18,'HorizontalAlignment','center');
ax3d = uiaxes(r3);

step3 = 1;
steps3 = struct('ex1',{{}},'ex2',{{}});   % reduction steps, built once per example
dd3Ex.ValueChangedFcn = @(~,~) setStep3(1);
btn3Prev.ButtonPushedFcn = @(~,~) moveStep3(-1);
btn3Next.ButtonPushedFcn = @(~,~) moveStep3(1);

%% =====================================================================
%  Tab 4: Signal paths
%  =====================================================================
t4 = uitab(tg,'Title','Signal paths');
g4 = uigridlayout(t4,[1 2],'ColumnWidth',{340,'1x'});

c4 = uigridlayout(g4,[12 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{112,22,22,22,22,22,22,22,22,22,'1x',22});
at(uilabel(c4,'Text',['External signals (R, D, N): T = forward / (1 + loop), with the other external ' ...
    'signals set to zero. Between internal signals (E, U, Y): forward path only. ' ...
    'Click two signal labels on the diagram to pick "From" and then "To". ' ...
    'Orange: forward path; blue: feedback loop.'],'FontWeight','bold','WordWrap','on'),1,[1 2]);
at(uilabel(c4,'Text','From'),2,1);
dd4From = at(uidropdown(c4,'Items',{'R','D','N','E','U','Y'}),2,2);
at(uilabel(c4,'Text','To'),3,1);
dd4To = at(uidropdown(c4,'Items',{'E','U','Y'},'Value','Y'),3,2);
lbl4Next = at(uilabel(c4,'Text','Next click on the diagram sets: From','FontAngle','italic'),4,[1 2]);
at(uilabel(c4,'Text','F(s)'),5,1);
ef4F = at(uieditfield(c4,'text','Value','1','Tooltip','Numerical values for the response plot'),5,2);
at(uilabel(c4,'Text','G(s)'),6,1);
ef4G = at(uieditfield(c4,'text','Value','10*(1+s/2)/s'),6,2);
at(uilabel(c4,'Text','P(s)'),7,1);
ef4P = at(uieditfield(c4,'text','Value','1/(s+1)/(s/10+1)'),7,2);
at(uilabel(c4,'Text','H(s)'),8,1);
ef4H = at(uieditfield(c4,'text','Value','1'),8,2);
at(uilabel(c4,'Text','Results','FontWeight','bold'),10,[1 2]);
ta4 = at(uitextarea(c4,'Editable','off','FontName','Monospaced'),11,[1 2]);
btn4 = at(uibutton(c4,'Text','Update'),12,[1 2]);

r4 = uigridlayout(g4,[3 1],'RowHeight',{'1.2x','fit','1x'});
ax4d = uiaxes(r4);
lbl4Eq = uilabel(r4,'Text','','Interpreter','latex','FontSize',18,'HorizontalAlignment','center');
g4y = uigridlayout(r4,[1 2],'Padding',[0 0 0 0],'ColumnWidth',{'1.3x','1x'});
ax4y = uiaxes(g4y);
ax4s = uiaxes(g4y);

pickFrom4 = true;
[dd4From.ValueChangedFcn, dd4To.ValueChangedFcn, ef4F.ValueChangedFcn, ef4G.ValueChangedFcn, ...
    ef4P.ValueChangedFcn, ef4H.ValueChangedFcn] = deal(@(~,~) update4());
btn4.ButtonPushedFcn = @(~,~) update4();
[ax1s.Interactions, ax4s.Interactions] = deal([]);

% Initial draw
update1(); update2(); setStep3(1); update4();

%% =====================================================================
%  Tab 1 callbacks
%  =====================================================================
    function update1()
        try
            top = dd1Top.Value(1:4);
            isFb = strcmp(top,'Feed');
            lbl1A.Text = 'P₁(s)';  lbl1B.Text = 'P₂(s)';
            if isFb, lbl1A.Text = 'L(s)'; lbl1B.Text = 'H(s)'; end
            if isFb && strcmp(ef1A.Value,'1/s') && strcmp(ef1B.Value,'5')
                ef1B.Value = '1/(1+s/10)';             % the notes' feedback example
            elseif ~isFb && strcmp(ef1B.Value,'1/(1+s/10)')
                ef1B.Value = '5';
            end
            set([lbl1C ef1C],'Visible',onoff(~isFb));
            set([lbl1S g1S],'Visible',onoff(strcmp(top,'Para')));
            set([lbl1F dd1F],'Visible',onoff(isFb));

            sg = arrayfun(@(d) 1 - 2*strcmp(d.Value,'−'),dd1S);
            fbSign = 1 - 2*startsWith(dd1F.Value,'−');      % +1 positive, -1 negative feedback
            switch top
                case 'Casc'
                    D = diagCascade();
                    formula = '$Y(s)=P_c(s)U(s),\quad P_c(s)=P_1(s)P_2(s)P_3(s)$';
                    expected = str2sym('P1*P2*P3');
                case 'Para'
                    D = diagParallel(sg);
                    formula = sprintf('$Y(s)=P_p(s)U(s),\\quad P_p(s)=%s$',signedSum(sg,{'P_1(s)','P_2(s)','P_3(s)'}));
                    expected = sg(1)*str2sym('P1') + sg(2)*str2sym('P2') + sg(3)*str2sym('P3');
                case 'Feed'
                    D = diagFeedback(fbSign);
                    if fbSign < 0
                        formula = '$\frac{Y(s)}{R(s)}=T_e(s)=\frac{L(s)}{1+L(s)H(s)}$';
                    else
                        formula = '$\frac{Y(s)}{R(s)}=T_e(s)=\frac{L(s)}{1-L(s)H(s)}$';
                    end
                    expected = str2sym('L')/(1 - fbSign*str2sym('L')*str2sym('H'));
            end
            [in,out] = deal(D.input,D.output);
            key = sprintf('1%s%s%d',top,sprintf('%d',sg),fbSign);
            if ~isKey(symCache,key)
                Tsym = simplify(solveTF(D,in,out));
                symCache(key) = {Tsym, isAlways(simplify(Tsym - expected) == 0,'Unknown','false')};
            end
            c = symCache(key);  [Tsym,okSym] = c{:};
            drawDiagram(ax1d,D,struct());
            title(ax1d,dd1Top.Value);
            lbl1Eq.Text = formula;

            % Numerical values (as in the notes' MATLAB code)
            if isFb
                vals = {'L',ef1A.Value; 'H',ef1B.Value};
            else
                vals = {'P1',ef1A.Value; 'P2',ef1B.Value; 'P3',ef1C.Value};
            end
            Tnum = symToTF(Tsym,vals);
            cla(ax1y);
            t = linspace(0,ef1T.Value,1500)';
            txt = {sprintf('From the diagram: %s/%s = %s',out,in,char(Tsym))
                   ['Formula agrees with the diagram: ' mark(okSym)]
                   ''
                   'With the values entered:'};
            txt = [txt; tfLines(Tnum)];
            if isproper(Tnum)
                y = step(Tnum,t);
                plot(ax1y,t,y,'Color',cLoop,'LineWidth',2);
                grid(ax1y,'on');
                title(ax1y,sprintf('Step response of the equivalent block, %s/%s',out,in));
                xlabel(ax1y,'Time (s)');
            else
                txt{end+1} = '(improper: no step response)';
            end
            if isFb
                B = struct('name',{'L(s)','H(s)'},'ef',{ef1A,ef1B},'col',{cPath,cLoop});
                eqName = 'closed loop Y/R';
            else
                B = struct('name',{'P_1(s)','P_2(s)','P_3(s)'},'ef',{ef1A,ef1B,ef1C}, ...
                    'col',{cPath,cLoop,[0.49 0.18 0.56]});
                eqName = 'equivalent block';
            end
            drawBlockPZ(ax1s,B,pole(Tnum),zero(Tnum),eqName,@update1,[]);
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
            i = find(strcmp(rules2,dd2Rule.Value));
            sx = 1 - 2*strcmp(dd2Sign.Value,'−');
            mistake = cb2Mistake.Value;
            [Db,Da,note] = diagRule(i,sx,mistake);
            outs = Db.outputs;
            cla(ax2d);
            [~,bh] = drawDiagram(ax2d,Db,struct(),0);
            dx = Db.xlim(2) + 2.2 - Da.xlim(1);
            % P(s) is dragged over the junction / pickoff point at x = cross(i), in direction dirn(i)
            cross = [1.5 3.5 1.2 2.8];  dirn = [-1 1 -1 1];
            b = bh(strcmp({bh.id},'P'));
            draggable([b.rect b.txt],ax2d,@(pt,p0) moveBlock2(b,pt(1) - p0(1)), ...
                @() releaseBlock2(b,cross(i),dirn(i)));
            if revealed2
                drawDiagram(ax2d,Da,struct(),dx);
                text(ax2d,Db.xlim(2) + 1.1,0,'$\equiv$','Interpreter','latex','FontSize',40, ...
                    'HorizontalAlignment','center');
                title(ax2d,'Before  ≡  after');
            else
                if dirn(i) < 0, arrow = '\leftarrow'; else, arrow = '\rightarrow'; end
                text(ax2d,b.x + dirn(i)*0.2,b.y + 0.75,['drag ' arrow],'FontSize',13,'Color',cPath, ...
                    'HorizontalAlignment','center','FontWeight','bold','PickableParts','none');
                text(ax2d,dx + mean(Da.xlim),0,{'Drag P(s) over the','junction / pickoff point','to see the equivalent form'}, ...
                    'FontSize',14,'Color',[0.5 0.5 0.5],'HorizontalAlignment','center');
                title(ax2d,'Before');
            end
            fitAxes(ax2d,[Db.xlim(1), dx + Da.xlim(2)],[min(Db.ylim(1),Da.ylim(1)) max(Db.ylim(2),Da.ylim(2))]);
            if ~revealed2
                ta2.Value = {note; ''; 'Drag the P(s) block over the summing junction or pickoff point'; ...
                    '(or press "Show the equivalent form") to see what must be added'; ...
                    'to keep every output signal unchanged.'};
                lbl2Eq.Text = '';
                return
            end

            txt = {note; ''};
            eqLines = {};
            allOK = true;
            for k = 1:numel(outs)
                yb = simplify(solveOutput(Db,outs{k}));
                ya = simplify(solveOutput(Da,outs{k}));
                ok = isAlways(simplify(yb - ya) == 0,'Unknown','false');
                allOK = allOK && ok;
                txt = [txt; {sprintf('%s before: %s',outs{k},char(yb)); ...
                    sprintf('%s after:  %s   %s',outs{k},char(ya),mark(ok))}]; %#ok<AGROW>
                if ok
                    eqLines{end+1} = sprintf('%s=%s',outTex(outs{k}),latex(ya)); %#ok<AGROW>
                else
                    eqLines{end+1} = sprintf('%s:\\ %s\\neq %s',outTex(outs{k}),latex(yb),latex(ya)); %#ok<AGROW>
                end
            end
            txt{end+1} = '';
            if allOK
                txt{end+1} = 'All output signals unchanged: the forms are equivalent ✔';
                col = cOK;
            else
                txt{end+1} = 'An output changed: the forms are NOT equivalent ✘';
                col = cBad;
            end
            ta2.Value = flatLines(txt);
            lbl2Eq.Text = ['$' strjoin(eqLines,',\\qquad ') '$'];   % \\ : strjoin unescapes the delimiter
            lbl2Eq.FontColor = col;
        catch err
            showError(ta2,err);
        end
    end

%% =====================================================================
%  Tab 3 callbacks
%  =====================================================================
    function moveStep3(d)
        % Read the current step when pressed (an anonymous function would
        % capture the step number at the time it was created).
        setStep3(step3 + d);
    end

    function setStep3(k)
        ex = dd3Ex.Value(9);
        f = ['ex' ex];
        if isempty(steps3.(f)), steps3.(f) = reductionSteps(ex); end
        steps = steps3.(f);
        step3 = min(max(k,1),numel(steps));
        btn3Prev.Enable = onoff(step3 > 1);
        btn3Next.Enable = onoff(step3 < numel(steps));
        try
            S0 = steps{1};  Sk = steps{step3};
            T0 = simplify(solveTF(S0.D,'R','Y'));
            Tk = simplify(solveTF(Sk.D,'R','Y'));
            ok = isAlways(simplify(T0 - Tk) == 0,'Unknown','false');
            lbl3Step.Text = sprintf('Step %d of %d',step3,numel(steps));
            lbl3Desc.Text = Sk.desc;
            drawDiagram(ax3d,Sk.D,struct());
            title(ax3d,Sk.title);
            lbl3Eq.Text = ['$\frac{Y(s)}{R(s)}=' Sk.tex '$'];
            txt = {sprintf('Y/R of this diagram (solved):')
                   ['  ' char(Tk)]
                   ''
                   sprintf('Same as the original diagram: %s',mark(ok))};
            if step3 == numel(steps)
                txt = [txt; {''; 'Fully reduced: Y(s) = T_e(s) R(s).'}];
            end
            ta3.Value = flatLines(txt);
            if ok, lbl3Eq.FontColor = [0 0 0]; else, lbl3Eq.FontColor = cBad; end
        catch err
            showError(ta3,err);
        end
    end

%% =====================================================================
%  Tab 4 callbacks
%  =====================================================================
    function pickSignal4(sig)
        % Clicking a signal label sets "From", then "To", alternately.
        if pickFrom4
            dd4From.Value = sig;
        elseif any(strcmp(dd4To.Items,sig))
            dd4To.Value = sig;
        else
            return                        % external signals cannot be a destination
        end
        pickFrom4 = ~pickFrom4;
        if pickFrom4, lbl4Next.Text = 'Next click on the diagram sets: From';
        else, lbl4Next.Text = 'Next click on the diagram sets: To'; end
        update4();
    end

    function update4()
        try
            D = diagGeneralLoop();
            src = dd4From.Value;  dst = dd4To.Value;
            ext = {'R','D','N'};
            isExt = any(strcmp(src,ext));
            if strcmp(src,dst)
                error('Choose two different signals.');
            end
            key = ['4' src dst];
            if ~isKey(symCache,key)
                [paths,loops] = pathsAndLoops(D,src,dst);
                Tsol = [];
                if any(strcmp(src,ext)), Tsol = simplify(solveTF(D,src,dst)); end
                symCache(key) = {paths,loops,Tsol};
            end
            c = symCache(key);  [paths,loops,Tsol] = c{:};
            if isempty(paths)
                error('There is no signal path from %s to %s.',src,dst);
            end
            fwd = sum(cellfun(@(p) p.gain,paths));
            hl = struct('path',{paths},'loop',{{}});
            if isExt, hl.loop = loops; end
            labels = drawDiagram(ax4d,D,hl);
            for k = 1:numel(labels)
                if ~isempty(labels(k).UserData)
                    sig = labels(k).UserData;
                    labels(k).ButtonDownFcn = @(~,~) pickSignal4(sig);
                end
            end
            title(ax4d,sprintf('%s(s) to %s(s)',src,dst));

            txt = {sprintf('Forward path %s -> %s: %s',src,dst,char(fwd))};
            if isExt
                Lsig = loops{1}.gain;              % includes the junction sign
                Lol = simplify(-Lsig);             % loop transfer function (sign ignored)
                Tf = simplify(fwd/(1 + Lol));
                ok = isAlways(simplify(Tf - Tsol) == 0,'Unknown','false');
                lbl4Eq.Text = sprintf(['$\\left.\\frac{%s(s)}{%s(s)}\\right|_{%s=0}=' ...
                    '\\frac{\\mathrm{forward}}{1+\\mathrm{loop}}=\\frac{%s}{1+%s}$'], ...
                    dst,src,strjoin(setdiff(ext,src),',\\,'),latex(fwd),latex(Lol));
                txt = [txt; {sprintf('Loop transfer function: %s',char(Lol))
                    sprintf('T = forward/(1 + loop) = %s',char(Tf))
                    ''
                    sprintf('Full solution with %s = 0:',strjoin(setdiff(ext,src),' = '))
                    ['  ' char(Tsol)]
                    sprintf('Agrees with forward/(1 + loop): %s',mark(ok))}];
                Tshow = Tf;
            else
                lbl4Eq.Text = sprintf(['$\\frac{%s(s)}{%s(s)}=\\mathrm{forward\\ path}=%s' ...
                    '\\quad(R=D=N=0)$'],dst,src,latex(fwd));
                txt = [txt; {''
                    'Between internal signals the transfer behaviour'
                    'is the forward path only: follow the signal from'
                    sprintf('%s to %s, with summing junctions replaced by',src,dst)
                    'gains of +1 or -1 (no division by 1 + loop).'}];
                Tshow = fwd;
            end

            % Response for the numerical values
            vals = {'F',ef4F.Value; 'G',ef4G.Value; 'P',ef4P.Value; 'H',ef4H.Value};
            Tnum = symToTF(Tshow,vals);
            txt = [txt; {''; 'With the values entered:'}; tfLines(Tnum)];
            cla(ax4y);
            if isproper(Tnum)
                [y,t] = step(Tnum);
                plot(ax4y,t,y,'Color',cPath,'LineWidth',2);
                grid(ax4y,'on');
                title(ax4y,sprintf('Response of %s to a unit step in %s',dst,src));
                xlabel(ax4y,'Time (s)');
            else
                txt{end+1} = '(improper: no step response)';
            end
            B = struct('name',{'G(s)','P(s)','H(s)'},'ef',{ef4G,ef4P,ef4H}, ...
                'col',{cPath,[0.20 0.55 0.45],cLoop});
            L0 = evalTF(ef4G.Value)*evalTF(ef4P.Value)*evalTF(ef4H.Value);
            drawBlockPZ(ax4s,B,pole(feedback(L0,1)),[],'closed-loop poles',@update4,@(pt) clPole4(pt));
            [~,rl] = locus4(L0);                % faint root locus for scaling G(s)
            hold(ax4s,'on');
            hL = plot(ax4s,real(rl(:)),imag(rl(:)),'.','Color',[0.72 0.72 0.72],'MarkerSize',4, ...
                'PickableParts','none');
            hold(ax4s,'off');
            uistack(hL,'bottom');
            ta4.Value = flatLines(txt);
        catch err
            showError(ta4,err);
        end
    end

%% =====================================================================
%  Tab 2: dragging the block
%  =====================================================================
    function reveal2(v)
        revealed2 = v;
        update2();
    end

    function moveBlock2(b,dx)
        p = b.rect.Position;  p(1) = b.x + dx - p(3)/2;
        b.rect.Position = p;
        b.txt.Position(1) = b.x + dx;
    end

    function releaseBlock2(b,xc,dirn)
        % Over the junction / pickoff point: show the equivalent form; otherwise snap back.
        p = b.rect.Position;
        if (p(1) + p(3)/2 - xc)*dirn > 0, revealed2 = true; end
        update2();
    end

%% =====================================================================
%  Block poles and zeros in the s-plane (tabs 1 and 4)
%  =====================================================================
    function drawBlockPZ(ax,B,pe,ze,eqName,upd,clFcn)
        % Poles (x) and zeros (o) of every block, each draggable, with the poles and
        % zeros of the equivalent / closed-loop system in black. A block entry is
        % rewritten in Bode form K(1+s/a)/(1+s/b)... with its DC gain kept.
        cla(ax);  hold(ax,'on');  grid(ax,'on');  box(ax,'on');
        hLeg = gobjects(0);  allR = [pe(:); ze(:)];
        for k = 1:numel(B)
            sys = zpk(evalTF(B(k).ef.Value));
            z = sys.Z{1};  p = sys.P{1};  Kb = bodeGain(z,p,sys.K);
            allR = [allR; z; p]; %#ok<AGROW>
            hLeg(end+1) = plot(ax,NaN,NaN,'x','Color',B(k).col,'MarkerSize',11,'LineWidth',2.5, ...
                'DisplayName',['$' B(k).name '$']); %#ok<AGROW>
            for kind = 'zp'
                if kind == 'z', r = z; mk = 'o'; else, r = p; mk = 'x'; end
                for j = 1:numel(r)
                    if imag(r(j)) < -1e-9, continue, end
                    h = plot(ax,real(r(j))*[1 1],imag(r(j))*[1 -1],mk,'Color',B(k).col, ...
                        'MarkerSize',13,'LineWidth',2.5);
                    draggable(h,ax,@(pt,~) moveBlockRoot(B(k).ef,z,p,Kb,kind,j,pt,ax,upd),upd);
                end
            end
        end
        he = plot(ax,real(pe),imag(pe),'kx','MarkerSize',8,'LineWidth',1.5,'DisplayName',eqName);
        if ~isempty(ze), plot(ax,real(ze),imag(ze),'ko','MarkerSize',7,'LineWidth',1.2); end
        if ~isempty(clFcn) && ~isempty(pe)
            draggable(he,ax,@(pt,~) clFcn(pt),upd);
            he.DisplayName = [eqName ' (drag)'];
        end
        hLeg(end+1) = he;
        Rm = max([1; abs(allR(isfinite(allR)))])*1.25;
        xr = max(real(allR(isfinite(allR))));  if isempty(xr), xr = 0; end
        xlim(ax,[-Rm, max(0.3*Rm, xr + 0.2*Rm)]);  ylim(ax,[-0.8 0.8]*Rm);
        xline(ax,0,'Color',[0.6 0.6 0.6]);  yline(ax,0,'Color',[0.6 0.6 0.6]);
        legend(ax,hLeg,'Location','southwest','Interpreter','latex','AutoUpdate','off');
        title(ax,'s-plane: drag a block''s pole (×) or zero (○)');
        xlabel(ax,'Re(s)');  ylabel(ax,'Im(s)');
        hold(ax,'off');
    end

    function moveBlockRoot(ef,z,p,Kb,kind,j,pt,ax,upd)
        x = pt(1);
        if abs(x) < 0.015*diff(ax.XLim), x = 0; end          % snap to the origin (integrator)
        if kind == 'z', r = z; else, r = p; end
        if abs(imag(r(j))) > 1e-9                            % complex pair: move both
            y = max(abs(pt(2)),0.02*diff(ax.YLim));
            c = find(abs(r - conj(r(j))) < 1e-9 & (1:numel(r))' ~= j,1);
            r(j) = complex(x,y);  r(c) = complex(x,-y);
        else                                                 % real root stays real
            r(j) = x;
        end
        if kind == 'z', z = r; else, p = r; end
        ef.Value = bodeStr(Kb,z,p);
        upd();
    end

    function [c,r] = locus4(L)
        % Closed-loop poles of 1 + c L(s) = 0 for gain factors c (root locus of G's gain).
        [n,d] = tfdata(L,'v');
        c = logspace(-3,3,600);
        r = complex(NaN(numel(d)-1,numel(c)));
        for k = 1:numel(c)
            q = roots(d + c(k)*[zeros(1,numel(d)-numel(n)) n]);
            r(1:numel(q),k) = q;
        end
    end

    function clPole4(pt)
        % Root-locus drag: scale G(s) so that a closed-loop pole lies at the cursor
        % (magnitude condition |c G(s0)P(s0)H(s0)| = 1).
        if ~isfield(drag,'G0') || isempty(drag.G0) || ~isequal(drag.p0,drag.G0.p0)
            sys = zpk(evalTF(ef4G.Value));
            L0 = sys*evalTF(ef4P.Value)*evalTF(ef4H.Value);
            drag.G0 = struct('p0',drag.p0,'z',sys.Z{1},'p',sys.P{1}, ...
                'K',bodeGain(sys.Z{1},sys.P{1},sys.K),'L',L0);
        end
        g = drag.G0;
        s0 = complex(pt(1),pt(2));
        [c,r] = locus4(g.L);                 % the gain whose closed-loop pole lies nearest the cursor
        [~,i] = min(min(abs(r - s0),[],1));
        ef4G.Value = bodeStr(g.K*c(i),g.z,g.p);
        update4();
    end

%% =====================================================================
%  Dragging
%  =====================================================================
    function startDrag(ax,moveFcn,doneFcn)
        % Begin a drag on ax. moveFcn(pt,p0) is called with the current and
        % starting mouse positions (data units) while the mouse moves, and
        % doneFcn() redraws once the mouse is released.
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
        if toc(drag.t) < 0.04, return, end     % limit the redraw rate
        applyDrag(drag.last);
    end

    function onRelease()
        if ~drag.active, return, end
        applyDrag(mousePoint(drag.ax));     % apply the release position exactly
        drag.active = false;
        drag.G0 = [];
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
%  Drawing
%  =====================================================================
    function [labels,bh] = drawDiagram(ax,D,hl,dx)
        % Draw a diagram; hl.path and hl.loop are lists of paths whose
        % elements are highlighted. Returns the signal label and block handles.
        if nargin < 4, dx = 0; end
        if dx == 0, cla(ax); end   % a second diagram (dx > 0) is added beside the first
        hold(ax,'on');
        Hp = elementsOf(getfieldDefault(hl,'path',{}),false);
        Hl = elementsOf(getfieldDefault(hl,'loop',{}),true);
        style = @(id,sig,to) highlightStyle(id,sig,to,Hp,Hl);

        for k = 1:numel(D.wires)
            w = D.wires{k};
            [col,lw] = style('',w.sig,w.to);
            p = w.pts + [dx 0];
            plot(ax,p(:,1),p(:,2),'-','Color',col,'LineWidth',lw);
            if w.arrow, arrowHead(ax,p(end-1,:),p(end,:),col); end
        end
        for k = 1:numel(D.dots)
            plot(ax,D.dots{k}(1)+dx,D.dots{k}(2),'o','MarkerFaceColor','k','MarkerEdgeColor','k','MarkerSize',5);
        end
        bh = struct('id',{},'rect',{},'txt',{},'x',{},'y',{});
        for k = 1:numel(D.blocks)
            b = D.blocks{k};
            [col,lw] = style(b.id,'','');
            hr = rectangle(ax,'Position',[b.x+dx-b.w/2, b.y-b.h/2, b.w, b.h],'EdgeColor',col,'LineWidth',max(lw,1.2), ...
                'FaceColor','w');
            ht = text(ax,b.x+dx,b.y,['$' b.tex '$'],'Interpreter','latex','FontSize',15, ...
                'HorizontalAlignment','center','VerticalAlignment','middle','Color',[0 0 0]);
            bh(end+1) = struct('id',b.id,'rect',hr,'txt',ht,'x',b.x+dx,'y',b.y); %#ok<AGROW>
        end
        r = 0.25;
        for k = 1:numel(D.sums)
            sm = D.sums{k};
            [col,lw] = style(sm.id,'','');
            x = sm.x + dx;  y = sm.y;
            rectangle(ax,'Position',[x-r y-r 2*r 2*r],'Curvature',[1 1],'EdgeColor',col, ...
                'LineWidth',max(lw,1.2),'FaceColor','w');
            q = r/sqrt(2);
            plot(ax,[x-q x+q],[y-q y+q],'Color',col,'LineWidth',1);
            plot(ax,[x-q x+q],[y+q y-q],'Color',col,'LineWidth',1);
            for j = 1:size(sm.in,1)
                if sm.in{j,2} > 0, sgn = '+'; else, sgn = '−'; end
                switch sm.in{j,3}
                    case 'W',  pos = [x-0.42 y+0.25];
                    case 'E',  pos = [x+0.42 y+0.25];
                    case 'S',  pos = [x-0.32 y-0.42];
                    case 'N',  pos = [x+0.30 y+0.45];
                    case 'SE', pos = [x+0.52 y-0.30];
                    case 'SS', pos = [x+0.22 y-0.58];
                end
                text(ax,pos(1),pos(2),sgn,'FontSize',15,'HorizontalAlignment','center');
            end
        end
        labels = gobjects(0);
        for k = 1:numel(D.labels)
            L = D.labels{k};
            h = text(ax,L.x+dx,L.y,['$' L.tex '$'],'Interpreter','latex','FontSize',L.fs, ...
                'HorizontalAlignment',L.ha,'VerticalAlignment','middle','Color',L.col);
            if ~isempty(L.sig)
                h.UserData = L.sig;
                h.FontWeight = 'bold';
            end
            labels(end+1) = h; %#ok<AGROW>
        end
        hold(ax,'off');
        if dx == 0, fitAxes(ax,D.xlim,D.ylim); end
    end

    function [col,lw] = highlightStyle(id,sig,to,Hp,Hl)
        % Colour of an element: forward path first, then the loop, else black.
        col = [0 0 0]; lw = 1.2;
        if isOn(id,sig,to,Hl), col = cLoop; lw = 3; end
        if isOn(id,sig,to,Hp), col = cPath; lw = 3.5; end
    end
end

%% =========================================================================
%  Diagram definitions (netlist + drawing)
%  =========================================================================
function D = newDiagram()
D = struct('blocks',{{}},'sums',{{}},'wires',{{}},'dots',{{}},'labels',{{}}, ...
    'xlim',[0 1],'ylim',[0 1],'width',1,'input','','output','','outputs',{{}});
end

function D = blk(D,id,in,out,gain,x,y,tex,w,h)
% System block: out = gain*in.
if nargin < 9, w = 1.6; end
if nargin < 10, h = 0.9; end
D.blocks{end+1} = struct('id',id,'in',in,'out',out,'gain',str2sym(gain),'x',x,'y',y,'w',w,'h',h,'tex',tex);
end

function D = sm(D,id,out,in,x,y)
% Summing junction: out = sum(sign*in); in = {signal, sign, side ('W','E','N','S')}.
D.sums{end+1} = struct('id',id,'out',out,'in',{in},'x',x,'y',y);
end

function D = wr(D,sig,to,pts,arrow)
% Wire carrying signal sig into element to ('' for a shared trunk).
if nargin < 5, arrow = true; end
D.wires{end+1} = struct('sig',sig,'to',to,'pts',pts,'arrow',arrow);
end

function D = lb(D,x,y,tex,sig,col,ha,fs)
if nargin < 5, sig = ''; end
if nargin < 6 || isempty(col), col = [0 0 0]; end
if nargin < 7, ha = 'center'; end
if nargin < 8, fs = 15; end
D.labels{end+1} = struct('x',x,'y',y,'tex',tex,'sig',sig,'col',col,'ha',ha,'fs',fs);
end

function D = dt(D,x,y)
D.dots{end+1} = [x y];
end

function D = finish(D,xl,yl)
D.xlim = xl;  D.ylim = yl;  D.width = diff(xl);
end

function D = diagCascade()
cR = [0.85 0.33 0.10]; cY = [0.20 0.55 0.45];
D = newDiagram();
D = lb(D,0,0,'U(s)','',cR,'right');
D = wr(D,'U','P1',[0.15 0; 1.2 0]);
D = blk(D,'P1','U','a','P1',2,0,'P_1(s)');
D = wr(D,'a','P2',[2.8 0; 3.7 0]);
D = blk(D,'P2','a','b','P2',4.5,0,'P_2(s)');
D = wr(D,'b','P3',[5.3 0; 6.2 0]);
D = blk(D,'P3','b','Y','P3',7,0,'P_3(s)');
D = wr(D,'Y','out',[7.8 0; 9 0]);
D = lb(D,9.15,0,'Y(s)','',cY,'left');
D.input = 'U';  D.output = 'Y';
D = finish(D,[-1.2 10.4],[-1.2 1.2]);
end

function D = diagParallel(sg)
cR = [0.85 0.33 0.10]; cY = [0.20 0.55 0.45];
D = newDiagram();
D = lb(D,0,0,'U(s)','',cR,'right');
D = wr(D,'U','',[0.15 0; 1.5 0],false);
D = dt(D,1.5,0);
ys = [1.5 0 -1.5];
side = {'N','W','S'};
in = cell(3,3);
for k = 1:3
    id = sprintf('P%d',k);
    D = wr(D,'U',id,[1.5 0; 1.5 ys(k); 2.7 ys(k)]);
    D = blk(D,id,'U',sprintf('p%d',k),id,3.5,ys(k),sprintf('P_%d(s)',k));
    switch k
        case 1, pts = [4.3 1.5; 6 1.5; 6 0.25];
        case 2, pts = [4.3 0; 5.75 0];
        case 3, pts = [4.3 -1.5; 6 -1.5; 6 -0.25];
    end
    D = wr(D,sprintf('p%d',k),'s',pts);
    in(k,:) = {sprintf('p%d',k),sg(k),side{k}};
end
in{1,3} = 'N'; in{3,3} = 'S';
D = sm(D,'s','Y',in,6,0);
D = wr(D,'Y','out',[6.25 0; 7.6 0]);
D = lb(D,7.75,0,'Y(s)','',cY,'left');
D.input = 'U';  D.output = 'Y';
D = finish(D,[-1.2 9],[-2.4 2.4]);
end

function D = diagFeedback(fbSign)
cR = [0.85 0.33 0.10]; cY = [0.20 0.55 0.45];
D = newDiagram();
D = lb(D,0,0,'R(s)','',cR,'right');
D = wr(D,'R','s',[0.15 0; 1.25 0]);
D = sm(D,'s','E',{'R',1,'W'; 'f',fbSign,'S'},1.5,0);
D = wr(D,'E','L',[1.75 0; 3.2 0]);
D = lb(D,2.45,0.35,'E(s)');
D = blk(D,'L','E','Y','L',4,0,'L(s)');
D = wr(D,'Y','',[4.8 0; 6 0],false);
D = dt(D,6,0);
D = wr(D,'Y','out',[6 0; 7.2 0]);
D = lb(D,7.35,0,'Y(s)','',cY,'left');
D = wr(D,'Y','H',[6 0; 6 -1.6; 4.8 -1.6]);
D = blk(D,'H','Y','f','H',4,-1.6,'H(s)');
D = wr(D,'f','s',[3.2 -1.6; 1.5 -1.6; 1.5 -0.25]);
D.input = 'R';  D.output = 'Y';
D = finish(D,[-1.2 8.6],[-2.6 1.0]);
end

function [Db,Da,note] = diagRule(i,sx,mistake)
% Before and after diagrams for the four equivalent-form rules.
cR = [0.85 0.33 0.10]; cY = [0.20 0.55 0.45];
Db = newDiagram();  Da = newDiagram();
switch i
    case 1   % P after the junction  ->  P on both junction inputs
        Db = lb(Db,0,0,'R(s)','',cR,'right');
        Db = wr(Db,'R','s',[0.15 0; 1.25 0]);
        Db = sm(Db,'s','e',{'R',1,'W'; 'X',sx,'S'},1.5,0);
        Db = lb(Db,1.5,-1.9,'X(s)');
        Db = wr(Db,'X','s',[1.5 -1.65; 1.5 -0.25]);
        Db = wr(Db,'e','P',[1.75 0; 2.7 0]);
        Db = blk(Db,'P','e','Y','P',3.5,0,'P(s)');
        Db = wr(Db,'Y','out',[4.3 0; 5.3 0]);
        Db = lb(Db,5.45,0,'Y(s)','',cY,'left');
        Db = finish(Db,[-1.2 6.6],[-2.3 1]);

        Da = lb(Da,0,0,'R(s)','',cR,'right');
        Da = wr(Da,'R','P',[0.15 0; 0.8 0]);
        Da = blk(Da,'P','R','a','P',1.6,0,'P(s)');
        Da = wr(Da,'a','s',[2.4 0; 3.25 0]);
        Da = sm(Da,'s','Y',{'a',1,'W'; 'b',sx,'S'},3.5,0);
        if mistake
            Da = wr(Da,'X','s',[3.5 -1.65; 3.5 -0.25]);
            Da.sums{1}.in{2,1} = 'X';
        else
            Da = blk(Da,'P2','X','b','P',3.5,-1.25,'P(s)',1.4,0.8);
            Da = wr(Da,'X','P2',[3.5 -2.4; 3.5 -1.65]);
            Da = wr(Da,'b','s',[3.5 -0.85; 3.5 -0.25]);
        end
        Da = lb(Da,3.5,-2.6 + 0.7*mistake,'X(s)');
        Da = wr(Da,'Y','out',[3.75 0; 5 0]);
        Da = lb(Da,5.15,0,'Y(s)','',cY,'left');
        Da = finish(Da,[-1.2 6.3],[-2.9 1]);
        Db.outputs = {'Y'};
        note = 'Moving P(s) backwards over the junction puts P(s) on every junction input.';
    case 2   % P before the junction  ->  P after, X through 1/P
        Db = lb(Db,0,0,'R(s)','',cR,'right');
        Db = wr(Db,'R','P',[0.15 0; 0.8 0]);
        Db = blk(Db,'P','R','a','P',1.6,0,'P(s)');
        Db = wr(Db,'a','s',[2.4 0; 3.25 0]);
        Db = sm(Db,'s','Y',{'a',1,'W'; 'X',sx,'S'},3.5,0);
        Db = wr(Db,'X','s',[3.5 -1.65; 3.5 -0.25]);
        Db = lb(Db,3.5,-1.9,'X(s)');
        Db = wr(Db,'Y','out',[3.75 0; 5 0]);
        Db = lb(Db,5.15,0,'Y(s)','',cY,'left');
        Db = finish(Db,[-1.2 6.3],[-2.3 1]);

        Da = lb(Da,0,0,'R(s)','',cR,'right');
        Da = wr(Da,'R','s',[0.15 0; 1.25 0]);
        Da = sm(Da,'s','e',{'R',1,'W'; 'b',sx,'S'},1.5,0);
        if mistake
            Da = wr(Da,'X','s',[1.5 -1.65; 1.5 -0.25]);
            Da.sums{1}.in{2,1} = 'X';
        else
            Da = blk(Da,'Pi','X','b','1/P',1.5,-1.3,'\frac{1}{P(s)}',1.4,1.0);
            Da = wr(Da,'X','Pi',[1.5 -2.5; 1.5 -1.8]);
            Da = wr(Da,'b','s',[1.5 -0.8; 1.5 -0.25]);
        end
        Da = lb(Da,1.5,-2.7 + 0.8*mistake,'X(s)');
        Da = wr(Da,'e','P',[1.75 0; 2.7 0]);
        Da = blk(Da,'P','e','Y','P',3.5,0,'P(s)');
        Da = wr(Da,'Y','out',[4.3 0; 5.3 0]);
        Da = lb(Da,5.45,0,'Y(s)','',cY,'left');
        Da = finish(Da,[-1.2 6.6],[-3 1]);
        Db.outputs = {'Y'};
        note = 'Moving P(s) forwards over the junction: every other junction input passes through 1/P(s).';
    case 3   % pickoff before P  ->  P before the pickoff, other branches through 1/P
        ys = [1.4 0 -1.4];
        Db = lb(Db,0,0,'R(s)','',cR,'right');
        Db = wr(Db,'R','',[0.15 0; 1.2 0],false);
        Db = dt(Db,1.2,0);
        Db = wr(Db,'R','P',[1.2 0; 1.2 ys(1); 2.3 ys(1)]);
        Db = blk(Db,'P','R','Y1','P',3.1,ys(1),'P(s)');
        Db = wr(Db,'Y1','out',[3.9 ys(1); 5 ys(1)]);
        Db = wr(Db,'R','',[1.2 0; 5 0]);
        Db = wr(Db,'R','',[1.2 0; 1.2 ys(3); 5 ys(3)]);
        Db = lb(Db,5.15,ys(1),'Y_1(s)','',cY,'left');
        Db = lb(Db,5.15,ys(2),'Y_2(s)','',cY,'left');
        Db = lb(Db,5.15,ys(3),'Y_3(s)','',cY,'left');
        Db = finish(Db,[-1.2 6.5],[-2.2 2.2]);
        Db.alias = {'Y2','R'; 'Y3','R'};

        Da = lb(Da,0,0,'R(s)','',cR,'right');
        Da = wr(Da,'R','P',[0.15 0; 0.7 0]);
        Da = blk(Da,'P','R','Y1','P',1.5,0,'P(s)');
        Da = wr(Da,'Y1','',[2.3 0; 2.8 0],false);
        Da = dt(Da,2.8,0);
        Da = wr(Da,'Y1','out',[2.8 0; 2.8 ys(1); 5.6 ys(1)]);
        if mistake
            Da = wr(Da,'Y1','out',[2.8 0; 5.6 0]);
            Da = wr(Da,'Y1','out',[2.8 0; 2.8 ys(3); 5.6 ys(3)]);
            Da.alias = {'Y2','Y1'; 'Y3','Y1'};
        else
            Da = wr(Da,'Y1','Pi2',[2.8 0; 3.4 0]);
            Da = blk(Da,'Pi2','Y1','Y2','1/P',4.2,0,'\frac{1}{P(s)}',1.4,1.0);
            Da = wr(Da,'Y2','out',[4.9 0; 5.6 0]);
            Da = wr(Da,'Y1','Pi3',[2.8 0; 2.8 ys(3); 3.4 ys(3)]);
            Da = blk(Da,'Pi3','Y1','Y3','1/P',4.2,ys(3),'\frac{1}{P(s)}',1.4,1.0);
            Da = wr(Da,'Y3','out',[4.9 ys(3); 5.6 ys(3)]);
        end
        Da = lb(Da,5.75,ys(1),'Y_1(s)','',cY,'left');
        Da = lb(Da,5.75,ys(2),'Y_2(s)','',cY,'left');
        Da = lb(Da,5.75,ys(3),'Y_3(s)','',cY,'left');
        Da = finish(Da,[-1.2 7.1],[-2.2 2.2]);
        Db.outputs = {'Y1','Y2','Y3'};
        note = 'Moving P(s) backwards over the pickoff point: the other branches must be divided by P(s).';
    case 4   % P before the pickoff  ->  P on every branch
        ys = [1.4 0 -1.4];
        Db = lb(Db,0,0,'R(s)','',cR,'right');
        Db = wr(Db,'R','P',[0.15 0; 0.7 0]);
        Db = blk(Db,'P','R','a','P',1.5,0,'P(s)');
        Db = wr(Db,'a','',[2.3 0; 2.8 0],false);
        Db = dt(Db,2.8,0);
        Db = wr(Db,'a','out',[2.8 0; 2.8 ys(1); 4.6 ys(1)]);
        Db = wr(Db,'a','out',[2.8 0; 4.6 0]);
        Db = wr(Db,'a','out',[2.8 0; 2.8 ys(3); 4.6 ys(3)]);
        for k = 1:3, Db = lb(Db,4.75,ys(k),sprintf('Y_%d(s)',k),'',cY,'left'); end
        Db.alias = {'Y1','a'; 'Y2','a'; 'Y3','a'};
        Db = finish(Db,[-1.2 6.1],[-2.2 2.2]);

        Da = lb(Da,0,0,'R(s)','',cR,'right');
        Da = wr(Da,'R','',[0.15 0; 1.2 0],false);
        Da = dt(Da,1.2,0);
        for k = 1:3
            id = sprintf('P%d',k);  out = sprintf('Y%d',k);
            if mistake && k > 1
                Da = wr(Da,'R','out',[1.2 0; 1.2 ys(k); 4.6 ys(k)]);
                Da.alias(k-1,:) = {out,'R'};
            else
                Da = wr(Da,'R',id,[1.2 0; 1.2 ys(k); 2.4 ys(k)]);
                Da = blk(Da,id,'R',out,'P',3.2,ys(k),'P(s)');
                Da = wr(Da,out,'out',[4.0 ys(k); 4.6 ys(k)]);
            end
            Da = lb(Da,4.75,ys(k),sprintf('Y_%d(s)',k),'',cY,'left');
        end
        Da = finish(Da,[-1.2 6.1],[-2.2 2.2]);
        Db.outputs = {'Y1','Y2','Y3'};
        note = 'Moving P(s) forwards over the pickoff point: every branch needs its own P(s).';
end
if mistake
    note = [note ' (Compensating block removed: watch the outputs change.)'];
end
end

function D = diagGeneralLoop()
% Figure 3.23: generalised closed-loop system with R, D and N.
cR = [0.85 0.33 0.10]; cD = [0.70 0.40 0.60]; cN = [0.95 0.60 0.20]; cY = [0.20 0.55 0.45];
D = newDiagram();
D = lb(D,0,0,'R(s)','R',cR,'right',18);
D = wr(D,'R','F',[0.2 0; 1.2 0]);
D = blk(D,'F','R','Rf','F',2,0,'F(s)');
D = wr(D,'Rf','s1',[2.8 0; 3.75 0]);
D = sm(D,'s1','E',{'Rf',1,'W'; 'Hy',-1,'S'},4,0);
D = wr(D,'E','G',[4.25 0; 5.2 0]);
D = lb(D,4.72,0.4,'E(s)','E',[0 0 0],'center',18);
D = blk(D,'G','E','U','G',6,0,'G(s)');
D = wr(D,'U','s2',[6.8 0; 7.75 0]);
D = lb(D,7.0,0.42,'U(s)','U',[0 0 0],'center',18);
D = sm(D,'s2','Ud',{'U',1,'W'; 'D',1,'N'},8,0);
D = lb(D,8,1.85,'D(s)','D',cD,'center',18);
D = wr(D,'D','s2',[8 1.6; 8 0.25]);
D = wr(D,'Ud','P',[8.25 0; 9.2 0]);
D = blk(D,'P','Ud','Y','P',10,0,'P(s)');
D = wr(D,'Y','',[10.8 0; 12 0],false);
D = dt(D,12,0);
D = wr(D,'Y','out',[12 0; 13.2 0]);
D = lb(D,13.35,0,'Y(s)','Y',cY,'left',18);
D = wr(D,'Y','s3',[12 0; 12 -2; 9.25 -2]);
D = sm(D,'s3','Yn',{'Y',1,'E'; 'N',1,'S'},9,-2);
D = lb(D,9,-3.85,'N(s)','N',cN,'center',18);
D = wr(D,'N','s3',[9 -3.6; 9 -2.25]);
D = wr(D,'Yn','H',[8.75 -2; 6.8 -2]);
D = blk(D,'H','Yn','Hy','H',6,-2,'H(s)');
D = wr(D,'Hy','s1',[5.2 -2; 4 -2; 4 -0.25]);
D = finish(D,[-1.4 15.0],[-4.3 2.3]);
end

function steps = reductionSteps(ex)
% Reduction steps of Examples 1 and 2 (Section 3.4.3), as in the notes.
cR = [0.85 0.33 0.10]; cY = [0.20 0.55 0.45];
steps = {};
if ex == '1'
    % Original (Fig 3.14)
    D = newDiagram();
    D = lb(D,0,0,'R(s)','',cR,'right');
    D = wr(D,'R','G1',[0.15 0; 1.2 0]);
    D = blk(D,'G1','R','a','G1',2,0,'G_1(s)');
    D = wr(D,'a','s1',[2.8 0; 3.75 0]);
    D = sm(D,'s1','b',{'a',1,'W'; 'h3',-1,'S'},4,0);
    D = wr(D,'b','s2',[4.25 0; 4.95 0]);
    D = sm(D,'s2','c',{'b',1,'W'; 'h2',1,'S'},5.2,0);
    D = wr(D,'c','s3',[5.45 0; 6.15 0]);
    D = sm(D,'s3','d',{'c',1,'W'; 'h1',-1,'S'},6.4,0);
    D = wr(D,'d','G2',[6.65 0; 7.4 0]);
    D = blk(D,'G2','d','e','G2',8.2,0,'G_2(s)');
    D = wr(D,'e','G3',[9 0; 9.6 0]);
    D = blk(D,'G3','e','Y','G3',10.4,0,'G_3(s)');
    D = wr(D,'Y','',[11.2 0; 12 0],false);
    D = wr(D,'Y','out',[12 0; 13 0]);
    D = lb(D,13.15,0,'Y(s)','',cY,'left');
    D = dt(D,12,0); D = dt(D,12,-1.5); D = dt(D,12,-3);
    D = feedbackRows(D,{'H1','H2','H3'},{'h1','h2','h3'},[-1.5 -3 -4.5],8.2,12, ...
        [6.4 6.4 -0.25; 5.2 5.2 -0.25; 4 4 -0.25]);
    D = finish(D,[-1.3 14.5],[-5.2 0.9]);
    steps{end+1} = struct('D',D,'title','Example 1: original (Fig 3.14)', ...
        'desc','Three feedback paths, each entering its own summing junction.', ...
        'tex','?');
    % (a) one summing junction
    D = newDiagram();
    D = lb(D,0,0,'R(s)','',cR,'right');
    D = wr(D,'R','G1',[0.15 0; 1.2 0]);
    D = blk(D,'G1','R','a','G1',2,0,'G_1(s)');
    D = wr(D,'a','s',[2.8 0; 3.75 0]);
    D = sm(D,'s','d',{'a',1,'W'; 'h1',-1,'SE'; 'h2',1,'SS'; 'h3',-1,'S'},4,0);
    D = wr(D,'d','G2',[4.25 0; 7.4 0]);
    D = blk(D,'G2','d','e','G2',8.2,0,'G_2(s)');
    D = wr(D,'e','G3',[9 0; 9.6 0]);
    D = blk(D,'G3','e','Y','G3',10.4,0,'G_3(s)');
    D = wr(D,'Y','',[11.2 0; 12 0],false);
    D = wr(D,'Y','out',[12 0; 13 0]);
    D = lb(D,13.15,0,'Y(s)','',cY,'left');
    D = dt(D,12,0); D = dt(D,12,-1.5); D = dt(D,12,-3);
    D = feedbackRows(D,{'H1','H2','H3'},{'h1','h2','h3'},[-1.5 -3 -4.5],8.2,12, ...
        [5.0 4.2 -0.17; 4.4 4.08 -0.24; 4 4 -0.25]);
    D = finish(D,[-1.3 14.5],[-5.2 0.9]);
    steps{end+1} = struct('D',D,'title','(a) Collapse the summing junctions', ...
        'desc','(a) Collapse the summing junctions into a single summing junction (keeping each sign).', ...
        'tex','?');
    % (b) cascade and parallel
    D = newDiagram();
    D = lb(D,0,0,'R(s)','',cR,'right');
    D = wr(D,'R','G1',[0.15 0; 1.2 0]);
    D = blk(D,'G1','R','a','G1',2,0,'G_1(s)');
    D = wr(D,'a','s',[2.8 0; 3.75 0]);
    D = sm(D,'s','d',{'a',1,'W'; 'f',-1,'S'},4,0);
    D = wr(D,'d','G',[4.25 0; 5.8 0]);
    D = blk(D,'G','d','Y','G2*G3',7,0,'G_2(s)G_3(s)',2.4);
    D = wr(D,'Y','',[8.2 0; 9.4 0],false);
    D = dt(D,9.4,0);
    D = wr(D,'Y','out',[9.4 0; 10.6 0]);
    D = lb(D,10.75,0,'Y(s)','',cY,'left');
    D = wr(D,'Y','H',[9.4 0; 9.4 -1.6; 8.6 -1.6]);
    D = blk(D,'H','Y','f','H1-H2+H3',7,-1.6,'H_1(s)-H_2(s)+H_3(s)',3.2);
    D = wr(D,'f','s',[5.4 -1.6; 4 -1.6; 4 -0.25]);
    D = finish(D,[-1.3 12],[-2.5 0.9]);
    steps{end+1} = struct('D',D,'title','(b) Cascade forward path, parallel feedback path', ...
        'desc','(b) Form the equivalent cascaded system in the forward path, G₂G₃, and the equivalent parallel system in the feedback path, H₁ − H₂ + H₃.', ...
        'tex','?');
    % (c) single block
    D = singleBlock('G1*G2*G3/(1+G2*G3*(H1-H2+H3))', ...
        '\frac{G_1(s)G_2(s)G_3(s)}{1+G_2(s)G_3(s)[H_1(s)-H_2(s)+H_3(s)]}',8.4);
    steps{end+1} = struct('D',D,'title','(c) Feedback form, times the cascaded G_1', ...
        'desc','(c) Apply the feedback form L/(1 + LH) and multiply by the cascaded G₁(s).', ...
        'tex','\frac{G_1G_2G_3}{1+G_2G_3(H_1-H_2+H_3)}');
else
    % Original (Fig 3.18)
    D = newDiagram();
    D = lb(D,-0.3,0,'R(s)','',cR,'right');
    D = wr(D,'R','s1',[-0.15 0; 0.75 0]);
    D = sm(D,'s1','V1',{'R',1,'W'; 'V6',-1,'S'},1,0);
    D = wr(D,'V1','G1',[1.25 0; 2 0]);
    D = lb(D,1.62,0.35,'V_1','',[],'center',12);
    D = blk(D,'G1','V1','V2','G1',2.8,0,'G_1(s)');
    D = wr(D,'V2','s2',[3.6 0; 4.35 0]);
    D = lb(D,3.97,0.35,'V_2','',[],'center',12);
    D = sm(D,'s2','V3',{'V2',1,'W'; 'V7',-1,'S'},4.6,0);
    D = wr(D,'V3','',[4.85 0; 5.4 0],false);
    D = lb(D,5.15,0.35,'V_3','',[],'center',12);
    D = dt(D,5.4,0);
    D = wr(D,'V3','G2',[5.4 0; 5.8 0]);
    D = blk(D,'G2','V3','V4','G2',6.6,0,'G_2(s)');
    D = wr(D,'V3','s3',[5.4 0; 5.4 1.1; 9.2 1.1; 9.2 0.25]);
    D = wr(D,'V4','',[7.4 0; 8.2 0],false);
    D = lb(D,7.8,0.35,'V_4','',[],'center',12);
    D = dt(D,8.2,0); D = dt(D,8.2,-1.5);
    D = wr(D,'V4','s3',[8.2 0; 8.95 0]);
    D = sm(D,'s3','V5',{'V4',1,'W'; 'V3',1,'N'; 'V8',-1,'S'},9.2,0);
    D = wr(D,'V5','G3',[9.45 0; 10 0]);
    D = blk(D,'G3','V5','Y','G3',10.8,0,'G_3(s)');
    D = wr(D,'Y','',[11.6 0; 12.2 0],false);
    D = dt(D,12.2,0);
    D = wr(D,'Y','out',[12.2 0; 13.2 0]);
    D = lb(D,13.35,0,'Y(s)','',cY,'left');
    D = wr(D,'V4','H2',[8.2 0; 8.2 -1.5; 7.4 -1.5]);
    D = blk(D,'H2','V4','V7','H2',6.6,-1.5,'H_2(s)');
    D = wr(D,'V7','s2',[5.8 -1.5; 4.6 -1.5; 4.6 -0.25]);
    D = wr(D,'V4','H1',[8.2 -1.5; 8.2 -3; 3.6 -3]);
    D = blk(D,'H1','V4','V6','H1',2.8,-3,'H_1(s)');
    D = wr(D,'V6','s1',[2 -3; 1 -3; 1 -0.25]);
    D = wr(D,'Y','H3',[12.2 0; 12.2 -1.5; 11.6 -1.5]);
    D = blk(D,'H3','Y','V8','H3',10.8,-1.5,'H_3(s)');
    D = wr(D,'V8','s3',[10 -1.5; 9.2 -1.5; 9.2 -0.25]);
    D = finish(D,[-1.6 14.6],[-3.7 1.6]);
    steps{end+1} = struct('D',D,'title','Example 2: original (Fig 3.18)', ...
        'desc','Nested loops plus a feedforward path from V₃ around G₂; the familiar forms cannot be applied directly.', ...
        'tex','?');
    % (a) G2 backwards past the V3 pickoff; G3/H3 loop reduced
    D = newDiagram();
    D = lb(D,-0.3,0,'R(s)','',cR,'right');
    D = wr(D,'R','s1',[-0.15 0; 0.75 0]);
    D = sm(D,'s1','V1',{'R',1,'W'; 'V6',-1,'S'},1,0);
    D = wr(D,'V1','G1',[1.25 0; 2 0]);
    D = blk(D,'G1','V1','V2','G1',2.8,0,'G_1(s)');
    D = wr(D,'V2','s2',[3.6 0; 4.35 0]);
    D = sm(D,'s2','V3',{'V2',1,'W'; 'V7',-1,'S'},4.6,0);
    D = wr(D,'V3','G2',[4.85 0; 5.6 0]);
    D = blk(D,'G2','V3','V4','G2',6.4,0,'G_2(s)');
    D = wr(D,'V4','',[7.2 0; 8.6 0],false);
    D = lb(D,7.5,0.35,'V_4','',[],'center',12);
    D = dt(D,7.8,0); D = dt(D,8.6,0); D = dt(D,8.6,-1.5);
    D = wr(D,'V4','Gi',[7.8 0; 7.8 1.2; 8.5 1.2]);
    D = blk(D,'Gi','V4','w','1/G2',9.2,1.2,'\frac{1}{G_2(s)}',1.4,1.0);
    D = wr(D,'w','s3',[9.9 1.2; 10.4 1.2; 10.4 0.25]);
    D = wr(D,'V4','s3',[8.6 0; 10.15 0]);
    D = sm(D,'s3','V5',{'V4',1,'W'; 'w',1,'N'},10.4,0);
    D = wr(D,'V5','T3',[10.65 0; 11.1 0]);
    D = blk(D,'T3','V5','Y','G3/(1+G3*H3)',12.3,0,'\frac{G_3(s)}{1+G_3(s)H_3(s)}',2.4,1.1);
    D = wr(D,'Y','out',[13.5 0; 14.4 0]);
    D = lb(D,14.55,0,'Y(s)','',cY,'left');
    D = wr(D,'V4','H2',[8.6 0; 8.6 -1.5; 7.2 -1.5]);
    D = blk(D,'H2','V4','V7','H2',6.4,-1.5,'H_2(s)');
    D = wr(D,'V7','s2',[5.6 -1.5; 4.6 -1.5; 4.6 -0.25]);
    D = wr(D,'V4','H1',[8.6 -1.5; 8.6 -3; 3.6 -3]);
    D = blk(D,'H1','V4','V6','H1',2.8,-3,'H_1(s)');
    D = wr(D,'V6','s1',[2 -3; 1 -3; 1 -0.25]);
    D = finish(D,[-1.6 15.8],[-3.7 2]);
    steps{end+1} = struct('D',D,'title','(a) Move G_2 backwards past the pickoff; reduce the G_3/H_3 loop', ...
        'desc','(a) Move G₂(s) backwards past the pickoff point (the feedforward branch now passes through 1/G₂). The G₃/H₃ loop becomes G₃/(1 + G₃H₃), and a parallel system appears after V₄.', ...
        'tex','?');
    % (b) parallel after V4 simplified; G1 forwards over the s2 junction
    D = newDiagram();
    D = lb(D,-0.3,0,'R(s)','',cR,'right');
    D = wr(D,'R','s1',[-0.15 0; 0.75 0]);
    D = sm(D,'s1','V1',{'R',1,'W'; 'V6',-1,'S'},1,0);
    D = wr(D,'V1','s2',[1.25 0; 2.15 0]);
    D = sm(D,'s2','x',{'V1',1,'W'; 'V7',-1,'S'},2.4,0);
    D = wr(D,'x','G12',[2.65 0; 3.3 0]);
    D = blk(D,'G12','x','V4','G1*G2',4.2,0,'G_1(s)G_2(s)',1.8);
    D = wr(D,'V4','',[5.1 0; 5.8 0],false);
    D = lb(D,5.45,0.35,'V_4','',[],'center',12);
    D = dt(D,5.8,0); D = dt(D,5.8,-1.5);
    D = wr(D,'V4','Pp',[5.8 0; 6.5 0]);
    D = blk(D,'Pp','V4','V5','1/G2+1',7.5,0,'\frac{1}{G_2(s)}+1',2.0,1.0);
    D = wr(D,'V5','T3',[8.5 0; 9.0 0]);
    D = blk(D,'T3','V5','Y','G3/(1+G3*H3)',10.2,0,'\frac{G_3(s)}{1+G_3(s)H_3(s)}',2.4,1.1);
    D = wr(D,'Y','out',[11.4 0; 12.3 0]);
    D = lb(D,12.45,0,'Y(s)','',cY,'left');
    D = wr(D,'V4','H2G1',[5.8 0; 5.8 -1.5; 5.0 -1.5]);
    D = blk(D,'H2G1','V4','V7','H2/G1',4.2,-1.5,'\frac{H_2(s)}{G_1(s)}',1.6,1.0);
    D = wr(D,'V7','s2',[3.4 -1.5; 2.4 -1.5; 2.4 -0.25]);
    D = wr(D,'V4','H1',[5.8 -1.5; 5.8 -3; 5.0 -3]);
    D = blk(D,'H1','V4','V6','H1',4.2,-3,'H_1(s)');
    D = wr(D,'V6','s1',[3.4 -3; 1 -3; 1 -0.25]);
    D = finish(D,[-1.6 13.6],[-3.7 1]);
    steps{end+1} = struct('D',D,'title','(b) Simplify the parallel system; move G_1 forwards over the junction', ...
        'desc','(b) The parallel system after V₄ becomes 1/G₂ + 1. Moving G₁(s) forwards over the second summing junction makes the H₂ path H₂/G₁, and G₁G₂ is now cascaded.', ...
        'tex','?');
    % (c) collapse sums, parallel feedback, cascade the output blocks
    D = newDiagram();
    D = lb(D,-0.3,0,'R(s)','',cR,'right');
    D = wr(D,'R','s1',[-0.15 0; 0.75 0]);
    D = sm(D,'s1','x',{'R',1,'W'; 'f',-1,'S'},1,0);
    D = wr(D,'x','G12',[1.25 0; 2.0 0]);
    D = blk(D,'G12','x','V4','G1*G2',2.9,0,'G_1(s)G_2(s)',1.8);
    D = wr(D,'V4','',[3.8 0; 4.6 0],false);
    D = lb(D,4.2,0.35,'V_4','',[],'center',12);
    D = dt(D,4.6,0);
    D = wr(D,'V4','C',[4.6 0; 5.2 0]);
    D = blk(D,'C','V4','Y','(1/G2+1)*G3/(1+G3*H3)',7.8,0,'\left(\frac{1}{G_2(s)}+1\right)\frac{G_3(s)}{1+G_3(s)H_3(s)}',5.2,1.1);
    D = wr(D,'Y','out',[10.4 0; 11.3 0]);
    D = lb(D,11.45,0,'Y(s)','',cY,'left');
    D = wr(D,'V4','Hf',[4.6 0; 4.6 -1.6; 3.9 -1.6]);
    D = blk(D,'Hf','V4','f','H2/G1+H1',2.9,-1.6,'\frac{H_2(s)}{G_1(s)}+H_1(s)',2.0,1.0);
    D = wr(D,'f','s1',[1.9 -1.6; 1 -1.6; 1 -0.25]);
    D = finish(D,[-1.6 12.8],[-2.5 1]);
    steps{end+1} = struct('D',D,'title','(c) Collapse the junctions; sum the parallel feedback; cascade', ...
        'desc','(c) Collapse the summing junctions, sum the parallel feedback elements (H₂/G₁ + H₁) and simplify the cascaded subsystems after V₄.', ...
        'tex','?');
    % (d) feedback form
    D = newDiagram();
    D = lb(D,-0.3,0,'R(s)','',cR,'right');
    D = wr(D,'R','T1',[-0.15 0; 0.6 0]);
    D = blk(D,'T1','R','V4','G1*G2/(1+G2*H2+G1*G2*H1)',2.9,0,'\frac{G_1(s)G_2(s)}{1+G_2(s)H_2(s)+G_1(s)G_2(s)H_1(s)}',4.6,1.1);
    D = wr(D,'V4','C',[5.2 0; 6.0 0]);
    D = lb(D,5.6,0.4,'V_4','',[],'center',12);
    D = blk(D,'C','V4','Y','(1/G2+1)*G3/(1+G3*H3)',8.6,0,'\left(\frac{1}{G_2(s)}+1\right)\frac{G_3(s)}{1+G_3(s)H_3(s)}',5.2,1.1);
    D = wr(D,'Y','out',[11.2 0; 12.1 0]);
    D = lb(D,12.25,0,'Y(s)','',cY,'left');
    D = finish(D,[-1.6 13.6],[-1.2 1.2]);
    steps{end+1} = struct('D',D,'title','(d) Simplify the feedback structure', ...
        'desc','(d) Apply the feedback form to the loop around G₁G₂ with feedback H₂/G₁ + H₁.', ...
        'tex','?');
    % (e) single block
    D = singleBlock('G1*G3*(1+G2)/((1+G2*H2+G1*G2*H1)*(1+G3*H3))', ...
        '\frac{G_1(s)G_3(s)[1+G_2(s)]}{[1+G_2(s)H_2(s)+G_1(s)G_2(s)H_1(s)][1+G_3(s)H_3(s)]}',9.6);
    steps{end+1} = struct('D',D,'title','(e) Single transfer function', ...
        'desc','(e) Simplify the cascaded form to a single transfer function.', ...
        'tex','\frac{G_1G_3(1+G_2)}{(1+G_2H_2+G_1G_2H_1)(1+G_3H_3)}');
end
% Steps that are not yet a single block show the solved Y/R
for k = 1:numel(steps)
    if strcmp(steps{k}.tex,'?')
        steps{k}.tex = latex(simplify(solveTF(steps{k}.D,'R','Y')));
    end
end
end

function D = feedbackRows(D,ids,outs,ys,xb,xp,ends)
% Feedback blocks H_k fed from the output pickoff column at x = xp; block k
% returns along y = ys(k) to x = ends(k,1), then to the junction at ends(k,:).
for k = 1:numel(ids)
    if k == 1, y0 = 0; else, y0 = ys(k-1); end
    D = wr(D,'Y',ids{k},[xp y0; xp ys(k); xb+0.8 ys(k)]);
    D = blk(D,ids{k},'Y',outs{k},ids{k},xb,ys(k),sprintf('H_%d(s)',k));
    D = wr(D,outs{k},sumFor(D,outs{k}),[xb-0.8 ys(k); ends(k,1) ys(k); ends(k,2:3)]);
end
end

function id = sumFor(D,sig)
% Summing junction that takes signal sig as an input.
id = '';
for k = 1:numel(D.sums)
    if any(strcmp(D.sums{k}.in(:,1),sig)), id = D.sums{k}.id; return, end
end
end

function D = singleBlock(gain,tex,w)
cR = [0.85 0.33 0.10]; cY = [0.20 0.55 0.45];
D = newDiagram();
D = lb(D,0,0,'R(s)','',cR,'right');
D = wr(D,'R','T',[0.15 0; 1.2 0]);
D = blk(D,'T','R','Y',gain,1.2 + w/2,0,tex,w,1.3);
D = wr(D,'Y','out',[1.2 + w, 0; 2.4 + w, 0]);
D = lb(D,2.55 + w,0,'Y(s)','',cY,'left');
D = finish(D,[-1.3 3.9 + w],[-1.2 1.2]);
end

%% =========================================================================
%  Algebra: signal equations, paths and loops
%  =========================================================================
function [names,A,B,ext] = buildEquations(D)
% Signal equations x = Ax + Be from blocks (out = gain*in) and summing
% junctions (out = sum of signed inputs); undefined signals are external.
defs = {};  terms = {};            % terms{k}: rows of {input signal, gain}
for k = 1:numel(D.blocks)
    b = D.blocks{k};
    defs{end+1} = b.out;  terms{end+1} = {b.in, b.gain}; %#ok<AGROW>
end
for k = 1:numel(D.sums)
    s = D.sums{k};
    defs{end+1} = s.out; %#ok<AGROW>
    terms{end+1} = [s.in(:,1) cellfun(@sym,s.in(:,2),'UniformOutput',false)]; %#ok<AGROW>
end
names = unique(defs,'stable');
inputs = {};
for k = 1:numel(terms), inputs = [inputs terms{k}(:,1)']; end %#ok<AGROW>
ext = setdiff(unique(inputs,'stable'),names,'stable');
n = numel(names);  m = numel(ext);
A = sym(zeros(n));  B = sym(zeros(n,m));
for k = 1:numel(defs)
    i = find(strcmp(names,defs{k}));
    for j = 1:size(terms{k},1)
        src = terms{k}{j,1};  g = terms{k}{j,2};
        js = strcmp(names,src);
        if any(js)
            A(i,js) = A(i,js) + g;
        else
            B(i,strcmp(ext,src)) = B(i,strcmp(ext,src)) + g;
        end
    end
end
end

function T = solveTF(D,src,dst)
% Transfer function from external signal src to signal dst (others zero).
[names,A,B,ext] = buildEquations(D);
x = (eye(numel(names)) - A)\B(:,strcmp(ext,src));
T = x(strcmp(names,dst));
end

function y = solveOutput(D,out)
% Output signal in terms of all external signals (names used as symbols).
if isfield(D,'alias')
    k = find(strcmp(D.alias(:,1),out),1);
    if ~isempty(k), out = D.alias{k,2}; end
end
[names,A,B,ext] = buildEquations(D);
e = cellfun(@str2sym,ext(:));
if any(strcmp(ext,out))
    y = str2sym(out);
    return
end
x = (eye(numel(names)) - A)\(B*e);
y = x(strcmp(names,out));
end

function [paths,loops] = pathsAndLoops(D,src,dst)
% Forward paths src -> dst and feedback loops, as lists of edges with gains.
E = edgeList(D);
paths = {};
dfs(src,{},{src});
loops = {};
sigs = unique([cellfun(@(e) e.from,E,'UniformOutput',false) cellfun(@(e) e.to,E,'UniformOutput',false)]);
seen = {};
for k = 1:numel(sigs)
    cyc(sigs{k},sigs{k},{},{sigs{k}});
end
    function dfs(node,edges,visited)
        if strcmp(node,dst) && ~isempty(edges)
            paths{end+1} = makePath(edges); return
        end
        for q = 1:numel(E)
            if strcmp(E{q}.from,node) && ~any(strcmp(visited,E{q}.to))
                dfs(E{q}.to,[edges E(q)],[visited {E{q}.to}]);
            end
        end
    end
    function cyc(start,node,edges,visited)
        for q = 1:numel(E)
            if ~strcmp(E{q}.from,node), continue, end
            if strcmp(E{q}.to,start)
                key = strjoin(sort(cellfun(@(e) e.elem,[edges E(q)],'UniformOutput',false)),'|');
                if ~any(strcmp(seen,key))
                    seen{end+1} = key; %#ok<AGROW>
                    loops{end+1} = makePath([edges E(q)]); %#ok<AGROW>
                end
            elseif ~any(strcmp(visited,E{q}.to))
                cyc(start,E{q}.to,[edges E(q)],[visited {E{q}.to}]);
            end
        end
    end
end

function p = makePath(edges)
g = sym(1);
for k = 1:numel(edges), g = g*edges{k}.gain; end
p = struct('edges',{edges},'gain',simplify(g));
end

function E = edgeList(D)
E = {};
for k = 1:numel(D.blocks)
    b = D.blocks{k};
    E{end+1} = struct('from',b.in,'to',b.out,'gain',b.gain,'elem',b.id); %#ok<AGROW>
end
for k = 1:numel(D.sums)
    s = D.sums{k};
    for j = 1:size(s.in,1)
        E{end+1} = struct('from',s.in{j,1},'to',s.out,'gain',sym(s.in{j,2}),'elem',s.id); %#ok<AGROW>
    end
end
end

function H = elementsOf(paths,isLoop)
% Blocks/junctions, (signal > element) pairs, signals leaving an element and
% path end signals used by a list of paths (loops have no end signal).
H = struct('elems',{{}},'pairs',{{}},'from',{{}},'ends',{{}});
for k = 1:numel(paths)
    for j = 1:numel(paths{k}.edges)
        e = paths{k}.edges{j};
        H.elems{end+1} = e.elem;
        H.pairs{end+1} = [e.from '>' e.elem];
        H.from{end+1} = e.from;
    end
    if ~isLoop, H.ends{end+1} = paths{k}.edges{end}.to; end
end
end

function tf_ = isOn(id,sig,to,H)
% Is a block/junction (id), or a wire carrying sig into element to, used?
% to = 'out' is an output arrow; to = '' a shared trunk before a pickoff.
if ~isempty(id)
    tf_ = any(strcmp(H.elems,id));
elseif strcmp(to,'out')
    tf_ = any(strcmp(H.ends,sig));
elseif isempty(to)
    tf_ = any(strcmp(H.from,sig)) || any(strcmp(H.ends,sig));
else
    tf_ = any(strcmp(H.pairs,[sig '>' to]));
end
end

%% =========================================================================
%  Other helpers
%  =========================================================================
function Tnum = symToTF(T,vals)
% Substitute numerical transfer functions (expressions in s) and return a tf.
for k = 1:size(vals,1)
    T = subs(T,sym(vals{k,1}),str2sym(vals{k,2}));
end
T = simplify(T);
[n,d] = numden(T);
n = sym2poly(expand(n));  d = sym2poly(expand(d));
Tnum = minreal(tf(n/d(1),d/d(1)),1e-9);
end

function G = evalTF(str)
% Evaluate a MATLAB expression in s as a transfer function.
s = tf('s'); %#ok<NASGU>
G = eval(str);
if isnumeric(G), G = tf(G); end
end

function K = bodeGain(z,p,k)
% Gain of the Bode form K(1+s/a).../(1+s/b)... (the DC gain without the integrators/differentiators).
K = real(k*prod(-z(abs(z) > 1e-12))/prod(-p(abs(p) > 1e-12)));
end

function str = bodeStr(K,z,p)
% Transfer function in Bode form, e.g. 10*(1+s/2)/(s*(1+s/10)).
num = rootFactors(z);  den = rootFactors(p);
str = sprintf('%.4g',K);
if ~isempty(num), str = [str '*' strjoin(num,'*')]; end
if numel(den) == 1
    str = [str '/' den{1}];
elseif numel(den) > 1
    str = [str '/(' strjoin(den,'*') ')'];
end
end

function f = rootFactors(r)
f = {};
nI = sum(abs(r) <= 1e-12);
if nI == 1, f{end+1} = 's'; elseif nI > 1, f{end+1} = sprintf('s^%d',nI); end
for r1 = r(abs(r) > 1e-12).'
    if abs(imag(r1)) < 1e-9
        if real(r1) < 0, f{end+1} = sprintf('(1+s/%.4g)',-real(r1)); %#ok<AGROW>
        else,            f{end+1} = sprintf('(1-s/%.4g)',real(r1)); end %#ok<AGROW>
    elseif imag(r1) > 0
        wn = abs(r1);  c1 = -2*real(r1)/wn^2;
        if c1 >= 0, sg = '+'; else, sg = '-'; end
        f{end+1} = sprintf('(1%s%.4g*s+%.4g*s^2)',sg,abs(c1),1/wn^2); %#ok<AGROW>
    end
end
end

function L = tfLines(T)
[n,d] = tfdata(T,'v');
L = {sprintf('  num: %s',polyStr(n)); sprintf('  den: %s',polyStr(d))};
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

function s = signedSum(sg,names)
s = '';
for k = 1:numel(sg)
    if sg(k) < 0, op = '-'; elseif isempty(s), op = ''; else, op = '+'; end
    s = [s op names{k}]; %#ok<AGROW>
end
end

function t = outTex(name)
t = regexprep(name,'^Y(\d)$','Y_$1');
t = [t '(s)'];
end

function arrowHead(ax,p1,p2,col)
d = p2 - p1;  d = d/norm(d);  nrm = [-d(2) d(1)];
L = 0.24;  W = 0.10;
pts = [p2; p2 - L*d + W*nrm; p2 - L*d - W*nrm];
patch(ax,pts(:,1),pts(:,2),col,'EdgeColor',col);
end

function fitAxes(ax,xl,yl)
% Equal scaling, with the limits stretched to the axes shape so the diagram
% sits at the top of its area instead of floating in the middle.
ax.DataAspectRatio = [1 1 1];
drawnow
pos = getpixelposition(ax);
r = pos(4)/max(pos(3),1);
if diff(xl)*r > diff(yl)
    yl = [yl(2) - diff(xl)*r, yl(2)];
else
    xl = mean(xl) + [-0.5 0.5]*diff(yl)/r;
end
xlim(ax,xl);  ylim(ax,yl);
ax.XAxis.Visible = 'off';  ax.YAxis.Visible = 'off';
ax.XGrid = 'off';  ax.YGrid = 'off';
ax.Interactions = [];
ax.Toolbar.Visible = 'off';
end

function v = getfieldDefault(s,f,d)
if isfield(s,f), v = s.(f); else, v = d; end
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
ta.Value = {'Error:'; err.message; ''; ...
    'Block values are MATLAB expressions in s, e.g. 1/(1+s) or 5.'};
end
