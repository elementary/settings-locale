# Locale Settings
[![Translation status](https://l10n.elementary.io/widgets/switchboard/-/switchboard-plug-locale/svg-badge.svg)](https://l10n.elementary.io/engage/switchboard/?utm_source=widget)

![screenshot](data/screenshot.png?raw=true)

## Building and Installation

You'll need the following dependencies:

* libadwaita-1-dev >= 1.3
* libaccountsservice-dev
* libibus-1.0-dev
* libgnome-desktop-4-dev
* libgranite-7-dev
* libswitchboard-3-dev
* meson >= 0.58.0
* policykit-1
* valac

Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`

    sudo ninja install
