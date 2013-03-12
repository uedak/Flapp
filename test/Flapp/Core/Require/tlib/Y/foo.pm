package Y;
use strict;
use warnings;

sub{ '['.shift->SUPER::foo(@_).']' };
