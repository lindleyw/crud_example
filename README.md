# crud_example
An example Restful CRUD example with Mojolicious, SQL::Abstract::More, and Mojo::Pg

This example program uses the following modules from CPAN:

    Mojolicious::Plugin::Bcrypt
    Mojo::Pg
    SQL::Abstract::More
    Test::Mojo::WithRoles
    Test::Mojo::Role::Debug

You will need to create a PostgreSQL database, for example with this command line:

    $ createdb msg_test
    
and then edit crud_example.conf to have your connection string with your username instead of 'bill' and your database as above:

        pg => 'postgresql://bill@/msg_test',

Before running the test script, use the command line:

    $ script/crud_example user create user pass123

You can then run the test script as:

    $ script/crud_example test -v

The -v is for verbose and may be omitted.

## Some interesting bits

From `lib/CrudExample.pm` in the `@@ migrations` section:

    CREATE TRIGGER users_modified
      BEFORE UPDATE ON users
      FOR EACH ROW
      EXECUTE PROCEDURE sync_lastmod();

This creates a trigger that, when a row in the `users` table is updated, will run the `sync_lastmod` procedure which we defined (see the file for details). That procedure sets the `modified` column to the current time. The effect is that Postgres keeps an automatic record of when each row was last modified.

And:

    -- Only trigger when contents are added or changed
    CREATE TRIGGER message_trigger BEFORE insert OR update OF contents
      ON messages EXECUTE PROCEDURE notify_trigger();

You may now listen for (subscribe to) the Pg event 'message' with parameter 'insert' or 'update'. See for example the `pubsub->listen` method in `Mojo::Pg` for details. Whenever any process inserts or updates the contents field of a row, even a user from the `psql` command line, your listening code will receive a notification.




