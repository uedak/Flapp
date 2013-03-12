package Z;
use Flapp qw/-b Flapp -r/;
use strict;
use warnings;

sub _caller { scalar (caller)."($_[1])" }

1;
