package Ado::Control::Mess;
use Mojo::Base 'Ado::Control';
use Time::Piece;

#available messages on this system
sub list {
    my $c = shift;
    $c->require_formats(['json']) || return;
    my $args = Params::Check::check(
        {   limit => {
                allow => sub { $_[0] =~ /^\d+$/ ? 1 : ($_[0] = 20); }
            },
            offset => {
                allow => sub { $_[0] =~ /^\d+$/ ? 1 : defined($_[0] = 0); }
            },
        },
        {   limit  => $c->req->param('limit')  || 20,
            offset => $c->req->param('offset') || 0,
        }
    );

    $c->res->headers->content_range(
        "messages $$args{offset}-${\($$args{limit} + $$args{offset})}/*");
    $c->debug("rendering json only [$$args{limit}, $$args{offset}]");

    #content negotiation
    return $c->respond_to(
        json => $c->list_for_json(
            [$$args{limit}, $$args{offset}],
            [Ado::Model::Mess->select_range($$args{limit}, $$args{offset})]
        )
    );
}

#validation template for action add.
my $add_input_validation_template = {
    to_uid => {
        'required' => 1,
        like       => qr/^\d{1,11}$/
    },
    from_uid => {
        'required' => 1,
        like       => qr/^\d{1,11}$/
    },
    subject => {
        'required' => 1,
        like       => qr/^.{1,255}$/
    },
    subject_message_id => {
        'required' => 1,
        like       => qr/^\d{1,11}$/
    },
    message => {
        'required' => 1,
        like       => qr/^.{1,12345}$/
    },
    message_assets => {
        'required' => 0,
        like       => qr/^.{1,12345}$/
    },
};

#Adds a new message. Status 201 on success, 400 on validate,5xx on faill
sub add {
    my $c      = shift;
    my $result = $c->validate_input($add_input_validation_template);

    #400 Bad Request
    return $c->render(
        status => 400,
        json   => $result->{json}
    ) if $result->{errors};

    my $message =
      Ado::Model::Mess->create(%{$result->{output}}, tstamp => gmtime->epoch);

    #TODO: Remove as much as possible hardcodding
    $c->res->headers->location(
        $c->url_for('messid', id => $message->id, format => 'json'));

    #201 Created
    return $c->render(status => 201, text => '');
}


sub show {
    my ($c)  = @_;
    my $id   = $c->stash('id');
    my $data = Ado::Model::Mess->find($id)->data;

    #404 Not Found
    return $c->render(
        status => 404,
        json   => {
            code    => 404,
            status  => 'error',
            message => "The message with id $id was not found.",
            data    => 'resource_not_found'
        }
    ) unless $data;

    return $c->render(
        status => 200,
        json   => {
            code   => 200,
            status => 'success',
            data   => $data
        }
    );
}

sub update {
    my ($c) = @_;
    my $id   = $c->stash('id');
    my $mess = Ado::Model::Mess->find($id);
    my $data = $mess->data;

    #404 Not Found
    return $c->render(
        status => 404,
        json   => {
            code    => 404,
            status  => 'error',
            message => "The message with id $id was not found.",
            data    => 'resource_not_found'
        }
    ) unless $data;
    $c->debug('$data:',$c->dumper($data));
    #Only the message can be updated. This logic belongs to the model maybe?!?
    my $update_template ={
      message=>$$add_input_validation_template{message},
    };
    
    my $result = $c->validate_input($update_template);

    #400 Bad Request
    return $c->render(
        status => 400,
        json   => $result->{json}
    ) if $result->{errors};


    $mess->save(%{$result->{output}}, tstamp => gmtime->epoch);
    return shift->render(status => 204, text => '');
}

sub disable {
    return shift->render(text => 'not implemented...');
}

1;

=pod

=encoding utf8

=head1 NAME

Ado::Control::Mess - The controller to manage messages. 

=head1 SYNOPSIS

  #in your browser go to
  http://your-host/mess/list
  #or
  http://your-host/mess
  #and
  http://your-host/mess/edit/$id
  #and
  http://your-host/mess/add

=head1 DESCRIPTION

Ado::Control::Mess is the controller class for the end-users' 
Ado messaging system.

=head1 ATTRIBUTES

L<Ado::Control::Mess> inherits all the attributes from 
<Ado::Control> and defines the following ones.

=head1 METHODS/ACTIONS
                     
=head2 list

Displays the messages this system has.
Uses the request parameters C<limit> and C<offset> to display a range of items
starting at C<offset> and ending at C<offset>+C<limit>.
This method serves the resource C</mess/list.json>.
If other format is requested returns status 415 with C<Content-location> header
pointing to the proper URI.
See L<http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.4.16> and
L<http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.14>.

=head2 add

Adds a message to the table mess. 
Renders no content with status 201 and a C<Location> header 
pointing to the new resourse so the user agent can fetch it eventually.
See http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.2

=head2 show

Displays a message. Not implemented yet

=head2 update

Updates a message. Not implemented yet

=head2 disable

Disables a message . Not implemented yet

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

