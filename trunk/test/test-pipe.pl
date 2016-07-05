
use XAS::Lib::Pipe;
use Badger::Filesystem 'File';

my $pipe = XAS::Lib::Pipe->new(
    -fifo => File('/var/lib/xas/nmon')
);

$pipe->run;
  