#03-restapi.t
use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use List::Util qw(shuffle);
my $t1  = Test::Mojo->new('Ado');
my $app = $t1->app;
my $dbh = $app->dbix->dbh;
ok($dbh->do('DROP TABLE IF EXISTS vest'), "Table vest was dropped.");

# Remove generic routes (for this test only) so newly generated routes can match.
$app->routes->find('controller')->remove();
$app->routes->find('controlleraction')->remove();
$app->routes->find('controlleractionid')->remove();

# Load plugin
$app->plugin('vest');

my @message = qw(
  oтгде ще можеш да добиеш тия знания ако не от ония които писаха историята на
  този свят и които при все че не са живели дълго време защото никому не се
  дарява дълъг живот за дълго време оставиха писания за тия неща. Сами от себе
  си да се научим не можем защото кратки са дните на нашия живот на земята.
  Затова с четене на старите летописи и с чуждото умение трябва да попълним
  недостатъчността на нашите години за обогатяване на разума.
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
my $time = time;
Ado::Model::Vest->create(%$_, tstamp => $time) for (@talk_x, @talk_y, @talk_z);

#$t1 login first
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

# $t2 login
my $t2 = Test::Mojo->new('Ado');
subtest 't2_login' => sub {
    $t2->get_ok('/login/ado');

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


# Listing talks of the current user - usually in the left sidebar
$t1->get_ok('/вест/talks.json')->status_is('200', 'Status is 200')
  ->content_type_is('application/json')->json_has('/data')
  ->json_is('/data/2/id' => 1, 'my first talk')->json_is('/data/1/id' => 5, 'my second talk')
  ->json_is('/data/0/id' => 26, 'my third talk');
$t2->get_ok('/вест/talks.json')->json_is('/data/0/id' => 1, 'my first talk')
  ->json_is('/data/1/id' => undef, 'no second talk')
  ->json_is('/data/2/id' => undef, 'no third talk');

# Listing messages from a talk for the current user
$t1->get_ok('/вест/messages/1.json')->status_is('200', 'Status is 200')
  ->content_type_is('application/json')->json_has('/data')
  ->json_is('/links/1'        => undef,              '/links/1 is not present')
  ->json_is('/data/0/id'      => 4,                  '/data is sorted properly')
  ->json_is('/data/3/id'      => 1,                  '/data is sorted properly')
  ->json_is('/data/3/subject' => 'разговор', '/data/0/subject is ok');
$t1->get_ok('/вест/messages/5.json?limit=10')->json_is(
    '/links/1' =>
      {"rel" => "next", "href" => "/%D0%B2%D0%B5%D1%81%D1%82/messages/5.json?limit=10&offset=10"},
    '/links/1 is present'
)->json_is('/data/0/id' => 25, '/data is sorted properly');


done_testing;
