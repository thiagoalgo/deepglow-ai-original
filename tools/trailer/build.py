import subprocess, os
ROOT=os.path.abspath(os.path.join(os.path.dirname(__file__),'..','..'))
C=os.environ.get('CAPTURE_DIR','capture')+'/'
B=60/128*4  # one bar at 128 BPM
import sys
V=sys.argv[1] if len(sys.argv)>1 else '45'
if V=='30':
    TOTAL=30; RUSH=18.75; FADE=27.5; END='endcard_soon.png'; OUT='deepglow_trailer_30s_1080p.mp4'
    segs=[('b01',0.5,2),('b02',4.0,2),('b01',22.4,1),('tree',1.5,2),('b03',4.0,1),('b04',4.0,1),('b05',4.0,1),('b06',4.5,1),
     ('b01',32,.5),('b02',8.5,.5),('b05',40,.5),('b06',40,.5)]
    caps=[('c1.png',0.5,3.5),('c2.png',3.9,7.3),('c3.png',9.6,12.9),('c4.png',13.3,16.7),('c5.png',20.8,24.2)]
else:
    TOTAL=45; RUSH=30; FADE=41.5; END='endcard.png'; OUT='deepglow_trailer_steam_1080p.mp4'
    segs=[('b01',0.5,3),('b02',4.0,2),('b01',22.4,1),('tree',1.5,3),('b03',4.0,2),('b04',4.0,2),('b05',4.0,2),('b06',4.5,2),
     ('b01',32,.5),('b02',8.5,.5),('b03',39.5,.5),('b04',39.5,.5),('b05',40,.5),('b06',40,.5),('b05',9,.5),('b03',9,.5)]
    caps=[('c1.png',0.8,3.6),('c2.png',5.9,8.9),('c3.png',11.6,14.8),('c4.png',17.1,20.3),('c5.png',35.8,39.2)]
os.makedirs('seg',exist_ok=True)
lst=[]; t=0; frames_total=0
for i,(src,start,bars) in enumerate(segs):
    # frame-exact durations at 30fps
    end_f=round((t+bars*B)*30); nf=end_f-frames_total; frames_total=end_f; t+=bars*B
    out=f'seg/s{i:02d}.mp4'
    subprocess.run(['ffmpeg','-v','error','-y','-ss',str(start),'-i',C+src+'.mp4','-frames:v',str(nf),'-t',str(nf/30),
      '-c:v','libx264','-crf','10','-preset','fast','-pix_fmt','yuv420p','-r','30','-c:a','pcm_s16le','-ar','48000','-ac','2',out.replace('.mp4','.mkv')],check=True)
    lst.append(f"file '{out.replace('.mp4','.mkv')}'")
# end card
end_len=TOTAL-frames_total/30
subprocess.run(['ffmpeg','-v','error','-y','-loop','1','-i',END,'-f','lavfi','-i','anullsrc=r=48000:cl=stereo','-t',str(end_len),
  '-vf','fade=in:st=0:d=0.5,fps=30,format=yuv420p','-c:v','libx264','-crf','10','-preset','fast','-c:a','pcm_s16le','seg/zend.mkv'],check=True)
lst.append("file 'seg/zend.mkv'")
open('list.txt','w').write('\n'.join(lst))
subprocess.run(['ffmpeg','-v','error','-y','-f','concat','-safe','0','-i','list.txt','-c','copy','body.mkv'],check=True)
print('gameplay ends', frames_total/30)
M=os.path.join(ROOT,'assets/audio/music/')
inputs=['-i','body.mkv']
for c,_,_ in caps: inputs+=['-i',c]
inputs+=['-stream_loop','1','-i',M+'camp_fast.ogg','-stream_loop','1','-i',M+'camp_fast_rush.ogg']
fc='[0:v]fade=in:st=0:d=0.4[v0];'
for k,(c,a,b) in enumerate(caps):
    fc+=f"[v{k}][{k+1}:v]overlay=0:0:enable='between(t,{a},{b})'[v{k+1}];"
n=len(caps)
fc+=f"[v{n}]fade=out:st={TOTAL-0.8}:d=0.8[vout];"
mi=n+1; ri=n+2
fc+=f"[{mi}:a]atrim=0:{TOTAL},volume=0.8[mus];"
fc+=f"[{ri}:a]atrim=0:{TOTAL},volume=0.8,afade=in:st={RUSH}:d=1.5[rush];"
fc+=f"[0:a]volume=0.75[sfx];"
fc+=f"[mus][rush][sfx]amix=inputs=3:normalize=0:duration=first,afade=out:st={FADE}:d={TOTAL-FADE},volume=2dB,alimiter=limit=0.79:level=0[aout]"
subprocess.run(['ffmpeg','-v','error','-y',*inputs,'-filter_complex',fc,'-map','[vout]','-map','[aout]','-t',str(TOTAL),
 '-c:v','libx264','-preset','slow','-b:v','5.6M','-minrate','5.4M','-maxrate','10M','-bufsize','10M','-pix_fmt','yuv420p','-profile:v','high','-r','30',
 '-c:a','aac','-b:a','256k','-ar','48000','-movflags','+faststart',OUT],check=True)
