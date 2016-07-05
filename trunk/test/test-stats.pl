use lib '../lib';

package XAS::Apps::Metrics::Stats;

our $VERSION = '0.01';

use XAS::Metrics::Mpstat;
use XAS::Metrics::Pidstat;
use XAS::Metrics::Iostat;
use XAS::Metrics::Spooler;
use XAS::Metrics::Netstat;
use XAS::Metrics::Netstat::TCP;
use XAS::Metrics::Netstat::RAW;
use XAS::Metrics::Netstat::UDP;
use XAS::Metrics::Iostat::Extended;

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'XAS::Lib::App::Service',
  filesystem => 'Dir File',
  vars => {
    SERVICE_NAME         => 'XAS_METRICS',
    SERVICE_DISPLAY_NAME => 'XAS Metrics',
    SERVICE_DESCRIPTION  => 'Collect system metrics',
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub setup {
    my $self = shift;

    XAS::Metrics::Spooler->new(
        -alias     => 'metrics-spooler',
        -directory => Dir('metrics'),
    );

    $self->service->register('metrics-spooler');

    XAS::Metrics::Pidstat->new(
        -service   => $self->service,
        -connector => 'metrics-spooler',
    );

    XAS::Metrics::Mpstat->new(
        -service   => $self->service,
        -connector => 'metrics-spooler',
    );

    XAS::Metrics::Iostat->new(
        -service   => $self->service,
        -connector => 'metrics-spooler',
    );

    XAS::Metrics::Iostat::Extended->new(
        -service   => $self->service,
        -connector => 'metrics-spooler',
    );

    # XAS::Metrics::Netstat->new(
    #     -service   => $self->service,
    #     -connector => 'metrics-spooler',
    # );

    # XAS::Metrics::Netstat::TCP->new(
    #     -service   => $self->service,
    #     -connector => 'metrics-spooler',
    # );
    
    # XAS::Metrics::Netstat::RAW->new(
    #     -service   => $self->service,
    #     -connector => 'metrics-spooler',
    # );

    # XAS::Metrics::Netstat::UDP->new(
    #     -service   => $self->service,
    #     -connector => 'metrics-spooler',
    # );

}

sub main {
    my $self = shift;

    $self->setup();

    $self->log->info_msg('startup');

    $self->service->run();

    $self->log->info_msg('shutdown');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

package main;

my $app = XAS::Apps::Metrics::Stats->new();
$app->run;

1;

__END__

=head1 NAME

XAS::Apps::xxxx - A class for the XAS environment

=head1 SYNOPSIS

 use XAS::Apps::xxxx ;

 my $app = XAS::Apps::xxxx->new(
     -throws   => 'changeme',
     -priority => 'low',
     -facility => 'systems',
 );

 exit $app->run();

=head1 DESCRIPTION

=head1 CONFIGURATION

The configuration file uses the familiar Windows .ini format. It has the 
following stanza.

 [xxxx: xxxx]
 property = value

Where the section header "xxxx:" may have addtional qualifiers and repeated
as many times as needed. These qualifiers must be unique.

The following properties may be used.

=over 4

=item B<property>

=back

=head1 METHODS

=head2 setup

This method will configure the process.

=head2 main

This method will start the processing. 

=head2 options

This method provides these additonal cli options. 

=over 4

=back

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
