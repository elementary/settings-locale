project(
    'io.elementary.settings.locale',
    'vala', 'c',
    meson_version: '>=0.58.0',
    version: '8.0.3'
)

gnome = import('gnome')
i18n = import('i18n')

prefix = get_option('prefix')
datadir = prefix / get_option('datadir')
libdir = prefix / get_option('libdir')

adw_dep = dependency('libadwaita-1', version: '>=1.4')

switchboard_dep = dependency('switchboard-3')
switchboard_plugsdir = switchboard_dep.get_variable('plugsdir', pkgconfig_define: ['libdir', libdir])
pkgdatadir = switchboard_plugsdir / 'personal' / 'pantheon-locale'

polkit_dep = dependency('polkit-gobject-1')
polkit_actiondir = polkit_dep.get_variable('actiondir', pkgconfig_define: ['prefix', prefix])

add_project_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    '-DG_LOG_DOMAIN="@0@"'.format(meson.project_name()),
    '-DGNOME_DESKTOP_USE_UNSTABLE_API',
    language: 'c'
)

add_project_arguments(
    ['--vapidir', meson.current_source_dir() / 'vapi'],
    language: 'vala'
)

configuration_data = configuration_data()
configuration_data.set('GETTEXT_PACKAGE', meson.project_name())
configuration_data.set('PKGDATADIR', pkgdatadir)
configuration_data.set('LOCALEDIR', get_option('prefix') / get_option('localedir'))

constants = configure_file(
    configuration: configuration_data,
    input: 'config.vala.in',
    output: '@BASENAME@'
)

subdir('data')
subdir('src')
subdir('po')

gnome.post_install(
    glib_compile_schemas: true
)
