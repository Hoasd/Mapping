#!/usr/bin/perl

use strict;
use warnings;
use feature qw(say);
use Data::Printer {
    color => {
        'regex'  => 'yellow',
        'hash'   => 'magenta',
        'string' => 'cyan',
        'array'  => 'green',
    },
};

my @lines = <DATA>;
my %lookup = map { $_ => undef } qw/FTXXX1 FTBAZ1/;

foreach my $match (
    grep {
        my ($id, @data) = split /,/, $_;
        #exists $lookup{$id};
        $lookup{$id} = \@data if exists $lookup{$id};
    }
    @lines
) {
    print $match;
    #$Logsped{$lookup{$id}} = [splice $match, 1, 5];
}

p %lookup;

__DATA__
FTXXX1,1001,Ritter Testing,Cisco 866
FTFOO1,1129,Foo Limited,CheckPoint
FTBAR1,1006,Bar Limited,Palo Alto
FTBAZ1,1074,Baz Limited,SonicWall NSA 3200
FTJUH1,1076,J & H Limited,StrongSwan
