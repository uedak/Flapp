use Test::More;
use Cwd;
use FindBin;
use lib Cwd::abs_path("$FindBin::Bin/../../../lib");
use lib Cwd::abs_path("$FindBin::Bin/../../../generate/MyProject/lib");
use lib Cwd::abs_path("$FindBin::Bin/tlib");
use MyProject qw/-s -w/;
use utf8;
$Flapp::UTF8 = 2;
use MyTest;
my $proj = 'MyProject';
my($DBH, $DBN) = MyTest->setup($proj);
ok $DBN;

eval{
    $proj->begin;
    ok my $dbh0 = $proj->dbh(Default => 0);
    ok my $dbh1 = $proj->dbh(Default => 1);
    is $dbh0->{private_flapp_dbh}[1], 0;
    is $dbh1->{private_flapp_dbh}[1], 1;
    $dbh0->do('CREATE TABLE test(id int)');
    
    my $sql = 'SELECT * FROM test';
    is_deeply $dbh0->selectall_arrayref($sql), [];
    is_deeply $dbh1->selectall_arrayref($sql), [];
    
    if(fork){
        wait;
    }else{
        $_->{InactiveDestroy} = 1 for($DBH, $dbh0, $dbh1);
        exit;
    }
    is_deeply $dbh0->selectall_arrayref($sql), [];
    is_deeply $dbh1->selectall_arrayref($sql), [];
    
    $proj->end;
};

my $msg = $@;
$DBH->prepare("drop database $DBN;")->execute;
die $msg if $msg;
