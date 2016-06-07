package CrudExample::Model::User v0.0.1 {

    use Mojo::Base -base;
    use SQL::Abstract::More;

    has 'pg';  # Set during object creation with new()
    has 'sql' => sub { SQL::Abstract::More->new(); };

    sub _fieldnames {
        my ($fieldset) = @_;
        my @fields = qw(username);
        if (defined $fieldset) {
            # Do not normally return password
            push @fields, 'password' if ($fieldset eq 'save'); 
            push @fields, 'id' if ($fieldset eq 'find');
        }
        return @fields;
    }

    # Actions

    sub add {
        my ($self, $data) = @_;

        my $id;
        eval {
            $id = $self->pg->db->query
              ( $self->sql->insert
                ( -into => 'users',
                  -values => {%{$data}{_fieldnames('save')}},
                  -returning => 'id',
                )
              );
        };

        if (defined $id) {
            return {id => $id};
        } else {
            return {error => $!};
        }
    }

    sub list {
        my ($self, $args) = @_;
        $self->pg->db->query
          ($self->sql->select( -from => 'users',
                               -columns => [_fieldnames('find')],
                               -offset => $args->{start},
                               -limit  => $args->{count},
                               -order_by => {-asc => [qw(username)]},
                             ) 
          )->hashes->to_array;
    }

    sub find {
        my ($self, $key, $value) = @_;
        return $self->pg->db->query
          ( $self->sql->select( -from => 'users',
                                -columns => [_fieldnames('find')],
                                -where => {$key => $value})
          )->hash;
    }

    sub remove {
        my ($self, $username) = @_;
        return $self->pg->db->query
          ( $self->sql->delete( -from => 'users',
                                -where => {username => $username})
          )->rows;
    }

    sub get_password {
        my ($self, $username) = @_;
        
        return $self->pg->db->query
          ( $self->sql->select( -from => 'users',
                                -columns => [qw(password)],
                                -where => {username => $username})
          )->hash->{password};
    }

    sub set_password {
        my ($self, $username, $password) = @_;
        
        # crypto is handled in the controller
        return $self->pg->db->query
          ( $self->sql->update( -table => 'users',
                                -set   => {password => $password},
                                -where => {username => $username})
          )->rows;
    }

}

1;
