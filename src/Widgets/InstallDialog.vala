/* Copyright 2011-2017 elementary LLC. (https://elementary.io)
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

public class SwitchboardPlugLocale.Widgets.InstallDialog : Granite.Dialog {
    private Gtk.SearchEntry search_entry;
    private Gtk.ListBox list_box;

    construct {
        default_height = 400;
        default_width = 400;
        modal = true;

        search_entry = new Gtk.SearchEntry ();

        list_box = new Gtk.ListBox () {
            hexpand = true,
            vexpand = true,
            activate_on_single_click = false
        };
        list_box.set_filter_func ((Gtk.ListBoxFilterFunc) filter_function);
        list_box.set_sort_func ((Gtk.ListBoxSortFunc) sort_function);

        var scrolled = new Gtk.ScrolledWindow () {
            child = list_box,
            has_frame = true
        };

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
        box.append (search_entry);
        box.append (scrolled);

        get_content_area ().append (box);

        add_button (_("Cancel"), Gtk.ResponseType.CANCEL);

        var button_add = (Gtk.Button)add_button (_("Install Language"), Gtk.ResponseType.ACCEPT);
        button_add.sensitive = false;
        button_add.add_css_class (Granite.CssClass.SUGGESTED);

        load_languagelist ();

        search_entry.grab_focus ();

        list_box.row_selected.connect ((row) => {
            var langrow = (LangRow) list_box.get_selected_row ();

            button_add.sensitive = row != null;
            button_add.label = _("Install %s").printf (Utils.translate (langrow.lang, "C"));
        });

        list_box.row_activated.connect (() => {
            install_selected ();
            hide ();
        });

        response.connect ((response) => {
            if (response == Gtk.ResponseType.ACCEPT) {
                install_selected ();
            }

            hide ();
        });

        search_entry.activate.connect (() => {
            list_box.get_row_at_y (0).activate ();
        });

        search_entry.search_changed.connect (() => {
            list_box.invalidate_filter ();
        });
    }

    private void install_selected () {
        unowned var lang_row = (LangRow) list_box.get_selected_row ();

        Installer.UbuntuInstaller.get_default ().install.begin (lang_row.lang, (obj, res) => {
            try {
                ((Installer.UbuntuInstaller) obj).install.end (res);
            } catch (Error e) {
                if (e.matches (GLib.DBusError.quark (), GLib.DBusError.ACCESS_DENIED)) {
                    return;
                }

                var dialog = new Granite.MessageDialog (
                    _("Couldn't install language pack"),
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

    [CCode (instance_pos = -1)]
    private int sort_function (LangRow row1, LangRow row2) {
        return row1.lang.collate (row2.lang);
    }

    [CCode (instance_pos = -1)]
    private bool filter_function (LangRow row) {
        if (search_entry.text == "") {
            return true;
        }

        var search_term = search_entry.text.down ();
        var english_lang = Utils.translate (row.lang, "C").down ();
        var translated_lang = Utils.translate (row.lang, null).down ();

        if (search_term in english_lang || search_term in translated_lang) {
            return true;
        }

        return false;
    }

    private void load_languagelist () {
        var file = File.new_for_path (Path.build_path ("/", Constants.PKGDATADIR, "languagelist"));
        try {
            var dis = new DataInputStream (file.read ());
            string line;
            var langs = new GLib.List<string> ();
            while ((line = dis.read_line (null)) != null) {
                if (line.substring (0, 1) != "#" && line != "") {
                    if (line == "ia") {
                        continue;
                    }

                    if (langs.find_custom (line, strcmp).length () == 0) {
                        var langrow = new LangRow (line);
                        list_box.append (langrow);
                        langs.append (line);
                    }
                }
            }
        } catch (Error e) {
            critical (e.message);
        }
    }

    private class LangRow : Gtk.ListBoxRow {
        public string lang { get; construct; }

        public LangRow (string lang) {
            Object (lang: lang);
        }

        construct {
            var label = new Gtk.Label (Utils.translate (lang, null)) {
                margin_top = 6,
                margin_end = 6,
                margin_bottom = 6,
                margin_start = 6,
                xalign = 0
            };

            child = label;
        }
    }
}
