use strict;
use warnings;

use Test::More;
use Test::Script;
use Test::Deep;

use lib 't/lib';
use Util;

my $script = 'bin/Mapping_old.pl';

TODO: {
    # you cannot pass this test yet because you're using pod2usage, which doesn't exist
    local $TODO = 'POD::Usage not loaded in code';
    script_compiles($script);
}

# A list of test cases with the expected file name as the first element and all the
# arguments as the rest of the array reference. The => is just syntactic sugar. It would
# allow us to not quote the numbers on the left, but because they are numbers that would
# look like they are actual octal. Real names instead of numbers would be a vast
# improvement here.
my @testcases = (
    [ '001' => qw/ -v 1076 / ],
    [ '002' => qw/ -t FTXXX1 -v 1006 4001 / ],
    [ '003' => qw/ -t FTBLA1 --err_log 0_FTYYY1.tst / ],
);

foreach my $t (@testcases) {
    my $filename = shift @$t;
    script_runs( [ $script, @$t ], { stdout => \my $stdout }, join( q{ }, @$t ) );
    cmp_deeply(
        [ map { chomp; $_ } split m{\n}, $stdout ],
        Util::get_expected($filename),
        '... and the output matches'
    );
}

done_testing;
