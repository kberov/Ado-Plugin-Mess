package Ado::Model::Vest;    #A table/row class
use 5.010001;
use strict;
use warnings;
use utf8;
use parent qw(Ado::Model);

sub is_base_class { return 0 }
my $TABLE_NAME = 'vest';

sub TABLE       { return $TABLE_NAME }
sub PRIMARY_KEY { return 'id' }
my $COLUMNS = [
    'id', 'from_uid', 'to_uid', 'to_guid', 'subject', 'subject_message_id', 'tstamp', 'message',
    'message_assets', 'seen'
];

sub COLUMNS { return $COLUMNS }
my $ALIASES = {};

sub ALIASES { return $ALIASES }
my $CHECKS = {
    'to_uid'  => {default => 0, 'allow' => qr/(?^x:^-?\d{1,11}$)/},
    'to_guid' => {default => 0, 'allow' => qr/(?^x:^-?\d{1,11}$)/},
    'tstamp'  => {
        'required' => 1,
        'defined'  => 1,
        'allow'    => qr/(?^x:^-?\d{1,11}$)/
    },
    'subject' => {
        'defined' => 1,
        'allow'   => qr/(?^x:^.{0,255}$)/,
        'default' => ''
    },
    'message_assets' => {'allow' => qr/(?^x:^.{1,}$)/},
    'message'        => {'allow' => qr/(?^x:^.{1,}$)/},
    'from_uid'       => {
        'required' => 1,
        'defined'  => 1,
        'allow'    => qr/(?^x:^-?\d{1,11}$)/
    },
    'subject_message_id' => {
        'required' => 1,
        'defined'  => 1,
        'allow'    => qr/(?^x:^-?\d{1,12}$)/
    },
    'id'   => {'allow' => qr/(?^x:^-?\d{1,}$)/},
    'seen' => {'allow' => qr/^\d$/}
};

sub CHECKS { return $CHECKS }


sub create {
    my ($self, @args) = @_;
    $self = $self->new(@args);
    state $dbh = $self->dbh;
    my $subject = $self->subject;

    #guess the talk by subject or subject_message_id
    state $sth = $dbh->prepare_cached("SELECT id FROM vest WHERE (id=? OR subject=?)");
    my $started_talk =
      $dbh->selectrow_hashref($sth, {}, $self->subject_message_id, $subject || '-');

    if ($started_talk && $started_talk->{id}) {    #existing talk
        $self->subject_message_id($started_talk->{id});
        $self->subject('');
    }
    else {
        $self->subject_message_id(0);              # new talk
        $self->subject(substr($self->message, 0, 30))
          unless $subject;
    }
    $self->insert();
    return $self;
}

# All messages from a talk
sub _MESSAGES_SQL {
    return state $MESSAGES_SQL = __PACKAGE__->SQL('SELECT') . <<"SQL";

      -- include the first message too
      WHERE (subject_message_id = ? OR id = ?)
        AND (
            to_guid IN(SELECT group_id FROM user_group WHERE user_id=?)    
            OR(to_uid =?) OR(from_uid =?)
        )
SQL
}

# Gets user and group names and adds them to the resultset rows.
sub _map_hashes {
    my $hashes = shift;

    #users'/groups names
    state $names     = {};
    state $gravatars = {};
    for my $h (@$hashes) {
        if (!exists $names->{$h->{to_uid}}) {
            my $user = Ado::Model::Users->find($h->{to_uid});
            $h->{to_uid_name} = $names->{$h->{to_uid}} = $user->name;
        }
        else {
            $h->{to_uid_name} = $names->{$h->{to_uid}};
        }
        if (!exists $names->{$h->{from_uid}}) {
            my $user = Ado::Model::Users->find($h->{from_uid});
            $h->{from_uid_name} = $names->{$h->{from_uid}} = $user->name;
            $h->{from_uid_gravatar} = $gravatars->{$h->{from_uid}} =
              Digest::MD5::md5_hex($user->email);
        }
        else {
            $h->{from_uid_name}     = $names->{$h->{from_uid}};
            $h->{from_uid_gravatar} = $gravatars->{$h->{from_uid}};
        }
        if (!exists $names->{$h->{to_guid}}) {
            $h->{to_guid_name} = $names->{$h->{to_guid}} =
              Ado::Model::Groups->find($h->{to_guid})->name;
        }
        else { $h->{to_guid_name} = $names->{$h->{to_guid}}; }
    }
    return $hashes;
}

# Selects messages from a talk within a given range by talk id.
sub by_subject_message_id {
    my ($class, $user, $s_m_id, $limit, $offset) = @_;
    my $uid = $user->id;
    state $SQL = <<"SQL";
    SELECT * FROM (${\ _MESSAGES_SQL } ${\ $class->SQL_LIMIT('?','?') })
    ORDER BY id ASC 
SQL

#warn "$SQL $s_m_id, $s_m_id, $uid, $uid, $uid, $limit, $offset";
    my $hashes =
      $class->dbix->query($SQL, $s_m_id, $s_m_id, $uid, $uid, $uid, $limit, $offset)->hashes;
    return _map_hashes($hashes);
}

# Counts messages in a talk for a user by given subject_message_id
sub count_messages {
    my ($class, $user, $subject_message_id) = @_;
    my $uid = $user->id;
    state $count_SQL = 'SELECT count(id) AS count FROM (' . _MESSAGES_SQL . ') AS messages';
    return $class->dbix->query($count_SQL, $subject_message_id, $subject_message_id, $uid, $uid,
        $uid)->hash->{count};
}

sub talks {
    my ($class, $user, $limit, $offset) = @_;
    my $uid = $user->id;
    state $SQL = _MESSAGES_SQL . ' ORDER BY id DESC ' . $class->SQL_LIMIT('?', '?');
    my $hashes = $class->dbix->query($SQL, 0, 0, $uid, $uid, $uid, $limit, $offset)->hashes;
    return _map_hashes($hashes);
}

__PACKAGE__->QUOTE_IDENTIFIERS(0);

#__PACKAGE__->BUILD;#build accessors during load

1;

=pod

=encoding utf8

=head1 NAME

Ado::Model::Vest - A class for TABLE vest

=head1 SYNOPSIS

    #select messages from a talk
    my $messages =
      Ado::Model::Vest->by_subject_message_id(
        $user, $s_m_id, $limit, $offset)
    #list them
    foreach(@$messages){
    ..
    }
    # create a new message
    Ado::Model::Vest->create(%params, tstamp => time);

Look at L<Ado::Control::Vest> for a wealth of usage examples.

=head1 DESCRIPTION

This class provides methods for manipulating messages and talks.
It uses the table C<vest> as storage.
A message is a record in table C<vest>.
A talk consists of a set of messages, having the same value in column
L</subject_message_id> and one record which column L</id> has the same value.
In other words, the record which L</id> value is referenced by other records in
L</subject_message_id>, is the parent record, that defines a talk.
This is the first message in a talk.  

=head1 COLUMNS

Each column from table C<vest> has an accessor in this class.

=head2 id

The primary key for the message. C<INTEGER PRIMARY KEY AUTOINCREMENT>.

=head2 from_uid

Id of the user who sends the message. C<INT(11) REFERENCES users(id) NOT NULL>.

=head2 to_uid

Id of the user to whom the message is sent. C<INT(11) REFERENCES users(id) DEFAULT 0>.
Can be zero (0) in case the message is sent to the whole group.
This way we can have group talks. 

In case both to_uid and to_guid values are zero,
the sender is talking to him self - Taking Notes. See L</to_guid>.

=head2 to_guid

Id of the group to which the message is sent. 
C<INT(11) REFERENCES groups(id) DEFAULT 0>.
In case the value is zero (0) the message is private. If it has C<to_uid!=0>,
the message can be seen by the user referenced by  C<to_uid>, otherwise only 
the user referenced by C<from_uid> can see the message. 

=head2 subject

Subject (topic) of the talk. C<VARCHAR(255) DEFAULT ''>. 
Only the first message in a talk has a subject.
Every next message has C<subject=''>.

=head2 subject_message_id

Id of the first message in a talk. The first message in a talk has
C<subject_message_id=0>. Eevery next message has C<subject_message_id> equal
to the C<id> of the first message. There can be many conversations in a
group or between two users.

=head2 tstamp

Last modification time. All dates are stored as seconds since the epoch(1970). 
In Perl we use a Time::Piece object to format this value as we wish.

=head2 message

The message it self. C<TEXT>.

=head2 message_assets

File-paths (relative to C<$app-E<gt>home>) of Files attached to this message - TODO.

=head2 permissions 

Can be used in case the message is published as status update and it should be
readable only by certain users.
C<VARCHAR(10) NOT NULL DEFAULT '-rw-r-----'>.

=head2 seen

Incremented by 1 by the client chat application when the message is displayed
on the screen of the user referred by C<to_uid> or by some member of
the group referred by C<to_guid>. C<INTEGER DEFAULT 0>. TODO.


=head1 METHODS

L<Ado::Model::Vest> inherits all methods from L<Ado::Model> and implements
the following new ones.

=head2 by_subject_message_id

Selects messages from a talk within a given range, ordered by talk id descending
and returns an ARRAY reference of HASHES.
Only messages that are viewable by the current user are selected

    my $messages = Ado::Model::Vest->by_subject_message_id(
        $c->user, $subject_message_id, $limit, $offset
    );

=head2 count_messages

Counts messages in a talk for a user by given subject_message_id
Returns an integer.

my $count = Ado::Model::Vest->count_messages($user, $s_m_id);

=head2 create

Creates a new message. Performs a check If there is a talk with C<id> equal to
the  C<subject_message_id> of the message or if the subject of the message is
equal to a talk subject. Depending on the results either creates a new talk or
a new message within a talk. In case the message is part of an existing talk the
C<subject> is set to '';
Returns C<$self>.

=head2 talks

Selects records which contain talk subjects(topics) (C<subject!=''>)
from all messages within a given range, ordered by talk id descending
and returns an ARRAYref of HASHES.
Only messages that are viewable by the current user are selected.

    my $messages = Ado::Model::Vest->talks($c->user, $limit, $offset);

=head1 GENERATOR

This class was initially generated using L<DBIx::Simple::Class::Schema> and later
edited and enriched by the author.

=head1 SEE ALSO


L<Ado::Model>, L<DBIx::Simple::Class>, L<DBIx::Simple::Class::Schema>

=cut

