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
    public class LocaleSetting : Granite.SimpleSettingsPage {
        private Gtk.Button set_button;
        private Gtk.Button set_system_button;
        private Gtk.ComboBox format_combobox;
        private Gtk.ComboBox region_combobox;
        private Gtk.ListStore format_store;
        private Gtk.ListStore region_store;

        private LocaleManager lm;
        private Preview preview;
        private string language;
        private EndLabel region_endlabel;

        private static GLib.Settings? temperature_settings = null;

        public signal void settings_changed ();

        public LocaleSetting () {
            Object (icon_name: "preferences-desktop-locale");
        }

        construct {
            lm = LocaleManager.get_default ();

            var region_label = new Gtk.Label ("");
            region_label.halign = Gtk.Align.START;

            Gtk.CellRendererText renderer = new Gtk.CellRendererText ();
            region_store = new Gtk.ListStore (2, typeof (string), typeof (string));

            region_combobox = new Gtk.ComboBox.with_model (region_store);
            region_combobox.height_request = 27;
            region_combobox.pack_start (renderer, true);
            region_combobox.add_attribute (renderer, "text", 0);
            region_combobox.changed.connect (compare);

            format_store = new Gtk.ListStore (2, typeof (string), typeof (string));

            format_combobox = new Gtk.ComboBox.with_model (format_store);
            format_combobox.pack_start (renderer, true);
            format_combobox.add_attribute (renderer, "text", 0);
            format_combobox.changed.connect (on_format_changed);
            format_combobox.changed.connect (compare);
            format_combobox.active = 0;

            preview = new Preview ();
            preview.margin_bottom = 12;
            preview.margin_top = 12;

            region_endlabel = new EndLabel (_("Region: "));

            content_area.halign = Gtk.Align.CENTER;
            content_area.attach (region_endlabel, 0, 2, 1, 1);
            content_area.attach (region_combobox, 1, 2, 1, 1);
            content_area.attach (new EndLabel (_("Formats: ")), 0, 3, 1, 1);
            content_area.attach (format_combobox, 1, 3, 1, 1);
            content_area.attach (preview, 0, 5, 2, 1);

            if (temperature_settings != null) {
                var temperature = new Granite.Widgets.ModeButton ();
                temperature.append_text (_("Celsius"));
                temperature.append_text (_("Fahrenheit"));

                content_area.attach (new EndLabel (_("Temperature:")), 0, 4, 1, 1);
                content_area.attach (temperature, 1, 4, 1, 1);

                var temp_setting = temperature_settings.get_string ("temperature-unit");

                if (temp_setting == "centigrade") {
                    temperature.selected = 0;
                } else if (temp_setting == "fahrenheit") {
                    temperature.selected = 1;
                }

                temperature.mode_changed.connect (() => {
                    if (temperature.selected == 0) {
                        temperature_settings.set_string ("temperature-unit", "centigrade");
                    } else {
                        temperature_settings.set_string ("temperature-unit", "fahrenheit");
                    }
                });

            }

            set_button = new Gtk.Button.with_label (_("Set Language"));
            set_button.sensitive = false;
            set_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

            set_system_button = new Gtk.Button.with_label (_("Set System Language"));
            set_system_button.tooltip_text = _("Set language for login screen, guest account and new user accounts");
            set_system_button.sensitive = false;

            var keyboard_button = new Gtk.Button.with_label (_("Keyboard Settings…"));

            action_area.add (keyboard_button);
            action_area.add (set_system_button);
            action_area.add (set_button);
            action_area.set_child_secondary (keyboard_button, true);

            show_all ();

            keyboard_button.clicked.connect (() => {
                try {
                    AppInfo.launch_default_for_uri ("settings://input/keyboard/layout", null);
                } catch (Error e) {
                    warning ("Failed to open keyboard settings: %s", e.message);
                }
            });

            set_button.clicked.connect (() => {
                var locale = get_selected_locale ();
                debug ("Setting user language to '%s'", locale);
                lm.set_user_language (locale);

                var format = get_format ();
                debug ("Setting user format to '%s'", format);
                lm.set_user_format (format);

                settings_changed ();
                compare ();
            });

            set_system_button.clicked.connect (() => {
                if (!Utils.allowed_permission ()) {
                    return;
                }

                on_applied_to_system ();
            });
        }

        static construct {
            if (SettingsSchemaSource.get_default ().lookup ("org.gnome.GWeather", true) != null) {
                temperature_settings = new Settings ("org.gnome.GWeather");
            }
        }

        public string get_selected_locale () {
            Gtk.TreeIter iter;
            string locale;

            if (!region_combobox.get_active_iter (out iter)) {
                return "";
            }

            region_store.get (iter, 1, out locale);

            return locale;
        }

        public string get_format () {
            Gtk.TreeIter iter;
            string format;

            if (!format_combobox.get_active_iter (out iter)) {
                return "";
            }

            format_store.get (iter, 1, out format);

            return format;
        }

        private void on_format_changed () {
            var format = get_format ();

            if (format != "") {
                preview.reload_languages (format);
            }
        }

        private void compare () {
            string? compared_format = null;

            var selected_locale = get_selected_locale ();
            var selected_format = get_format ();

            if (set_button != null) {
                if (lm.get_user_language () == selected_locale && lm.get_user_format () == selected_format) {
                     set_button.sensitive = false;
                 } else {
                     set_button.sensitive = true;
                }
            }

            if (selected_locale != selected_format) {
                compared_format = selected_format;
            }

            compare_system_settings (selected_locale, compared_format, selected_locale, selected_format);
        }

        private void compare_system_settings (string locale, string? unknown, string selected, string format) {
            if (set_system_button != null) {
                if (lm.get_localectl_settings (locale, null, selected) == locale && lm.get_localectl_settings (null, unknown, selected) == format) {
                    set_system_button.sensitive = false;
                } else {
                    set_system_button.sensitive = true;
                }
            }
        }

        public class EndLabel : Gtk.Label {
            public EndLabel (string label) {
                Object (
                    halign: Gtk.Align.END,
                    label: label
                );
            }
        }

        public async void reload_locales (string language, Gee.HashSet<string> locales) {
            this.language = language;
            string? selected_locale_id = null;
            bool user_locale_found = false;
            int locales_added = 0;

            region_store.clear ();

            var default_regions = yield Utils.get_default_regions ();
            var user_locale = lm.get_user_language ();

            foreach (var locale in locales) {
                string code;
                if (!Gnome.Languages.parse_locale (locale, null, out code, null, null)) {
                    continue;
                }

                var region_string = Utils.translate_region (language, code, language);

                var iter = Gtk.TreeIter ();
                region_store.append (out iter);
                region_store.set (iter, 0, region_string, 1, locale);

                if (user_locale == locale) {
                    selected_locale_id = locale;
                    user_locale_found = true;
                }

                if (!user_locale_found && default_regions.has_key (language)) {
                    if (locale.has_prefix (default_regions[language])) {
                        selected_locale_id = locale;
                    }
                }

                locales_added++;
            }

            region_combobox.id_column = 1;
            region_combobox.sensitive = locales_added > 1;
            if (selected_locale_id != null) {
                region_combobox.active_id = selected_locale_id;
            } else {
                region_combobox.active = 0;
            }

            region_store.set_sort_column_id (0, Gtk.SortType.ASCENDING);

            compare ();
        }

        public void reload_formats (Gee.ArrayList<string>? locales) {
            format_store.clear ();
            var user_format = lm.get_user_format ();
            string? format_id = null;

            int i = 0;
            string? active_id = null;
            foreach (var locale in locales) {
                string country = Gnome.Languages.get_country_from_locale (locale, null);

                if (country != null) {
                    var iter = Gtk.TreeIter ();
                    format_store.append (out iter);
                    format_store.set (iter, 0, country, 1, locale);

                    if (locale == user_format) {
                        format_id = locale;
                    }

                    i++;
                }
            }

            format_combobox.id_column = 1;
            format_combobox.sensitive = i != 1; // set to unsensitive if only have one item

            if (format_id != null) {
                format_combobox.active_id = format_id;
            } else {
                format_combobox.active = 0;
            }

            format_store.set_sort_column_id (0, Gtk.SortType.ASCENDING);

            compare ();
        }

        public void reload_labels (string language) {
            title = Utils.translate (language, null);
        }

        private void on_applied_to_system () {
            var selected_system_locale = get_selected_locale ();
            var selected_system_format = get_format ();
            debug ("Setting system language to '%s' and format to '%s'", selected_system_locale, selected_system_format);
            lm.apply_to_system (selected_system_locale, selected_system_format);

            settings_changed ();
            compare();
        }
    }
}
