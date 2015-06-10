package Ado::Control::Vest;
use Mojo::Base 'Ado::Control';
use Time::Piece;
use Ado::Model::Users;

#validation template for action add.
my $add_contact_validation_template = {
    id => {
        'required' => 1,
        like       => qr/^\d{1,11}$/
    },
};

sub add_contact {
    my $c = shift;
    $c->require_formats('json') || return;
    my $vresult = $c->validate_input($add_contact_validation_template);

    state $log = $c->app->log;

    #400 Bad Request
    if ($vresult->{errors}) {
        $log->error('Validation error:' . $c->dumper($vresult));
        return $c->render(
            status => $vresult->{json}{code},
            json   => $vresult->{json}
        );
    }
    state $GR  = 'Ado::Model::Groups';
    state $UG  = 'Ado::Model::UserGroup';
    state $SQL = $UG->SQL('SELECT') . ' WHERE user_id=? AND group_id=?';
    my $contact_id = $vresult->{output}->{id};
    my $user       = $c->user;
    my $group      = $GR->by_name('vest_contacts_' . $user->id);
    my $ug         = $UG->query($SQL, $contact_id, $group->id);

    # avoid Firefox complaining about "no element found"
    $c->res->headers->header('Content-Type' => 'text/plain');

    #already a contact
    return $c->rendered(302) if $ug->user_id;
    $ug = $UG->create(
        user_id  => $contact_id,
        group_id => $group->id,
    );
    $c->rendered(204);
    return;
}

my $list_args_checks = {
    limit => {
        allow => sub { $_[0] =~ /^\d+$/ ? 1 : ($_[0] = 20); }
    },
    offset => {
        allow => sub { $_[0] =~ /^\d+$/ ? 1 : defined($_[0] = 0); }
    },
};

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
    state $default_limit = 20;
    my $limit = ($c->req->param('limit') || $default_limit);
    my $offset = $c->req->param('offset') || 0;

    # Default to last 20 messages (including first message)
    $offset = $offset > 0 ? $offset : ($limit > $count ? $offset : $count - $limit);
    my $args = Params::Check::check(
        $list_args_checks,
        {   limit  => $limit,
            offset => $offset,
        }
    );
    $c->debug('Looking for messages in talk ' . $s_m_id . ' for user ' . $user->id);
    my $messages =
      Ado::Model::Vest->by_subject_message_id($user, $s_m_id, $$args{limit}, $$args{offset});
    $c->res->headers->content_range(
        "messages $$args{offset}-${\($$args{limit} + $$args{offset})}/*");

    #notifications about new messages in talks
    my $meta = {talks => Ado::Model::Vest->talks($user, $default_limit, 0)};

    #content negotiation (json only for now)
    return $c->respond_to(
        json => $c->list_for_json([$$args{limit}, $$args{offset}], $messages, $meta));

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

    #content negotiation (json only for now)
    return $c->respond_to(json => $c->list_for_json([$$args{limit}, $$args{offset}], $talks));
}

#validation template for action create.
my $create_validation_template = {
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
        size       => [1, 255]    #up to 255 characters in subject
    },
    subject_message_id => {
        'required' => 1,
        like       => qr/^\d{1,11}$/
    },
    message => {
        'required' => 1,
        size       => [1, 5119]    #up to 5KB messages
    },
    message_assets => {
        'required' => 0,
        size       => [5, 3000]
    },
};

#Adds a new message. Status 201 on success, 400 on validate,5xx on faill
sub create {
    my $c      = shift;
    my $result = $c->validate_input($create_validation_template);

    #$c->debug('$create_validation_template:' . $c->dumper($create_validation_template));
    #$c->debug('$result:' . $c->dumper($result));

    #400 Bad Request
    return $c->render(
        status => $result->{json}{code},
        json   => $result->{json}
    ) if $result->{errors};

    my $message =
      eval { Ado::Model::Vest->create(%{$result->{output}}, tstamp => time) };
    if ($message) {

        # avoid Firefox complaining about "no element found"
        my $h = $c->res->headers;
        $h->header('Content-Type' => 'text/plain');

        #201 Created
        $h->header(Location =>
              $c->url_for('/' . $c->current_route . '/id/' . $message->id => format => 'json'));
        return $c->rendered(201);
    }
    else {
        my $err = 'Error in POST ' . $c->current_route;
        $c->app->log->error($err . ': ' . $@);
        return $c->render(
            status => 500,
            json   => {
                code    => 500,
                status  => 'error',
                message => 'The message could not be created on the server. '
                  . 'The administrator is informed about the error.',
                data => $err
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

    #Only the message can be updated. This logic belongs to the model maybe?!?
    my $update_template = {message => $$create_validation_template{message},};

    my $result = $c->validate_input($update_template);

    #400 Bad Request
    return $c->render(
        status => 400,
        json   => $result->{json}
    ) if $result->{errors};


    $vest->save(%{$result->{output}}, tstamp => time);
    return $c->rendered(204);
}

sub disable {
    my ($c) = @_;
    $c->res->body('not implemented...');
    $c->rendered(200);
    return;
}

sub screen {
    my ($c) = @_;
    $c->require_formats('html', 'json') || return;
    my $user   = $c->user;
    my $uid    = $user->id;
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

    my $contacts = [Ado::Model::Users->by_group_name('vest_contacts_' . $uid)];

    # Get last talk with each of the contacts
    state $talk_with_contact_SQL = <<'SQL';
            SELECT subject_message_id, MAX(id) AS id FROM vest
                WHERE ((to_uid=? AND from_uid=?) OR (to_uid=? AND from_uid=?))
SQL

    foreach my $contact (@$contacts) {
        my $cid = $contact->{id};
        my $last_talk = $c->dbix->query($talk_with_contact_SQL, $uid, $cid, $cid, $uid)->hash;
        $contact->{last_talk_id} = ($last_talk->{subject_message_id} || $last_talk->{id});
    }


    my $to_json = {
        user => {%{$user->data}, name => $user->name},
        talks => Ado::Model::Vest->talks($user, int($c->param('limit') || 20), 0),
        contacts => $contacts,
        routes   => $routes,
    };

    $c->respond_to(
        json => {json => $to_json},
        html => $to_json,
    );
    return;
}

my $users_validation_template = {
    name => {
        'required' => 1,
        size       => [1, 255]
    },
};
my $U = 'Ado::Model::Users';
$U->SQL('find_users_by_name' => <<"SQL");
    SELECT u.id, u.first_name, u.last_name FROM users u, user_group ug
    WHERE (u.id = ug.user_id
            AND ug.group_id=(SELECT g.id FROM groups g WHERE name='vest')
        ) AND
       -- Exclude existing contacts - members of vest_contacts_\$current_user->id
       u.id NOT IN(
            SELECT user_id from user_group WHERE user_id = u.id AND
            group_id=(SELECT id FROM groups WHERE name=?)) AND
       --exclude the current user
       u.id != ? AND
       -- from group vest
       (u.disabled=0 AND (u.stop_date>? OR u.stop_date=0) AND u.start_date<?) AND
      (
        (upper(u.first_name) LIKE upper(?) OR upper(u.last_name) LIKE upper(?)) OR
        (upper(u.last_name) LIKE upper(?) OR upper(u.first_name) LIKE upper(?))
      )
       ${\ $U->SQL_LIMIT('?', '?')}
SQL

#Searches and lists users belonging to the group vest by first and last name.
sub users {
    my ($c) = @_;
    $c->require_formats('json') || return;
    my $result = $c->validate_input($users_validation_template);
    state $log = $c->app->log;

    #400 Bad Request
    if ($result->{errors}) {
        $log->error($c->dumper($result));
        return $c->render(
            status => $result->{json}{code},
            json   => $result->{json}
        );
    }
    my $user = $c->user;

    #Search by name
    my $c_uid = $user->id;
    my $name  = Mojo::Util::trim($result->{output}{name});
    my ($first_name, $last_name) = map { uc($_) } split /\s+/, $name;
    $last_name //= '' . $user;    #stupid unfindable random string

    #Remove everything after "@" to prevent searching for all users @gmail
    $first_name =~ s/\@.+//;

    my $limit                    = 50;
    my $offset                   = 0;
    my $time                     = time;
    my $user_contacts_group_name = "vest_contacts_$c_uid";
    $c->debug("Searching in contacts of ${\ $user->login_name} (group $user_contacts_group_name) "
          . "to find if a user \%$first_name\% \%$last_name\% Does not belong to it");
    my @a = $U->query($U->SQL('find_users_by_name'),
        $user_contacts_group_name, $c_uid, $time, $time, "\%$first_name\%",
        "\%$last_name\%", "\%$first_name\%", "\%$last_name\%", $limit, $offset);

    my @data = map { +{%{$_->data}, name => $_->name} } @a;
    return $c->respond_to(json => $c->list_for_json([$limit, $offset], \@data));
}

#/talks/:id/seen
sub seen {
    my ($c) = @_;
    state $set_seen_validation_template = {
        unseen => {
            required => 1,
            like     => qr/^[\d\,]+\d$/
        }
    };
    my $result = $c->validate_input($set_seen_validation_template);

    #400 Bad Request
    if ($result->{errors}) {
        $c->app->log->error($c->dumper($result));
        return $c->render(
            status => $result->{json}{code},
            json   => $result->{json}
        );
    }

    #set messages as seen
    my $id = $c->stash('id');
    my @ids = (split /\,\s?/, $result->{output}{unseen});
    my $sql =
      'UPDATE vest SET seen = 1 WHERE to_uid=? AND (subject_message_id = ? OR id=?) AND id IN('
      . (join ',', map {'?'} @ids) . ')';
    $c->debug($sql, $id, $c->dumper(\@ids));
    $c->dbix->query($sql, $c->user->id, $id, $id, @ids);

    # avoid Firefox complaining about "no element found"
    $c->res->headers->header('Content-Type' => 'text/plain');
    $c->rendered(204);
    return;
}

1;

=pod

=encoding utf8

=head1 NAME

Ado::Control::Vest - The controller to manage messages. 

=head1 SYNOPSIS

  #in your browser go to
  http://your-host/vest
  #and
  http://your-host/vest/edit/$id
  #and
  http://your-host/vest/create
  
  #OR just have a chat with a friend.

=head1 DESCRIPTION

Ado::Control::Vest is the controller class for the end-users'
Ado messaging system.

=head1 ATTRIBUTES

L<Ado::Control::Vest> inherits all the attributes from L<Ado::Control>.

=head1 METHODS

L<Ado::Control::Vest> inherits all methods from L<Ado::Control> and implements
the following new ones. These methods are mapped to actions.
See C<etc/plugins/vest.conf>.

=head2 add_contact

Adds a contact to the list of contacts for the current user.
Invoked only via POST request. The only parameter is C<id> - the id of the user to be added. See C<Ado-Plugin-Vest/public/plugins/vest/vest.js> for example usage.
Reenders no content with header 204 in case the user is added or 302 if the
user was already added before.

=head2 create

Creates a new message.
Renders no content with status 201 and a C<Location> header 
pointing to the new resource so the user agent can fetch it eventually.
See L<http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.2>
and L<Ado::Model::Vest/create>.


=head2 disable

Disables a message . Not implemented yet

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

=head2 seen

Updates the seen column to 1 for a list of message IDs. Invoked via a PUT
request. Mapped to route C</talks/:id/seen>. The list is expected to be comma
separated string of message IDs in the request body. ":id" is the id of the
talk. Current user can set as "seen" only messages sent to him. Responds with
empty body and status 204.

=head2 update

Updates a message. Not implemented yet

=head2 users

Performs case insensitive search by first and last name and lists users
belonging to the group vest. Renders the first 50 results in JSON format.

    #Request
    http://localhost:3000/vest/users?name=кРа%20бер&format=json
    http://localhost:3000/vest/users/кРа%20бер.json
    #Response
    {
    "links":[
        {"rel":"self","href":"\/vest\/users\/%D0%BA%D0%A0%D0%B0%20%D0%B1%D0%B5%D1%80.json?limit=50&offset=0"}],
        "data":[
            {"name":"Красимир Беров","last_name":"Беров","first_name":"Красимир","id":7}]
    }

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


