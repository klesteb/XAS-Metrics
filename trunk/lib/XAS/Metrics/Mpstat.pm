package XAS::Metrics::Mpstat;

our $VERSION = '0.01';

use POE;
use DateTime;
use Data::Dumper;
use XAS::Lib::Process;
use DateTime::Format::Strptime;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Base',
  accessors => 'process',
  utils     => 'dotid trim',
  vars => {
    PARAMS => {
      -service   => 1,
      -connector => 1,
      -interval  => { optional => 1, default => 60 },
      -alias     => { optional => 1, default => 'mpstat' },
      -type      => { optional => 1, default => 'xas-metrics-mpstats' },
    }
  }
;

# ---------------------------------------------------------------------
# Public Events
# ---------------------------------------------------------------------

# ---------------------------------------------------------------------
# Public Methods
# ---------------------------------------------------------------------

# ---------------------------------------------------------------------
# Private Methods
# ---------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    unless ($self->type ne '') {

        $self->{'type'} = 'xas-metrics-mpstats';

    }

    my $command = sprintf('mpstat -P ALL %s', $self->interval);
    my @fields = qw(time period cpu usr nice sys iowait irq soft steal guest idle);
    my $strp = DateTime::Format::Strptime->new(
        pattern   => '%F %r',
        time_zone => 'local'
    );

    $self->{'process'} = XAS::Lib::Process->new(
        -alias        => $self->alias,
        -command      => $command,
        -user         => 'root',
        -group        => 'root',
        -exit_retries => -1,
        -environment  => { S_TIME_FORMAT => 'ISO' },
        -redirect     => 1,
        -output_handler => sub {
            my $line = trim(shift);

            return if ($line =~ /Linux/);
            return if ($line =~ /%usr/);
            return if ($line eq '');

            my %info;
            my $json;
            my $dt = DateTime->now(time_zone => 'local');

            @info{@fields} = split(/\s+/, $line);

            my $date = sprintf('%s %s %s', $dt->ymd, $info{'time'}, $info{'period'});
            my $now = $strp->parse_datetime($date);

            $info{'datetime'} = $now->strftime('%Y-%m-%dT%H:%M:%S.%3N%z');

            delete $info{'time'};
            delete $info{'period'};

            $self->log->debug(Dumper(\%info));

            $poe_kernel->post($self->connector, 'write_data', \%info, $self->type);

        }
    );

    $self->service->register($self->alias);

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
