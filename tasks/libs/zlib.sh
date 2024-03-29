#!/bin/bash
#
# Task: Library: zlib
#

# declare routine package:uninstall
function task_lib_zlib_package_uninstall() {
  # uninstall binary packages
  if [ "$zlib_package_pkgs" == "bin" ]; then
    sudo apt-get remove --purge $zlib_package_pkgs_bin;
  # uninstall development packages
  elif [ "$zlib_package_pkgs" == "dev" ]; then
    sudo apt-get remove --purge $zlib_package_pkgs_dev;
  # uninstall both packages
  elif [ "$zlib_package_pkgs" == "both" ]; then
    sudo apt-get remove --purge $zlib_package_pkgs_bin $zlib_package_pkgs_dev;
  else
    notify "errorRoutine" "lib:zlib:package:uninstall";
  fi;
}

# declare routine package:install
function task_lib_zlib_package_install() {
  # install binary packages
  if [ "$zlib_package_pkgs" == "bin" ]; then
    sudo apt-get install -y $zlib_package_pkgs_bin;
  # install development packages
  elif [ "$zlib_package_pkgs" == "dev" ]; then
    sudo apt-get install -y $zlib_package_pkgs_dev;
  # install both packages
  elif [ "$zlib_package_pkgs" == "both" ]; then
    sudo apt-get install -y $zlib_package_pkgs_bin $zlib_package_pkgs_dev;
  else
    notify "errorRoutine" "lib:zlib:package:install";
  fi;
  # whereis library
  echo "whereis package library: $(whereis libz.so)";
}

# declare routine package:test
function task_lib_zlib_package_test() {
  # ldconfig tests
  ldconfig_lookup="libz.so";
  if [ -f "${global_package_path_usr_lib}/${ldconfig_lookup}" ] || [ -f "${global_package_path_usr_lib64}/${ldconfig_lookup}" ]; then
    # check ldconfig paths
    ldconfig_cmd1="ldconfig -p | grep ${global_package_path_usr_lib} | grep ${ldconfig_lookup}";
    echo "find package libraries #1: sudo bash -c \"${ldconfig_cmd1}\"";
    sudo bash -c "${ldconfig_cmd1}";
    # check ldconfig versions
    ldconfig_cmd2="ldconfig -v | grep ${ldconfig_lookup}";
    echo "find package libraries #2: sudo bash -c \"${ldconfig_cmd2}\"";
    sudo bash -c "${ldconfig_cmd2}";
  else
    notify "errorRoutine" "lib:zlib:package:test";
  fi;
}

# declare routine source:cleanup
function task_lib_zlib_source_cleanup() {
  # remove source files
  if [ -d "$zlib_source_path" ]; then
    sudo rm -Rf "${zlib_source_path}";
  else
    notify "warnRoutine" "lib:zlib:source:cleanup";
  fi;
  # remove source tar
  if [ -f "$zlib_source_tar" ]; then
    sudo rm -f "${zlib_source_tar}";
  else
    notify "warnRoutine" "lib:zlib:source:cleanup";
  fi;
}

# declare routine source:download
function task_lib_zlib_source_download() {
  if [ ! -d "$zlib_source_path" ]; then
    # download and extract source files from tar
    if [ ! -f "$zlib_source_tar" ]; then
      sudo bash -c "cd \"${global_source_path_usr_src}\" && wget \"${zlib_source_url}\" -O \"${zlib_source_tar}\" && tar -xzf \"${zlib_source_tar}\"";
    # extract source files from tar
    else
      sudo bash -c "cd \"${global_source_path_usr_src}\" && tar -xzf \"${zlib_source_tar}\"";
    fi;
  else
    notify "warnRoutine" "lib:zlib:source:download";
  fi;
}

# declare routine source:make
function task_lib_zlib_source_make() {
  if [ -d "$zlib_source_path" ]; then
    # config command - add configuration tool
    config_cmd="./configure";

    # config command - add arch
    if [ -n "$zlib_source_arg_arch" ]; then
      config_cmd="${config_cmd} --archs=\"${zlib_source_arg_arch}\"";
    fi;

    # config command - add prefix (usr)
    if [ -n "$zlib_source_arg_prefix_usr" ]; then
      config_cmd="${config_cmd} --prefix=${zlib_source_arg_prefix_usr}";
    fi;

    # config command - add options
    if [ -n "$zlib_source_arg_options" ]; then
      config_cmd="${config_cmd} ${zlib_source_arg_options}";
    fi;

    # make command - add make tool
    make_cmd="make -j${global_source_make_cores}";

    # clean, configure and make
    sudo bash -c "cd \"${zlib_source_path}\" && make clean";
    echo "config arguments: ${config_cmd}";
    echo "make arguments: ${make_cmd}";
    sudo bash -c "cd \"${zlib_source_path}\" && eval ${config_cmd} && eval ${make_cmd}";
  else
    notify "errorRoutine" "lib:zlib:source:make";
  fi;
}

# declare routine source:uninstall
function task_lib_zlib_source_uninstall() {
  if [ -f "${global_source_path_usr_lib}/libz.so" ]; then
    # uninstall binaries from source
    sudo bash -c "cd \"${zlib_source_path}\" && make uninstall";
  else
    notify "errorRoutine" "lib:zlib:source:uninstall";
  fi;
}

# declare routine source:install
function task_lib_zlib_source_install() {
  if [ -f "$zlib_source_path/libz.so" ]; then
    # install binaries from source
    sudo bash -c "cd \"${zlib_source_path}\" && make install";
    # whereis library
    echo "whereis source library: ${global_source_path_usr_lib}/libz.so";
  else
    notify "errorRoutine" "lib:zlib:source:install";
  fi;
}

# declare routine source:test
function task_lib_zlib_source_test() {
  # ldconfig tests
  ldconfig_lookup="libz.so";
  if [ -f "${global_source_path_usr_lib}/${ldconfig_lookup}" ]; then
    # check ldconfig paths
    ldconfig_cmd1="ldconfig -p | grep ${global_source_path_usr_lib} | grep ${ldconfig_lookup}";
    echo "find source libraries #1: sudo bash -c \"${ldconfig_cmd1}\"";
    sudo bash -c "${ldconfig_cmd1}";
    # check ldconfig versions
    ldconfig_cmd2="ldconfig -v | grep ${ldconfig_lookup}";
    echo "find source libraries #2: sudo bash -c \"${ldconfig_cmd2}\"";
    sudo bash -c "${ldconfig_cmd2}";
  else
    notify "errorRoutine" "lib:zlib:source:test";
  fi;
}

# declare subtask package
function task_lib_zlib_package() {
  # run routine package:uninstall
  if ([ "$zlib_package_uninstall" == "yes" ] && [ "$args_routine" == "config" ]) || [ "$args_routine" == "uninstall" ]; then
    notify "startRoutine" "lib:zlib:package:uninstall";
    task_lib_zlib_package_uninstall;
    notify "stopRoutine" "lib:zlib:package:uninstall";
  else
    notify "skipRoutine" "lib:zlib:package:uninstall";
  fi;

  # run routine package:install
  if ([ "$zlib_package_install" == "yes" ] && [ "$args_routine" == "config" ]) || [ "$args_routine" == "all" ] || [ "$args_routine" == "install" ]; then
    notify "startRoutine" "lib:zlib:package:install";
    task_lib_zlib_package_install;
    notify "stopRoutine" "lib:zlib:package:install";
  else
    notify "skipRoutine" "lib:zlib:package:install";
  fi;

  # run routine package:test
  if ([ "$zlib_package_test" == "yes" ] && [ "$args_routine" == "config" ]) || [ "$args_routine" == "all" ] || [ "$args_routine" == "test" ]; then
    notify "startRoutine" "lib:zlib:package:test";
    task_lib_zlib_package_test;
    notify "stopRoutine" "lib:zlib:package:test";
  else
    notify "skipRoutine" "lib:zlib:package:test";
  fi;
}

# declare subtask source
function task_lib_zlib_source() {
  # run routine source:cleanup
  if ([ "$zlib_source_cleanup" == "yes" ] && [ "$args_routine" == "config" ]) || [ "$args_routine" == "cleanup" ]; then
    notify "startRoutine" "lib:zlib:source:cleanup";
    task_lib_zlib_source_cleanup;
    notify "stopRoutine" "lib:zlib:source:cleanup";
  else
    notify "skipRoutine" "lib:zlib:source:cleanup";
  fi;

  # run routine source:download
  if ([ "$zlib_source_download" == "yes" ] && [ "$args_routine" == "config" ]) || [ "$args_routine" == "all" ] || [ "$args_routine" == "download" ]; then
    notify "startRoutine" "lib:zlib:source:download";
    task_lib_zlib_source_download;
    notify "stopRoutine" "lib:zlib:source:download";
  else
    notify "skipRoutine" "lib:zlib:source:download";
  fi;

  # run routine source:make
  if ([ "$zlib_source_make" == "yes" ] && [ "$args_routine" == "config" ]) || [ "$args_routine" == "all" ] || [ "$args_routine" == "make" ]; then
    notify "startRoutine" "lib:zlib:source:make";
    task_lib_zlib_source_make;
    notify "stopRoutine" "lib:zlib:source:make";
  else
    notify "skipRoutine" "lib:zlib:source:make";
  fi;

  # run routine source:uninstall
  if ([ "$zlib_source_uninstall" == "yes" ] && [ "$args_routine" == "config" ]) || [ "$args_routine" == "uninstall" ]; then
    notify "startRoutine" "lib:zlib:source:uninstall";
    task_lib_zlib_source_uninstall;
    notify "stopRoutine" "lib:zlib:source:uninstall";
  else
    notify "skipRoutine" "lib:zlib:source:uninstall";
  fi;

  # run routine source:install
  if ([ "$zlib_source_install" == "yes" ] && [ "$args_routine" == "config" ]) || [ "$args_routine" == "all" ] || [ "$args_routine" == "install" ]; then
    notify "startRoutine" "lib:zlib:source:install";
    task_lib_zlib_source_install;
    notify "stopRoutine" "lib:zlib:source:install";
  else
    notify "skipRoutine" "lib:zlib:source:install";
  fi;

  # run routine source:test
  if ([ "$zlib_source_test" == "yes" ] && [ "$args_routine" == "config" ]) || [ "$args_routine" == "all" ] || [ "$args_routine" == "test" ]; then
    notify "startRoutine" "lib:zlib:source:test";
    task_lib_zlib_source_test;
    notify "stopRoutine" "lib:zlib:source:test";
  else
    notify "skipRoutine" "lib:zlib:source:test";
  fi;
}

# declare task
function task_lib_zlib() {
  # run subtask package
  if ([ "$zlib_package_flag" == "yes" ] && [ "$args_subtask" == "config" ]) || [ "$args_subtask" == "all" ] || [ "$args_subtask" == "package" ]; then
    notify "startSubTask" "lib:zlib:package";
    task_lib_zlib_package;
    notify "stopSubTask" "lib:zlib:package";
  else
    notify "skipSubTask" "lib:zlib:package";
  fi;

  # run subtask source
  if ([ "$zlib_source_flag" == "yes" ] && [ "$args_subtask" == "config" ]) || [ "$args_subtask" == "all" ] || [ "$args_subtask" == "source" ]; then
    notify "startSubTask" "lib:zlib:source";
    task_lib_zlib_source;
    notify "stopSubTask" "lib:zlib:source";
  else
    notify "skipSubTask" "lib:zlib:source";
  fi;
}
