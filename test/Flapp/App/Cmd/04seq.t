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
    Cwd::abs_path($FindBin::Bin).'/tlib/Seq.pm',
    "$cmdt/lib/MyProject/MyCmdTest/Controller",
);
$os->rm_rf($proj->config->log_dir);

my $DTP = qr/\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\ \d+/;
my $LOG = $proj->config->log_dir.'/'.$proj->now->ymd.'_MyCmdTest';
my $HOST = '_'.$proj->hostname.'.log';
my $MSD = $proj->config->Mailer->spool_dir;

{
    my($so, $ls, $buf);
    is $os->qx('%path/run.pl Seq::seq1 2>&1', $cmdt), <<_END_;
[*] Seq::seq1 BEGIN
[*] Seq::run1 BEGIN
[*] Seq::run1 END successfully

[*] Seq::run2 BEGIN
[*] Seq::run2 END successfully

[*] Seq::run3 BEGIN
[*] Seq::run3 END successfully

[*] Seq::seq1 END successfully

_END_
    $ls = $os->ls($MSD);
    is @$ls, 1;
    $os->cat($buf, '<', "$MSD/$ls->[0]");
    like $buf, qr%From: from\@test\.com
\QMIME-Version: 1.0\E
Subject: \[\*\] MyProject Seq::seq1 END successfully
To: success\@test\.com
Content-Type: text/plain; charset="iso-2022-jp"
Content-Transfer-Encoding: 7bit

\[\*\] $DTP Seq::seq1 BEGIN
\[\*\] $DTP Seq::run1 BEGIN
\[\*\] $DTP Seq::run1 END successfully
\[\*\] $DTP Seq::run2 BEGIN
\[\*\] $DTP Seq::run2 END successfully
\[\*\] $DTP Seq::run3 BEGIN
\[\*\] $DTP Seq::run3 END successfully
\[\*\] $DTP Seq::seq1 END successfully

\z%;
    $os->system('rm -f %path/*', $MSD);
    
    
    
    ($so = $os->qx('%path/run.pl Seq::seq1 WARN=1 2>&1', $cmdt)) =~ s/^ at .+\n//mg;
    is $so, <<_END_;
[*] Seq::seq1 BEGIN
[*] Seq::run1 BEGIN
[*] Seq::run1 END successfully

[*] Seq::run2 BEGIN
[?] ?

[?] Seq::run2 END with warning

[*] Seq::run3 BEGIN
[*] Seq::run3 END successfully

[?] Seq::seq1 END with warning

_END_
    $ls = $os->ls($MSD);
    is @$ls, 1;
    $os->cat($buf, '<', "$MSD/$ls->[0]");
    like $buf, qr%From: from\@test\.com
\QMIME-Version: 1.0\E
Subject: \[\?\] MyProject Seq::seq1 END with warning
To: warn\@test\.com
Content-Type: text/plain; charset="iso-2022-jp"
Content-Transfer-Encoding: 7bit

\[\*\] $DTP Seq::seq1 BEGIN
\[\*\] $DTP Seq::run1 BEGIN
\[\*\] $DTP Seq::run1 END successfully
\[\*\] $DTP Seq::run2 BEGIN
\[\?\] $DTP \?\\n at __WARN__.+
\[\?\] $DTP Seq::run2 END with warning
\[\*\] $DTP Seq::run3 BEGIN
\[\*\] $DTP Seq::run3 END successfully
\[\?\] $DTP Seq::seq1 END with warning

\z%;
    $os->system('rm -f %path/*', $MSD);
    
    
    
    ($so = $os->qx('%path/run.pl Seq::seq1 DIE=1 2>&1', $cmdt)) =~ s/^ at .+\n//mg;
    is $so, <<_END_;
[*] Seq::seq1 BEGIN
[*] Seq::run1 BEGIN
[*] Seq::run1 END successfully

[*] Seq::run2 BEGIN
[!] !

[!] Seq::run2 END with die
[!] Seq::seq1 END with die

_END_
    $ls = $os->ls($MSD);
    is @$ls, 1;
    $os->cat($buf, '<', "$MSD/$ls->[0]");
    like $buf, qr%From: from\@test\.com
\QMIME-Version: 1.0\E
Subject: \[\!\] MyProject Seq::seq1 END with die
To: die\@test\.com
Content-Type: text/plain; charset="iso-2022-jp"
Content-Transfer-Encoding: 7bit

\[\*\] $DTP Seq::seq1 BEGIN
\[\*\] $DTP Seq::run1 BEGIN
\[\*\] $DTP Seq::run1 END successfully
\[\*\] $DTP Seq::run2 BEGIN
\[\!\] $DTP \!\\n at __DIE__.+
\[\!\] $DTP Seq::run2 END with die
\[\!\] $DTP Seq::seq1 END with die

\z%;
    $os->system('rm -f %path/*', $MSD);
    
    
    
    ($so = $os->qx('%path/run.pl Seq::seq1 FORK=1 WARN=1 2>&1', $cmdt)) =~ s/^ at .+\n//mg;
    is $so, <<_END_;
[*] Seq::seq1 BEGIN
[*] Seq::run1 BEGIN
[*] Seq::run1 END successfully

[*] Seq::run2 BEGIN
[?] ?

[?] Seq::run2 END with warning

[*] Seq::run3 BEGIN
[*] Seq::run3 END successfully

[?] Seq::seq1 END with warning

_END_
    $ls = $os->ls($MSD);
    is @$ls, 1;
    $os->cat($buf, '<', "$MSD/$ls->[0]");
    like $buf, qr%From: from\@test\.com
\QMIME-Version: 1.0\E
Subject: \[\?\] MyProject Seq::seq1 END with warning
To: warn\@test\.com
Content-Type: text/plain; charset="iso-2022-jp"
Content-Transfer-Encoding: 7bit

\[\*\] $DTP Seq::seq1 BEGIN
\[\*\] $DTP Seq::run1 BEGIN
\[\*\] $DTP Seq::run1 END successfully
\[\*\] $DTP Seq::run2 BEGIN
\[\?\] $DTP->\d+ \?\\n at __WARN__.+
\[\?\] $DTP Seq::run2 END with warning
\[\*\] $DTP Seq::run3 BEGIN
\[\*\] $DTP Seq::run3 END successfully
\[\?\] $DTP Seq::seq1 END with warning

\z%;
    $os->system('rm -f %path/*', $MSD);
    
    
    
    ($so = $os->qx('%path/run.pl Seq::seq1 FORK=1 DIE=1 2>&1', $cmdt)) =~ s/^ at .+\n//mg;
    is $so, <<_END_;
[*] Seq::seq1 BEGIN
[*] Seq::run1 BEGIN
[*] Seq::run1 END successfully

[*] Seq::run2 BEGIN
[!] !

[!] Seq::run2 END with die
[!] Seq::seq1 END with die

_END_
    $ls = $os->ls($MSD);
    is @$ls, 1;
    $os->cat($buf, '<', "$MSD/$ls->[0]");
    like $buf, qr%From: from\@test\.com
\QMIME-Version: 1.0\E
Subject: \[\!\] MyProject Seq::seq1 END with die
To: die\@test\.com
Content-Type: text/plain; charset="iso-2022-jp"
Content-Transfer-Encoding: 7bit

\[\*\] $DTP Seq::seq1 BEGIN
\[\*\] $DTP Seq::run1 BEGIN
\[\*\] $DTP Seq::run1 END successfully
\[\*\] $DTP Seq::run2 BEGIN
\[\!\] $DTP->\d+ \!\\n at __DIE__.+
\[\!\] $DTP Seq::run2 END with die
\[\!\] $DTP Seq::seq1 END with die

\z%;
    $os->system('rm -f %path/*', $MSD);
}



{
    my($so, $ls, $buf);
    is $os->qx('%path/run.pl Seq::seq2 2>&1', $cmdt), <<_END_;
[*] Seq::seq2 BEGIN
[*] Seq::run1 BEGIN
[*] Seq::run1 END successfully

[*] Seq::run2 BEGIN
[*] Seq::run2 END successfully

[*] Seq::run3 BEGIN
[*] Seq::run3 END successfully

[*] Seq::seq2 END successfully

_END_
    $ls = $os->ls($MSD);
    is @$ls, 1;
    $os->cat($buf, '<', "$MSD/$ls->[0]");
    like $buf, qr%From: from\@test\.com
\QMIME-Version: 1.0\E
Subject: \[\*\] MyProject Seq::seq2 END successfully
To: success\@test\.com
Content-Type: text/plain; charset="iso-2022-jp"
Content-Transfer-Encoding: 7bit

\[\*\] $DTP Seq::seq2 BEGIN
\[\*\] $DTP Seq::run1 BEGIN
\[\*\] $DTP Seq::run1 END successfully
\[\*\] $DTP Seq::run2 BEGIN
\[\*\] $DTP Seq::run2 END successfully
\[\*\] $DTP Seq::run3 BEGIN
\[\*\] $DTP Seq::run3 END successfully
\[\*\] $DTP Seq::seq2 END successfully

\z%;
    $os->system('rm -f %path/*', $MSD);
    
    
    
    ($so = $os->qx('%path/run.pl Seq::seq2 WARN=1 2>&1', $cmdt)) =~ s/^ at .+\n//mg;
    is $so, <<_END_;
[*] Seq::seq2 BEGIN
[*] Seq::run1 BEGIN
[*] Seq::run1 END successfully

[*] Seq::run2 BEGIN
[?] ?

[?] Seq::run2 END with warning

[*] Seq::run3 BEGIN
[*] Seq::run3 END successfully

[?] Seq::seq2 END with warning

_END_
    $ls = $os->ls($MSD);
    is @$ls, 1;
    $os->cat($buf, '<', "$MSD/$ls->[0]");
    like $buf, qr%From: from\@test\.com
\QMIME-Version: 1.0\E
Subject: \[\?\] MyProject Seq::seq2 END with warning
To: warn\@test\.com
Content-Type: text/plain; charset="iso-2022-jp"
Content-Transfer-Encoding: 7bit

\[\*\] $DTP Seq::seq2 BEGIN
\[\*\] $DTP Seq::run1 BEGIN
\[\*\] $DTP Seq::run1 END successfully
\[\*\] $DTP Seq::run2 BEGIN
\[\?\] $DTP->\d+ \?\\n at __WARN__.+
\[\?\] $DTP Seq::run2 END with warning
\[\*\] $DTP Seq::run3 BEGIN
\[\*\] $DTP Seq::run3 END successfully
\[\?\] $DTP Seq::seq2 END with warning

\z%;
    $os->system('rm -f %path/*', $MSD);
    
    
    
    ($so = $os->qx('%path/run.pl Seq::seq2 DIE=1 2>&1', $cmdt)) =~ s/^ at .+\n//mg;
    is $so, <<_END_;
[*] Seq::seq2 BEGIN
[*] Seq::run1 BEGIN
[*] Seq::run1 END successfully

[*] Seq::run2 BEGIN
[!] !

[!] Seq::run2 END with die
[!] Seq::seq2 END with die

_END_
    $ls = $os->ls($MSD);
    is @$ls, 1;
    $os->cat($buf, '<', "$MSD/$ls->[0]");
    like $buf, qr%From: from\@test\.com
\QMIME-Version: 1.0\E
Subject: \[\!\] MyProject Seq::seq2 END with die
To: die\@test\.com
Content-Type: text/plain; charset="iso-2022-jp"
Content-Transfer-Encoding: 7bit

\[\*\] $DTP Seq::seq2 BEGIN
\[\*\] $DTP Seq::run1 BEGIN
\[\*\] $DTP Seq::run1 END successfully
\[\*\] $DTP Seq::run2 BEGIN
\[\!\] $DTP->\d+ \!\\n at __DIE__.+
\[\!\] $DTP Seq::run2 END with die
\[\!\] $DTP Seq::seq2 END with die

\z%;
    $os->system('rm -f %path/*', $MSD);
    
    
    
    ($so = $os->qx('%path/run.pl Seq::seq2 FORK=1 WARN=1 2>&1', $cmdt)) =~ s/^ at .+\n//mg;
    is $so, <<_END_;
[*] Seq::seq2 BEGIN
[*] Seq::run1 BEGIN
[*] Seq::run1 END successfully

[*] Seq::run2 BEGIN
[?] ?

[?] Seq::run2 END with warning

[*] Seq::run3 BEGIN
[*] Seq::run3 END successfully

[?] Seq::seq2 END with warning

_END_
    $ls = $os->ls($MSD);
    is @$ls, 1;
    $os->cat($buf, '<', "$MSD/$ls->[0]");
    like $buf, qr%From: from\@test\.com
\QMIME-Version: 1.0\E
Subject: \[\?\] MyProject Seq::seq2 END with warning
To: warn\@test\.com
Content-Type: text/plain; charset="iso-2022-jp"
Content-Transfer-Encoding: 7bit

\[\*\] $DTP Seq::seq2 BEGIN
\[\*\] $DTP Seq::run1 BEGIN
\[\*\] $DTP Seq::run1 END successfully
\[\*\] $DTP Seq::run2 BEGIN
\[\?\] $DTP->\d+ \?\\n at __WARN__.+
\[\?\] $DTP Seq::run2 END with warning
\[\*\] $DTP Seq::run3 BEGIN
\[\*\] $DTP Seq::run3 END successfully
\[\?\] $DTP Seq::seq2 END with warning

\z%;
    $os->system('rm -f %path/*', $MSD);
    
    
    
    ($so = $os->qx('%path/run.pl Seq::seq2 FORK=1 DIE=1 2>&1', $cmdt)) =~ s/^ at .+\n//mg;
    is $so, <<_END_;
[*] Seq::seq2 BEGIN
[*] Seq::run1 BEGIN
[*] Seq::run1 END successfully

[*] Seq::run2 BEGIN
[!] !

[!] Seq::run2 END with die
[!] Seq::seq2 END with die

_END_
    $ls = $os->ls($MSD);
    is @$ls, 1;
    $os->cat($buf, '<', "$MSD/$ls->[0]");
    like $buf, qr%From: from\@test\.com
\QMIME-Version: 1.0\E
Subject: \[\!\] MyProject Seq::seq2 END with die
To: die\@test\.com
Content-Type: text/plain; charset="iso-2022-jp"
Content-Transfer-Encoding: 7bit

\[\*\] $DTP Seq::seq2 BEGIN
\[\*\] $DTP Seq::run1 BEGIN
\[\*\] $DTP Seq::run1 END successfully
\[\*\] $DTP Seq::run2 BEGIN
\[\!\] $DTP->\d+ \!\\n at __DIE__.+
\[\!\] $DTP Seq::run2 END with die
\[\!\] $DTP Seq::seq2 END with die

\z%;
    $os->system('rm -f %path/*', $MSD);
}

$os->rm_rf($cmdt);
$os->rm_rf($proj->config->log_dir);
$os->rm_rf($proj->project_root.'/tmp/apps');
