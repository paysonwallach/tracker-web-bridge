project(
  'com.paysonwallach.tracker-web.bridge',
  'vala',
  'c',
  license: 'GPL-3.0',
  meson_version: '>=0.57.0',
  version: '0.1.0'
)

cmake = import('cmake')
vala = meson.get_compiler('vala')

vapi_dir = join_paths(meson.current_source_dir(), 'vapi')

gee_dep = dependency('gee-0.8')
glib_dep = dependency('glib-2.0')
glib_json_dep = dependency('json-glib-1.0')
gio_dep = dependency('gio-2.0')
gio_unix_dep = dependency('gio-unix-2.0')
posix_dep = vala.find_library('posix')
tracker_dep = dependency('tracker-sparql-3.0')

conf = configuration_data()
conf.set_quoted('APP_ID', meson.project_name())
conf.set_quoted('API_VERSION', 'v1')

config_h = configure_file(
  output: 'config.h',
  configuration: conf
)

config_inc_dir = include_directories('.')

config_dep = declare_dependency(
  dependencies: vala.find_library('config', dirs: vapi_dir),
  sources: config_h
)

add_project_arguments([
    '-DG_LOG_DOMAIN="@0@"'.format(meson.project_name())
  ],
  language:'c'
)

add_project_arguments(
  ['--vapidir', vapi_dir],
  language: 'vala'
)

bridge_source_files = [
  'src/Application.vala',
  'src/ExtensionProxy.vala',
  'src/Main.vala',
  'src/Protocol.vala',
  'src/Utils/Serializable.vala'
]

dependencies = [
  gee_dep,
  glib_dep,
  glib_json_dep,
  gio_dep,
  gio_unix_dep,
  posix_dep,
  tracker_dep,
  config_dep
]

executable(
  meson.project_name(),
  bridge_source_files,
  include_directories: config_inc_dir,
  dependencies: dependencies,
  install: true,
  install_dir: join_paths(get_option('prefix'), get_option('libexecdir'))
)

meson.add_install_script(
  'meson/post_install.py',
  join_paths(
    get_option('prefix'),
    get_option('libexecdir')
  ),
  get_option('browsers'),
  skip_if_destdir: true
)
