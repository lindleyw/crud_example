package CrudExample::Controller::Messages v0.0.1 {

    use Mojo::Base 'Mojolicious::Controller';
    use Mojo::JSON;

    sub get {
        my $self = shift;
        my $user = $self->session('username');
        my $id = $self->stash('id');

        my $result = $self->messages->get($user, $id);
        if (defined $result) {
            return $self->render(json => $result);
        } else {
            return $self->render(json => {success => 0, error => 'Not found'});
        }
    }

    sub get_all {
        my $self = shift;
        my $user = $self->session('username');
        my $type = $self->stash('type') // 'unread';

        my $result = $self->messages->get_all($user, $type);
        if (defined $result) {
            return $self->render(json => $result);
        } else {
            return $self->render(json => {success => 0, error => 'Not found'});
        }
    }

    sub count {
        my $self = shift;
        my $user = $self->session('username');
        my $type = $self->stash('type') // 'unread';

        my $result = $self->messages->count($user, $type);
        if (defined $result) {
            return $self->render(json => $result);
        } else {
            return $self->render(json => {success => 0, error => 'Not found'});
        }
    }

    sub send_msg {
        my $self = shift;
        my $sender = $self->session('username');
        my $recipient = $self->stash('id');
        my $message = $self->req->body;

        unless (defined $message) {
            return $self->render(json => {success => 0, error => 'Message contents required'});
        }

        my $result = $self->messages->send($sender, $recipient, $message);
        if (defined $result) {
            return $self->render(json => $result);
        } else {
            return $self->render(json => {success => 0, error => 'Not sent'});
        }
    }

    sub delete {
        my $self = shift;
        my $user = $self->session('username');
        my $id = $self->stash('id');

        my $result = $self->messages->delete($user, $id);
        if (defined $result) {
            return $self->render(json => $result);
        } else {
            return $self->render(json => {success => 0, error => 'Not found'});
        }
    }

    sub mark_unread {
        my $self = shift;
        my $user = $self->session('username');
        my $id = $self->stash('id');

        my $result = $self->messages->mark_unread($user, $id);
        if (defined $result) {
            return $self->render(json => $result);
        } else {
            return $self->render(json => {success => 0, error => 'Not found'});
        }
    }

}

1;
