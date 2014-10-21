use 5.014;
use strict;
use warnings FATAL => 'all';
use Ado::BuildPlugin;

my $builder = Ado::BuildPlugin->new(
    module_name        => 'Ado::Plugin::Vest',
    license            => 'lgpl_3_0',
    dist_version_from  => 'lib/Ado/Plugin/Vest.pm',
    create_readme      => 1,
    dist_author        => q{Красимир Беров <berov@cpan.org>},
    release_status     => 'unstable',
    configure_requires => {'Module::Build' => '0.42', 'Ado' => '0.67'},
    build_requires => {'Test::More' => '0',},
    requires       => {
        'Ado'                             => '0.67',
        'Mojolicious'                     => '0',
        'Mojolicious::Plugin::DSC'        => '0',
        'Mojolicious::Plugin::SemanticUI' => '0'
    },
    add_to_cleanup => ['Ado-Plugin-Vest-*', '*.bak'],
);

$builder->create_build_script();
