use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib "$FindBin::Bin/tlib";
use lib Cwd::abs_path("$FindBin::Bin/../../../../lib");
use strict;
use warnings;

use Z::Foo::Bar;
{
    is_deeply \@{Z::Foo::Bar::ISA}, ['Y::Foo::Bar::As::Z::Foo::Bar'];
    is_deeply \@{Y::Foo::Bar::As::Z::Foo::Bar::ISA}, ['X::Foo::Bar::As::Z::Foo::Bar'];
    is_deeply \@{X::Foo::Bar::As::Z::Foo::Bar::ISA}, ['Z::Foo'];
    is_deeply \@{Z::Foo::ISA}, ['Y::Foo'];
    is_deeply \@{Y::Foo::ISA}, ['X::Foo'];
    is_deeply \@{X::Foo::ISA}, [];
    
    no strict 'refs';
    my $pkg = 'Z::Foo::Bar';
    while($pkg){
        #print "#$pkg\n";
        $pkg = ${$pkg.'::ISA'}[0];
    }
}

is(Z::Foo::Bar->p1, 'Z::Foo::Bar');
is(Z::Foo::Bar->p2, 'Y::Foo::Bar');
is(Z::Foo::Bar->p3, 'X::Foo::Bar');
is(Z::Foo::Bar->p4, 'Z::Foo');
is(Z::Foo::Bar->p5, 'Y::Foo');
is(Z::Foo::Bar->p6, 'X::Foo');

is(Z::Foo::Bar->foo, 'Z::Foo::Bar->Y::Foo::Bar->X::Foo::Bar->Z::Foo->Y::Foo->X::Foo');
is(Z::Foo::Bar->bar, 'Z::Foo::Bar->Y::Foo::Bar->X::Foo::Bar->Z::Foo->Y::Foo->X::Foo');
is(Z::Foo::Bar->baz, 'Z::Foo::Bar->Y::Foo::Bar->X::Foo::Bar->Z::Foo->Y::Foo->X::Foo');

use X::Foo::Bar;
is(X::Foo::Bar->p1, 'X::Foo::Bar');
is(X::Foo::Bar->p2, 'X::Foo::Bar');
is(X::Foo::Bar->p3, 'X::Foo::Bar');
is(X::Foo::Bar->p4, 'X::Foo');
is(X::Foo::Bar->p5, 'X::Foo');
is(X::Foo::Bar->p6, 'X::Foo');
is(X::Foo::Bar->foo, 'X::Foo::Bar->X::Foo');

eval 'use F1';
like "$@", qr/^Can't include package "Z::Foo" \(having \@ISA and non-module\)/;
