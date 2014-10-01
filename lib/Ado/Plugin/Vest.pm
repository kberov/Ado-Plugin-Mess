package Ado::Plugin::Vest;
use Mojo::Base qw(Ado::Plugin);
use Mojo::Util qw(decamelize slurp);
File::Spec::Functions->import(qw(catfile));

our $VERSION = '0.02';

sub register {
    my ($self, $app, $conf) = shift->initialise(@_);
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

L<Ado::Plugin::Vest> implements a (not too) naive messaging application.
It can be used as a chat between two users or as commenting widget under some article.
Other uses are also possible. Just create your client (HTML5 or desktop) application and start making Ajax 
or Websocket (TODO) requests.


=head1 SYNOPSIS

  # To enable this plugin after installation add it to etc/ado.conf 
  #"plugins" section *after* DSC plugin.
  plugins => [
    {name => 'charset', config => {charset => 'UTF-8'}},
    {   name   => 'DSC',
        config => {#...
        },
    },
    #...
    {name => 'vest', config => {...}},
    #...
 ],

=head1 ATTRIBUTES

Ado::Plugin::Vest inherits all atributes from L<Ado::Plugin>.

=head1 METHODS

Ado::Plugin::Vest implements the following methods.

=head2 register

Loads routes described in C<etc/plugins/vest.conf>.


=head1 SPONSORS

The original author

=head1 SEE ALSO

L<Ado::Control::Ado::Default>,
L<Ado::Control>, L<Mojolicious::Controller>,
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

