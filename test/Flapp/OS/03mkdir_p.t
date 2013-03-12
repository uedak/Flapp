use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../lib") =~ /(.+)/ && $1;
use lib Cwd::abs_path("$FindBin::Bin/../../../generate/MyProject/lib") =~ /(.+)/ && $1;
use strict;
use warnings;

use MyProject;
my $proj = 'MyProject';
$proj->begin;

ok my $os = $proj->OS;

my $cwd = Cwd::getcwd;
chdir($FindBin::Bin) || die "$!($FindBin::Bin)";
{
    my $foo = "$FindBin::Bin/foo";
    my $bar = "$FindBin::Bin/foo/bar";
    
    $os->mkdir_p($bar) || die "$!($bar)";
    ok (-d $bar && $os->rm_rf($foo));
    
    $bar = "$FindBin::Bin/foo/bar/";
    $os->mkdir_p($bar) || die "$!($bar)";
    ok (-d $bar && $os->rm_rf($foo));
    
    $bar = "foo/bar";
    $os->mkdir_p($bar) || die "$!($bar)";
    ok (-d $bar && $os->rm_rf($foo));
    
    $bar = "foo/bar/";
    $os->mkdir_p($bar) || die "$!($bar)";
    ok (-d $bar && $os->rm_rf($foo));
}
chdir($cwd) || die "$!($cwd)";
