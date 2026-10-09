#!/usr/bin/env python3
# Keep Hacking: standalone procedural 2D pixel asset kit and screenshot previews.
# All pixel artwork authored from scratch with PIL; not extracted from the reference game.
from __future__ import annotations
from PIL import Image, ImageDraw, ImageFont, ImageFilter
from pathlib import Path
import math, random, json, shutil

ROOT = Path(__file__).resolve().parents[1]
for d in ['assets/props','assets/icons','assets/tiles','assets/fx','assets/ui','assets/backgrounds','assets/atlases','screenshots','concept']:
    (ROOT / d).mkdir(parents=True,exist_ok=True)
R = Image.Resampling.NEAREST
P = {
    'bg':'#070C1A', 'back':'#0B1528','bg2':'#111E35', 'mid':'#182742','metal':'#263952',
    'edge':'#405676','light':'#728AA7','white':'#D9F5FA','pale':'#A4BDC9',
    'cyan':'#45DEF5','cyan2':'#1D809E','mint':'#42F7A9','green':'#159D78',
    'purple':'#B26EFF','purple2':'#683CB8','magenta':'#F14DC9',
    'red':'#FF5378','red2':'#9A314D','orange':'#FEAD62','yellow':'#FFD971',
    'navy':'#080D24','teal':'#1F8192','glass':'#112E3D','shadow':'#030610',
}

rng=random.Random(62)
font_path='/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf'
font_bold='/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf'
def font(n=12,bold=False):
    try:
        return ImageFont.truetype(font_bold if bold else font_path,n)
    except OSError:
        for candidate in (('DejaVuSansMono-Bold.ttf' if bold else 'DejaVuSansMono.ttf'),('C:/Windows/Fonts/consolab.ttf' if bold else 'C:/Windows/Fonts/consola.ttf'),'/System/Library/Fonts/Menlo.ttc'):
            try: return ImageFont.truetype(candidate,n)
            except OSError: pass
        return ImageFont.load_default(size=n)
def txt(im,xy,t,s=11,color=None,bold=False,anchor=None,stroke_width=0):
    d=ImageDraw.Draw(im)
    d.text(xy,t,font=font(s,bold),fill=color or P['white'],anchor=anchor,stroke_width=stroke_width,stroke_fill=P['shadow'])
def rect(d,box,fill,outline=None,width=1):
    d.rectangle(tuple(map(int,box)),fill=fill,outline=outline,width=width)
def poly(d,pts,fill,outline=None):
    d.polygon(pts,fill=fill)
    if outline:d.line(pts+[pts[0]],fill=outline,width=1)
def line(d,pts,c,w=1):d.line(pts,fill=c,width=w,joint='curve')
def oval(d,xy,fill=None,outline=None,width=1):d.ellipse(xy,fill=fill,outline=outline,width=width)
def spark(d,x,y,c=P['cyan'],r=3):
    line(d,[(x-r,y),(x+r,y)],c,1);line(d,[(x,y-r),(x,y+r)],c,1);d.point((x,y),fill=P['white'])
def framed(d,box,fill=None,trim=None):
    x0,y0,x1,y1=box
    rect(d,(x0+2,y0+2,x1+2,y1+2),P['shadow'])
    rect(d,box,fill or P['mid'],trim or P['edge'],2)
    line(d,[(x0+3,y0+1),(x1-3,y0+1)],P['light'])
    d.point([(x0+3,y0+3),(x1-3,y1-3)],fill=P['cyan2'])

def prop(name):
    im=Image.new('RGBA',(64,64),(0,0,0,0));d=ImageDraw.Draw(im)
    def box(b,c=P['metal'],edge=P['shadow'],top=P['edge']):
        x0,y0,x1,y1=b;rect(d,(x0+2,y0+3,x1+2,y1+3),P['shadow']);rect(d,b,c,edge,2);line(d,[(x0+2,y0+2),(x1-2,y0+2)],top,2)
    def led(x,y,c=P['mint']):rect(d,(x,y,x+3,y+2),c)
    def cabinet(x,y,w=30,h=46,c=P['mid']):
        box((x,y,x+w,y+h),c)
        rect(d,(x+4,y+5,x+w-4,y+h-4),P['back'],P['edge'])
        for j in range(5):
            yy=y+9+j*7;rect(d,(x+6,yy,x+w-6,yy+4),P['metal']);line(d,[(x+8,yy+1),(x+16,yy+1)],P['cyan2']);led(x+w-11,yy+1,P['mint'] if j!=3 else P['orange'])
    if name=='terminal':
        box((9,7,54,42));rect(d,(14,11,49,36),P['glass'],P['cyan2'],2)
        for y,w in [(15,20),(20,25),(25,14),(30,24)]:line(d,[(18,y),(18+w,y)],P['mint'],1)
        rect(d,(24,43,39,49),P['edge']);box((10,48,54,55),P['mid']);
        for i in range(8):d.point((17+i*4,51),fill=P['cyan2'])
    elif name=='server_rack':cabinet(16,4,30,52)
    elif name=='server_cluster':cabinet(4,11,27,43);cabinet(31,7,28,48)
    elif name=='firewall':
        box((9,10,55,52),P['red2'],P['red']);rect(d,(16,17,48,46),P['back'],P['red2'],2)
        rect(d,(25,29,39,40),P['red']);d.arc((25,19,39,34),180,360,fill=P['red'],width=3)
        for x in [11,49]:led(x,47,P['red'])
    elif name=='database':
        for y in [14,24,34,44]:
            rect(d,(14,y,51,y+11),P['cyan2'],P['back']);oval(d,(14,y-4,51,y+5),P['metal'],P['cyan']);led(40,y+5)
        oval(d,(14,42,51,52),P['metal'],P['cyan2'])
    elif name=='router':
        line(d,[(18,33),(15,15)],P['edge'],3);line(d,[(48,33),(51,13)],P['edge'],3)
        spark(d,15,13,P['cyan'],3);spark(d,51,11,P['purple'],3)
        box((9,31,56,49));rect(d,(14,38,50,44),P['glass']);
        for x in range(18,49,7):led(x,40)
    elif name=='quantum_core':
        box((9,13,53,51),P['metal']);poly(d,[(32,9),(53,30),(32,54),(10,30)],P['cyan2'],P['cyan'])
        poly(d,[(32,18),(43,30),(32,43),(21,30)],P['purple'],P['white']);spark(d,32,30,P['white'],4)
    elif name=='data_cache':
        box((11,14,52,51),P['orange']);rect(d,(15,19,48,44),P['metal'],P['yellow'])
        for x in range(20,46,8):rect(d,(x,23,x+4,38),P['glass']);led(43,46,P['mint'])
    elif name=='bot_drone':
        for x,y in [(13,16),(48,16),(13,44),(48,44)]:
            oval(d,(x-8,y-8,x+7,y+7),P['metal'],P['cyan2'],2);oval(d,(x-3,y-3,x+3,y+3),P['cyan'])
        box((21,19,42,43),P['edge']);rect(d,(27,25,36,35),P['mint'])
    elif name=='security_cam':
        line(d,[(12,16),(23,23),(27,43)],P['light'],4);poly(d,[(25,23),(50,15),(57,29),(35,41)],P['metal'],P['edge']);oval(d,(41,23,49,31),P['cyan'])
    elif name=='antenna':
        box((13,46,53,55));line(d,[(32,45),(32,10)],P['light'],3)
        for y,w in [(26,13),(35,20)]:line(d,[(32-w//2,y),(32+w//2,y)],P['cyan2'],2)
        spark(d,32,8,P['mint'],5)
    elif name=='cooling_fan':
        box((8,9,55,55));oval(d,(15,16,48,49),P['back'],P['edge'],2)
        for k in range(4):
            a=k*math.pi/2;xx=32+int(11*math.cos(a));yy=32+int(11*math.sin(a));
            poly(d,[(32,32),(xx-4,yy-5),(xx+4,yy+5)],P['cyan2'],P['light'])
        oval(d,(28,28,36,36),P['cyan'])
    elif name=='processor':
        box((15,14,48,49),P['mid']);rect(d,(20,19,43,43),P['glass'],P['mint'],2)
        for i in range(5):
            x=17+i*7;line(d,[(x,10),(x,14)],P['orange'],2);line(d,[(x,49),(x,55)],P['orange'],2)
            y=17+i*7;line(d,[(10,y),(15,y)],P['orange'],2);line(d,[(48,y),(54,y)],P['orange'],2)
        spark(d,32,31,P['cyan'])
    elif name=='encrypted_vault':
        box((10,10,54,53),P['purple2'],P['purple']);rect(d,(19,17,46,46),P['back'],P['purple2'],2)
        oval(d,(24,23,40,39),P['edge'],P['purple'],2);oval(d,(30,29,34,33),P['mint'])
    elif name=='access_port':
        box((12,13,51,49));rect(d,(19,18,43,43),P['glass'],P['mint'],2)
        rect(d,(26,28,37,35),P['mint']);rect(d,(28,23,35,27),P['cyan']);led(42,47)
    elif name=='glitch_node':
        box((14,12,49,48),P['red2'],P['red']);rect(d,(20,20,42,38),P['back'])
        for i in range(24):
            x=rng.randrange(10,54);y=rng.randrange(7,56);rect(d,(x,y,x+rng.randrange(2,7),y+rng.randrange(1,4)),rng.choice([P['red'],P['purple'],P['orange']]))
    elif name=='relay_tower':
        line(d,[(13,54),(32,7),(50,54)],P['edge'],3);line(d,[(17,50),(47,50)],P['light'],3)
        for y in [19,29,39]:line(d,[(int(13+(y-7)*19/47),y),(int(50-(y-7)*18/47),y)],P['cyan2'],2)
        oval(d,(28,4,36,12),P['mint'])
    elif name=='satellite_dish':
        box((24,44,46,55));line(d,[(36,44),(29,27)],P['edge'],3)
        d.pieslice((10,7,47,44),215,325,fill=P['cyan2'],outline=P['cyan'],width=2);line(d,[(29,27),(45,15)],P['light'],2);spark(d,45,15,P['mint'])
    elif name=='firewall_gate':
        box((5,34,59,49),P['red2'],P['red']);
        for x in range(9,56,10):poly(d,[(x,36),(x+7,36),(x+3,46),(x-4,46)],P['orange'])
        rect(d,(8,23,16,35),P['metal']);rect(d,(47,23,55,35),P['metal'])
    elif name=='terminal_desk':
        box((6,41,58,55),P['metal']);box((18,12,45,39));rect(d,(22,16,42,34),P['glass']);
        for i in range(4):line(d,[(24,19+i*3),(35+i%2*5,19+i*3)],P['mint'])
        rect(d,(19,43,45,47),P['cyan2'])
    elif name=='power_cell':
        box((18,11,46,53),P['glass']);rect(d,(23,8,41,12),P['light']);
        for y in [17,29,41]:rect(d,(24,y,41,y+7),P['cyan2'],P['cyan']);spark(d,32,31,P['white'])
    elif name=='wifi_beacon':
        box((14,45,50,54));line(d,[(32,44),(32,25)],P['light'],3);oval(d,(28,19,36,27),P['cyan'])
        for k in [1,2]:d.arc((32-10*k,21-10*k,32+10*k,21+10*k),205,335,fill=P['mint'],width=2)
    elif name=='data_pod':
        box((13,15,50,53),P['metal']);rect(d,(17,19,46,46),P['glass']);
        for i in range(5):line(d,[(20,23+i*4),(40,23+i*4)],P['orange']);led(37,49,P['mint'])
    elif name=='virus_specimen':
        oval(d,(18,18,46,46),P['purple2'],P['magenta'],2)
        for k in range(8):
            a=math.pi*k/4;xx=32+int(23*math.cos(a));yy=32+int(23*math.sin(a));line(d,[(32+int(12*math.cos(a)),32+int(12*math.sin(a))),(xx,yy)],P['magenta'],2)
        oval(d,(26,28,30,32),P['white']);oval(d,(36,28,40,32),P['white'])
    elif name=='secure_node':
        box((14,14,49,48),P['green'],P['mint']);poly(d,[(31,20),(41,24),(40,38),(31,43),(22,38),(21,24)],P['glass'],P['mint'])
        line(d,[(26,32),(30,36),(37,27)],P['mint'],3)
    elif name=='decrypt_station':
        box((8,24,55,50));rect(d,(14,28,49,44),P['glass']);
        for i in range(5):line(d,[(17+i*6,31),(20+i*6,40)],P['purple'],2)
        line(d,[(32,24),(43,13)],P['cyan'],2);spark(d,45,11,P['cyan'])
    elif name=='packet_transmitter':
        box((12,43,52,56));line(d,[(32,42),(32,13)],P['light'],3)
        for i in range(3):
            rr=8+i*7;d.arc((32-rr,14-rr,32+rr,14+rr),195,345,fill=[P['cyan'],P['green'],P['purple']][i],width=2)
    elif name=='extraction_port':
        box((12,15,51,54),P['metal']);rect(d,(17,22,46,42),P['glass'],P['mint']);
        for i in range(3):poly(d,[(23+i*7,29),(26+i*7,26),(29+i*7,29),(26+i*7,33)],P['mint'])
        rect(d,(21,46,43,50),P['cyan2'])
    elif name=='vault_door':
        box((9,4,55,58));rect(d,(15,11,49,51),P['glass'],P['edge'],2);oval(d,(21,18,43,42),P['metal'],P['cyan'],2)
        for a in [0,45,90,135]:
            x=32+int(9*math.cos(a*math.pi/180));y=30+int(9*math.sin(a*math.pi/180));d.ellipse((x-1,y-1,x+1,y+1),fill=P['mint'])
        oval(d,(28,26,36,34),P['cyan'])
    elif name=='mainframe':
        box((5,8,58,56));rect(d,(9,13,54,50),P['back'],P['edge']);
        for j in range(3):
            yy=18+j*11;rect(d,(13,yy,49,yy+8),P['metal']);
            for i in range(4):led(18+i*8,yy+3,[P['mint'],P['cyan'],P['purple']][j])
        rect(d,(20,52,42,57),P['red2'])
    elif name=='proxy_bot':
        box((20,21,45,46));oval(d,(18,10,47,31),P['edge'],P['cyan']);rect(d,(24,23,40,26),P['glass']);
        led(26,21,P['mint']);led(36,21,P['mint']);line(d,[(26,45),(20,56)],P['light'],3);line(d,[(39,45),(46,56)],P['light'],3)
    elif name=='code_console':
        box((9,10,54,53));rect(d,(14,16,49,44),P['back'],P['cyan2']);
        for j in range(5):line(d,[(17,20+j*4),(19+((j*7+9)%23),20+j*4)],P['mint'])
        rect(d,(22,47,44,49),P['cyan2'])
    elif name=='neon_crate':
        box((11,16,51,53));rect(d,(17,20,46,47),P['purple2'],P['magenta']);
        poly(d,[(21,25),(42,25),(32,42)],P['back'],P['magenta'])
    elif name=='signal_orb':
        oval(d,(12,13,52,53),P['cyan2'],P['cyan'],2);oval(d,(18,19,46,47),P['glass'],P['white'])
        poly(d,[(32,17),(43,32),(32,46),(21,32)],P['mint']);spark(d,32,32,P['white'])
    else:
        raise ValueError(name)
    return im

PROP_NAMES=['terminal','server_rack','server_cluster','firewall','database','router','quantum_core','data_cache','bot_drone','security_cam','antenna','cooling_fan','processor','encrypted_vault','access_port','glitch_node','relay_tower','satellite_dish','firewall_gate','terminal_desk','power_cell','wifi_beacon','data_pod','virus_specimen','secure_node','decrypt_station','packet_transmitter','extraction_port','vault_door','mainframe','proxy_bot','code_console','neon_crate','signal_orb']

ICON_NAMES=['credits','data','xp','packets','key','lock','unlock','shield','radar','bolt','glitch','bot','upload','speed','upgrade','tree','replay','settings','map','firewall','exploit','scan','code','cpu','stealth','lab','network','warning','success','target','boost','power']
def icon_32(name):
    im=Image.new('RGBA',(32,32),(0,0,0,0));d=ImageDraw.Draw(im)
    c=P['mint'];alt=P['cyan'];m=P['magenta'];o=P['orange'];w=P['white']
    if name=='credits':
        oval(d,(5,7,26,25),P['green'],c,2);rect(d,(7,9,24,23),P['green']);line(d,[(15,10),(15,23)],c,2);line(d,[(11,13),(19,13),(19,19),(11,19)],w,2)
    elif name=='data':poly(d,[(16,3),(28,16),(16,29),(4,16)],P['cyan2'],alt);poly(d,[(16,7),(24,16),(16,24),(8,16)],alt)
    elif name=='xp':
        rect(d,(5,8,27,24),P['orange'],P['yellow'],2);line(d,[(9,12),(14,20),(19,12),(24,20)],P['back'],2)
    elif name=='packets':
        for i in range(3):rect(d,(5+i*6,6+i*6,15+i*6,16+i*6),P['cyan2'],alt)
    elif name=='key':oval(d,(3,8,16,21),None,c,3);line(d,[(15,18),(28,28)],c,4);line(d,[(23,21),(26,18)],c,2)
    elif name in ('lock','unlock'):
        rect(d,(6,14,26,28),P['red2'] if name=='lock' else P['green'],P['red'] if name=='lock' else c,2)
        d.arc((9 if name=='lock' else 13,4,22 if name=='lock' else 26,21),190 if name=='lock' else 140,350,fill=P['red'] if name=='lock' else c,width=3)
        oval(d,(15,18,18,21),w)
    elif name=='shield':poly(d,[(16,2),(28,7),(26,20),(16,29),(6,20),(4,7)],P['cyan2'],alt);line(d,[(11,15),(15,19),(22,11)],w,2)
    elif name=='radar':
        for r in [5,10,14]:oval(d,(16-r,16-r,16+r,16+r),None,alt)
        line(d,[(16,16),(26,6)],c,2)
    elif name=='bolt':poly(d,[(18,2),(8,17),(15,17),(12,30),(26,12),(19,12)],o,P['yellow'])
    elif name=='glitch':
        for i in range(6):rect(d,(rng.randrange(3,25),4+i*4,rng.randrange(10,30),6+i*4),rng.choice([m,alt,P['red']]))
    elif name=='bot':oval(d,(6,8,26,25),P['metal'],alt,2);rect(d,(12,14,15,17),c);rect(d,(18,14,21,17),c);line(d,[(16,8),(16,4)],alt)
    elif name=='upload':poly(d,[(16,3),(29,17),(21,17),(21,29),(11,29),(11,17),(3,17)],c,P['white'])
    elif name=='speed':
        d.arc((3,4,29,30),180,360,fill=alt,width=3);line(d,[(16,17),(24,8)],c,3)
    elif name=='upgrade':poly(d,[(16,2),(29,17),(22,17),(22,29),(10,29),(10,17),(3,17)],c)
    elif name=='tree':
        line(d,[(16,5),(16,15),(7,15),(7,24)],c,2);line(d,[(16,15),(25,15),(25,24)],c,2)
        for x,y in [(16,6),(7,25),(25,25)]:rect(d,(x-3,y-3,x+3,y+3),P['cyan2'],c)
    elif name=='replay':
        d.arc((4,4,27,27),30,300,fill=c,width=3);poly(d,[(20,2),(29,7),(20,11)],c)
    elif name=='settings':
        oval(d,(7,7,25,25),P['edge'],alt,2);oval(d,(12,12,20,20),P['bg'],c)
        for i in range(8):
            a=i*math.pi/4;x=16+int(12*math.cos(a));y=16+int(12*math.sin(a));rect(d,(x-1,y-1,x+1,y+1),alt)
    elif name=='map':
        poly(d,[(3,6),(12,3),(21,7),(29,4),(29,26),(21,29),(12,25),(3,28)],P['metal'],alt);line(d,[(12,3),(12,25)],c)
    elif name=='firewall':
        rect(d,(3,13,29,28),P['red2'],P['red'],2)
        for x in [7,17]:line(d,[(x,14),(x,26)],P['orange'],2)
    elif name=='exploit':poly(d,[(16,3),(23,12),(27,13),(21,19),(22,27),(16,24),(10,27),(11,19),(5,13),(9,12)],P['purple2'],m)
    elif name=='scan':
        oval(d,(4,4,23,23),None,alt,3);line(d,[(20,21),(29,29)],c,4)
    elif name=='code':txt(im,(4,5),'</>',12,c,True)
    elif name=='cpu':rect(d,(7,7,25,25),P['metal'],c,2);rect(d,(12,12,20,20),P['cyan2'])
    elif name=='stealth':oval(d,(2,10,30,24),None,alt,2);oval(d,(11,11,21,22),P['purple2'],c)
    elif name=='lab':rect(d,(7,5,25,27),P['metal'],alt,2);line(d,[(12,12),(20,12)],c)
    elif name=='network':
        for x,y in [(5,16),(16,6),(26,16),(16,26)]:oval(d,(x-3,y-3,x+3,y+3),c)
        for q in [(5,16),(16,6),(26,16),(16,26)]:line(d,[(16,16),q],alt,1)
    elif name=='warning':poly(d,[(16,2),(30,28),(2,28)],P['red2'],P['red']);line(d,[(16,10),(16,20)],w,3);oval(d,(15,23,17,25),w)
    elif name=='success':oval(d,(3,3,29,29),P['green'],c,2);line(d,[(9,16),(14,22),(24,10)],w,3)
    elif name=='target':
        for r in [12,7,2]:oval(d,(16-r,16-r,16+r,16+r),None,alt,2)
        line(d,[(16,0),(16,7)],c,2)
    elif name=='boost':poly(d,[(16,3),(19,12),(29,13),(22,19),(24,29),(16,24),(8,29),(10,19),(3,13),(13,12)],P['purple2'],P['magenta'])
    elif name=='power':d.arc((5,5,27,27),-45,225,fill=c,width=4);line(d,[(16,2),(16,18)],alt,4)
    else:raise ValueError(name)
    return im

TILE_NAMES=['deck_a','deck_b','grid_a','grid_b','grid_alert','metal_plate','metal_grid','neon_floor','circuit_a','circuit_b','cable_h','cable_v','cable_turn','walkway','hazard','data_stream','server_carpet','hub_floor','noise','purple_floor']
def tile32(name):
    im=Image.new('RGBA',(32,32),(0,0,0,0));d=ImageDraw.Draw(im)
    if name=='deck_a':d.rectangle((0,0,31,31),fill='#131E34');line(d,[(0,0),(31,0)],'#24354F');line(d,[(0,31),(31,31)],'#090F23');d.point([(5,5),(22,27)],fill='#27405A')
    elif name=='deck_b':d.rectangle((0,0,31,31),fill='#10192E');d.rectangle((2,3,29,29),outline='#1B2B41');d.point([(4,17),(19,5),(27,26)],fill='#30506B')
    elif name in ('grid_a','grid_b','grid_alert'):
        base={'grid_a':'#182C40','grid_b':'#152338','grid_alert':'#371E32'}[name];d.rectangle((0,0,31,31),fill=base)
        for x in [0,16]:line(d,[(x,0),(x,31)],'#27415B' if name!='grid_alert' else '#593147')
        for y in [0,16]:line(d,[(0,y),(31,y)],'#27415B' if name!='grid_alert' else '#593147')
        d.point((11,8),fill='#385571' if name!='grid_alert' else '#8D3F5B')
    elif name=='metal_plate':
        d.rectangle((0,0,31,31),fill=P['metal']);rect(d,(2,2,29,29),P['mid'],P['edge']);
        for p in [(5,5),(25,5),(5,25),(25,25)]:d.point(p,fill=P['cyan2'])
    elif name=='metal_grid':
        d.rectangle((0,0,31,31),fill=P['back'])
        for k in range(0,32,8):line(d,[(k,0),(k,31)],P['metal']);line(d,[(0,k),(31,k)],P['metal'])
    elif name=='neon_floor':
        d.rectangle((0,0,31,31),fill='#121936');rect(d,(3,3,28,28),'#182345','#314076');line(d,[(3,28),(28,28)],P['purple'],2)
    elif name in ('circuit_a','circuit_b'):
        d.rectangle((0,0,31,31),fill=P['back']);pts=[(0,16),(11,16),(11,4),(25,4),(25,32)] if name=='circuit_a' else [(10,0),(10,12),(24,12),(24,24),(32,24)]
        line(d,pts,P['cyan2'],2)
        for x,y in pts[1:-1]:rect(d,(x-2,y-2,x+2,y+2),P['mint'])
    elif name=='cable_h':d.rectangle((0,0,31,31),fill=P['back']);line(d,[(0,16),(31,16)],P['edge'],5);line(d,[(0,16),(31,16)],P['cyan2'],2)
    elif name=='cable_v':d.rectangle((0,0,31,31),fill=P['back']);line(d,[(16,0),(16,31)],P['edge'],5);line(d,[(16,0),(16,31)],P['cyan2'],2)
    elif name=='cable_turn':d.rectangle((0,0,31,31),fill=P['back']);line(d,[(0,16),(16,16),(16,32)],P['edge'],5);line(d,[(0,16),(16,16),(16,32)],P['cyan2'],2)
    elif name=='walkway':d.rectangle((0,0,31,31),fill='#26324E');forg='#54627B';line(d,[(0,3),(31,3)],forg,2);line(d,[(0,28),(31,28)],P['back'],2)
    elif name=='hazard':
        d.rectangle((0,0,31,31),fill=P['metal']);
        for x in range(-24,50,12):poly(d,[(x,31),(x+7,31),(x+30,0),(x+23,0)],P['orange'])
    elif name=='data_stream':
        d.rectangle((0,0,31,31),fill=P['back'])
        for i in range(4):line(d,[(i*8+3,0),(i*8+3,32)],P['cyan2'])
        for i in range(8):d.point((i*4,((i*11)%28)+2),fill=P['mint'])
    elif name=='server_carpet':d.rectangle((0,0,31,31),fill='#1B2340');
    elif name=='hub_floor':
        d.rectangle((0,0,31,31),fill='#0F3041');
        for x,y in [(5,3),(17,19),(27,6)]:rect(d,(x,y,x+2,y+2),'#18556A')
    elif name=='noise':
        d.rectangle((0,0,31,31),fill=P['back'])
        rr=random.Random(123)
        for i in range(22):x=rr.randrange(32);y=rr.randrange(32);d.point((x,y),fill=rr.choice(['#22314C','#183550','#182642']))
    elif name=='purple_floor':d.rectangle((0,0,31,31),fill='#1A163E');rect(d,(0,0,31,31),None,'#2E2556')
    return im

def export_assets():
    for n in PROP_NAMES:prop(n).save(ROOT/'assets/props'/f'{n}.png')
    for n in ICON_NAMES:icon_32(n).save(ROOT/'assets/icons'/f'{n}.png')
    for n in TILE_NAMES:tile32(n).save(ROOT/'assets/tiles'/f'{n}.png')

def effects():
    for f in range(10):
        a=Image.new('RGBA',(64,64),(0,0,0,0));d=ImageDraw.Draw(a);rad=5+f*3
        d.ellipse((32-rad,32-rad,32+rad,32+rad),outline=(*hexrgb(P['cyan']),max(0,230-f*23)),width=2 if f<6 else 1)
        for k in range(8):
            ang=k*math.pi/4;xx=32+int(rad*math.cos(ang));yy=32+int(rad*math.sin(ang));d.rectangle((xx,yy,xx+2,yy+2),fill=(*hexrgb(P['mint']),max(0,230-f*20)))
        a.save(ROOT/'assets/fx'/f'scan_pulse_{f:02d}.png')
    for f in range(8):
        a=Image.new('RGBA',(64,64),(0,0,0,0));d=ImageDraw.Draw(a);r=random.Random(400+f)
        for k in range(26):
            x=r.randrange(9,56);y=r.randrange(9,56);c=r.choice([P['cyan'],P['mint'],P['purple'],P['magenta']]);rect(d,(x,y,x+r.randrange(2,7),y+r.randrange(1,5)),c)
        a.save(ROOT/'assets/fx'/f'glitch_{f:02d}.png')
    for f in range(8):
        a=Image.new('RGBA',(64,64),(0,0,0,0));d=ImageDraw.Draw(a);y=50-f*5
        poly(d,[(32,y-8),(39,y),(32,y+8),(25,y)],P['cyan'],P['white'])
        for j in range(4):d.point((32+(j%2)*4, min(63,y+12+j*4)),fill=P['mint'])
        a.save(ROOT/'assets/fx'/f'data_extract_{f:02d}.png')

def hexrgb(x):return tuple(bytes.fromhex(x[1:]))

def ui_assets():
    for n,w,h,col in [('button_primary',176,46,P['mint']),('button_secondary',176,46,P['cyan']),('button_alert',176,46,P['red']),('button_disabled',176,46,P['edge'])]:
        im=Image.new('RGBA',(w,h),(0,0,0,0));d=ImageDraw.Draw(im)
        rect(d,(3,4,w-3,h-3),P['shadow']);rect(d,(1,1,w-5,h-6),P['mid'],col,2);line(d,[(5,4),(w-10,4)],P['light']);rect(d,(8,8,11,h-12),col);im.save(ROOT/'assets/ui'/f'{n}.png')
    for n,w,h in [('panel_small',256,128),('tooltip',304,160),('window',480,288),('hud_counter',108,34),('skill_node',56,56),('selection_card',130,260)]:
        im=Image.new('RGBA',(w,h),(0,0,0,0));d=ImageDraw.Draw(im)
        framed(d,(2,2,w-5,h-5),P['back'],P['edge']);
        rect(d,(8,7,w-12,13),P['metal']);rect(d,(9,h-13,w-12,h-9),P['glass']);
        for x,y in [(6,6),(w-9,6),(6,h-9),(w-9,h-9)]:rect(d,(x,y,x+2,y+2),P['mint'])
        im.save(ROOT/'assets/ui'/f'{n}.png')
    for n,fg in [('bar_full',P['mint']),('bar_alarm',P['red']),('bar_energy',P['cyan'])]:
        im=Image.new('RGBA',(256,24),(0,0,0,0));d=ImageDraw.Draw(im)
        rect(d,(0,3,254,19),P['back'],P['edge'],2)
        for x in range(8,243,12):rect(d,(x,7,x+8,15),fg)
        im.save(ROOT/'assets/ui'/f'{n}.png')
    for n,active,col in [('skill_active',True,P['mint']),('skill_locked',False,P['red']),('skill_available',True,P['cyan'])]:
        im=Image.new('RGBA',(56,56),(0,0,0,0));d=ImageDraw.Draw(im)
        rect(d,(4,6,52,52),P['shadow']);rect(d,(3,3,50,49),P['mid'],col,2);rect(d,(8,9,45,44),P['glass'],P['edge'])
        if not active:im.alpha_composite(icon_32('lock'),(11,9))
        im.save(ROOT/'assets/ui'/f'{n}.png')

# Screenshot rendering primitives
W,H=640,360
PR={n:prop(n) for n in PROP_NAMES}
IC={n:icon_32(n) for n in ICON_NAMES}
TI={n:tile32(n) for n in TILE_NAMES}

def sprite(im,n,x,y,size=32):
    a=PR[n].resize((size,size),R);im.alpha_composite(a,(int(x),int(y)))
def ic(im,n,x,y,size=18):im.alpha_composite(IC[n].resize((size,size),R),(int(x),int(y)))
def framed_ui(im,rect_,title=None,c=None):
    d=ImageDraw.Draw(im);framed(d,rect_,P['back'],c or P['edge'])
    if title:txt(im,(rect_[0]+9,rect_[1]+7),title,9,P['white'],True)
def button(im,b,label,c='mint',mini=False):
    d=ImageDraw.Draw(im);x,y,w,h=b;col=P.get(c,c)
    rect(d,(x+2,y+2,x+w+2,y+h+2),P['shadow']);rect(d,(x,y,x+w,y+h),P['mid'],col,2)
    rect(d,(x+4,y+4,x+6,y+h-4),col)
    txt(im,(x+w//2,y+h//2),label,8 if mini else 10,P['white'],True,'mm')

def backdrop(mode='blue'):
    im=Image.new('RGBA',(W,H),P['bg'] if mode!='red' else '#170E24');d=ImageDraw.Draw(im)
    for y in range(0,H,24):
        for x in range(0,W,24):
            c='#0E1F38' if (x//24+y//24)%2==0 else '#11223B'
            if mode=='red':c='#221423' if (x//24+y//24)%2 else '#1C111F'
            rect(d,(x,y,x+23,y+23),c)
            line(d,[(x+3,y+3),(x+20,y+20)],'#132942' if mode!='red' else '#2A1729')
    return im

def screenshot_hud(im,t,progress,credits=400,data=20,alarm=False):
    d=ImageDraw.Draw(im)
    for i,(nm,q) in enumerate([('credits',credits),('data',data),('xp',int(credits/18))]):
        y=12+i*22
        framed_ui(im,(6,y,79,y+19),c=P['red2'] if alarm else P['edge']);ic(im,nm,10,y+1,16);txt(im,(72,y+9),str(q),10,P['white'],True,'rm')
    txt(im,(326,11),f'{t:02d}s',13,P['white'],True,'mt')
    rect(d,(145,27,496,39),P['back'],P['edge'],1);rect(d,(149,30,149+int(343*progress),36),P['red'] if alarm else P['mint'])
    for j in range(30):
        x=151+j*11
        d.line((x,30,x,36),fill='#236A71' if not alarm else '#734157')
    framed_ui(im,(572,8,632,36));ic(im,'settings',580,15,17);txt(im,(611,21),'ESC',9,P['pale'],False,'mm')

def circuits(im,reg,seed=0):
    x0,y0,x1,y1=reg;r=random.Random(seed);d=ImageDraw.Draw(im)
    for i in range(24):
        x=r.randint(x0+10,x1-10);y=r.randint(y0+8,y1-8);xn=x+r.randint(-16,16);yn=y+r.randint(-16,16)
        line(d,[(x,y),(xn,y),(xn,yn)],P['cyan2'],1);d.point((xn,yn),fill=P['mint'] if i%4==0 else P['edge'])

def world_bg(im,stage=0,seed=2):
    r=random.Random(seed);d=ImageDraw.Draw(im)
    floor=TI['deck_a'] if stage<2 else TI['hub_floor']
    for y in range(0,H,32):
        for x in range(0,W,32):
            im.alpha_composite(floor,(x,y))
            if r.random()<.10:
                z=r.choice(['#264260','#1C3553','#33516C'])
                d.point((x+r.randrange(32),y+r.randrange(32)),fill=z)
    for i in range(70):
        x=r.randrange(W);y=r.randrange(H);c=P['cyan2'] if stage%2 else '#315071';
        if r.random()<.14:spark(d,x,y,c,2)
    for j in range(15):
        x=r.randrange(W);y=r.randrange(H);n=r.choice(['relay_tower','server_cluster','data_cache','antenna','router','server_rack'])
        if x<110 or x>550 or y<42 or y>314:sprite(im,n,x,y,33)

def board_play(seed=3,count=40,alarm=False,mode='standard',seconds=35):
    random.seed(seed);r=random.Random(seed)
    im=Image.new('RGBA',(W,H),P['bg']);world_bg(im,0,seed)
    d=ImageDraw.Draw(im);x0,y0=89,58;tw,th=464,243
    rect(d,(x0-5,y0-4,x0+tw+5,y0+th+5),'#040A12',P['purple2'] if alarm else P['cyan2'],2)
    # tiles
    for y in range(y0,y0+th,16):
        for x in range(x0,x0+tw,16):
            nm='grid_alert' if alarm else ('grid_a' if ((x+y)//16)%3 else 'grid_b')
            im.alpha_composite(TI[nm].crop((0,0,16,16)),(x,y))
    # network trails
    d=ImageDraw.Draw(im)
    r2=random.Random(seed+500)
    for i in range(max(7,count//3)):
        x=r2.randrange(5,28)*16+x0+3;y=r2.randrange(2,14)*16+y0+4
        line(d,[(x,y),(x+16,y),(x+16,y+16)],P['green'] if not alarm else P['red2'],1)
        rect(d,(x-1,y-1,x+1,y+1),P['mint'] if not alarm else P['red'])
    # scatter sprites in discrete slots, left center open around focus
    names=['terminal','server_rack','router','data_cache','access_port','database','cooling_fan','processor','power_cell','encrypted_vault','firewall','quantum_core']
    locations=[(x0+9+cx*21,y0+5+cy*21) for cy in range(11) for cx in range(21)]
    r.shuffle(locations)
    for i,(x,y) in enumerate(locations[:count]):
        n=r.choices(names,weights=[14,10,11,12,12,8,7,6,8,6,9,3],k=1)[0]
        sprite(im,n,x,y,25 if n!='server_rack' else 27)
        if i%6==0:
            rect(d,(x+3,y+23,x+21,y+25),P['back']);rect(d,(x+3,y+23,x+r.randrange(9,19),y+24),P['cyan'] if not alarm else P['red'])
    # Auto scripts and harvest particles
    if count>50:
        for i in range(5 if count<115 else 12):
            x=r.randrange(x0+20,x0+tw-20);y=r.randrange(y0+20,y0+th-20)
            sprite(im,'bot_drone',x,y,31);spark(d,x+13,y-4,P['cyan'])
    if count>90:
        for i in range(38):
            x=r.randrange(x0+5,x0+tw-10);y=r.randrange(y0+3,y0+th-5)
            d.point([(x,y),(x+2,y)],fill=r.choice([P['cyan'],P['mint'],P['purple'],P['yellow']]))
    # targeting reticle
    cx,cy=x0+tw//2,y0+th//2
    d.ellipse((cx-21,cy-21,cx+21,cy+21),outline=P['cyan'],width=2)
    line(d,[(cx-29,cy),(cx-17,cy)],P['cyan']);line(d,[(cx+17,cy),(cx+29,cy)],P['cyan'])
    line(d,[(cx,cy-29),(cx,cy-17)],P['cyan']);line(d,[(cx,cy+17),(cx,cy+29)],P['cyan'])
    spark(d,cx,cy,P['mint'],3)
    screenshot_hud(im,seconds, .28 if count<30 else (.63 if count<115 else .83),200+count*53, 12+count//6,alarm)
    if mode=='late':
        framed_ui(im,(221,70,437,128),'SECURITY BREACH',P['red'])
        txt(im,(329,105),'DATA EXTRACTED +2048',11,P['mint'],True,'mm')
    button(im,(545,322,86,26),'UPGRADES','cyan',True)
    txt(im,(86,335),('BETA // RED NODE' if alarm else 'KEEP HACKING // NETRUN'),8,P['pale'])
    return im

def draw_node(im,cx,cy,idx,locked=False,selected=False,small=False):
    d=ImageDraw.Draw(im);size=30 if small else 34
    x=cx-size//2;y=cy-size//2;c=P['red'] if locked else P['mint'] if selected else P['cyan2']
    rect(d,(x+2,y+2,x+size+2,y+size+2),P['shadow']);rect(d,(x,y,x+size,y+size),P['mid'],c,2)
    rect(d,(x+4,y+4,x+size-4,y+size-4),P['back'])
    icons=['power','code','radar','shield','data','cpu','bot','speed','target','stealth','glitch','network','scan','exploit']
    ic(im,'lock' if locked else icons[idx%len(icons)],x+6,y+6,size-12)

def skill_screen(dense=False):
    im=backdrop();d=ImageDraw.Draw(im)
    # subtle PCB background pattern
    for k in range(34):
        x=(k*83)%650-10;y=(k*59)%400
        line(d,[(x,y),(x+35,y),(x+35,y+8)],'#142D49');rect(d,(x+35,y+7,x+37,y+9),'#184361')
    if dense:
        levels=[[(34,66),(80,66),(126,66),(172,66),(218,66),(265,66),(311,66),(357,66),(403,66),(450,66),(498,66),(548,66),(594,66)],
             [(80,128),(173,128),(267,128),(358,128),(451,128),(548,128)],
             [(36,190),(81,190),(126,190),(172,190),(218,190),(264,190),(310,190),(358,190),(404,190),(451,190),(498,190),(548,190),(593,190)],
             [(81,255),(172,255),(265,255),(358,255),(450,255),(548,255)]]
        nodes=[p for row in levels for p in row]
        for i in range(len(levels[0])-1):line(d,[levels[0][i],levels[0][i+1]],P['green'],2)
        for rr in range(1,len(levels)):
            for j,p in enumerate(levels[rr]):
                q=levels[rr-1][(j*2)%len(levels[rr-1])]
                line(d,[p,(p[0],q[1]),q],P['green'] if rr<3 else P['cyan2'],1)
        for i,p in enumerate(nodes):draw_node(im,p[0],p[1],i,locked=i%7==0,selected=i%4==0,small=True)
        txt(im,(26,19),'UPGRADE NETWORK',15,P['white'],True)
        txt(im,(545,23),'46 / 62',10,P['mint'],True)
    else:
        nodes=[(175,75),(253,75),(331,75),(409,75),(210,145),(288,145),(366,145),(446,145),(175,218),(253,218),(331,218),(409,218)]
        edges=[(0,4),(1,5),(2,6),(3,7),(4,5),(5,6),(6,7),(4,8),(5,9),(6,10),(7,11)]
        for a,b in edges:line(d,[nodes[a],nodes[b]],P['green'] if a%2 else P['cyan2'],2)
        for i,p in enumerate(nodes):draw_node(im,p[0],p[1],i,locked=i>=7,selected=i<=4)
        framed_ui(im,(228,137,409,219),'PACKET OVERCLOCK',P['cyan'])
        txt(im,(242,163),'Faster scan cycles',10,P['white'])
        txt(im,(242,180),'+20% / run',11,P['mint'],True)
        txt(im,(241,204),'COST  350',10,P['yellow'],True)
        txt(im,(26,19),'RESEARCH / UPGRADES',14,P['white'],True)
    rect(d,(0,323,639,359),P['back'],P['edge'],1)
    ic(im,'settings',13,331,19);ic(im,'credits',247,333,18)
    txt(im,(268,342),'240,540',10,P['mint'],True)
    ic(im,'data',340,333,18);txt(im,(366,342),'24',10,P['cyan'])
    button(im,(486,330,68,24),'MAP','mint',True);button(im,(560,330,68,24),'RUN','orange',True)
    return im

def selection_screen():
    im=backdrop();d=ImageDraw.Draw(im)
    txt(im,(320,18),'SELECT YOUR TARGET NETWORK',17,P['white'],True,'mt')
    names=['HOME LAB','TECH CAMPUS','DATA CENTER','DARK GRID'];caps=['SANDBOX','MID SECURITY','HARD MODE','NIGHTMARE']
    colors=[P['cyan'],P['mint'],P['purple'],P['red']]
    for idx in range(4):
        x=48+idx*146;y=62;col=colors[idx]
        rect(d,(x+4,y+4,x+132,y+251),P['shadow']);rect(d,(x,y,x+128,y+247),P['mid'],col,2)
        # illustration slice
        rect(d,(x+6,y+22,x+122,y+151),['#102C3A','#112745','#1B1B42','#311323'][idx])
        for k in range(9):
            px=x+10+(k*37)%100;py=y+31+(k*29)%108
            sprite(im,['terminal','server_rack','cooling_fan','mainframe'][idx],px,py,29 if idx<2 else 30)
        rect(d,(x+4,y+2,x+124,y+24),P['back'],col,1)
        txt(im,(x+64,y+13),names[idx],10,P['white'],True,'mm')
        for i in range(4):
            xx=x+23+(i%2)*53;yy=y+171+(i//2)*39
            rect(d,(xx-13,yy-13,xx+15,yy+15),P['back'],P['edge'])
            ic(im,'lock' if idx>=2 else ['scan','shield','speed','data'][i],xx-10,yy-10,21)
        if idx>=2:
            rect(d,(x+4,y+223,x+124,y+244),P['back']);ic(im,'lock',x+38,y+223,20);txt(im,(x+83,y+232),'LOCKED',9,P['red'],True,'mm')
        else:
            txt(im,(x+64,y+235),caps[idx],8,col,True,'mm')
    button(im,(518,325,108,24),'RUN TARGET','mint',True)
    txt(im,(31,339),'KEEP HACKING  //  CHOOSE TARGET',9,P['pale'])
    return im

def hub_screen():
    im=Image.new('RGBA',(W,H),P['bg']);world_bg(im,2,22);d=ImageDraw.Draw(im)
    # grid city streets, dense neon neighborhood
    for x0,y0,x1,y1 in [(0,135,640,156),(0,274,640,300),(152,0,173,345),(355,0,376,345),(515,0,536,345)]:
        rect(d,(x0,y0,x1,y1),'#15273A',P['metal'],1)
    for i in range(25):
        x=(i*71+13)%640;y=(i*89+8)%324+12
        if x%5<4:
            sprite(im,random.choice(['antenna','relay_tower','server_cluster','router']),x,y,27)
    bld=[(38,54,'terminal_desk','HOME BASE',P['mint']),(209,53,'server_cluster','OFFICE GRID',P['cyan']),
        (399,65,'mainframe','CLOUD NODE',P['purple']),(63,187,'database','ARCHIVES',P['mint']),(229,186,'quantum_core','DATA VAULT',P['cyan']),(432,181,'vault_door','FIREWALL',P['red'])]
    for idx,(x,y,n,label,col) in enumerate(bld):
        rect(d,(x+2,y,x+142,y+92),P['back'],col if idx<2 else P['edge'],2)
        for j in range(3):sprite(im,n,x+15+j*38,y+12,45)
        rect(d,(x+5,y+70,x+139,y+90),P['back']);txt(im,(x+72,y+80),label,10,P['white'],True,'mm')
        if idx>2:ic(im,'lock',x+110,y+24,20)
    rect(d,(0,0,640,38),P['back'],P['cyan2'],2)
    txt(im,(19,17),'NEXUS DISTRICT',15,P['white'],True,'lm');txt(im,(445,17),'INCOME  +63 / SEC',10,P['mint'],True)
    rect(d,(0,319,640,360),P['back'],P['edge'])
    txt(im,(14,338),'CONNECTIONS  04 / 12',10,P['white'])
    button(im,(416,326,96,27),'RESEARCH','cyan',True);button(im,(520,326,105,27),'HACK NOW','mint',True)
    return im

def title_screen():
    im=backdrop();d=ImageDraw.Draw(im)
    for i in range(20):
        x=50+(i*57)%560;y=20+(i*61)%320
        sprite(im,['server_cluster','terminal','quantum_core','firewall'][i%4],x,y,40)
    rect(d,(110,55,530,301),P['back'],P['cyan2'],2)
    txt(im,(320,116),'KEEP HACKING',31,P['mint'],True,'mm')
    txt(im,(320,156),'INFILTRATE > EXTRACT > UPGRADE',12,P['cyan'],True,'mm')
    button(im,(237,198,169,35),'NEW RUN','mint')
    button(im,(237,245,169,35),'UPGRADES','cyan')
    return im

def save_screens():
    # Render at 640x360 pixel art, upscale exactly 2x (1280x720).
    scenes=[('01_first_breach',board_play(4,20,True,'standard',32)),
            ('02_upgrade_details',skill_screen(False)),
            ('03_automated_intrusion',board_play(19,155,False,'standard',24)),
            ('04_network_selection',selection_screen()),
            ('05_nexus_district',hub_screen()),
            ('06_midgame_scan',board_play(13,72,False,'standard',28)),
            ('07_full_research_tree',skill_screen(True)),
            ('08_final_breach',board_play(29,192,True,'late',44))]
    for n,im in scenes:im.convert('RGB').resize((1280,720),R).save(ROOT/'screenshots'/f'{n}.png',optimize=True)
    return [n for n,_ in scenes]

def make_atlas(names,folder,name,cellsz,columns):
    rows=math.ceil(len(names)/columns)
    atlas=Image.new('RGBA',(cellsz*columns,cellsz*rows),(0,0,0,0))
    for i,n in enumerate(names):
        spriteim=Image.open(ROOT/'assets'/folder/f'{n}.png').convert('RGBA')
        atlas.alpha_composite(spriteim,(i%columns*cellsz,i//columns*cellsz))
    atlas.save(ROOT/'assets/atlases'/f'{name}.png')
    return {'file':f'assets/atlases/{name}.png','columns':columns,'cell_width':cellsz,'cell_height':cellsz,'items':names}

def make_sheet_preview():
    # Overview with labels, does not replace transparent individual PNG assets.
    ww,hh=1120,1000
    p=Image.new('RGBA',(ww,hh),P['bg']);d=ImageDraw.Draw(p)
    txt(p,(30,24),'KEEP HACKING  //  GAME-READY ASSETS',24,P['mint'],True)
    txt(p,(30,58),'32-bit RGBA PNG  -  PIXEL-ART  -  NEON CYBER GRID',12,P['pale'])
    for i,n in enumerate(PROP_NAMES):
        col=i%8;row=i//8;x=22+col*138;y=92+row*124
        rect(d,(x,y,x+128,y+111),P['back'],P['metal']);
        p.alpha_composite(PR[n].resize((80,80),R),(x+24,y+2))
        txt(p,(x+64,y+97),n.replace('_',' ').upper(),9,P['white'],True,'mm')
    offset=92+5*124+18
    txt(p,(29,offset),'ICON LANGUAGE',16,P['cyan'],True)
    for i,n in enumerate(ICON_NAMES):
        x=27+i%16*68;y=offset+33+i//16*67
        rect(d,(x,y,x+60,y+57),P['back'],P['metal'])
        p.alpha_composite(IC[n].resize((36,36),R),(x+12,y+2))
        txt(p,(x+30,y+48),n[:9].upper(),7,P['pale'],False,'mm')
    p.convert('RGB').save(ROOT/'assets/asset_catalog.png',optimize=True)


def build_manifest(atlases,scenes):
    m={
        'title':'Keep Hacking - Original Pixel Asset Pack',
        'version':'0.9.1', 'reference':'Keep Watering (visual/gameplay research only; no original images included)',
        'license':'Original procedurally authored art. Check third-party rights before shipping the separately generated concept image.',
        'native_dimensions':{'props':[64,64],'icons':[32,32],'tiles':[32,32],'fx':[64,64], 'screenshots':[1280,720]},
        'transparent_pngs':True,
        'palette':P,
        'assets':{
            'props':{n:f'assets/props/{n}.png' for n in PROP_NAMES},
            'icons':{n:f'assets/icons/{n}.png' for n in ICON_NAMES},
            'tiles':{n:f'assets/tiles/{n}.png' for n in TILE_NAMES},
            'effects':{key:f'assets/fx/{key}.png' for key in [*(f'scan_pulse_{f:02d}' for f in range(10)),*(f'glitch_{f:02d}' for f in range(8)),*(f'data_extract_{f:02d}' for f in range(8))]},
            'ui':{p.stem:str(p.relative_to(ROOT)) for p in sorted((ROOT/'assets/ui').glob('*.png'))},
        },
        'atlases':atlases,
        'screenshot_mapping':{
            '01_first_breach':'Reference screenshot 1: initial timed gameplay, low-density network, red-alert zone',
            '02_upgrade_details':'Reference screenshot 2: research tree with upgrade hover details',
            '03_automated_intrusion':'Reference screenshot 3: fully populated high-automation run',
            '04_network_selection':'Reference screenshot 4: select four increasingly secure networks',
            '05_nexus_district':'Reference screenshot 5: progression hub with locked sectors',
            '06_midgame_scan':'Reference screenshot 6: medium-population run',
            '07_full_research_tree':'Reference screenshot 7: large upgrade research network',
            '08_final_breach':'Reference screenshot 8: late run with alarms and extraction',
        },
        'screenshots':{n:f'screenshots/{n}.png' for n in scenes}
    }
    (ROOT/'manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')

if __name__=='__main__':
    print('Making assets...')
    export_assets();effects();ui_assets()
    a1=make_atlas(PROP_NAMES,'props','props_64',64,8)
    a2=make_atlas(ICON_NAMES,'icons','icons_32',32,8)
    a3=make_atlas(TILE_NAMES,'tiles','tiles_32',32,8)
    fxfiles=sorted(p.stem for p in (ROOT/'assets/fx').glob('*.png'))
    a4=make_atlas(fxfiles,'fx','fx_64',64,8)
    print('Rendering 8 previews...')
    scenes=save_screens();make_sheet_preview();build_manifest([a1,a2,a3,a4],scenes)
    print('Finished',len(PROP_NAMES),'props',len(ICON_NAMES),'icons',len(TILE_NAMES),'tiles',len(fxfiles),'FX frames',len(scenes),'screens')

def extra_exports():
    (ROOT/'assets/marketing').mkdir(exist_ok=True)
    # Full-size background plates for menus, including non-transparent variants.
    for mode,n in [('blue','ui_blue_background_1280x720'),('red','ui_red_background_1280x720')]:
        im=backdrop(mode).convert('RGB').resize((1280,720),R)
        im.save(ROOT/'assets/backgrounds'/f'{n}.png',optimize=True)
    # Brand logotype on genuine transparent background.
    im=Image.new('RGBA',(600,150),(0,0,0,0));d=ImageDraw.Draw(im)
    txt(im,(29,27),'KEEP',58,P['white'],True)
    txt(im,(29,80),'HACKING',58,P['mint'],True)
    line(d,[(30,141),(423,141),(451,123),(522,123)],P['cyan'],3)
    spark(d,539,122,P['magenta'],8)
    im.resize((1200,300),R).save(ROOT/'assets/marketing'/'logo_keep_hacking_transparent.png',optimize=True)
    # Original cyber-style Steam capsule, completely built from pack primitives.
    cap=Image.new('RGBA',(616,353),P['bg']);d=ImageDraw.Draw(cap)
    for yy in range(0,353,14):
        for xx in range(0,616,14):
            color='#101B35' if (xx//14+yy//14)%2 else '#121F39'
            rect(d,(xx,yy,xx+13,yy+13),color)
    for k in range(24):
        x=(k*73)%616;y=(k*43)%353
        line(d,[(x,y),(x+40,y),(x+40,y-9)],'#1C5A75',2)
        spark(d,x+40,y-9,P['cyan2'],2)
    for x,y,n,s in [(9,156,'server_cluster',166),(414,147,'mainframe',177),(118,200,'terminal',105),(378,208,'quantum_core',105)]:
        sprite(cap,n,x,y,s)
    # center title backing, shadow and accents
    rect(d,(75,54,553,213),'#071120',P['cyan2'],3)
    txt(cap,(313,97),'KEEP',54,P['white'],True,'mm')
    txt(cap,(313,164),'HACKING',61,P['mint'],True,'mm')
    rect(d,(55,221,561,259),P['back'],P['cyan2'],2)
    txt(cap,(313,240),'SCAN  >  BREACH  >  EXTRACT  >  UPGRADE',13,P['cyan'],True,'mm')
    txt(cap,(310,313),'ONE MORE RUN. ONE MORE ACCESS.',13,P['white'],True,'mm')
    cap.convert('RGB').save(ROOT/'assets/marketing'/'steam_capsule_616x353.png',optimize=True)
    # Wider screenshot banner with the original generated game concept at the center.
    conceptpath=ROOT/'concept'/'01_gameplay_concept.png'
    if conceptpath.exists():
        base=Image.open(conceptpath).convert('RGB');bw,bh=base.size
        tw,th=1920,1080
        ratio=max(tw/bw,th/bh);b=base.resize((int(bw*ratio),int(bh*ratio)),Image.Resampling.LANCZOS)
        ox=(b.width-tw)//2;oy=(b.height-th)//2
        b=b.crop((ox,oy,ox+tw,oy+th)).convert('RGBA')
        tint=Image.new('RGBA',(tw,265),(3,8,19,180));b.alpha_composite(tint,(0,0))
        logo=Image.open(ROOT/'assets/marketing'/'logo_keep_hacking_transparent.png')
        b.alpha_composite(logo.resize((720,180),R),(65,40))
        b.convert('RGB').save(ROOT/'assets/marketing'/'key_art_1920x1080.png',quality=95)
    # Large contact sheet with all eight gameplay/selection/research screenshots.
    thumbs=sorted((ROOT/'screenshots').glob('*.png'))
    ow,oh=1410,1660;out=Image.new('RGB',(ow,oh),P['bg']);dd=ImageDraw.Draw(out)
    txt(out,(35,18),'KEEP HACKING  //  8 SCENE CONCEPTS',23,P['mint'],True)
    for idx,pp in enumerate(thumbs):
        x=32+idx%2*700;y=90+idx//2*393
        src=Image.open(pp).convert('RGB');src.thumbnail((650,366),Image.Resampling.LANCZOS)
        out.paste(src,(x,y))
        title=pp.stem.replace('_',' ').upper()
        txt(out,(x+5,y+378),title,13,P['white'],True)
    out.save(ROOT/'screenshots'/'00_contact_sheet.png',optimize=True)
    # Crop unused vertical whitespace from the catalog.
    catalogpath=ROOT/'assets'/'asset_catalog.png'
    cat=Image.open(catalogpath)
    cat.crop((0,0,cat.width,918)).save(catalogpath,optimize=True)

extra_exports()

def update_manifest_for_extras():
    mp=ROOT/'manifest.json';mf=json.loads(mp.read_text())
    mf['assets']['backgrounds']={p.stem:str(p.relative_to(ROOT)) for p in sorted((ROOT/'assets/backgrounds').glob('*.png'))}
    mf['assets']['marketing']={p.stem:str(p.relative_to(ROOT)) for p in sorted((ROOT/'assets/marketing').glob('*.png'))}
    mf['concepts']={p.stem:str(p.relative_to(ROOT)) for p in sorted((ROOT/'concept').glob('*.png'))}
    mf['screenshots']['00_contact_sheet']='screenshots/00_contact_sheet.png'
    mf['asset_catalog']='assets/asset_catalog.png'
    mp.write_text(json.dumps(mf,ensure_ascii=False,indent=2),encoding='utf-8')
update_manifest_for_extras()
