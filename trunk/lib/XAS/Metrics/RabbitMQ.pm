package XAS::Metrics::RabbitMQ;

our $VERSION = '0.01';

use JSON;
use Badger::URL;
use HTTP::Request;

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Lib::Curl::HTTP',
  utils     => ':validation dotid',
  accessors => 'url json',
  constants => 'TRUE FALSE',
  vars => {
    PARAMS => {
      -url => { optional => 1, default => 'http://localhost:15672/' },
    }
  }
;

use Data::Dumper;

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub alive {
    my $self = shift;
    my ($vhost) = validate_params(\@_, [
        { opitional => 1, default => '%2f' }
    ]);

    my $data;
    my $request;
    my $stat = FALSE;
    my $path = sprintf('/api/aliveness-test/%s', $vhost);

    $self->url->path($path);

    $request = HTTP::Request->new(GET => $self->url->text);
    $data = $self->_make_call($request);

    if ($data->{'status'} =~ /ok/i) {

        $stat = TRUE;

    }

    return $stat;

}

sub whoami {
    my $self = shift;

    my $data;
    my $request;
    my $path = '/api/whoami';

    $self->url->path($path);

    $request = HTTP::Request->new(GET => $self->url->text);
    $data = $self->_make_call($request);

    return $data;

}

sub overview {
    my $self = shift;

    my $data;
    my $request;
    my $path = '/api/overview';

    $self->url->path($path);

    $request = HTTP::Request->new(GET => $self->url->text);
    $data = $self->_make_call($request);

    return $data;

}

sub cluster_name {
    my $self = shift;

    my $data;
    my $request;
    my $path = '/api/cluster-name';

    $self->url->path($path);

    $request = HTTP::Request->new(GET => $self->url->text);
    $data = $self->_make_call($request);

    return $data;

}

sub definitions {
    my $self = shift;

    my $data;
    my $request;
    my $path = '/api/definitions';

    $self->url->path($path);

    $request = HTTP::Request->new(GET => $self->url->text);
    $data = $self->_make_call($request);

    return $data;

}

sub nodes {
    my $self = shift;
    my ($name) = validate_params(\@_, [
        { opitional => 1, default => undef }
    ]);

    my $data;
    my $request;
    my $path = '/api/nodes';

    $path = sprintf('%s/%s', $path, $name) if (defined($name));

    $self->url->path($path);

    $request = HTTP::Request->new(GET => $self->url->text);
    $data = $self->_make_call($request);

    return $data;

}

sub connections {
    my $self = shift;
    my $p = validate_params(\@_, {
        -name    => { optional => 1, default => undef },
        -channel => { optional => 1, default => FALSE, depends => [ '-name' ] },
    });

    my $name    = $p->{'-name'};
    my $channel = $p->{'-channel'};

    my $data;
    my $request;
    my $path = '/api/connections';

    $path = sprintf('%s/%s', $path, $name) if (defined($name));
    $path = sprintf('%s/channels', $path)  if ($channel);

    $self->url->path($path);

    $request = HTTP::Request->new(GET => $self->url->text);
    $data = $self->_make_call($request);

    return $data;

}

sub channels {
    my $self = shift;
    my ($name) = validate_params(\@_, [
        { optional => 1, default => undef },
    ]);

    my $data;
    my $request;
    my $path = '/api/channels';

    $path = sprintf('%s/%s', $path, $name) if (defined($name));

    $self->url->path($path);

    $request = HTTP::Request->new(GET => $self->url->text);
    $data = $self->_make_call($request);

    return $data;

}

sub exchanges {
    my $self = shift;
    my $p = validate_params(\@_, {
        -vhost  => { optional => 1, default => undef },
        -name   => { optional => 1, default => undef, depends => ['-vhost'] },
        -source => { optional => 1, default => FALSE, depends => ['-name','-vhost'] },
        -destination => { optional => 1, default => FALSE, depends => ['-name','-vhost'] },
    });

    my $name   = $p->{'-name'};
    my $vhost  = $p->{'-vhost'};
    my $source = $p->{'-source'};
    my $dest   = $p->{'-destination'};

    my $data;
    my $request;
    my $path = '/api/exchanges';

    if ($source && $dest) {

        $self->throw_msg(
            dotid($self->class) . '.invparams',
            'invparams',
            'using -source and -destination together is not valid'
        );

    }

    if ($source) {

        $path = sprintf('%s/%s/%s/bindings/source', $path, $vhost, $name);

    } elsif ($dest) {

        $path = sprintf('%s/%s/%s/bindings/destination', $path, $vhost, $name);

    } elsif (defined($name)) {

        $path = sprintf('%s/%s/%s', $path, $vhost, $name);

    } elsif (defined($vhost)) {

        $path = sprintf('%s/%s', $path, $vhost);

    }

    $self->url->path($path);

    $request = HTTP::Request->new(GET => $self->url->text);
    $data = $self->_make_call($request);

    return $data;

}

sub queues {
    my $self = shift;
    my $p = validate_params(\@_, {
        -vhost    => { optional => 1, default => undef },
        -name     => { optional => 1, default => undef, depends => ['-vhost'] },
        -bindings => { optional => 1, default => FALSE, depends => ['-name','-vhost'] },
    });

    my $name     = $p->{'-name'};
    my $vhost    = $p->{'-vhost'};
    my $bindings = $p->{'-source'};

    my $data;
    my $request;
    my $path = '/api/queues';

    if ($bindings) {

        $path = sprintf('%s/%s/%s/bindings', $path, $vhost, $name);

    } elsif (defined($name)) {

        $path = sprintf('%s/%s/%s', $path, $vhost, $name);

    } elsif (defined($vhost)) {

        $path = sprintf('%s/%s', $path, $vhost);

    }

    $self->url->path($path);

    $request = HTTP::Request->new(GET => $self->url->text);
    $data = $self->_make_call($request);

    return $data;

}

sub vhosts {
    my $self = shift;
    my $p = validate_params(\@_, {
        -name        => { optional => 1, default => undef },
        -permissions => { optional => 1, default => FALSE, depends => ['-name'] },
    });

    my $name        = $p->{'-name'};
    my $permissions = $p->{'-permissions'};

    my $data;
    my $request;
    my $path = '/api/vhosts';

    if ($permissions) {

        $path = sprintf('%s/%s/permissions', $path, $name);

    } elsif (defined($name)) {

        $path = sprintf('%s/%s', $path, $name);

    }

    $self->url->path($path);

    $request = HTTP::Request->new(GET => $self->url->text);
    $data = $self->_make_call($request);

    return $data;

}

sub users {
    my $self = shift;
    my $p = validate_params(\@_, {
        -name        => { optional => 1, default => undef },
        -permissions => { optional => 1, default => FALSE, depends => ['-name'] },
    });

    my $name        = $p->{'-name'};
    my $permissions = $p->{'-permissions'};

    my $data;
    my $request;
    my $path = '/api/users';

    if ($permissions) {

        $path = sprintf('%s/%s/permissions', $path, $name);

    } elsif (defined($name)) {

        $path = sprintf('%s/%s', $path, $name);

    }

    $self->url->path($path);

    $request = HTTP::Request->new(GET => $self->url->text);
    $data = $self->_make_call($request);

    return $data;

}

sub parameters {
    my $self = shift;
    my $p = validate_params(\@_, {
        -component => { optional => 1, default => undef },
        -vhost     => { optional => 1, default => undef, depends => ['-component'] },
        -name      => { optional => 1, default => undef, depends => ['-vhost','-component'] },
    });

    my $name      = $p->{'-name'};
    my $vhost     = $p->{'-vhost'};
    my $component = $p->{'-permissions'};

    my $data;
    my $request;
    my $path = '/api/parameters';

    if (defined($component)) {

        $path = sprintf('%s/%s', $path, $component);

    } elsif (defined($vhost)) {

        $path = sprintf('%s/%s/%s', $path, $component, $vhost);

    } elsif (defined($name)) {

        $path = sprintf('%s/%s/%s/%s', $path, $component, $vhost, $name);

    }

    $self->url->path($path);

    $request = HTTP::Request->new(GET => $self->url->text);
    $data = $self->_make_call($request);

    return $data;

}

sub permissions {
    my $self = shift;
    my $p = validate_params(\@_, {
        -vhost => { optional => 1, default => '%2f' },
        -name  => { optional => 1, default => undef },
    });

    my $name  = $p->{'-name'};
    my $vhost = $p->{'-vhost'};

    my $data;
    my $request;
    my $path = '/api/permissions';

    if (defined($name)) {

        $path = sprintf('%s/%s/%s', $path, $vhost, $name);

    }

    $self->url->path($path);

    $request = HTTP::Request->new(GET => $self->url->text);
    $data = $self->_make_call($request);

    return $data;

}

sub policies {
    my $self = shift;
    my $p = validate_params(\@_, {
        -vhost => { optional => 1, default => undef },
        -name  => { optional => 1, default => undef, depends => ['-vhost'] },
    });

    my $name  = $p->{'-name'};
    my $vhost = $p->{'-vhost'};

    my $data;
    my $request;
    my $path = '/api/policies';

    if (defined($name)) {

        $path = sprintf('%s/%s/%s', $path, $vhost, $name);

    } elsif (defined($vhost)) {

        $path = sprintf('%s/%s', $path, $vhost);

    }

    $self->url->path($path);

    $request = HTTP::Request->new(GET => $self->url->text);
    $data = $self->_make_call($request);

    return $data;

}

sub bindings {
    my $self = shift;
    my $p = validate_params(\@_, {
        -vhost    => { optional => 1, default => undef },
        -props    => { optional => 1, default => undef },
        -exchange => { optional => 1, default => undef, depends => ['-vhost'] },
        -queue    => { optional => 1, default => undef, depends => ['-exchange'] },
        -source   => { optional => 1, default => undef, depends => ['-vhost'] },
        -destination => { optional => 1, default => undef, depends => ['-source'] },
    });

    my $vhost       = $p->{'-vhost'};
    my $props       = $p->{'-props'};
    my $queue       = $p->{'-queue'};
    my $source      = $p->{'-source'};
    my $exchange    = $p->{'-exchange'};
    my $destination = $p->{'-destination'};

    my $data;
    my $request;
    my $path = '/api/bindings';

    if (defined($queue) && defined($destination)) {

        $self->throw_msg(
            dotid($self->class) . '.invparams',
            'invparams',
            'using -queue and -destination together is not valid'
        );

    }

    if (defined($vhost)) {

        $path = sprintf('%s/%s', $path, $vhost);

    } elsif (defined($queue)) {

        $path = sprintf('%s/%s/e/%s/q/%s', $path, $vhost, $exchange, $queue);

    } elsif (defined($queue) && defined($props)) {

        $path = sprintf('%s/%s/e/%s/q/%s/%s', $path, $vhost, $exchange, $queue, $props);

    } elsif (defined($destination)) {

        $path = sprintf('%s/%s/e/%s/e/%s', $path, $vhost, $source, $destination);

    } elsif (defined($destination) && defined($props)) {

        $path = sprintf('%s/%s/e/%s/e/%s/%s', $path, $vhost, $source, $destination, $props);

    }

    $self->url->path($path);

    $request = HTTP::Request->new(GET => $self->url->text);
    $data = $self->_make_call($request);

    return $data;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{'json'} = JSON->new->utf8();
    $self->{'url'}  = Badger::URL->new($self->url);

    return $self;

}

sub _make_call {
    my $self    = shift;
    my $request = shift;

    my $data;
    my $response;

    $request->header('Accept' => ['application/json']);
    $response = $self->request($request);

    if ($response->is_success) {

        $data = $self->json->decode($response->content);

    } else {

        $self->_error_msg($response);

    }

    return $data;

}

sub _error_msg {
    my $self     = shift;
    my $response = shift;

    $self->throw_msg(
        dotid($self->class) . '.http',
        'metrics_httperr',
        $response->code, $response->message
    );

}

1;

__END__

=head1 NAME

XAS::xxx - A class for the XAS environment

=head1 SYNOPSIS

 use XAS::XXX;

=head1 DESCRIPTION

=head1 METHODS

=head2 method1

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2016 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
