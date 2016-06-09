package CrudExample::Model::Message v0.0.1 {

    use Mojo::Base -base;
    use SQL::Abstract::More;

    has 'pg';  # Set during object creation with new()
    has 'sql' => sub { SQL::Abstract::More->new(); };

    sub _fieldnames {
        my ($fieldset) = @_;
        my @fields = qw(recipient contents viewed created);
        my @numeric_fields = qw();
        my $is_save = 0;
        if (defined $fieldset) {
            return @numeric_fields if ($fieldset eq 'numeric');
            push @fields, 'id' if ($fieldset eq 'find');
            $is_save = ($fieldset eq 'save');
        }
        unless (defined $fieldset && ($fieldset eq 'save' || $fieldset eq 'sort')) {
            @numeric_fields = map { $_.'::numeric' } @numeric_fields;
        }
        unless ($is_save) {
	    push @fields, 'modified';
        }
        return @fields, @numeric_fields;
    }

    sub _subselect {
        return \ [ shift =~ s/\bSELECT\b/shift/er , @_ ];
    }

    # call as:
    # $self->subselect('= (SELECT)', -from => 'table', -columns => 'id', -where => {username => 'george'})
    sub subselect {
        my $self = shift;
        return _subselect(shift, $self->sql->select(@_));
    }

    ####

    sub send {
        my ($self, $sender, $recipient, $data) = @_;

        my $id = eval {
            $self->pg->db->query
              ( $self->sql->insert
                ( -into => 'messages',
                  -values => { sender => $self->subselect (
                                                           '(SELECT)', 
                                                           -from => 'users',
                                                           -columns => [qw(id)],
                                                           -where => {username => $sender}),
                               recipient => $self->subselect (
                                                              '(SELECT)', 
                                                              -from => 'users',
                                                              -columns => [qw(id)],
                                                              -where => {username => $recipient}),
                               contents => $data
                             },
                  -returning => 'id'
                )
              )
          ->hash->{id};
        };
        if (defined $id) {
            return {id => $id};
        } else {
            return {error => $!};
        }
    }

    sub get {
        my ($self, $user, $id) = @_;
        my $sql = 'SELECT '.
          '(SELECT username FROM users WHERE id=sender) as sender,'.
            'contents, created, viewed FROM messages WHERE id=? AND '.
              'recipient=(SELECT id FROM users WHERE username=?)';

        my $result = eval {
          my $tx = $self->pg->db->begin;
          my $result_hashes = $self->pg->db->query($sql, $id, $user)->expand->hashes;
          $self->pg->db->query('UPDATE messages SET viewed=true WHERE '.
                               'id=? AND recipient=(SELECT id FROM users WHERE username=?)', $id, $user);
          $tx->commit;
          $result_hashes;
        };

        if (defined $result) {
            return $result;
        } else {
            return {error => $!};
        }
    }
    
    sub get_all {
        my ($self, $user, $type) = @_;
        my $sql = 'SELECT '.
          '(SELECT id FROM users WHERE id=from_user_id) as sender,'.
            'contents, created, viewed FROM messages WHERE '.
              'recipient=(SELECT id FROM users WHERE username=?)';
        if ($type eq 'read') {
            $sql .= ' AND viewed=true';
        } elsif ($type eq 'unread') {
            $sql .= ' AND viewed=false';
        }
        my $retval = eval {
            $self->pg->db->query($sql, $user)
              ->expand->hashes;
        };
        if (defined $retval) {
            return {id => $retval};
        } else {
            return {error => $!};
        }
    }

    sub count {
        my ($self, $user, $type) = @_;
        my $sql = 'SELECT COUNT(id) AS count FROM messages WHERE '.
              'recipient=(SELECT id FROM users WHERE username=?)';
        if ($type eq 'read') {
            $sql .= ' AND viewed=true';
        } elsif ($type eq 'unread') {
            $sql .= ' AND viewed=false';
        }
        my $retval = eval {
            $self->pg->db->query($sql, $user)
              ->hash->{count};
        };
        if (defined $retval) {
            return {count => $retval};
        } else {
            return {error => $!};
        }
    }

    sub remove {
        my ($self, $user, $id) = @_;
        my $sql = 'DELETE FROM messages WHERE '.
              'recipient=(SELECT id FROM users WHERE username=?) AND id=?';
        my $retval = eval {
            $self->pg->db->query($sql, $user, $id)->rows;
        };
        if (defined $retval) {
            return {success => $retval};
        } else {
            return {error => $!};
        }
    }

    sub mark_unread {
        my ($self, $user, $id) = @_;
        my $sql = 'UPDATE messages SET viewed=? WHERE '.
              'user_id=(SELECT id FROM users WHERE id=?) AND id=?';
        my $retval = eval {
            $self->pg->db->query($sql, $user, ($id ? \1 : \0))->rows;
        };
        if (defined $retval) {
            return {success => $retval};
        } else {
            return {error => $!};
        }
    }
}

1;
