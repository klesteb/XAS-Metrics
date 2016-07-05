use strict;
use warnings;

use Data::Dumper;
use XAS::Utils 'bash_escape';
    
#my $command = bash_escape("../sbin/xas-runcmd --interval 60 --duration 3600 \"netstat -i\"");
my $command = "../sbin/xas-runcmd --interval 60 --duration 3600 \"netstat -i\"";
warn $command;

my @argv = parse_command_line($command);
warn Dumper(@argv);

sub parse_command_line {
    my $str = shift;

    $str =~ s/\A\s+//ms;
    $str =~ s/\s+\z//ms;

    my @argv;
    my $buf;
    my $escaped;
    my $double_quoted;
    my $single_quoted;

    for my $char (split //, $str) {
        if ($escaped) {
            $buf .= $char;
            $escaped = undef;
            next;
        }

        if ($char eq '\\') {
            if ($single_quoted) {
                $buf .= $char;
            }
            else {
                $escaped = 1;
            }
            next;
        }

        if ($char =~ /\s/) {
            if ($single_quoted || $double_quoted) {
                $buf .= $char;
            }
            else {
                push @argv, $buf if defined $buf;
                undef $buf;
            }
            next;
        }

        if ($char eq '"') {
            if ($single_quoted) {
                $buf .= $char;
                next;
            }
            $double_quoted = !$double_quoted;
            next;
        }

        if ($char eq "'") {
            if ($double_quoted) {
                $buf .= $char;
                next;
            }
            $single_quoted = !$single_quoted;
            next;
        }

        $buf .= $char;
    }
    push @argv, $buf if defined $buf;

    if ($escaped || $single_quoted || $double_quoted) {
        die 'invalid command line string';
    }

    @argv;
}
