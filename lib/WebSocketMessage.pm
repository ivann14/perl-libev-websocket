package WebSocketMessage;

use strict;
use warnings;

use threads;
use threads::shared;

use Protocol::WebSocket;
use Protocol::WebSocket::Frame;

sub new {
    my ( $class, %args ) = @_;
	
	my $self;
	if ($args{type} eq 'handshake') {
		$self = bless { 
			buffer => $args{buffer},
			type => $args{type}
		}, $class;
	} else {
		$self = bless { 
			frame => Protocol::WebSocket::Frame->new( buffer => $args{buffer}, type => $args{type} )
		}, $class;
	}
	
    return $self;
}

sub is_handshake {
    my ($self) = @_;
	
	if ( $self->{frame} ) {
		return 0;
	}
	
	return 1;
}

sub is_close {
    my ($self) = @_;
	
	if( $self->{frame} && $self->{frame}->is_close ) {
		return 1;
	}

	return 0;
}


sub is_ping {
    my ($self) = @_;
	
	if( $self->{frame} && $self->{frame}->is_ping ) {
		return 1;
	}

	return 0;
}

sub is_pong {
    my ($self) = @_;
	
	if( $self->{frame} && $self->{frame}->is_pong ) {
		return 1;
	}

	return 0;
}


sub is_text {
    my ($self) = @_;
	
	if( $self->{frame} && $self->{frame}->is_text ) {
		return 1;
	}

	return 0;
}

sub is_binary {
    my ($self) = @_;
	
	if( $self->{frame} && $self->{frame}->is_binary ) {
		return 1;
	}

	return 0;
}

sub get_data {
    my ($self) = @_;
	
	if ($self->{frame}) {
		return $self->{frame}->to_bytes;
	}
	
	return $self->{buffer};
}

1;
__END__

=head1 NAME

WebSocketMessage - WebSocket message 

=head1 SYNOPSIS

	my $message = WebSocketMessage->new ("text", "text message for client");
	my $message = WebSocketMessage->new ("ping", "ping message for client");
	my $message = WebSocketMessage->new ("pong", "pong response for client");
	my $message = WebSocketMessage->new ("close", "close code and reason");
	my $message = WebSocketMessage->new ("handshake", "websocket response handshake");
	my $data_to_be_sent_for_client = $message->get_data();

=head1 DESCRIPTION

This class represents WebSocket message. Used for sending data to clients from server.

=head2 Methods

=over 12

=item C<new>

Constructor. Takes type of the WebSocket message and data to send.

=item C<get_data>

Returns data that should be send to client via TCP connection.

=item C<is_handshake>

Returns true if message contains websocket handshake response.

=item C<is_ping>

Returns true if message is type of ping.

=item C<is_pong>

Returns true if message is type of pong.

=item C<is_text>

Returns true if message is type of text.

=item C<is_close>

Returns true if message is type of close.

=back
