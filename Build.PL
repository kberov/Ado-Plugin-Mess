#use 5.016003;

use 5.014002;
use strict;
use warnings FATAL => 'all';
use File::Spec::Functions qw(catdir);
BEGIN{
  CORE::say "\$ENV{ADO_HOME} is missing. Please fist install Ado."
  and exit unless $ENV{ADO_HOME};
}
use lib("$ENV{ADO_HOME}/lib");
use Ado::BuildPlugin;

my $builder = Ado::BuildPlugin->new(
  module_name         => 'Ado::Plugin::Mess',
    license             => 'LGPL_3_0',
    dist_version_from   => 'lib/Ado/Plugin/Mess.pm',
    create_license     => 1,
    create_readme      => 1,
    dist_author        => q{Красимир Беров <berov@cpan.org>},
    release_status     => 'unstable',
    configure_requires => {
        'Module::Build' => '0.3800',
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
      Ado => '0.16',
    },
    add_to_cleanup     => [ 'Ado-Plugin-Mess-*' ],
    add_to_cleanup => ['Ado-Plugin-Mess-*', '*.bak'],
);

$builder->create_build_script();

