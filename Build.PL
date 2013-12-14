use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Ado::Plugin::Mess',
    license             => 'LGPL_3',
    dist_author         => q{Красимир Беров (Krasimir Berov) <berov@cpan.org>},
    dist_version_from   => 'lib/Ado/Plugin/Mess.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    add_to_cleanup     => [ 'Ado-Plugin-Mess-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
