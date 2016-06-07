package CrudExample::Command::user;
use Mojo::Base 'Mojolicious::Command';

has description => 'Modify application users';
has usage       => "Usage: APPLICATION user [create|delete] username [password]\n";

no warnings 'uninitialized';

sub run {
    my ($self, @args) = @_;

    my $command = shift @args;
    if ($command eq 'create') {
        if (defined $args[0] && defined $args[1]) {
            $self->app->users->add({username => $args[0], password => $self->app->bcrypt($args[1])});
        } else {
            warn "Please specify username and plaintext password.\n"
        }
    } elsif ($command eq 'delete') {
        $self->app->users->remove($args[0]);
    } else {
        warn $self->usage;
    }
}

1;
