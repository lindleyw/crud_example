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

