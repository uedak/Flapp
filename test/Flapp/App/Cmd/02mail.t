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
    'cp %path %path',
    Cwd::abs_path($FindBin::Bin).'/tlib/Mail.pm',
    "$cmdt/lib/MyProject/MyCmdTest/Controller",
);
$os->rm_rf($proj->config->log_dir);

my $DTP = qr/\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\ \d+/;
my $LOG = $proj->config->log_dir.'/'.$proj->now->ymd.'_MyCmdTest';
my $HOST = '@'.$proj->hostname.'.log';
my $MSD = $proj->config->Mailer->spool_dir;

{ #no_from
    $os->system('rm -f %path/*', $MSD);
    like $os->qx('%path/run.pl Mail::no_from 2>&1', $cmdt), qr/\[\*\] Mail::no_from BEGIN
\[\!\] No \$c->mail_from\n at __DIE__.+
\[\!\] Mail::no_from END with die

\z/s;

    my $log = "$LOG-Mail-no_from$HOST";
    $os->cat(my $buf, '<', $log) || die "$!($log)";
    like $buf, qr/^\[\*\] $DTP Mail::no_from BEGIN
\[\!\] $DTP No \$c->mail_from\\n at __DIE__.+
\[\!\] $DTP Mail::no_from END with die

\z/;
    $os->unlink($log);
    is_deeply $os->ls($MSD), [];
}

{ #MailTest1
    $os->system('rm -f %path/*', $MSD);
    my $qx = $os->qx('%path/run.pl Mail::mailtest 2>&1', $cmdt);
    #print $qx;
    
    my $log = "$LOG-Mail-mailtest$HOST";
    $os->cat(my $buf, '<', $log) || die "$!($log)";
    #print $buf;
    like $buf, qr/\[\*\] $DTP Mail::mailtest BEGIN
\[\+\] $DTP ok1
\[\+\] $DTP ok2
\[\+\] $DTP ok3
\[\*\] $DTP Mail::mailtest END successfully

/;
    $os->unlink($log);
    
    my $ls = $os->ls($MSD);
    is @$ls, 1;
    $os->cat($buf, '<', "$MSD/$ls->[0]");
    Encode::from_to($buf, 'jis', 'utf8');
    #print $buf;
    like $buf, qr%From: from\@test\.com
\QMIME-Version: 1.0\E
Subject: \[\*\] MyProject Mail::mailtest END successfully
To: success\@test\.com
Content-Type: text/plain; charset="iso-2022-jp"
Content-Transfer-Encoding: 7bit

\[\*\] $DTP Mail::mailtest BEGIN
\[\*\] $DTP Mail::mailtest END successfully

\z%;
    $os->system('rm -f %path/*', $MSD);
}

{ #MailTest2(warn)
    $os->system('rm -f %path/*', $MSD);
    my $qx = $os->qx('%path/run.pl Mail::mailtest warn=1 2>&1', $cmdt);
    #print $qx;
    
    my $log = "$LOG-Mail-mailtest$HOST";
    $os->cat(my $buf, '<', $log) || die "$!($log)";
    #print $buf;
    like $buf, qr/\[\*\] $DTP Mail::mailtest BEGIN
\[\+\] $DTP ok1
\[\?\] $DTP ほげ\\n at __WARN__.+
\[\+\] $DTP ok2
\[\+\] $DTP ok3
\[\?\] $DTP Mail::mailtest END with warning

/;
    $os->unlink($log);
    
    my $ls = $os->ls($MSD);
    is @$ls, 1;
    $os->cat($buf, '<', "$MSD/$ls->[0]");
    Encode::from_to($buf, 'jis', 'utf8');
    #print $buf;
    like $buf, qr%From: from\@test\.com
\QMIME-Version: 1.0\E
Subject: \[\?\] MyProject Mail::mailtest END with warning
To: warn\@test\.com
Content-Type: text/plain; charset="iso-2022-jp"
Content-Transfer-Encoding: 7bit

\[\*\] $DTP Mail::mailtest BEGIN
\[\?\] $DTP ほげ\\n at __WARN__.+
\[\?\] $DTP Mail::mailtest END with warning

\z%;
    $os->system('rm -f %path/*', $MSD);
}

{ #MailTest3(die)
    $os->system('rm -f %path/*', $MSD);
    my $qx = $os->qx('%path/run.pl Mail::mailtest die=1 2>&1', $cmdt);
    #print $qx;
    
    my $log = "$LOG-Mail-mailtest$HOST";
    $os->cat(my $buf, '<', $log) || die "$!($log)";
    #print $buf;
    like $buf, qr/\[\*\] $DTP Mail::mailtest BEGIN
\[\+\] $DTP ok1
\[\+\] $DTP ok2
\[\!\] $DTP ふが\\n at __DIE__.+
\[\!\] $DTP Mail::mailtest END with die

/;
    $os->unlink($log);
    
    my $ls = $os->ls($MSD);
    is @$ls, 1;
    $os->cat($buf, '<', "$MSD/$ls->[0]");
    Encode::from_to($buf, 'jis', 'utf8');
    #print $buf;
    like $buf, qr%From: from\@test\.com
\QMIME-Version: 1.0\E
Subject: \[\!\] MyProject Mail::mailtest END with die
To: die\@test\.com
Content-Type: text/plain; charset="iso-2022-jp"
Content-Transfer-Encoding: 7bit

\[\*\] $DTP Mail::mailtest BEGIN
\[\!\] $DTP ふが\\n at __DIE__.+
\[\!\] $DTP Mail::mailtest END with die

\z%;
    $os->system('rm -f %path/*', $MSD);
}

{ #MailTest4(warn+die)
    $os->system('rm -f %path/*', $MSD);
    my $qx = $os->qx('%path/run.pl Mail::mailtest warn=1 die=1 2>&1', $cmdt);
    #print $qx;
    
    my $log = "$LOG-Mail-mailtest$HOST";
    $os->cat(my $buf, '<', $log) || die "$!($log)";
    #print $buf;
    like $buf, qr/\[\*\] $DTP Mail::mailtest BEGIN
\[\+\] $DTP ok1
\[\?\] $DTP ほげ\\n at __WARN__.+
\[\+\] $DTP ok2
\[\!\] $DTP ふが\\n at __DIE__.+
\[\!\] $DTP Mail::mailtest END with die

/;
    $os->unlink($log);
    
    my $ls = $os->ls($MSD);
    is @$ls, 1;
    $os->cat($buf, '<', "$MSD/$ls->[0]");
    Encode::from_to($buf, 'jis', 'utf8');
    #print $buf;
    like $buf, qr%From: from\@test\.com
\QMIME-Version: 1.0\E
Subject: \[\!\] MyProject Mail::mailtest END with die
To: die\@test\.com
Content-Type: text/plain; charset="iso-2022-jp"
Content-Transfer-Encoding: 7bit

\[\*\] $DTP Mail::mailtest BEGIN
\[\?\] $DTP ほげ\\n at __WARN__.+
\[\!\] $DTP ふが\\n at __DIE__.+
\[\!\] $DTP Mail::mailtest END with die

\z%;
    $os->system('rm -f %path/*', $MSD);
}

$os->rm_rf($cmdt);
$os->rm_rf($proj->config->log_dir);
$os->rm_rf($proj->project_root.'/tmp/apps');
