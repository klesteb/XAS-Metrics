use lib '../lib';
use strict;
use warnings;

use DateTime;
use Data::Dumper;
use XAS::Lib::Process;
use DateTime::Format::Strptime;
use XAS::Utils 'trim :validation';

my $interval = '60';
my $duration = '3600';

my $command = "pidstat -dhlrsw $interval $duration";

my @fields = qw(time pid minflt_s majflt_s vsz rss mem stksize stkref kb_rd_s 
                kb_wr_s kb_ccwr_s cswch_s nvcswch_s command);

my $process = XAS::Lib::Process->new(
    -alias       => 'pidstat',
    -command     => $command,
    -environment => { S_TIME_FORMAT => 'ISO' },
    -redirect    => 1,
    -output_handler => sub {
        my $output = shift;

        $output = trim($output);

        return if ($output =~ /Linux/);
        return if ($output =~ /#/);
        return if ($output eq '');

        my %info;

        @info{@fields} = split(/\s+/, $output, 15);

        my $dt = DateTime->from_epoch(epoch => $info{'time'}, time_zone => 'local');

        $info{'datetime'} = $dt->strftime('%Y-%m-%dT%H:%M:%S.%3N%z');

        delete $info{'time'};

        warn Dumper(\%info);

    }
);

$process->run();

