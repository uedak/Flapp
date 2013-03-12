use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib "$FindBin::Bin/tlib";
use lib Cwd::abs_path("$FindBin::Bin/../../../../lib");
use strict;
use warnings;

use X;
ok my $x = 'X';
is $x->foo, ,'foo';
eval{ $x->bar };
like $@, qr/X\Wbar\.pm did not return a code ref at .*01basic\.t line \d+/;

eval{ $x->baz };
like $@, qr/^Can't locate object method "baz" via package "X" at .*01basic\.t line \d+/;

use Y;
ok my $y = 'Y';
is $y->foo, '[foo]';

eval{ $y->bar };
like $@, qr/X\Wbar\.pm did not return a code ref at .*01basic\.t line \d+/;

eval{ $y->baz };
like $@, qr/^Can't locate object method "baz" via package "Y" at .*01basic\.t line \d+/;

use Z;
is(Z->Foo, 'Z::Foo');
is(Z->Foo->bar, 'Z::Foo::bar');

is(Z->_caller('c1'), 'main(c1)');
is(Z->_caller2('c2'), 'main(c2)');
is(Z->_caller2('c3'), 'main(c3)');


use NoParent;
eval{ NoParent->foo };
like $@, qr/^Can't locate object method "foo" via package "NoParent" at .*NoParent\.pm line \d+/;
