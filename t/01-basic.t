use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

my $app = Test::Mojo->new('Ado')->app;
isa_ok($app->plugin('vest'), 'Ado::Plugin::Vest');
my $dbh = $app->dbix->dbh;

#The table vest should be created by now.
is($dbh->table_info(undef, undef, 'vest', "'TABLE'")->fetchall_arrayref({})->[0]{TABLE_NAME},
    'vest', 'Table "vest" was created.');

done_testing();

