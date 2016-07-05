package XAS::Metrics::Pidstat;

our $VERSION = '0.01';

use POE;
use DateTime;
use Data::Dumper;
use XAS::Lib::Process;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Base',
  accessors => 'process',
  utils     => 'dotid trim',
  codec     => 'JSON',
  vars => {
    PARAMS => {
      -service   => 1,
      -connector => 1,
      -interval  => { optional => 1, default => 60 },
      -alias     => { optional => 1, default => 'pidstat' },
      -type      => { optional => 1, default => 'xas-metrics-pidstat' },
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

    my $command = sprintf('pidstat -dhlrsw %s', $self->interval);
    my @fields = qw(time pid minflt_s majflt_s vsz rss mem stksize stkref kb_rd_s 
                    kb_wr_s kb_ccwr_s cswch_s nvcswch_s command);

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
            return if ($line =~ /#/);
            return if ($line eq '');

            my %info;

            @info{@fields} = split(/\s+/, $line, 15);

            my $dt = DateTime->from_epoch(epoch => $info{'time'}, time_zone => 'local');

            $info{'datetime'} = $dt->strftime('%Y-%m-%dT%H:%M:%S.%3N%z');

            delete $info{'time'};

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
