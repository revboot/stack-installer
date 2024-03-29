#!/bin/bash
#
# Task: Application: nginx
#

# declare routine package:uninstall
function task_app_nginx_package_uninstall() {
  # uninstall binary packages
  if [ "$nginx_package_pkgs" == "bin" ]; then
    sudo apt-get remove --purge $nginx_package_pkgs_bin;
  # uninstall development packages
  elif [ "$nginx_package_pkgs" == "dev" ]; then
    sudo apt-get remove --purge $nginx_package_pkgs_dev;
  # uninstall both packages
  elif [ "$nginx_package_pkgs" == "both" ]; then
    sudo apt-get remove --purge $nginx_package_pkgs_bin $nginx_package_pkgs_dev;
  else
    notify "errorRoutine" "app:nginx:package:uninstall";
  fi;
}

# declare routine package:install
function task_app_nginx_package_install() {
  # install binary packages
  if [ "$nginx_package_pkgs" == "bin" ]; then
    sudo apt-get install -y $nginx_package_pkgs_bin;
  # install development packages
  elif [ "$nginx_package_pkgs" == "dev" ]; then
    sudo apt-get install -y $nginx_package_pkgs_dev;
  # install both packages
  elif [ "$nginx_package_pkgs" == "both" ]; then
    sudo apt-get install -y $nginx_package_pkgs_bin $nginx_package_pkgs_dev;
  else
    notify "errorRoutine" "app:nginx:package:install";
  fi;
  # whereis binary
  echo "whereis package binary: $(whereis nginx)";
}

# declare routine package:test
function task_app_nginx_package_test() {
  # ldd, ld and binary tests
  bin_path="${global_package_path_usr_sbin}/nginx";
  if [ -f "$bin_path" ]; then
    # print shared library dependencies
    ldd_cmd="ldd ${bin_path}";
    echo "shared library dependencies: ${ldd_cmd}";
    $ldd_cmd;
    # print ld debug statistics
    lddebug_cmd="env LD_DEBUG=statistics $bin_path -v";
    echo "ld debug statistics: ${lddebug_cmd}";
    $lddebug_cmd;
    # check binary info
    bin_cmd="${bin_path} -vVt";
    echo "check binary info: sudo ${bin_cmd}";
    sudo $bin_cmd;
  else
    notify "errorRoutine" "app:nginx:package:test";
  fi;
}

# declare routine source:cleanup
function task_app_nginx_source_cleanup() {
  # remove source files
  if [ -d "$nginx_source_path" ]; then
    sudo rm -Rf "${nginx_source_path}";
  else
    notify "warnRoutine" "app:nginx:source:cleanup";
  fi;
  # remove source tar
  if [ -f "$nginx_source_tar" ]; then
    sudo rm -f "${nginx_source_tar}";
  else
    notify "warnRoutine" "app:nginx:source:cleanup";
  fi;
}

# declare routine source:download
function task_app_nginx_source_download() {
  if [ ! -d "$nginx_source_path" ]; then
    # download and extract source files from tar
    if [ ! -f "$nginx_source_tar" ]; then
      sudo bash -c "cd \"${global_source_path_usr_src}\" && wget \"${nginx_source_url}\" -O \"${nginx_source_tar}\" && tar -xzf \"${nginx_source_tar}\"";
    # extract source files from tar
    else
      sudo bash -c "cd \"${global_source_path_usr_src}\" && tar -xzf \"${nginx_source_tar}\"";
    fi;
  else
    notify "warnRoutine" "app:nginx:source:download";
  fi;
}

# declare routine source:make
function task_app_nginx_source_make() {
  if [ -d "$nginx_source_path" ]; then
    # config command - add configuration tool
    config_cmd="./configure";

    # config command - add compiler
    if [ "$nginx_source_arg_compiler_flag" == "yes" ]; then
      # config command - add compiler: paths
      if [ "$nginx_source_arg_compiler_paths" == "source" ]; then
        nginx_source_arg_compiler_cc="${nginx_source_arg_compiler_cc} -I ${global_source_path_usr_inc}";
        nginx_source_arg_compiler_ld="${nginx_source_arg_compiler_ld} -L ${global_source_path_usr_lib}";
      fi;

      # config command - add compiler: cc
      if [ -n "$nginx_source_arg_compiler_cc" ]; then
        config_cmd="${config_cmd} --with-cc-opt=\'${nginx_source_arg_compiler_cc}\'";
      fi;

      # config command - add compiler: ld
      if [ -n "$nginx_source_arg_compiler_ld" ]; then
        config_cmd="${config_cmd} --with-ld-opt=\'${nginx_source_arg_compiler_ld}\'";
      fi;
    fi;

    # config command - add arch
    if [ -n "$nginx_source_arg_arch" ]; then
      config_cmd="${config_cmd} --with-cpu-opt=${nginx_source_arg_arch}";
    fi;

    # config command - add prefix (usr)
    if [ -n "$nginx_source_arg_prefix_usr" ]; then
      config_cmd="${config_cmd} --prefix=${global_source_path_usr_share}/nginx";
      config_cmd="${config_cmd} --sbin-path=${global_source_path_usr_sbin}/nginx";
      config_cmd="${config_cmd} --modules-path=${global_source_path_usr_lib}/nginx/modules";
      config_cmd="${config_cmd} --conf-path=${global_source_path_usr_etc}/nginx/nginx.conf";
    fi;
    # config command - add prefix (var)
    if [ -n "$nginx_source_arg_prefix_var" ]; then
      config_cmd="${config_cmd} --http-client-body-temp-path=${global_source_path_var_lib}/nginx/body";
      config_cmd="${config_cmd} --http-proxy-temp-path=${global_source_path_var_lib}/nginx/proxy";
      config_cmd="${config_cmd} --http-fastcgi-temp-path=${global_source_path_var_lib}/nginx/fastcgi";
      config_cmd="${config_cmd} --http-scgi-temp-path=${global_source_path_var_lib}/nginx/scgi";
      config_cmd="${config_cmd} --http-uwsgi-temp-path=${global_source_path_var_lib}/nginx/uwsgi";
      config_cmd="${config_cmd} --pid-path=${global_source_path_var_run}/nginx.pid";
      config_cmd="${config_cmd} --lock-path=${global_source_path_var_lock}/nginx.lock";
      config_cmd="${config_cmd} --error-log-path=${global_source_path_var_log}/nginx/error.log";
      config_cmd="${config_cmd} --http-log-path=${global_source_path_var_log}/nginx/access.log";
    fi;

    # config command - add libraries: zlib
    if [ "$nginx_source_arg_libraries_zlib" == "package" ]; then
      config_cmd="${config_cmd}";
    elif [ "$nginx_source_arg_libraries_zlib" == "source" ]; then
      config_cmd="${config_cmd} --with-zlib=${zlib_source_path}";
    fi;

    # config command - add libraries: pcre
    if [ "$nginx_source_arg_libraries_pcre" == "package" ]; then
      config_cmd="${config_cmd}";
    elif [ "$nginx_source_arg_libraries_pcre" == "source" ]; then
      config_cmd="${config_cmd} --with-pcre=${pcre_source_path} --with-pcre-jit";
    elif [ "$nginx_source_arg_libraries_pcre" == "no" ]; then
      config_cmd="${config_cmd} --without-pcre";
    fi;

    # config command - add libraries: openssl
    if [ "$nginx_source_arg_libraries_openssl" == "package" ]; then
      config_cmd="${config_cmd}";
    elif [ "$nginx_source_arg_libraries_openssl" == "source" ]; then
      config_cmd="${config_cmd} --with-openssl=${openssl_source_path}";
    fi;
    if [ "$nginx_source_arg_libraries_openssl" == "package" ] || [ "$nginx_source_arg_libraries_openssl" == "source" ]; then
      # config command - add openssl arch
      if [ -n "$openssl_source_arg_arch" ]; then
        config_cmd="${config_cmd} --with-openssl-opt=${openssl_source_arg_arch}";
      fi;

      # config command - add openssl options
      if [ -n "$openssl_source_arg_options" ]; then
        config_cmd="${config_cmd} --with-openssl-opt=${openssl_source_arg_options}";
      fi;

      # config command - add openssl main: threads
      if [ "$openssl_source_arg_main_threads" == "yes" ]; then
        config_cmd="${config_cmd} --with-openssl-opt=threads";
      elif [ "$openssl_source_arg_main_threads" == "no" ]; then
        config_cmd="${config_cmd} --with-openssl-opt=no-threads";
      fi;

      # config command - add openssl main: zlib
      if [ "$openssl_source_arg_main_zlib" == "yes" ]; then
        config_cmd="${config_cmd} --with-openssl-opt=zlib";
      fi;

      # config command - add openssl main: nistp gcc
      if [ "$openssl_source_arg_main_nistp" == "yes" ]; then
        config_cmd="${config_cmd} --with-openssl-opt=enable-ec_nistp_64_gcc_128";
      fi;

      # config command - add openssl proto: tls 1.3
      if [ "$openssl_source_arg_proto_tls1_3" == "no" ]; then
        config_cmd="${config_cmd} --with-openssl-opt=no-tls1_3";
      fi;

      # config command - add openssl proto: tls 1.2
      if [ "$openssl_source_arg_proto_tls1_2" == "no" ]; then
        config_cmd="${config_cmd} --with-openssl-opt=no-tls1_2";
      fi;

      # config command - add openssl proto: tls 1.1
      if [ "$openssl_source_arg_proto_tls1_1" == "no" ]; then
        config_cmd="${config_cmd} --with-openssl-opt=no-tls1_1";
      fi;

      # config command - add openssl proto: tls 1.0
      if [ "$openssl_source_arg_proto_tls1_0" == "no" ]; then
        config_cmd="${config_cmd} --with-openssl-opt=no-tls1";
      fi;

      # config command - add openssl proto: ssl 3
      if [ "$openssl_source_arg_proto_ssl3" == "no" ]; then
        config_cmd="${config_cmd} --with-openssl-opt=no-ssl3";
      fi;

      # config command - add openssl proto: ssl 2
      if [ "$openssl_source_arg_proto_ssl2" == "no" ]; then
        config_cmd="${config_cmd} --with-openssl-opt=no-ssl2";
      fi;

      # config command - add openssl proto: dtls 1.2
      if [ "$openssl_source_arg_proto_dtls1_2" == "no" ]; then
        config_cmd="${config_cmd} --with-openssl-opt=no-dtls1_2";
      fi;

      # config command - add openssl proto: dtls 1.0
      if [ "$openssl_source_arg_proto_dtls1_0" == "no" ]; then
        config_cmd="${config_cmd} --with-openssl-opt=no-dtls1";
      fi;

      # config command - add openssl proto: next proto negotiation
      if [ "$openssl_source_arg_proto_npn" == "no" ]; then
        config_cmd="${config_cmd} --with-openssl-opt=no-nextprotoneg";
      fi;

      # config command - add openssl cypher: idea
      if [ "$openssl_source_arg_cypher_idea" == "no" ]; then
        config_cmd="${config_cmd} --with-openssl-opt=no-idea";
      fi;

      # config command - add openssl cypher: weak ciphers
      if [ "$openssl_source_arg_cypher_weak" == "no" ]; then
        config_cmd="${config_cmd} --with-openssl-opt=no-weak-ssl-ciphers";
      fi;
    fi;

    # config command - add libraries: libatomic
    if [ "$nginx_source_arg_libraries_libatomic" == "package" ]; then
      config_cmd="${config_cmd}";
    elif [ "$nginx_source_arg_libraries_libatomic" == "source" ]; then
      config_cmd="${config_cmd} --with-libatomic=${libatomic_source_path}";
    fi;

    # config command - add options
    if [ -n "$nginx_source_arg_options" ]; then
      config_cmd="${config_cmd} ${nginx_source_arg_options}";
    fi;

    # config command - add main: distro
    if [ -n "$nginx_source_arg_main_distro" ]; then
      config_cmd="${config_cmd} --build=${nginx_source_arg_main_distro}";
    fi;

    # config command - add main: user
    if [ -n "$nginx_source_arg_main_user" ]; then
      config_cmd="${config_cmd} --user=${nginx_source_arg_main_user}";
    fi;

    # config command - add main: group
    if [ -n "$nginx_source_arg_main_group" ]; then
      config_cmd="${config_cmd} --group=${nginx_source_arg_main_group}";
    fi;

    # config command - add main: debug
    if [ "$nginx_source_arg_main_debug_flag" == "yes" ]; then
      config_cmd="${config_cmd} --with-debug";
    fi;

    # config command - add main: threads
    if [ "$nginx_source_arg_main_threads_flag" == "yes" ]; then
      config_cmd="${config_cmd} --with-threads";
    fi;

    # config command - add main: asynchronous io
    if [ "$nginx_source_arg_main_fileaio_flag" == "yes" ]; then
      config_cmd="${config_cmd} --with-file-aio";
    fi;

    # config command - add main: ipv6
    if [ "$nginx_source_arg_main_ipv6_flag" == "yes" ]; then
      config_cmd="${config_cmd} --with-ipv6";
    fi;

    # config command - add main: (dynamic module) compat(ibility)
    if [ "$nginx_source_arg_main_compat_flag" == "yes" ]; then
      config_cmd="${config_cmd} --with-compat";
    fi;

    # config command - add connection modules: poll
    if [ "$nginx_source_arg_module_poll_flag" == "yes" ]; then
      config_cmd="${config_cmd} --with-poll_module";
    elif [ "$nginx_source_arg_module_poll_flag" == "no" ]; then
      config_cmd="${config_cmd} --without-poll_module";
    fi;

    # config command - add connection modules: select
    if [ "$nginx_source_arg_module_select_flag" == "yes" ]; then
      config_cmd="${config_cmd} --with-select_module";
    elif [ "$nginx_source_arg_module_select_flag" == "no" ]; then
      config_cmd="${config_cmd} --without-select_module";
    fi;

    if [ "$nginx_source_arg_modules_http_flag" == "yes" ]; then
      # config command - add http modules: protocol: (http)v2
      if [ "$nginx_source_arg_modules_http_http2_flag" == "yes" ]; then
        config_cmd="${config_cmd} --with-http_v2_module";
      fi;

      # config command - add http modules: protocol: spdy
      if [ "$nginx_source_arg_modules_http_spdy_flag" == "yes" ]; then
        config_cmd="${config_cmd} --with-http_spdy_module";
      fi;

      # config command - add http modules: protocol: ssl
      if [ "$nginx_source_arg_modules_http_ssl_flag" == "yes" ]; then
        config_cmd="${config_cmd} --with-http_ssl_module";
      fi;

     # config command - add http modules: protocol: dav
      if [ "$nginx_source_arg_modules_http_webdav_flag" == "yes" ]; then
        config_cmd="${config_cmd} --with-http_dav_module";
      fi;

      # config command - add http modules: core: rewrite
      if [ "$nginx_source_arg_modules_http_rewrite_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-http_rewrite_module";
      fi;

      # config command - add http modules: core: map
      if [ "$nginx_source_arg_modules_http_map_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-http_map_module";
      fi;

      # config command - add http modules: core: browser
      if [ "$nginx_source_arg_modules_http_browser_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-http_browser_module";
      fi;

      # config command - add http modules: core: userid
      if [ "$nginx_source_arg_modules_http_userid_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-http_userid_module";
      fi;

      # config command - add http modules: index: auto_index
      if [ "$nginx_source_arg_modules_http_autoindex_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-http_autoindex_module";
      fi;

      # config command - add http modules: index: random_index
      if [ "$nginx_source_arg_modules_http_randomindex_flag" == "yes" ]; then
        config_cmd="${config_cmd} --with-http_random_index_module";
      fi;

      # config command - add http modules: access/limit: access
      if [ "$nginx_source_arg_modules_http_access_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-http_access_module";
      fi;

      # config command - add http modules: access/limit: limit_conn
      if [ "$nginx_source_arg_modules_http_limitconn_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-http_limit_conn_module";
      fi;

      # config command - add http modules: access/limit: limit_req
      if [ "$nginx_source_arg_modules_http_limitreq_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-http_limit_req_module";
      fi;

      # config command - add http modules: auth: auth_basic
      if [ "$nginx_source_arg_modules_http_authbasic_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-http_auth_basic_module";
      fi;

      # config command - add http modules: auth: auth_(sub)request
      if [ "$nginx_source_arg_modules_http_authrequest_flag" == "yes" ]; then
        config_cmd="${config_cmd} --with-http_auth_request_module";
      fi;

      # config command - add http modules: security: referer
      if [ "$nginx_source_arg_modules_http_referer_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-http_referer_module";
      fi;

      # config command - add http modules: security: secure_link
      if [ "$nginx_source_arg_modules_http_securelink_flag" == "yes" ]; then
        config_cmd="${config_cmd} --with-http_secure_link_module";
      fi;

      # config command - add http modules: location: realip
      if [ "$nginx_source_arg_modules_http_realip_flag" == "yes" ]; then
        config_cmd="${config_cmd} --with-http_realip_module";
      fi;

      # config command - add http modules: location: geo
      if [ "$nginx_source_arg_modules_http_geo_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-http_geo_module";
      fi;

      # config command - add http modules: location: geoip --static
      if [ "$nginx_source_arg_modules_http_geoip_flag" == "yes" ]; then
        config_cmd="${config_cmd} --with-http_geoip_module";
      fi;

      # config command - add http modules: location: geoip --dso
      if [ "$nginx_source_arg_modules_http_geoip_flag" == "dso" ]; then
        config_cmd="${config_cmd} --with-http_geoip_module=dynamic";
      fi;

      # config command - add http modules: encoding: gzip_static/gzip
      if [ "$nginx_source_arg_modules_http_gzip_flag" == "yes" ]; then
        config_cmd="${config_cmd} --with-http_gzip_static_module";
      elif [ "$nginx_source_arg_modules_http_gzip_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-http_gzip_module";
      fi;

      # config command - add http modules: encoding: gunzip
      if [ "$nginx_source_arg_modules_http_gunzip_flag" == "yes" ]; then
        config_cmd="${config_cmd} --with-http_gunzip_module";
      fi;

      # config command - add http modules: encoding: charset
      if [ "$nginx_source_arg_modules_http_charset_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-http_charset_module";
      fi;

      # config command - add http modules: filter: empty_gif
      if [ "$nginx_source_arg_modules_http_emptygif_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-http_empty_gif_module";
      fi;

      # config command - add http modules: filter: image_filter --static
      if [ "$nginx_source_arg_modules_http_imagefilter_flag" == "yes" ]; then
        config_cmd="${config_cmd} --with-http_image_filter_module";
      fi;

      # config command - add http modules: filter: image_filter --dso
      if [ "$nginx_source_arg_modules_http_imagefilter_flag" == "dso" ]; then
        config_cmd="${config_cmd} --with-http_image_filter_module=dynamic";
      fi;

      # config command - add http modules: filter: xslt --static
      if [ "$nginx_source_arg_modules_http_xslt_flag" == "yes" ]; then
        config_cmd="${config_cmd} --with-http_xslt_module";
      fi;

      # config command - add http modules: filter: xslt --dso
      if [ "$nginx_source_arg_modules_http_xslt_flag" == "dso" ]; then
        config_cmd="${config_cmd} --with-http_xslt_module=dynamic";
      fi;

      # config command - add http modules: filter: sub(stitute)
      if [ "$nginx_source_arg_modules_http_sub_flag" == "yes" ]; then
        config_cmd="${config_cmd} --with-http_sub_module";
      fi;

      # config command - add http modules: filter: addition
      if [ "$nginx_source_arg_modules_http_addition_flag" == "yes" ]; then
        config_cmd="${config_cmd} --with-http_addition_module";
      fi;

      # config command - add http modules: filter: slice
      if [ "$nginx_source_arg_modules_http_slice_flag" == "yes" ]; then
        config_cmd="${config_cmd} --with-http_slice_module";
      fi;

      # config command - add http modules: pseudo-stream: mp4
      if [ "$nginx_source_arg_modules_http_mp4_flag" == "yes" ]; then
        config_cmd="${config_cmd} --with-http_mp4_module";
      fi;

      # config command - add http modules: pseudo-stream: flv
      if [ "$nginx_source_arg_modules_http_flv_flag" == "yes" ]; then
        config_cmd="${config_cmd} --with-http_flv_module";
      fi;

      # config command - add http modules: upstream: upstream_keepalive
      if [ "$nginx_source_arg_modules_http_upstream_keepalive_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-http_upstream_keepalive_module";
      fi;

      # config command - add http modules: upstream: upstream_least_conn
      if [ "$nginx_source_arg_modules_http_upstream_leastconn_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-http_upstream_least_conn_module";
      fi;

      # config command - add http modules: upstream: upstream_random
      if [ "$nginx_source_arg_modules_http_upstream_random_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-http_upstream_random_module";
      fi;

      # config command - add http modules: upstream: upstream_hash
      if [ "$nginx_source_arg_modules_http_upstream_hash_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-http_upstream_hash_module";
      fi;

      # config command - add http modules: upstream: upstream_ip_hash
      if [ "$nginx_source_arg_modules_http_upstream_iphash_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-http_upstream_ip_hash_module";
      fi;

      # config command - add http modules: upstream: upstream_zone
      if [ "$nginx_source_arg_modules_http_upstream_zone_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-http_upstream_zone_module";
      fi;

      # config command - add http modules: proxy/cgi: proxy
      if [ "$nginx_source_arg_modules_http_proxy_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-http_proxy_module";
      fi;

      # config command - add http modules: proxy/cgi: fastcgi
      if [ "$nginx_source_arg_modules_http_fastcgi_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-http_fastcgi_module";
      fi;

      # config command - add http modules: proxy/cgi: scgi
      if [ "$nginx_source_arg_modules_http_scgi_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-http_scgi_module";
      fi;

      # config command - add http modules: proxy/cgi: uwsgi
      if [ "$nginx_source_arg_modules_http_uwsgi_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-http_uwsgi_module";
      fi;

      # config command - add http modules: proxy/cgi: grpc
      if [ "$nginx_source_arg_modules_http_grpc_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-http_grpc_module";
      fi;

      # config command - add http modules: script: ssi
      if [ "$nginx_source_arg_modules_http_ssi_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-http_ssi_module";
      fi;

      # config command - add http modules: script: perl --static
      if [ "$nginx_source_arg_modules_http_perl_flag" == "yes" ]; then
        config_cmd="${config_cmd} --with-http_perl_module";
      fi;

      # config command - add http modules: script: perl --dso
      if [ "$nginx_source_arg_modules_http_perl_flag" == "dso" ]; then
        config_cmd="${config_cmd} --with-http_perl_module=dynamic";
      fi;

      # config command - add http modules: cache
      if [ "$nginx_source_arg_modules_http_cache_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-http-cache";
      fi;

      # config command - add http modules: cache: memcached
      if [ "$nginx_source_arg_modules_http_memcached_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-http_memcached_module";
      fi;

      # config command - add http modules: other: mirror
      if [ "$nginx_source_arg_modules_http_mirror_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-http_mirror_module";
      fi;

      # config command - add http modules: other: split_clients
      if [ "$nginx_source_arg_modules_http_splitclients_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-http_split_clients_module";
      fi;

      # config command - add http modules: other: stub_status:
      if [ "$nginx_source_arg_modules_http_stub_flag" == "yes" ]; then
        config_cmd="${config_cmd} --with-http_stub_status_module";
      fi;
    fi;

    # config command - add stream modules
    if [ "$nginx_source_arg_modules_stream_flag" == "yes" ] || [ "$nginx_source_arg_modules_stream_flag" == "dso" ]; then
      # config command - add stream modules: --static
      if [ "$nginx_source_arg_modules_stream_flag" == "yes" ]; then
        config_cmd="${config_cmd} --with-stream";
      fi;

      # config command - add stream modules: --dso
      if [ "$nginx_source_arg_modules_stream_flag" == "dso" ]; then
        config_cmd="${config_cmd} --with-stream=dynamic";
      fi;

      # config command - add stream modules: protocol: ssl
      if [ "$nginx_source_arg_modules_stream_ssl_flag" == "yes" ]; then
        config_cmd="${config_cmd} --with-stream_ssl_module";
      fi;

      # config command - add stream modules: protocol: ssl_preread
      if [ "$nginx_source_arg_modules_stream_ssl_preread_flag" == "yes" ]; then
        config_cmd="${config_cmd} --with-stream_ssl_preread_module";
      fi;

      # config command - add stream modules: core: map
      if [ "$nginx_source_arg_modules_stream_map_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-stream_map_module";
      fi;

      # config command - add stream modules: access/limit: limit_conn
      if [ "$nginx_source_arg_modules_stream_limitconn_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-stream_limit_conn_module";
      fi;

      # config command - add stream modules: access/limit: access
      if [ "$nginx_source_arg_modules_stream_access_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-stream_access_module";
      fi;

      # config command - add stream modules: location: realip
      if [ "$nginx_source_arg_modules_stream_realip_flag" == "yes" ]; then
        config_cmd="${config_cmd} --with-stream_realip_module";
      fi;

      # config command - add stream modules: location: geo
      if [ "$nginx_source_arg_modules_stream_geo_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-stream_geo_module";
      fi;

      # config command - add stream modules: location: geoip: --static
      if [ "$nginx_source_arg_modules_stream_geoip_flag" == "yes" ]; then
        config_cmd="${config_cmd} --with-stream_geoip_module";
      # config command - add stream modules: location: geoip: --dso
      elif [ "$nginx_source_arg_modules_stream_geoip_flag" == "dso" ]; then
        config_cmd="${config_cmd} --with-stream_geoip_module=dynamic";
      fi;

      # config command - add stream modules: upstream: upstream_least_conn
      if [ "$nginx_source_arg_modules_stream_upstream_leastconn_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-stream_upstream_least_conn_module";
      fi;

      # config command - add stream modules: upstream: upstream_random
      if [ "$nginx_source_arg_modules_stream_upstream_random_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-stream_upstream_random_module";
      fi;

      # config command - add stream modules: upstream: upstream_hash
      if [ "$nginx_source_arg_modules_stream_upstream_hash_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-stream_upstream_hash_module";
      fi;

      # config command - add stream modules: upstream: upstream_zone
      if [ "$nginx_source_arg_modules_stream_upstream_zone_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-stream_upstream_zone_module";
      fi;

      # config command - add stream modules: other: return
      if [ "$nginx_source_arg_modules_stream_return_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-stream_return_module";
      fi;

      # config command - add stream modules: other: split_clients
      if [ "$nginx_source_arg_modules_stream_splitclients_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-stream_split_clients_module";
      fi;
    fi;

    # config command - add mail modules
    if [ "$nginx_source_arg_modules_mail_flag" == "yes" ] || [ "$nginx_source_arg_modules_mail_flag" == "dso" ]; then
      # config command - add mail modules: --static
      if [ "$nginx_source_arg_modules_mail_flag" == "yes" ]; then
        config_cmd="${config_cmd} --with-mail";
      # config command - add mail modules: --dso
      elif [ "$nginx_source_arg_modules_mail_flag" == "dso" ]; then
        config_cmd="${config_cmd} --with-mail=dynamic";
      fi;

      # config command - add mail modules: protocol: ssl
      if [ "$nginx_source_arg_modules_mail_ssl_flag" == "yes" ]; then
        config_cmd="${config_cmd} --with-mail_ssl_module";
      fi;

      # config command - add mail modules: protocol: smtp
      if [ "$nginx_source_arg_modules_mail_smtp_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-mail_smtp_module";
      fi;

      # config command - add mail modules: protocol: pop3
      if [ "$nginx_source_arg_modules_mail_pop3_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-mail_pop3_module";
      fi;

      # config command - add mail modules: protocol: imap
      if [ "$nginx_source_arg_modules_mail_imap_flag" == "no" ]; then
        config_cmd="${config_cmd} --without-mail_imap_module";
      fi;
    fi;

    # config command - add other modules
    if [ "$nginx_source_arg_modules_other_flag" == "yes" ]; then
      # config command - add other modules: cpp_test
      if [ "$nginx_source_arg_modules_other_cpptest_flag" == "yes" ]; then
        config_cmd="${config_cmd} --with-cpp_test_module";
      fi;

      # config command - add other modules: google_perftools
      if [ "$nginx_source_arg_modules_other_googleperftools_flag" == "yes" ]; then
        config_cmd="${config_cmd} --with-google_perftools_module";
      fi;
    fi;

    # make command - add make tool
    make_cmd="make -j${global_source_make_cores}";

    # clean, configure and make
    sudo bash -c "cd \"${nginx_source_path}\" && make clean";
    echo "config arguments: ${config_cmd}";
    echo "make arguments: ${make_cmd}";
    sudo bash -c "cd \"${nginx_source_path}\" && eval ${config_cmd} && eval ${make_cmd}";
  else
    notify "errorRoutine" "app:nginx:source:make";
  fi;
}

# declare routine source:uninstall
function task_app_nginx_source_uninstall() {
  if [ -f "${global_source_path_usr_sbin}/nginx" ]; then
    # uninstall binaries from source
    sudo rm -f "${global_source_path_usr_sbin}/nginx";
    sudo rm -Rf "${global_source_path_usr_share}/nginx";
    # remove source etc directory
    if [ -d "${global_source_path_usr_etc}/nginx" ]; then
      sudo rm -Rf "${global_source_path_usr_etc}/nginx";
    # remove source etc symlink
    elif [ -L "${global_source_path_usr_etc}/nginx" ]; then
      sudo rm -f "${global_source_path_usr_etc}/nginx";
    fi;
  else
    notify "errorRoutine" "app:nginx:source:uninstall";
  fi;
}

# declare routine source:install
function task_app_nginx_source_install() {
  if [ -f "$nginx_source_path/objs/nginx" ]; then
    # install binaries from source
    sudo bash -c "cd \"${nginx_source_path}\" && make install";
    # create missing directory
    sudo mkdir -p "${global_source_path_var_lib}/nginx";
    # whereis binary
    echo "whereis source binary: ${global_source_path_usr_sbin}/nginx";
  else
    notify "errorRoutine" "app:nginx:source:install";
  fi;
}

# declare routine source:etc
function task_app_nginx_source_etc() {
  # use configuration from package
  if [ -d "${global_package_path_usr_etc}/nginx" ] && [ "$nginx_source_etc_mode" == "package" ]; then
    # remove source etc directory
    if [ -d "${global_source_path_usr_etc}/nginx" ]; then
      sudo rm -Rf "${global_source_path_usr_etc}/nginx";
    # remove source etc symlink
    elif [ -L "${global_source_path_usr_etc}/nginx" ]; then
      sudo rm -f "${global_source_path_usr_etc}/nginx";
    fi;
    # symlink directory and remove backups
    sudo ln -s "${global_package_path_usr_etc}/nginx" "${global_source_path_usr_etc}/nginx";
    sudo rm -f "${global_source_path_usr_etc}/nginx/*.default";
  # use configuration from source
  elif [ -d "${global_source_path_usr_etc}/nginx" ] && [ "$nginx_source_etc_mode" == "source" ]; then
    # copy configuration from source etc to package etc
    sudo cp "${global_source_path_usr_etc}/nginx/*" "${global_package_path_usr_etc}/nginx";
  else
    notify "errorRoutine" "app:nginx:source:etc";
  fi;
}

# declare routine source:test
function task_app_nginx_source_test() {
  # ldd, ld and binary tests
  bin_path="${global_source_path_usr_sbin}/nginx";
  if [ -f "$bin_path" ]; then
    # print shared library dependencies
    ldd_cmd="ldd ${bin_path}";
    echo "shared library dependencies: ${ldd_cmd}";
    $ldd_cmd;
    # print ld debug statistics
    lddebug_cmd="env LD_DEBUG=statistics $bin_path -v";
    echo "ld debug statistics: ${lddebug_cmd}";
    $lddebug_cmd;
    # check binary info
    bin_cmd="${bin_path} -vVt";
    echo "check binary info: sudo ${bin_cmd}";
    sudo $bin_cmd;
  else
    notify "errorRoutine" "app:nginx:source:test";
  fi;
}

# declare subtask package
function task_app_nginx_package() {
  # run routine package:uninstall
  if ([ "$nginx_package_uninstall" == "yes" ] && [ "$args_routine" == "config" ]) || [ "$args_routine" == "uninstall" ]; then
    notify "startRoutine" "app:nginx:package:uninstall";
    task_app_nginx_package_uninstall;
    notify "stopRoutine" "app:nginx:package:uninstall";
  else
    notify "skipRoutine" "app:nginx:package:uninstall";
  fi;

  # run routine package:install
  if ([ "$nginx_package_install" == "yes" ] && [ "$args_routine" == "config" ]) || [ "$args_routine" == "all" ] || [ "$args_routine" == "install" ]; then
    notify "startRoutine" "app:nginx:package:install";
    task_app_nginx_package_install;
    notify "stopRoutine" "app:nginx:package:install";
  else
    notify "skipRoutine" "app:nginx:package:install";
  fi;

  # run routine package:test
  if ([ "$nginx_package_test" == "yes" ] && [ "$args_routine" == "config" ]) || [ "$args_routine" == "all" ] || [ "$args_routine" == "test" ]; then
    notify "startRoutine" "app:nginx:package:test";
    task_app_nginx_package_test;
    notify "stopRoutine" "app:nginx:package:test";
  else
    notify "skipRoutine" "app:nginx:package:test";
  fi;
}

# declare subtask source
function task_app_nginx_source() {
  # run routine source:cleanup
  if ([ "$nginx_source_cleanup" == "yes" ] && [ "$args_routine" == "config" ]) || [ "$args_routine" == "cleanup" ]; then
    notify "startRoutine" "app:nginx:source:cleanup";
    task_app_nginx_source_cleanup;
    notify "stopRoutine" "app:nginx:source:cleanup";
  else
    notify "skipRoutine" "app:nginx:source:cleanup";
  fi;

  # run routine source:download
  if ([ "$nginx_source_download" == "yes" ] && [ "$args_routine" == "config" ]) || [ "$args_routine" == "all" ] || [ "$args_routine" == "download" ]; then
    notify "startRoutine" "app:nginx:source:download";
    task_app_nginx_source_download;
    notify "stopRoutine" "app:nginx:source:download";
  else
    notify "skipRoutine" "app:nginx:source:download";
  fi;

  # run routine source:make
  if ([ "$nginx_source_make" == "yes" ] && [ "$args_routine" == "config" ]) || [ "$args_routine" == "all" ] || [ "$args_routine" == "make" ]; then
    notify "startRoutine" "app:nginx:source:make";
    task_app_nginx_source_make;
    notify "stopRoutine" "app:nginx:source:make";
  else
    notify "skipRoutine" "app:nginx:source:make";
  fi;

  # run routine source:uninstall
  if ([ "$nginx_source_uninstall" == "yes" ] && [ "$args_routine" == "config" ]) || [ "$args_routine" == "uninstall" ]; then
    notify "startRoutine" "app:nginx:source:uninstall";
    task_app_nginx_source_uninstall;
    notify "stopRoutine" "app:nginx:source:uninstall";
  else
    notify "skipRoutine" "app:nginx:source:uninstall";
  fi;

  # run routine source:install
  if ([ "$nginx_source_install" == "yes" ] && [ "$args_routine" == "config" ]) || [ "$args_routine" == "all" ] || [ "$args_routine" == "install" ]; then
    notify "stopRoutine" "app:nginx:source:install";
    task_app_nginx_source_install;
    notify "stopRoutine" "app:nginx:source:install";
  else
    notify "skipRoutine" "app:nginx:source:install";
  fi;

  # run routine source:etc
  if ([ "$nginx_source_etc" == "yes" ] && [ "$args_routine" == "config" ]) || [ "$args_routine" == "all" ] || [ "$args_routine" == "etc" ]; then
    notify "startRoutine" "app:nginx:source:etc";
    task_app_nginx_source_etc;
    notify "stopRoutine" "app:nginx:source:etc";
  else
    notify "skipRoutine" "app:nginx:source:etc";
  fi;

  # run routine source:test
  if ([ "$nginx_source_test" == "yes" ] && [ "$args_routine" == "config" ]) || [ "$args_routine" == "all" ] || [ "$args_routine" == "test" ]; then
    notify "startRoutine" "app:nginx:source:test";
    task_app_nginx_source_test;
    notify "stopRoutine" "app:nginx:source:test";
  else
    notify "skipRoutine" "app:nginx:source:test";
  fi;
}

# declare task
function task_app_nginx() {
  # run subtask package
  if ([ "$nginx_package_flag" == "yes" ] && [ "$args_subtask" == "config" ]) || [ "$args_subtask" == "all" ] || [ "$args_subtask" == "package" ]; then
    notify "startSubTask" "app:nginx:package";
    task_app_nginx_package;
    notify "stopSubTask" "app:nginx:package";
  else
    notify "skipSubTask" "app:nginx:package";
  fi;

  # run subtask source
  if ([ "$nginx_source_flag" == "yes" ] && [ "$args_subtask" == "config" ]) || [ "$args_subtask" == "all" ] || [ "$args_subtask" == "source" ]; then
    notify "startSubTask" "app:nginx:source";
    task_app_nginx_source;
    notify "stopSubTask" "app:nginx:source";
  else
    notify "skipSubTask" "app:nginx:source";
  fi;
}
