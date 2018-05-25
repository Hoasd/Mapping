use strict;
use warnings;

use Test::More;
use Test::Script;
use Test::Deep;
use Sub::Override;
use Term::ANSIColor 'colorstrip';

use lib 't/lib';
use Util;

my $script = 'bin/Mapping_old.pl';

TODO: {
    # you cannot pass this test yet because you're using pod2usage, which doesn't exist
    local $TODO = 'POD::Usage not loaded in code';
    script_compiles($script);
}

# A list of test cases with the expected file name

my @testcases = (
    {
        name  => 'v_1076_r_0',
        state => 0,                   # needs to be 1 or 0, not undef
        args  => [qw/ -v 1076 -r/],
    },

    {
        name  => 'v_1076_r_1',
        state => 1,                   # needs to be 1 or 0, not undef
        args  => [qw/ -v 1076 -r/],
    },

    ## TODO create these expected output files
    #{
    #    name  => 't_FTXXX1_v_1006_4001_r_0',
    #    state => 0,
    #    args  => [qw/ -t FTXXX1 -v 1006 4001 -r/],
    #},
    #{
    #    name  => 't_FTXXX1_v_1006_4001_r_1',
    #    state => 1,
    #    args  => [qw/ -t FTXXX1 -v 1006 4001 -r/],
    #},
    #{
    #    name  => 'too_long_r_0',
    #    state => 0,
    #    args  => [qw/ -t FTBLA1 --err_log 0_FTYYY1.tst -r/],
    #},
    #{
    #    name  => 'too_long_r_1',
    #    state => 1,
    #    args  => [qw/ -t FTBLA1 --err_log 0_FTYYY1.tst -r/],
    #},
);

foreach my $t (@testcases) {

    # This is similar to Class::Method::Modifier's around(), but temporary, so
    # we have to keep the original sub, so we can call it from within our replacement.
    # As soon as $sub goes out of scope it will restore the original on its own.
    my $orig = \&Test::Script::_perl_args;
    my $sub  = Sub::Override->new(
        'Test::Script::_perl_args' => sub {
            my $args = $orig->(@_);

            # We need to load our SocketOverride module to get the fake Socket into
            # the script, so we can control whether the port is open or closed.
            #
            # This is insane.
            push @{$args}, '-I', 't/lib', '-MSocketOverride=' . $t->{state};
            return $args;
        }
    );

    script_runs(
        [ $script, @{ $t->{args} } ],
        { stdout => \my $stdout, stderr => \my $stderr },
        sprintf(
            q{'%s' with an %s port},
            join( q{ }, @{ $t->{args} } ),
            $t->{state} ? 'open' : 'closed'
        ),
    );

    # This is really fragile because or the \r. It requires us to have the lines that get
    # overwritten in the expected output files. If we wouldn't do that, the \r character
    # would still have to be in the file, but try hacking that in with an IDE. The mixed
    # up order makes this test not as good as it should be, but it is kind of cool.
    cmp_deeply(
        [ map { chomp; $_ } split m{[\r\n]}, colorstrip($stdout) ],
        Util::get_expected( $t->{name} ),
        '... and the output matches'
    );

    if ( $t->{state} ) {
        like $stdout, qr/\033\[1;32;48mopen\033\[m/, '... and the output contains a green open';
    }
    else {
        like $stdout, qr/\033\[5;31;48mclosed\033\[m/, '... and the output contains a red closed';
    }
}

done_testing;
