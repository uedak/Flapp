use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../lib");
use lib Cwd::abs_path("$FindBin::Bin/../../../generate/MyProject/lib");
use strict;
use warnings;

use MyProject;
my $proj = 'MyProject';
is $proj->Util, 'MyProject::Util';

{
    my $x = {x => {y => ['z']}};
    my $y = $proj->Util->deep_copy($x);
    is_deeply $x, $y;
    isnt $x, my $y0 = $y;
    isnt $x->{x}, my $y0x = $y->{x};
    isnt $x->{x}{y}, my $y0xy = $y->{x}{y};
    
    my $z = $proj->Util->deep_copy($y);
    is_deeply $x, $y;
    is $y, $y0;
    is $y->{x}, $y0x;
    is $y->{x}{y}, $y0xy;
}

{
    my $x = {r => qr/./};
    my $y = $proj->Util->deep_copy($x);
    is_deeply $x, $y;
    isnt $x, $y;
    is $x->{r}, $y->{r};
}

{
    my $x = {x => bless({}, 'X')};
    my $y = $proj->Util->deep_copy($x);
    
    is_deeply $x, $y;
    isnt $x, $y;
    is ref $x->{x}, ref $y->{x};
    isnt $x->{x}, $y->{x};
}
