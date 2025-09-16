# Locale Settings
[![Translation status](https://l10n.elementaryos.org/widget/settings/locale/svg-badge.svg)](https://l10n.elementaryos.org/engage/settings/)

![screenshot](data/screenshot.png?raw=true)

## Building and Installation

You'll need the following dependencies:

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
