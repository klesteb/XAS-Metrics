use lib '../lib';
use strict;
use warnings;

use Data::Dumper;
use XAS::Lib::Process;
use XAS::Utils 'trim :validation';

my $interval = '60';
my $duration = '3600';
my $command  = "iostat -td ALL $interval $duration";

my $now;
my $first = 1;
my @fields = qw(device tps kb_read_sec kb_write_sec kb_read kb_write);

my $process = XAS::Lib::Process->new(
    -alias       => 'iostat',
    -command     => $command,
    -environment => { S_TIME_FORMAT => 'ISO' },
    -redirect    => 1,
    -output_handler => sub {
        my $output = shift;

        $output = trim($output);

        return if ($output =~ /Linux/);
        return if ($output =~ /Device/);
        return if ($output eq '');

        if ($output =~ /^\d+-\d+-\d+/) {

            $now = $output;
            return;

        }

        my %info;

        @info{@fields} = split(/\s+/, $output);

        $info{'datetime'} = $now;

        if ($first) {

            $first = 0;

        } else {

            warn Dumper(\%info);

        }

    }
);

$process->run();

