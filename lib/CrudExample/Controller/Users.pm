package CrudExample::Controller::Users;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;

sub whoami {
    # Who is the currently logged-in user making the request?
    my ($self) = @_;

    return $self->render(json => { logged_in => $self->session('logged_in') ? \1 : \0,
                                   username => $self->session('username'),
                                 });
}

sub create {
    my ($self) = @_;

    my %user_data;
    my $text = Mojo::JSON::decode_json($self->req->body);
    foreach my $field ($self->users->fieldnames('save')) {
        $user_data{$field} = $text->{$field};
    }
    unless (defined $user_data{username} && defined $user_data{password}) {
        return $self->render(json => {error => "Username and password required"});
    }
    $user_data{password} = $self->bcrypt($text->{password});
    my $result = $self->users->add(\%user_data);
    # Creating a user also logs you in as that user
    if (!exists $result->{error}) {
        $self->session(logged_in => 1);
        $self->session(username => $user_data{username});
        $result->{success} = 1;
    }
    return $self->render(json => $result);
}

sub logout {
    my $self = shift;

    my $whowasi = $self->session('username');
    $self->session(expires => 1);
    return $self->render(json => {success => 1, username => $whowasi});
}

sub do_login {
    my $self = shift;

    my ($user, $pass);

    if ( ($self->tx->req->method eq 'POST') && 
         index($self->req->body, '{') >= 0 ) {
        my $text = Mojo::JSON::decode_json($self->req->body);
        ($user, $pass) = ($text->{username}, $text->{password});
    } else {
        ($user, $pass) = ($self->param('username'), $self->param('password'));
    }

    if ($self->bcrypt_validate($pass,$self->app->users->get_password($user) // '')) {
        $self->session(logged_in => 1);
        $self->session(username => $user);

        # c.f. http://mojolicious.org/perldoc/Mojolicious/Guides/Rendering#Content-negotiation
        $self->respond_to( json => {json => {success => 1} },
                           html => {json => {success => 1} },
                         );
    } else {
        my $error = 'Wrong username/password';
        $self->respond_to( json => {json => {success => 0, error => $error}, status => 403},
                           html => {text => $error, status => 403} );
    }
}

sub list {
    my $self = shift;

    $self->render(json => 
                  $self->app->users->list({pattern => $self->param('matching'),
                                           start => $self->param('start') // 0,
                                           count => $self->param('count') // 10}
                                         )
                 );
                  
}

1;
