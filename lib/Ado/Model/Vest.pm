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
    my $self = shift->new(@_);

    #guess the talk by subject or subject_message_id
    my $started_talk =
      $self->dbix->query("SELECT id FROM vest WHERE (subject=? OR id=?) AND subject!='' ",
        $self->{subject}, $self->subject_message_id)->hash;
    if ($started_talk && $started_talk->{id}) {    #existing talk
        $self->subject_message_id($started_talk->{id});
        $self->subject('');
    }
    else {
        $self->subject_message_id(0);              # new talk
    }
    $self->insert;
    return $self;
}
sub QUOTE_IDENTIFIERS {0}

#__PACKAGE__->BUILD;#build accessors during load

1;

=pod

=encoding utf8

=head1 NAME

A class for TABLE vest in schema main

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


=head1 GENERATOR

L<DBIx::Simple::Class::Schema>

=head1 SEE ALSO


L<Ado::Model>, L<DBIx::Simple::Class>, L<DBIx::Simple::Class::Schema>

=cut

