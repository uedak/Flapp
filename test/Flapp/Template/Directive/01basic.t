use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../../lib");
use lib Cwd::abs_path("$FindBin::Bin/../../../../generate/MyProject/lib");
use strict;
use warnings;

use MyProject;
ok my $p = MyProject->Template->Parser->new;
MyProject->begin;

ok !eval{ $p->parse(\'[% ELSE %]') };
like $@, qr/^No directive "IF"\n at \[% ELSE \(\? 1\)\n/;
