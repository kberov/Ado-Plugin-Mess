use Mojo::Base -strict;
use Test::More;
use Test::AdoPlugin qw($T);
Test::AdoPlugin->setup(__FILE__);

my ($dbix, $dbh) = ($T->app->dbix, $T->app->dbix->dbh);
isa_ok($T->app, 'Ado');

#the thable vest should be created now
is( $dbh->table_info(undef, undef, 'vest', "'TABLE'")->fetchall_arrayref({})
      ->[0]{TABLE_NAME},
    'vest',
    'Table "vest" was created.'
);
ok($dbh->do('DROP TABLE IF EXISTS vest'), "Table vest was dropped.");

done_testing();

