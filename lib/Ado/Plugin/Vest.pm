package Ado::Plugin::Vest;
use Mojo::Base qw(Ado::Plugin);
use Mojo::Util qw(decamelize slurp decode);
File::Spec::Functions->import(qw(catfile));

our $VERSION = '0.09';
my $VEST = 'vest';

sub register {
    my ($self, $app, $conf) = shift->initialise(@_);
    $conf->{add_users_to_vest} //= 1;

    #make plugin configuration available for later in the app
    $app->config(__PACKAGE__, $conf);
    $app->defaults('vest_base_url' => $conf->{vest_base_url});
    $self->_create_table($app, $conf);
    $self->_add_data($app, $conf);
    $app->hook(after_user_add => \&_add_user_to_vest);

    return $self;
}

sub _add_data {
    my ($self, $app, $conf) = @_;
    return unless $conf->{vest_data_sql_file};
    return $self->_do_sql_file($app->dbix->dbh, $conf->{vest_data_sql_file});
}

#hook after_user_add
sub _add_user_to_vest {
    my ($c, $user, $raw_data) = @_;
    unless ($user->ingroup($VEST)) {
        my $uid = $user->id;
        my $group = $user->add_to_group(ingroup => $VEST);
        state $vest = Ado::Model::Users->by_login_name($VEST);

        #Create group for contacts
        Ado::Model::Groups->create(
            name        => "vest_contacts_$uid",
            description => "Contacts of user $uid",
            created_by  => $uid,
            changed_by  => $uid,
            disabled    => 0
        );

        #Add $vest to contacts
        $vest->add_to_group(ingroup => "vest_contacts_$uid");

        #Add wellcome message
        Ado::Model::Vest->create(
            from_uid           => $vest->id,
            to_uid             => $user->id,
            subject            => $c->l('Wellcome [_1]!', $user->name),
            subject_message_id => 0,
            message            => $c->l(
                'Wellcome [_1]! Use the Contacts sidebar to find users by name and have a chat.',
                $user->name
            ),
            tstamp => time
        );
        $c->app->log->info("\$user->id $uid added to group '${\ $group->name }'.$/"
              . "Created group vest_contacts_$uid and added $VEST to it.$/"
              . 'Sent wellcome message.');

        return 1;
    }
    return;
}

sub _create_table {
    my ($self, $app, $conf) = @_;
    return unless $conf->{vest_schema_sql_file};
    my $dbh = $app->dbix->dbh;
    my $table =
      $dbh->table_info(undef, undef, $VEST, "'TABLE'")->fetchall_arrayref({});
    return if @$table;
    return $self->_do_sql_file($dbh, $conf->{vest_schema_sql_file});
}

sub _do_sql_file {
    my ($self, $dbh, $sql_file) = @_;
    $self->app->log->debug('_do_sql_file:' . $sql_file)
      if $Ado::Control::DEV_MODE;

    my $SQL = decode('UTF-8', slurp(catfile($self->config_dir, $sql_file)));

    #Remove multi-line comments
    $SQL =~ s|/\*+.+?\*/\s+?||gsmx;
    $self->app->log->debug('$SQL:' . $SQL)
      if $Ado::Control::DEV_MODE;
    local $dbh->{RaiseError} ||= 1;
    my $statement = '';
    eval {
        $dbh->begin_work;
        for my $st (split /;/smx, $SQL) {
            $statement = $st;

            #$self->app->log->debug('$statement:'.$statement);
            $dbh->do($st) if $st =~ /\S+/smx;
        }
        $dbh->commit;
    } || do {
        $dbh->rollback;
        my $e = "\nError in statement:$statement\n$@";
        $self->app->log->error($e);
        Carp::croak($e);
    };
    return 1;
}

1;

=pod

=encoding utf8

=head1 NAME

Ado::Plugin::Vest - Messaging services for an Ado system!

=head1 DESCRIPTION

L<Ado::Plugin::Vest> implements a (not too) naive messaging service
for any web-application based on L<Ado>. It can be used as a chat between
two users, as commenting widget under articles, for showing system messages etc.
Other uses are also possible. You can create your client (HTML5 or desktop)
application and start making Ajax (or Websocket - TODO) requests.
Currently a HTTP based chat application is being implemented as a proof of concept. Go to C<http://yourdomain/vest> and try it.

Combined with the OAuth2 authentication support in Ado this can be a good
foundation for a community or intranet site. Any Google+ or Facebook
user can authenticate and use it for instant messages.

B<Note> that this distribution is fairly experimental and the author 
gladly accepts proposals enlightenment and inspiration.

=head1 SYNOPSIS

=over

=item 1. To enable this plugin after installation, add it to
C<etc/ado.$mode.conf>.

  #"plugins" section *after* DSC plugin.
  plugins => [
    #...
    'vest',
    #...
 ],

=item 2. Restart Ado

=item 3. Login via Google+ or Facebook : http://yourdomain/authorise/$provider

=item 4. Go to http://yourdomain/vest and search for contacts by name.
They should have been signed up already like you.

=item  5. Have some chat...

=back

=head1 ATTRIBUTES

Ado::Plugin::Vest inherits all atributes from L<Ado::Plugin>.

=head1 METHODS

Ado::Plugin::Vest implements the following methods.

=head2 register

Loads routes described in C<etc/plugins/vest.conf>.
Makes the plugin configuration available at
C<$app-E<gt>config('Ado::Plugin::Vest')>.
Creates the table C<vest> if it does not exist yet.
Returns C<$self>.

=head1 HOOKS

L<Ado::Plugin::Vest> registers to only one hook.

=head2 after_user_add

L<Ado::Plugin::Vest> registers to the hook L<Ado::Plugin::Auth/after_user_add>.
It adds the newly registered user to the group 'vest', sends him a wellcome
message and creates a group for user's contacts named
C<vest_contacts_$user-E<gt>id>.
When the user adds someone as a contact he/she is added to this group.

=head1 SEE ALSO

L<Ado::Control::Vest>, L<Ado::Control>, L<Mojolicious::Controller>,
L<Ado::Model::Vest>, L<Ado::Model>,
L<Mojolicious::Guides::Growing/Model_View_Controller>,
L<Mojolicious::Guides::Growing/Controller_class>


=head1 AUTHOR

Красимир Беров (Krasimir Berov)

=head1 COPYRIGHT AND LICENSE

Copyright 2014 Красимир Беров (Krasimir Berov).

This program is free software, you can redistribute it and/or
modify it under the terms of the 
GNU Lesser General Public License v3 (LGPL-3.0).
You may copy, distribute and modify the software provided that 
modifications are open source. However, software that includes 
the license may release under a different license.

See http://opensource.org/licenses/lgpl-3.0.html for more information.

=cut

