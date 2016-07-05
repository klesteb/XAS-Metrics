use lib '../lib';
use strict;
use warnings;

use DateTime;
use Data::Dumper;
use Badger::Codecs;
use XAS::Lib::Process;
use DateTime::Format::Strptime;
use XAS::Utils 'trim :validation';

my $interval = '60';
my $duration = '10';

my $json = Badger::Codecs->codec('JSON');
my $command = "/home/kevin/dev/XAS-Metrics/trunk/sbin/xas-netstat --interval $interval --duration $duration --report raw";

my $process = XAS::Lib::Process->new(
    -alias       => 'netstat',
    -command     => $command,
    -user        => 'root',
    -group       => 'root',
    -environment => { S_TIME_FORMAT => 'ISO' },
    -redirect    => 1,
    -output_handler => sub {
        my $output = shift;

        my $line = trim($output);

        warn Dumper($json->decode($line));

    }
);

$process->log->level('debug', 1);
$process->run();

