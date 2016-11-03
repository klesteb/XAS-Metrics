package XAS::Apps::Metrics::Process ;

our $VERSION = '0.01';

use XAS::Metrics::Spooler;

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'XAS::Lib::App::Service',
  mixin      => 'XAS::Lib::Mixins::Configs',
  utils      => 'load_module trim dotid',
  accessors  => 'cfg',
  filesystem => 'Dir',
  vars => {
    SERVICE_NAME         => 'XAS_Metrics',
    SERVICE_DISPLAY_NAME => 'XAS Metrics',
    SERVICE_DESCRIPTION  => 'Collect system performance metrics',
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub setup {
    my $self = shift;

    my @sections = $self->cfg->Sections();

    my $spooler = XAS::Metrics::Spooler->new(
        -alias     => 'metrics-spooler',
        -directory => Dir('metrics'),
        -service   => $self->service,
    );

    $self->service->register('metrics-spooler');

    foreach my $section (@sections) {

        next if ($section !~ /^metrics:/);

        my @args    = ();
        my ($alias) = $section =~ /^metrics:(.*)/;
        my @params  = $self->cfg->Parameters($section);
        my $module  = $self->cfg->val($section, 'module');

        $alias = trim($alias);

        load_module($module);

        push(@args, '-alias', $alias);
        push(@args, '-service', $self->service);
        push(@args, '-connector', 'metrics-spooler');

        foreach my $param (@params) {

            next if ($param =~ /module/i);

            push(@args, "-$param", $self->cfg->val($section, $param));

        }

        $module->new(\@args);

        $self->service->register($alias);

    }

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

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->load_config();

    return $self;

}
      
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
