package WebSocketRequest;

use strict;
use warnings;

sub new {
	my ( $class, $request ) = @_;
	my $self = bless {
        request => $request
    }, $class;

    return $self;
}

sub headers {
	my ($self) = @_;
	return $self->{request}->headers;
}

sub max_message_size {
	my ($self) = @_;
	return $self->{request}->max_message_size;
}


sub version {
	my ($self) = @_;
	return $self->{request}->version;
}


sub host {
	my ($self) = @_;
	return $self->{request}->host;
}


sub origin {
	my ($self) = @_;
	return $self->{request}->origin;
}


sub cache_control {
	my ($self) = @_;
	return $self->{request}->{fields}->{'cache-control'};
}


sub sec_websocket_extensions {
	my ($self) = @_;
	return $self->{request}->{fields}->{'sec-websocket-extensions'};
}


sub accept_encoding {
	my ($self) = @_;
	return $self->{request}->{fields}->{'accept-encoding'};
}


sub resource_name {
	my ($self) = @_;
	return $self->{request}->{fields}->{'resource-name'};
}


sub get_cookie_value {
	my ($self, $key) = @_;

	my $TOKEN = qr/[^;,\s"]+/;
	my $string = $self->{request}->{fields}->{cookie};
	$string =~ m/\s*($key)\s*(?:=\s*($TOKEN))?;?/g;
	return $2;
}

1;