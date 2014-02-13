# == Define: phabricator::web
#
class phabricator::web (
  $hostname = undef,
) {

  validate_string($hostname)

  include phabricator::install

  file { "${phabricator::config::base_dir}/phabricator/conf/local/local.json":
    ensure  => present,
    content => template('phabricator/config.json.erb'),
    require => Vcsrepo["${phabricator::config::base_dir}/phabricator"],
  }

  class { 'nginx':
    worker_processes => 'auto',
    server_tokens    => 'off',
    http_cfg_append  => {
      'charset'         => 'UTF-8',
      'gzip_comp_level' => '4',
      'gzip_proxied'    => 'any',
      'gzip_static'     => 'on',
      'gzip_types'      => 'application/javascript application/json application/rss+xml application/vnd.ms-fontobject application/xhtml+xml application/xml application/xml+rss application/x-font-opentype application/x-font-ttf application/x-javascript image/svg+xml image/x-icon text/css text/javascript text/plain text/xml',
      'gzip_vary'       => 'on',
      'tcp_nopush'      => 'on',
    }
  }
  nginx::resource::vhost { $hostname:
    ensure        => 'present',
    index_files   => ['index.php'],
    www_root      => "${phabricator::config::base_dir}/phabricator/webroot",
    access_log    => '/var/log/nginx/phabricator-access.log',
    error_log     => '/var/log/nginx/phabricator-error.log',
    rewrite_rules => [
      '^/(.*)$ /index.php?__path__=/$1 last',
    ],
  }
  nginx::resource::location { "${hostname}/rsrc/":
    ensure              => 'present',
    location            => '/rsrc/',
    vhost               => $hostname,
    location_custom_cfg => {
      try_files => '$uri $uri/ =404',
    },
  }
  nginx::resource::location { "${hostname}/favicon.ico":
    ensure              => 'present',
    location            => '= /favicon.ico',
    vhost               => $hostname,
    location_custom_cfg => {
      try_files => '$uri =204',
    },
  }
  nginx::resource::location { "${hostname}/~.php":
    ensure              => 'present',
    location            => '~ .php$',
    vhost               => $hostname,
    fastcgi             => 'phabricator_rack_app',
    location_cfg_append => {
      'fastcgi_index' => 'index.php',
      'fastcgi_param' => "PHABRICATOR_ENV '${phabricator::config::environment}'",
    },
  }
  nginx::resource::upstream { 'phabricator_rack_app':
    ensure  => present,
    members => [
      'localhost:9000',
    ],
  }

  php::module { ['apc', 'curl', 'gd', 'mysql']: }
  case $environment {
    'production': {
      $apc_settings = {
        'apc.stat' => '0',
      }
    }
    default: {
      $apc_settings = {
        'apc.stat' => '1',
      }
    }
  }
  php::module::ini { 'apc':
    settings => $apc_settings,
  }

  php::fpm::conf { 'www':
    ensure               => present,
    listen               => '127.0.0.1:9000',
    user                 => 'nginx',
    pm_status_path       => '/status',
    ping_path            => '/ping',
    catch_workers_output => 'yes',
    env                  => ['PATH'],
    php_value            => {
      date_timezone => 'UTC',
    },
    require              => [
      Class['nginx'],
      Php::Module['mysql'],
    ],
  }
  class { 'php::fpm::daemon': }
}
