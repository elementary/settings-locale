i18n.merge_file(
    input: 'locale.policy.in',
    output: meson.project_name() + '.policy',
    po_dir: meson.project_source_root() / 'po' / 'extra',
    install: true,
    install_dir: polkit_actiondir
)

i18n.merge_file(
    input: 'locale.metainfo.xml.in',
    output: meson.project_name() + '.metainfo.xml',
    po_dir: meson.project_source_root() / 'po' / 'extra',
    type: 'xml',
    install: true,
    install_dir: datadir / 'metainfo'
)

install_data(
    'locale.gschema.xml',
    install_dir: datadir / 'glib-2.0' / 'schemas',
    rename: meson.project_name() + '.gschema.xml'
)

install_data(
    'languagelist',
    'packages_blocklist',
    install_dir: pkgdatadir
)

css_gresource = gnome.compile_resources(
    'gresource_css',
    'gresource.xml'
)
