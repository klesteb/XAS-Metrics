package XAS::Metrics::Iostat::Extended;

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
      -alias     => { optional => 1, default => 'iostat-extended' },
      -type      => { optional => 1, default => 'xas-metrics-iostat-extended' },
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

        $self->{'type'} = 'xas-metrics-iostat-extended';

    }

    my $now;
    my $first   = 0;
    my $command = sprintf('iostat -txd ALL %s', $self->interval);
    my @fields  = qw(device rrqm_sec wrqm_sec rrmc_sec wrqm_sec rsec_sec wsec_sec avgrq_sz avgqu_sz await r_await w_await svctm util);

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
            return if ($line =~ /Device/);
            return if ($line eq '');

            if ($line =~ /^\d+-\d+-\d+/) {

                $now = $line;
                return;

            }

            my %info;

            @info{@fields} = split(/\s+/, $line);

            $info{'datetime'} = $now;

            if ($first) {

                $first = 0;

            } else {

                $self->log->debug(Dumper(\%info));

                $poe_kernel->post($self->connector, 'write_data', \%info, $self->type);

            }

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
