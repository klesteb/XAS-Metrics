package XAS::Metrics::Nmon;

our $VERSION = '0.01';

use XAS::Metrics::Nmon::Pipe;
use XAS::Metrics::Nmon::Process;

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'XAS::Base',
  accessors  => 'process pipe',
  filesystem => 'File',
  vars => {
    PARAMS => {
      -service   => 1,
      -connector => 1,
      -interval  => { optional => 1, default => 60 },
      -type      => { optional => 1, default => 'xas-metrics-nmon' },
      -fifo      => { optional => 1, default => undef, ias => 'Badger::Filesystem::File' },
    }
  }
;

# ---------------------------------------------------------------------
# Public Methods
# ---------------------------------------------------------------------

# ---------------------------------------------------------------------
# Private Methods
# ---------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);
    my $snapshots = int(86400 / $self->interval);

    unless ($self->type ne '') {

        $self->{'type'} = 'xas-metrics-nmon';

    }

    unless (defined($self->{'fifo'})) {

        $self->{'fifo'} = File($self->env->lib, 'nmon');

    }

    my $command = sprintf('nmon -F %s -s %s -t', $self->fifo, $self->interval);

    $self->{'pipe'} = XAS::Metrics::Nmon::Pipe->new(
        -alias     => 'nmon-pipe',
        -fifo      => $self->fifo,
        -connector => $self->connector,
        -type      => $self->type,
    );

    $self->{'process'} = XAS::Metrics::Nmon::Process->new(
        -alias   => 'nmon-process',
        -command => $command,
    );

    $self->service->register('nmon-pipe');
    $self->service->register('nmon-process');

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
