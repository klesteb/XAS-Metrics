use strict;
use warnings;
use Data::Dumper;
#use XAS::Utils 'de_camel_case';

sub de_camel_case {
    my $s = shift;

    my $o;
    my @a = split('', $s);
    my $z = scalar(@a);

    for (my $x = 0; $x < $z; $x++) {

        if ($a[$x] =~ /[A-Z]/) {

            if ($x == 0) {

                $o .= lc($a[$x]);

            } else {

                $o .= '_' . lc($a[$x]);

            }

        } else {

            $o .= $a[$x];

        }

    }

    return $o;

}

my @fields = qw(aCamelCase OneTwo ThreeFour five_six seven Eight ninE TEN);
my @parsed = map { de_camel_case($_) } @fields;
warn Dumper(@parsed);

    
