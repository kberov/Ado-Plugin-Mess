#02-restapi.t
use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Mojo::Util;
use List::Util qw(shuffle);


my $OE  = $^O =~ /win/i ? 'cp866' : 'utf8';
my $t1  = Test::Mojo->new('Ado');
my $app = $t1->app;
my $dbh = $app->dbix->dbh;
ok($dbh->do('DROP TABLE IF EXISTS vest'), "Table vest was dropped.");

# Remove generic routes (for this test only) so newly generated routes can match.
$app->routes->find('controller')->remove();
$app->routes->find('controlleraction')->remove();
$app->routes->find('controlleractionid')->remove();

isa_ok($app->plugin('vest'), 'Ado::Plugin::Vest');
my $vest_base_url = $app->config('Ado::Plugin::Vest')->{vest_base_url};

#$t1 login first
subtest 't1_login' => sub {
    $t1->get_ok('/login/ado')->status_is(200)->content_like(qr/id="login_form"/);

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

# $t2 login - use the same running app instance
my $t2 = Test::Mojo->new($app);
subtest 't2_login' => sub {
    $t2->get_ok('/login/ado')->status_is(200)->content_like(qr/id="login_form"/);

    #get the csrf fields
    my $form       = $t2->tx->res->dom->at('#login_form');
    my $csrf_token = $form->at('[name="csrf_token"]')->{value};
    my $form_hash  = {
        _method        => 'login/ado',
        login_name     => 'test2',
        login_password => '',
        csrf_token     => $csrf_token,
        digest         => Mojo::Util::sha1_hex($csrf_token . Mojo::Util::sha1_hex('test2test2')),
    };
    $t2->post_ok('/login' => {} => form => $form_hash)->status_is(302);
};


#reload
#{route => '/$vest_base_url', via => ['GET'],  to => 'vest#list',}
#no format

=pod
$t1->get_ok("$vest_base_url/list")->status_is('415', '415 - Unsupported Media Type ')
  ->content_type_is('text/html;charset=UTF-8')->header_like('Content-Location' => qr|\.json$|x)
  ->content_like(qr|\.json</a>\!|x);

#with format
$t1->get_ok("$vest_base_url/list.json")->status_is('200', 'Status is 200')
  ->content_type_is('application/json')->json_has('/data')->json_has('/links')
  ->json_is('/links/0/rel' => 'self', '/links/0/rel is self')
  ->json_like('/links/0/href' => qr'\.json\?limit=20\&offset=0')
  ->json_is('/links/1' => undef, '/links/1 is not present')
  ->json_is('/data'    => [],    '/data is empty');
=cut

#Play with several messages.
#{route => '/вест', via => ['POST'], to => 'vest#add',},
$t1->post_ok(
    $vest_base_url,
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
    }
  );

# fixed bug - missing "required" validation on second POST
$t1->post_ok(
    $vest_base_url,
    form => {
        from_uid           => 3,
        subject_message_id => 0,

        #to_uid   => 4,
        subject => 'Какъв приятен разговор!',
        message => 'Здравей, Приятел!'
    }
)->status_is('400', 'Status is 400');

$t1->post_ok(
    $vest_base_url,
    form => {
        from_uid           => 3,
        subject_message_id => 0,
        to_uid             => 'не число',
        subject            => 'Какъв приятен разговор!',
        message            => 'Здравей, Приятел!'
    }
  )->status_is('400', 'Status is 400')->json_is('/message/to_uid/0/', 'like')
  ->content_like(qr/"message"\:\{"to_uid"\:\["like"/x, 'erros ok: to_uid is not alike ');

my $s_m_id = 0;
for my $id (1, 3, 5) {
    $t1->post_ok(
        $vest_base_url,
        form => {
            from_uid => 3,
            to_uid   => 4,
            subject  => 'разговор' . time,

            # $s_m_id==0 =>new talk
            subject_message_id => $s_m_id,
            message            => "Здравей, Приятел! $id"
        }
      )->status_is('201', 'ok 201 - Created')->header_like(Location => qr/\/id\/\d+/)
      ->content_is('');
    my $location = $t1->tx->res->headers->header('Location');
    ($s_m_id) = $location =~ qr/\/id\/(\d+)/ unless $s_m_id;

=pod
{   route  => '/вест/:id',
    params => {id => qr/\d+/},
    via    => ['GET'],
    to     => 'messshow',
},
=cut

    $t2->get_ok("$vest_base_url/$id.json")
      ->status_is('200', "$vest_base_url/$id.json" . ' Status is 200')
      ->json_is('/data/message', "Здравей, Приятел! $id", "ok created $id");
    my $next = $id + 1;


    #reply from a friend
    $t2->post_ok(
        $vest_base_url,
        form => {
            from_uid           => 4,
            to_uid             => 3,
            subject            => 'Какъв приятен разговор',
            subject_message_id => $s_m_id,
            message            => "Oh, salut mon ami! $next"
        }
      )->status_is('201', 'ok 201 - Created')->header_like(Location => qr"/id/$next")
      ->content_is('');

}    #end for my $id (1, 3, 5)

=pod
{   route  => '/вест/:id',
    params => {id => qr/\d+/},
    via    => ['PUT'],
    to     => 'messupdate',
},
=cut

$t1->put_ok(
    "$vest_base_url/5",
    form => {
        to_uid             => 4,
        from_uid           => 3,
        subject            => 'Какъв приятен разговор',
        subject_message_id => 1,
        message            => "Let's speak some English."
    }
)->status_is('204', 'Status is 204')->content_is('', 'ok updated id 5');

$t1->get_ok("$vest_base_url/5.json")->status_is('200', 'Status is 200')
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

$t1->delete_ok("$vest_base_url/1")->status_is('200', 'Status is 200')
  ->content_is('not implemented...', 'ok not implemented...yet');
ok($dbh->do('DROP TABLE IF EXISTS vest'), "Table vest was dropped.");

# Reload plugin to recreate the table
$app->plugin('vest');

#Some hardcodded business logic
my @message = qw(
  oтгде ще можеш да добиеш тия знания ако не от ония които писаха историята на
  този свят и които при все че не са живели дълго време защото никому не се
  дарява дълъг живот за дълго време оставиха писания за тия неща. Сами от себе
  си да се научим не можем защото кратки са дните на нашия живот на земята.
);

# Setup: Add some talks and messages in them.
# Visible by both users test1(3), and test2(4)
my @talk_x = (
    {   from_uid           => 3,
        to_uid             => 4,
        subject            => 'разговор',
        subject_message_id => 0,
        message            => "Здравей, Приятел!"
    },
    {   from_uid           => 4,
        to_uid             => 3,
        subject            => 'разговор' . time,
        subject_message_id => 1,
        message            => "Здрасти!"
    },
    {   from_uid           => 4,
        to_uid             => 3,
        subject            => 'разговор' . time,
        subject_message_id => 1,
        message            => "Как си?"
    },
    {   from_uid           => 3,
        to_uid             => 4,
        subject            => 'разговор' . time,
        subject_message_id => 1,
        message            => "Благодаря, добре. А ти?"
    }
);

# Visible only by test1(wrote some notes for him self).
my @talk_y    = ();
my $talk_y_id = scalar(@talk_x) + 1;
for ($talk_y_id .. 25) {
    push @talk_y,
      { from_uid           => 3,
        to_uid             => 0,
        subject            => ($talk_y_id == $_ ? 'topic Y' : ''),
        subject_message_id => ($talk_y_id == $_ ? 0 : $talk_y_id),
        message => ucfirst(join(' ', shuffle(@message)) . '.')
      };
}

# Visible only by test1 and admin (wrote some messages to admin).
my @talk_z    = ();
my $talk_z_id = scalar(@talk_y) + scalar(@talk_x) + 1;
for ($talk_z_id .. 40) {
    push @talk_z,
      { from_uid           => 3,
        to_uid             => 0,
        subject            => ($talk_z_id == $_ ? 'topic Z' : ''),
        subject_message_id => ($talk_z_id == $_ ? 0 : $talk_z_id),
        message => ucfirst(join(' ', shuffle(@message[0 .. int(rand(@message))])) . '.')
      };
}

# Insert the messages
note('Creating ' . (@talk_x + @talk_y + @talk_z) . ' messages in 3 talks.');
my $time = time;
Ado::Model::Vest->create(%$_, tstamp => $time) for (@talk_x, @talk_y, @talk_z);

# Listing talks of the current user - usually in the left sidebar
$t1->get_ok("$vest_base_url/talks.json")->status_is('200', 'Status is 200')
  ->content_type_is('application/json')->json_has('/data')
  ->json_is('/data/2/id' => 1, 'my first talk')->json_is('/data/1/id' => 5, 'my second talk')
  ->json_is('/data/0/id' => 26, 'my third talk');
$t2->get_ok("$vest_base_url/talks.json")->json_is('/data/0/id' => 1, 'my first talk')
  ->json_is('/data/1/id' => undef, 'no second talk')
  ->json_is('/data/2/id' => undef, 'no third talk');

# Listing messages from a talk for the current user
$t1->get_ok("$vest_base_url/messages/1.json")->status_is('200', 'Status is 200')
  ->content_type_is('application/json')->json_has('/data')
  ->json_is('/links/1'        => undef,              '/links/1 is not present')
  ->json_is('/data/0/id'      => 1,                  '/data is sorted properly')
  ->json_is('/data/3/id'      => 4,                  '/data is sorted properly')
  ->json_is('/data/0/subject' => 'разговор', '/data/0/subject is ok');

$t1->get_ok("$vest_base_url/messages/5.json?limit=10")->json_is(
    '/links/1' => {
        "rel"  => "next",
        "href" => "$vest_base_url/messages/5.json?limit=10&offset=21"
    },
    '/links/1 is present'
)->json_is('/data/9/id' => 25, '/data is sorted properly');

#Make some more talks for UI tests
note('Creating more messages in many talks. This may take a while...');

for my $talk (14 .. 25) {
    my $to_uid   = 4;                      #Test 2
    my $from_uid = 3;                      #Test 1
    my @from_to  = ($from_uid, $to_uid);
    my $subject     = "Разговор " . ucfirst(join(' ', shuffle(@message[0 .. 6])) . '.');
    my $lastmessage = 2;
    for my $message_id (1 .. ($talk >= 24 ? $lastmessage * 15 : $lastmessage)) {
        my $time     = time;
        my $from_uid = $from_to[int(rand(@from_to))];
        my $message  = ucfirst(join(' ', shuffle(@message[0 .. int(rand(@message))])) . '.');
        Ado::Model::Vest->create(
            from_uid => $from_uid,
            to_uid   => $from_uid == $from_to[0] ? $from_to[1] : $from_to[0],

            # Using the feature of create method to attach messages with
            # the same subject to the same parent/topic.
            subject            => $subject,
            subject_message_id => 0,                                        #required,defined
            message            => $message_id == 1 ? $subject : $message,
            tstamp             => $time
        );
    }

    #LIFO
    $t1->get_ok($vest_base_url)
      ->text_like('#talks li:first-child a' => qr/$subject/, 'last talk subject on top')
      ->element_exists('nav#vestbar')->element_exists('div.ui.dropdown.item')
      ->element_exists('template#message_template')
      ->element_exists("form#message_form[action\$=\"$vest_base_url\"]")
      ->element_exists('h5#talk_topic')->element_exists('div#messages div.ui.list');
    $t2->get_ok("$vest_base_url.json")->content_type_is('application/json')
      ->json_is('/user/id' => $to_uid)->json_is('/routes/0/params' => undef)
      ->json_is('/talks/0/to_guid' => 0)->json_is('/contacts/0/id' => $from_uid)
      ->json_is('/talks/0/subject' => $subject);
}


#HTML UI
$t1->get_ok("$vest_base_url")->element_exists('main.ui.container', 'main.ui.container');

done_testing();

