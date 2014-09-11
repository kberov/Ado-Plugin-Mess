use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

# This is obsolete now after Ado::Plugin is good enough.
# use Test::AdoPlugin qw($T);
# Test::AdoPlugin->setup(__FILE__);

#my ($dbix, $dbh) = ($T->app->dbix, $T->app->dbix->dbh);
#isa_ok($T->app, 'Ado');
my $app = Test::Mojo->new('Ado')->app;
isa_ok($app->plugin('vest'), 'Ado::Plugin::Vest');
my $dbh = $app->dbix->dbh;

#The table vest should be created by now.
is($dbh->table_info(undef, undef, 'vest', "'TABLE'")->fetchall_arrayref({})->[0]{TABLE_NAME},
    'vest', 'Table "vest" was created.');
ok($dbh->do('DROP TABLE IF EXISTS vest'), "Table vest was dropped.");

done_testing();

