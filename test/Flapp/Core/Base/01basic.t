use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib "$FindBin::Bin/tlib";
use lib Cwd::abs_path("$FindBin::Bin/../../../../lib");
use strict;
use warnings;

use Y;
{
    is_deeply \@{Y::ISA}, ['M::As::Y'];
    is_deeply \@{M::As::Y::ISA}, ['X'];
    is_deeply \@{X::ISA}, [];
    
    no strict 'refs';
    my $pkg = 'Y';
    while($pkg){
        #print "-> $pkg\n";
        $pkg = ${$pkg.'::ISA'}[0];
    }
}

use Z;
{
    is_deeply \@{Z::ISA}, ['M::As::Z'];
    is_deeply \@{M::As::Z::ISA}, ['X'];
    is_deeply \@{X::ISA}, [];
    
    no strict 'refs';
    my $pkg = 'Z';
    while($pkg){
        #print "-> $pkg\n";
        $pkg = ${$pkg.'::ISA'}[0];
    }
}
