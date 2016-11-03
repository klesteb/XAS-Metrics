package XAS::Metrics::RabbitMQ::Base;

our $VERSION = '0.01';

use POE;
use DateTime;
use Try::Tiny;
use XAS::Lib::POE::PubSub;
use XAS::Metrics::RabbitMQ;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::POE::Service',
  mixin     => 'XAS::Lib::Mixins::Handlers',
  accessors => 'rabbit datetime events',
  vars => {
    PARAMS => {
      -url              => 1,
      -service          => 1,
      -username         => 1,
      -password         => 1,
      -connector        => 1,
      -fail_on_error    => { optional => 1, default => undef },
      -keep_alive       => { optional => 1, default => undef },
      -follow_location  => { optional => 1, default => undef },
      -ssl_verify_peer  => { optional => 1, default => undef },
      -ssl_verify_host  => { optional => 1, default => undef },
      -max_redirects    => { optional => 1, default => undef },
      -timeout          => { optional => 1, default => undef },
      -connect_timeout  => { optional => 1, default => undef },
      -ssl_cacert       => { optional => 1, default => undef },
      -ssl_keypasswd    => { optional => 1, default => undef },
      -proxy_url        => { optional => 1, default => undef },
      -ssl_cert         => { optional => 1, default => undef },
      -ssl_key          => { optional => 1, default => undef },
      -proxy_password   => { optional => 1, default => undef },
      -proxy_username   => { optional => 1, default => undef },
      -auth_method      => { optional => 1, default => undef },
      -proxy_auth       => { optional => 1, default => undef },
      -interval         => { optional => 1, default => 60 },
      -alias            => { optional => 1, default => 'rabbitmq-channels' },
      -type             => { optional => 1, default => 'rabbitmq-channels' },
    },
    ARGS => [
        'url',
        'username',
        'password',
        'fail_on_error',
        'keep_alive',
        'follow_location',
        'ssl_verify_peer',
        'ssl_verify_host',
        'max_redirects',
        'timeout',
        'connect_timeout',
        'ssl_cacert',
        'ssl_keypasswd',
        'proxy_url',
        'ssl_cert',
        'ssl_key',
        'proxy_password',
        'proxy_username',
        'auth_method',
        'proxy_auth',
    ]
  }
;

# ---------------------------------------------------------------------
# Public Events
# ---------------------------------------------------------------------

# ---------------------------------------------------------------------
# Public Methods
# ---------------------------------------------------------------------

sub session_initialize {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_initialize()");

    $poe_kernel->state('get_data', $self);

    # walk the chain

    $self->SUPER::session_initialize();

    $self->log->debug("$alias: leaving session_initialize()");

}

sub session_startup {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_startup()");

    $poe_kernel->delay('get_data', $self->interval);

    # walk the chain

    $self->SUPER::session_startup();

    $self->log->debug("$alias: leaving session_startup()");

}

sub session_pause {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_pause()");

    $poe_kernel->delay('get_data');

    # walk the chain

    $self->SUPER::session_pause();

    $self->log->debug("$alias: entering session_pause()");

}

sub session_resume {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_resume()");

    $poe_kernel->delay('get_data', $self->interval);

    # walk the chain

    $self->SUPER::session_resume();

    $self->log->debug("$alias: entering session_resume()");

}

sub session_shutdown {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_cleanup()");

    $poe_kernel->delay('get_data');

    # walk the chain

    $self->SUPER::session_shutdown();

    $self->log->debug("$alias: leaving session_cleanup()");

}

# ---------------------------------------------------------------------
# Private Methods
# ---------------------------------------------------------------------

sub init {
    my $class = shift;

    my @args;
    my $self = $class->SUPER::init(@_);

    foreach my $arg (@{$self->class->var('ARGS')}) {

        push(@args, "-$arg", $self->$arg) if defined($self->$arg);

    }

    $self->{'events'}   = XAS::Lib::POE::PubSub->new();
    $self->{'rabbit'}   = XAS::Metrics::RabbitMQ->new(\@args);
    $self->{'datetime'} = DateTime->new();

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

Copyright (c) 2012-2016 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
