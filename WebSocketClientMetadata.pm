package WebSocketClientMetadata;

use strict;
use warnings;

use Protocol::WebSocket;

#timer , dat pristup k loopu, lockovanie, IPV6,

sub new {
    my ( $class, %args ) = @_;

    my $self = bless {
        id            => $args{id},
        write_watcher => $args{write_watcher},
        read_watcher  => $args{read_watcher},
        handshake     => Protocol::WebSocket::Handshake::Server->new(),
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
