package CrudExample;
use Mojo::Base 'Mojolicious';

use Mojolicious::Plugin::Bcrypt;

use CrudExample::Model::User;
use CrudExample::Model::Message;

use Mojo::Pg;

# This method will run once at server start
sub startup {
  my $self = shift;

  $self->plugin('bcrypt', { cost => 6 });

  # Configuration
  $self->plugin('Config');                   # reads crud_example.conf
  $self->secrets($self->config('secrets'));
  $self->app->sessions->cookie_name($self->config('cookie_name') // 'CRUD_Example');

  # Load migrations from data in CrudExample package (this file)
  # and create a singleton to hold our database connection
  $self->helper(pg => sub {
                    state $pg = Mojo::Pg->new(shift->config('pg'))->
                      migrations->from_data('CrudExample')->migrate->pg;
                });

  $self->helper(users => sub {
                    state $user = CrudExample::Model::User->new(pg => shift->pg);
                });
  $self->helper(messages => sub {
                    state $msgs = CrudExample::Model::Message->new(pg => shift->pg);
                });

  $self->helper(current_user =>  sub {
                    my ($self) = @_;
                    return $self->session('username');
                });

  # Load commands from our namespace
  push @{$self->commands->namespaces}, 'CrudExample::Command';

  # Router
  my $r = $self->routes;

  # A single static file
  $r->get('/' => sub { my $c = shift; $c->reply->static('/index.html') } );

  # User dispatch
  $r->get('/login')->to('users#login');   # via template
  $r->post('/login')->name('do_login')->to('users#do_login');
  $r->get('/me')->to('users#whoami');
  $r->get('/logout')->to('users#logout');

  # Messages dispatch
  $r->get('/messages')->to('messages#get_all');
  $r->get('/messages/unread')->to('messages#get_all', type => 'unread');
  $r->get('/messages/read')->to('messages#get_all', type => 'read');
  $r->get('/messages/count')->to('messages#count');
  $r->get('/message/:id')->to('messages#get');
  $r->delete('/message/:id')->to('messages#delete');
  $r->put('/message/:id')->to('messages#mark_unread');
  $r->post('/message/:id')->to('messages#send_msg');

}

1;

__DATA__

@@ migrations

-- 1 up

SET client_encoding = 'UTF8';

DO $$
  BEGIN
    CREATE PROCEDURAL LANGUAGE plpgsql;
  EXCEPTION
    WHEN others THEN RAISE NOTICE 'OK, language available';
  END;
$$;

CREATE OR REPLACE FUNCTION sync_lastmod() RETURNS trigger AS $$
BEGIN
  NEW.modified := NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE users (
                    id       serial PRIMARY KEY,
                    username character varying(255) UNIQUE,
                    password character varying(255),
                    fullname character varying(255),
                    created  timestamp with time zone default now(),
                    modified timestamp with time zone
                    );

CREATE TRIGGER users_modified
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE PROCEDURE sync_lastmod();

CREATE TABLE messages (
                       id        serial PRIMARY KEY,
                       recipient integer references users(id) NOT NULL,
                       sender    integer references users(id) NOT NULL,
                       contents  jsonb NOT NULL,
                       viewed    boolean DEFAULT false,
                       created   timestamp with time zone default now(),
                       modified  timestamp with time zone
                      );

CREATE TRIGGER messages_modified
  BEFORE UPDATE ON messages
  FOR EACH ROW
  EXECUTE PROCEDURE sync_lastmod();

CREATE OR REPLACE FUNCTION notify_trigger() RETURNS trigger AS $$
  -- DECLARE
  BEGIN
    -- TG_TABLE_NAME is the name of the table whose trigger called this function
    -- TG_OP is the operation that triggered this function: INSERT, UPDATE or DELETE.
    -- Use 'execute' because table name changes at runtime.
    EXECUTE 'NOTIFY ' || TG_TABLE_NAME || ', ''' || TG_OP || '''';
    RETURN new;
  END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS message_trigger on messages;
-- Only trigger when contents are added or changed
CREATE TRIGGER message_trigger BEFORE insert OR update OF contents
  ON messages EXECUTE PROCEDURE notify_trigger();
-- You may now listen for (subscribe to) the Pg event 'message'
-- with parameter 'insert' or 'update'

