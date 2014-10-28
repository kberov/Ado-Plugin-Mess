package Ado::Control::Vest;
use Mojo::Base 'Ado::Control';
use Time::Piece;

my $list_args_checks = {
    limit => {
        allow => sub { $_[0] =~ /^\d+$/ ? 1 : ($_[0] = 20); }
    },
    offset => {
        allow => sub { $_[0] =~ /^\d+$/ ? 1 : defined($_[0] = 0); }
    },
};

#available messages on this system - disabled
sub list {
    my $c = shift;
    $c->require_formats('json') || return;
    my $args = Params::Check::check(
        $list_args_checks,
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
            [Ado::Model::Vest->select_range($$args{limit}, $$args{offset})]
        )
    );
}

#Lists last 20 messages from a talk of the current user (by subject_message_id)
sub list_messages {
    my ($c) = @_;
    $c->require_formats('json') || return;

    my $s_m_id = $c->stash('id');
    $s_m_id || return $c->render(
        status => 400,
        json   => {
            'code'    => 400,
            'data'    => 'validate_input',
            'message' => {'id' => ['required'],},
            'status'  => 'error'
        }
    );
    my $user = $c->user;

    # Count the messages in a talk
    my $count = Ado::Model::Vest->count_messages($user, $s_m_id);
    my $limit = ($c->req->param('limit') || 20);
    my $offset = $c->req->param('offset') || 0;

    # Default to last 20 messages (including first message)
    $offset = $offset > 0 ? $offset : ($limit > $count ? $offset : $count - $limit);
    my $args = Params::Check::check(
        $list_args_checks,
        {   limit  => $limit,
            offset => $offset,
        }
    );
    my $messages =
      Ado::Model::Vest->by_subject_message_id($user, $s_m_id, $$args{limit}, $$args{offset});
    $c->res->headers->content_range(
        "messages $$args{offset}-${\($$args{limit} + $$args{offset})}/*");
    $c->debug("rendering json only [$$args{limit}, $$args{offset}]");

    #content negotiation (json only for now)
    return $c->respond_to(json => $c->list_for_json([$$args{limit}, $$args{offset}], $messages));

}

sub list_talks {
    my ($c) = @_;
    $c->require_formats('json') || return;

    my $args = Params::Check::check(
        $list_args_checks,
        {   limit  => $c->req->param('limit')  || 20,
            offset => $c->req->param('offset') || 0,
        }
    );
    my $talks = Ado::Model::Vest->talks($c->user, $$args{limit}, $$args{offset});
    $c->res->headers->content_range(
        "messages $$args{offset}-${\($$args{limit} + $$args{offset})}/*");
    $c->debug("rendering json only [$$args{limit}, $$args{offset}]");

    #content negotiation (json only for now)
    return $c->respond_to(json => $c->list_for_json([$$args{limit}, $$args{offset}], $talks));
}

#validation template for action add.
my $add_input_validation_template = {
    from_uid => {
        'required' => 1,
        like       => qr/^\d{1,11}$/
    },
    to_uid => {
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
sub create {
    my $c      = shift;
    my $result = $c->validate_input($add_input_validation_template);

    #$c->debug('$add_input_validation_template:' . $c->dumper($add_input_validation_template));
    #$c->debug('$result:' . $c->dumper($result));

    #400 Bad Request
    return $c->render(
        status => $result->{json}{code},
        json   => $result->{json}
    ) if $result->{errors};

    my $message =
      eval { Ado::Model::Vest->create(%{$result->{output}}, tstamp => time) };
    if ($message) {

        # May be?
        # $c->render(
        #     status => 200,
        #     json   => {
        #         code   => 200,
        #         status => 'success',
        #         data   => $message->data
        #     }
        # );
        # Or just 201 Created?
        $c->res->headers->location(
            $c->url_for('/' . $c->current_route . '/id/' . $message->id => format => 'json'));
        return $c->render(status => 201, text => '');
    }
    else {
        my $err_data = 'Error in POST ' . $c->current_route;
        $c->app->log->error($err_data . ': ' . $@);
        return $c->render(
            status => 500,
            json   => {
                code    => 500,
                status  => 'error',
                message => 'The message could not be created on the server. '
                  . 'The administrator is informed about the error.',
                data => ($c->app->mode eq 'development' ? $@ : $err_data)
            }
        );
    }
    return;
}


sub show {
    my ($c) = @_;
    $c->require_formats('json') || return;

    my $id   = $c->stash('id');
    my $data = Ado::Model::Vest->find($id)->data;

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
    my ($c)  = @_;
    my $id   = $c->stash('id');
    my $vest = Ado::Model::Vest->find($id);
    my $data = $vest->data;

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
    $c->debug('$data:', $c->dumper($data));

    #Only the message can be updated. This logic belongs to the model maybe?!?
    my $update_template = {message => $$add_input_validation_template{message},};

    my $result = $c->validate_input($update_template);

    #400 Bad Request
    return $c->render(
        status => 400,
        json   => $result->{json}
    ) if $result->{errors};


    $vest->save(%{$result->{output}}, tstamp => time);
    return shift->render(status => 204, text => '');
}

sub disable {
    return shift->render(text => 'not implemented...');
}

sub screen {
    my ($c) = @_;
    $c->require_formats('html', 'json') || return;
    my $user   = $c->user;
    my $routes = [
        map {
            +{  authz       => $_->{over},
                description => $_->{description},
                methods     => $_->{via},
                params      => $_->{params},
                url         => $_->{route},
              }
        } @{$c->app->config('Ado::Plugin::Vest')->{routes}}
    ];

    my $to_json = {
        user => {%{$user->data}, name => $user->name},
        talks => Ado::Model::Vest->talks($user, int($c->param('limit') || 20), 0),
        contacts => [Ado::Model::Users->by_group_name('vest_contacts_for_' . $user->login_name)],
        routes   => $routes,
    };

    $c->respond_to(
        json => {json => $to_json},
        html => $to_json,
    );
    return;
}

1;

=pod

=encoding utf8

=head1 NAME

Ado::Control::Vest - The controller to manage messages. 

=head1 SYNOPSIS

  #in your browser go to
  http://your-host/vest/list
  #or
  http://your-host/vest
  #and
  http://your-host/vest/edit/$id
  #and
  http://your-host/vest/add

=head1 DESCRIPTION

Ado::Control::Vest is the controller class for the end-users'
Ado messaging system.

=head1 ATTRIBUTES

L<Ado::Control::Vest> inherits all the attributes from L<Ado::Control>.

=head1 METHODS

L<Ado::Control::Vest> inherits all methods from L<Ado::Control> and implements
the following new ones. These methods are mapped to actions.
See C<etc/plugins/vest.conf>.

=head2 create

Creates a new message.
Renders no content with status 201 and a C<Location> header 
pointing to the new resource so the user agent can fetch it eventually.
See L<http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.2>
and L<Ado::Model::Vest/create>.

=head2 list

Displays the messages this system has.
Uses the request parameters C<limit> and C<offset> to display a range of items
starting at C<offset> and ending at C<offset>+C<limit>.
This method serves the resource C</вест/list.json>.
If other format is requested returns status 415 with C<Content-location> header
pointing to the proper URI.
See L<http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.4.16> and
L<http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.14>.

=head2 list_messages

Lists messages from a talk. Renders JSON.
Accepts parameters C<limit> (20 by default) and C<offset> (0). 
If offset is not passed, lists last (19+first message) messages.
THe first item in the list is the talk topic.


=head2 screen

This is the default action, which is executed when
C<$c-E<gt>app-E<gt>config('Ado::Plugin::Vest')-E<gt>{vest_base_url}> is accessed. 
Supported formats are "json" and "html".
One should all the information to create the GUI for a fully functional client application
by only requesting C<http://example.com/vest.json>.

=head2 list_talks

Renders JSON containing the last talks for a user.
Accepts parameters C<limit> (20 by default) and C<offset> (0). 

=head2 show

Displays a message. Not implemented yet

=head2 update

Updates a message. Not implemented yet

=head2 disable

Disables a message . Not implemented yet

=head1 SPONSORS

The original author

=head1 SEE ALSO

L<Ado::Plugin::Vest>,
L<Ado::Control::Ado::Default>,
L<Ado::Control>, L<Mojolicious::Controller>,
L<Mojolicious::Guides::Growing/Model_View_Controller>,
L<Mojolicious::Guides::Growing/Controller_class>


=head1 AUTHOR

Красимир Беров (Krasimir Berov)

=head1 COPYRIGHT AND LICENSE

Copyright 2013-2014 Красимир Беров (Krasimir Berov).

This program is free software, you can redistribute it and/or
modify it under the terms of the 
GNU Lesser General Public License v3 (LGPL-3.0).
You may copy, distribute and modify the software provided that 
modifications are open source. However, software that includes 
the license may release under a different license.

See http://opensource.org/licenses/lgpl-3.0.html for more information.

=cut


