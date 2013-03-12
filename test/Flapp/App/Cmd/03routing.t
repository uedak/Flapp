use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../../lib");
use lib Cwd::abs_path("$FindBin::Bin/../../../../generate/MyProject/lib");
use Encode;
use strict;
use warnings;

use MyProject;
ok my $proj = 'MyProject';
ok my $os = $proj->OS;
local $::ENV{FLAPP_ROOT} = Flapp->root_dir;

#setup
$os->system('perl %path/apps/Tool/run.pl generate CmdApp MyCmdTest', $proj->project_root);
my $cmdt = $proj->project_root.'/apps/MyCmdTest';

$os->system(
    'cp -rf %path %path %path %path',
    Cwd::abs_path($FindBin::Bin).'/tlib/Root.pm',
    Cwd::abs_path($FindBin::Bin).'/tlib/Foo.pm',
    Cwd::abs_path($FindBin::Bin).'/tlib/Bar',
    "$cmdt/lib/MyProject/MyCmdTest/Controller",
);
$os->rm_rf($proj->config->log_dir);

{
    like $os->qx('%path/run.pl', $cmdt), qr/^\[\*\] Root::index BEGIN\n/;
    like $os->qx('%path/run.pl foo', $cmdt), qr/^\[\*\] Root::foo BEGIN\n/;
    like $os->qx('%path/run.pl Foo', $cmdt), qr/^\[\*\] Foo::index BEGIN\n/;
    like $os->qx('%path/run.pl Foo::foo', $cmdt), qr/^\[\*\] Foo::foo BEGIN\n/;
    like $os->qx('%path/run.pl Bar::Baz', $cmdt), qr/^\[\*\] Bar::Baz::index BEGIN\n/;
    like $os->qx('%path/run.pl Bar::Baz::baz', $cmdt), qr/^\[\*\] Bar::Baz::baz BEGIN\n/;
}

$os->rm_rf($cmdt);
$os->rm_rf($proj->config->log_dir);
$os->rm_rf($proj->project_root.'/tmp/apps');
