package Ado::Plugin::Vest;
use Mojo::Base qw(Ado::Plugin);
use Mojo::Util qw(decamelize slurp);
File::Spec::Functions->import(qw(catfile));

our $VERSION = '0.03';

sub register {
    my ($self, $app, $conf) = shift->initialise(@_);

    #make plugin configuration available for later in the app
    $app->config(__PACKAGE__, $conf);
    $app->defaults('vest_base_url' => $$conf{vest_base_url});
    $self->_create_table($app, $conf);
    return $self;
}

sub _create_table {
    my ($self, $app, $conf) = @_;
    return unless $conf->{vest_schema_sql_file};
    my $dbix = $app->dbix;
    my $table =
      $dbix->dbh->table_info(undef, undef, 'vest', "'TABLE'")->fetchall_arrayref({});
    return if @$table;

    #Always execute this file because we may have table changes
    my $sql_file = catfile($self->config_dir, $conf->{vest_schema_sql_file});
    my $SQL = slurp($sql_file);

    #Remove multiline comments
    $SQL =~ s|/\*.+\*/||gsmx;
    for my $statement (split /;/, $SQL) {
        $dbix->dbh->do($statement) if $statement =~ /\S+/;
    }
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

