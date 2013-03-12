package Z::Foo::Bar;
use Z qw/-b Z::Foo -i Y::Foo::Bar/;
use strict;
use warnings;

sub foo { __PACKAGE__.'->'.shift->SUPER::foo }
sub bar { (sub{ __PACKAGE__.'->'.shift->SUPER::bar })->(@_) }
sub baz { my $p = shift; (sub{ __PACKAGE__.'->'.$p->SUPER::baz })->() }
sub p1 { __PACKAGE__ }

1;
