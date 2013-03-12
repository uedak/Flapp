use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib "$FindBin::Bin/tlib";
use lib Cwd::abs_path("$FindBin::Bin/../../../../lib");
use strict;
use warnings;

eval{ require 'X.pm' };
like $@, qr/^Global symbol "\$x" requires explicit package name/;
