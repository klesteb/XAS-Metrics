use lib '../lib';

package XAS::Apps::Metrics::Nmon;

our $VERSION = '0.01';

use XAS::Metrics::Nmon;
use XAS::Metrics::Spooler;

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'XAS::Lib::App::Service',
  filesystem => 'Dir File',
  vars => {
    SERVICE_NAME         => 'XAS_NMON',
    SERVICE_DISPLAY_NAME => 'XAS Nmon Metrics',
    SERVICE_DESCRIPTION  => 'Collect system metrics with nmon',
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub setup {
    my $self = shift;

    my $spooler = XAS::Metrics::Spooler->new(
        -alias     => 'nmon-spooler',
        -service   => $self->service,
        -directory => Dir('metrics'),
    );

    my $nmon = XAS::Metrics::Nmon->new(
        -type      => 'xas-metrics-nmon',
        -service   => $self->service,
        -connector => 'nmon-spooler',
    );

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

my $app = XAS::Apps::Metrics::Nmon->new();
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
