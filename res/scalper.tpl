<chart>
id=130833104787766379
symbol=EURUSD
period=5
leftpos=64748
digits=5
scale=4
graph=1
fore=0
grid=1
volume=0
scroll=1
shift=1
ohlc=1
one_click=0
askline=1
days=0
descriptions=0
shift_size=20
fixed_pos=32
window_left=0
window_top=0
window_right=1168
window_bottom=438
window_type=3
background_color=0
foreground_color=16777215
barup_color=65280
bardown_color=255
bullcandle_color=65280
bearcandle_color=255
chartline_color=65280
volumes_color=3329330
grid_color=10061943
askline_color=255
stops_color=255

<window>
height=100
fixed_height=0
<indicator>
name=main
</indicator>
<indicator>
name=Bollinger Bands
period=20
shift=0
deviations=2.000000
apply=0
color=7451452
style=0
weight=1
period_flags=0
show_data=1
</indicator>
</window>

<window>
height=50
fixed_height=0
<indicator>
name=Stochastic Oscillator
kperiod=5
dperiod=3
slowing=3
method=0
apply=0
color=11186720
style=0
weight=1
color2=255
style2=2
weight2=1
min=0.000000
max=100.000000
levels_color=12632256
levels_style=2
levels_weight=1
level_0=25.0000
level_1=75.0000
period_flags=0
show_data=1
</indicator>
</window>

<expert>
name=scalper
flags=279
window_num=0
<inputs>
TRADE_MODE=2
TRADE_SIZE=1.0
STOP=360
TARGET=300
BOUNCE_SPREAD=320
MAX_RISK_PCT=0.5
MARTINGALE=false
HOUR_START=8
HOUR_END=11
</inputs>
</expert>
</chart>

