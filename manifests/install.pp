# Installs Phabricator.
#
# @summary Installs Arcanist, libphutil and Phabricator.
# @private
#
class phabricator::install {
  # The `php::packages` class requires `Class['apt::update']` unconditionally,
  # but the `apt::update` class may not have been defined. See
  # https://github.com/voxpupuli/puppet-php/pull/323.
  include apt
  include php

  php::extension {
    'apcu':
      package_prefix => 'php-';

    ['curl', 'gd', 'mbstring']: ;

    'mysql':
      so_name => 'mysqli';
  }

  # We need to ensure that `git` is installed or else the `git` provider for
  # the `vcsrepo` type will not be functional.
  ensure_packages(['git'])

  vcsrepo {
    default:
      ensure   => 'latest',
      provider => 'git';

    'arcanist':
      path     => "${phabricator::install_dir}/arcanist",
      source   => 'https://github.com/phacility/arcanist.git',
      revision => $phabricator::arcanist_revision;

    'libphutil':
      path     => "${phabricator::install_dir}/libphutil",
      source   => 'https://github.com/phacility/libphutil.git',
      revision => $phabricator::libphutil_revision;

    'phabricator':
      path     => "${phabricator::install_dir}/phabricator",
      source   => 'https://github.com/phacility/phabricator.git',
      revision => $phabricator::phabricator_revision;
  }

  # These packages are required in order to compile XHPAST.
  ensure_packages(['g++', 'make'])

  exec { 'build_xhpast.php':
    command     => "${phabricator::install_dir}/libphutil/scripts/build_xhpast.php",
    refreshonly => true,
    require     => [
      Class['php::cli'],
      Package['g++'],
      Package['make'],
    ],
    subscribe   => Vcsrepo['libphutil'],
  }
}
