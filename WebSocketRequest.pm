package WebSocketRequest;

use strict;
use warnings;

sub new {
    my ( $class, $request ) = @_;
    my $self = bless { request => $request }, $class;

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
    my ( $self, $key ) = @_;

    my $TOKEN  = qr/[^;,\s"]+/;
    my $string = $self->{request}->{fields}->{cookie};
	if ($string) {
		$string =~ m/\s*($key)\s*(?:=\s*($TOKEN))?;?/g;
		return $2;
	}
	
	return "";
}

1;
__END__

=head1 NAME

WebSocketRequest - WebSocket request

=head1 SYNOPSIS

	my $request = WebSocketRequest->new ($handshake->req);
	my $cookie_value = $request->get_cookie_value("key");

=head1 DESCRIPTION

This class represents WebSocket handshake request. Used for authenticating an incoming websocket client.
  
=head2 Attributes

=over 12

=item C<headers>

=item C<max_message_size>

=item C<version>

=item C<host>

=item C<origin>

=item C<cache_control>

=item C<sec_websocket_extensions>

=item C<accept_encoding>

=item C<resource_name>

=head2 Methods

=over 12

=item C<new>

Constructor. Takes Protocol::WebSocket::Request as parameter.

=item C<get_cookie_value>

Returns cookie value for given key.

=back
