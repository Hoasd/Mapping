package SocketOverride;

## This is black magic. No, seriously. Carry on, there is nothing to see here.

# %INC contains info on which files perl has already loaded. We use this to
# stop it from loading the real IO::Socket.
$INC{'IO/Socket.pm'}      = 1;
$INC{'IO/Socket/INET.pm'} = 1;

our $state;

# We load this module with -MSocketOverride=$state, so the state gets passed to
# our import() method. This way we get the state of the port we want to have in
# the test into the other program in a different perl interpreter.
sub import {
    shift;    # discard module name
    $state = shift;
}

# This is the code that the real program will run when it does IO::Socket::INET->new.
# It essentially only  returns true or false (1 or 0), which is how we define the
# control flow for our test.
package IO::Socket::INET;

{
    no warnings 'once';
    *IO::Socket::INET::new = sub {
        my $class = shift;

        return $SocketOverride::state;
    };
}

1;
