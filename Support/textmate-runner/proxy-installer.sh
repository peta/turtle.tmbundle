#!/usr/bin/env bash

LREG='/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister'
CWD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Started proxy-installer.sh in working directory: '$CWD'"

if   [[ "$1" == "install" ]]; then
	$LREG -r -v -f "$CWD/runner"
	echo "Installed. Terminating"
elif [[ "$1" == "uninstall" ]]; then
	$LREG -r -v -u "$CWD/runner"
	echo "Uninstalled. Terminating"
else
	echo "Usage:    proxy-installer.sh (install | uninstall)"
	exit 1
fi