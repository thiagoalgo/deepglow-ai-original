from PIL import Image, ImageDraw, ImageFont
import os
ROOT=os.path.abspath(os.path.join(os.path.dirname(__file__),'..','..'))
FONT=os.path.join(ROOT,'assets/fonts/m5x7.ttf')
TEAL=(55,242,194); FILL=(13,19,52); BORDER=(58,70,163); OUT=(8,13,36); WHITE=(217,245,242); AMBER=(246,168,74); PINK=(237,120,183); YEL=(241,237,101)
def font(s): return ImageFont.truetype(FONT, s)
def text_size(d,t,f):
    b=d.textbbox((0,0),t,font=f); return b[2]-b[0], b[3]-b[1], b[1]
def panel(d,x0,y0,x1,y1):
    # stepped corners, 2px border, flat fill
    d.rectangle([x0+2,y0,x1-2,y1],fill=BORDER); d.rectangle([x0,y0+2,x1,y1-2],fill=BORDER)
    d.rectangle([x0+2,y0+2,x1-2,y1-2],fill=FILL)
def caption(name,line,sub=None,color=TEAL,y=None):
    im=Image.new('RGBA',(640,360),(0,0,0,0)); d=ImageDraw.Draw(im); d.fontmode='1'
    f=font(32); w,h,top=text_size(d,line,f)
    ws=0
    if sub:
        fs=font(16); ws,hs,tops=text_size(d,sub,fs)
    W=max(w,ws)+32; H=h+20+(18 if sub else 0)
    x0=(640-W)//2//2*2; y0=y if y is not None else 356-H
    panel(d,x0,y0,x0+W,y0+H)
    d.text(((640-w)//2, y0+8-top+1), line, font=f, fill=OUT)
    d.text(((640-w)//2, y0+8-top), line, font=f, fill=color)
    if sub:
        d.text(((640-ws)//2, y0+8+h+6-tops), sub, font=fs, fill=WHITE)
    im.resize((1920,1080),Image.NEAREST).save(name)
caption('c1.png','Harvest a glowing forest')
caption('c2.png','Race the night', 'Every phase ends at dusk', color=AMBER)
caption('c3.png','Grow your upgrade tree', color=YEL)
caption('c4.png','Six bioluminescent biomes', color=TEAL)
caption('c5.png','Reach the light below', color=PINK)
# end card: background + title
bg=Image.open(os.path.join(ROOT,'assets/sprites/board/background.png')).convert('RGB')
from PIL import ImageEnhance
dark=bg.point(lambda v:int(v*0.55))
d=ImageDraw.Draw(dark); d.fontmode='1'
f=font(96); t='DEEPGLOW'; w,h,top=text_size(d,t,f)
x=(640-w)//2; y=120-top
for dx,dy in [(-2,0),(2,0),(0,-2),(0,2),(2,2),(4,4)]:
    d.text((x+dx,y+dy),t,font=f,fill=OUT)
d.text((x,y),t,font=f,fill=TEAL)
f2=font(32); import sys
t2=sys.argv[1] if len(sys.argv)>1 else 'Wishlist now on Steam'; w2,h2,top2=text_size(d,t2,f2)
panel(d,(640-w2)//2-18,228,(640+w2)//2+18,228+h2+20)
d.text(((640-w2)//2,236-top2),t2,font=f2,fill=WHITE)
f3=font(16); t3='An incremental adventure into the deep'; w3,_,top3=text_size(d,t3,f3)
d.text(((640-w3)//2,200-top3),t3,font=f3,fill=(154,107,222))
dark.resize((1920,1080),Image.NEAREST).save(sys.argv[2] if len(sys.argv)>2 else 'endcard.png')
