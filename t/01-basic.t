BEGIN {
    my $NO_ADO_HOME = <<"NO";
  \$ENV{ADO_HOME} is not set!..
  NO
  say($NO_ADO_HOME) and exit(255) unless $ENV{ADO_HOME};
NO
}
use Mojo::Base -strict;
use Test::More;
use lib "$ENV{ADO_HOME}/lib";
use Test::AdoPlugin qw($T);
Test::AdoPlugin->setup(__FILE__);

my ($dbix, $dbh) = ($T->app->dbix, $T->app->dbix->dbh);
isa_ok($T->app, 'Ado');

#warn Data::Dumper::Dumper(\%INC);
ok($INC{'Ado/Plugin/Mess.pm'}, 'Ado::Plugin::Mess is loaded');

#the thable mess should be created now
is($dbh->table_info(undef, undef, 'mess', "'TABLE'")->fetchall_arrayref({})->[0]{TABLE_NAME},
    'mess', 'Table "mess" was created.');
ok($dbh->do('DROP TABLE IF EXISTS mess'), "Table mess was dropped.");

done_testing();

