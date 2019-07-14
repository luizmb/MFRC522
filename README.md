# MFRC522-Swift

This code is a direct translation from:
https://github.com/mxgxw/MFRC522-python

- MFRC522.py
- Read.py
- Dump.py
- Write.py

Tested on Raspberry Pi 3 running:
Swift version 5.0 (swift-5.0-RELEASE)
Target: armv7-unknown-linux-gnueabihf
From: https://packagecloud.io/swift-arm/release

# Instructions
Before anything, make sure you added SSH keys to your Pi and can SSH into it without password.
On Xcode, select scheme `Build on Pi` and destination My Mac.
Be sure to make your Pi reachable as `raspberrypi`, or change the file `build.sh` with its IP address.
You may want to change destination folder too, on the same file.
When you build the scheme on Xcode, the source files will be copied to the Pi, built there, and binaries will be copied back so you have all the warnings and errors.
I couldn't make remote debugging working yet, but it's half-way done:
- On you Mac run:
```
defaults write com.apple.dt.Xcode IDEDebuggerFeatureSetting 12
```
- Edit `Build on Pi` scheme
- Group "Run", tab "Info", on "Launch" select "Custom commands" add the following commands:
```
platform select remote-linux
target create "~/Documents/code/RPi/.build/debug/RPi"
platform connect connect://raspberrypi:9293
run
platform disconnect
```
- On your Raspberry Pi, go to the app folder (currently defaults to ~/Documents/code/RPi) and run:
```
$ lldb-server platform --listen "*:9293" --server
```
- Debugging on Xcode *SHOULD* work remotely from your Pi, but for some reason I'm still investigating, this doesn't work. If you run `lldb` on your Mac and execute exactly the same commands you will be able to debug, add breakpoint, `po`, `expr` and all the fun things we like about lldb.
