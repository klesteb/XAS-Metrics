package XAS::Metrics::Nmon::Process;

our $VERSION = '0.01';

use POE;
use XAS::Lib::POE::PubSub;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::Process',
  accessors => 'event',
  constants => ':process',
  vars => {
    PARAMS => {
      -auto_start   => { optional => 1, default => 0 },
      -exit_retries => { optional => 1, default => -1 },
    }
  }
;

# ---------------------------------------------------------------------
# Public Methods
# ---------------------------------------------------------------------

sub session_initialize {
    my $self = shift;

    my $dir;
    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_initialize()");

    $poe_kernel->state('start_processing', $self);

    # walk the chain

    $self->SUPER::session_initialize();

    $self->log->debug("$alias: leaving session_initialize()");

}

# ---------------------------------------------------------------------
# Public Events
# ---------------------------------------------------------------------

sub start_processing {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: entering start_processing()");

    $poe_kernel->call($alias, 'start_process');

    $self->log->debug("$alias: leaving start_processing()");

}

# sub check_process {
#     my ($self) = $_[OBJECT];

#     my $alias = $self->alias;
#     my $stat  = $self->status;

#     $self->log->debug("$alias: entering check_process()");

#     if ($stat == PROC_RUNNING) {

#         $self->event->publish(-event => 'pipe_connect');

#     } else {

#         $poe_kernel->delay('check_process', 5);

#     }

# }

# ---------------------------------------------------------------------
# Private Methods
# ---------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self  = $class->SUPER::init(@_);
    my $alias = $self->alias;

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
