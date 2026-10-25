project('lifecycle-dependency', 'c')
mode = get_option('fixture_mode')
if mode == 'headers'
  install_headers('header.h', subdir: 'lifecycle')
elif mode == 'shared'
  shared_library('lifecycle-shared', 'value.c',
    c_args: '-DVALUE_FUNCTION=lifecycle_shared',
    version: '1.0', soversion: '1', install: true)
else
  static_library('lifecycle-static', 'value.c',
    c_args: '-DVALUE_FUNCTION=lifecycle_static', install: true)
endif
meson.add_install_script(find_program('cmake'),
  '-DCOUNTER=' + meson.current_build_dir() / 'install-count.txt',
  '-P', meson.current_source_dir() / 'record-install.cmake')
