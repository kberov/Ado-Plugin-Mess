#02-restapi.t
use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('Ado');
my $app = $t->app;
isa_ok($app->plugin('vest'), 'Ado::Plugin::Vest');
my $dbh = $app->dbix->dbh;

#make sure the vest table is empty
ok($dbh->do('DROP TABLE IF EXISTS vest'), "Table vest was dropped.");

#reload
#{route => '/вест', via => ['GET'],  to => 'vest#list',}
#no format
$t->get_ok('/вест')->status_is('415', '415 - Unsupported Media Type ')
  ->content_type_is('text/html;charset=UTF-8')->header_like(
    'Content-Location' => qr|http\://localhost\:\d+/вест.json|x,
    'Content-Location points to /вест.json'
  )->content_like(qr|http://localhost:\d+/вест.json</a>\!|x, 'Error page points to /вест.json');
$t->get_ok('/вест/list')->status_is('404', '404 Not Found');

#with format
$t->get_ok('/вест.json')->status_is('200', 'Status is 200')->content_type_is('application/json')
  ->json_has('/data')->json_has('/links')
  ->json_is('/links/0/rel' => 'self', '/links/0/rel is self')->json_is(
    '/links/0/href' => '/вест.json?limit=20&offset=0',
    '/links/0/href is /вест.json?limit=20&offset=0'
  )->json_is('/links/1' => undef, '/links/2 is not present')

  ->json_is('/links/2' => undef, '/links/2 is not present')
  ->json_is('/data'    => [],    '/data is empty')->json_is(
    {   links => [
            {   rel  => 'self',
                href => '/вест.json?limit=20&offset=0',
            }
        ],
        data => []
    }
  );

#Play with several messages.
#{route => '/вест', via => ['POST'], to => 'vest#add',},
$t->post_ok(
    '/вест',
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
$t->post_ok(
    '/вест',
    form => {
        from_uid           => 3,
        subject_message_id => 0,
        to_uid             => 'не число',
        subject            => 'Какъв приятен разговор!',
        message            => 'Здравей, Приятел!'
    }
  )->status_is('400', 'Status is 400')
  ->content_like(qr/"message"\:\{"to_uid"\:\["like"/x, 'erros ok: to_uid is not alike ');

for my $id (1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21) {
    $t->post_ok(
        '/вест',
        form => {
            from_uid           => 3,
            to_uid             => 4,
            subject            => 'Какъв приятен разговор',
            subject_message_id => ($id == 1 ? 0 : 1),                             #same talk
            message            => "Здравей, Приятел! $id"
        }
      )->status_is('201', 'ok 201 - Created')->header_is(Location => "/вест/$id.json")
      ->content_is('');

=pod
{   route  => '/вест/:id',
    params => {id => qr/\d+/},
    via    => ['GET'],
    to     => 'messshow',
},
=cut

    $t->get_ok("/вест/$id.json")->status_is('200', 'Status is 200')
      ->json_is('/data/message', "Здравей, Приятел! $id", "ok created $id");
    my $next = $id + 1;

    #reply from a friend
    $t->post_ok(
        '/вест',
        form => {
            to_uid             => 4,
            from_uid           => 3,
            subject            => 'Какъв приятен разговор',
            subject_message_id => 1,
            message            => "Oh, salut mon ami! $next"
        }
      )->status_is('201', 'ok 201 - Created')->header_is(Location => "/вест/$next.json")
      ->content_is('');

}    # end for my $id

=pod
{   route  => '/вест/:id',
    params => {id => qr/\d+/},
    via    => ['PUT'],
    to     => 'messupdate',
},
=cut

$t->put_ok(
    '/вест/5',
    form => {
        to_uid             => 4,
        from_uid           => 3,
        subject            => 'Какъв приятен разговор',
        subject_message_id => 1,
        message            => "Let's speak some English."
    }
)->status_is('204', 'Status is 204')->content_is('', 'ok updated /вест/5.json');

$t->get_ok('/вест/5.json')->status_is('200', 'Status is 200')
  ->json_is('/data/message',  "Let's speak some English.", 'ok message 5 is updated')
  ->json_is('/data/to_uid',   4,                           'ok message 5 to_uid is unchanged')
  ->json_is('/data/from_uid', 3,                           'ok message 5 from_uid is unchanged')
  ->json_is(    #becuse it belongs to a talk with id 1
    '/data/subject', '', 'ok message 5 subject is empty'
  )->json_is('/data/subject_message_id', 1, 'ok message 5 subject_message_id is unchanged');

#=pod
#{   route  => '/вест/:id',
#    params => {id => qr/\d+/},
#    via    => ['DELETE'],
#    to     => 'vest#disable',
#},
#=cut

#$t->delete_ok('/вест/' . int(rand($messages)))
#  ->status_is('200', 'Status is 200')
#  ->content_is('not implemented...', 'ok not implemented...yet');

done_testing();

