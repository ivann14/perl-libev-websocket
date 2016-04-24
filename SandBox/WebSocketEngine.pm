
package WebSocketEngine;

use strict;
use warnings;

use lib '..';

use parent 'AbstractWebSocketEngine';
use ReadJob;

sub new {
    my $class = shift;

    return $class->SUPER::new(@_);
}

sub process_text_data {
    my ( $self, $text, $client ) = @_;
    my $job = ReadJob->new( data => $text, clients => $self->clients );
    return $job;
}


sub authenticate_client {
    my ( $self, $client, $request ) = @_;
	my $value = $request->get_cookie_value("login");
	
	# If cookie contains key login with value false, then do not authenticate
	if (defined $value && $value eq "false") {
		print "Authentication failed. \n";
		return 0;
	} else {
		print "Authentication accepted. \n";
		return 1;
	}
}

1;
