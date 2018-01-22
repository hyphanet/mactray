### Changelog

* 2.2.0

    * Update fred to 1480

* 2.1.0

    * Update fred to 1477
    * Add user notifications, can be disabled in settings window
    
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
