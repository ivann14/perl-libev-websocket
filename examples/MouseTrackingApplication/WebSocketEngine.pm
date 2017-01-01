
package WebSocketEngine;

use strict;
use warnings;

use lib '../lib';

use JSON::MaybeXS qw(encode_json decode_json);
use parent 'AbstractWebSocketEngine';
use ReadJob;

sub new {
    my $class = shift;

    return $class->SUPER::new(@_);
}

sub process_text_data {
    my ( $self, $text, $client ) = @_;
    my $job = ReadJob->new( data => $text, clients => $self->clients, client => $client );
    return $job;
}

sub authenticate_client {
    my ( $self, $client, $request ) = @_;
    my $value = $request->get_cookie_value("login");

    # If cookie contains key login with value false, then do not authenticate
    if ( defined $value && $value eq "false" ) {
        print "Authentication failed. \n";
        return 0;
    }
    else {
        print "Authentication accepted. \n";
        return 1;
    }
}

sub process_pong_data {
    my ( $self, $bytes, $client ) = @_;

    $self->SUPER::process_pong_data( $bytes, $client );
}


sub process_client_disconnecting {
    my ( $self, $client ) = @_;
	
    my $json_object = { id => $client->id, destroy => "true" };
    my $json_string = encode_json($json_object); 
    my $writer =
      WebSocketClientWriter->new->send_text_to_clients( $json_string,
        $self->clients );

    $self->SUPER::process_client_disconnecting( $client );
}


sub process_client_connection_is_closed {
    my ( $self, $client ) = @_;

    $self->SUPER::process_client_connection_is_closed($client);
    print "Client disconnected. \n";
}

1;
