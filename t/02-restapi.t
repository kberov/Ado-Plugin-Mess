#restapi.t
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

#{route => '/mess', via => ['GET'],  to => 'mess#list',}
#no format
$T->get_ok('/mess')->status_is('415', '415 - Unsupported Media Type ')
  ->content_type_is('text/html;charset=UTF-8')->header_like(
    'Content-Location' => qr|http\://localhost\:\d+/mess.json|x,
    'Content-Location points to /mess.json'
  )->content_like(qr|http://localhost:\d+/mess.json</a>\!|x, 'Error page points to /mess.json');
$T->get_ok('/mess/list')->status_is('404', '404 Not Found');
#with format
$T->get_ok('/mess.json')->status_is('200', 'Status is 200')->content_type_is('application/json')
  ->json_has('/data')->json_has('/links')
  ->json_is('/links/0/rel' => 'self', '/links/0/rel is self')->json_is(
    '/links/0/href' => '/mess.json?limit=20&offset=0',
    '/links/0/href is /mess.json?limit=20&offset=0'
  )->json_is('/links/1' => undef, '/links/2 is not present')

  ->json_is('/links/2' => undef, '/links/2 is not present')
  ->json_is('/data'    => [],    '/data is empty')->json_is(
    {   links => [
            {   rel  => 'self',
                href => '/mess.json?limit=20&offset=0',
            }
        ],
        data => []
    }
  );
#{route => '/mess', via => ['POST'], to => 'mess#add',},
        

done_testing();

