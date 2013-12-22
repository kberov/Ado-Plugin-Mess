package Ado::Control::Mess;
use Mojo::Base 'Ado::Control';


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

    $c->res->headers->content_range("messages $$args{offset}-${\($$args{limit} + $$args{offset})}/*");
    $c->debug("rendering json only [$$args{limit}, $$args{offset}]");

    #content negotiation
    return $c->respond_to(
        json => $c->list_for_json([$$args{limit}, $$args{offset}], [Ado::Model::Mess->select_range($$args{limit}, $$args{offset})]));

}


sub add {
    return shift->render(text => 'not implemented...');
}

sub show {
    return shift->render(text => 'not implemented...');
}

sub update {
    return shift->render(text => 'not implemented...');
}

sub disable {
    return shift->render(text => 'not implemented...');
}

1;

