package XAS::Metrics::Spooler;

our $VERSION = '0.01';

use POE;
use XAS::Factory;
use Try::Tiny::Retry ':all';

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'XAS::Lib::POE::Service',
  mixin      => 'XAS::Lib::Mixins::Handlers',
  accessors  => 'spool',
  constants  => 'TRUE FALSE',
  codec      => 'JSON',
  filesystem => 'Dir',
  vars => {
    PARAMS => {
      -service   => 1,
      -directory => { optional => 1, isa => 'Badger::Filesystem::Directory', default => undef },
    }
  }
;

# ---------------------------------------------------------------------
# Public Events
# ---------------------------------------------------------------------

sub write_data {
    my ($self, $datum, $type) = @_[OBJECT,ARG0,ARG1];

    my $alias = $self->alias;
    my $dt = DateTime->now(time_zone => 'local');

    $self->log->debug("$alias: entering write_data()");

    retry {

        my $data = {
            hostname => $self->env->host,
            datetime => $dt->strftime('%Y-%m-%dT%H:%M:%S.%3N%z'),
            type     => $type,
            data     => $datum,
        };

        my $json = encode($data);
        $self->spool->write($json);

    } delay_exp {

        30, 1000    # attempts, delay in milliseconds

    } retry_if {

        my $ex = $_;
        my $ref = ref($ex);

        if ($ref && $ex->isa('XAS::Exception')) {

            return TRUE if ($ex->match_type('xas.lib.spool'));

        }

        return FALSE;

    } catch {

        my $ex = $_;

        $self->exception_handler($ex);

    };

    $self->log->debug("$alias: leaving write_data()");

}

# ---------------------------------------------------------------------
# Public Methods
# ---------------------------------------------------------------------

sub session_initialize {
    my $self = shift;

    my $dir;
    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_initialize()");

    $poe_kernel->state('write_data', $self);

    # walk the chain

    $self->SUPER::session_initialize();

    $self->log->debug("$alias: leaving session_initialize()");

}

# ---------------------------------------------------------------------
# Private Methods
# ---------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    if (defined($self->{'directory'})) {

        if ($self->directory->is_relative) {

            $self->{'directory'} = Dir($self->env->spool, $self->directory);

        }

    } else {

        $self->{'directory'} = Dir($self->env->spool, 'metrics');

    }

    $self->{'spool'} = XAS::Factory->module(spool => {
        -directory => $self->directory,
        -lock      => Dir($self->directory, 'locked')->path,
    });

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
