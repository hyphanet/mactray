# FreenetTray

### About

A menu bar app for Freenet for OS X. 

* Menu bar icon shows whether or not Freenet is running
* Automatically starts Freenet at login
* Allows users to start and stop Freenet manually
* Provides easy access to the downloads folder
* Built-in Freenet installer with bundled Java package

### Screenshots

##### Menu Bar

![Menu Bar](screenshots/menubar.jpg "FreenetTray menu dropdown")

##### Settings

![Settings](screenshots/settings.jpg "FreenetTray settings")

##### Installer

![Installer Prompt](screenshots/installer_step1.jpg "Freenet Installer prompt")

![Installer Location Window](screenshots/installer_step2.jpg "Freenet Installer Location Window")

![Installer In Progress](screenshots/installer_step3.jpg "Freenet Installer In Progress")

![Installer Finished](screenshots/installer_step4.jpg "Freenet Installer Finished")

### Changelog

See the [Changelog.md](Changelog.md) file
    
### Licensing
 
See the Acknowledgements file for license and copyright information

### Build instructions

Before doing anything, ensure you have the following things on the build machine:

* A 64-bit Intel Mac running OS X 10.10+
* Xcode 7.x+ installed (must have the OS X 10.11 SDK)

DO NOT open FreenetTray.xcodeproj directly! The application requires CocoaPods, 
which will build the 3rd party library dependencies for you and generate an Xcode 
workspace for you to use.

##### Build steps

First, open a terminal and change directory to the source code location:

```sh
$ cd /path/to/mactray/
```

You will then need to install CocoaPods:

```sh
$ sudo gem install cocoapods
```

Now allow CocoaPods to download and build the required 3rd party libraries:

```sh
$ pod install
```

Cocoapods may take a few minutes, but quickly display build results like this:

```text
Analyzing dependencies

Downloading dependencies
Installing CocoaAsyncSocket <version number>
Installing IYLoginItem <version number>
Generating Pods project
Integrating client project
```

Now there should be a FreenetTray.xcworkspace file, open it:

```sh
$ open FreenetTray.xcworkspace 
```

Now you can build and run the application, or archive it for distribution.

When built against the OS X 10.11 SDK, the built application should be fully 
compatible with 64-bit Intel Macs running OS X 10.8 - OS X 10.11.

