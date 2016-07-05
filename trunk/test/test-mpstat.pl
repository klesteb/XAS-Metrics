use lib '../lib';
use strict;
use warnings;

use DateTime;
use Data::Dumper;
use XAS::Lib::Process;
use DateTime::Format::Strptime;
use XAS::Utils 'trim :validation';

my $interval = '3';
my $duration = '3600';

my $command = "mpstat -P ALL $interval $duration";

my @fields = qw(time period cpu usr nice sys iowait irq soft steal guest idle);
my $strp = DateTime::Format::Strptime->new(
    pattern => '%F %r',
    time_zone => 'local'
);

my $process = XAS::Lib::Process->new(
    -alias       => 'mpstat',
    -command     => $command,
    -environment => { S_TIME_FORMAT => 'ISO' },
    -redirect    => 1,
    -output_handler => sub {
        my $output = shift;

        $output = trim($output);

        return if ($output =~ /Linux/);
        return if ($output =~ /%usr/);
        return if ($output eq '');

        my %info;
        my $dt = DateTime->now(time_zone => 'local');

        @info{@fields} = split(/\s+/, $output);

        my $date = sprintf('%s %s %s', $dt->ymd, $info{'time'}, $info{'period'});
        my $now = $strp->parse_datetime($date);

        $info{'datetime'} = $now->strftime('%Y-%m-%dT%H:%M:%S.%3N%z');

        delete $info{'time'};
        delete $info{'period'};

        warn Dumper(\%info);

    }
);

$process->run();

