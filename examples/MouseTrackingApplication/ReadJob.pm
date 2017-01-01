package ReadJob;

use strict;
use warnings;

use lib '../lib';

use parent 'AbstractJob';
use WebSocketClientWriter;
use JSON::MaybeXS qw(encode_json decode_json);

sub new {
    my ( $class, %args ) = @_;
    my %self : shared;
    $self{clients} = $args{clients};
    $self{data}    = $args{data};
    $self{client}  = $args{client};

    bless( \%self, $class );

    return ( \%self );
}

sub DoJob {
    my ($self) = @_;

    my $json_object = decode_json($self->{data});
    $json_object->{id} = $self->{client}->id; 
    my $json_string = encode_json($json_object); 
    my $writer =
      WebSocketClientWriter->new->send_text_to_clients( $json_string,
        $self->{clients} );
}

1;
