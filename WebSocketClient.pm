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
    $self{writeBuffer}   = Thread::Queue->new();
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

sub writeBuffer {
    my ($self) = @_;
    lock($self);
    return $self->{writeBuffer};
}

sub empty_write_buffer {
    my ($self) = @_;
    lock($self);
    $self->{writeBuffer} = Thread::Queue->new();
}

1;
