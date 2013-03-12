use Test::More qw/no_plan/;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../lib") =~ /(.+)/ && $1;
use lib Cwd::abs_path("$FindBin::Bin/../../../generate/MyProject/lib") =~ /(.+)/ && $1;
use strict;
use warnings;

use MyProject;
is (MyProject->Mailer, 'MyProject::Mailer');
my $proj = 'MyProject';
$proj->begin;
ok -d(my $tmp = MyProject->Mailer->config->spool_dir);
my $dir = Cwd::abs_path("$FindBin::Bin/02sendmail");

{
    ok $proj->OS->sendmail(<<'_END_');
To: ＴＯ <to@te.st>
From: Ｆｒｏｍ <from@te.st>
Subject: Ｓｕｂｊｅｃｔ—‾∥－～￠￡￢

Ｈｅｌｌｏ　Ｗｏｒｌｄ！
—‾∥－～￠￡￢
_END_
    
    my $ls = $proj->OS->ls($tmp);
    is @$ls, 1;
    ok $proj->OS->cat(my $buf1, '<', "$tmp/$ls->[0]");
    ok $proj->OS->cat(my $buf2, '<', "$dir/test1.eml");
    is $buf1, $buf2;
    ok $proj->OS->unlink("$tmp/$ls->[0]");
}

if(eval{ require Plack }){
    my %att = (
        "$dir/test2.txt" => 'test2.txt',
        "$dir/test2.gif" => 'test2.gif',
    );
    ok $proj->OS->sendmail(<<'_END_', \%att);
To: ＴＯ <>
From: Ｆｒｏｍ <from@te.st>
Subject: Ｓｕｂｊｅｃｔ—‾∥－～￠￡￢

Ｈｅｌｌｏ　Ｗｏｒｌｄ！
—‾∥－～￠￡￢
_END_
    
    my $ls = $proj->OS->ls($tmp);
    is @$ls, 1;
    ok $proj->OS->cat(my $buf1, '<', "$tmp/$ls->[0]");
    $buf1 =~ s/(_NextPart_0\.)\d+/${1}0/g;
    ok $proj->OS->cat(my $buf2, '<', "$dir/test2.eml");
    is $buf1, $buf2;
    ok $proj->OS->unlink("$tmp/$ls->[0]");
}
