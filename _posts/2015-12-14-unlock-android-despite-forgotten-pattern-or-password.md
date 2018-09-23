---
layout: post
title: Unlock Android despite forgotten Pattern or Password
---

## The Problem

A family member forgot the pattern setup in its android device.

 - The "forgot password" button would not appear to enter the password
 - The android device manager was setup but would show "lock already set the password you entered is not required"

Now usually all hope is lost and you need to factory reset your device (and lose all data). This however was not an option in my case.


## The Situation

The situation for my case can be summarized like this:

 - Android 5.1.1 (others might work)
 - A second user without or with known Pattern/Password.
 - Sony Xperia Z Ultra (C6833), Version 14.6.A.0.368 (others probably work)

    - NO Sony bootloader unlock (otherwise there is probably a simpler way)
    - NO root
    - FACTORY Stock
    - NO Previous Backup via the Companion App (Otherwise you can just extract the data you need from the backup file!)
    - NO USB Debugging enabled
    - NO Developer Unlock


Because of this situation none of the methods posted on [XDA](http://forum.xda-developers.com/showthread.php?t=2620456) are usable here and the internet is suggesting a factory reset.
However as I was willing to dissassemble the device nothing is lost if I first try to dig deeper and try to get into the phone via software!

After some hours of trying to find a zero day exploit (as the version was already outdated at the time of writing), I came up with a simpler solution.
I knew that there are a lot of attack vectors as I still had access to the guest user...


## The Solution

So here are the steps to unlock the phone:

 - Install http://kingroot.net/ as the second user. The good part is the second user can even enable untrusted sources in options! Root the phone by clicking the button on the app.
 - Install a terminal app, for example https://play.google.com/store/apps/details?id=jackpal.androidterm&hl=en (Open the link with the "Play Store" App on the phone and login with your google account)
 - Open the terminal and type "su" followed by 'Enter'</li>
 - If you get a notification that an app tries to get root you can accept the message and now have a root shell (= full access to the phone)
 - Now you can easily remove your pattern or password [(reference)](http://www.addictivetips.com/android/how-to-bypass-disable-pattern-unlock-on-android-via-adb-commands/):

    - Pattern: Type "rm /data/system/gesture.key"
    - Password: Type "rm /data/system/password.key"

 - Now restart the phone and if asked for a pattern or password just enter anything ;)



I think this is basically a bug/security issue in the android operating system,
because guest users should not be able to select 'Allow untrusted sources' in the device options.
On the other side I think android device manger should allow us to reset the pattern/password...
Of course now its simple the backup the data and factory reset the phone (if you don't trust the installed tools).
Note however that factory reset might not delete everything in this case (as the phone was rooted), the safe choice would be to install a new firmware file.
