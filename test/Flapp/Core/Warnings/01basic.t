use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib "$FindBin::Bin/tlib";
use lib Cwd::abs_path("$FindBin::Bin/../../../../lib");
use strict;
use warnings;

{
    my $w;
    local $::SIG{__WARN__} = sub{ $w = shift };
    require 'X.pm';
    like $w, qr/^Use of uninitialized value in concatenation \(\.\) or string at/;
}
