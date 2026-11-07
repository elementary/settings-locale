/* Copyright 2011-2022 elementary, Inc. (https://elementary.io)
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

namespace SwitchboardPlugLocale {
    public class Utils : Object {
        private static Gee.ArrayList<string> installed_languages;
        private static Gee.ArrayList<string> installed_locales;
        private static Gee.HashMap<string, string> default_regions;
        private static Gee.ArrayList<string> blocklist_packages;

        public static void init () {
            installed_locales = new Gee.ArrayList<string> ();
            default_regions = new Gee.HashMap<string, string> ();
            blocklist_packages = new Gee.ArrayList<string> ();
        }

        public static Gee.ArrayList<string>? get_installed_languages () {
            if (installed_languages != null) {
                return installed_languages;
            }

            installed_languages = new Gee.ArrayList<string>.wrap (Gnome.Languages.get_all_locales ());

            return installed_languages;
        }

        public static async string [] get_missing_languages () {
            if (blocklist_packages.size == 0) {
                blocklist_packages = yield get_blocklist_packages ();
            }

            Pid pid;
            int input;
            int output;
            int error;

            string[] missing = {};
            string[] missing_aux = {};
            try {
                string res = "";

                Process.spawn_async_with_pipes (null,
                    {"check-language-support", null},
                    Environ.get (),
                    SpawnFlags.SEARCH_PATH,
                    null,
                    out pid,
                    out input,
                    out output,
                    out error);
                UnixInputStream read_stream = new UnixInputStream (output, true);
                DataInputStream out_channel = new DataInputStream (read_stream);
                string line = null;
                while ((line = yield out_channel.read_line_async (Priority.DEFAULT)) != null) {
                    res += line;
                }

                missing_aux = res.strip ().split (" ");

                for (var i = 0; i < missing_aux.length; i++) {
                    if (!blocklist_packages.contains (missing_aux[i])) {
                        missing += missing_aux[i];
                    }
                }
            } catch (Error e) {
                warning (e.message);
            }

            return missing;
        }

        public static async Gee.ArrayList<string> get_blocklist_packages () {
            Gee.ArrayList<string> blocklist_items = new Gee.ArrayList<string> ();
            var file = File.new_for_path (Path.build_path ("/", Constants.PKGDATADIR, "packages_blocklist"));

            try {
                var dis = new DataInputStream (file.read ());
                string line = null;

                while ((line = yield dis.read_line_async (Priority.DEFAULT)) != null) {
                    blocklist_items.add (line);
                }
            } catch (Error e) {
                error (e.message);
            }

            return blocklist_items;
        }

        public static string? get_default_for_lang (string lang) {
            string output;
            int status;
            try {
                Process.spawn_sync (null,
                    {"/usr/share/language-tools/language2locale", lang , null},
                    Environ.get (),
                    SpawnFlags.SEARCH_PATH,
                    null,
                    out output,
                    null,
                    out status);

                return output[0:5];
            } catch (Error e) {
                return null;
            }
        }

        public static async Gee.HashMap<string, string>? get_default_regions () {
            if (default_regions.size > 0) {
                return default_regions;
            }

            default_regions = new Gee.HashMap<string, string> ();

            uint8[] data;
            try {
                var file = File.new_for_path ("/usr/share/language-tools/main-countries");
                yield file.load_contents_async (null, out data, null);
            } catch (Error e) {
                warning (e.message);
                return default_regions;
            }

            string contents = (string)data;
            var output_array = contents.split ("\n");
            foreach (string line in output_array) {
                if (line != "" && line.index_of ("#") == -1) {
                    var line_array = line.split ("\t");
                    if (line_array.length > 1) {
                        default_regions[line_array[0]] = line_array[1];
                    }
                }
            }

            return default_regions;
        }

        public static Gee.HashSet<string> get_locales_for_language_code (string language) {
            Gee.HashSet<string> locales = new Gee.HashSet<string> ();
            foreach (string locale in get_installed_languages ()) {
                string code;
                if (!Gnome.Languages.parse_locale (locale, out code, null, null, null)) {
                    continue;
                }

                if (code == language) {
                    locales.add (locale);
                }
            }

            return locales;
        }

        public static string translate_language (string lang) {
            Intl.textdomain ("iso_639");
            var lang_name = dgettext ("iso_639", lang);
            lang_name = dgettext ("iso_639_3", lang);

            return lang_name;
        }

        public static string translate_country (string country) {
            Intl.textdomain ("iso_3166");
            return dgettext ("iso_3166", country);
        }

        public static string translate (string locale, string? translation) {
            var current_language = Environment.get_variable ("LANGUAGE");
            if (translation == null) {
                Environment.set_variable ("LANGUAGE", locale, true);
            } else {
                Environment.set_variable ("LANGUAGE", translation, true);
            }

            var lang_name = translate_language (Gnome.Languages.get_language_from_locale (locale, null));

            if (current_language != null) {
                Environment.set_variable ("LANGUAGE", current_language, true);
            } else {
                Environment.unset_variable ("LANGUAGE");
            }

            return lang_name;
        }

        public static string translate_region (string locale, string region, string? translation) {
            var current_language = Environment.get_variable ("LANGUAGE");
            if (translation == null) {
                Environment.set_variable ("LANGUAGE", locale, true);
            } else {
                Environment.set_variable ("LANGUAGE", translation, true);
            }

            string region_name = region;

            if (region.length == 2) {
                region_name = translate_country (Gnome.Languages.get_country_from_code (region, null));
            }

            if (current_language != null) {
                Environment.set_variable ("LANGUAGE", current_language, true);
            } else {
                Environment.unset_variable ("LANGUAGE");
            }

            return region_name;
        }

        static Utils? instance = null;

        public static Utils get_default () {
            if (instance == null) {
                instance = new Utils ();
            }
            return instance;
        }
    }
}
