#03-ui.t
use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Mojo::Util;


my $t1  = Test::Mojo->new('Ado');
my $app = $t1->app;
my $dbh = $app->dbix->dbh;

# Remove generic routes (for this test only) so newly generated routes can match.
$app->routes->find('controller')->remove();
$app->routes->find('controlleraction')->remove();
$app->routes->find('controlleractionid')->remove();


subtest 't1_login' => sub {
    $t1->get_ok('/login/ado');

#get the csrf fields
    my $form       = $t1->tx->res->dom->at('#login_form');
    my $csrf_token = $form->at('[name="csrf_token"]')->{value};
    my $form_hash  = {
        _method        => 'login/ado',
        login_name     => 'test1',
        login_password => '',
        csrf_token     => $csrf_token,
        digest         => Mojo::Util::sha1_hex($csrf_token . Mojo::Util::sha1_hex('test1test1')),
    };
    $t1->post_ok('/login' => {} => form => $form_hash)->status_is(302);
};


done_testing;
