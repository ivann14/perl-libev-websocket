package WebSocketClient;

use strict;
use warnings;

use threads;
use threads::shared;

use Thread::Queue;

sub new {
    my ( $class, %args ) = @_;
    my %self : shared;
    $self{id}            = $args{id};
    $self{last_active}   = $args{last_active};
    $self{write_buffer}   = Thread::Queue->new();
    $self{closing}       = 0;
    $self{resource_name} = $args{resource_name};
    bless( \%self, $class );
    return ( \%self );
}

sub id {
    my ($self) = @_;
    lock($self);
    return $self->{id};
}

sub resource_name {
    my ($self) = @_;
    lock($self);
    return $self->{resource_name};
}

sub set_resource_name {
    my ( $self, $resource_name ) = @_;
    lock($self);
    $self->{resource_name} = $resource_name;
}

sub pinged {
    my ($self) = @_;
    lock($self);
    return $self->{pinged};
}

sub set_pinged {
    my ( $self, $pinged ) = @_;
    lock($self);
    $self->{pinged} = $pinged;
}

sub last_active {
    my ($self) = @_;
    lock($self);
    return $self->{last_active};
}

sub set_last_active {
    my ( $self, $last_active ) = @_;
    lock($self);
    $self->{last_active} = $last_active;
}

sub closing {
    my ($self) = @_;
    lock($self);
    return $self->{closing};
}

sub set_closing {
    my ( $self, $closing ) = @_;
    lock($self);
    $self->{last_active} = $closing;
}

sub write_buffer {
    my ($self) = @_;
    lock($self);
    return $self->{write_buffer};
}

sub empty_write_buffer {
    my ($self) = @_;
    lock($self);
    $self->{write_buffer} = Thread::Queue->new();
}

1;
__END__

=head1 NAME

WebSocketClient - WebSocket client

=head1 SYNOPSIS
	
    my $client = WebSocketClient->new( id => $identifier );
    
=head1 DESCRIPTION

This class is the representation of the connected websocket client. Contains all the data about client that can be shared between threads. WebSocket client has write buffer to enqueue messages. These messages will be sent to client, if the client's socket is writeable. This class is thread safe.
  
=head2 Methods

=over 12

=item C<id>

Returns client identifier. String representation of guid is used by default.

=item C<resource_name>

Returns resource name.

=item C<set_resource_name>

Sets resource name.

=item C<pinged>

Returns time when the client got pinged. By default time() method is used.

=item C<set_pinged>

Sets time when the client got pinged.

=item C<last_active>

Returns time of the last received client's frame.

=item C<set_last_active>

Sets time of the last received client's frame.

=item C<closing>

Returns true, if the connection with client is going to be closed. Otherwise false.
If returns true, then no more frames will be read. By default is false.

=item C<set_closing>

Set true, if connection to client will be closed and no other frames should be read from the socket.

=item C<write_buffer>

Returns Thread::Queue instance that is used as a buffer for WebSocket frames.

=item C<empty_write_buffer>

Client's write buffer will become empty, without all enqueued frames.



=back
