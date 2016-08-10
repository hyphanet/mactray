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

* 2.0.6

    * Update fred to 1475

* 2.0.5

    * Update fred to 1474

* 2.0.5-pre1

    * Update fred to 1474-pre1

* 2.0.4

    * Update fred to 1473
    * Update BounceCastle
    * Add Sharesite plugin

* 2.0.3

    * Ensure app shows a warning if run on OS X < 10.8

* 2.0.2

    * Update Fred to build 1472
    * Update plugins
        * UPnP to version 10007
        * KeyUtils to version 5026
    * Update wrapper to 3.5.28
    * Uninstaller is now in Settings window instead of dropdown
        * Fixes bug 6748
    * Fixes issue where wrapper crashes prevent starting node again
        * Fixes bug 6810
    * Use Github Gists for installation log uploads
    * Add new translations
        * French
        * Spanish
        * Italian
        * Norwegian Bokmål (Norway)
        * Chinese (Taiwan)
    * Update translations
        * Portuguese (Brazil)
        * Chinese (China)

* 2.0.1

    * Installer now waits for node to be fully running and configured before telling user it is finished
        * Fixes bug 6724
    * An uninstaller is now provided right in the dropdown menu
        * Uninstalls both the node and the tray app, use with caution
    * Removes launchd autostart script on older Freenet installations
        * Fixes bug 6735
    * Chinese translations
    * Portuguese (Brazil) translations

* 2.0.0
    * Built-in Freenet installer
    * Bundled Java installer
        * Oracle Java 8u66
    * Display node and FCP status in settings window
    * Display current installed Freenet build in settings window
* 1.4
    * Automatically finds node installation, doesn't depend on installer anymore
    * Settings window with node status and location override
    * Menu option to open downloads folder
* 1.3.1.1
    * No code changes, this build exists to sync up the release numbers in git
* 1.3.1
    * Fixed start/stop functionality
    * Added initial FCP support
    * Added multiple vector tray icons drawn in code for Retina and beyond :)
    * Major internal refactoring
* ~1.3+
    * Version included with Freenet installations since ~2010
    * Various small changes made by contributors without a version bump
* 1.2
    * Probably never existed
* 1.1 
    * Added about panel to show copyright info
    * Updated code to include license file inside program bundle for distribution.
* 1.0
    * Initial release     
    * Start and stop the freenest node
    * Open the web interface
    * Quit the tray app 
    
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

