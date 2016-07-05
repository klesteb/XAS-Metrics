use lib '../lib';
use strict;
use warnings;

use DateTime;
use Data::Dumper;
use XAS::Lib::Process;
use DateTime::Format::Strptime;
use XAS::Utils 'trim :validation de_camel_case';

my $interval = '60';
my $duration = '3600';
my $fifo = '/var/lib/xas/nmon';
my $command = "nmon -F $fifo -s$interval -t &";
my $strp = DateTime::Format::Strptime->new(
    pattern   => '%d-%b-%Y %T',
    time_zone => 'local'
);

system($command);

my $epoch;
my $fields;
my @datum;

# data output
#
# {
#    category => 'cpu01',
#    name     => 'user',
#    value    => '0.0',
#    epoch    =>  123456
# }
#

sub load_records {
    my $records = shift;

    my $data;
    my $fields = $fields->{$records->[0]};
    my $size   = scalar(@$fields);

    $data->{'category'} = lc($records->[0]);
    $data->{'epoch'}    = $epoch;

    for (my $x = 2; $x < $size; $x++) {

        my $details;

        $details->{'name'}  = $fields->[$x];
        $details->{'value'} = $records->[$x];

        push(@{$data->{'details'}}, $details);

    }

    push(@datum, $data);

}

sub build_fields {
    my $records = shift;

    foreach my $f (@$records) {

        push(@{$fields->{$records->[0]}}, $f);

    }

}


if (open(FIFO, "<" . $fifo)) {

    while (defined (my $line = readline(*FIFO))) {

        $line = trim($line);

        my @records = split(',', $line);

        next if ($records[0] =~ /AAA/);
        next if ($records[0] =~ /BBB/);

        if (($records[0] =~ /^ZZZ/) && ($records[1] =~ /^T\d+/)) {

warn Dumper(\@datum);
@datum = ();

            my $dt  = sprintf('%s %s', $records[3], $records[2]);
            my $now = $strp->parse_datetime($dt);

            $now->set_time_zone('UTC');      # change to UTC
            $epoch = $now->epoch();          # create epoch time

        } elsif ($records[0] =~ /^CPU/) {

            if ($records[1] =~ /^T\d+/) {

                load_records(\@records);

            } else {

                my @t1 = map { (my $s = $_) =~ s/%//g; $s } @records;

                build_fields(\@t1);
#                warn Dumper($fields->{$records[0]});

            }

        } elsif ($records[0] eq 'MEM') {

            if ($records[1] =~ /^T\d+/) {

                load_records(\@records);

            } else {

                build_fields(\@records);
#                warn Dumper($fields->{$records[0]});

            }

        } elsif ($records[0] eq 'VM') {

            if ($records[1] =~ /^T\d+/) {

                load_records(\@records);

            } else {

                build_fields(\@records);
#                warn Dumper($fields->{$records[0]});

            }

        } elsif ($records[0] eq 'PROC') {

            if ($records[1] =~ /^T\d+/) {

                load_records(\@records);

            } else {

                my @t1 = map { (my $s = $_) =~ s/-/_/g; $s } @records;

                build_fields(\@t1);
#                warn Dumper($fields->{$records[0]});

            }

        } elsif ($records[0] eq 'NET') {

            if ($records[1] =~ /^T\d+/) {

                load_records(\@records);

            } else {

                my @t1 = map { (my $s = $_) =~ s/KB\/s/kbs_sec/g; $s } @records;
                @records = map { (my $s = $_) =~ s/-/_/g; $s } @t1;

                build_fields(\@records);
#                warn Dumper($fields->{$records[0]});

            }

        } elsif ($records[0] eq 'NETPACKET') {

            if ($records[1] =~ /^T\d+/) {

                load_records(\@records);

            } else {

                my @t1 = map { (my $s = $_) =~ s/\/s/_sec/g; $s } @records;
                @records = map { (my $s = $_) =~ s/-/_/g; $s } @t1;

                build_fields(\@records);
#                warn Dumper($fields->{$records[0]});

            }

        } elsif ($records[0] eq 'JFSFILE') {

            if ($records[1] =~ /^T\d+/) {

                load_records(\@records);

            } else {

                build_fields(\@records);
#                warn Dumper($fields->{$records[0]});

            }

        } elsif ($records[0] =~ /^DISK/) {

            if ($records[1] =~ /^T\d+/) {

                load_records(\@records);

            } else {

                build_fields(\@records);
#                warn Dumper($fields->{$records[0]});

            }

        } elsif ($records[0] =~ /^DG/) {

            if ($records[1] =~ /^T\d+/) {

                load_records(\@records);

            } else {

                build_fields(\@records);
#                warn Dumper($fields->{$records[0]});

            }

        } elsif ($records[0] eq 'TOP') {

            # really Nigel, this is a mess

            next if (scalar(@records) < 3);

            if ($records[2] =~ /^T\d+/) {

                my $temp = $records[1];
                $records[1] = $records[2];
                $records[2] = $temp;

                load_records(\@records);

            } else {

                my @t1 = map { (my $s = $_) =~ s/\+//g; $s } @records;
                @records = map { (my $s = $_) =~ s/%//g; $s } @t1;
                
                build_fields(\@records);
#                warn Dumper($fields->{$records[0]});

            }

        }

    }

}

