package XAS::Metrics::Netstat::UDP;

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
  vars => {
    PARAMS => {
      -service   => 1,
      -connector => 1,
      -interval  => { optional => 1, default => 60 },
      -alias     => { optional => 1, default => 'netstat-udp' },
      -type      => { optional => 1, default => 'xas-metrics-netstat-udp' },
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

        $self->{'type'} = 'xas-metrics-netstat-udp';

    }

    my $command = 'netstat --udp --numeric --programs';
    my @fields  = qw(proto recv_queue send_queue local_address foreign_address state extras);

    $self->{'process'} = XAS::Lib::Process->new(
        -alias        => $self->alias,
        -command      => $command,
        -user         => 'root',
        -group        => 'root',
        -retry_delay  => $self->interval,
        -exit_retries => -1,
        -environment  => { S_TIME_FORMAT => 'ISO' },
        -redirect     => 1,
        -output_handler => sub {
            my $line = trim(shift);

            return if ($line =~ /Active/);
            return if ($line =~ /Proto/);
            return if ($line eq '');

            my %info;
            my $json;
            my $now = DateTime->now(time_zone => 'local');

            @info{@fields} = split(/\s+/, $line, 7);
            $info{'datetime'} = $now->strftime('%Y-%m-%dT%H:%M:%S.%3N%z');
            ($info{'pid'}, $info{'program'}) = split('/', $info{'extras'});

            delete $info{'extras'};

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
