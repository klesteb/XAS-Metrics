package XAS::Metrics::RabbitMQ::Overview;

our $VERSION = '0.01';

use POE;
use Try::Tiny;

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Metrics::RabbitMQ::Base',
  vars => {
    PARAMS => {
      -alias => { optional => 1, default => 'rabbitmq-overview' },
      -type  => { optional => 1, default => 'rabbitmq-overview' },
    }
  }
;

# ---------------------------------------------------------------------
# Public Methods
# ---------------------------------------------------------------------

# ---------------------------------------------------------------------
# Public Events
# ---------------------------------------------------------------------

sub get_data {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: entering get_data()");

    try {

        my $data = $self->rabbit->overview();
        my $now  = $self->datetime->now(time_zone => 'local');

        $data->{'datetime'} = $now->strftime('%Y-%m-%dT%H:%M:%S.%3N%z');

        $poe_kernel->post($self->connector, 'write_data', $data, $self->type);

    } catch {

        my $ex = $_;
        $self->exception_handler($ex);

    };

    $poe_kernel->delay('get_data', $self->interval);
    $self->log->debug("$alias: leaving get_data()");

}

# ---------------------------------------------------------------------
# Private Methods
# ---------------------------------------------------------------------

# ---------------------------------------------------------------------
# Private Events
# ---------------------------------------------------------------------

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

Copyright (c) 2012-2016 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
