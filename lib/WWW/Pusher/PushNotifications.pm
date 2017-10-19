package WWW::Pusher::PushNotifications;
{
  $WWW::Pusher::PushNotifications::VERSION = '0.01';
}

use warnings;
use strict;

use 5.008;

use JSON;
use URI;
use LWP::UserAgent;
use Digest::MD5 qw(md5_hex);
use Digest::SHA qw(hmac_sha256_hex);

use Data::Dumper;

my $pusher_defaults = {
	host => 'https://nativepush-cluster1.pusher.com',
	port => 443
};

=head1 NAME

WWW::Pusher::PushNotifications - Perl interface to pusher.com Push Notifications API

Based on WWW::Pusher by Squeeks and JT Smith.

=head1 VERSION

version 0.01

=cut

=head1 SYNOPSIS

    use WWW::Pusher::PushNotifications;

    my $pusher    = WWW::Pusher::PushNotifications->new(
       auth_key => 'YOUR API KEY',
			 secret => 'YOUR SECRET',
			 app_id => 'YOUR APP ID',
       use_apns => 1
			 );

    my $response  = $pusher->notify(data => '{'apns': {'priority': 5, 'aps': {'alert': {'body': 'tada'}}}}', interests => ['test_interest']);

=head1 METHODS

=head2 new(auth_key => $auth_key, secret => $secret, app_id => $app_id, [use_apns => $use_apns, use_gcm  => $use_gcm, use_fcm => $use_fcm])

Creates a new WWW::Pusher::PushNotifications object.

You can optionally specify the host and port keys and override using pusher.com's server if you
wish. In addtion, setting debug to a true value will return an L<LWP::UserAgent> response on any request.

=cut

sub new
{
	my ($class, %args) = @_;

	die 'Pusher auth key must be defined' unless $args{auth_key};
	die 'Pusher secret must be defined'  unless $args{secret};
	die 'Pusher application ID must be defined' unless $args{app_id};

	my $self = {
		uri	 => URI->new($args{host} || $pusher_defaults->{host}),
		lwp	 => LWP::UserAgent->new,
		debug    => $args{debug} || undef,
		auth_key => $args{auth_key},
		app_id   => $args{app_id},
		secret   => $args{secret},
		host 	 => $args{host} || $pusher_defaults->{host},
		port	 => $args{port} || $pusher_defaults->{port},
    use_apns => $args{use_apns} || 1,
    use_gcm  => $args{use_gcm} || 0,
    use_fcm => $args{use_fcm} || 0
	};

	$self->{uri}->port($self->{port});
	$self->{uri}->path('/server_api/v1/apps/'.$self->{app_id}.'/notifications');

	return bless $self;

}


=head2 notify(data => $data, interests => $interests, [socket_id => $socket_id, webhook_url => $webhook_url, debug => 1])

Send a push notification to the specified interest. There
should be no need to JSON encode your data.

Returns true on success, or undef on failure. Setting "debug" to a true value will return an L<LWP::UserAgent>
response object.

=cut

sub notify
{
	my ($self, %args) = @_;

  die 'Pusher interests must be defined' unless $args{interests};

	my $time     = time;
	my $uri      = $self->{uri}->clone;

  my $payload  = {
    'interests'   => $args{interests}
  };

  if ($args{webhook_url}) {
    $payload->{'webhook_url'} = $args{webhook_url};
  }

  if ($args{use_apns}) {
    $payload->{'apns'} = $args{data};
  }

  if ($args{use_gcm}) {
    $payload->{'gcm'} = $args{data};
  }

  if ($args{use_fcm}) {
    $payload->{'fcm'} = $args{data};
  }

  my $json = encode_json $payload;

	# The signature needs to have args in an exact order
	my $params = [
		'auth_key'       => $self->{auth_key},
		'auth_timestamp' => $time,
		'auth_version'   => '1.0',
		'body_md5'       => md5_hex($json)
	];

	$uri->query_form(@{$params});
	my $signature      = "POST\n".$uri->path."\n".$uri->query;
	my $auth_signature = hmac_sha256_hex($signature, $self->{secret});

	my $request = HTTP::Request->new('POST', $uri->as_string."&auth_signature=".$auth_signature, ['Content-Type' => 'application/json']);
  $request->content($json);

	my $response = $self->{lwp}->request($request);

	if($self->{debug} || $args{debug})
	{
		return $response;
	}
	elsif($response->is_success)
	{
		return 1;
	}
	else
	{
		return undef;
	}

}

=head1 AUTHOR

Sebastian Desimone C<< <sebastian at latinwit.com> >>

Squeeks, C<< <squeek at cpan.org> >>

JT Smith C<< <rizen at cpan.org> >>

=head1 BUGS

Please report bugs to the tracker on GitHub: L<https://github.com/SebasDesimone/WWW-Pusher-PushNotifications/issues>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Pusher::PushNotifications

More information at: L<https://github.com/SebasDesimone/WWW-Pusher-PushNotifications>

=head1 SEE ALSO

Pusher - L<https://pusher.com/>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Sebastian Desimone.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of WWW::Pusher::PushNotifications
