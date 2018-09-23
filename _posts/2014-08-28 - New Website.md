# Date: 2014-08-28; Title: New Website; Tags: yaaf; Author: Matthias Dittrich

## The first step is done!

Finally I found some time to convert the outdated PHP website (once again thank you Simon) to F#. 
At first I planned to use ASP.net MVC but after some testing it was 
really easy to get <a href="https://github.com/NancyFx/Nancy/">Nancy</a> running on mono.
Because of experience of making ASP.net working on mono <a href="https://github.com/mono/mono/pull/888">in the past</a> 
I decided to stick with the "light" but (for now) very stable and good working solution.


With this first step done, and most of the release steps <a href="https://buildbot.yaaf.de/builders/yaaf-website-builder">automated</a>
I will try to Introduce a lot of new features to this website in the future:

 - Add Registration into the site.
 - Add Chat History (and allow edit).
 - Manage some advanced chat settings.
 - Request re-sync of your IMAP History.
 - Blog?
 - Simple "Safe-Picture" service (protect pictures with capture)
 - Muact?
 - Add JavaScript-Chat client to the site (via Yaaf.Xmpp, test for JavaScript library)
 - Admin page for server management?
 
The time will tell if I find enough time to do all those features. 
The beta and automatically updated version (on every "working" commit) of this site can be <a href="http://devel-website.yaaf.de">found here</a>.
The Version numbers on the bottom right will tell you if there is an actuall difference between those two.