use lib '../lib';
use strict;
use warnings;

use DateTime;
use Data::Dumper;
use XAS::Utils 'trim :validation run_cmd';

my $count    = 0;
my $interval = '60';
my $duration = '3600';

my $command = "netstat -i";
my @fields = qw(interface mtu met rx_ok rx_error rx_drop rx_ovr tx_ok tx_error tx_drop tx_ovr flag);

while ($count < $duration) {

    my ($output, $rc, $sig) = run_cmd($command);
    if ($rc == 0) {

        foreach my $line (@$output) {

            $line = trim($line);

            next if ($line =~ /Kernel/);
            next if ($line =~ /Iface/);

            my %info;
            my $now = DateTime->now(time_zone => 'local');

            @info{@fields} = split(/\s+/, $line);
            $info{'datetime'} = $now->strftime('%Y-%m-%dT%H:%M:%S.%3N%z');

            warn Dumper(\%info);

        }

    }

    $count += $interval;
    sleep $interval;

}

