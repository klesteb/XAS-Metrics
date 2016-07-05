use lib '../lib';
use strict;
use warnings;

use DateTime;
use Data::Dumper;
use XAS::Lib::Process;
use DateTime::Format::Strptime;
use XAS::Utils 'trim :validation';

my $interval = '60';
my $duration = '10';

my $command = "netstat -i";
my @fields = qw(interface mtu met rx_ok rx_error rx_drop rx_ovr tx_ok tx_error tx_drop tx_ovr flag);

my $process = XAS::Lib::Process->new(
    -alias        => 'netstat',
    -command      => $command,
    -user         => 'root',
    -group        => 'root',
    -retry_delay  => $interval,
    -exit_retries => -1,
    -environment  => { S_TIME_FORMAT => 'ISO' },
    -redirect     => 1,
    -output_handler => sub {
        my $output = shift;

        my $line = trim($output);

        return if ($line =~ /Kernel/);
        return if ($line =~ /Iface/);
        return if ($line eq '');

        my %info;
        my $now = DateTime->now(time_zone => 'local');

        @info{@fields} = split(/\s+/, $line);
        $info{'datetime'} = $now->strftime('%Y-%m-%dT%H:%M:%S.%3N%z');

        warn Dumper(\%info);

    }
);

#$process->log->level('debug', 1);
$process->run();

