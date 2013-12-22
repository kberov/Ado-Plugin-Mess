package Ado::Plugin::Mess;
use Mojo::Base qw(Ado::Plugin);

our $VERSION = '0.01';

sub register {
    my ($self, $app, $conf) = @_;
    $self->app($app);    #!Needed in $self->config!

    #Merge passed configuration with configuration
    #from  etc/ado.conf and etc/plugins/routes.conf
    $conf = {%{$self->config}, %{$conf ? $conf : {}}};
    $app->log->debug('Plugin ' . $self->name . ' configuration:' . $app->dumper($conf));

    # My magic here! :)
    push @{$app->routes->namespaces}, @{$conf->{namespaces}}
      if @{$conf->{namespaces} || []};
    $app->load_routes($conf->{routes});
    return $self;
}

1;

=pod

=encoding utf8

=head1 NAME

Ado::Plugin::Mess - Messaging services for an Ado system!

=head1 DESCRIPTION

TODO                                                        


=head1 SYNOPSIS

  # To use this plugin add it to etc/ado.conf 
  #plugins section after DSC plugin.
  plugins => [
    {name => 'charset', config => {charset => 'UTF-8'}},
    {   name   => 'DSC',
        config => {#...
        },
    },
    #...
    {name => 'mess', config => {}},
    #...
 ],

=head1 ATTRIBUTES

Ado::Plugin::Mess inherits all atributes from L<Ado::Plugin>.

=head1 METHODS

Ado::Plugin::Mess implements the following methods.

=head2 register

Loads routes described in C<etc/plugins/mess.conf>.


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

Copyright 2013 Красимир Беров (Krasimir Berov).

This program is free software, you can redistribute it and/or
modify it under the terms of the 
GNU Lesser General Public License v3 (LGPL-3.0).
You may copy, distribute and modify the software provided that 
modifications are open source. However, software that includes 
the license may release under a different license.

See http://opensource.org/licenses/lgpl-3.0.html for more information.

=cut

