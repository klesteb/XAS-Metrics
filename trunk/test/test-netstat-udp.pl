use lib '../lib';
use strict;
use warnings;

use DateTime;
use Data::Dumper;
use XAS::Utils 'trim :validation run_cmd';

my $count    = 0;
my $interval = '60';
my $duration = '3600';

my $command = "netstat --udp --numeric --programs";
my @fields = qw(proto recv_queue send_queue local_address foreign_address state extras);

while ($count < $duration) {

    my ($output, $rc, $sig) = run_cmd($command);
    if ($rc == 0) {

        foreach my $line (@$output) {

            $line = trim($line);

            next if ($line =~ /Active/);
            next if ($line =~ /Proto/);

            my %info;
            my $now = DateTime->now(time_zone => 'local');

            @info{@fields} = split(/\s+/, $line, 7);
            $info{'datetime'} = $now->strftime('%Y-%m-%dT%H:%M:%S.%3N%z');
            ($info{'pid'}, $info{'program'}) = split('/', $info{'extras'});

            delete $info{'extras'};

            warn Dumper(\%info);

        }

    }

    $count += $interval;
    sleep $interval;

}

