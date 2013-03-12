use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib "$FindBin::Bin/tlib";
use lib Cwd::abs_path("$FindBin::Bin/../../../../lib");
use strict;
use warnings;

use Z2::Foo::Bar;
{
    is_deeply \@{Z2::Foo::Bar::ISA}, ['Y2::Foo::Bar::As::Z2::Foo::Bar'];
    is_deeply \@{Y2::Foo::Bar::As::Z2::Foo::Bar::ISA}, ['X2::Foo::Bar::As::Z2::Foo::Bar'];
    is_deeply \@{X2::Foo::Bar::As::Z2::Foo::Bar::ISA}, ['Z2::Foo'];
    is_deeply \@{Z2::Foo::ISA}, ['Y2::Foo'];
    is_deeply \@{Y2::Foo::ISA}, ['X2::Foo'];
    is_deeply \@{X2::Foo::ISA}, [];
    
    no strict 'refs';
    my $pkg = 'Z2::Foo::Bar';
    while($pkg){
        #print "#$pkg\n";
        $pkg = ${$pkg.'::ISA'}[0];
    }
}

is(Z2::Foo::Bar->p1, 'Z2::Foo::Bar');
is(Z2::Foo::Bar->p2, 'Y2::Foo::Bar');
is(Z2::Foo::Bar->p3, 'X2::Foo::Bar');
is(Z2::Foo::Bar->p4, 'Z2::Foo');
is(Z2::Foo::Bar->p5, 'Y2::Foo');
is(Z2::Foo::Bar->p6, 'X2::Foo');

is(Z2::Foo::Bar->foo, 'Z2::Foo::Bar->Y2::Foo::Bar->X2::Foo::Bar->Z2::Foo->Y2::Foo->X2::Foo');

use X2::Foo::Bar;
is(X2::Foo::Bar->p1, 'X2::Foo::Bar');
is(X2::Foo::Bar->p2, 'X2::Foo::Bar');
is(X2::Foo::Bar->p3, 'X2::Foo::Bar');
is(X2::Foo::Bar->p4, 'X2::Foo');
is(X2::Foo::Bar->p5, 'X2::Foo');
is(X2::Foo::Bar->p6, 'X2::Foo');
is(X2::Foo::Bar->foo, 'X2::Foo::Bar->X2::Foo');

eval{ X2->Foo->Bar->bar };
like $@, qr/^Can't require non-module ".+?" from module ".+?" at .*02require\.t line \d+/;
