#!/usr/bin/perl

use strict;
use warnings;
use feature qw(say);
use Getopt::Long;
use Data::Printer {
    color => {
        'regex'  => 'yellow',
        'hash'   => 'magenta',
        'string' => 'cyan',
        'array'  => 'green',
    },
};


my %OPT = (
    "lsped"        => "logsped",
    "err_log"      => "0_FTXXX1.tst",
    "participants" => "hw_list.txt",
    "list"         => 1,
);

open (my $PARTICIPANTS, "<", $OPT{participants}) or die "Could not open $OPT{map}: $!";

my %lookup = map { $_ => undef } qw/FTXXX1 FTBAZ1/;

foreach my $match (
    grep {
        chomp $_;
        my ($id, @data) = split /,/, $_;
        #exists $lookup{$id};
        $lookup{$id} = \@data if exists $lookup{$id};
    }
    <$PARTICIPANTS>
) {
    say $match;
    #$Logsped{$lookup{$id}} = [splice $match, 1, 5];
}

p %lookup;
