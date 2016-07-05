package XAS::Metrics::Nmon::Pipe;

our $VERSION = '0.01';

use POE;
use DateTime;
use Data::Dumper;
use XAS::Lib::POE::PubSub;
use DateTime::Format::Strptime;

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'XAS::Lib::Pipe',
  accessors  => 'datum fields epoch strp event',
  utils      => ':validation dotid trim',
  codec      => 'JSON',
  filesystem => 'File',
  vars => {
    PARAMS => {
      -connector => 1,
      -alias     => { optional => 1, default => 'nmon-pipe' },
      -type      => { optional => 1, default => 'xas-metrics-nmon' },
    }
  }
;

# ---------------------------------------------------------------------
# Public Methods
# ---------------------------------------------------------------------

sub session_startup {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_startup()");

    $poe_kernel->call($alias, 'pipe_connect');
    $self->event->publish(-event => 'start_processing');

    # walk the chain

    $self->SUPER::session_startup();

    $self->log->debug("$alias: leaving session_startup()");

}

sub load_records {
    my $self    = shift;
    my $records = shift;

    my $data;
    my $fields = $self->fields->{$records->[0]};
    my $size   = scalar(@$fields);

    $data->{'category'} = lc($records->[0]);
    $data->{'epoch'}    = $self->epoch;

    for (my $x = 2; $x < $size; $x++) {

        my $details;

        $details->{'name'}  = $fields->[$x];
        $details->{'value'} = $records->[$x];

        push(@{$data->{'details'}}, $details);

    }

    push(@{$self->{'datum'}}, $data);

}

sub build_fields {
    my $self    = shift;
    my $records = shift;

    foreach my $f (@$records) {

        unless (defined($self->fields->{$records->[0]})) {

            push(@{$self->{'fields'}->{$records->[0]}}, $f);

        }

    }

}

sub process_input {
    my $self = shift;
    my ($input) = validate_params(\@_, [1]);

    my $alias   = $self->alias;
    my $line    = trim($input);
    my @records = split(',', $line);

warn "$line\n";

    $self->log->debug("$alias: process_input()");

    return if ($records[0] =~ /AAA/);
    return if ($records[0] =~ /BBB/);

    if (($records[0] =~ /^ZZZ/) && ($records[1] =~ /^T\d+/)) {

        # write out cached data

        my $datum = $self->datum;
warn Dumper($datum);

        $poe_kernel->post($self->connector, 'write_data', $datum, $self->type);

        $self->{'datum'} = ();
        $self->{'fields'} = {};

        # beginning a data collection

        my $dt  = sprintf('%s %s', $records[3], $records[2]);
        my $now = $self->strp->parse_datetime($dt);

        $now->set_time_zone('UTC');       # change to UTC
        $self->{'epoch'} = $now->epoch(); # create epoch time

    } elsif ($records[0] =~ /^CPU/) {

        if ($records[1] =~ /^T\d+/) {

            $self->load_records(\@records);

        } else {

            my @t1 = map { (my $s = $_) =~ s/%//g; $s } @records;

            $self->build_fields(\@t1);
            $self->log->debug(Dumper($self->fields->{$records[0]}));

        }

    } elsif ($records[0] eq 'MEM') {

        if ($records[1] =~ /^T\d+/) {

            $self->load_records(\@records);

        } else {

            $self->build_fields(\@records);
            $self->log->debug(Dumper($self->fields->{$records[0]}));

        }

    } elsif ($records[0] eq 'VM') {

        if ($records[1] =~ /^T\d+/) {

            $self->load_records(\@records);

        } else {

            $self->build_fields(\@records);
            $self->log->debug(Dumper($self->fields->{$records[0]}));

        }

    } elsif ($records[0] eq 'PROC') {

        if ($records[1] =~ /^T\d+/) {

            $self->load_records(\@records);

        } else {

            my @t1 = map { (my $s = $_) =~ s/-/_/g; $s } @records;

            $self->build_fields(\@t1);
            $self->log->debug(Dumper($self->fields->{$records[0]}));

        }

    } elsif ($records[0] eq 'NET') {

        if ($records[1] =~ /^T\d+/) {

            $self->load_records(\@records);

        } else {

            my @t1 = map { (my $s = $_) =~ s/KB\/s/kbs_sec/g; $s } @records;
            @records = map { (my $s = $_) =~ s/-/_/g; $s } @t1;

            $self->build_fields(\@records);
            $self->log->debug(Dumper($self->fields->{$records[0]}));

        }

    } elsif ($records[0] eq 'NETPACKET') {

        if ($records[1] =~ /^T\d+/) {

            $self->load_records(\@records);

        } else {

            my @t1 = map { (my $s = $_) =~ s/\/s/_sec/g; $s } @records;
            @records = map { (my $s = $_) =~ s/-/_/g; $s } @t1;

            $self->build_fields(\@records);
            $self->log->debug(Dumper($self->fields->{$records[0]}));

        }

    } elsif ($records[0] eq 'JFSFILE') {

        if ($records[1] =~ /^T\d+/) {

            $self->load_records(\@records);

        } else {

            $self->build_fields(\@records);
            $self->log->debug(Dumper($self->fields->{$records[0]}));

        }

    } elsif ($records[0] =~ /^DISK/) {

        if ($records[1] =~ /^T\d+/) {

            $self->load_records(\@records);

        } else {

            $self->build_fields(\@records);
            $self->log->debug(Dumper($self->fields->{$records[0]}));

        }

    } elsif ($records[0] =~ /^DG/) {

        if ($records[1] =~ /^T\d+/) {

            $self->load_records(\@records);

        } else {

            $self->build_fields(\@records);
            $self->log->debug(Dumper($self->fields->{$records[0]}));

        }

    } elsif ($records[0] eq 'TOP') {

        # really Nigel, this is a mess

        return if (scalar(@records) < 3);

        if ($records[2] =~ /^T\d+/) {

            my $temp = $records[1];
            $records[1] = $records[2];
            $records[2] = $temp;

            $self->load_records(\@records);

        } else {

            my @t1 = map { (my $s = $_) =~ s/\+//g; $s } @records;
            @records = map { (my $s = $_) =~ s/%//g; $s } @t1;

            $self->build_fields(\@records);
            $self->log->debug(Dumper($self->fields->{$records[0]}));

        }

    }

}

# ---------------------------------------------------------------------
# Public Events
# ---------------------------------------------------------------------

# ---------------------------------------------------------------------
# Private Events
# ---------------------------------------------------------------------

# ---------------------------------------------------------------------
# Private Methods
# ---------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self  = $class->SUPER::init(@_);
    my $alias = $self->alias;

    $self->{'datum'}  = ();
    $self->{'fields'} = {};

    $self->{'strp'} = DateTime::Format::Strptime->new(
        pattern   => '%d-%b-%Y %T',
        time_zone => 'local'
    );

    $self->{'event'} = XAS::Lib::POE::PubSub->new();
    $self->event->subscribe($alias);

    return $self;

}

1;

__END__

=head1 NAME

XAS:: - Perl extension for the XAS environment

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new

This module inherits from L<XAS::Lib::POE::Service|XAS::Lib::POE::Service> and 
takes these additional parameters:

=over 4

=back

=head1 PUBLIC EVENTS

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012-2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
