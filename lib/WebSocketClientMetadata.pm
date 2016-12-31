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
        handshake     => $args{handshake}
          || Protocol::WebSocket::Handshake::Server->new(),
	frame     => $args{frame},
	prepare_watcher => $args{prepare_watcher},
 	client => $args{client},
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

sub frame {
    my ($self) = @_;
 
    if (not defined $self->{frame}) {
	$self->{frame} = $self->handshake->build_frame;
    }

    return $self->{frame};
}

sub prepare_write_watcher {
     my ($self) = @_;
  
     if (not defined $self->{prepare_watcher}) {
 
        my $idle = $self->write_watcher->loop->idle (sub {
		my ( $this_watcher ) = @_;
				
		if ($self->{client}->write_buffer->peek) {
			$this_watcher->stop;
			$self->write_watcher->start;
		}
	}); 	

 	$self->{prepare_watcher} = $idle;
     }
 
     return $self->{prepare_watcher};
 }

1;
__END__

=head1 NAME

WebSocketClientMetadata - WebSocket client metadata		

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

=item C<frame>

Returns frame object, frame object contains bytes sent form client that will be stored in this object until there is enough bytes
to build the whole WebSocket frame.

=back
