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
    'id',      'from_uid',           'to_uid', 'to_guid',
    'subject', 'subject_message_id', 'tstamp', 'message',
    'message_assets'
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
        'allow'    => qr/(?^x:^-?\d{1,}$)/
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
    'id' => {'allow' => qr/(?^x:^-?\d{1,}$)/}
};

sub CHECKS { return $CHECKS }


sub create {
    my ($self, @args) = @_;
    $self = $self->new(@args);
    state $dbh = $self->dbh;

    #guess the talk by subject or subject_message_id
    state $sth =
      $dbh->prepare_cached("SELECT id FROM vest WHERE (subject=? OR id=?) AND subject != '' ");
    my $started_talk =
      $dbh->selectrow_hashref($sth, {}, $self->subject, $self->subject_message_id);

    if ($started_talk && $started_talk->{id}) {    #existing talk
        $self->subject_message_id($started_talk->{id});
        $self->subject('');
    }
    else {
        $self->subject_message_id(0);              # new talk
    }
    $self->insert();
    return $self;
}

sub _MESSAGES_SQL {
    return state $MESSAGES_SQL = __PACKAGE__->SQL('SELECT') . <<"SQL";
     WHERE subject_message_id = ? 
        AND (
            to_guid IN(SELECT group_id FROM user_group WHERE user_id=?)
            OR(to_uid =?) OR(from_uid =?)
        )
SQL
}
# Selects messages from a talk within a given range by talk id.
sub by_subject_message_id {
    my ($class, $user, $subject_message_id, $limit, $offset) = @_;
    my $uid = $user->id;
    state $SQL = <<"SQL";
    ${\ _MESSAGES_SQL }
    UNION
    ${\ __PACKAGE__->SQL('SELECT') }
    WHERE id = ?  ORDER BY id DESC
    ${\ __PACKAGE__->SQL_LIMIT('?','?') }
SQL

    return $class->dbix->query($SQL, $subject_message_id, $uid, $uid, $uid, $subject_message_id,
        $limit, $offset)->objects($class);
}

sub talks {
    my ($class, $user, $limit, $offset) = @_;
    my $uid = $user->id;
    state $SQL = _MESSAGES_SQL . ' ORDER BY id DESC ' . $class->SQL_LIMIT('?', '?');
    return $class->dbix->query($SQL, 0, $uid, $uid, $uid, $limit, $offset)->objects($class);
}

__PACKAGE__->QUOTE_IDENTIFIERS(0);

#__PACKAGE__->BUILD;#build accessors during load

1;

=pod

=encoding utf8

=head1 NAME

Ado::Model::Vest - A class for TABLE vest in schema main

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COLUMNS

Each column from table C<vest> has an accessor in this class.

=head2 id

=head2 from_uid

=head2 to_uid

=head2 to_guid

=head2 subject

=head2 subject_message_id

=head2 tstamp

=head2 message

=head2 message_assets

=head1 METHODS

=head2 create

=head1 METHODS

L<Ado::Model::Vest> inherits all methods from L<Ado::Model> 
and implements the following new ones.

=head2 by_subject_message_id

Selects messages from a talk within a given range, ordered by talk id descending
and returns a list of Ado::Model::Vest instances.
only messages that are viewable by the current user are selected

    my @messages = Ado::Model::Vest->by_subject_message_id(
        $c->user, $subject_message_id, $limit, $offset
    );

=head2 talks

Selects records which contain talk subjects(topics) from all messages 
within a given range, ordered by talk id descending
and returns a list of Ado::Model::Vest instances.
only messages that are viewable by the current user are selected.

    my @messages = Ado::Model::Vest->talks($c->user, $limit, $offset);

=head1 GENERATOR

L<DBIx::Simple::Class::Schema>

=head1 SEE ALSO


L<Ado::Model>, L<DBIx::Simple::Class>, L<DBIx::Simple::Class::Schema>

=cut

