use lib '../lib';
use strict;
use warnings;

use Data::Dumper;
use XAS::Lib::Process;
use XAS::Utils 'trim :validation';

my $interval = '60';
my $duration = '3600';
my $command  = "iostat -txd ALL $interval $duration";

my $now;
my $first = 1;
my @fields = qw(device rrqm_sec wrqm_sec rrmc_sec wrqm_sec rsec_sec wsec_sec avgrq_sz avgqu_sz await r_await w_await svctm util);
my $process = XAS::Lib::Process->new(
    -alias       => 'iostat-extended',
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

