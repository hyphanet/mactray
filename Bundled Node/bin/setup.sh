#!/bin/sh

INSTALL_PATH="${INSTALL_PATH:-$PWD}"

cd "$INSTALL_PATH"

# We need the exec flag on /bin, /lib, and update.sh
chmod u+x bin/* lib/*
chmod a+rx update.sh

# Create symlink for freenet.jar
ln -s freenet-stable-latest.jar freenet.jar

# set localization automatically
echo "node.l10n=$LANG_SHORTCODE" >> freenet.ini

# Enable auto-update
echo "node.updater.enabled=true" >> freenet.ini
echo "node.updater.autoupdate=true" >> freenet.ini

# Register pre-installed plugins
echo "pluginmanager.loadplugin=JSTUN;KeyUtils;ThawIndexBrowser;UPnP;Library;Sharesite" >> freenet.ini

# Set up fproxy port
echo "fproxy.enabled=true" >> freenet.ini
echo "fproxy.port=$FPROXY_PORT" >> freenet.ini

# Set up fcp port
echo "fcp.enabled=true" >> freenet.ini
echo "fcp.port=$FCP_PORT" >> freenet.ini

echo "End" >> freenet.ini

touch .isInstalled
exit 0