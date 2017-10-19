use lib '../lib';
use strict;
use Test::More;

use_ok 'WWW::Pusher::PushNotifications';

my $pusher = WWW::Pusher::PushNotifications->new(auth_key => 'made-up', secret => 'made-up', app_id => 'made-up');

isa_ok $pusher, 'WWW::Pusher::PushNotifications';

done_testing();
