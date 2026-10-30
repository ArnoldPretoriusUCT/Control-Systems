function Chapter1_IntroductionApp
%CHAPTER1_INTRODUCTIONAPP Interactive GUI for MEC3079S Chapter 1 — Introduction.
%
%   Run Chapter1_IntroductionApp to open the app. Five live simulations show
%   what control systems do, before any theory:
%     1. Elevator      (1.2.1): transient response, steady-state error and
%        stability, with passenger comfort and patience.
%     2. Toaster       (1.4.1): an open-loop timer against a closed-loop
%        colour sensor, with bread you cannot see in advance.
%     3. Toilet cistern (1.4.3): a timed valve (open loop) and a float valve
%        (closed loop) side by side, with changing water pressure.
%     4. Balance it    (1.2.2): keep an inverted pendulum upright yourself,
%        then let a feedback controller do it.
%     5. Cruise control (1.2.2, 1.5.3): hills, passengers and headwind;
%        a fixed pedal against cruise control, and the limits of the engine.
%
%   Each tab has a Scenario list, controls, a "Try this" list of challenges
%   and a scoreboard. Simulations run in real time; switching tabs pauses them.
%   Click a floor in the elevator shaft (or a level on its plot) to call the
%   elevator, and drag up/down on the cruise-control speed plot to change the
%   set speed while driving.
%
%   Requires the Control System Toolbox (for the pendulum controller).

cBlue   = [0.00 0.45 0.74];
cOrange = [0.85 0.33 0.10];
cGreen  = [0.47 0.67 0.19];
cRed    = [0.85 0.10 0.10];
cGrey   = [0.55 0.55 0.55];
cWater  = [0.35 0.65 0.95];
dtFrame = 0.04;                 % animation frame period (s)

fig = uifigure('Name','MEC3079S Chapter 1 — Introduction: control systems in action', ...
    'Position',[50 40 1340 860]);
mainGrid = uigridlayout(fig,[1 1],'Padding',[0 0 0 0]);
tg = uitabgroup(mainGrid);

%% =====================================================================
%  Tab 1: Elevator
%  =====================================================================
t1 = uitab(tg,'Title','Elevator');
g1 = uigridlayout(t1,[1 2],'ColumnWidth',{340,'1x'});
c1 = uigridlayout(g1,[14 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{80,22,22,22,22,22,22,22,96,'fit',22,'1x',22,0});
at(uilabel(c1,'Text',['Press a floor button. A good elevator is quick (patience), smooth (comfort) ' ...
    'and stops exactly level with the floor (steady-state error). Adjust the controller and see ' ...
    'what the passengers think.'],'FontWeight','bold','WordWrap','on'),1,[1 2]);
% name, mode (1 feedback, 2 timed), speed, smoothness, motor limit, passengers
presets1 = { ...
    'Comfortable ride',                 1, 6,  7, 1.0, 4
    'In a hurry',                       1, 10, 6, 3.0, 4
    'Wobbly: too little damping',       1, 5,  3,   2.0, 4
    'Unstable: no damping at all',      1, 6,  0, 2.0, 4
    'Sluggish',                         1, 1,  9, 1.0, 4
    'No sensor (timed motor), empty',   2, 4,  7, 1.0, 0
    'No sensor (timed motor), full',    2, 4,  7, 1.0, 12
    'Custom', [], [], [], [], []};
modes1 = {'Feedback: position sensor on','No feedback: timed motor'};
at(uilabel(c1,'Text','Scenario'),2,1);
dd1 = at(uidropdown(c1,'Items',presets1(:,1)','Value',presets1{1,1}),2,2);
at(uilabel(c1,'Text','Control'),3,1);
dd1M = at(uidropdown(c1,'Items',modes1),3,2);
at(uilabel(c1,'Text','Speed'),4,1);
sl1S = at(uislider(c1,'Limits',[1 10],'Value',4,'MajorTicks',[],'MinorTicks',[]),4,2);
at(uilabel(c1,'Text','Smoothness'),5,1);
sl1D = at(uislider(c1,'Limits',[0 10],'Value',7,'MajorTicks',[],'MinorTicks',[]),5,2);
at(uilabel(c1,'Text','Motor strength'),6,1);
sl1A = at(uislider(c1,'Limits',[0.5 3],'Value',1,'MajorTicks',[],'MinorTicks',[]),6,2);
at(uilabel(c1,'Text','Passengers'),7,1);
sl1P = at(uislider(c1,'Limits',[0 12],'Value',4,'MajorTicks',[],'MinorTicks',[]),7,2);
at(uilabel(c1,'Text','Call the elevator:','FontWeight','bold'),8,[1 2]);
gBtn = at(uigridlayout(c1,[2 4],'Padding',[0 0 0 0],'RowSpacing',4,'ColumnSpacing',4),9,[1 2]);
btn1F = gobjects(1,6);
for f = 6:-1:1
    btn1F(f) = uibutton(gBtn,'Text',sprintf('%d',f),'FontSize',20,'FontWeight','bold');
    btn1F(f).Layout.Row = 1 + (f <= 3);
    btn1F(f).Layout.Column = mod(f - 1,3) + 1;
end
btn1R = uibutton(gBtn,'Text','Reset');  btn1R.Layout.Row = [1 2];  btn1R.Layout.Column = 4;
lbl1Score = at(uilabel(c1,'Text','','FontSize',16,'WordWrap','on'),10,[1 2]);
at(uilabel(c1,'Text','Try this','FontWeight','bold'),11,[1 2]);
ta1 = at(uitextarea(c1,'Editable','off','Value',{ ...
    '• Ride from floor 1 to 6 in under 12 s with'; '  everyone 😀 (max acceleration < 1 m/s²).'; ...
    '• Turn the smoothness down: why does it wobble?'; '  What happens at 0?'; ...
    '• Switch the sensor off and add passengers.'; '  Does it still stop at the floor?'; ...
    '• Feedback mode: does the number of passengers'; '  change where it stops?'}),12,[1 2]);
at(uilabel(c1,'Text','Speed = how hard it chases the floor; smoothness = damping.','FontAngle','italic','WordWrap','on'),13,[1 2]);

r1 = uigridlayout(g1,[2 2],'RowHeight',{'1x','1x'},'ColumnWidth',{300,'1x'});
ax1s = at(uiaxes(r1),[1 2],1);
ax1x = at(uiaxes(r1),1,2);
ax1a = at(uiaxes(r1),2,2);
[ax1s.Interactions, ax1x.Interactions, ax1a.Interactions] = deal([]);

%% =====================================================================
%  Tab 2: Toaster
%  =====================================================================
t2 = uitab(tg,'Title','Toaster');
g2 = uigridlayout(t2,[1 2],'ColumnWidth',{340,'1x'});
c2 = uigridlayout(g2,[13 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{80,22,22,22,22,22,22,22,44,'fit',22,'1x',22});
at(uilabel(c2,'Text',['A normal toaster is open loop: you set a time and hope. A smart toaster ' ...
    'watches the colour of the toast (feedback) and pops it when it is done. Try both, especially ' ...
    'with surprise bread.'],'FontWeight','bold','WordWrap','on'),1,[1 2]);
breads = struct('name',{'White','Brown','Rye','Sourdough'},'rate',{1.0,0.8,0.6,0.9}, ...
    'raw',{[0.97 0.93 0.80],[0.80 0.65 0.45],[0.62 0.48 0.33],[0.93 0.87 0.72]});
shades = {'Light',0.35;'Golden',0.5;'Dark',0.7};
% name, mode (1 timer, 2 sensor), bread, thickness, minutes, target, surprise
presets2 = { ...
    'Timer, white bread (it was set for this)', 1, 1, 2,   2.5, 2, false
    'Timer, thick rye',                         1, 3, 3,   2.5, 2, false
    'Timer, thin white',                        1, 1, 1.2, 2.5, 2, false
    'Timer, surprise bread',                    1, 1, 2,   2.5, 2, true
    'Colour sensor, surprise bread',            2, 1, 2,   2.5, 2, true
    'Colour sensor, dark toast please',         2, 1, 2,   2.5, 3, true
    'Custom', [], [], [], [], [], []};
modes2 = {'Timer (open loop)','Colour sensor (closed loop)'};
at(uilabel(c2,'Text','Scenario'),2,1);
dd2 = at(uidropdown(c2,'Items',presets2(:,1)','Value',presets2{1,1}),2,2);
at(uilabel(c2,'Text','Toaster'),3,1);
dd2M = at(uidropdown(c2,'Items',modes2),3,2);
at(uilabel(c2,'Text','Bread'),4,1);
dd2B = at(uidropdown(c2,'Items',{breads.name}),4,2);
at(uilabel(c2,'Text','Thickness (cm)'),5,1);
sl2T = at(uislider(c2,'Limits',[1 3],'Value',2,'MajorTicks',[1 2 3],'MinorTicks',[]),5,2);
lbl2Time = at(uilabel(c2,'Text','Timer (min)'),6,1);
sl2Time = at(uislider(c2,'Limits',[0.5 5],'Value',2.5,'MajorTicks',1:5,'MinorTicks',[]),6,2);
at(uilabel(c2,'Text','I want my toast'),7,1);
dd2S = at(uidropdown(c2,'Items',shades(:,1)','Value','Golden'),7,2);
cb2Sur = at(uicheckbox(c2,'Text','Surprise bread (type and thickness unknown)'),8,[1 2]);
btn2Go = at(uibutton(c2,'Text','Toast! 🔥','FontSize',20,'FontWeight','bold'),9,[1 2]);
lbl2Score = at(uilabel(c2,'Text','','FontSize',16,'WordWrap','on'),10,[1 2]);
at(uilabel(c2,'Text','Toast history','FontWeight','bold'),11,[1 2]);
ta2 = at(uitextarea(c2,'Editable','off','FontName','Monospaced','Value',{'(no toast yet)'}),12,[1 2]);
at(uilabel(c2,'Text','Try: 5 surprise toasts with the timer, then 5 with the sensor.','FontAngle','italic','WordWrap','on'),13,[1 2]);

r2 = uigridlayout(g2,[1 2],'ColumnWidth',{'1.2x','1x'});
ax2s = uiaxes(r2);
ax2b = uiaxes(r2);
[ax2s.Interactions, ax2b.Interactions] = deal([]);

%% =====================================================================
%  Tab 3: Toilet cistern
%  =====================================================================
t3 = uitab(tg,'Title','Toilet cistern');
g3 = uigridlayout(t3,[1 2],'ColumnWidth',{340,'1x'});
c3 = uigridlayout(g3,[9 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{96,22,22,44,'fit',22,'1x',22,0});
at(uilabel(c3,'Text',['Two cisterns are flushed at the same time. The left one opens its valve for a ' ...
    'fixed time, calculated for normal water pressure (open loop). The right one has a ball float ' ...
    'that closes the valve when the water reaches the right level (closed loop). Change the pressure, ' ...
    'e.g. someone is showering, and flush again.'],'FontWeight','bold','WordWrap','on'),1,[1 2]);
presets3 = { ...
    'Normal pressure',                 1.0
    'Someone is showering (low)',      0.55
    'Garden hose and shower (very low)', 0.35
    'Pressure higher than expected',   1.4
    'Custom', []};
at(uilabel(c3,'Text','Scenario'),2,1);
dd3 = at(uidropdown(c3,'Items',presets3(:,1)','Value',presets3{2,1}),2,2);
at(uilabel(c3,'Text','Supply pressure'),3,1);
sl3P = at(uislider(c3,'Limits',[0.3 1.5],'Value',0.55,'MajorTicks',[0.5 1 1.5], ...
    'MajorTickLabels',{'low','normal','high'},'MinorTicks',[]),3,2);
btn3Go = at(uibutton(c3,'Text','Flush both! 🌊','FontSize',20,'FontWeight','bold'),4,[1 2]);
lbl3Score = at(uilabel(c3,'Text','','FontSize',15,'WordWrap','on'),5,[1 2]);
at(uilabel(c3,'Text','Try this','FontWeight','bold'),6,[1 2]);
ta3 = at(uitextarea(c3,'Editable','off','Value',{ ...
    '• Flush at normal pressure: both work.'; ...
    '• Lower the pressure: which cistern still'; '  fills to the line? Which is quicker?'; ...
    '• Raise the pressure: where does the extra'; '  water go?'; ...
    '• The float costs money. When would the'; '  timer be good enough?'}),7,[1 2]);

r3 = uigridlayout(g3,[2 2],'RowHeight',{'1.3x','1x'},'ColumnWidth',{'1x','1x'});
ax3o = at(uiaxes(r3),1,1);
ax3c = at(uiaxes(r3),1,2);
ax3h = at(uiaxes(r3),2,[1 2]);
[ax3o.Interactions, ax3c.Interactions, ax3h.Interactions] = deal([]);

%% =====================================================================
%  Tab 4: Balance it (inverted pendulum)
%  =====================================================================
t4 = uitab(tg,'Title','Balance it');
g4 = uigridlayout(t4,[1 2],'ColumnWidth',{340,'1x'});
c4 = uigridlayout(g4,[13 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{96,22,22,22,22,22,44,44,'fit',22,'1x',22,0});
at(uilabel(c4,'Text',['An upright pole on a cart is unstable: on its own it falls. Move the mouse ' ...
    'left and right over the track to move the cart and keep the pole up. Then hand over to the ' ...
    'feedback controller, which measures the angle 100s of times per second, and poke it.'], ...
    'FontWeight','bold','WordWrap','on'),1,[1 2]);
whos4 = {'You (move the mouse)','Feedback controller','Nobody'};
gravs = {'Earth (9.81)',9.81;'Mars (3.71)',3.71;'Moon (1.62)',1.62};
% name, who, length, gravity, strength
presets4 = { ...
    'You, on the Moon (easy)',                1, 2.5, 3, 5
    'You, on Earth (hard!)',                  1, 1.5, 1, 5
    'Nobody in control',                      3, 1.5, 1, 5
    'Feedback controller',                    2, 1.5, 1, 5
    'Feedback controller, short pole',        2, 0.5, 1, 7
    'Gentle controller (weak feedback)',      2, 1.5, 1, 1.5
    'Custom', [], [], [], []};
at(uilabel(c4,'Text','Scenario'),2,1);
dd4 = at(uidropdown(c4,'Items',presets4(:,1)','Value',presets4{1,1}),2,2);
at(uilabel(c4,'Text','Who is in control?'),3,1);
dd4W = at(uidropdown(c4,'Items',whos4),3,2);
at(uilabel(c4,'Text','Pole length (m)'),4,1);
sl4L = at(uislider(c4,'Limits',[0.5 3],'Value',2.5,'MajorTicks',[],'MinorTicks',[]),4,2);
at(uilabel(c4,'Text','Gravity'),5,1);
dd4G = at(uidropdown(c4,'Items',gravs(:,1)'),5,2);
at(uilabel(c4,'Text','Controller strength'),6,1);
sl4K = at(uislider(c4,'Limits',[1 10],'Value',5,'MajorTicks',[],'MinorTicks',[]),6,2);
g4b = at(uigridlayout(c4,[1 2],'Padding',[0 0 0 0]),7,[1 2]);
btn4Go = uibutton(g4b,'Text','Start ▶','FontSize',18,'FontWeight','bold');
btn4Poke = uibutton(g4b,'Text','Poke! 👉','FontSize',18,'FontWeight','bold');
lbl4Time = at(uilabel(c4,'Text','0.0 s','FontSize',30,'FontWeight','bold','HorizontalAlignment','center'),8,[1 2]);
lbl4Score = at(uilabel(c4,'Text','','FontSize',15,'WordWrap','on'),9,[1 2]);
at(uilabel(c4,'Text','Try this','FontWeight','bold'),10,[1 2]);
ta4 = at(uitextarea(c4,'Editable','off','Value',{ ...
    '• Balance for 20 s on the Moon. Then Earth.'; ...
    '• Is a long pole or a short pole easier?'; '  (Try balancing a pencil and a broom.)'; ...
    '• Let the controller balance it and poke it.'; ...
    '• With the controller on, move the mouse: the'; '  cart follows, but which way does it go first?'; ...
    '• Make the controller too gentle. What happens?'}),11,[1 2]);
at(uilabel(c4,'Text','The controller here is the kind you will design in this course.','FontAngle','italic','WordWrap','on'),12,[1 2]);

r4 = uigridlayout(g4,[2 1],'RowHeight',{'2x','1x'});
ax4s = uiaxes(r4);
ax4p = uiaxes(r4);
[ax4s.Interactions, ax4p.Interactions] = deal([]);
ax4s.Toolbar.Visible = 'off';

%% =====================================================================
%  Tab 5: Cruise control
%  =====================================================================
t5 = uitab(tg,'Title','Cruise control');
g5 = uigridlayout(t5,[1 2],'ColumnWidth',{340,'1x'});
c5 = uigridlayout(g5,[15 2],'ColumnWidth',{110,'1x'}, ...
    'RowHeight',{80,22,22,22,22,22,22,22,22,44,'fit',22,'1x',22,0});
at(uilabel(c5,'Text',['Drive over hills with passengers and a headwind. With a fixed pedal (open ' ...
    'loop) the speed wanders; cruise control (feedback) measures the speed and adjusts the throttle. ' ...
    'The engine has limits, though.'],'FontWeight','bold','WordWrap','on'),1,[1 2]);
modes5 = {'Fixed pedal (open loop)','Cruise control (feedback)'};
engines = {'Corolla (90 kW)',90e3;'Sports car (300 kW)',300e3;'Rocket (unlimited)',1e9};
% name, mode, set speed, passengers, hills, wind, aggressiveness, engine
presets5 = { ...
    'Fixed pedal on a flat road',            1, 100, 1, false, 0,  5, 1
    'Fixed pedal, hills and passengers',     1, 100, 4, true,  0,  5, 1
    'Cruise control, hills and passengers',  2, 100, 4, true,  0,  5, 1
    'Cruise control, gentle',                2, 100, 4, true,  0,  1, 1
    'Cruise control, aggressive',            2, 100, 4, true,  0,  10, 1
    'Headwind of 40 km/h',                   2, 100, 1, false, 40, 5, 1
    'Custom', [], [], [], [], [], [], []};
at(uilabel(c5,'Text','Scenario'),2,1);
dd5 = at(uidropdown(c5,'Items',presets5(:,1)','Value',presets5{3,1}),2,2);
at(uilabel(c5,'Text','Control'),3,1);
dd5M = at(uidropdown(c5,'Items',modes5),3,2);
at(uilabel(c5,'Text','Set speed (km/h)'),4,1);
sl5V = at(uislider(c5,'Limits',[40 160],'Value',100,'MajorTicks',40:40:160,'MinorTicks',[]),4,2);
at(uilabel(c5,'Text','Passengers'),5,1);
sl5P = at(uislider(c5,'Limits',[1 5],'Value',4,'MajorTicks',1:5,'MinorTicks',[]),5,2);
at(uilabel(c5,'Text','Headwind (km/h)'),6,1);
sl5W = at(uislider(c5,'Limits',[-20 60],'Value',0,'MajorTicks',[-20 0 20 40 60],'MinorTicks',[]),6,2);
at(uilabel(c5,'Text','Aggressiveness'),7,1);
sl5K = at(uislider(c5,'Limits',[1 10],'Value',5,'MajorTicks',[],'MinorTicks',[]),7,2);
at(uilabel(c5,'Text','Engine'),8,1);
dd5E = at(uidropdown(c5,'Items',engines(:,1)'),8,2);
cb5H = at(uicheckbox(c5,'Text','Hilly road','Value',true),9,[1 2]);
g5b = at(uigridlayout(c5,[1 2],'Padding',[0 0 0 0]),10,[1 2]);
btn5Go = uibutton(g5b,'Text','Drive ▶','FontSize',18,'FontWeight','bold');
btn5L = uibutton(g5b,'Text','0→100 launch 🏁','FontSize',16,'FontWeight','bold');
lbl5Score = at(uilabel(c5,'Text','','FontSize',15,'WordWrap','on'),11,[1 2]);
at(uilabel(c5,'Text','Try this','FontWeight','bold'),12,[1 2]);
ta5 = at(uitextarea(c5,'Editable','off','Value',{ ...
    '• Fixed pedal on the hills: how far does the'; '  speed drift? Now switch cruise control on.'; ...
    '• Add passengers or headwind. Which mode'; '  copes without you changing anything?'; ...
    '• Launch 0→100 with the Corolla, then with'; '  a more aggressive controller. Faster?'; ...
    '• Now try the rocket. Why is that cheating?'}),13,[1 2]);
at(uilabel(c5,'Text','The throttle plot is the "control action": it can never exceed 100%.','FontAngle','italic','WordWrap','on'),14,[1 2]);

r5 = uigridlayout(g5,[2 3],'RowHeight',{'1.2x','1x'},'ColumnWidth',{'1x','1x','0.75x'});
ax5r = at(uiaxes(r5),1,[1 2]);
ax5g = at(uiaxes(r5),1,3);
ax5v = at(uiaxes(r5),2,[1 2]);
ax5u = at(uiaxes(r5),2,3);
[ax5r.Interactions, ax5g.Interactions, ax5v.Interactions, ax5u.Interactions] = deal([]);

%% =====================================================================
%  Simulation state, timers and wiring
%  =====================================================================
el = struct();  ts = struct();  cs = struct();  pd = struct();  cr = struct();
gfx1 = struct(); gfx2 = struct(); gfx3 = struct(); gfx4 = struct(); gfx5 = struct();
hist2 = {};  best4 = 0;
lastTick = repmat(tic,1,5);  frameDt = dtFrame;     % frames step by the real elapsed time

stepFcns = {@stepElevator,@stepToaster,@stepCistern,@stepPendulum,@stepCruise};
tas = [ta1 ta2 ta3 ta4 ta5];
timers = timer.empty;
for q = 1:5
    timers(q) = timer('ExecutionMode','fixedSpacing','Period',dtFrame,'BusyMode','drop', ...
        'TimerFcn',@(~,~) safeStep(q),'Name',sprintf('Ch1App%d',q));
end
fig.CloseRequestFcn = @(~,~) closeApp();
tg.SelectionChangedFcn = @(~,~) pauseAll();
fig.WindowButtonMotionFcn = @(~,~) [];          % keeps CurrentPoint up to date for tab 4

% Tab 1 wiring
dd1.ValueChangedFcn = @(~,~) loadPreset1();
[dd1M.ValueChangedFcn, sl1S.ValueChangedFcn, sl1D.ValueChangedFcn, sl1A.ValueChangedFcn, ...
    sl1P.ValueChangedFcn] = deal(@(~,~) custom1());
for f = 1:6, btn1F(f).ButtonPushedFcn = @(~,~) callFloor(f); end
btn1R.ButtonPushedFcn = @(~,~) resetElevator();
ax1s.ButtonDownFcn = @(~,~) clickFloor(ax1s,@(y) round(y/3) + 1);   % click a floor in the shaft
ax1x.ButtonDownFcn = @(~,~) clickFloor(ax1x,@(y) round(y));         % or a level on the plot
% Tab 2 wiring
dd2.ValueChangedFcn = @(~,~) loadPreset2();
[dd2M.ValueChangedFcn, dd2B.ValueChangedFcn, sl2T.ValueChangedFcn, sl2Time.ValueChangedFcn, ...
    dd2S.ValueChangedFcn, cb2Sur.ValueChangedFcn] = deal(@(~,~) custom2());
btn2Go.ButtonPushedFcn = @(~,~) startToast();
% Tab 3 wiring
dd3.ValueChangedFcn = @(~,~) loadPreset3();
sl3P.ValueChangedFcn = @(~,~) set(dd3,'Value','Custom');
btn3Go.ButtonPushedFcn = @(~,~) flushBoth();
% Tab 4 wiring
dd4.ValueChangedFcn = @(~,~) loadPreset4();
[dd4W.ValueChangedFcn, sl4L.ValueChangedFcn, dd4G.ValueChangedFcn, sl4K.ValueChangedFcn] = deal(@(~,~) custom4());
btn4Go.ButtonPushedFcn = @(~,~) startPendulum();
btn4Poke.ButtonPushedFcn = @(~,~) pokePendulum();
% Tab 5 wiring
dd5.ValueChangedFcn = @(~,~) loadPreset5();
[dd5M.ValueChangedFcn, sl5V.ValueChangedFcn, sl5P.ValueChangedFcn, sl5W.ValueChangedFcn, ...
    sl5K.ValueChangedFcn, dd5E.ValueChangedFcn] = deal(@(~,~) custom5());
cb5H.ValueChangedFcn = @(~,~) setHills5();
btn5Go.ButtonPushedFcn = @(~,~) toggleDrive();
btn5L.ButtonPushedFcn = @(~,~) launch5();
ax5v.ButtonDownFcn = @(~,~) dragSpeed5();      % drag the set speed on the speed plot

% Initial scenes
loadPreset1(); loadPreset2(); loadPreset3(); loadPreset4(); loadPreset5();

%% =====================================================================
%  Timer management
%  =====================================================================
    function safeStep(q)
        if ~isvalid(fig), return, end
        try
            frameDt = min(max(toc(lastTick(q)),0.005),0.1);
            lastTick(q) = tic;
            stepFcns{q}();
        catch err
            stop(timers(q));
            tas(q).Value = {'Simulation stopped:'; err.message};
        end
    end

    function run(q)
        for k = 1:numel(timers)
            if k ~= q && strcmp(timers(k).Running,'on'), stop(timers(k)); end
        end
        if strcmp(timers(q).Running,'off'), lastTick(q) = tic; start(timers(q)); end
    end

    function pauseAll()
        for k = 1:numel(timers)
            if isvalid(timers(k)) && strcmp(timers(k).Running,'on'), stop(timers(k)); end
        end
        btn5Go.Text = 'Drive ▶';
    end

    function closeApp()
        for k = 1:numel(timers)
            if isvalid(timers(k)), stop(timers(k)); delete(timers(k)); end
        end
        delete(fig);
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
%  Tab 1: Elevator
%  =====================================================================
    function loadPreset1()
        k = find(strcmp(presets1(:,1),dd1.Value));
        if isempty(presets1{k,2}), return, end
        dd1M.Value = modes1{presets1{k,2}};
        [sl1S.Value, sl1D.Value, sl1A.Value, sl1P.Value] = presets1{k,3:6};
        resetElevator();
    end

    function custom1()
        dd1.Value = 'Custom';
        drawShaft();
    end

    function resetElevator()
        stop(timers(1));
        el = struct('x',0,'v',0,'F',0,'r',0,'t',0,'tStart',0,'maxA',0,'arrived',true, ...
            'crashed',false,'prof',[],'log',[0 0 0 0],'from',1,'to',1,'msg','Press a floor button.');
        drawShaft();
        lbl1Score.Text = el.msg;
    end

    function clickFloor(ax,floorOf)
        cp = ax.CurrentPoint(1,1:2);
        if isstruct(fig.UserData) && isfield(fig.UserData,'TestPoint'), cp = fig.UserData.TestPoint; end
        callFloor(min(max(floorOf(cp(2)),1),6));
    end

    function dragSpeed5()
        % While the button is held, the set speed follows the mouse on the speed plot.
        setSpeed5();
        fig.WindowButtonMotionFcn = @(~,~) setSpeed5();
        fig.WindowButtonUpFcn = @(~,~) endSpeed5();
    end

    function setSpeed5()
        cp = ax5v.CurrentPoint(1,1:2);
        if isstruct(fig.UserData) && isfield(fig.UserData,'TestPoint'), cp = fig.UserData.TestPoint; end
        sl5V.Value = min(max(round(cp(2)/5)*5,40),160);
        custom5();
    end

    function endSpeed5()
        fig.WindowButtonMotionFcn = @(~,~) [];
        fig.WindowButtonUpFcn = '';
    end

    function callFloor(f)
        if el.crashed, resetElevator(); end
        el.to = f;  el.from = round(el.x/3) + 1;
        el.r = 3*(f - 1);
        el.tStart = el.t;  el.maxA = 0;  el.arrived = false;
        if strcmp(dd1M.Value,modes1{2})
            % Timed motor: accelerate then brake for times worked out for the nominal load
            mn = 4000 + 80*4;  D = el.r - el.x;
            F0 = mn*min(1,sl1A.Value);
            t1 = sqrt(abs(D)*mn/F0);
            el.prof = [el.t t1 sign(D) F0];
            el.v = 0;
        else
            el.prof = [];
        end
        btn1F(f).BackgroundColor = [1 0.85 0.4];
        lbl1Score.Text = sprintf('Going to floor %d…',f);
        run(1);
    end

    function stepElevator()
        nSub = 8;  h = frameDt/nSub;
        n = round(sl1P.Value);  m = 4000 + 80*n;  mn = 4000 + 80*4;   % car + counterweight inertia
        wn = 0.2*sl1S.Value;  zeta = 0.12*sl1D.Value;  aMax = sl1A.Value;  tau = 0.25;  b = 40;
        vMax = 2.5;                                                   % cruising speed of the lift
        timed = ~isempty(el.prof);
        for q = 1:nSub
            if timed
                tt = el.t - el.prof(1);  t1 = el.prof(2);
                if tt < t1, el.F = el.prof(3)*el.prof(4);
                elseif tt < 2*t1, el.F = -el.prof(3)*el.prof(4);
                else, el.F = 0; end
                if tt >= 2*t1                      % brake grabs the car where it is
                    a = 0;  el.v = 0;
                    if ~el.arrived, arrive(); end
                else
                    a = (el.F - b*el.v)/m;
                end
            else
                eMax = vMax*2*max(zeta,0.05)/wn;               % limits the cruising speed to vMax
                Fc = mn*(wn^2*min(max(el.r - el.x,-eMax),eMax) - 2*zeta*wn*el.v);
                Fc = min(max(Fc,-mn*aMax),mn*aMax);
                el.F = el.F + h*(Fc - el.F)/tau;   % the motor responds with a lag
                a = (el.F - b*el.v)/m;
            end
            el.v = el.v + a*h;
            el.x = el.x + el.v*h;
            el.t = el.t + h;
            if ~el.arrived, el.maxA = max(el.maxA,abs(a)); end
        end
        el.log(end+1,:) = [el.t el.x a el.r];
        if size(el.log,1) > 1500, el.log(1,:) = []; end
        if ~timed && ~el.arrived && abs(el.r - el.x) < 0.01 && abs(el.v) < 0.01, arrive(); end
        if el.x > 3*5 + 1.6 || el.x < -1.6
            el.crashed = true;
            stop(timers(1));
            lbl1Score.Text = sprintf(['💥 CRASH! The car hit the %s of the shaft. Without enough damping the ' ...
                'feedback loop is unstable: every correction overshoots more than the last.'], ...
                pick(el.x > 0,'top','bottom'));
            lbl1Score.FontColor = cRed;
        end
        if ~el.arrived && ~el.crashed && el.t - el.tStart > 40
            lbl1Score.Text = '〰️ Still not settled after 40 s: the loop is (nearly) unstable. Add smoothness!';
            lbl1Score.FontColor = cOrange;
        end
        drawShaft();
        if el.arrived && ~el.crashed && abs(el.v) < 1e-3 && abs(el.F) < 5, stop(timers(1)); end
    end

    function arrive()
        el.arrived = true;
        err = (el.x - el.r)*1000;
        T = el.t - el.tStart;
        if el.maxA < 1.05, face = '😀 comfortable'; elseif el.maxA < 1.8, face = '😐 a bit jerky'; else, face = '🤢 feeling sick'; end
        if T < 6 + 1.6*abs(el.to - el.from), pat = '🙂 patient'; else, pat = '😤 impatient'; end
        if abs(err) < 10, lev = '✅ level with the floor';
        else, lev = sprintf('⚠️ stopped %.0f mm %s the floor',abs(err),pick(err > 0,'above','below')); end
        el.msg = sprintf('Floor %d → %d in %.1f s\nPassengers: %s, %s\nMax acceleration %.2f m/s²\n%s', ...
            el.from,el.to,T,face,pat,el.maxA,lev);
        lbl1Score.Text = el.msg;
        lbl1Score.FontColor = [0 0 0];
        for k = 1:6, btn1F(k).BackgroundColor = [0.96 0.96 0.96]; end
    end

    function drawShaft()
        if isempty(fieldnames(gfx1)) || ~isvalid(gfx1.car)
            cla(ax1s); hold(ax1s,'on');
            patch(ax1s,[0 3 3 0],[-1.6 -1.6 17.6 17.6],[0.93 0.93 0.95],'EdgeColor','none');
            for f = 1:6
                y = 3*(f - 1);
                plot(ax1s,[0 3],[y y],'-','Color',[0.5 0.5 0.5],'LineWidth',1.5);
                text(ax1s,0.08,y + 0.35,sprintf('%d',f),'FontSize',16,'FontWeight','bold','Color',[0.4 0.4 0.4]);
            end
            plot(ax1s,[0 3],[17.6 17.6],'k-','LineWidth',4);
            plot(ax1s,[0 3],[-1.6 -1.6],'k-','LineWidth',4);
            gfx1.cable = plot(ax1s,[1.5 1.5],[17.6 2.6],'-','Color',[0.3 0.3 0.3],'LineWidth',1.5);
            gfx1.car = patch(ax1s,[0.8 2.2 2.2 0.8],[0 0 2.6 2.6],[0.75 0.80 0.88],'EdgeColor',[0.2 0.2 0.3],'LineWidth',2);
            gfx1.people = plot(ax1s,NaN,NaN,'o','MarkerSize',9,'MarkerFaceColor',[0.95 0.75 0.55],'MarkerEdgeColor','k');
            gfx1.target = plot(ax1s,2.75,0,'<','MarkerSize',16,'MarkerFaceColor',cGreen,'MarkerEdgeColor','k');
            hold(ax1s,'off');
            xlim(ax1s,[0 3]); ylim(ax1s,[-1.6 17.6]);
            ax1s.XTick = [];  ax1s.YTick = [];
            title(ax1s,'Elevator shaft (click a floor)');
            set(ax1s.Children,'HitTest','off');
            cla(ax1x); hold(ax1x,'on');
            gfx1.ref = stairs(ax1x,0,1,'--','Color',cOrange,'LineWidth',2);
            gfx1.pos = plot(ax1x,0,1,'Color',cBlue,'LineWidth',2.5);
            hold(ax1x,'off'); grid(ax1x,'on'); ylim(ax1x,[0.5 6.6]);
            legend(ax1x,{'button pressed (desired)','elevator (actual)'},'Location','northwest','AutoUpdate','off');
            title(ax1x,'Position: transient response and steady state (Fig 1.6)'); ylabel(ax1x,'floor (click to call)'); xlabel(ax1x,'time (s)');
            set(ax1x.Children,'HitTest','off');
            cla(ax1a); hold(ax1a,'on');
            gfx1.band = patch(ax1a,[0 20 20 0],[-1 -1 1 1],[0.88 0.96 0.85],'EdgeColor','none');
            gfx1.acc = plot(ax1a,0,0,'Color',cRed,'LineWidth',2);
            hold(ax1a,'off'); grid(ax1a,'on'); ylim(ax1a,[-3.2 3.2]);
            title(ax1a,'Acceleration felt by the passengers (green = comfortable)'); ylabel(ax1a,'m/s²'); xlabel(ax1a,'time (s)');
        end
        x = el.x;
        set(gfx1.car,'YData',x + [0 0 2.6 2.6]);
        set(gfx1.cable,'YData',[17.6 x + 2.6]);
        n = round(sl1P.Value);
        px = 0.95 + mod(0:n-1,6)*0.24;  py = x + 0.45 + floor((0:n-1)/6)*0.9;
        set(gfx1.people,'XData',px,'YData',py);
        set(gfx1.target,'YData',el.r + 1.3);
        if el.crashed, gfx1.car.FaceColor = [1 0.5 0.5]; else, gfx1.car.FaceColor = [0.75 0.80 0.88]; end

        L = el.log;
        tW = max(L(end,1),20);
        set(gfx1.ref,'XData',L(:,1),'YData',L(:,4)/3 + 1);
        set(gfx1.pos,'XData',L(:,1),'YData',L(:,2)/3 + 1);
        set(gfx1.acc,'XData',L(:,1),'YData',L(:,3));
        set(gfx1.band,'XData',[tW-20 tW tW tW-20]);
        xlim(ax1x,[tW - 20 tW]);  xlim(ax1a,[tW - 20 tW]);
        drawnow limitrate
    end

%% =====================================================================
%  Tab 2: Toaster
%  =====================================================================
    function loadPreset2()
        k = find(strcmp(presets2(:,1),dd2.Value));
        if isempty(presets2{k,2}), return, end
        dd2M.Value = modes2{presets2{k,2}};
        dd2B.Value = breads(presets2{k,3}).name;
        sl2T.Value = presets2{k,4};  sl2Time.Value = presets2{k,5};
        dd2S.Value = shades{presets2{k,6},1};
        cb2Sur.Value = presets2{k,7};
        custom2(true);
    end

    function custom2(keepPreset)
        if nargin < 1, dd2.Value = 'Custom'; end
        timed = strcmp(dd2M.Value,modes2{1});
        set([lbl2Time sl2Time],'Enable',onoff(timed));
        set([dd2B sl2T],'Enable',onoff(~cb2Sur.Value));
        if isempty(fieldnames(ts)) || ~ts.on
            ts = struct('B',0,'t',0,'on',false,'y',0,'popT',-1,'bread',find(strcmp({breads.name},dd2B.Value)), ...
                'thick',sl2T.Value,'log',[0 0]);
            drawToaster();
        end
    end

    function startToast()
        if ~isempty(fieldnames(ts)) && ts.on, return, end
        if cb2Sur.Value
            bread = randi(4);  thick = round(1 + 2*rand,1);
        else
            bread = find(strcmp({breads.name},dd2B.Value));  thick = sl2T.Value;
        end
        ts = struct('B',0,'t',0,'on',true,'y',0,'popT',-1,'bread',bread,'thick',thick,'log',[0 0]);
        lbl2Score.Text = 'Toasting… 🔥';  lbl2Score.FontColor = [0 0 0];
        run(2);
    end

    function stepToaster()
        target = shades{strcmp(shades(:,1),dd2S.Value),2};
        if ts.on
            dtMin = 0.6*frameDt;                 % 1 minute of toasting every 1.7 s
            k = 0.2*breads(ts.bread).rate*(2/ts.thick);
            ts.B = min(ts.B + k*dtMin,1);
            ts.t = ts.t + dtMin;
            ts.log(end+1,:) = [ts.t ts.B];
            if strcmp(dd2M.Value,modes2{1})
                done = ts.t >= sl2Time.Value;
            else
                done = ts.B + 0.015*randn >= target;     % the camera is a little noisy
            end
            if done || ts.B >= 1, popToast(target); end
        elseif ts.popT >= 0
            ts.y = min(ts.y + 0.25,1);                    % pop-up animation
            if ts.y >= 1, ts.popT = -1; stop(timers(2)); end
        end
        drawToaster();
    end

    function popToast(target)
        ts.on = false;  ts.popT = 0;
        err = ts.B - target;
        if ts.B >= 0.9, verdict = '🔥 BURNT! Smoke everywhere.';
        elseif abs(err) < 0.06, verdict = '😋 Perfect toast!';
        elseif err < 0, verdict = '😕 Too pale.';
        else, verdict = '😬 Too dark.'; end
        lbl2Score.Text = sprintf('%s\n%s bread, %.1f cm, %.1f min\nshade %.2f (wanted %.2f)', ...
            verdict,breads(ts.bread).name,ts.thick,ts.t,ts.B,target);
        if contains(verdict,'Perfect'), lbl2Score.FontColor = cGreen*0.8; else, lbl2Score.FontColor = cRed; end
        mode = pick(strcmp(dd2M.Value,modes2{1}),'timer ','sensor');
        words = {'BURNT','Perfect','Too pale','Too dark'};
        word = words{find(cellfun(@(w) contains(verdict,w),{'BURNT','Perfect','pale','dark'}),1)};
        line = sprintf('%s %-9s %3.1f %3.1f %4.2f %s',mode,breads(ts.bread).name,ts.thick,ts.t,ts.B,word);
        if isempty(hist2), hist2 = {line}; else, hist2 = [{line}; hist2(:)]; end
        ta2.Value = [{'mode   bread      cm  min shade'}; hist2(1:min(end,12))];
    end

    function drawToaster()
        if isempty(fieldnames(gfx2)) || ~isvalid(gfx2.slice)
            cla(ax2s); hold(ax2s,'on');
            gfx2.smoke = scatter(ax2s,NaN,NaN,600,[0.5 0.5 0.5],'filled','MarkerFaceAlpha',0.25);
            gfx2.slice = rectangle(ax2s,'Position',[3.2 2 3.6 4],'Curvature',[0.35 0.35], ...
                'FaceColor',[0.97 0.93 0.8],'EdgeColor',[0.6 0.45 0.3],'LineWidth',2);
            rectangle(ax2s,'Position',[1.5 0 7 4.5],'Curvature',[0.25 0.4],'FaceColor',[0.82 0.84 0.88], ...
                'EdgeColor',[0.4 0.42 0.46],'LineWidth',3);
            rectangle(ax2s,'Position',[3 4.3 4 0.25],'FaceColor',[0.15 0.15 0.15],'EdgeColor','none');
            gfx2.glow = rectangle(ax2s,'Position',[3.1 4.35 3.8 0.12],'FaceColor',[0.15 0.15 0.15],'EdgeColor','none');
            rectangle(ax2s,'Position',[8.5 2.5 0.6 0.4],'Curvature',0.3,'FaceColor',[0.2 0.2 0.2]);
            gfx2.dial = text(ax2s,5,2,'','FontSize',22,'FontWeight','bold','HorizontalAlignment','center','Color',[0.2 0.2 0.25]);
            gfx2.mode = text(ax2s,5,1,'','FontSize',13,'HorizontalAlignment','center','Color',[0.3 0.3 0.35]);
            hold(ax2s,'off');
            axis(ax2s,'equal'); xlim(ax2s,[0 10]); ylim(ax2s,[-0.5 10]);
            ax2s.XTick = [];  ax2s.YTick = [];  ax2s.XColor = 'none';  ax2s.YColor = 'none';
        end
        if isempty(fieldnames(ts)), return, end
        if ts.on, yb = 1.2; else, yb = 1.2 + 3.8*ts.y; end
        gfx2.slice.Position = [3.2 yb 3.6 4];
        gfx2.slice.FaceColor = toastColour(ts.B,breads(ts.bread).raw);
        if ts.on, gfx2.glow.FaceColor = [1 0.3 0.05]; else, gfx2.glow.FaceColor = [0.15 0.15 0.15]; end
        if ts.B > 0.8
            nS = round(10*(ts.B - 0.8)/0.2);
            set(gfx2.smoke,'XData',4 + 2*rand(1,nS),'YData',yb + 4 + 3*rand(1,nS));
        else
            set(gfx2.smoke,'XData',NaN,'YData',NaN);
        end
        if strcmp(dd2M.Value,modes2{1})
            gfx2.dial.String = sprintf('⏱ %.1f / %.1f min',ts.t,sl2Time.Value);
            gfx2.mode.String = 'Timer: stops after a fixed time';
        else
            gfx2.dial.String = sprintf('📷 %.1f min',ts.t);
            gfx2.mode.String = 'Camera: stops when the colour is right';
        end
        if cb2Sur.Value && ts.on, title(ax2s,'Mystery bread ❓'); else
            title(ax2s,sprintf('%s bread, %.1f cm thick',breads(ts.bread).name,ts.thick)); end

        target = shades{strcmp(shades(:,1),dd2S.Value),2};
        if ~isfield(gfx2,'curve') || ~isvalid(gfx2.curve)
            cla(ax2b); hold(ax2b,'on');
            sh = linspace(0,1,100)';
            img = zeros(100,1,3);
            for q = 1:100, img(q,1,:) = toastColour(sh(q),[0.97 0.93 0.8]); end
            image(ax2b,[0 5.2],[0 1],repmat(img,1,2));
            gfx2.target = plot(ax2b,[0 5.2],[0.5 0.5],'--','Color',cGreen,'LineWidth',3);
            gfx2.targetTxt = text(ax2b,0.1,0.5,'  what you wanted','Color',[0.1 0.4 0.1],'FontSize',13, ...
                'VerticalAlignment','bottom','FontWeight','bold');
            plot(ax2b,[0 5.2],[0.9 0.9],':','Color',cRed,'LineWidth',2);
            text(ax2b,0.1,0.9,'  burnt','Color','w','FontSize',13,'VerticalAlignment','bottom','FontWeight','bold');
            gfx2.timerLine = plot(ax2b,[1 1],[0 1],'-','Color',[0.2 0.2 0.2],'LineWidth',2);
            gfx2.timerTxt = text(ax2b,1,0.03,' timer','FontSize',13,'FontWeight','bold');
            gfx2.curve = plot(ax2b,0,0,'Color',cBlue,'LineWidth',3);
            hold(ax2b,'off');
            ax2b.YDir = 'normal';
            xlim(ax2b,[0 5.2]); ylim(ax2b,[0 1]);
            title(ax2b,'How brown is the toast?'); xlabel(ax2b,'time (min)'); ylabel(ax2b,'shade');
        end
        set(gfx2.target,'YData',[target target]);
        gfx2.targetTxt.Position(2) = target;
        timed = strcmp(dd2M.Value,modes2{1});
        set(gfx2.timerLine,'XData',sl2Time.Value*[1 1],'Visible',onoff(timed));
        set(gfx2.timerTxt,'Position',[sl2Time.Value 0.03 0],'Visible',onoff(timed));
        set(gfx2.curve,'XData',ts.log(:,1),'YData',ts.log(:,2));
        drawnow limitrate
    end

%% =====================================================================
%  Tab 3: Toilet cistern
%  =====================================================================
    function loadPreset3()
        k = find(strcmp(presets3(:,1),dd3.Value));
        if isempty(presets3{k,2}), return, end
        sl3P.Value = presets3{k,2};
        cs = struct('h',[0.25 0.25],'valve',[0 0],'flushLeft',0,'tOpen',0,'t',0,'wasted',[0 0], ...
            'log',[0 0.25 0.25],'phase','idle','tFill',NaN,'tFull',[NaN NaN]);
        drawCistern();
        lbl3Score.Text = 'Press Flush both!';
    end

    function flushBoth()
        cs = struct('h',[0.25 0.25],'valve',[0 0],'flushLeft',3,'tOpen',0,'t',0,'wasted',[0 0], ...
            'log',[0 0.25 0.25],'phase','flush','tFill',NaN,'tFull',[NaN NaN]);
        lbl3Score.Text = 'Flushing… 🌊';
        run(3);
    end

    function stepCistern()
        hSet = 0.25;  A = 0.1;  Q0 = A*(hSet - 0.02)/20;     % normal pressure fills in 20 s
        Q = Q0*sl3P.Value;
        dt = 6*frameDt;                                      % 6x faster than real time
        for q = 1:2
            cs.t = cs.t + dt/2;
            switch cs.phase
                case 'flush'
                    cs.h = max(cs.h - 0.1*dt/2,0.02);
                    cs.valve = [0 0];
                    if all(cs.h <= 0.02)
                        cs.phase = 'fill';
                        cs.tOpen = (hSet - 0.02)*A/Q0;        % the timer assumes normal pressure
                        cs.tFill = cs.t;
                    end
                case 'fill'
                    % Left: timed valve (open loop)
                    cs.valve(1) = double(cs.tOpen > 0);
                    cs.tOpen = max(cs.tOpen - dt/2,0);
                    % Right: float valve (closed loop), closes as the float rises
                    cs.valve(2) = min(max((hSet - cs.h(2))/0.02,0),1);
                    cs.h = cs.h + Q*cs.valve*dt/2/A;
                    over = cs.h > 0.29;                       % overflow pipe
                    cs.wasted(over) = cs.wasted(over) + (cs.h(over) - 0.29)*A*1000;
                    cs.h(over) = 0.29;
                    newFull = isnan(cs.tFull) & cs.h >= 0.99*hSet;
                    cs.tFull(newFull) = cs.t - cs.tFill;
                    if cs.tOpen <= 0 && cs.valve(2) < 1e-3
                        cs.phase = 'done';
                    end
            end
        end
        cs.log(end+1,:) = [cs.t cs.h];
        if strcmp(cs.phase,'done')
            stop(timers(3));
            errO = cs.h(1)/hSet*100;  errC = cs.h(2)/hSet*100;
            if cs.wasted(1) > 0.05
                o = sprintf('⚠️ Timer: overflowed, %.1f L wasted',cs.wasted(1));
            elseif errO < 97
                o = sprintf('⚠️ Timer: only %.0f%% full (weak next flush)',errO);
            else
                o = sprintf('✅ Timer: %.0f%% full',errO);
            end
            lbl3Score.Text = sprintf('%s\n✅ Float: %.0f%% full, refilled in %.0f s',o,errC,cs.tFull(2));
        end
        drawCistern();
    end

    function drawCistern()
        axs = [ax3o ax3c];
        names = {'Open loop: timed valve','Closed loop: float valve'};
        if isempty(fieldnames(gfx3)) || ~isvalid(gfx3.water(1))
            for q = 1:2
                ax = axs(q);
                cla(ax); hold(ax,'on');
                gfx3.water(q) = patch(ax,[0 1 1 0],[0 0 0.25 0.25],cWater,'EdgeColor','none','FaceAlpha',0.8);
                plot(ax,[0 0 1 1],[0.33 0 0 0.33],'k-','LineWidth',4);
                plot(ax,[0 1],[0.25 0.25],'--','Color',cGreen,'LineWidth',2);
                text(ax,0.02,0.255,'fill line','Color',cGreen*0.7,'FontSize',12,'VerticalAlignment','bottom');
                plot(ax,[0.9 0.9],[0 0.29],'-','Color',[0.5 0.5 0.5],'LineWidth',6);       % overflow pipe
                plot(ax,[0.1 0.1 0.25],[0.40 0.33 0.33],'-','Color',[0.4 0.4 0.4],'LineWidth',6);  % supply pipe
                gfx3.valve(q) = plot(ax,0.1,0.37,'o','MarkerSize',18,'MarkerFaceColor',cRed,'MarkerEdgeColor','k');
                gfx3.stream(q) = plot(ax,[0.25 0.25],[0.33 0.02],':','Color',cWater,'LineWidth',5);
                if q == 2
                    gfx3.arm = plot(ax,[0.25 0.55],[0.33 0.25],'-','Color',[0.3 0.3 0.3],'LineWidth',3);
                    gfx3.ball = plot(ax,0.55,0.25,'o','MarkerSize',26,'MarkerFaceColor',[0.95 0.95 0.95],'MarkerEdgeColor','k','LineWidth',1.5);
                else
                    gfx3.clock = text(ax,0.5,0.37,'','FontSize',15,'FontWeight','bold','HorizontalAlignment','center');
                end
                gfx3.pct(q) = text(ax,0.5,0.1,'','FontSize',22,'FontWeight','bold','HorizontalAlignment','center','Color',[0.1 0.25 0.5]);
                hold(ax,'off');
                xlim(ax,[-0.05 1.05]); ylim(ax,[-0.02 0.42]);
                ax.XTick = [];  ax.YTick = [];
                title(ax,names{q});
            end
            cla(ax3h); hold(ax3h,'on');
            gfx3.fill = plot(ax3h,[0 60],[100 100],'--','Color',cGreen,'LineWidth',2);
            gfx3.lO = plot(ax3h,0,100,'Color',cOrange,'LineWidth',2.5);
            gfx3.lC = plot(ax3h,0,100,'Color',cBlue,'LineWidth',2.5);
            hold(ax3h,'off'); grid(ax3h,'on'); ylim(ax3h,[0 125]);
            legend(ax3h,{'fill line','timed valve (open loop)','float valve (closed loop)'},'Location','southeast','AutoUpdate','off');
            title(ax3h,'Water level after the flush'); xlabel(ax3h,'time (s)'); ylabel(ax3h,'% full');
        end
        if isempty(fieldnames(cs)), return, end
        for q = 1:2
            set(gfx3.water(q),'YData',[0 0 cs.h(q) cs.h(q)]);
            if cs.valve(q) > 0.02
                gfx3.valve(q).MarkerFaceColor = cGreen;
                set(gfx3.stream(q),'YData',[0.33 cs.h(q)],'Visible','on');
            else
                gfx3.valve(q).MarkerFaceColor = cRed;
                gfx3.stream(q).Visible = 'off';
            end
            gfx3.pct(q).String = sprintf('%.0f%%',cs.h(q)/0.25*100);
        end
        yb = min(cs.h(2),0.31);
        set(gfx3.arm,'XData',[0.25 0.55],'YData',[0.33 yb]);
        set(gfx3.ball,'YData',yb);
        if strcmp(cs.phase,'fill') || strcmp(cs.phase,'done')
            gfx3.clock.String = sprintf('⏱ valve open for %.0f s more',cs.tOpen);
        else
            gfx3.clock.String = '';
        end
        L = cs.log;
        tW = max(L(end,1),60);
        set(gfx3.fill,'XData',[0 tW]);
        set(gfx3.lO,'XData',L(:,1),'YData',L(:,2)/0.25*100);
        set(gfx3.lC,'XData',L(:,1),'YData',L(:,3)/0.25*100);
        xlim(ax3h,[0 tW]);
        drawnow limitrate
    end

%% =====================================================================
%  Tab 4: Balance it
%  =====================================================================
    function loadPreset4()
        k = find(strcmp(presets4(:,1),dd4.Value));
        if isempty(presets4{k,2}), return, end
        dd4W.Value = whos4{presets4{k,2}};
        sl4L.Value = presets4{k,3};
        dd4G.Value = gravs{presets4{k,4},1};
        sl4K.Value = presets4{k,5};
        resetPendulum();
    end

    function custom4()
        dd4.Value = 'Custom';
        if isempty(fieldnames(pd)) || ~pd.running, resetPendulum(); end
    end

    function resetPendulum()
        stop(timers(4));
        pd = struct('x',0,'v',0,'th',deg2rad(3),'w',0,'t',0,'running',false,'fallen',false,'log',[0 0 3]);
        lbl4Time.Text = '0.0 s';
        lbl4Score.Text = 'Press Start.';  lbl4Score.FontColor = [0 0 0];
        drawPendulum();
    end

    function startPendulum()
        resetPendulum();
        pd.running = true;
        lbl4Score.Text = pick(strcmp(dd4W.Value,whos4{1}),'Move the mouse over the track! 🖱️','Balancing…');
        run(4);
    end

    function pokePendulum()
        if isempty(fieldnames(pd)) || ~pd.running, return, end
        pd.w = pd.w + (0.6 + 0.4*rand)*sign(randn)*sqrt(gravity()/sl4L.Value)*0.35;
    end

    function g = gravity()
        g = gravs{strcmp(gravs(:,1),dd4G.Value),2};
    end

    function stepPendulum()
        g = gravity();  l = sl4L.Value;  who = find(strcmp(whos4,dd4W.Value));
        nSub = 10;  h = frameDt/nSub;  aMax = 25;  track = 2.6;
        pt = mousePoint(ax4s);
        xRef = min(max(pt(1),-track + 0.3),track - 0.3);
        if who == 2
            % Pole placement for the linearised cart-pole (cart acceleration as input)
            A = [0 1 0 0; 0 0 0 0; 0 0 0 1; 0 0 g/l 0];  B = [0; 1; 0; -1/l];
            K = place(A,B,-sqrt(g/l)*(0.5 + 0.1*sl4K.Value)*[0.6 0.8 1.6 2]);
        end
        for q = 1:nSub
            switch who
                case 1, a = 60*(xRef - pd.x) - 14*pd.v;            % your hand moves the cart
                case 2, a = -K*[-min(max(xRef - pd.x,-0.4),0.4); pd.v; pd.th; pd.w];  % follow the target gently
                otherwise, a = -6*pd.v;
            end
            a = min(max(a,-aMax),aMax);
            alpha = (g*sin(pd.th) - a*cos(pd.th))/l;
            pd.v = pd.v + a*h;  pd.x = pd.x + pd.v*h;
            pd.w = pd.w + alpha*h;  pd.th = pd.th + pd.w*h;
            if abs(pd.x) > track                                    % bumpers
                pd.x = sign(pd.x)*track;  pd.v = 0;
            end
            pd.t = pd.t + h;
        end
        pd.log(end+1,:) = [pd.t pd.x rad2deg(pd.th)];
        if size(pd.log,1) > 1000, pd.log(1,:) = []; end
        lbl4Time.Text = sprintf('%.1f s',pd.t);
        if abs(pd.th) > deg2rad(75)
            pd.running = false;  pd.fallen = true;
            stop(timers(4));
            best4 = max(best4,pd.t);
            lbl4Score.Text = sprintf('😵 It fell after %.1f s. Best: %.1f s. Press Start to try again.',pd.t,best4);
            lbl4Score.FontColor = cRed;
        elseif pd.t > 60
            pd.running = false;  stop(timers(4));
            best4 = max(best4,pd.t);
            lbl4Score.Text = '🏆 Balanced for a full minute!';  lbl4Score.FontColor = cGreen*0.8;
        end
        drawPendulum();
    end

    function drawPendulum()
        l = sl4L.Value;
        if isempty(fieldnames(gfx4)) || ~isvalid(gfx4.cart)
            cla(ax4s); hold(ax4s,'on');
            plot(ax4s,[-3 3],[0 0],'-','Color',[0.35 0.35 0.35],'LineWidth',5);
            plot(ax4s,[-2.95 -2.95 NaN 2.95 2.95],[0 0.4 NaN 0 0.4],'k-','LineWidth',6);
            gfx4.cart = patch(ax4s,[-0.35 0.35 0.35 -0.35],[0.1 0.1 0.45 0.45],[0.3 0.5 0.8],'EdgeColor','k','LineWidth',2);
            gfx4.wheels = plot(ax4s,[-0.2 0.2],[0.08 0.08],'o','MarkerSize',12,'MarkerFaceColor',[0.2 0.2 0.2],'MarkerEdgeColor','k');
            gfx4.rod = plot(ax4s,[0 0],[0.45 2],'-','Color',[0.55 0.35 0.15],'LineWidth',6);
            gfx4.bob = plot(ax4s,0,2,'o','MarkerSize',22,'MarkerFaceColor',cOrange,'MarkerEdgeColor','k','LineWidth',1.5);
            gfx4.hand = plot(ax4s,0,-0.25,'^','MarkerSize',14,'MarkerFaceColor',cGreen,'MarkerEdgeColor','k');
            hold(ax4s,'off');
            ax4s.XTick = -3:3;  ax4s.YTick = [];
            xlabel(ax4s,'track (m)');
            cla(ax4p); hold(ax4p,'on');
            gfx4.ang = plot(ax4p,0,0,'Color',cOrange,'LineWidth',2.5);
            gfx4.pos = plot(ax4p,0,0,'Color',cBlue,'LineWidth',1.5);
            hold(ax4p,'off'); grid(ax4p,'on'); ylim(ax4p,[-80 80]);
            legend(ax4p,{'pole angle (deg)','cart position (×30)'},'Location','northwest','AutoUpdate','off');
            xlabel(ax4p,'time (s)');
        end
        if isempty(fieldnames(pd)), return, end
        x = pd.x;  th = pd.th;
        set(gfx4.cart,'XData',x + [-0.35 0.35 0.35 -0.35]);
        set(gfx4.wheels,'XData',x + [-0.2 0.2]);
        tip = [x + l*sin(th), 0.45 + l*cos(th)];
        set(gfx4.rod,'XData',[x tip(1)],'YData',[0.45 tip(2)]);
        set(gfx4.bob,'XData',tip(1),'YData',tip(2));
        who = find(strcmp(whos4,dd4W.Value));
        if who == 3, gfx4.hand.Visible = 'off';
        else
            pt = mousePoint(ax4s);
            set(gfx4.hand,'XData',min(max(pt(1),-2.3),2.3),'Visible','on');
        end
        if ~isequal(ax4s.YLim,[-0.5 max(3.6,l + 0.9)])
            axis(ax4s,'equal'); xlim(ax4s,[-3.1 3.1]); ylim(ax4s,[-0.5 max(3.6,l + 0.9)]);
        end
        if who == 1, ttl = 'You are in control: move the mouse left/right (green arrow = your hand)';
        elseif who == 2, ttl = 'Feedback controller in control (the green arrow sets where the cart should go)';
        else, ttl = 'Nobody in control'; end
        title(ax4s,ttl);
        L = pd.log;
        set(gfx4.ang,'XData',L(:,1),'YData',L(:,3));
        set(gfx4.pos,'XData',L(:,1),'YData',L(:,2)*30);
        tW = max(L(end,1),15);
        xlim(ax4p,[tW - 15 tW]);
        drawnow limitrate
    end

%% =====================================================================
%  Tab 5: Cruise control
%  =====================================================================
    function loadPreset5()
        k = find(strcmp(presets5(:,1),dd5.Value));
        if isempty(presets5{k,2}), return, end
        dd5M.Value = modes5{presets5{k,2}};
        [sl5V.Value, sl5P.Value] = presets5{k,3:4};
        cb5H.Value = presets5{k,5};
        [sl5W.Value, sl5K.Value] = presets5{k,6:7};
        dd5E.Value = engines{presets5{k,8},1};
        resetCruise(sl5V.Value/3.6);
    end

    function custom5()
        dd5.Value = 'Custom';
    end

    function setHills5()
        dd5.Value = 'Custom';
        makeRoad();
        drawCruise();
    end

    function resetCruise(v0)
        stop(timers(5));
        btn5Go.Text = 'Drive ▶';
        cr = struct('s',500,'v',v0,'I',0,'t',0,'u',0,'log',[0 v0*3.6 sl5V.Value 0],'launch',-1,'t100',NaN);
        makeRoad();
        lbl5Score.Text = 'Press Drive.';
        drawCruise();
    end

    function makeRoad()
        xs = (0:2:30000)';
        if cb5H.Value
            slope = 0.06*sin(2*pi*xs/900) + 0.03*sin(2*pi*xs/340 + 1);
        else
            slope = zeros(size(xs));
        end
        gfx5.xs = xs;  gfx5.slope = slope;
        gfx5.z = cumtrapz(xs,slope);
        if isfield(gfx5,'road') && isvalid(gfx5.road)
            set(gfx5.road,'XData',[xs; xs(end); xs(1)],'YData',[gfx5.z; -1e4; -1e4]);
        end
    end

    function toggleDrive()
        if strcmp(timers(5).Running,'on')
            stop(timers(5));  btn5Go.Text = 'Drive ▶';
        else
            run(5);  btn5Go.Text = 'Pause ⏸';
        end
    end

    function launch5()
        resetCruise(0);
        cr.launch = 0;
        lbl5Score.Text = 'Launch! 🏁';
        run(5);  btn5Go.Text = 'Pause ⏸';
    end

    function stepCruise()
        m = 1250 + 75*round(sl5P.Value);  mNom = 1250 + 75;  g = 9.81;
        Pmax = engines{strcmp(engines(:,1),dd5E.Value),2};
        vSet = sl5V.Value/3.6;  wind = sl5W.Value/3.6;
        kA = sl5K.Value;  Kp = 0.08*kA;  Ki = 0.02*kA;
        if Pmax > 5e5, Fgrip = 60000; else, Fgrip = 6000; end     % tyre grip (the rocket ignores it)
        Fmax = @(v) min(Fgrip,Pmax/max(v,1));
        drag = @(v,w) 0.4*(v + w)*abs(v + w);
        cruise = strcmp(dd5M.Value,modes5{2});
        nSub = 4;  h = frameDt/nSub;
        for q = 1:nSub
            if cruise
                e = vSet - cr.v;
                u = Kp*e + Ki*cr.I;
                if (u < 1 && u > -0.5) || sign(e) ~= sign(u), cr.I = cr.I + e*h; end   % anti-windup
            else
                % Pedal set for the set speed on a flat road with one passenger and no wind
                u = (drag(vSet,0) + 0.012*mNom*g)/Fmax(vSet);
            end
            u = min(max(u,-0.5),1);
            if u >= 0, F = u*Fmax(cr.v); else, F = u*8000; end
            sl = interp1(gfx5.xs,gfx5.slope,cr.s);
            a = (F - drag(cr.v,wind) - 0.012*m*g*sign(cr.v) - m*g*sin(atan(sl)))/m;
            cr.v = max(cr.v + a*h,0);
            cr.s = cr.s + cr.v*h;
            cr.t = cr.t + h;  cr.u = u;
            if cr.s > 29000, cr.s = 1000; end
        end
        if cr.launch >= 0 && isnan(cr.t100) && cr.v*3.6 >= 99.5
            cr.t100 = cr.t;
        end
        cr.log(end+1,:) = [cr.t cr.v*3.6 sl5V.Value cr.u*100];
        if size(cr.log,1) > 2000, cr.log(1,:) = []; end
        L = cr.log;
        recent = L(L(:,1) >= cr.t - 30,:);
        txt = sprintf('Speed %.0f km/h (set %.0f)\nLast 30 s: %.0f to %.0f km/h',cr.v*3.6,sl5V.Value, ...
            min(recent(:,2)),max(recent(:,2)));
        if cr.launch >= 0
            if isnan(cr.t100), txt = sprintf('%s\n0→100: %.1f s and counting…',txt,cr.t);
            else, txt = sprintf('%s\n🏁 0→100 km/h in %.1f s',txt,cr.t100); end
        end
        lbl5Score.Text = txt;
        drawCruise();
    end

    function drawCruise()
        if ~isfield(gfx5,'road') || ~isvalid(gfx5.road)
            cla(ax5r); hold(ax5r,'on');
            ax5r.Color = [0.85 0.93 1];
            gfx5.road = patch(ax5r,[gfx5.xs; gfx5.xs(end); gfx5.xs(1)],[gfx5.z; -1e4; -1e4],[0.45 0.65 0.35], ...
                'EdgeColor',[0.3 0.3 0.3],'LineWidth',3);
            gfx5.car = patch(ax5r,NaN,NaN,cRed,'EdgeColor','k','LineWidth',1.5);
            gfx5.wheels = plot(ax5r,NaN,NaN,'o','MarkerSize',10,'MarkerFaceColor','k','MarkerEdgeColor','k');
            gfx5.wind = text(ax5r,0,0,'','FontSize',14,'Color',[0.3 0.3 0.6]);
            hold(ax5r,'off');
            ax5r.YTick = [];
            xlabel(ax5r,'distance (m)');
            % Speedometer
            cla(ax5g); hold(ax5g,'on');
            th = linspace(deg2rad(225),deg2rad(-45),100);
            plot(ax5g,cos(th),sin(th),'k-','LineWidth',3);
            for v = 0:20:200
                a = deg2rad(225 - 270*v/200);
                plot(ax5g,[0.85 1]*cos(a),[0.85 1]*sin(a),'k-','LineWidth',2);
                text(ax5g,0.68*cos(a),0.68*sin(a),sprintf('%d',v),'HorizontalAlignment','center','FontSize',10);
            end
            gfx5.setMark = plot(ax5g,NaN,NaN,'^','MarkerSize',12,'MarkerFaceColor',cOrange,'MarkerEdgeColor','k');
            gfx5.needle = plot(ax5g,[0 0],[0 0.9],'-','Color',cRed,'LineWidth',4);
            plot(ax5g,0,0,'ko','MarkerSize',10,'MarkerFaceColor','k');
            gfx5.speed = text(ax5g,0,-0.45,'','FontSize',22,'FontWeight','bold','HorizontalAlignment','center');
            text(ax5g,0,-0.72,'km/h','FontSize',12,'HorizontalAlignment','center');
            hold(ax5g,'off');
            axis(ax5g,'equal'); xlim(ax5g,[-1.15 1.15]); ylim(ax5g,[-1 1.15]);
            ax5g.XTick = [];  ax5g.YTick = [];  ax5g.XColor = 'none';  ax5g.YColor = 'none';
            cla(ax5v); hold(ax5v,'on');
            gfx5.vSet = plot(ax5v,0,0,'--','Color',cOrange,'LineWidth',2);
            gfx5.vAct = plot(ax5v,0,0,'Color',cBlue,'LineWidth',2.5);
            hold(ax5v,'off'); grid(ax5v,'on');
            legend(ax5v,{'set speed','actual speed'},'Location','southeast','AutoUpdate','off');
            title(ax5v,'Speed (drag up/down to change the set speed)'); xlabel(ax5v,'time (s)'); ylabel(ax5v,'km/h');
            set(ax5v.Children,'HitTest','off');
            cla(ax5u); hold(ax5u,'on');
            gfx5.uBand = patch(ax5u,[0 30 30 0],[100 100 130 130],[1 0.9 0.9],'EdgeColor','none');
            gfx5.uAct = plot(ax5u,0,0,'Color',[0.25 0.25 0.25],'LineWidth',2);
            hold(ax5u,'off'); grid(ax5u,'on'); ylim(ax5u,[-55 130]);
            title(ax5u,'Throttle (control action)'); xlabel(ax5u,'time (s)'); ylabel(ax5u,'% (negative = brake)');
        end
        if isempty(fieldnames(cr)), return, end
        s = cr.s;
        z = interp1(gfx5.xs,gfx5.z,s);  sl = interp1(gfx5.xs,gfx5.slope,s);
        ang = atan(sl*2.5);                         % the plot exaggerates the hills 2.5x
        body = [-2.2 2.2 2.2 1.2 0.6 -1.0 -1.8 -2.2; 0 0 0.9 0.9 1.6 1.6 0.9 0.9]*2.2;
        R = [cos(ang) -sin(ang); sin(ang) cos(ang)];
        b = R*(body.*[1; 2.5]) ;
        b(2,:) = b(2,:)/2.5;
        set(gfx5.car,'XData',s + b(1,:),'YData',z + 0.6 + b(2,:));
        wp = R*([-1.4 1.4; 0 0]*2.2.*[1; 2.5]);
        set(gfx5.wheels,'XData',s + wp(1,:),'YData',z + 0.6 + wp(2,:)/2.5);
        if sl5W.Value ~= 0
            set(gfx5.wind,'Position',[s + 60, z + 15, 0],'String',sprintf('💨 %+.0f km/h',sl5W.Value));
        else
            gfx5.wind.String = '';
        end
        xlim(ax5r,[s - 100 s + 200]); ylim(ax5r,[z - 25 z + 35]);
        title(ax5r,sprintf('%s   |   %d passenger(s)   |   slope %+.1f%%',dd5M.Value,round(sl5P.Value),100*sl));
        vk = cr.v*3.6;
        a = deg2rad(225 - 270*min(vk,200)/200);
        set(gfx5.needle,'XData',[0 0.9*cos(a)],'YData',[0 0.9*sin(a)]);
        as = deg2rad(225 - 270*sl5V.Value/200);
        set(gfx5.setMark,'XData',1.08*cos(as),'YData',1.08*sin(as));
        gfx5.speed.String = sprintf('%.0f',vk);
        L = cr.log;  tW = max(L(end,1),30);
        set(gfx5.vSet,'XData',L(:,1),'YData',L(:,3));
        set(gfx5.vAct,'XData',L(:,1),'YData',L(:,2));
        set(gfx5.uAct,'XData',L(:,1),'YData',L(:,4));
        set(gfx5.uBand,'XData',[tW-30 tW tW tW-30]);
        xlim(ax5v,[tW - 30 tW]); ylim(ax5v,[0 max(170,max(L(:,2)) + 10)]);
        xlim(ax5u,[tW - 30 tW]);
        drawnow limitrate
    end
end

%% =========================================================================
%  Helpers
%  =========================================================================
function c = toastColour(B,raw)
% Colour of the toast for a browning level B from 0 (raw) to 1 (charcoal).
keys = [0 0.35 0.5 0.7 0.9 1];
cols = [raw; 0.92 0.78 0.52; 0.82 0.58 0.28; 0.55 0.32 0.13; 0.25 0.14 0.07; 0.08 0.06 0.05];
c = interp1(keys,cols,min(max(B,0),1));
end

function s = pick(c,a,b)
if c, s = a; else, s = b; end
end

function s = onoff(b)
if b, s = 'on'; else, s = 'off'; end
end

function h = at(h,row,col)
% Place a component in a grid layout cell (row, col may be spans like [1 2]).
h.Layout.Row = row;
h.Layout.Column = col;
end
