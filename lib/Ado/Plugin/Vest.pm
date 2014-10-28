package Ado::Plugin::Vest;
use Mojo::Base qw(Ado::Plugin);
use Mojo::Util qw(decamelize slurp);
File::Spec::Functions->import(qw(catfile));

our $VERSION = '0.06';

sub register {
    my ($self, $app, $conf) = shift->initialise(@_);

    #make plugin configuration available for later in the app
    $app->config(__PACKAGE__, $conf);
    $app->defaults('vest_base_url' => $$conf{vest_base_url});
    $self->_create_table($app, $conf);
    $self->_add_data($app, $conf);

    return $self;
}

sub _add_data {
    my ($self, $app, $conf) = @_;
    return unless $conf->{vest_data_sql_file};

    return $self->_do_sql_file($app->dbix->dbh, $conf->{vest_data_sql_file});
}

sub _create_table {
    my ($self, $app, $conf) = @_;
    return unless $conf->{vest_schema_sql_file};
    my $dbh = $app->dbix->dbh;
    my $table =
      $dbh->table_info(undef, undef, 'vest', "'TABLE'")->fetchall_arrayref({});
    return if @$table;
    return $self->_do_sql_file($dbh, $conf->{vest_schema_sql_file});
}

sub _do_sql_file {
    my ($self, $dbh, $sql_file) = @_;
    $self->app->log->debug('_do_sql_file:' . $sql_file)
      if $Ado::Control::DEV_MODE;

    my $SQL = slurp(catfile($self->config_dir, $sql_file));

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
    return;
}

1;

=pod

=encoding utf8

=head1 NAME

Ado::Plugin::Vest - Messaging services for an Ado system!

=head1 DESCRIPTION

L<Ado::Plugin::Vest> implements a (not too) naive messaging service.
It can be used as a chat between two users or as commenting widget under some article.
Other uses are also possible. Just create your client (HTML5 or desktop) application and start making Ajax (or Websocket - TODO) requests.
Currently a HTTP based chat application is being implemented as a proof of concept.

B<Note> that this distribution is fairly experimental and the author 
gladly accepts proposals enlightenment and inspiration.

=head1 SYNOPSIS

  # 1. To enable this plugin after installation, add it to etc/ado.conf
  #"plugins" section *after* DSC plugin.
  plugins => [
    #...
    'vest',
    #...
 ],
 # 2. Restart Ado
 # 3. Login and go to http://yourdomain/vest

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

