#!/bin/bash
#
# Task: Library: geoip
#

function task_lib_geoip() {

  # build subtask
  if [ "$geoip_build_flag" == "yes" ]; then
    # cleanup code and tar
    if [ "$geoip_build_cleanup" == "yes" ]; then
      sudo rm -Rf ${geoip_build_path}*;
    fi;

    # extract code from tar
    if [ ! -d "$geoip_build_path" ]; then
      if [ ! -f "${geoip_build_tar}" ]; then
        sudo bash -c "cd ${global_build_usrprefix}/src; wget ${geoip_build_url} && tar xzf ${geoip_build_tar}";
      fi;
    fi;

    cd $geoip_build_path;

    # compile binaries
    if [ "$geoip_build_make" == "yes" ]; then
      # command - add configuration tool
      geoip_build_cmd_full="./configure";

      # command - add arch
      if [ -n "$geoip_build_arg_arch" ]; then
        geoip_build_cmd_full="${geoip_build_cmd_full} --target=${geoip_build_arg_arch}";
      fi;

      # command - add prefix (usr)
      if [ -n "$geoip_build_arg_usrprefix" ]; then
        geoip_build_cmd_full="${geoip_build_cmd_full} --prefix=${geoip_build_arg_usrprefix}";
      fi;

      ## command - add libraries
      #if [ -n "$geoip_build_arg_libraries" ]; then
      #  geoip_build_cmd_full="${geoip_build_cmd_full} ${geoip_build_arg_libraries}";
      #fi;

      # command - add options
      if [ -n "$geoip_build_arg_options" ]; then
        geoip_build_cmd_full="${geoip_build_cmd_full} ${geoip_build_arg_options}";
      fi;

      # clean, configure and make
      sudo make clean;
      echo "${geoip_build_cmd_full}";
      sudo $geoip_build_cmd_full && sudo make;
    fi;

    # install binaries
    if [ "$geoip_build_install" == "yes" ] && [ -f "${geoip_build_path}/libGeoIP/.libs/libGeoIP.so" ]; then
      sudo make uninstall; sudo make install;
      sudo bash -c "cd \"${global_build_usrprefix}/share/GeoIP\" && rm -f GeoIP.dat.gz && wget \"https://mirrors-cdn.liferay.com/geolite.maxmind.com/download/geoip/database/GeoIP.dat.gz\" && rm -f GeoIP.dat && gunzip GeoIP.dat.gz";
      sudo bash -c "cd \"${global_build_usrprefix}/share/GeoIP\" && rm -f GeoIPv6.dat.gz && wget \"https://mirrors-cdn.liferay.com/geolite.maxmind.com/download/geoip/database/GeoIPv6.dat.gz\" && rm -f GeoIPv6.dat && gunzip GeoIPv6.dat.gz";
      sudo bash -c "cd \"${global_build_usrprefix}/share/GeoIP\" && rm -f GeoLiteCity.dat.xz && wget \"https://mirrors-cdn.liferay.com/geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.xz\" && rm -f GeoLiteCity.dat && unxz GeoLiteCity.dat.xz";
      sudo bash -c "cd \"${global_build_usrprefix}/share/GeoIP\" && rm -f GeoLiteCityv6.dat.gz && wget \"https://mirrors-cdn.liferay.com/geolite.maxmind.com/download/geoip/database/GeoLiteCityv6.dat.gz\" && rm -f GeoLiteCityv6.dat && gunzip GeoLiteCityv6.dat.gz";
      echo "system library: $(whereis libGeoIP.so)";
      echo "built library: ${global_build_usrprefix}/lib/libGeoIP.so";
      geoip_ldconfig_test_cmd="ldconfig -p | grep libGeoIP.so; ldconfig -v | grep libGeoIP.so";
      echo "list libraries: ${geoip_ldconfig_test_cmd}"; ${geoip_ldconfig_test_cmd};
    fi;
  fi;

}
