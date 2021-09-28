bridge_source_files = files(
  'Application.vala',
  'ExtensionProxy.vala',
  'Main.vala',
  'Protocol.vala',
  'Utils/Serializable.vala'
)

executable(
  meson.project_name(),
  bridge_source_files,
  include_directories: config_inc_dir,
  dependencies: [
    gee_dep,
    glib_dep,
    glib_json_dep,
    gio_dep,
    gio_unix_dep,
    posix_dep,
    tracker_dep,
    config_dep
  ],
  install: true,
  install_dir: join_paths(get_option('prefix'), get_option('libexecdir'))
)
