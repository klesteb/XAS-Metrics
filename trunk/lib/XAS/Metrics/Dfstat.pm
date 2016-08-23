package XAS::Metrics::Dfstat;

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
      -alias     => { optional => 1, default => 'dfstat' },
      -type      => { optional => 1, default => 'xas-metrics-dfstat' },
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

        $self->{'type'} = 'xas-metrics-dfstat';

    }

    my $command = 'df -P';
    my @fields = qw(name size used free capacity mount);

    my $convert = sub {         # convert 12.3% to .123
        my $percentage = shift;
        $percentage =~ s{%}{};
        return $percentage / 100;
    };

    $self->{'process'} = XAS::Lib::Process->new(
        -alias        => $self->alias,
        -command      => $command,
        -user         => 'root',
        -group        => 'root',
        -retry_delay  => $self->interval,
        -exit_retries => -1,
        -redirect     => 1,
        -output_handler => sub {
            my $line = trim(shift);

            return if ($line =~ /^Filesystem/ );
            return if ($line eq '');

            my %info;
            my $now = DateTime->now(time_zone => 'local');

            @info{@fields} = split(/\s+/, $line);
            $info{'datetime'} = $now->strftime('%Y-%m-%dT%H:%M:%S.%3N%z');
            $info{'capacity'} = $convert->($info{'capacity'});

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
