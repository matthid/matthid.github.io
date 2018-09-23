---
layout: post
title: "Stream Amazon Prime to UPNP Devices via WLAN"
---

Ok this is weird: 
I simply want to stream an Amazon Prime movie to our receiver supporting UPNP to be able to watch the film on the big TV screen 
and ideally use the notebook at the same time.
Why is this so incredibly hard to realize and you need several software projects to realize it?

First I tried to use plugins for already existing software within our network. Namely:

 - [Amazon Prime Plugin for Plex](https://forums.plex.tv/discussion/136247/amazon-prime-plug-in), which doesn't exist apparently
 - The people from the plex thread talk about [a plugin for XBMC/Kodi](https://github.com/XLordKX/kodi).
   The plugin wouldn't even install on the device I wanted (older debian installation).
   But out of curiousity I tried with the latest version on Windows, installed the plugin
   and tadaaah it didn't work [Issue1](https://github.com/XLordKX/kodi/issues/33) and [Issue2](https://github.com/XLordKX/kodi/issues/35).
   So the plugin is no longer usable...
 - Because we have an older linux device in place (exactly for watching stuff) I tried to just login and play the videos there, however firefox and chromium 
   apparently get no love from amazon. I even installed the latest chrome, but amazon would tell me something about missing plugins :(
   (Note that this wasn't my prefered solution anyway...)
   
Obviously it isn't as simple as I thought initially. So how about a more generic solution.
What if I just stream the whole desktop to the device?

If you start googleing about this it [really](http://www.computerhilfen.de/hilfen-22-412113-0.html) 
[looked](https://software.grok.lsu.edu/article.aspx?articleid=14625) like VLC is the way to go.
I tried. I really tried. But whenever I tried to forward the desktop to a stream (`http://`, `udp` or whatever) VLC crashed.
So while in theory VLC does exactly what we need it doesn't work (at least it didn't for me).


Now several hours later I'm still not ready to give up. How can such a simple thing not work?
You know what? Gaming has been really successfull in streaming things via twitch.tv, 
so I guess I should look there for mature software and see how far I can get...


First I installed [OBS](https://obsproject.com/) the first software recommended by [Twitch.tv](http://help.twitch.tv/customer/portal/articles/792761-how-to-broadcast-pc-games)
and actually open source (so I thought it might be open enough to do other things than stream for twitch.tv).
So now OBS is designed to stream to a streaming server and not to UPNP device so I need my own streaming server.
After some more help from google it was clear that OBS itself provides the required [documentation](https://obsproject.com/forum/resources/how-to-set-up-your-own-private-rtmp-server-using-nginx.50/) to do it.
The only problem is that I'm using windows and had no intention of compiling anything, therefore I used [a precompiled nginx version with rtmp support](https://github.com/illuspas/nginx-rtmp-win32).

For recording I used the following trick:

 - Before starting chrome change the default audio device to a virtual one (or one that isn't connected/unused):
   ![Screenshot Setup before starting chrome](/public/images/blog/2015-12-22/pre-chrome.jpg "pre-chrome")
 - Now I can add the device to OBS (and hear it later correctly synced on the UPNP device via stream)
 - Start chrome
 - Add the chrome windows to OBS as you like:
   ![Screenshot Setup after starting chrome](/public/images/blog/2015-12-22/after-chrome.jpg "after-chrome")


For nginx I basically used the exact configuration from the documentation above:

`C:\Users\dragon\Downloads\nginx-rtmp-win32-master\conf`:

```text
worker_processes  1;

error_log  logs/error.log debug;

events {
    worker_connections  1024;
}

rtmp {
    server {
        listen 8089;
        #chunk_size 256;

        #wait_key on;
        #wait_video on;
		
        application live {
            live on;
            record off;

            #wait_key on;
            #interleave on;
            #publish_notify on;
            #sync 10ms;
            #wait_video on;
            #allow publish 127.0.0.1;
            #deny publish all;
            #allow play all;
        }
		
		#application hls {
		#	live on;
		#	hls on;  
		#	hls_path temp/hls;  
		#	hls_fragment 8s;  
		#}
    }
}

http {
    server {
        listen      8088;
		
        location / {
            root www;
        }
		
        location /stat {
            rtmp_stat all;
            rtmp_stat_stylesheet stat.xsl;
        }

        location /stat.xsl {
            root www;
        }
		
		location /hls {  
           #server hls fragments  
			types{  
				application/vnd.apple.mpegurl m3u8;  
				video/mp2t ts;  
			}  
			alias temp/hls;  
			expires -1;  
        }  

    }
}
```

I like that the pre compiled nginx already has setup a page where I can directly what the stream if I want to.

After starting nginx in a console window (or by double clicking nginx.exe) your streaming server should be ready and you can finalize the OBS setup and start the stream:

- First make sure you setup the "Stream" settings exactly the way you setup the nginx configuration.
  Note that the Stream key doesn't matter (here I use "test") but is used again later:
  ![Screenshot Setup 'Stream'](/public/images/blog/2015-12-22/setup-stream.jpg "setup-stream")

- Then setup the output in a way suited to you (I only use an higher bitrate for better quality):
  ![Screenshot Setup 'Output'](/public/images/blog/2015-12-22/setup-output.jpg "setup-output")

- Then setup the video in a way suited to your TV (change to the optimal resolution for your TV):
  ![Screenshot Setup 'Video'](/public/images/blog/2015-12-22/setup-video.jpg "setup-video")

Now the stream can be started successfully and we can even watch it via `http://localhost:8088` by entering `rtmp://127.0.0.1:8089/live/test` in the box.

We are almost there, because we only need to bridge the gap between the rtmp stream and the UPNP device. 
Luckily [serviio](http://serviio.org/download) can close the gap:

![Screenshot Setup 'Serviio'](/public/images/blog/2015-12-22/add-stream-to-serviio.jpg "add-stream-to-serviio")

## Further information for this setup

- There is definitely a high delay (several seconds) depending on your configuration as this is not meant to be 'live'.

- Note that you can even lock your laptop, the stream will continue to work!

- You can however not 'minimize' chrome (move it to the edge of the screen)

- This method is not limited to Amazon Prime at all, stream whatever you like!

- If you don't mind the delay you can use the UPNP device as second monitor:

  - First setup a fake display like [this](http://superuser.com/questions/62051/is-there-a-way-to-fake-a-dual-second-monitor),
    [that](http://superuser.com/questions/947291/can-a-fake-second-display-be-enabled-in-windows-10) or use a [HDMI-to-VGA adapter](http://www.amazon.de/s/ref=nb_sb_noss?__mk_de_DE=%C3%85M%C3%85%C5%BD%C3%95%C3%91&url=search-alias%3Daps&field-keywords=HDMI+to+VGA)
    This will make windows think that a second monitor is attached.
  - Now you can setup OBS to stream this second monitor instead of the chrome window.

  