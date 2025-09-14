/* Copyright 2011-2018 elementary LLC. (https://elementary.io)
*
* This program is free software: you can redistribute it
* and/or modify it under the terms of the GNU Lesser General Public License as
* published by the Free Software Foundation, either version 3 of the
* License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be
* useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
* Public License for more details.
*
* You should have received a copy of the GNU General Public License along
* with this program. If not, see http://www.gnu.org/licenses/.
*/

namespace SwitchboardPlugLocale.Widgets {
    public class LocaleSetting : Switchboard.SettingsPage {
        private Gtk.Button set_button;
        private Adw.Banner missing_lang_infobar;
        private Adw.Banner restart_infobar;
        private Gtk.DropDown format_dropdown;
        private Gtk.DropDown region_dropdown;
        private GLib.ListStore format_list;
        private GLib.ListStore locale_list;

        private LocaleManager lm;
        private Preview preview;
        private string language;

        private static GLib.Settings? temperature_settings = null;

        public LocaleSetting () {
            Object (icon: new ThemedIcon ("preferences-desktop-locale"));
        }

        construct {
            add_css_class ("locale-setting");

            lm = LocaleManager.get_default ();

            format_list = new GLib.ListStore (typeof (Locale));
            locale_list = new GLib.ListStore (typeof (Locale));

            var expression = new Gtk.PropertyExpression (
                typeof (Locale),
                null,
                "name"
            );

            region_dropdown = new Gtk.DropDown (locale_list, null) {
                enable_search = true,
                expression = expression,
                hexpand = true,
                search_match_mode = SUBSTRING
            };
            region_dropdown.notify["selected"].connect (compare);

            format_dropdown = new Gtk.DropDown (format_list, null) {
                enable_search = true,
                expression = expression,
                search_match_mode = SUBSTRING
            };
            format_dropdown.notify["selected"].connect (() => {
                on_format_changed ();
                compare ();
            });

            var region_endlabel = new Granite.HeaderLabel (_("Region"));
            region_dropdown.update_property_value ({DESCRIPTION}, {region_endlabel.label});

            var formats_label = new Granite.HeaderLabel (_("Formats"));
            format_dropdown.update_property_value ({DESCRIPTION}, {formats_label.label});

            var region_formats_box = new Gtk.Box (VERTICAL, 6);
            region_formats_box.append (region_endlabel);
            region_formats_box.append (region_dropdown);
            region_formats_box.append (formats_label);
            region_formats_box.append (format_dropdown);

            var layout_link = new LinkRow (
                "settings://input/keyboard/layout",
                _("Keyboard layout settings…"),
                "preferences-desktop-keyboard-symbolic",
                "slate"
            );

            var datetime_link = new LinkRow (
                "settings://time",
                _("Time format settings…"),
                "preferences-system-time-symbolic",
                "slate"
            );

            var links_list = new Gtk.ListBox () {
                margin_top = 24,
                valign = CENTER,
                show_separators = true,
                selection_mode = NONE,
                hexpand = true
            };
            links_list.add_css_class ("boxed-list");
            links_list.add_css_class (Granite.STYLE_CLASS_RICH_LIST);
            links_list.append (layout_link);
            links_list.append (datetime_link);

            preview = new Preview () {
                halign = CENTER
            };
            preview.margin_bottom = 12;
            preview.margin_top = 12;

            var preview_label = new Granite.HeaderLabel (_("Preview"));

            var preview_box = new Gtk.Box (VERTICAL, 6) {
                margin_top = 24
            };
            preview_box.append (preview_label);
            preview_box.append (preview);

            missing_lang_infobar = new Adw.Banner (_("Language support is not installed completely")) {
                revealed = false,
                button_label = _("Complete Installation")
            };
            missing_lang_infobar.add_css_class ("infobar-margin");

            restart_infobar = new Adw.Banner (_("Some changes will not take effect until you log out")) {
                revealed = false
            };
            restart_infobar.add_css_class ("infobar-margin");

            var content_box = new Gtk.Box (VERTICAL, 0);
            content_box.append (missing_lang_infobar);
            content_box.append (restart_infobar);
            content_box.append (region_formats_box);

            if (temperature_settings != null) {
                var temperature_label = new Granite.HeaderLabel (_("Temperature"));

                var celcius_radio = new Gtk.CheckButton.with_label (_("Celsius"));
                celcius_radio.update_property_value ({DESCRIPTION}, {temperature_label.label});

                var fahrenheit_radio = new Gtk.CheckButton.with_label (_("Fahrenheit")) {
                    group = celcius_radio
                };
                fahrenheit_radio.update_property_value ({DESCRIPTION}, {temperature_label.label});

                var auto_radio = new Gtk.CheckButton.with_label (_("Automatic, based on locale")) {
                    group = celcius_radio
                };
                auto_radio.update_property_value ({DESCRIPTION}, {temperature_label.label});

                var temperature_radio_box = new Gtk.Box (VERTICAL, 6);
                temperature_radio_box.append (auto_radio);
                temperature_radio_box.append (celcius_radio);
                temperature_radio_box.append (fahrenheit_radio);

                var temperature_box = new Gtk.Box (VERTICAL, 6) {
                    margin_top = 24
                };
                temperature_box.append (temperature_label);
                temperature_box.append (temperature_radio_box);

                content_box.append (temperature_box);

                var temp_setting = temperature_settings.get_string ("temperature-unit");

                if (temp_setting == "centigrade") {
                    celcius_radio.active = true;
                } else if (temp_setting == "fahrenheit") {
                    fahrenheit_radio.active = true;
                } else {
                    auto_radio.active = true;
                }

                auto_radio.toggled.connect (() => {
                    if (auto_radio.active) {
                        temperature_settings.set_string ("temperature-unit", "default");
                    }
                });

                celcius_radio.toggled.connect (() => {
                    if (celcius_radio.active) {
                        temperature_settings.set_string ("temperature-unit", "centigrade");
                    }
                });

                fahrenheit_radio.toggled.connect (() => {
                    if (fahrenheit_radio.active) {
                        temperature_settings.set_string ("temperature-unit", "fahrenheit");
                    }
                });
            }

            content_box.append (links_list);
            content_box.append (preview_box);

            child = content_box;
            show_end_title_buttons = true;

            set_button = add_button (_("Set Language"));
            set_button.sensitive = false;
            set_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

            var set_system_button = add_button (_("Set System Language"));
            set_system_button.tooltip_text = _("Set language for login screen, guest account and new user accounts");

            unowned var installer = Installer.UbuntuInstaller.get_default ();

            missing_lang_infobar.button_clicked.connect (() => {
                missing_lang_infobar.revealed = false;

                installer.install_missing_languages.begin ((obj, res) => {
                    try {
                        installer.install_missing_languages.end (res);
                    } catch (Error e) {
                        missing_lang_infobar.revealed = true;

                        if (e.matches (GLib.DBusError.quark (), GLib.DBusError.ACCESS_DENIED)) {
                            return;
                        }

                        var dialog = new Granite.MessageDialog (
                            _("Couldn't install missing language packs"),
                            e.message,
                            new ThemedIcon ("preferences-desktop-locale")
                        ) {
                            badge_icon = new ThemedIcon ("dialog-error"),
                            modal = true,
                            transient_for = ((Gtk.Application) Application.get_default ()).active_window
                        };
                        dialog.present ();
                        dialog.response.connect (dialog.destroy);
                    }
                });
            });

            links_list.row_activated.connect ((row) => {
                var uri_launcher = new Gtk.UriLauncher (((LinkRow) row).uri);
                uri_launcher.launch.begin (
                    ((Gtk.Application) GLib.Application.get_default ()).active_window,
                    null
                );
            });

            set_button.clicked.connect (() => {
                var locale = get_selected_locale ();
                debug ("Setting user language to '%s'", locale);
                lm.set_user_language (locale);

                compare ();

                var format = get_format ();
                debug ("Setting user format to '%s'", format);
                lm.set_user_format (format);

                restart_infobar.revealed = true;
            });

            set_system_button.clicked.connect (on_applied_to_system);

            installer.check_missing_finished.connect (on_check_missing_finished);
        }

        private void on_check_missing_finished (string[] missing) {
            missing_lang_infobar.revealed = missing.length > 0;
        }

        static construct {
            if (SettingsSchemaSource.get_default ().lookup ("org.gnome.GWeather4", true) != null) {
                temperature_settings = new Settings ("org.gnome.GWeather4");
            } else if (SettingsSchemaSource.get_default ().lookup ("org.gnome.GWeather", true) != null) {
                temperature_settings = new Settings ("org.gnome.GWeather");
            }

            var provider = new Gtk.CssProvider ();
            provider.load_from_resource ("io/elementary/settings/locale/Plug.css");

            Gtk.StyleContext.add_provider_for_display (
                Gdk.Display.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
        }

        public string get_selected_locale () {
            var locale_object = (Locale) region_dropdown.selected_item;
            if (locale_object == null) {
                return "";
            }

            return locale_object.locale;
        }

        public string get_format () {
            var locale_object = (Locale) format_dropdown.selected_item;
            if (locale_object == null) {
                return "";
            }

            return locale_object.locale;
        }

        private void on_format_changed () {
            var format = get_format ();

            if (format != "") {
                preview.reload_languages (format);
            }
        }

        private void compare () {
            if (set_button != null) {
                if (lm.get_user_language () == get_selected_locale () && lm.get_user_format () == get_format ()) {
                    restart_infobar.revealed = false;
                    set_button.sensitive = false;
                } else {
                    set_button.sensitive = true;
                }
            }
        }

        public async void reload_locales (string language, Gee.HashSet<string> locales) {
            this.language = language;
            bool user_locale_found = false;

            locale_list.remove_all ();

            var default_regions = yield Utils.get_default_regions ();
            var user_locale = lm.get_user_language ();

            foreach (var locale in locales) {
                string code;
                if (!Gnome.Languages.parse_locale (locale, null, out code, null, null)) {
                    continue;
                }

                var region_string = Utils.translate_region (language, code, locale);

                var locale_object = new Locale (region_string, locale);

                var position = locale_list.insert_sorted (locale_object, locale_sort_func);

                if (user_locale_found) {
                    continue;
                }

                if (user_locale == locale) {
                    region_dropdown.selected = position;
                    user_locale_found = true;
                } else if (default_regions.has_key (language) && locale.has_prefix (default_regions[language])) {
                    region_dropdown.selected = position;
                }
            }

            region_dropdown.sensitive = locale_list.n_items > 1;

            compare ();
        }

        private int locale_sort_func (Object a, Object b) {
            return ((Locale) a).name.collate (((Locale) b).name);
        }

        public void reload_formats (Gee.ArrayList<string>? locales) {
            format_list.remove_all ();
            var user_format = lm.get_user_format ();

            foreach (var locale in locales) {
                string country = Gnome.Languages.get_country_from_locale (locale, null);

                if (country != null) {
                    var locale_object = new Locale (country, locale);
                    var position = format_list.insert_sorted (locale_object, locale_sort_func);

                    if (locale == user_format) {
                        format_dropdown.selected = position;
                    }
                }
            }

            format_dropdown.sensitive = format_list.n_items > 1;

            compare ();
        }

        public void reload_labels (string language_name) {
            title = language_name;
        }

        private void on_applied_to_system () {
            var selected_locale = get_selected_locale ();
            var selected_format = get_format ();
            debug ("Setting system language to '%s' and format to '%s'", selected_locale, selected_format);
            lm.apply_to_system.begin (selected_locale, selected_format, (obj, res) => {
                try {
                    lm.apply_to_system.end (res);
                    restart_infobar.revealed = true;
                } catch (Error e) {
                    if (e.matches (GLib.DBusError.quark (), GLib.DBusError.ACCESS_DENIED)) {
                        return;
                    }

                    var dialog = new Granite.MessageDialog (
                        _("Can't set system locale"),
                        e.message,
                        new ThemedIcon ("preferences-desktop-locale")
                    ) {
                        badge_icon = new ThemedIcon ("dialog-error"),
                        modal = true,
                        transient_for = ((Gtk.Application) Application.get_default ()).active_window
                    };
                    dialog.present ();
                    dialog.response.connect (dialog.destroy);
                }
            });
        }

        private class Locale : Object {
            public string name { get; construct; }
            public string locale { get; construct; }

            public Locale (string name, string locale) {
                Object (name: name, locale: locale);
            }
        }

        private class LinkRow : Gtk.ListBoxRow {
            public string uri { get; construct; }
            public string icon_name { get; construct; }
            public string label_string { get; construct; }
            public string color { get; construct; }

            public LinkRow (string uri, string label_string, string icon_name, string color) {
                Object (
                    uri: uri,
                    label_string: label_string,
                    icon_name: icon_name,
                    color: color
                );
            }

            class construct {
                set_accessible_role (LINK);
            }

            construct {

                var image = new Gtk.Image.from_icon_name (icon_name) {
                    pixel_size = 16
                };
                image.add_css_class (Granite.STYLE_CLASS_ACCENT);
                image.add_css_class (color);

                var left_label = new Gtk.Label (label_string) {
                    hexpand = true,
                    xalign = 0
                };

                var link_image = new Gtk.Image.from_icon_name ("adw-external-link-symbolic");

                var box = new Gtk.Box (HORIZONTAL, 0);
                box.append (image);
                box.append (left_label);
                box.append (link_image);

                child = box;
                add_css_class ("link");
            }
        }
    }
}
