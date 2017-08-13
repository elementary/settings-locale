/* Copyright 2015 Switchboard Locale Plug Developers
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
    public class Preview : Gtk.Grid {
        private Gtk.Label date_time_label;
        private Gtk.Label date_label;
        private Gtk.Label time_label;
        private Gtk.Label currency_label;
        private Gtk.Label number_label;

        public Preview () {
            Object (row_spacing: 12);
        }

        construct {
            date_time_label = new Gtk.Label ("");
            date_time_label.hexpand = true;

            date_label = new Gtk.Label ("");
            date_label.hexpand = true;
            date_label.xalign = 0;

            time_label = new Gtk.Label ("");
            time_label.hexpand = true;

            currency_label = new Gtk.Label ("");
            currency_label.hexpand = true;

            number_label = new Gtk.Label ("");
            number_label.hexpand = true;
            number_label.xalign = 1;

            var grid = new Gtk.Grid ();
            grid.column_spacing = 6;
            grid.add (date_label);
            grid.add (time_label);
            grid.add (currency_label);
            grid.add (number_label);

            attach (date_time_label, 0, 0, 1, 1);
            attach (grid, 0, 1, 1, 1);

            this.show_all ();
        }

        public void reload_languages (string format) {
            Intl.setlocale (LocaleCategory.ALL, format);

            var date = new DateTime.now_local ();
            date_time_label.label = "%s".printf (date.format ("%c"));

            char currency[20];
            Monetary.strfmon (currency, "%5.2n", 1234.56);

            date_label.label = date.format ("%x");
            time_label.label = date.format ("%X");
            currency_label.label = (string) currency;
            number_label.label = "%'.2f".printf (1234.56);
        }
    }
}
