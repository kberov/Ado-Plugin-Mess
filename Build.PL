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
    configure_requires => {'Module::Build' => '0.42', 'Ado' => '0.76'},
    build_requires => {'Test::More' => '0',},
    requires       => {
        'perl'                            => '5.14.0',
        'Ado'                             => '0.921',
        'Mojolicious'                     => '6.10',
        'Mojolicious::Plugin::DSC'        => '0',
        'Mojolicious::Plugin::SemanticUI' => '0.17'
    },
    recursive_test_files => 1,
    meta_merge           => {
        resources => {
            repository => "https://github.com/kberov/Ado-Plugin-Vest",
            bugtracker => "https://github.com/kberov/Ado-Plugin-Vest/issues",
        },
        keywords => [qw/Ado Mojolicious web ERP REST Messaging chat enterprise/],
        no_index => {namespace => ['Ado::Model'],}
    },

    add_to_cleanup => ['Ado-Plugin-Vest-*', '*.bak'],
);

$builder->create_build_script();
