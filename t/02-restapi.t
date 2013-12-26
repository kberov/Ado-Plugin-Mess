#restapi.t
BEGIN {
    my $NO_ADO_HOME = "\$ENV{ADO_HOME} is not set!..";

    #try to guess
    $ENV{ADO_HOME} = "$ENV{HOME}/opt/ado"
      unless $ENV{ADO_HOME} and -d "$ENV{HOME}/opt/ado/lib";
    say($NO_ADO_HOME) and exit(255) unless $ENV{ADO_HOME};
}
use Mojo::Base -strict;
use Test::More;
use lib "$ENV{ADO_HOME}/lib";
use Test::AdoPlugin qw($T);
Test::AdoPlugin->setup(__FILE__);

my ($dbix, $dbh) = ($T->app->dbix, $T->app->dbix->dbh);

#make sure the mess table is empty
ok($dbh->do('DROP TABLE IF EXISTS mess'), "Table mess was dropped.");

#remove the helper
is(delete ${Ado::}{dbix}, '*Ado::dbix', 'ok removed *Ado::dbix...');

#restart app
Test::AdoPlugin->setup(__FILE__);
($dbix, $dbh) = ($T->app->dbix, $T->app->dbix->dbh);

#reload
#{route => '/mess', via => ['GET'],  to => 'mess#list',}
#no format
$T->get_ok('/mess')->status_is('415', '415 - Unsupported Media Type ')
  ->content_type_is('text/html;charset=UTF-8')->header_like(
    'Content-Location' => qr|http\://localhost\:\d+/mess.json|x,
    'Content-Location points to /mess.json'
  )->content_like(
    qr|http://localhost:\d+/mess.json</a>\!|x,
    'Error page points to /mess.json'
  );
$T->get_ok('/mess/list')->status_is('404', '404 Not Found');

#with format
$T->get_ok('/mess.json')->status_is('200', 'Status is 200')
  ->content_type_is('application/json')->json_has('/data')->json_has('/links')
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

#Play with several messages.
#{route => '/mess', via => ['POST'], to => 'mess#add',},
$T->post_ok(
    '/mess',
    form => {
        from_uid           => 3,
        subject_message_id => 0,

        #to_uid   => 4,
        subject => 'Какъв приятен разговор!',
        message => 'Здравей, Приятел!'
    }
  )->status_is('400', 'Status is 400')->json_is(
    {   'code'    => 400,
        'data'    => 'validate_input',
        'message' => {'to_uid' => ['required'],},
        'status'  => 'error'
    },
    'erros ok: to_uid is required '
  );
$T->post_ok(
    '/mess',
    form => {
        from_uid           => 3,
        subject_message_id => 0,
        to_uid             => 'не число',
        subject            => 'Какъв приятен разговор!',
        message            => 'Здравей, Приятел!'
    }
  )->status_is('400', 'Status is 400')
  ->content_like(qr/"message"\:\{"to_uid"\:\["like"/x,
    'erros ok: to_uid is not alike ');

my $messages = 10;

$T->post_ok(
    '/mess',
    form => {
        from_uid           => 3,
        to_uid             => 4,
        subject            => 'Какъв приятен разговор',
        subject_message_id => 0,
        message            => 'Здравей, Приятел!'
    }
  )->status_is('201', 'ok 201 - Created')
  ->header_is(Location => '/mess/1.json')->content_is('');

=pod
{   route  => '/mess/:id',
    params => {id => qr/\d+/},
    via    => ['GET'],
    to     => 'messshow',
},
=cut

$T->get_ok('/mess/1')->status_is('200', 'Status is 200')
  ->json_is('/data/message', 'Здравей, Приятел!','ok created');

#=pod
#{   route  => '/mess/:id',
#    params => {id => qr/\d+/},
#    via    => ['PUT'],
#    to     => 'mess#update',
#},
#=cut

#$T->put_ok('/mess/' . int(rand($messages)))->status_is('200', 'Status is 200')
#  ->content_is('not implemented...', 'ok not implemented...yet');

#=pod
#{   route  => '/mess/:id',
#    params => {id => qr/\d+/},
#    via    => ['DELETE'],
#    to     => 'mess#disable',
#},
#=cut

#$T->delete_ok('/mess/' . int(rand($messages)))
#  ->status_is('200', 'Status is 200')
#  ->content_is('not implemented...', 'ok not implemented...yet');

done_testing();

