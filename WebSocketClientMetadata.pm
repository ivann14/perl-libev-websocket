package WebSocketClientMetadata;

use strict;
use warnings;

use Protocol::WebSocket;

sub new {
    my ( $class, %args ) = @_;

    my $self = bless {
        id            => $args{id},
        write_watcher => $args{write_watcher},
        read_watcher  => $args{read_watcher},
        handshake     => $args{handshake} || Protocol::WebSocket::Handshake::Server->new(),
    }, $class;
    return $self;
}

sub id {
    my ($self) = @_;
    return $self->{id};
}

sub write_watcher {
    my ($self) = @_;
    return $self->{write_watcher};
}

sub read_watcher {
    my ($self) = @_;
    return $self->{read_watcher};
}

sub handshake {
    my ($self) = @_;
    return $self->{handshake};
}
1;
__END__

=head1 NAME

WebSocketClientMetadata - WebSocket client metadata

=head1 SYNOPSIS
	
	

=head1 DESCRIPTION

This class represents all data about websocket client that can not be shared between threads. 
  
=head2 Methods

=over 12

=item C<id>

Returns WebSocketClientMetadata identifier which can be tied with existing WebSocketClient.
String representation of GUID is used by default.

=item C<write_watcher>

Returns object responsible for checking if client's socket is writeable.

=item C<write_watcher>

Returns object responsible for checking if client's socket is readable.

=item C<handshake>

Returns object representing websocket handshake request.

=back