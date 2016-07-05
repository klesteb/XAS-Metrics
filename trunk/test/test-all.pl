use lib '../lib';
use strict;
use warnings;

use DateTime;
use Data::Dumper;
use XAS::Lib::Process;
use DateTime::Format::Strptime;
use XAS::Utils 'trim :validation run_cmd';

my $interval = '60';
my $duration = '3600';

sub iostat {
    
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

}

sub iostat_ext {
    
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
    
}

sub mpstat {

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
    
}

sub netstat_interfaces {
    
    my $count   = 0;
    my $command = "netstat -i";
    my @fields  = qw(interface mtu met rx_ok rx_error rx_drop rx_ovr tx_ok tx_error tx_drop tx_ovr flag);

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

}

sub netstat_raw {
    
    my $count    = 0;
    my $command = "netstat --raw --numeric --programs";
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
    
}

sub netstat_tcp {

    my $count   = 0;
    my $command = "netstat --tcp --numeric-port --programs";
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
    
}

sub netstat_udp {
    
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
    
}

sub pidstat {

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
    
}

# main

iostat();
iostat_ext();
mpstat();
pidstat();

