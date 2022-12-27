# The Chan: Browse 4chan and 2ch on iPhone

![Screenshot 1](https://i.imgur.com/xwCHL7V.png)
![Screenshot 2](https://i.imgur.com/CLmZpky.png)
![Screenshot 3](https://i.imgur.com/4mocwOh.png)

Several years ago, when I just started my iOS developer journey, I created this imageboard browser app
and to my pleasant surpise it became pretty popular.
Over time, it had been getting improvements and new features, with many more being planned, until one day
Apple decided to remove it from App Store. After several unsuccessful attempts to appeal I gave up. Maybe if I were
to try harder back then I could implement some mechanism to bypass annoying reviewers, but by then I already had a
full time job and at some point it became really difficult to allocate time to work on The Chan, so getting removed
by Apple felt like the logical conclusion to the saga. Shortly after that I stopped using imagebooards altogether.

Recently I started occasionally browsing imageboards again and after looking into the available iOS app options
I got really dissapointed, so I decided to check if my app still worked, and it did! The problem is, it worked
really shittily, felt outdated, video playback was mostly broken and posting didn't work at all. So while I still
don't have the time to work on the client full-time, I've decided to make one last update, clean up the code and
make it public.

## List of features

* Browsing boards and threads (including catalog mode)
* Media gallery with video support (including .webm)
* Saving threads to favorites and recents
* Decent customization with system dark mode support
* Posting with attachments and captcha support (unfortunately no passcodes)
* Supports 4chan and 2ch
* Works on iOS 14+

## How to install
Download the [.ipa file](#) and install it using your preferred method, like AltStore, Sideloadly or TrollStore.

## How to build
1. Install the latest version of Xcode (tested with Xcode 14.1)
2. Clone the repo

    `git clone https://github.com/TheChanDev/TheChan.git`

3. Install [CocoaPods](https://cocoapods.org)
4. `cd TheChan && pod install`
5. `open TheChan.xcworkspace`
6. Try building the project. If you're building for a device, you should get errors about signing.
Follow Xcode's instructions to fix them. If needed, change the Bundle Identifier.
7. After configuring the signing, the project should build successfuly.

## Changes since the last version
* Reimplemented video playback from the ground up using `VLCKit`
* Added support for the new 4chan Captcha
* Added support for the new 2ch API
* Added support for system dark mode (restarting is no longer needed to change themes)
* Updated some themes for better readability
* Updated the iconography and slightly refreshed the look of many screens
* Updated app's icon
* Significantly cleaned up the code (it still sucks though)
* Removed all the analytics and crash reporting
* Updated dependencies and fixed their versions for easier builds
* Bunch of other stuff I forgot

There's a ton of other things I'd love to get fixed, but I feel like in this state app feels
pretty nice to use and has all the required features.

## Questions & Answers
Q: *Do you plan on working on this app more?*

No. If anyone finds any critical issues shortly after the initial release I'll try to fix them,
but essentialy by releasing the source code I give the app into community's hands. Anyone is free
to fork the app and work on it by themselves. You can use the name and charge money for it, I don't care.

Q: *Is it available on App Store or Testflight?*

No, but anyone is welcome to make it available there.

Q: *Is this malware?*

No. If you don't trust the provided .ipa you're free to build the app by yourself. Even when an app is installed
not through App Store, it's still sandboxed and has the access only to the things you explicitly give the access to.
You can also use something like Charles Proxy to see all the requests the app is making.

Q: *Why didn't you open-source the app earlier?*

I probably should've, but open-sourcing requires more work than just uploading the source code.

Q: *Can I contact you?*

Sure. Either use GitHub Issues or e-mail me at thechandev at pm.me