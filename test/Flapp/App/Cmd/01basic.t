use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../../lib");
use lib Cwd::abs_path("$FindBin::Bin/../../../../generate/MyProject/lib");
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
    'cp %path %path',
    Cwd::abs_path($FindBin::Bin).'/tlib/X.pm',
    "$cmdt/lib/MyProject/MyCmdTest/Controller",
);
$os->rm_rf($proj->config->log_dir);

my $DTP = qr/\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\ \d+/;
my $LOG = $proj->config->log_dir.'/'.$proj->now->ymd.'_MyCmdTest';
my $HOST = '@'.$proj->hostname.'.log';

{ #args
    is $os->qx('%path/run.pl X::args X=1 Y=0 Z 2>&1', $cmdt), q{[*] X::args BEGIN
[+] {X => 1,Y => 0}
[+] ['X=1','Y=0','Z']
[*] X::args END successfully

};
    
    my $log = "$LOG-X-args$HOST";
    $os->cat(my $buf, '<', $log) || die "$!($log)";
    like $buf, qr/^\[\*\] $DTP X::args BEGIN
\[\+\] $DTP {X => 1,Y => 0}
\[\+\] $DTP \['X=1','Y=0','Z'\]
\[\*\] $DTP X::args END successfully

\z/;
    $os->unlink($log);
}

{ #logtest
    is $os->qx('%path/run.pl X::logtest 2>&1', $cmdt), "[*] X::logtest BEGIN
[+] あ
[+] \nあ
[+] \nあ\n
[+] \n
[+] あ
 - あ
[+] \nあ
 - \nあ
[+] \nあ\n
 - \nあ\n
[+] \n
 - \n
[*] X::logtest END successfully

";
    
    my $log = "$LOG-X-logtest$HOST";
    $os->cat(my $buf, '<', $log) || die "$!($log)";
    like $buf, qr/^\[\*\] $DTP X::logtest BEGIN
\[\+\] $DTP あ
\[\+\] $DTP \\nあ
\[\+\] $DTP \\nあ\\n
\[\+\] $DTP \\n
\[\+\] $DTP あ
 - あ
\[\+\] $DTP \\nあ
 - \\nあ
\[\+\] $DTP \\nあ\\n
 - \\nあ\\n
\[\+\] $DTP \\n
 - \\n
\[\*\] $DTP X::logtest END successfully

\z/;
    $os->unlink($log);
}

{ #warntest
    my $qx = $os->qx('%path/run.pl X::warntest 2>&1', $cmdt);
    like $qx, qr/^\[\*\] X::warntest BEGIN
\[\+\] あ
\[\?\] あ\n at .+
\[\+\] \nあ
\[\?\] \nあ\n at .+
\[\+\] \nあ\n
\[\?\] \nあ\n at .+
\[\+\] \n
\[\?\] \n at .+
\[\?\] X::warntest END with warning

\z/s;
    
    my $log = "$LOG-X-warntest$HOST";
    $os->cat(my $buf, '<', $log) || die "$!($log)";
    like $buf, qr/^\[\*\] $DTP X::warntest BEGIN
\[\+\] $DTP あ
\[\?\] $DTP あ\\n at __WARN__.+
\[\+\] $DTP \\nあ
\[\?\] $DTP \\nあ\\n at __WARN__.+
\[\+\] $DTP \\nあ\\n
\[\?\] $DTP \\nあ\\n at __WARN__.+
\[\+\] $DTP \\n
\[\?\] $DTP \\n at __WARN__.+
\[\?\] $DTP X::warntest END with warning

\z/;
    $os->unlink($log);
}

{ #dietest1
    my $qx = $os->qx('%path/run.pl X::dietest1 2>&1', $cmdt);
    #print $qx;
    like $qx, qr/^\[\*\] X::dietest1 BEGIN
\[\+\] あ
\[\?\] あ\n at __WARN__.+
\[\!\] あ\n at __DIE__.+
\[\!\] X::dietest1 END with die

\z/s;
    my $log = "$LOG-X-dietest1$HOST";
    $os->cat(my $buf, '<', $log) || die "$!($log)";
    like $buf, qr/^\[\*\] $DTP X::dietest1 BEGIN
\[\+\] $DTP あ
\[\?\] $DTP あ\\n at __WARN__.+
\[\!\] $DTP あ\\n at __DIE__.+
\[\!\] $DTP X::dietest1 END with die

\z/;
    $os->unlink($log);
}

{ #dietest2
    my $qx = $os->qx('%path/run.pl X::dietest2 2>&1', $cmdt);
    #print $qx;
    like $qx, qr/^\[\*\] X::dietest2 BEGIN
\[\+\] あ\n
\[\?\] あ\n at __WARN__.+
\[\!\] あ\n at __DIE__.+
\[\!\] X::dietest2 END with die

\z/s;
    my $log = "$LOG-X-dietest2$HOST";
    $os->cat(my $buf, '<', $log) || die "$!($log)";
    like $buf, qr/^\[\*\] $DTP X::dietest2 BEGIN
\[\+\] $DTP あ\\n
\[\?\] $DTP あ\\n at __WARN__.+
\[\!\] $DTP あ\\n at __DIE__.+
\[\!\] $DTP X::dietest2 END with die

\z/;
    $os->unlink($log);
}

$os->rm_rf($cmdt);
$os->rm_rf($proj->config->log_dir);
$os->rm_rf($proj->project_root.'/tmp/apps');
