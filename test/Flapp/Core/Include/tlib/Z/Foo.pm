package Z::Foo;
use Z qw/-b Y::Foo -r/;
use strict;
use warnings;

sub foo { __PACKAGE__.'->'.shift->SUPER::foo }
sub bar { (sub{ __PACKAGE__.'->'.shift->SUPER::bar })->(@_) }
sub baz { my $p = shift; (sub{ __PACKAGE__.'->'.$p->SUPER::baz })->() }
sub p1 { __PACKAGE__ }
sub p2 { __PACKAGE__ }
sub p3 { __PACKAGE__ }
sub p4 { __PACKAGE__ }

1;
