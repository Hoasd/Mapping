#!/usr/bin/perl

use strict;
use warnings;
use POSIX;
use IO::Socket;
use Getopt::Long;
use feature qw(say);
use Data::Dumper;

my %OPT = (
    "lsped"    => "logsped",
    "err_log"  => "0_FTUNDF.tst",
    "map"      => "hw_list.txt",
    "list"     => 1,
);

my (@vpn_id, @ftam, @ip_addr, %Final_list);

my %targets = (
    vpn_id  => [],
    ftam_id => [],
    ip      => [],
);

GetOptions (\%OPT,
    'lsped|l=s',
    'err_log|f=s',
    'run|r',
    'debug|x',
    'man',
    'map=s',
    'help',
    'lsped=s',
    'vpn_id|v=i{1,}'    => \&shift_values,
    'ftam_id|t=s{1,}'   => \&shift_values,
    'ip|i=s{1,}'        => \&shift_values
) or pod2usage(2);

# flush the print buffer immediately
$| = 1;


sub shift_values {
    my ($opt_name, $opt_value) = @_;
    chomp $opt_value;
    #print ("Option name is $opt_name and value is $opt_value\n");
    push @{$targets{$opt_name}}, uc $opt_value;
}

#print Dumper($targets{ftam_id});

sub merge_parms_with_credentials {
    #print Dumper(\%targets);
    my $TN_map_ref = shift;        # Ergebnisliste (%TN_map = (%Logsped - %FailedConnections)) -> {FTxxxx} => [vpn_id,Name,Hardware]
    my %Logsped;                   # Dort landet die konvertierte Logsped aus <$fh_credentials> als Hash
    my @F;

    # Einlesen der Hardwareliste
    open (my $fh_map, "<", $OPT{map}) or die "Could not open $OPT{map}: $!";
   

#    my $pattern = join '|', map { sprintf '(:?%s)', $_ } @patterns;


    while (my $item = <$fh_map>) {
        chomp $item;
        my @items = split /,/, $item, 4;
        push @F, [ $items[0], $items[1], $items[2], $items[3]  ];
    }
    close $fh_map;
    #print Dumper(\@F);
    
    # Einlesen der Logsped 
    open (my $fh_credentials, "<", $OPT{lsped}) or die "Could not open $OPT{lsped}: $!";
    while (my $dataset = <$fh_credentials>) {
        chomp $dataset;
        # Convert Logsped from Whitespace to csv and assign the participant as anonymous array reference to: $tn = [FTXXX1,1001,ip,X,Passwd,Port,FTM_TSEL] 
        my $tn = [split '\s+', $dataset];           # split /\s+/ does not work
        $Logsped{$tn->[0]} = [splice @$tn, 1, 5];    # FTxxxx ends up as Key in %Logsped, with an anonymous array 0..5 [nnnn,ip,X,Passwd,Port,FTM_TSEL]  
        #print Dumper(\%Logsped);
    }
    close $fh_credentials;

   # foreach my $ip (@{$targets{ip}}) {
   #     say $ip;
   # }

    foreach my $vpn_id (@{$targets{vpn_id}}) {
        #say $vpn_id;
        foreach my $line (@F) {
            #print "Foo: ", $line->[1], "\n"; 
            #print Dumper($line) if ($line->[1] =~ m/$vpn_id/);
            if ($line->[1] =~ m/$vpn_id/) {
                #print "Match: $line->[1]\n";
                #print Dumper($F[$ if $vpn_id m/$F[1]/;
                $TN_map_ref->{$line->[0]} = $Logsped{$line->[0]} if ($line->[1] =~ m/$vpn_id/);
                ($TN_map_ref->{$line->[0]}[5], $TN_map_ref->{$line->[0]}[6], $TN_map_ref->{$line->[0]}[7]) = ($line->[1], $line->[2], $line->[3]);
            }
            #print Dumper($TN_map_ref);
        }
    }
    
    # Verheiraten der %TN_Map mit der %Logsped und der %TN_map als Ergebnis:
    foreach my $ftam (@{$targets{ftam_id}}) {
        foreach my $line (@F) {
            if ($line->[0] =~ m/$ftam/) {
                #print "Treffer:\t\$line: $line->[0]\t\$ftam $ftam\n" if ($line->[0] =~ m/$ftam/);
                $TN_map_ref->{$line->[0]} = $Logsped{$line->[0]};
                push @{ $TN_map_ref->{$ftam} }, @{$line}[1,2,3];  # Anwendung eines Splice, weil $line->[0] FTXXX1 enthaelt und damit redundant in den Datensatz uebernommen werden wuerde!
                
                if ($OPT{debug}) {
                    print "\xe2\x94\x80"x120, "\n";
                    print Dumper(\$Logsped{$line->[0]});
                    print Dumper($TN_map_ref);
                    print Dumper($TN_map_ref->{$ftam});
                    print Dumper($TN_map_ref->{$line->[0]});
                    print "\xe2\x94\x80"x120, "\n";
                }
            }
            #print Dumper($TN_map_ref);
            #last;
            
            #print "\xe2\x94\x80"x120, "\n";
            #print Dumper($Logsped{$ftam});
            #print "\xe2\x94\x80"x120, "\n";
            
            #($TN_map_ref->{$line->[0]}, $TN_map_ref->{$tn}[6], $TN_map_ref->{$tn}[7],  $TN_map_ref->{$tn}[8] = ($line->[1], $line->[2], $line->[3]);
            $TN_map_ref->{$ftam} = $Logsped{$ftam};
        }
    }
    #print Dumper($TN_map_ref);
    return ($TN_map_ref);
}


sub print_list {
    my $TN_map_ref = shift; # $TN_map_ref referenziert auf die leere $Final_list
    #print Dumper(\$TN_map_ref);
    #my ($err_lst_ref, $TN_error_list_ref) = merge_logsped();
    my $h = merge_logsped($TN_map_ref);
    #my $h = $Final_list;
    printf "\n%-8s%-16s%-8s%4s%-59s%-10s\n", "FTMSEL", "IP Adresse", "Port", "VPN", "    Teilnehmer", "Hardware";
    print "\xe2\x94\x80"x120, "\n";
    foreach my $tn (keys %{$h}) {
        #printf "%-8s%-6i%-15s\t%-6s%-60s%-s\n", $tn, $h->{$tn}[5], $h->{$tn}[1], $h->{$tn}[4], $h->{$tn}[6], $h->{$tn}[7];
        printf "%-8s%-16s%-8s%-8i%-55s%-s\n", $tn, $h->{$tn}[1], $h->{$tn}[4], $h->{$tn}[5], $h->{$tn}[6], $h->{$tn}[7];
        $h->{$tn}[8] = "Daeschd";
    }
    print "\xe2\x94\x80"x120, "\n";
}

sub merge_logsped {
    my %Logsped;                        # Dort landet die konvertierte Logsped aus <$fh_credentials> als Hash
    #say "Bin in \&merge_logsped | vor dem Dumper";
    my $Final_list = shift;                    # Ergebnisliste (%TN_map = (%Logsped - %FailedConnections)) -> {FTxxxx} => [vpn_id,Name,Hardware]
    #say "Bin in \&merge_logsped | nach dem Dumper";

    open (my $fh_unrechables, "<", $OPT{err_log}) or die "Could not open $OPT{err_log}: $!";
    my %Failed_Connections = map { chomp; split /,/, $_, 2 } <$fh_unrechables>;
    close $fh_unrechables;
    #print Dumper(\%Failed_Connections);

    #print Dumper($Final_list);
    open (my $fh_credentials, "<", $OPT{lsped}) or die "Could not open $OPT{lsped}: $!";
    while (my $dataset = <$fh_credentials>) {
        chomp $dataset;
        # Convert Logsped from Whitespace to csv and assign the participant as anonymous array reference to: $tn = [FTXXX1,1001,ip,X,Passwd,Port,FTM_TSEL] 
        my $tn = [split '\s+', $dataset];           # split /\s+/ does not work
        $Logsped{$tn->[0]} = [splice @$tn, 1, 5];    # FTxxxx ends up as Key in %Logsped, with an anonymous array 0..5 [nnnn,ip,X,Passwd,Port,FTM_TSEL]  
        #print Dumper(\%Logsped);
    }
    close $fh_credentials;

    # Verheiraten der %Failed_Connections mit der %Logsped und der %TN_Map als Ergebnis:
    foreach my $tn (keys %Failed_Connections) {
        $Final_list{$tn} = $Logsped{$tn} if exists $Failed_Connections{$tn}; # Weise %TN_Map den Datensatz aus der %Logsped zu wenn match mit der %Failed_Connections 
        ($Final_list{$tn}->[5], $Final_list{$tn}->[6], $Final_list{$tn}->[7], $Final_list{$tn}->[8]) = split /,/, $Failed_Connections{$tn};
    }
    return ($Final_list);
}


sub check_ports {
    my $ref = shift; # $TN_Map_ref referenziert auf die leere $Final_list, in die nach dem Verbindungstest der Status zurückgeschrieben wird!
    my $h = merge_logsped($ref);
    my ($tn, $state, $port);
    printf "\n%-8s%-16s%-7s%-8s%5s%-59s%-s\n", "FTMSEL", "IP Adresse", "Port", "State", "VPN", "    Teilnehmer", "Hardware";
    print "\xe2\x94\x80"x120, "\n";

    foreach $tn (keys %{$h}) {
        #\r will refresh the line
        #print "\rScanning port $h->{$tn}[4]";
        #printf "\rScanning: %-8s%-16s%-7s%-6i%-60s%-s", $tn, $h->{$tn}[1], $h->{$tn}[4], $h->{$tn}[5], $h->{$tn}[6], $h->{$tn}[7];
        printf "\rScanning: %-8s%-16s%-7s", $tn, $h->{$tn}[1], $h->{$tn}[4];
     
        #Connect to port number
        my $socket = IO::Socket::INET->new(PeerAddr => $h->{$tn}[1], PeerPort => $h->{$tn}[4] , Proto => 'tcp' , Timeout => 2);
     
        #Check connection
        if( $socket ) {
            #print "\r = Port \033\[7;39;44m$h->{$tn}->[4]\033\[m is \033[5;37;48mopen\033\[m.\n";
            $h->{$tn}[8] = 1;
            printf "\r%-8s%-16s%-7s%-22s%-8i%-55s%-s\n", $tn, $h->{$tn}[1], $h->{$tn}[4], "\033\[1;32;48mopen\033\[m", $h->{$tn}[5], $h->{$tn}[6], $h->{$tn}[7];
        }
    	else {
            #print "\r = Port $h->{$tn}->[4] is closed.\n";
            $h->{$tn}[8] = 0;
            printf "\r%-8s%-16s%-7s%-22s%-8i%-55s%-s\n", $tn, $h->{$tn}[1], $h->{$tn}[4], "\033\[5;31;48mclosed\033\[m", $h->{$tn}[5], $h->{$tn}[6], $h->{$tn}[7];
    	}
    }

#    my $date = strftime("%d-%m-%Y - %H:%M:%S", localtime); 
#    if ($h->{$tn}[8] == 1) { 
#        print "\n\nSuccess: Port check for \033[1;37;48m$tn\033\[m\@\033[1;37;48m$h->{$tn}->[1]\033\[m on $date\n\n";
#    } 
#    else { 
#        print "\n\nFailed: Port check for \033[1;37;48m$tn\033\[m\@\033[1;37;48m$h->{$tn}->[1]\033\[m on $date\n\n";
#    }

    print "\xe2\x94\x80"x120, "\n";
    #print Dumper(\$h);
}
 
#print "$tn not found\n" if (!defined $ip_addr);
#die "\nKein Eintrag für Teilnehmer \"$tn\" in $lsped\n\n" if (!defined $ip_addr);


my $foo = merge_parms_with_credentials(\%Final_list); 
$OPT{run} ? check_ports(\%Final_list) : print_list(\%Final_list);   # %Final_list ist leer und wird nur als Referenz übergeben, 