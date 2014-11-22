use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
my $t   = Test::Mojo->new('Ado');
my $app = $t->app;

# Remove generic routes (for this test only).
$app->routes->find('controlleraction')->remove();

$app->routes->post('/vest/uadd')->to(
    cb => sub {
        my $c = shift;
        $c->app->plugins->emit_hook(after_user_add => $c, $c->user, {});
        $c->render(text => $c->user->ingroup('vest') || '');
    }
);

my $dbh = $app->dbix->dbh;

isa_ok($app->plugin('vest'), 'Ado::Plugin::Vest');

#The table vest should be created by now.
is($dbh->table_info(undef, undef, 'vest', "'TABLE'")->fetchall_arrayref({})->[0]{TABLE_NAME},
    'vest', 'Table "vest" was created.');

$t->post_ok('/vest/uadd' => {})->status_is(200)->content_is('vest');

#Now user "Guest" should be in group "vest".
done_testing();

