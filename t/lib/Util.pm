package Util;
use strict;
use warnings;

use Test::Deep 'bag';

=head2 get_expected

Takes a filename without the I<.data> extension, reads the file from
the I<t/expected> directory and returns a C<Test::Deep::bag()> of the
lines in the file without trailing linebreaks.

Data files shouldn't have empty trailing lines, but they should have the
leading empty line that's in the program's output.

=cut

sub get_expected {
    my $filename = shift;

    open my $fh, '<', "t/expected/$filename.data" or die $!;
    my @lines = <$fh>;
    chomp @lines;
    
    return bag( @lines );
}

1;
