# Switchboard Locale Plug
[![l10n](https://l10n.elementary.io/widgets/switchboard/switchboard-plug-locale/svg-badge.svg)](https://l10n.elementary.io/projects/switchboard/switchboard-plug-locale)

## Building and Installation

You'll need the following dependencies:

* cmake
* libaccountsservice-dev
* libibus-1.0-dev
* libgnome-desktop-3-dev
* libgranite-dev
* libswitchboard-2.0-dev
* valac

It's recommended to create a clean build environment

    mkdir build
    cd build/
    
Run `cmake` to configure the build environment and then `make` to build

    cmake -DCMAKE_INSTALL_PREFIX=/usr ..
    make
    
To install, use `make install`, then execute with `switchboard`

    sudo make install
    switchboard
