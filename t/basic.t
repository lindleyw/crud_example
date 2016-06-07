#!/usr/bin/env perl                                                                                      
use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Test::Mojo::WithRoles 'Debug';

use Mojo::JSON 'decode_json';

binmode STDERR, ':utf8';
binmode STDOUT, ':utf8';

my $t = Test::Mojo::WithRoles->new('CrudExample');

#
# Before running this script, use the command line:
#    $ script/crud_example user create user pass123
#

# Log in, creating cookie

$t->post_ok('/login' => form => {username => 'user', password => 'pass123'})
->status_is(200);
$t->get_ok('/me')->status_is(200)->json_is('/username' => 'user')->json_has('/logged_in');

# Retrieve the count of messages                                                                                                           
# Test using JSON path                                                                                                                     
my $resp = $t->get_ok('/messages/count')->status_is(200);

# Examine JSON response and retrieve count                                                                                                 
my $original_message_count = (decode_json($resp->tx->res->content->asset->slurp))->{count};
# Verify that worked                                                                                                                       
$resp = $t->get_ok('/messages/count')->status_is(200)->json_is('/count', $original_message_count, "Retrieve original message count");

my $new_message_text = "Message text goes here.";
$resp = $t->post_ok('/message/user' => json => {'text' => $new_message_text})->status_is(200);
my $new_message_id = (decode_json($resp->tx->res->content->asset->slurp))->{id};
ok (defined $new_message_id, "New message has an ID");

$t->get_ok('/messages/count')->status_is(200)->json_is('/count', $original_message_count+1, "Message count incremented");
# We receive an array of messages, so grab the first and check its contents.                                                               
$t->get_ok("/message/$new_message_id")->status_is(200)->
json_is('/0/contents/text', $new_message_text, "Message text is correct")->
json_is('/0/viewed', 0, "Message was not previously viewed");

# Verify that message is now flagged as Viewed                                                                                             
$t->get_ok("/message/$new_message_id")->status_is(200)->json_is('/0/viewed', 1, "Message flagged as viewed");

done_testing;
